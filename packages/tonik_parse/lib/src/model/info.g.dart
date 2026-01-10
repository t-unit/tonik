// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Info _$InfoFromJson(Map<String, dynamic> json) => Info(
  title: json['title'] as String,
  summary: json['summary'] as String?,
  description: json['description'] as String?,
  version: json['version'] as String,
  contact: json['contact'] == null
      ? null
      : Contact.fromJson(json['contact'] as Map<String, dynamic>),
  license: json['license'] == null
      ? null
      : License.fromJson(json['license'] as Map<String, dynamic>),
  termsOfService: json['termsOfService'] as String?,
);
