// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'path_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PathItem _$PathItemFromJson(Map<String, dynamic> json) => PathItem(
      summary: json['summary'] as String?,
      description: json['description'] as String?,
      get: json['get'] == null
          ? null
          : Operation.fromJson(json['get'] as Map<String, dynamic>),
      put: json['put'] == null
          ? null
          : Operation.fromJson(json['put'] as Map<String, dynamic>),
      post: json['post'] == null
          ? null
          : Operation.fromJson(json['post'] as Map<String, dynamic>),
      delete: json['delete'] == null
          ? null
          : Operation.fromJson(json['delete'] as Map<String, dynamic>),
      patch: json['patch'] == null
          ? null
          : Operation.fromJson(json['patch'] as Map<String, dynamic>),
      parameters: (json['parameters'] as List<dynamic>?)
          ?.map(ReferenceWrapper<Parameter>.fromJson)
          .toList(),
      head: json['head'] == null
          ? null
          : Operation.fromJson(json['head'] as Map<String, dynamic>),
      options: json['options'] == null
          ? null
          : Operation.fromJson(json['options'] as Map<String, dynamic>),
      servers: (json['servers'] as List<dynamic>?)
          ?.map((e) => Server.fromJson(e as Map<String, dynamic>))
          .toList(),
      trace: json['trace'] == null
          ? null
          : Operation.fromJson(json['trace'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PathItemToJson(PathItem instance) => <String, dynamic>{
      'summary': instance.summary,
      'description': instance.description,
      'get': instance.get,
      'put': instance.put,
      'post': instance.post,
      'delete': instance.delete,
      'patch': instance.patch,
      'head': instance.head,
      'options': instance.options,
      'trace': instance.trace,
      'servers': instance.servers,
      'parameters': instance.parameters,
    };
