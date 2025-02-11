import 'package:json_annotation/json_annotation.dart';
import 'package:tonic_parse/src/model/media_type.dart';
import 'package:tonic_parse/src/model/reference.dart';
import 'package:tonic_parse/src/model/schema.dart';
import 'package:tonic_parse/src/model/serialization_style.dart';

part 'header.g.dart';

@JsonSerializable()
class Header {
  Header({
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

  factory Header.fromJson(Map<String, dynamic> json) => _$HeaderFromJson(json);

  final String? description;
  final bool? isRequired;
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
      'Header{description: $description, isRequired: $isRequired, '
      'isDeprecated: $isDeprecated, allowEmptyValue: $allowEmptyValue, '
      'style: $style, explode: $explode, allowReserved: $allowReserved, '
      'schema: $schema, content: $content}';
}
