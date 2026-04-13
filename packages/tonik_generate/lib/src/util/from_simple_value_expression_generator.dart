import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';
import 'package:tonik_generate/src/util/spec_literal_string.dart';

/// Returns the reason why simple decoding is not supported for the given model,
/// or `null` if simple decoding is supported.
String? getSimpleDecodingUnsupportedReason(Model model) {
  return switch (model) {
    StringModel() ||
    IntegerModel() ||
    NumberModel() ||
    DoubleModel() ||
    DecimalModel() ||
    BooleanModel() ||
    DateTimeModel() ||
    DateModel() ||
    UriModel() ||
    BinaryModel() ||
    Base64Model() ||
    EnumModel() ||
    ClassModel() ||
    AllOfModel() ||
    OneOfModel() ||
    AnyModel() ||
    AnyOfModel() => null,
    NeverModel() => 'NeverModel does not permit any value',
    ListModel(:final content) => _getListContentUnsupportedReason(content),
    AliasModel(:final model) => getSimpleDecodingUnsupportedReason(model),
    MapModel() => 'Map types cannot be simple-decoded',
    NamedModel() || CompositeModel() => 'Unsupported model type: $model',
  };
}

String? _getListContentUnsupportedReason(Model content) {
  return switch (content) {
    StringModel() ||
    IntegerModel() ||
    NumberModel() ||
    DoubleModel() ||
    DecimalModel() ||
    BooleanModel() ||
    DateTimeModel() ||
    DateModel() ||
    UriModel() ||
    BinaryModel() ||
    Base64Model() ||
    EnumModel() ||
    OneOfModel() ||
    AllOfModel() ||
    AnyModel() ||
    AnyOfModel() => null,
    NeverModel() => 'NeverModel does not permit any value',
    ClassModel() => 'Lists of objects are not supported in simple encoding',
    ListModel() => 'Nested lists are not supported in simple encoding',
    AliasModel(:final model) => _getListContentUnsupportedReason(model),
    NamedModel() || CompositeModel() => 'Unsupported model type: $content',
  };
}

/// Creates a Dart expression that correctly deserializes a simple value
/// to its Dart representation.
Expression buildSimpleValueExpression(
  Expression value, {
  required Model model,
  required bool isRequired,
  required NameManager nameManager,
  required Expression explode,
  String? package,
  String? contextClass,
  String? contextProperty,
}) {
  final contextParam = (contextClass != null || contextProperty != null)
      ? {
          'context': specLiteralString(
            (contextClass != null && contextProperty != null)
                ? '$contextClass.$contextProperty'
                : contextClass ?? contextProperty!,
          ),
        }
      : <String, Expression>{};

  return switch (model) {
    StringModel() =>
      isRequired
          ? value.property('decodeSimpleString').call([], contextParam)
          : value.property('decodeSimpleNullableString').call([], contextParam),
    IntegerModel() =>
      isRequired
          ? value.property('decodeSimpleInt').call([], contextParam)
          : value.property('decodeSimpleNullableInt').call([], contextParam),
    NumberModel() =>
      isRequired
          ? value.property('decodeSimpleDouble').call([], contextParam)
          : value.property('decodeSimpleNullableDouble').call([], contextParam),
    DoubleModel() =>
      isRequired
          ? value.property('decodeSimpleDouble').call([], contextParam)
          : value.property('decodeSimpleNullableDouble').call([], contextParam),
    DecimalModel() =>
      isRequired
          ? value.property('decodeSimpleBigDecimal').call([], contextParam)
          : value
                .property('decodeSimpleNullableBigDecimal')
                .call([], contextParam),
    BooleanModel() =>
      isRequired
          ? value.property('decodeSimpleBool').call([], contextParam)
          : value.property('decodeSimpleNullableBool').call([], contextParam),
    DateTimeModel() =>
      isRequired
          ? value.property('decodeSimpleDateTime').call([], contextParam)
          : value
                .property('decodeSimpleNullableDateTime')
                .call([], contextParam),
    DateModel() =>
      isRequired
          ? value.property('decodeSimpleDate').call([], contextParam)
          : value.property('decodeSimpleNullableDate').call([], contextParam),
    UriModel() =>
      isRequired
          ? value.property('decodeSimpleUri').call([], contextParam)
          : value.property('decodeSimpleNullableUri').call([], contextParam),
    BinaryModel() => _buildFromSimpleBinaryExpression(
      value,
      isRequired: isRequired,
      contextParam: contextParam,
    ),
    Base64Model() => _buildFromSimpleBase64Expression(
      value,
      isRequired: isRequired,
      contextParam: contextParam,
    ),
    EnumModel() ||
    ClassModel() ||
    AllOfModel() ||
    OneOfModel() ||
    AnyOfModel() => _buildFromSimpleExpression(
      value,
      model,
      isRequired,
      nameManager,
      package: package,
      contextClass: contextClass,
      contextProperty: contextProperty,
      explode: explode,
    ),
    final ListModel listModel => _buildListFromSimpleExpression(
      value,
      listModel,
      isRequired,
      nameManager,
      package: package,
      contextClass: contextClass,
      contextProperty: contextProperty,
      explode: explode,
    ),
    final AliasModel aliasModel => buildSimpleValueExpression(
      value,
      model: aliasModel.model,
      isRequired: isRequired,
      nameManager: nameManager,
      package: package,
      contextClass: contextClass,
      contextProperty: contextProperty,
      explode: explode,
    ),
    NeverModel() => _buildNeverModelExpression(value, isRequired),
    AnyModel() => value,
    MapModel() => generateSimpleDecodingExceptionExpression(
      'Map types cannot be simple-decoded.',
    ),
    // coverage:ignore-start
    NamedModel() ||
    CompositeModel() => generateSimpleDecodingExceptionExpression(
      'Unsupported model type for simple decoding.',
    ),
    // coverage:ignore-end
  };
}

