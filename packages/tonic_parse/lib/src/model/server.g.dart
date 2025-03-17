// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'server.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Server _$ServerFromJson(Map<String, dynamic> json) => Server(
  url: json['url'] as String,
  description: json['description'] as String?,
);

Map<String, dynamic> _$ServerToJson(Server instance) => <String, dynamic>{
  'url': instance.url,
  'description': instance.description,
};
