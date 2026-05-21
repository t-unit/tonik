import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';

/// Per-method state for recursion-breaking inline helpers.
///
/// One instance per generated method body. Tracks which `(model, prefix)`
/// pairs already have their body emitted (so dedup works), and the
/// recursion stack (so a self-reference mid-descent resolves to a call
/// instead of rebuilding the body).
class InlineHelperContext {
  InlineHelperContext({required this.nameManager});

  final NameManager nameManager;

  final Set<(NamedModel, String)> _emitted = {};
  final List<NamedModel> _stack = [];

  T withRecursion<T>(NamedModel model, T Function() body) {
    _stack.add(model);
    try {
      return body();
    } finally {
      _stack.removeLast();
    }
  }

  bool isOnStack(NamedModel model) =>
      _stack.any((entry) => identical(entry, model));

  /// `_$decode<TypeName>` / `_$encode<TypeName>`. The `_$` sigil cannot
  /// appear in user-side identifiers or in any name produced by
  /// [NameManager.modelName], so the result is collision-free.
  String helperName(NamedModel model, String prefix) =>
      '$prefix${nameManager.modelName(model)}';

  bool isHelperEmitted(NamedModel model, String prefix) =>
      _emitted.contains((model, prefix));

  void markHelperEmitted(NamedModel model, String prefix) {
    _emitted.add((model, prefix));
  }
}