Expression _buildNeverModelExpression(Expression value, bool isRequired) {
  final throwExpr = generateSimpleDecodingExceptionExpression(
    'Cannot decode NeverModel - this type does not permit any value.',
  );
  return isRequired
      ? throwExpr
      : value.equalTo(literalNull).conditional(literalNull, throwExpr);
}

Expression _buildFromSimpleExpression(
  Expression value,
  Model model,
  bool isRequired,
  NameManager nameManager, {
  required Expression explode,
  String? package,
  String? contextClass,
  String? contextProperty,
}) {
  final name = nameManager.modelName(model);
  final explodeParam = {'explode': explode};

  return isRequired
      ? refer(name, package).property('fromSimple').call([value], explodeParam)
      : value
            .equalTo(literalNull)
            .conditional(
              literalNull,
              refer(
                name,
                package,
              ).property('fromSimple').call([value], explodeParam),
            );
}

Expression _buildListDecode(
  Expression value,
  bool isRequired, {
  Map<String, Expression> contextParam = const {},
}) {
  return value
      .property(
        isRequired
            ? 'decodeSimpleStringList'
            : 'decodeSimpleNullableStringList',
      )
      .call([], contextParam);
}

Expression _buildListFromSimpleExpression(
  Expression value,
  ListModel model,
  bool isRequired,
  NameManager nameManager, {
  required Expression explode,
  String? package,
  String? contextClass,
  String? contextProperty,
}) {
  final content = model.content;
  final contextParam = (contextClass != null || contextProperty != null)
      ? {
          'context': specLiteralString(
            (contextClass != null && contextProperty != null)
                ? '$contextClass.$contextProperty'
                : contextClass ?? contextProperty!,
          ),
        }
      : <String, Expression>{};

  final listDecode = _buildListDecode(
    value,
    isRequired,
    contextParam: contextParam,
  );

  return switch (content) {
    StringModel() => listDecode,
    IntegerModel() => _buildPrimitiveList(
      listDecode,
      'decodeSimpleInt',
      isRequired,
      contextParam: contextParam,
    ),
    NumberModel() => _buildPrimitiveList(
      listDecode,
      'decodeSimpleDouble',
      isRequired,
      contextParam: contextParam,
    ),
    DoubleModel() => _buildPrimitiveList(
      listDecode,
      'decodeSimpleDouble',
      isRequired,
      contextParam: contextParam,
    ),
    DecimalModel() => _buildPrimitiveList(
      listDecode,
      'decodeSimpleBigDecimal',
      isRequired,
      contextParam: contextParam,
    ),
    BooleanModel() => _buildPrimitiveList(
      listDecode,
      'decodeSimpleBool',
      isRequired,
      contextParam: contextParam,
    ),
    DateTimeModel() => _buildPrimitiveList(
      listDecode,
      'decodeSimpleDateTime',
      isRequired,
      contextParam: contextParam,
    ),
    DateModel() => _buildPrimitiveList(
      listDecode,
      'decodeSimpleDate',
      isRequired,
      contextParam: contextParam,
    ),
    UriModel() => _buildPrimitiveList(
      listDecode,
      'decodeSimpleUri',
      isRequired,
      contextParam: contextParam,
    ),
    BinaryModel() => _buildTonikFilePrimitiveList(
      listDecode,
      'decodeSimpleBinary',
      isRequired,
      contextParam: contextParam,
    ),
    Base64Model() => _buildTonikFilePrimitiveList(
      listDecode,
      'decodeSimpleBase64',
      isRequired,
      contextParam: contextParam,
    ),
    ClassModel() => generateSimpleDecodingExceptionExpression(
      'ClassModel is not supported in lists for simple decoding.',
    ),
    EnumModel() ||
    OneOfModel() ||
    AllOfModel() ||
    AnyOfModel() => _buildClassList(
      listDecode,
      content,
      isRequired,
      nameManager,
      package: package,
      contextClass: contextClass,
      contextProperty: contextProperty,
      explode: explode,
    ),
    ListModel() => generateSimpleDecodingExceptionExpression(
      'Nested lists are not supported in simple decoding.',
    ),
    AliasModel() => _buildListFromSimpleExpression(
      value,
      ListModel(content: content.model, context: model.context),
      isRequired,
      nameManager,
      package: package,
      contextClass: contextClass,
      contextProperty: contextProperty,
      explode: explode,
    ),
    NeverModel() => generateSimpleDecodingExceptionExpression(
      'Cannot decode List<NeverModel> - this type does not permit any value.',
    ),
    AnyModel() => listDecode,
    NamedModel() ||
    CompositeModel() => generateSimpleDecodingExceptionExpression(
      'Unsupported model type for simple decoding.',
    ),
  };
}

