// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schema.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Schema _$SchemaFromJson(Map<String, dynamic> json) => Schema(
  ref: json[r'$ref'] as String?,
  type: const _SchemaTypeConverter().fromJson(json['type']),
  format: json['format'] as String?,
  required: (json['required'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  enumerated: json['enum'] as List<dynamic>?,
  allOf: const _SchemaListConverter().fromJson(json['allOf'] as List?),
  anyOf: const _SchemaListConverter().fromJson(json['anyOf'] as List?),
  oneOf: const _SchemaListConverter().fromJson(json['oneOf'] as List?),
  not: const SchemaConverter().fromJson(json['not']),
  items: const SchemaConverter().fromJson(json['items']),
  properties: const SchemaMapConverter().fromJson(
    json['properties'] as Map<String, dynamic>?,
  ),
  description: json['description'] as String?,
  isNullable: json['nullable'] as bool?,
  discriminator: json['discriminator'] == null
      ? null
      : Discriminator.fromJson(json['discriminator'] as Map<String, dynamic>),
  isDeprecated: json['deprecated'] as bool?,
  uniqueItems: json['uniqueItems'] as bool?,
  xDartName: json['x-dart-name'] as String?,
  xDartEnum: (json['x-dart-enum'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  defs: const SchemaMapConverter().fromJson(
    json[r'$defs'] as Map<String, dynamic>?,
  ),
  contentEncoding: json['contentEncoding'] as String?,
  contentMediaType: json['contentMediaType'] as String?,
  contentSchema: const SchemaConverter().fromJson(json['contentSchema']),
);
