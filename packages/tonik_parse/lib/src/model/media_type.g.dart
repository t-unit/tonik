// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_type.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MediaType _$MediaTypeFromJson(Map<String, dynamic> json) => MediaType(
  schema: const SchemaConverter().fromJson(json['schema']),
  encoding: (json['encoding'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, Encoding.fromJson(e as Map<String, dynamic>)),
  ),
);
