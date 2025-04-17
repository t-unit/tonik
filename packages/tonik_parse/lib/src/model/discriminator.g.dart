// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'discriminator.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Discriminator _$DiscriminatorFromJson(Map<String, dynamic> json) =>
    Discriminator(
      propertyName: json['propertyName'] as String,
      mapping: (json['mapping'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
    );

Map<String, dynamic> _$DiscriminatorToJson(Discriminator instance) =>
    <String, dynamic>{
      'propertyName': instance.propertyName,
      'mapping': instance.mapping,
    };
