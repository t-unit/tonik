// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Response _$ResponseFromJson(Map<String, dynamic> json) => Response(
  description: json['description'] as String,
  headers: (json['headers'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, ReferenceWrapper<Header>.fromJson(e)),
  ),
  content: (json['content'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, MediaType.fromJson(e as Map<String, dynamic>)),
  ),
);
