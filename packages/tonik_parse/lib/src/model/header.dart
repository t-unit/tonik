import 'package:json_annotation/json_annotation.dart';
import 'package:tonik_parse/src/model/media_type.dart';
import 'package:tonik_parse/src/model/reference.dart';
import 'package:tonik_parse/src/model/schema.dart';
import 'package:tonik_parse/src/model/serialization_style.dart';

part 'header.g.dart';

@JsonSerializable()
class Header {
  Header({
    required this.description,
    required this.isRequired,
    required this.isDeprecated,
    required this.style,
    required this.explode,
    required this.schema,
    required this.content,
  });

  factory Header.fromJson(Map<String, dynamic> json) => _$HeaderFromJson(json);

  final String? description;
  @JsonKey(name: 'required')
  final bool? isRequired;
  @JsonKey(name: 'deprecated')
  final bool? isDeprecated;
  final SerializationStyle? style;
  final bool? explode;
  final ReferenceWrapper<Schema>? schema;
  final Map<String, MediaType>? content;

  // We ignore the example and examples parameter.

  @override
  String toString() =>
      'Header{description: $description, isRequired: $isRequired, '
      'isDeprecated: $isDeprecated, style: $style, explode: $explode, '
      'schema: $schema, content: $content}';
}
