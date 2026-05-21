import 'package:code_builder/code_builder.dart';
import 'package:meta/meta.dart';

/// The result of an expression builder.
///
/// Every value-encoding/decoding builder in `tonik_generate` returns a
/// `BuiltExpression`. It carries:
///
/// * The inner [Expression] (accessed via [expression], [code], [statement],
///   or [accept]) that the caller substitutes at the use-site.
/// * [inlineFunctions] — zero or more local helpers the caller must
///   splice into the enclosing method body BEFORE the use-site statement.
///   They exist to break recursion on self-referential typedef'd
///   `MapModel`/`ListModel` (which have no constructor or method to defer
///   the cycle through). A late-bound local function in Dart can reference
///   itself by name; a single emitted helper per recursive type is enough.
///
/// The non-recursive case always returns [inlineFunctions] empty via
/// [BuiltExpression.simple]; callers can read [expression] without worrying
/// about helper splicing.
///
/// Accessors [expression], [code], [statement], and [accept] all run
/// [_assertNoHelpers] so a caller that forgets to splice [inlineFunctions]
/// gets a clear error instead of silently emitting code that references an
/// undeclared local function.
///
/// Callers that splice [inlineFunctions] themselves and need to compose the
/// raw [Expression] into a larger construct — for example, building a
/// nested closure body whose helpers will flow up the chain — should use
/// [unsafeRawBody], which skips the assertion. Read its dartdoc before
/// reaching for it.
@immutable
class BuiltExpression {
  const BuiltExpression({
    required Expression body,
    this.inlineFunctions = const [],
  }) : _body = body;

  /// Convenience for the common case: just an expression, no helpers.
  const BuiltExpression.simple(Expression body)
      : _body = body,
        inlineFunctions = const [];

  final Expression _body;
  final List<InlineHelper> inlineFunctions;

  /// The result expression. Throws if [inlineFunctions] is non-empty, so
  /// callers that ignore helpers cannot silently emit references to
  /// undeclared local functions.
  Expression get expression {
    _assertNoHelpers('expression');
    return _body;
  }

  /// Raw access to the inner expression. Skips [_assertNoHelpers].
  ///
  /// Use only when the caller takes responsibility for [inlineFunctions]
  /// — typically when composing the inner expression into a closure body
  /// while propagating [inlineFunctions] up into a parent [BuiltExpression].
  /// If you are not propagating helpers yourself, prefer [expression].
  Expression get unsafeRawBody => _body;

  /// Forwards to [Expression.accept] on the inner expression. Convenience
  /// for callers and tests that previously consumed an `Expression`
  /// directly. Throws if any [inlineFunctions] are present, because those
  /// must be spliced into the enclosing method body and a bare
  /// `.accept(emitter)` would silently drop them.
  R accept<R>(ExpressionVisitor<R> visitor, [R? context]) =>
      expression.accept(visitor, context);

  /// Forwards to [Expression.code] on the inner expression. Same caveat
  /// as [accept] — throws when helpers would be dropped.
  Code get code => expression.code;

  /// Forwards to [Expression.statement] on the inner expression. Same
  /// caveat as [accept].
  Code get statement => expression.statement;

  void _assertNoHelpers(String op) {
    if (inlineFunctions.isEmpty) return;
    throw StateError(
      'BuiltExpression.$op called but ${inlineFunctions.length} '
      'inline helper(s) would be dropped. The caller must splice '
      'BuiltExpression.inlineFunctions into the enclosing method body '
      'before reading the inner expression. If composing into a closure '
      'whose enclosing method will splice the helpers, use '
      'BuiltExpression.unsafeRawBody.',
    );
  }
}

/// One local helper plus its identifier. The identifier is the dedup key;
/// the helper is emitted as two [Code] pieces:
///
/// * [forwardDeclaration] — a `late final Return Function(Param) name;`
///   line emitted at the top of the enclosing method's body.
/// * [assignment] — a `name = (param) => body;` line emitted after all
///   forward declarations but before any use site.
///
/// Splitting declaration from assignment lets mutually-recursive helpers
/// (`_encodeAMap` ↔ `_encodeBMap`) reference each other without a
/// "referenced before declaration" error.
@immutable
class InlineHelper {
  const InlineHelper({
    required this.name,
    required this.forwardDeclaration,
    required this.assignment,
  });

  /// The function identifier, unique within its enclosing method scope.
  final String name;

  /// `late final Ret Function(P) name;` line, emitted first.
  final Code forwardDeclaration;

  /// `name = (p) => body;` line, emitted after every helper has a forward
  /// declaration in scope.
  final Code assignment;
}

/// Deduplicates inline helpers by name, preserving first occurrence.
List<InlineHelper> dedupHelpers(Iterable<InlineHelper> helpers) {
  final seen = <String>{};
  final out = <InlineHelper>[];
  for (final h in helpers) {
    if (seen.add(h.name)) out.add(h);
  }
  return out;
}

/// Splices a list of [helpers] into a single [Code] block — every forward
/// declaration first, then every assignment. Use this at the top of an
/// enclosing method body BEFORE the use-site statement so that mutually
/// recursive helpers can reference each other.
List<Code> spliceInlineHelpers(Iterable<InlineHelper> helpers) {
  final deduped = dedupHelpers(helpers);
  return [
    for (final h in deduped) h.forwardDeclaration,
    for (final h in deduped) h.assignment,
  ];
}

/// Collects [BuiltExpression.inlineFunctions] from many sources into a
/// single deduplicated list.
List<InlineHelper> collectInlineFunctions(
  Iterable<BuiltExpression> expressions,
) {
  return dedupHelpers(expressions.expand((e) => e.inlineFunctions));
}

/// The result of a builder that emits a sequence of statements rather
/// than a single [Expression] — for example, the delimited and form-query
/// parameter encoders, which expand into a `for` loop.
///
/// Carries the same inline-helper contract as [BuiltExpression] so call
/// sites treat the two shapes interchangeably from a recursion-handling
/// perspective.
@immutable
class BuiltStatements {
  const BuiltStatements({
    required this.statements,
    this.inlineFunctions = const [],
  });

  /// Convenience for the common case: just statements, no helpers.
  const BuiltStatements.simple(this.statements) : inlineFunctions = const [];

  final List<Code> statements;
  final List<InlineHelper> inlineFunctions;
}
