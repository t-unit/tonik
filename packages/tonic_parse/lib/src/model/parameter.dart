import 'package:json_annotation/json_annotation.dart';
import 'package:tonic_parse/src/model/media_type.dart';
import 'package:tonic_parse/src/model/reference.dart';
import 'package:tonic_parse/src/model/schema.dart';
import 'package:tonic_parse/src/model/serialization_style.dart';

part 'parameter.g.dart';

@JsonSerializable()
class Parameter {
  Parameter({
    required this.name,
    required this.location,
    required this.description,
    required this.isRequired,
    required this.isDeprecated,
    required this.allowEmptyValue,
    required this.style,
    required this.explode,
    required this.allowReserved,
    required this.schema,
    required this.content,
  });

  factory Parameter.fromJson(Map<String, dynamic> json) =>
      _$ParameterFromJson(json);

  final String name;
  @JsonKey(name: 'in')
  final ParameterLocation location;
  final String? description;
  @JsonKey(name: 'required')
  final bool? isRequired;
  @JsonKey(name: 'deprecated')
  final bool? isDeprecated;
  final bool? allowEmptyValue;
  final SerializationStyle? style;
  final bool? explode;
  final bool? allowReserved;
  final ReferenceWrapper<Schema>? schema;
  final Map<String, MediaType>? content;

  // We ignore the example and examples parameter.

  @override
  String toString() =>
      'Parameter{name: $name, location: $location, description: $description, '
      'isRequired: $isRequired, isDeprecated: $isDeprecated, '
      'allowEmptyValue: $allowEmptyValue, style: $style, explode: $explode, '
      'allowReserved: $allowReserved, schema: $schema, content: $content}';
}

enum ParameterLocation { query, header, path, cookie }
