import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/built_expression.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';
import 'package:tonik_generate/src/util/form_entries_expression_builder.dart';
import 'package:tonik_generate/src/util/map_value_to_string_expression_builder.dart';
import 'package:tonik_generate/src/util/spec_literal_string.dart';

BuiltStatements buildToFormQueryParameterCode(
  String parameterName,
  QueryParameterObject parameter, {
  bool explode = false,
  bool allowEmpty = true,
  bool allowReserved = false,
}) {
  return BuiltStatements.simple(
    _buildToFormQueryParameterCode(
      parameterName,
      parameter,
      explode: explode,
      allowEmpty: allowEmpty,
      allowReserved: allowReserved,
    ),
  );
}

List<Code> _buildToFormQueryParameterCode(
  String parameterName,
  QueryParameterObject parameter, {
  required bool explode,
  required bool allowEmpty,
  required bool allowReserved,
}) {
  final model = parameter.model;
  final rawName = parameter.rawName;

  final unsupported = formEntriesUnsupportedReason(model);
  if (unsupported != null) {
    return [generateEncodingExceptionExpression(unsupported).statement];
  }

  if (model is MapModel &&
      !isMapValueTypeSimplyEncodable(model.valueModel)) {
    return [
      generateEncodingExceptionExpression(
        'Map with complex value types cannot be form query encoded.',
      ).statement,
    ];
  }

  if (isAnyModelFormValue(model)) {
    final entries =
        refer('encodeAnyToFormEntries', 'package:tonik_util/tonik_util.dart')
            .call(
      [refer(parameterName)],
      {
        'name': specLiteralString(rawName),
        'explode': literalBool(explode),
        'allowEmpty': literalBool(allowEmpty),
        if (allowReserved) 'allowReserved': literalBool(true),
      },
    );
    return [
      refer(r'_$entries').property('addAll').call([entries]).statement,
    ];
  }

  final value = buildFormEntriesValueExpression(
    refer(parameterName),
    model,
    paramName: specLiteralString(rawName),
    explode: literalBool(explode),
    allowEmpty: literalBool(allowEmpty),
    allowReserved: allowReserved,
  );

  if (value == null) {
    return [
      generateEncodingExceptionExpression(
        'Unsupported model type for form query encoding.',
      ).statement,
    ];
  }

  return [
    refer(r'_$entries').property('addAll').call([value]).statement,
  ];
}
