import 'package:code_builder/code_builder.dart';
import 'package:meta/meta.dart';

/// The result of an expression builder.
///
/// Every value-encoding/decoding builder in `tonik_generate` returns a
/// `BuiltExpression` (or [BuiltStatements], for builders that emit a
/// sequence of statements rather than a single expression). It carries:
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
/// Primitive non-recursive builders use [BuiltExpression.simple]; compound
/// builders forward inner helpers via the full constructor and may still
/// return an empty list when no recursion is reachable.
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
  BuiltExpression({
    required Expression body,
    List<InlineHelper> inlineFunctions = const [],
  })  : _body = body,
        inlineFunctions = List.unmodifiable(inlineFunctions);

  /// Convenience for the common case: just an expression, no helpers.
  const BuiltExpression.simple(Expression body)
      : _body = body,
        inlineFunctions = const [];

  final Expression _body;

  /// Inline helpers the caller must splice into the enclosing method body
  /// before any use of this expression. May be empty.
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
  ///
  /// If you read [unsafeRawBody] and do not propagate [inlineFunctions]
  /// in your returned [BuiltExpression], the generated code will reference
  /// undeclared local functions and fail to compile.
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
/// * [assignment] — a single statement binding a function expression to
///   `name`, emitted after every forward declaration but before any use
///   site. The body may be arrow-form (the decode side emits
///   `name = (Object? v) => body;`) or a statement block (the encode side
///   emits `name = (Object? raw) { if (raw is! T) throw ...; final v = raw;
///   return body; };` so the runtime cast failure can be reported with the
///   typedef name).
///
/// Splitting declaration from assignment lets mutually-recursive helpers
/// (`_encodeAMap` <-> `_encodeBMap`) reference each other without a
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
/// Mirrors the [BuiltExpression] safety pattern: the public [statements]
/// getter runs [_assertNoHelpers] so a caller that forgets to splice
/// [inlineFunctions] gets a clear error instead of silently emitting code
/// that references undeclared local functions. Callers composing the
/// statements into a larger block and propagating [inlineFunctions] up to
/// a parent builder should use [unsafeRawStatements].
@immutable
class BuiltStatements {
  BuiltStatements({
    required List<Code> statements,
    List<InlineHelper> inlineFunctions = const [],
  })  : _statements = List.unmodifiable(statements),
        inlineFunctions = List.unmodifiable(inlineFunctions);

  /// Convenience for the common case: just statements, no helpers.
  const BuiltStatements.simple(List<Code> statements)
      : _statements = statements,
        inlineFunctions = const [];

  final List<Code> _statements;

  /// Inline helpers the caller must splice into the enclosing method body
  /// before any use of these statements. May be empty.
  final List<InlineHelper> inlineFunctions;

  /// The result statements. Throws if [inlineFunctions] is non-empty, so
  /// callers that ignore helpers cannot silently emit references to
  /// undeclared local functions.
  List<Code> get statements {
    _assertNoHelpers('statements');
    return _statements;
  }

  /// Raw access to the inner statements list. Skips [_assertNoHelpers].
  ///
  /// Use only when the caller takes responsibility for [inlineFunctions]
  /// — typically when composing the statements into a larger block while
  /// propagating [inlineFunctions] up into a parent [BuiltStatements] or
  /// [BuiltExpression]. If you are not propagating helpers yourself,
  /// prefer [statements].
  ///
  /// If you read [unsafeRawStatements] and do not propagate
  /// [inlineFunctions] in your returned builder, the generated code will
  /// reference undeclared local functions and fail to compile.
  List<Code> get unsafeRawStatements => _statements;

  void _assertNoHelpers(String op) {
    if (inlineFunctions.isEmpty) return;
    throw StateError(
      'BuiltStatements.$op called but ${inlineFunctions.length} '
      'inline helper(s) would be dropped. The caller must splice '
      'BuiltStatements.inlineFunctions into the enclosing method body '
      'before reading the inner statements. If composing into a larger '
      'block whose enclosing method will splice the helpers, use '
      'BuiltStatements.unsafeRawStatements.',
    );
  }
}
