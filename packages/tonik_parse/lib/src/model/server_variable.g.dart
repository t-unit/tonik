// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'server_variable.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServerVariable _$ServerVariableFromJson(Map<String, dynamic> json) =>
    ServerVariable(
      defaultValue: json['default'] as String,
      enumValues: (json['enum'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      description: json['description'] as String?,
    );
