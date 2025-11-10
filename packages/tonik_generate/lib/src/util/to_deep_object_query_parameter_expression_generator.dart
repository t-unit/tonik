import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';

/// Creates a Code expression that correctly serializes a query parameter
/// using deepObject encoding.
///
/// According to OpenAPI spec, deepObject style is ONLY for query parameters
/// with object values. It produces: 
///   `paramName[key1]=value1&paramName[key2]=value2`
///
/// For invalid types (primitives, lists, enums), generates code that throws
/// at runtime with a descriptive error message.
Code buildToDeepObjectQueryParameterCode(
  String parameterName,
  QueryParameterObject parameter,
) {
  final model = parameter.model;
  final rawName = parameter.rawName;
  final explode = parameter.explode;
  final allowEmpty = parameter.allowEmptyValue;

  if (_isValidDeepObjectModel(model)) {
    return refer(parameterName)
        .property('toDeepObject')
        .call(
          [literalString(rawName, raw: true)],
          {
            'explode': literalBool(explode),
            'allowEmpty': literalBool(allowEmpty),
          },
        ).code;
  }

  return refer('EncodingException', 'package:tonik_util/tonik_util.dart')
      .call([
        literalString(
          'deepObject encoding only supports object types. '
          'Parameter "$rawName" is not supported.',
          raw: true,
        ),
      ])
      .thrown
      .code;
}

bool _isValidDeepObjectModel(Model model) {
  return switch (model) {
    ClassModel() => true,
    AllOfModel() => true,
    OneOfModel() => true,
    AnyOfModel() => true,
    AliasModel() => _isValidDeepObjectModel(model.model),
    _ => false,
  };
}
