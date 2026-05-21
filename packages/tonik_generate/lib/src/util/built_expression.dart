import 'package:code_builder/code_builder.dart';
import 'package:meta/meta.dart';

/// The result of an expression builder: an expression plus optional
/// inline helpers the caller must splice into the enclosing method body
/// before any use of the expression.
///
/// Helpers exist to break recursion on self-referential typedef'd
/// MapModel/ListModel — a local late-bound function can reference itself
/// by name, where a typedef cannot.
///
/// [expression], [code], [statement], and [accept] throw if helpers
/// would be dropped. [unsafeRawBody] skips that check for callers that
/// propagate helpers up into a parent [BuiltExpression] themselves.
@immutable
class BuiltExpression {
  BuiltExpression({
    required Expression body,
    List<InlineHelper> inlineFunctions = const [],
  })  : _body = body,
        inlineFunctions = List.unmodifiable(inlineFunctions);

  const BuiltExpression.simple(Expression body)
      : _body = body,
        inlineFunctions = const [];

  final Expression _body;
  final List<InlineHelper> inlineFunctions;

  Expression get expression {
    _assertNoHelpers('expression');
    return _body;
  }

  /// Skips the helper-dropped assertion. Only safe when the caller will
  /// propagate [inlineFunctions] up into a parent [BuiltExpression].
  Expression get unsafeRawBody => _body;

  R accept<R>(ExpressionVisitor<R> visitor, [R? context]) =>
      expression.accept(visitor, context);

  Code get code => expression.code;

  Code get statement => expression.statement;

  void _assertNoHelpers(String op) {
    if (inlineFunctions.isEmpty) return;
    throw StateError(
      'BuiltExpression.$op called but ${inlineFunctions.length} '
      'inline helper(s) would be dropped. Splice inlineFunctions into '
      'the enclosing method body, or use unsafeRawBody to propagate them.',
    );
  }
}

/// A late-bound local function plus its identifier.
///
/// [forwardDeclaration] is emitted before any [assignment] so that
/// mutually-recursive helpers (`_$encodeAMap` ↔ `_$encodeBMap`) can
/// reference each other.
@immutable
class InlineHelper {
  const InlineHelper({
    required this.name,
    required this.forwardDeclaration,
    required this.assignment,
  });

  final String name;
  final Code forwardDeclaration;
  final Code assignment;
}

/// Returns [helpers] with duplicates by [InlineHelper.name] removed,
/// preserving first occurrence.
List<InlineHelper> dedupHelpers(Iterable<InlineHelper> helpers) {
  final seen = <String>{};
  final out = <InlineHelper>[];
  for (final h in helpers) {
    if (seen.add(h.name)) out.add(h);
  }
  return out;
}

/// All forward declarations first, then all assignments. Splice into the
/// enclosing method body before any use site so that mutually-recursive
/// helpers can reference each other.
List<Code> spliceInlineHelpers(Iterable<InlineHelper> helpers) {
  final deduped = dedupHelpers(helpers);
  return [
    for (final h in deduped) h.forwardDeclaration,
    for (final h in deduped) h.assignment,
  ];
}

List<InlineHelper> collectInlineFunctions(
  Iterable<BuiltExpression> expressions,
) {
  return dedupHelpers(expressions.expand((e) => e.inlineFunctions));
}

/// Statement-shape sibling of [BuiltExpression] for builders that emit a
/// sequence rather than a single expression (delimited / form-query
/// parameter encoders).
@immutable
class BuiltStatements {
  BuiltStatements({
    required List<Code> statements,
    List<InlineHelper> inlineFunctions = const [],
  })  : _statements = List.unmodifiable(statements),
        inlineFunctions = List.unmodifiable(inlineFunctions);

  const BuiltStatements.simple(List<Code> statements)
      : _statements = statements,
        inlineFunctions = const [];

  final List<Code> _statements;
  final List<InlineHelper> inlineFunctions;

  List<Code> get statements {
    _assertNoHelpers('statements');
    return _statements;
  }

  /// Skips the helper-dropped assertion. Only safe when the caller will
  /// propagate [inlineFunctions] up into a parent builder.
  List<Code> get unsafeRawStatements => _statements;

  void _assertNoHelpers(String op) {
    if (inlineFunctions.isEmpty) return;
    throw StateError(
      'BuiltStatements.$op called but ${inlineFunctions.length} '
      'inline helper(s) would be dropped. Splice inlineFunctions into '
      'the enclosing method body, or use unsafeRawStatements to '
      'propagate them.',
    );
  }
}
