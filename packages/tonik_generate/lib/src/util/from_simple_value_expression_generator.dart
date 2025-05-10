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
}) {
  return switch (model) {
    StringModel() =>
      isRequired
          ? value.property('decodeSimpleString').call([])
          : value.property('decodeSimpleNullableString').call([]),
    IntegerModel() =>
      isRequired
          ? value.property('decodeSimpleInt').call([])
          : value.property('decodeSimpleNullableInt').call([]),
    NumberModel() =>
      isRequired
          ? value.property('decodeSimpleDouble').call([])
          : value.property('decodeSimpleNullableDouble').call([]),
    DoubleModel() =>
      isRequired
          ? value.property('decodeSimpleDouble').call([])
          : value.property('decodeSimpleNullableDouble').call([]),
    DecimalModel() =>
      isRequired
          ? value.property('decodeSimpleBigDecimal').call([])
          : value.property('decodeSimpleNullableBigDecimal').call([]),
    BooleanModel() =>
      isRequired
          ? value.property('decodeSimpleBool').call([])
          : value.property('decodeSimpleNullableBool').call([]),
    DateTimeModel() =>
      isRequired
          ? value.property('decodeSimpleDateTime').call([])
          : value.property('decodeSimpleNullableDateTime').call([]),
    DateModel() =>
      isRequired
          ? value.property('decodeSimpleDate').call([])
          : value.property('decodeSimpleNullableDate').call([]),
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
    ),
    final ListModel listModel => _buildListFromSimpleExpression(
      value,
      listModel,
      isRequired,
      nameManager,
      package: package,
    ),
    final AliasModel aliasModel => buildSimpleValueExpression(
      value,
      model: aliasModel.model,
      isRequired: isRequired,
      nameManager: nameManager,
      package: package,
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

Expression _buildListDecode(Expression value, bool isRequired) {
  return value
      .property(
        isRequired
            ? 'decodeSimpleStringList'
            : 'decodeSimpleNullableStringList',
      )
      .call([]);
}

Expression _buildListFromSimpleExpression(
  Expression value,
  ListModel model,
  bool isRequired,
  NameManager nameManager, {
  String? package,
}) {
  final content = model.content;
  final listDecode = _buildListDecode(value, isRequired);

  return switch (content) {
    StringModel() => listDecode,
    IntegerModel() => _buildPrimitiveList(
      listDecode,
      'decodeSimpleInt',
      isRequired,
    ),
    NumberModel() => _buildPrimitiveList(
      listDecode,
      'decodeSimpleDouble',
      isRequired,
    ),
    DoubleModel() => _buildPrimitiveList(
      listDecode,
      'decodeSimpleDouble',
      isRequired,
    ),
    DecimalModel() => _buildPrimitiveList(
      listDecode,
      'decodeSimpleBigDecimal',
      isRequired,
    ),
    BooleanModel() => _buildPrimitiveList(
      listDecode,
      'decodeSimpleBool',
      isRequired,
    ),
    DateTimeModel() => _buildPrimitiveList(
      listDecode,
      'decodeSimpleDateTime',
      isRequired,
    ),
    DateModel() => _buildPrimitiveList(
      listDecode,
      'decodeSimpleDate',
      isRequired,
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
    ),
    NamedModel() => throw UnimplementedError('NamedModel is not supported'),
  };
}

Expression _buildPrimitiveList(
  Expression listDecode,
  String decodeMethod,
  bool isRequired,
) {
  final mapFunction =
      Method(
        (b) =>
            b
              ..requiredParameters.add(Parameter((b) => b..name = 'e'))
              ..body = refer('e').property(decodeMethod).call([]).code,
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
