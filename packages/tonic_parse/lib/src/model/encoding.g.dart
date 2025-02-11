// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'encoding.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Encoding _$EncodingFromJson(Map<String, dynamic> json) => Encoding(
      contentType: json['contentType'] as String?,
      headers: (json['headers'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, ReferenceWrapper<Header>.fromJson(e)),
      ),
      style: $enumDecodeNullable(_$SerializationStyleEnumMap, json['style']),
      explode: json['explode'] as bool?,
      allowReserved: json['allowReserved'] as bool?,
    );

Map<String, dynamic> _$EncodingToJson(Encoding instance) => <String, dynamic>{
      'contentType': instance.contentType,
      'headers': instance.headers,
      'style': _$SerializationStyleEnumMap[instance.style],
      'explode': instance.explode,
      'allowReserved': instance.allowReserved,
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
