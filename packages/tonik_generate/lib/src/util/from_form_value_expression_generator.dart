import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';
import 'package:tonik_generate/src/util/spec_literal_string.dart';

/// Creates a Dart expression that correctly deserializes a form-encoded value
/// to its Dart representation.
///
/// When [useImmutableCollections] is `true`, decoded lists are wrapped with
/// `.lock` so the result is `IList` throughout.
Expression buildFromFormValueExpression(
  Expression value, {
  required Model model,
  required bool isRequired,
  required NameManager nameManager,
  String? package,
  String? contextClass,
  String? contextProperty,
  Expression? explode,
  bool useImmutableCollections = false,
}) {
  final contextParam = _buildContextParam(contextClass, contextProperty);

  return switch (model) {
    StringModel() =>
      value
          .property(
            isRequired ? 'decodeFormString' : 'decodeFormNullableString',
          )
          .call([], contextParam),

    IntegerModel() =>
      value
          .property(
            isRequired ? 'decodeFormInt' : 'decodeFormNullableInt',
          )
          .call([], contextParam),

    DoubleModel() =>
      value
          .property(
            isRequired ? 'decodeFormDouble' : 'decodeFormNullableDouble',
          )
          .call([], contextParam),

    NumberModel() =>
      value
          .property(
            isRequired ? 'decodeFormDouble' : 'decodeFormNullableDouble',
          )
          .call([], contextParam),

    BooleanModel() =>
      value
          .property(
            isRequired ? 'decodeFormBool' : 'decodeFormNullableBool',
          )
          .call([], contextParam),

    DateTimeModel() =>
      value
          .property(
            isRequired ? 'decodeFormDateTime' : 'decodeFormNullableDateTime',
          )
          .call([], contextParam),

    DateModel() =>
      value
          .property(
            isRequired ? 'decodeFormDate' : 'decodeFormNullableDate',
          )
          .call([], contextParam),

    DecimalModel() =>
      value
          .property(
            isRequired
                ? 'decodeFormBigDecimal'
                : 'decodeFormNullableBigDecimal',
          )
          .call([], contextParam),

    UriModel() =>
      value
          .property(
            isRequired ? 'decodeFormUri' : 'decodeFormNullableUri',
          )
          .call([], contextParam),

    BinaryModel() => _buildFromFormBinaryExpression(
      value,
      isRequired: isRequired,
      contextParam: contextParam,
    ),

    Base64Model() => _buildFromFormBase64Expression(
      value,
      isRequired: isRequired,
      contextParam: contextParam,
    ),

    AliasModel() => buildFromFormValueExpression(
      value,
      model: model.model,
      isRequired: isRequired,
      nameManager: nameManager,
      package: package,
      contextClass: contextClass,
      contextProperty: contextProperty,
      explode: explode,
      useImmutableCollections: useImmutableCollections,
    ),

    EnumModel() ||
    ClassModel() ||
    AllOfModel() ||
    OneOfModel() ||
    AnyOfModel() => _buildFromFormExpression(
      value,
      model,
      isRequired,
      nameManager,
      package: package,
      contextClass: contextClass,
      contextProperty: contextProperty,
      explode: explode,
    ),

    final ListModel listModel => _buildListFromFormExpression(
      value,
      listModel,
      isRequired,
      nameManager,
      package: package,
      contextClass: contextClass,
      contextProperty: contextProperty,
      explode: explode,
      useImmutableCollections: useImmutableCollections,
    ),

    NeverModel() => _buildNeverModelExpression(value, isRequired),

    AnyModel() => value,

    MapModel() => generateFormDecodingExceptionExpression(
      'Map types cannot be form-decoded.',
    ),

    // coverage:ignore-start
    _ => generateFormDecodingExceptionExpression(
      'Unsupported model type for form decoding.',
    ),
    // coverage:ignore-end
  };
}

Expression _buildNeverModelExpression(Expression value, bool isRequired) {
  final throwExpr = generateFormDecodingExceptionExpression(
    'Cannot decode NeverModel - this type does not permit any value.',
  );
  return isRequired
      ? throwExpr
      : value.equalTo(literalNull).conditional(literalNull, throwExpr);
}

Expression _buildFromFormExpression(
  Expression value,
  Model model,
  bool isRequired,
  NameManager nameManager, {
  String? package,
  String? contextClass,
  String? contextProperty,
  Expression? explode,
}) {
  final name = nameManager.modelName(model);
  final explodeParam = {'explode': explode ?? literalBool(true)};

  return isRequired
      ? refer(name, package).property('fromForm').call([value], explodeParam)
      : value
            .equalTo(literalNull)
            .conditional(
              literalNull,
              refer(
                name,
                package,
              ).property('fromForm').call([value], explodeParam),
            );
}

Map<String, Expression> _buildContextParam(
  String? contextClass,
  String? contextProperty,
) {
  if (contextClass != null || contextProperty != null) {
    final contextString = (contextClass != null && contextProperty != null)
        ? '$contextClass.$contextProperty'
        : contextClass ?? contextProperty!;

    return {'context': specLiteralString(contextString)};
  }
  return <String, Expression>{};
}

