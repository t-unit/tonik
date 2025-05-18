import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';

/// Creates a Dart expression that correctly deserializes a simple value
/// to its Dart representation.
Expression buildSimpleValueExpression(
  Expression value, {
  required Model model,
  required bool isRequired,
  required NameManager nameManager,
  String? package,
  String? contextClass,
  String? contextProperty,
}) {
  final contextParam =
      (contextClass != null || contextProperty != null)
          ? {
            'context': literalString(
              (contextClass != null && contextProperty != null)
                  ? '$contextClass.$contextProperty'
                  : contextClass ?? contextProperty!,
              raw: true,
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
    ),
    final ListModel listModel => _buildListFromSimpleExpression(
      value,
      listModel,
      isRequired,
      nameManager,
      package: package,
      contextClass: contextClass,
      contextProperty: contextProperty,
    ),
    final AliasModel aliasModel => buildSimpleValueExpression(
      value,
      model: aliasModel.model,
      isRequired: isRequired,
      nameManager: nameManager,
      package: package,
      contextClass: contextClass,
      contextProperty: contextProperty,
    ),
    NamedModel() => throw UnimplementedError('NamedModel is not supported'),
  };
}

Expression _buildFromSimpleExpression(
  Expression value,
  Model model,
  bool isRequired,
  NameManager nameManager, {
  String? package,
  String? contextClass,
  String? contextProperty,
}) {
  final name = nameManager.modelName(model);
  return isRequired
      ? refer(name, package).property('fromSimple').call([value])
      : value
          .equalTo(literalNull)
          .conditional(
            literalNull,
            refer(
              name,
              package,
            ).property('fromSimple').call([value.nullChecked]),
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
  String? package,
  String? contextClass,
  String? contextProperty,
}) {
  final content = model.content;
  final contextParam =
      (contextClass != null || contextProperty != null)
          ? {
            'context': literalString(
              (contextClass != null && contextProperty != null)
                  ? '$contextClass.$contextProperty'
                  : contextClass ?? contextProperty!,
              raw: true,
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
    ClassModel() =>
      throw UnimplementedError(
        'ClassModel is not supported in lists for simple encoding',
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
    ),
    ListModel() =>
      throw UnimplementedError(
        'Nested lists are not supported in simple encoding',
      ),
    AliasModel() => _buildListFromSimpleExpression(
      value,
      ListModel(content: content.model, context: model.context),
      isRequired,
      nameManager,
      package: package,
      contextClass: contextClass,
      contextProperty: contextProperty,
    ),
    NamedModel() => throw UnimplementedError('NamedModel is not supported'),
  };
}

Expression _buildPrimitiveList(
  Expression listDecode,
  String decodeMethod,
  bool isRequired, {
  Map<String, Expression> contextParam = const {},
}) {
  final mapFunction =
      Method(
        (b) =>
            b
              ..requiredParameters.add(Parameter((b) => b..name = 'e'))
              ..body =
                  refer('e').property(decodeMethod).call([], contextParam).code,
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
  String? package,
  String? contextClass,
  String? contextProperty,
}) {
  final className = nameManager.modelName(content);
  final mapFunction =
      Method(
        (b) =>
            b
              ..requiredParameters.add(Parameter((b) => b..name = 'e'))
              ..body =
                  refer(
                    className,
                    package,
                  ).property('fromSimple').call([refer('e')]).code,
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
