import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';

/// Creates a Dart expression that correctly deserializes a form-encoded value
/// to its Dart representation.
Expression buildFromFormValueExpression(
  Expression value, {
  required Model model,
  required bool isRequired,
  required NameManager nameManager,
  String? package,
  String? contextClass,
  String? contextProperty,
}) {
  final contextParam = _buildContextParam(contextClass, contextProperty);

  return switch (model) {
    StringModel() => value.property(
      isRequired ? 'decodeFormString' : 'decodeFormNullableString',
    ).call([], contextParam),
    
    IntegerModel() => value.property(
      isRequired ? 'decodeFormInt' : 'decodeFormNullableInt',
    ).call([], contextParam),
    
    DoubleModel() => value.property(
      isRequired ? 'decodeFormDouble' : 'decodeFormNullableDouble',
    ).call([], contextParam),
    
    NumberModel() => value.property(
      isRequired ? 'decodeFormDouble' : 'decodeFormNullableDouble',
    ).call([], contextParam),
    
    BooleanModel() => value.property(
      isRequired ? 'decodeFormBool' : 'decodeFormNullableBool',
    ).call([], contextParam),
    
    DateTimeModel() => value.property(
      isRequired ? 'decodeFormDateTime' : 'decodeFormNullableDateTime',
    ).call([], contextParam),
    
    DateModel() => value.property(
      isRequired ? 'decodeFormDate' : 'decodeFormNullableDate',
    ).call([], contextParam),
    
    DecimalModel() => value.property(
      isRequired ? 'decodeFormBigDecimal' : 'decodeFormNullableBigDecimal',
    ).call([], contextParam),
    
    UriModel() => value.property(
      isRequired ? 'decodeFormUri' : 'decodeFormNullableUri',
    ).call([], contextParam),
    
    AliasModel() => buildFromFormValueExpression(
      value,
      model: model.model,
      isRequired: isRequired,
      nameManager: nameManager,
      package: package,
      contextClass: contextClass,
      contextProperty: contextProperty,
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
    ),
    
    ListModel() => 
      throw UnsupportedError('Form decoding not supported for complex types'),
    
    _ => throw UnimplementedError('Unsupported model type: $model'),
  };
}

Expression _buildFromFormExpression(
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
      ? refer(name, package).property('fromForm').call([value])
      : value
          .equalTo(literalNull)
          .conditional(
            literalNull,
            refer(name, package).property('fromForm').call([value]),
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
    
    return {'context': literalString(contextString, raw: true)};
  }
  return <String, Expression>{};
}
