// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'components.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Components _$ComponentsFromJson(Map<String, dynamic> json) => Components(
  schemas: (json['schemas'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, ReferenceWrapper<Schema>.fromJson(e)),
  ),
  responses: (json['responses'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, ReferenceWrapper<Response>.fromJson(e)),
  ),
  parameters: (json['parameters'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, ReferenceWrapper<Parameter>.fromJson(e)),
  ),
  requestBodies: (json['requestBodies'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, ReferenceWrapper<RequestBody>.fromJson(e)),
  ),
  headers: (json['headers'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, ReferenceWrapper<Header>.fromJson(e)),
  ),
  securitySchemes: (json['securitySchemes'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, ReferenceWrapper<SecurityScheme>.fromJson(e)),
  ),
  pathItems: (json['pathItems'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, ReferenceWrapper<PathItem>.fromJson(e)),
  ),
);
