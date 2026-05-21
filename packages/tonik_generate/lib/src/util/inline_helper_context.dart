import 'package:meta/meta.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/util/built_expression.dart';

/// Per-method state shared by recursive expression builders.
///
/// One instance is created at the top of each generated method body. It
/// tracks:
///
/// * Which recursive typedef names already have a local helper declared
///   in this method body — so a class with `Map<String, Tree>` and
///   `List<Tree>` properties emits a single `_decodeTree` helper.
/// * The active recursion stack — typedefs currently in flight inside
///   the builder, so cycles are detected mid-descent.
/// * Reserved identifier names in the enclosing method scope, so
///   generated helpers never shadow `value`, `json`, the request body
///   parameter, or each other.
///
/// Callers obtain a name via [reserveHelperName] before emitting the
/// helper. Subsequent requests with the same `(NamedModel, prefix)` key
/// return the originally-reserved name so dedup is automatic.
///
/// One instance per generated method body. Sharing across methods would
/// silently emit duplicate helpers because `_emittedHelpers` is
/// method-local by design.
class InlineHelperContext {
  InlineHelperContext({
    required this.nameManager,
    Iterable<String> reservedNames = const [],
  }) : _reservedNames = {...reservedNames};

  final NameManager nameManager;

  /// Names already taken in the enclosing method scope (parameter names,
  /// local variables emitted earlier, previously-claimed helper names).
  final Set<String> _reservedNames;

  /// `(typedef-name, prefix)` → assigned helper identifier. Both axes are
  /// needed because the same typedef may need an encode AND a decode
  /// helper in the same method body.
  final Map<_HelperKey, String> _helperNames = {};

  /// `(typedef-name, prefix)` for helpers whose function body has already
  /// been emitted into [BuiltExpression.inlineFunctions] by an earlier
  /// builder pass. Distinguishing "reserved" from "emitted" is necessary
  /// because the body can recursively reference itself via the reserved
  /// name while we are still in the middle of emitting that body — we
  /// must not emit it again.
  final Set<_HelperKey> _emittedHelpers = {};

  final List<NamedModel> _stack = [];

  /// Pushes [model] onto the recursion stack for the duration of [body].
  T withRecursion<T>(NamedModel model, T Function() body) {
    _stack.add(model);
    try {
      return body();
    } finally {
      _stack.removeLast();
    }
  }

  /// Detects whether [model] is currently being expanded on this
  /// context's recursion stack. Today this is redundant with
  /// [isHelperEmitted] because every `_buildNamedTypedef*HelperCall` calls
  /// [markHelperEmitted] immediately before [withRecursion]. The check
  /// remains as a load-bearing safety net for future call sites that
  /// might not preserve that ordering — do not delete it as dead code.
  bool isOnStack(NamedModel model) =>
      _stack.any((entry) => identical(entry, model));

  /// Returns the (possibly new) helper-function identifier for
  /// `(model, prefix)`. [prefix] is `_decode` or `_encode` etc. Subsequent
  /// calls with the same key return the originally-reserved name.
  ///
  /// The chosen name is appended to the reserved-name set so further
  /// inline helpers in the same method scope cannot collide with it. A
  /// monotonic numeric suffix is appended only if the natural name is
  /// already taken.
  ///
  /// Caller is responsible for ensuring `prefix + nameManager.modelName(model)`
  /// yields a valid Dart identifier. Callers in this codebase use the
  /// constants `_decode` and `_encode` plus a `NameManager`-produced PascalCase
  /// name, both of which are always valid identifiers.
  String reserveHelperName(NamedModel model, String prefix) {
    final key = _HelperKey(model, prefix);
    final existing = _helperNames[key];
    if (existing != null) return existing;

    final base = '$prefix${nameManager.modelName(model)}';
    var candidate = base;
    var counter = 2;
    while (_reservedNames.contains(candidate)) {
      if (counter > _suffixCollisionLimit) {
        throw StateError(
          'reserveHelperName exhausted suffix range for model '
          '"${nameManager.modelName(model)}" with prefix "$prefix" '
          '(last candidate "$candidate"). Reserved name set has at '
          'least $_suffixCollisionLimit entries colliding with this '
          'base; this points at a generator bug or hostile input.',
        );
      }
      candidate = '$base$counter';
      counter++;
    }
    _reservedNames.add(candidate);
    _helperNames[key] = candidate;
    return candidate;
  }

  /// Upper bound on suffixed retries before [reserveHelperName] throws.
  /// Set tightly so a generator bug producing exponential collisions
  /// surfaces in test logs instead of running silently for thousands of
  /// iterations. Legitimate single-method clashes do not exceed single
  /// digits.
  static const int _suffixCollisionLimit = 32;

  /// True if a helper function body for `(model, prefix)` has been
  /// emitted into [BuiltExpression.inlineFunctions] at some level above
  /// the current call. Used by builders to decide whether to recurse
  /// into the body or simply emit a call to the reserved name.
  bool isHelperEmitted(NamedModel model, String prefix) {
    return _emittedHelpers.contains(_HelperKey(model, prefix));
  }

  /// Marks `(model, prefix)` as having had its body emitted. Must be
  /// called before recursing into the body so self-references resolve
  /// to the reserved name without rebuilding the body.
  void markHelperEmitted(NamedModel model, String prefix) {
    _emittedHelpers.add(_HelperKey(model, prefix));
  }
}

@immutable
class _HelperKey {
  const _HelperKey(this.model, this.prefix);
  final NamedModel model;
  final String prefix;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _HelperKey &&
          identical(other.model, model) &&
          other.prefix == prefix;

  @override
  int get hashCode => Object.hash(identityHashCode(model), prefix);
}
