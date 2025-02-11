// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Info _$InfoFromJson(Map<String, dynamic> json) => Info(
      title: json['title'] as String,
      description: json['description'] as String?,
      version: json['version'] as String,
    );

Map<String, dynamic> _$InfoToJson(Info instance) => <String, dynamic>{
      'title': instance.title,
      'description': instance.description,
      'version': instance.version,
    };
