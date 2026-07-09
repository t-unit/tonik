import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/built_expression.dart';
import 'package:tonik_generate/src/util/spec_literal_string.dart';
import 'package:tonik_generate/src/util/uri_encode_expression_generator.dart';

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

/// Builds deep-object encoding code for a [MapModel] parameter.
///
/// For `Map<String, String>`, delegates directly to the
/// `Map<String, String>.toDeepObject()` extension. For maps with other
/// simple value types (int, bool, enum, etc.), generates a `.map()` call
/// to convert values to URI-encoded strings first.
///
/// Throws an `EncodingException` for maps with complex value types
/// (ClassModel, ListModel, nested MapModel) that can't be flattened to
/// a single string per entry.
Expression _buildMapDeepObjectExpression(
  String parameterName,
  String rawName,
  MapModel model, {
  required bool explode,
  required bool allowEmpty,
  required bool allowReserved,
}) {
  final valueModel = model.valueModel;
  final resolvedValueModel = valueModel.resolved;

  // For Map<String, String>, the extension handles encoding directly.
  if (resolvedValueModel is StringModel) {
    return refer(parameterName)
        .property('toDeepObject')
        .call(
          [specLiteralString(rawName)],
          {
            'explode': literalBool(explode),
            'allowEmpty': literalBool(allowEmpty),
            if (allowReserved) 'allowReserved': literalBool(true),
          },
        );
  }

  // For maps with simple value types, convert values to URI-encoded strings
  // then use the Map<String, String>.toDeepObject() extension.
  if (_isSimpleMapValueModel(resolvedValueModel)) {
    final uriEncodeExpr = buildUriEncodeExpression(
      refer('v'),
      valueModel,
      allowEmpty: literalBool(allowEmpty),
      allowReserved: allowReserved ? literalBool(true) : null,
    );

    final mapEntryClosure = Method(
      (b) => b
        ..requiredParameters.addAll([
          Parameter((p) => p..name = 'k'),
          Parameter((p) => p..name = 'v'),
        ])
        ..body = refer(
          'MapEntry',
          'dart:core',
        ).newInstance([refer('k'), uriEncodeExpr.expression]).code,
    ).closure;

    return refer(parameterName)
        .property('map')
        .call([mapEntryClosure])
        .property('toDeepObject')
        .call(
          [specLiteralString(rawName)],
          {
            'explode': literalBool(explode),
            'allowEmpty': literalBool(allowEmpty),
            'alreadyEncoded': literalBool(true),
          },
        );
  }

  // Complex value types (ClassModel, ListModel, nested MapModel) can't be
  // flattened to a single string per entry.
  return refer('EncodingException', 'package:tonik_util/tonik_util.dart').call([
    specLiteralString(
      'deepObject encoding is not supported for Map types with '
      'complex values. Parameter "$rawName" cannot be encoded.',
    ),
  ]).thrown;
}

/// Whether [model] can be converted to a single URI-encoded string.
bool _isSimpleMapValueModel(Model model) {
  return switch (model) {
    IntegerModel() ||
    DoubleModel() ||
    NumberModel() ||
    BooleanModel() ||
    DateTimeModel() ||
    DecimalModel() ||
    UriModel() ||
    DateModel() ||
    BinaryModel() ||
    Base64Model() ||
    EnumModel() => true,
    AnyModel() || AnyOfModel() || OneOfModel() || AllOfModel() => true,
    AliasModel() => _isSimpleMapValueModel(model.resolved),
    _ => false,
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
