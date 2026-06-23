import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/built_expression.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';
import 'package:tonik_generate/src/util/form_entries_expression_builder.dart';

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
    useQueryComponent: useQueryComponent ? literalBool(true) : null,
  );

  if (entries == null) {
    return BuiltExpression.simple(
      generateEncodingExceptionExpression(
        'Unsupported model type for form encoding.',
      ),
    );
  }

  // A nullable body must collapse to null rather than throw.
  final body = _entriesToBody(entries);
  return BuiltExpression.simple(
    isNullable
        ? receiver.equalTo(literalNull).conditional(literalNull, body)
        : body,
  );
}

Expression _entriesToBody(Expression entries) {
  return entries
      .property('map')
      .call([formEntryToWireString()])
      .property('join')
      .call([literalString('&')]);
}
