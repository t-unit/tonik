import 'package:tonik_parse/src/model/example.dart';
import 'package:tonik_parse/src/model/media_type.dart';
import 'package:tonik_parse/src/model/reference.dart';
import 'package:tonik_parse/src/model/schema.dart';
import 'package:tonik_parse/src/model/serialization_style.dart';

class Parameter({
  required final String name,
  required final ParameterLocation location,
  required final String? description,
  required final bool? isRequired,
  required final bool? isDeprecated,
  required final bool? allowEmptyValue,
  required final SerializationStyle? style,
  required final bool? explode,
  required final bool? allowReserved,
  required final Schema? schema,
  required final Map<String, MediaType>? content,
  required final String? xDartName,

  /// Single example inline value.
  final Object? example,

  /// Multiple named examples; each value may be inline or a `$ref`.
  final Map<String, ReferenceWrapper<Example>>? examples,
}) {
  factory fromJson(Map<String, dynamic> json) => Parameter(
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

  @override
  String toString() =>
      'Parameter{name: $name, location: $location, description: $description, '
      'isRequired: $isRequired, isDeprecated: $isDeprecated, '
      'allowEmptyValue: $allowEmptyValue, style: $style, explode: $explode, '
      'allowReserved: $allowReserved, schema: $schema, content: $content, '
      'xDartName: $xDartName, example: $example, examples: $examples}';
}

enum ParameterLocation() {
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
