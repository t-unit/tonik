// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'open_api_object.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OpenApiObject _$OpenApiObjectFromJson(Map<String, dynamic> json) =>
    OpenApiObject(
      info: Info.fromJson(json['info'] as Map<String, dynamic>),
      servers: (json['servers'] as List<dynamic>?)
          ?.map((e) => Server.fromJson(e as Map<String, dynamic>))
          .toList(),
      paths: (json['paths'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, ReferenceWrapper<PathItem>.fromJson(e)),
      ),
      components: json['components'] == null
          ? null
          : Components.fromJson(json['components'] as Map<String, dynamic>),
      tags: (json['tags'] as List<dynamic>?)
          ?.map((e) => Tag.fromJson(e as Map<String, dynamic>))
          .toList(),
      externalDocs: json['externalDocs'] == null
          ? null
          : ExternalDocumentation.fromJson(
              json['externalDocs'] as Map<String, dynamic>,
            ),
    );
