import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/built_expression.dart';
import 'package:tonik_generate/src/util/map_property_value_expression_builder.dart';
import 'package:tonik_generate/src/util/spec_literal_string.dart';

/// Produces `paramName[key1]=value1&paramName[key2]=value2`. Per OpenAPI,
/// deepObject style is query-only and object-only; primitives / lists /
/// enums emit code that throws at runtime.
BuiltExpression buildToDeepObjectQueryParameterCode(
  String parameterName,
  QueryParameterObject parameter, {
  bool allowReserved = false,
}) {
  final model = parameter.model;
  final rawName = parameter.rawName;
  final explode = parameter.explode;
  final allowEmpty = parameter.allowEmptyValue;

  if (model is AnyModel) {
    return BuiltExpression.simple(
      refer('encodeAnyToDeepObject', 'package:tonik_util/tonik_util.dart').call(
        [refer(parameterName), specLiteralString(rawName)],
        {
          'explode': literalBool(explode),
          'allowEmpty': literalBool(allowEmpty),
          if (allowReserved) 'allowReserved': literalBool(true),
        },
      ),
    );
  }

  // Maps go before the general object path because typedefs do not implement
  // ParameterEncodable.
  final resolvedModel = model.resolved;
  if (resolvedModel is MapModel) {
    return BuiltExpression.simple(
      _buildMapDeepObjectExpression(
        parameterName,
        rawName,
        resolvedModel,
        explode: explode,
        allowEmpty: allowEmpty,
        allowReserved: allowReserved,
      ),
    );
  }

  if (_isValidDeepObjectModel(model)) {
    return BuiltExpression.simple(
      refer(parameterName)
          .property('toDeepObject')
          .call(
            [specLiteralString(rawName)],
            {
              'explode': literalBool(explode),
              'allowEmpty': literalBool(allowEmpty),
              if (allowReserved) 'allowReserved': literalBool(true),
            },
          ),
    );
  }

  return BuiltExpression.simple(
    refer('EncodingException', 'package:tonik_util/tonik_util.dart').call([
      specLiteralString(
        'deepObject encoding only supports object types. '
        'Parameter "$rawName" is not supported.',
      ),
    ]).thrown,
  );
}

Expression _buildMapDeepObjectExpression(
  String parameterName,
  String rawName,
  MapModel model, {
  required bool explode,
  required bool allowEmpty,
  required bool allowReserved,
}) {
  final conversion = buildMapPropertyValueConversion(
    refer(parameterName),
    model,
    isNullable: false,
    context: rawName,
  );
  return switch (conversion) {
    SupportedMapPropertyValueConversion(:final expression) =>
      expression
          .property('toDeepObject')
          .call(
            [specLiteralString(rawName)],
            {
              'explode': literalBool(explode),
              'allowEmpty': literalBool(allowEmpty),
              if (allowReserved) 'allowReserved': literalBool(true),
            },
          ),
    UnsupportedMapPropertyValueConversion() =>
      refer(
        'EncodingException',
        'package:tonik_util/tonik_util.dart',
      ).call([
        specLiteralString(
          'deepObject encoding is not supported for Map types with '
          'complex values. Parameter "$rawName" cannot be encoded.',
        ),
      ]).thrown,
  };
}

bool _isValidDeepObjectModel(Model model) {
  return switch (model) {
    ClassModel() => true,
    AllOfModel() => true,
    OneOfModel() => true,
    AnyOfModel() => true,
    AliasModel() => _isValidDeepObjectModel(model.resolved),
    _ => false,
  };
}
