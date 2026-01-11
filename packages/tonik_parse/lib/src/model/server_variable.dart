import 'package:json_annotation/json_annotation.dart';

part 'server_variable.g.dart';

@JsonSerializable(createToJson: false)
class ServerVariable {
  ServerVariable({
    required this.defaultValue,
    this.enumValues,
    this.description,
  });

  factory ServerVariable.fromJson(Map<String, dynamic> json) =>
      _$ServerVariableFromJson(json);

  @JsonKey(name: 'default')
  final String defaultValue;

  @JsonKey(name: 'enum')
  final List<String>? enumValues;

  final String? description;

  @override
  String toString() =>
      'ServerVariable{'
      'defaultValue: $defaultValue, '
      'enumValues: $enumValues, '
      'description: $description}';
}
