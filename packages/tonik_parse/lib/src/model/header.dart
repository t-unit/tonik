import 'package:tonik_parse/src/model/example.dart';
import 'package:tonik_parse/src/model/media_type.dart';
import 'package:tonik_parse/src/model/reference.dart';
import 'package:tonik_parse/src/model/schema.dart';
import 'package:tonik_parse/src/model/serialization_style.dart';

class Header {
  Header({
    required this.description,
    required this.isRequired,
    required this.isDeprecated,
    required this.style,
    required this.explode,
    required this.schema,
    required this.content,
    this.example,
    this.examples,
  });

  factory Header.fromJson(Map<String, dynamic> json) => Header(
    description: json['description'] as String?,
    isRequired: json['required'] as bool?,
    isDeprecated: json['deprecated'] as bool?,
    style: json['style'] == null
        ? null
        : SerializationStyle.fromJson(json['style']),
    explode: json['explode'] as bool?,
    schema: const SchemaConverter().fromJson(json['schema']),
    content: (json['content'] as Map<String, dynamic>?)?.map(
      (k, e) => MapEntry(k, MediaType.fromJson(e as Map<String, dynamic>)),
    ),
    example: json['example'],
    examples: (json['examples'] as Map<String, dynamic>?)?.map(
      (k, e) => MapEntry(k, ReferenceWrapper<Example>.fromJson(e)),
    ),
  );

  final String? description;
  final bool? isRequired;
  final bool? isDeprecated;
  final SerializationStyle? style;
  final bool? explode;
  final Schema? schema;
  final Map<String, MediaType>? content;

  /// Single example inline value.
  final Object? example;

  /// Multiple named examples; each value may be inline or a `$ref`.
  final Map<String, ReferenceWrapper<Example>>? examples;

  @override
  String toString() =>
      'Header{description: $description, isRequired: $isRequired, '
      'isDeprecated: $isDeprecated, style: $style, explode: $explode, '
      'schema: $schema, content: $content, '
      'example: $example, examples: $examples}';
}
