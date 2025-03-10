// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'operation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Operation _$OperationFromJson(Map<String, dynamic> json) => Operation(
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      summary: json['summary'] as String?,
      description: json['description'] as String?,
      operationId: json['operationId'] as String?,
      parameters: (json['parameters'] as List<dynamic>?)
          ?.map(ReferenceWrapper<Parameter>.fromJson)
          .toList(),
      requestBody: json['requestBody'] == null
          ? null
          : ReferenceWrapper<RequestBody>.fromJson(json['requestBody']),
      responses: (json['responses'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, ReferenceWrapper<Response>.fromJson(e)),
      ),
      isDeprecated: json['deprecated'] as bool?,
      servers: (json['servers'] as List<dynamic>?)
          ?.map((e) => Server.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$OperationToJson(Operation instance) => <String, dynamic>{
      'tags': instance.tags,
      'summary': instance.summary,
      'description': instance.description,
      'operationId': instance.operationId,
      'parameters': instance.parameters,
      'requestBody': instance.requestBody,
      'responses': instance.responses,
      'deprecated': instance.isDeprecated,
      'servers': instance.servers,
    };
