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
  parameters:
      (json['parameters'] as List<dynamic>?)
          ?.map(ReferenceWrapper<Parameter>.fromJson)
          .toList(),
  requestBody:
      json['requestBody'] == null
          ? null
          : ReferenceWrapper<RequestBody>.fromJson(json['requestBody']),
  responses: (json['responses'] as Map<String, dynamic>).map(
    (k, e) => MapEntry(k, ReferenceWrapper<Response>.fromJson(e)),
  ),
  isDeprecated: json['deprecated'] as bool?,
  servers:
      (json['servers'] as List<dynamic>?)
          ?.map((e) => Server.fromJson(e as Map<String, dynamic>))
          .toList(),
  security:
      (json['security'] as List<dynamic>?)
          ?.map(
            (e) => (e as Map<String, dynamic>).map(
              (k, e) => MapEntry(
                k,
                (e as List<dynamic>).map((e) => e as String).toList(),
              ),
            ),
          )
          .toList(),
);
