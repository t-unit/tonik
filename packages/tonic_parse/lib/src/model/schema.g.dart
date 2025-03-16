// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schema.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Schema _$SchemaFromJson(Map<String, dynamic> json) => Schema(
      type: const _SchemaTypeConverter().fromJson(json['type']),
      format: json['format'] as String?,
      required: (json['required'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      enumerated: json['enum'] as List<dynamic>?,
      allOf: (json['allOf'] as List<dynamic>?)
          ?.map(ReferenceWrapper<Schema>.fromJson)
          .toList(),
      anyOf: (json['anyOf'] as List<dynamic>?)
          ?.map(ReferenceWrapper<Schema>.fromJson)
          .toList(),
      oneOf: (json['oneOf'] as List<dynamic>?)
          ?.map(ReferenceWrapper<Schema>.fromJson)
          .toList(),
      not: json['not'] == null
          ? null
          : ReferenceWrapper<Schema>.fromJson(json['not']),
      items: json['items'] == null
          ? null
          : ReferenceWrapper<Schema>.fromJson(json['items']),
      properties: (json['properties'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, ReferenceWrapper<Schema>.fromJson(e)),
      ),
      description: json['description'] as String?,
      isNullable: json['nullable'] as bool?,
      discriminator: json['discriminator'] == null
          ? null
          : Discriminator.fromJson(
              json['discriminator'] as Map<String, dynamic>),
      isDeprecated: json['deprecated'] as bool?,
      uniqueItems: json['uniqueItems'] as bool?,
    );

Map<String, dynamic> _$SchemaToJson(Schema instance) => <String, dynamic>{
      'type': const _SchemaTypeConverter().toJson(instance.type),
      'format': instance.format,
      'required': instance.required,
      'enum': instance.enumerated,
      'allOf': instance.allOf,
      'anyOf': instance.anyOf,
      'oneOf': instance.oneOf,
      'not': instance.not,
      'items': instance.items,
      'properties': instance.properties,
      'description': instance.description,
      'nullable': instance.isNullable,
      'discriminator': instance.discriminator,
      'deprecated': instance.isDeprecated,
      'uniqueItems': instance.uniqueItems,
    };
