import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';

/// Creates a Dart expression that correctly deserializes a JSON value
/// to its Dart representation.
Expression buildFromJsonValueExpression(
  String value, {
  required Model model,
  required NameManager nameManager,
  required String package,
}) {
  return switch (model) {
    StringModel() => refer(value).property('decodeJsonString').call([]),
    IntegerModel() => refer(value).property('decodeJsonInt').call([]),
    NumberModel() => refer(value).property('decodeJsonNum').call([]),
    DoubleModel() => refer(value).property('decodeJsonDouble').call([]),
    DecimalModel() => refer(value).property('decodeJsonBigDecimal').call([]),
    BooleanModel() => refer(value).property('decodeJsonBool').call([]),
    DateTimeModel() => refer(value).property('decodeJsonDateTime').call([]),
    DateModel() => refer(value).property('decodeJsonDate').call([]),
    EnumModel() ||
    ClassModel() ||
    AllOfModel() ||
    OneOfModel() ||
    AnyOfModel() => _buildFromJsonExpression(
      value,
      model,
      nameManager,
      package: package,
    ),
    ListModel() => _buildListFromJsonExpression(
      value,
      model,
      nameManager,
      package: package,
    ),
    AliasModel() => buildFromJsonValueExpression(
      value,
      model: model.model,
      nameManager: nameManager,
      package: package,
    ),
    NamedModel() => throw UnimplementedError('NamedModel is not supported'),
  };
}

Expression _buildFromJsonExpression(
  String value,
  Model model,
  NameManager nameManager, {
  String? package,
}) {
  final name = nameManager.modelName(model);
  return refer(name, package).property('fromJson').call([refer(value)]);
}

Expression _buildListDecode(String value, String type) {
  return refer(
    value,
  ).property('decodeJsonList').call([], {}, [refer(type, 'dart:core')]);
}

Expression _buildStringListMap(String value, String decodeMethod) {
  final mapFunction =
      Method(
        (b) =>
            b
              ..requiredParameters.add(Parameter((b) => b..name = 'e'))
              ..body = refer('e').property(decodeMethod).call([]).code,
      ).closure;

  return _buildListDecode(
    value,
    'String',
  ).property('map').call([mapFunction]).property('toList').call([]);
}

Expression _buildNestedList(
  String value,
  ListModel content,
  NameManager nameManager, {
  String? package,
}) {
  final mapFunction =
      Method(
        (b) =>
            b
              ..requiredParameters.add(Parameter((b) => b..name = 'e'))
              ..body =
                  _buildListFromJsonExpression(
                    'e',
                    content,
                    nameManager,
                    package: package,
                  ).code,
      ).closure;

  return _buildListDecode(
    value,
    'Object?',
  ).property('map').call([mapFunction]).property('toList').call([]);
}

Expression _buildClassList(
  String value,
  Model content,
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
                  ).property('fromJson').call([refer('e')]).code,
      ).closure;

  return _buildListDecode(
    value,
    'Object?',
  ).property('map').call([mapFunction]).property('toList').call([]);
}

Expression _buildListFromJsonExpression(
  String value,
  ListModel model,
  NameManager nameManager, {
  String? package,
}) {
  final content = model.content;

  return switch (content) {
    IntegerModel() => _buildListDecode(value, 'int'),
    NumberModel() => _buildListDecode(value, 'num'),
    DoubleModel() => _buildListDecode(value, 'double'),
    DecimalModel() => _buildStringListMap(value, 'decodeJsonBigDecimal'),
    StringModel() => _buildListDecode(value, 'String'),
    BooleanModel() => _buildListDecode(value, 'bool'),
    DateTimeModel() => _buildStringListMap(value, 'decodeJsonDateTime'),
    DateModel() => _buildStringListMap(value, 'decodeJsonDate'),
    ListModel() => _buildNestedList(
      value,
      content,
      nameManager,
      package: package,
    ),
    ClassModel() ||
    AllOfModel() ||
    OneOfModel() ||
    AnyOfModel() ||
    EnumModel() => _buildClassList(
      value,
      content,
      nameManager,
      package: package,
    ),
    AliasModel() => _buildListFromJsonExpression(
      value,
      ListModel(content: content.model, context: model.context),
      nameManager,
      package: package,
    ),
    NamedModel() => throw UnimplementedError('NamedModel is not supported'),
  };
}
