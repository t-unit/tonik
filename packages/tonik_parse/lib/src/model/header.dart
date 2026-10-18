import 'package:tonik_parse/src/model/example.dart';
import 'package:tonik_parse/src/model/media_type.dart';
import 'package:tonik_parse/src/model/reference.dart';
import 'package:tonik_parse/src/model/schema.dart';
import 'package:tonik_parse/src/model/serialization_style.dart';

class Header({
  required final String? description,
  required final bool? isRequired,
  required final bool? isDeprecated,
  required final SerializationStyle? style,
  required final bool? explode,
  required final Schema? schema,
  required final Map<String, ReferenceWrapper<MediaType>>? content,

  /// Single example inline value.
  final Object? example,

  /// Multiple named examples; each value may be inline or a `$ref`.
  final Map<String, ReferenceWrapper<Example>>? examples,
}) {
  factory fromJson(Map<String, dynamic> json) => Header(
    description: json['description'] is String
        ? json['description'] as String
        : null,
    isRequired: json['required'] is bool ? json['required'] as bool : null,
    isDeprecated: json['deprecated'] is bool
        ? json['deprecated'] as bool
        : null,
    style: _optionalStyle(json['style']),
    explode: json['explode'] is bool ? json['explode'] as bool : null,
    schema: _optionalSchema(json['schema']),
    content: _optionalReferences<MediaType>(json['content']),
    example: json['example'],
    examples: _optionalReferences<Example>(json['examples']),
  );

  @override
  String toString() =>
      'Header{description: $description, isRequired: $isRequired, '
      'isDeprecated: $isDeprecated, style: $style, explode: $explode, '
      'schema: $schema, content: $content, '
      'example: $example, examples: $examples}';
}

SerializationStyle? _optionalStyle(Object? value) {
  if (value == null) return null;
  try {
    return SerializationStyle.fromJson(value);
  } on FormatException {
    return null;
  }
}

Schema? _optionalSchema(Object? value) {
  try {
    return const SchemaConverter().fromJson(value);
    // Optional schemas use casts and format checks during parsing.
    // ignore: avoid_catching_errors
  } on TypeError catch (error) {
    if (error is MalformedReferenceError) rethrow;
    return null;
  } on FormatException {
    return null;
  }
}

Map<String, ReferenceWrapper<T>>? _optionalReferences<T>(Object? value) {
  if (value is! Map<String, dynamic>) return null;
  final entries = <String, ReferenceWrapper<T>>{};
  for (final entry in value.entries) {
    try {
      entries[entry.key] = ReferenceWrapper<T>.fromJson(entry.value);
      // Optional references use casts and format checks during parsing.
      // ignore: avoid_catching_errors
    } on TypeError catch (error) {
      if (error is MalformedReferenceError) rethrow;
    } on FormatException {
      continue;
    }
  }
  return entries;
}
