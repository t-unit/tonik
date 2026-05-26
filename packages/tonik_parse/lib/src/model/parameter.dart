import 'package:tonik_parse/src/model/example.dart';
import 'package:tonik_parse/src/model/media_type.dart';
import 'package:tonik_parse/src/model/reference.dart';
import 'package:tonik_parse/src/model/schema.dart';
import 'package:tonik_parse/src/model/serialization_style.dart';

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
    required this.xDartName,
    this.example,
    this.examples,
  });

  factory Parameter.fromJson(Map<String, dynamic> json) => Parameter(
    name: json['name'] as String,
    location: ParameterLocation.fromJson(json['in']),
    description: json['description'] as String?,
    isRequired: json['required'] as bool?,
    isDeprecated: json['deprecated'] as bool?,
    allowEmptyValue: json['allowEmptyValue'] as bool?,
    style: json['style'] == null
        ? null
        : SerializationStyle.fromJson(json['style']),
    explode: json['explode'] as bool?,
    allowReserved: json['allowReserved'] as bool?,
    schema: const SchemaConverter().fromJson(json['schema']),
    content: (json['content'] as Map<String, dynamic>?)?.map(
      (k, e) => MapEntry(k, MediaType.fromJson(e as Map<String, dynamic>)),
    ),
    xDartName: json['x-dart-name'] as String?,
    example: json['example'],
    examples: (json['examples'] as Map<String, dynamic>?)?.map(
      (k, e) => MapEntry(k, ReferenceWrapper<Example>.fromJson(e)),
    ),
  );

  final String name;
  final ParameterLocation location;
  final String? description;
  final bool? isRequired;
  final bool? isDeprecated;
  final bool? allowEmptyValue;
  final SerializationStyle? style;
  final bool? explode;
  final bool? allowReserved;
  final Schema? schema;
  final Map<String, MediaType>? content;
  final String? xDartName;

  /// Single example inline value.
  final Object? example;

  /// Multiple named examples; each value may be inline or a `$ref`.
  final Map<String, ReferenceWrapper<Example>>? examples;

  @override
  String toString() =>
      'Parameter{name: $name, location: $location, description: $description, '
      'isRequired: $isRequired, isDeprecated: $isDeprecated, '
      'allowEmptyValue: $allowEmptyValue, style: $style, explode: $explode, '
      'allowReserved: $allowReserved, schema: $schema, content: $content, '
      'xDartName: $xDartName, example: $example, examples: $examples}';
}

enum ParameterLocation {
  query,
  header,
  path,
  cookie;

  static ParameterLocation fromJson(Object? value) => switch (value) {
    'query' => ParameterLocation.query,
    'header' => ParameterLocation.header,
    'path' => ParameterLocation.path,
    'cookie' => ParameterLocation.cookie,
    _ => throw FormatException('Invalid ParameterLocation: $value'),
  };
}
