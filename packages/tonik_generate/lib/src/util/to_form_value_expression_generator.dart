import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/built_expression.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';
import 'package:tonik_generate/src/util/form_entries_expression_builder.dart';

/// Builds the expression that encodes a `application/x-www-form-urlencoded`
/// request body to its wire string.
///
/// Object bodies expand (per `explode: true`) to one `key=value` field each,
/// joined with `&`. [useQueryComponent] uses `+` for spaces.
BuiltExpression buildToFormValueExpression(
  String valueExpression,
  Model model, {
  required bool useQueryComponent,
  bool explodeLiteral = true,
  bool allowEmptyLiteral = true,
  bool isNullable = false,
}) {
  final receiver = refer(valueExpression);
  final resolved = model.resolved;

  final unsupported = formEntriesUnsupportedReason(resolved);
  if (unsupported != null) {
    return BuiltExpression.simple(
      generateEncodingExceptionExpression(unsupported),
    );
  }

  if (resolved is MapModel) {
    return BuiltExpression.simple(
      generateEncodingExceptionExpression(
        'Form encoding not supported for map types.',
      ),
    );
  }

  // AnyModel renders directly to the body string via encodeAnyToForm.
  if (isAnyModelFormValue(model)) {
    return BuiltExpression.simple(
      refer('encodeAnyToForm', 'package:tonik_util/tonik_util.dart').call(
        [receiver],
        {
          'explode': literalBool(explodeLiteral),
          'allowEmpty': literalBool(allowEmptyLiteral),
          if (useQueryComponent) 'useQueryComponent': literalBool(true),
        },
      ),
    );
  }

  final entries = buildFormEntriesValueExpression(
    isNullable ? receiver.nullChecked : receiver,
    model,
    paramName: literalString(''),
    explode: literalBool(explodeLiteral),
    allowEmpty: literalBool(allowEmptyLiteral),
    useQueryComponent: useQueryComponent,
  );

  if (entries == null) {
    return BuiltExpression.simple(
      generateEncodingExceptionExpression(
        'Unsupported model type for form encoding.',
      ),
    );
  }

  // A nullable body must collapse to null rather than throw, so guard the
  // receiver before rendering the entries to a body string.
  final body = _entriesToBody(entries);
  return BuiltExpression.simple(
    isNullable
        ? receiver.equalTo(literalNull).conditional(literalNull, body)
        : body,
  );
}

Expression _entriesToBody(Expression entries) {
  // Scalar bodies produce a single entry with an empty name, whose wire form is
  // the bare value; only keyed (object/exploded) entries render as `name=value`.
  return entries
      .property('map')
      .call([
        Method(
          (b) => b
            ..lambda = true
            ..requiredParameters.add(Parameter((p) => p..name = 'e'))
            ..body = const Code(
              r"e.name.isEmpty ? e.value : '${e.name}=${e.value}'",
            ),
        ).closure,
      ])
      .property('join')
      .call([literalString('&')]);
}
