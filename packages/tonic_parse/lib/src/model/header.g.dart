// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'header.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Header _$HeaderFromJson(Map<String, dynamic> json) => Header(
      description: json['description'] as String?,
      isRequired: json['isRequired'] as bool?,
      isDeprecated: json['isDeprecated'] as bool?,
      allowEmptyValue: json['allowEmptyValue'] as bool?,
      style: $enumDecodeNullable(_$SerializationStyleEnumMap, json['style']),
      explode: json['explode'] as bool?,
      allowReserved: json['allowReserved'] as bool?,
      schema: json['schema'] == null
          ? null
          : ReferenceWrapper<Schema>.fromJson(json['schema']),
      content: (json['content'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, MediaType.fromJson(e as Map<String, dynamic>)),
      ),
    );

Map<String, dynamic> _$HeaderToJson(Header instance) => <String, dynamic>{
      'description': instance.description,
      'isRequired': instance.isRequired,
      'isDeprecated': instance.isDeprecated,
      'allowEmptyValue': instance.allowEmptyValue,
      'style': _$SerializationStyleEnumMap[instance.style],
      'explode': instance.explode,
      'allowReserved': instance.allowReserved,
      'schema': instance.schema,
      'content': instance.content,
    };

const _$SerializationStyleEnumMap = {
  SerializationStyle.matrix: 'matrix',
  SerializationStyle.label: 'label',
  SerializationStyle.form: 'form',
  SerializationStyle.simple: 'simple',
  SerializationStyle.spaceDelimited: 'spaceDelimited',
  SerializationStyle.pipeDelimited: 'pipeDelimited',
  SerializationStyle.deepObject: 'deepObject',
};