Expression _buildPrimitiveList(
  Expression listDecode,
  String decodeMethod,
  bool isRequired, {
  Map<String, Expression> contextParam = const {},
}) {
  final mapFunction = Method(
    (b) => b
      ..requiredParameters.add(Parameter((b) => b..name = 'e'))
      ..body = refer('e').property(decodeMethod).call([], contextParam).code,
  ).closure;

  if (isRequired) {
    return listDecode
        .property('map')
        .call([mapFunction])
        .property('toList')
        .call([]);
  } else {
    // Use code_builder's nullSafeProperty for ?.map
    return listDecode
        .nullSafeProperty('map')
        .call([mapFunction])
        .property('toList')
        .call([]);
  }
}

Expression _buildClassList(
  Expression listDecode,
  Model content,
  bool isRequired,
  NameManager nameManager, {
  required Expression explode,
  String? package,
  String? contextClass,
  String? contextProperty,
}) {
  final className = nameManager.modelName(content);
  final explodeParam = {'explode': explode};

  final mapFunction = Method(
    (b) => b
      ..requiredParameters.add(Parameter((b) => b..name = 'e'))
      ..body =
          refer(
            className,
            package,
          ).property('fromSimple').call([
            refer('e'),
          ], explodeParam).code,
  ).closure;

  if (isRequired) {
    return listDecode
        .property('map')
        .call([mapFunction])
        .property('toList')
        .call([]);
  } else {
    return listDecode
        .nullSafeProperty('map')
        .call([mapFunction])
        .property('toList')
        .call([]);
  }
}

Expression _buildFromSimpleBinaryExpression(
  Expression value, {
  required bool isRequired,
  required Map<String, Expression> contextParam,
}) {
  final tonikFileBytesRef = refer(
    'TonikFileBytes',
    'package:tonik_util/tonik_util.dart',
  );

  if (isRequired) {
    return tonikFileBytesRef.call([
      value.property('decodeSimpleBinary').call([], contextParam),
    ]);
  } else {
    final decodeExpr = value
        .property('decodeSimpleBinary')
        .call([], contextParam);
    return value
        .equalTo(literalNull)
        .conditional(literalNull, tonikFileBytesRef.call([decodeExpr]));
  }
}

Expression _buildFromSimpleBase64Expression(
  Expression value, {
  required bool isRequired,
  required Map<String, Expression> contextParam,
}) {
  final tonikFileBytesRef = refer(
    'TonikFileBytes',
    'package:tonik_util/tonik_util.dart',
  );

  if (isRequired) {
    return tonikFileBytesRef.call([
      value.property('decodeSimpleBase64').call([], contextParam),
    ]);
  } else {
    final decodeExpr = value
        .property('decodeSimpleBase64')
        .call([], contextParam);
    return value
        .equalTo(literalNull)
        .conditional(literalNull, tonikFileBytesRef.call([decodeExpr]));
  }
}

Expression _buildTonikFilePrimitiveList(
  Expression listDecode,
  String decodeFunctionName,
  bool isRequired, {
  Map<String, Expression> contextParam = const {},
}) {
  final mapFunction = Method(
    (b) => b
      ..requiredParameters.add(Parameter((b) => b..name = 'e'))
      ..body =
          refer(
            'TonikFileBytes',
            'package:tonik_util/tonik_util.dart',
          ).call([
            refer('e').property(decodeFunctionName).call([], contextParam),
          ]).code,
  ).closure;

  if (isRequired) {
    return listDecode
        .property('map')
        .call([mapFunction])
        .property('toList')
        .call([]);
  } else {
    return listDecode
        .nullSafeProperty('map')
        .call([mapFunction])
        .property('toList')
        .call([]);
  }
}
