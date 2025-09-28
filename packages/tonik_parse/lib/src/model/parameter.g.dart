// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'parameter.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Parameter _$ParameterFromJson(Map<String, dynamic> json) => Parameter(
  name: json['name'] as String,
  location: $enumDecode(_$ParameterLocationEnumMap, json['in']),
  description: json['description'] as String?,
  isRequired: json['required'] as bool?,
  isDeprecated: json['deprecated'] as bool?,
  allowEmptyValue: json['allowEmptyValue'] as bool?,
  style: $enumDecodeNullable(_$SerializationStyleEnumMap, json['style']),
  explode: json['explode'] as bool?,
  allowReserved: json['allowReserved'] as bool?,
  schema:
      json['schema'] == null
          ? null
          : ReferenceWrapper<Schema>.fromJson(json['schema']),
  content: (json['content'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, MediaType.fromJson(e as Map<String, dynamic>)),
  ),
);

const _$ParameterLocationEnumMap = {
  ParameterLocation.query: 'query',
  ParameterLocation.header: 'header',
  ParameterLocation.path: 'path',
  ParameterLocation.cookie: 'cookie',
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