Expression _buildListFromFormExpression(
  Expression value,
  ListModel model,
  bool isRequired,
  NameManager nameManager, {
  String? package,
  String? contextClass,
  String? contextProperty,
  Expression? explode,
  bool useImmutableCollections = false,
}) {
  final content = model.content;
  final contextParam = _buildContextParam(contextClass, contextProperty);

  final listDecode = value
      .property(
        isRequired ? 'decodeFormStringList' : 'decodeFormNullableStringList',
      )
      .call([], contextParam);

  var result = switch (content) {
    StringModel() => listDecode,
    IntegerModel() => _buildPrimitiveList(
      listDecode,
      'decodeFormInt',
      isRequired,
      contextParam: contextParam,
    ),
    NumberModel() => _buildPrimitiveList(
      listDecode,
      'decodeFormDouble',
      isRequired,
      contextParam: contextParam,
    ),
    DoubleModel() => _buildPrimitiveList(
      listDecode,
      'decodeFormDouble',
      isRequired,
      contextParam: contextParam,
    ),
    DecimalModel() => _buildPrimitiveList(
      listDecode,
      'decodeFormBigDecimal',
      isRequired,
      contextParam: contextParam,
    ),
    BooleanModel() => _buildPrimitiveList(
      listDecode,
      'decodeFormBool',
      isRequired,
      contextParam: contextParam,
    ),
    DateTimeModel() => _buildPrimitiveList(
      listDecode,
      'decodeFormDateTime',
      isRequired,
      contextParam: contextParam,
    ),
    DateModel() => _buildPrimitiveList(
      listDecode,
      'decodeFormDate',
      isRequired,
      contextParam: contextParam,
    ),
    UriModel() => _buildPrimitiveList(
      listDecode,
      'decodeFormUri',
      isRequired,
      contextParam: contextParam,
    ),
    BinaryModel() => _buildTonikFilePrimitiveList(
      listDecode,
      'decodeFormBinary',
      isRequired,
      contextParam: contextParam,
    ),
    Base64Model() => _buildTonikFilePrimitiveList(
      listDecode,
      'decodeFormBase64',
      isRequired,
      contextParam: contextParam,
    ),
    ClassModel() => generateFormDecodingExceptionExpression(
      'ClassModel is not supported in lists for form decoding.',
    ),
    EnumModel() ||
    AllOfModel() ||
    OneOfModel() ||
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
    ListModel() => generateFormDecodingExceptionExpression(
      'Nested lists are not supported in form decoding.',
    ),
    AliasModel() => _buildListFromFormExpression(
      value,
      ListModel(content: content.model, context: model.context),
      isRequired,
      nameManager,
      package: package,
      contextClass: contextClass,
      contextProperty: contextProperty,
      explode: explode,
      useImmutableCollections: useImmutableCollections,
    ),
    NeverModel() => generateFormDecodingExceptionExpression(
      'Cannot decode List<NeverModel> - this type does not permit any value.',
    ),
    AnyModel() => listDecode,
    NamedModel() ||
    CompositeModel() => generateFormDecodingExceptionExpression(
      'Unsupported model type for form decoding.',
    ),
  };

  // When using immutable collections, wrap with .lock to convert to IList.
  if (useImmutableCollections) {
    result = isRequired
        ? result.property('lock')
        : result.nullSafeProperty('lock');
  }

  return result;
}

Expression _buildPrimitiveList(
  Expression listDecode,
  String decodeFunctionName,
  bool isRequired, {
  Map<String, Expression> contextParam = const {},
}) {
  final mapFunction = Method(
    (b) => b
      ..requiredParameters.add(Parameter((b) => b..name = 'e'))
      ..body = refer(
        'e',
      ).property(decodeFunctionName).call([], contextParam).code,
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

Expression _buildClassList(
  Expression listDecode,
  Model content,
  bool isRequired,
  NameManager nameManager, {
  String? package,
  String? contextClass,
  String? contextProperty,
  Expression? explode,
}) {
  final name = nameManager.modelName(content);
  final explodeParam = {'explode': explode ?? literalBool(true)};

  final mapFunction = Method(
    (b) => b
      ..requiredParameters.add(Parameter((b) => b..name = 'e'))
      ..body = refer(name, package).property('fromForm').call([
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

Expression _buildFromFormBinaryExpression(
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
      value.property('decodeFormBinary').call([], contextParam),
    ]);
  } else {
    final decodeExpr = value
        .property('decodeFormBinary')
        .call([], contextParam);
    return value
        .equalTo(literalNull)
        .conditional(literalNull, tonikFileBytesRef.call([decodeExpr]));
  }
}

Expression _buildFromFormBase64Expression(
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
      value.property('decodeFormBase64').call([], contextParam),
    ]);
  } else {
    final decodeExpr = value
        .property('decodeFormBase64')
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
