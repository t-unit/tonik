import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';

/// Creates a Dart expression that correctly deserializes a form value
/// to its Dart representation.
Expression buildFormSimpleValueExpression(
  ResponseHeader header, {
  required NameManager nameManager,
  required String package,
  required String headerName,
}) {
  final resolved = header.resolve();
  final headerValue = refer('response')
      .property('headers')
      .property('value')
      .call([literalString(headerName, raw: true)]);

  return switch (resolved.model) {
    StringModel() =>
      resolved.isRequired
          ? headerValue.property('decodeSimpleString').call([])
          : headerValue.property('decodeSimpleNullableString').call([]),
    IntegerModel() =>
      resolved.isRequired
          ? headerValue.property('decodeSimpleInt').call([])
          : headerValue.property('decodeSimpleNullableInt').call([]),
    NumberModel() =>
      resolved.isRequired
          ? headerValue.property('decodeSimpleDouble').call([])
          : headerValue.property('decodeSimpleNullableDouble').call([]),
    DoubleModel() =>
      resolved.isRequired
          ? headerValue.property('decodeSimpleDouble').call([])
          : headerValue.property('decodeSimpleNullableDouble').call([]),
    DecimalModel() =>
      resolved.isRequired
          ? headerValue.property('decodeSimpleBigDecimal').call([])
          : headerValue.property('decodeSimpleNullableBigDecimal').call([]),
    BooleanModel() =>
      resolved.isRequired
          ? headerValue.property('decodeSimpleBool').call([])
          : headerValue.property('decodeSimpleNullableBool').call([]),
    DateTimeModel() =>
      resolved.isRequired
          ? headerValue.property('decodeSimpleDateTime').call([])
          : headerValue.property('decodeSimpleNullableDateTime').call([]),
    DateModel() =>
      resolved.isRequired
          ? headerValue.property('decodeSimpleDate').call([])
          : headerValue.property('decodeSimpleNullableDate').call([]),
    EnumModel() ||
    ClassModel() ||
    AllOfModel() ||
    OneOfModel() ||
    AnyOfModel() => _buildFromSimpleExpression(
      headerValue,
      resolved.model,
      resolved.isRequired,
      nameManager,
      package: package,
    ),
    final ListModel listModel => _buildListFromSimpleExpression(
      headerValue,
      listModel,
      resolved.isRequired,
      nameManager,
      package: package,
    ),
    final AliasModel aliasModel => buildFormSimpleValueExpression(
      ResponseHeaderObject(
        name: resolved.name!,
        context: resolved.context,
        description: resolved.description,
        explode: resolved.explode,
        model: aliasModel.model,
        isRequired: resolved.isRequired,
        isDeprecated: resolved.isDeprecated,
        encoding: resolved.encoding,
      ),
      nameManager: nameManager,
      package: package,
      headerName: headerName,
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
