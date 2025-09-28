// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Info _$InfoFromJson(Map<String, dynamic> json) => Info(
  title: json['title'] as String,
  description: json['description'] as String?,
  version: json['version'] as String,
  contact: json['contact'] == null
      ? null
      : Contact(
          name: json['contact']['name'] as String?,
          url: json['contact']['url'] as String?,
          email: json['contact']['email'] as String?,
        ),
  license: json['license'] == null
      ? null
      : License(
          name: json['license']['name'] as String?,
          url: json['license']['url'] as String?,
        ),
  termsOfService: json['termsOfService'] as String?,
);

Map<String, dynamic> _$InfoToJson(Info instance) => <String, dynamic>{
  'title': instance.title,
  'description': instance.description,
  'version': instance.version,
  'contact': instance.contact == null
      ? null
      : {
          'name': instance.contact!.name,
          'url': instance.contact!.url,
          'email': instance.contact!.email,
        },
  'license': instance.license == null
      ? null
      : {
          'name': instance.license!.name,
          'url': instance.license!.url,
        },
  'termsOfService': instance.termsOfService,
};
