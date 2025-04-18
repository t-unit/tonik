// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RequestBody _$RequestBodyFromJson(Map<String, dynamic> json) => RequestBody(
  description: json['description'] as String?,
  content: (json['content'] as Map<String, dynamic>).map(
    (k, e) => MapEntry(k, MediaType.fromJson(e as Map<String, dynamic>)),
  ),
  isRequired: json['required'] as bool?,
);

Map<String, dynamic> _$RequestBodyToJson(RequestBody instance) =>
    <String, dynamic>{
      'description': instance.description,
      'content': instance.content,
      'required': instance.isRequired,
    };
