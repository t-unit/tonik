import 'package:tonik_parse/src/model/encoding.dart';
import 'package:tonik_parse/src/model/example.dart';
import 'package:tonik_parse/src/model/reference.dart';
import 'package:tonik_parse/src/model/schema.dart';

class MediaType({
  required final Schema? schema,
  required final Map<String, Encoding>? encoding,
  final Schema? itemSchema,

  /// Single example inline value.
  final Object? example,

  /// Multiple named examples; each value may be inline or a `$ref`.
  final Map<String, ReferenceWrapper<Example>>? examples,
}) {
  factory fromJson(Map<String, dynamic> json) => MediaType(
    schema: _optional(() => const SchemaConverter().fromJson(json['schema'])),
    itemSchema: _optional(
      () => const SchemaConverter().fromJson(json['itemSchema']),
    ),
    encoding: _optionalMap(
      json['encoding'],
      (value) => Encoding.fromJson(value! as Map<String, dynamic>),
    ),
    example: json['example'],
    examples: _optionalMap(
      json['examples'],
      ReferenceWrapper<Example>.fromJson,
    ),
  );

  @override
  String toString() =>
      'MediaType{schema: $schema, itemSchema: $itemSchema, '
      'encoding: $encoding, '
      'example: $example, examples: $examples}';
}

T? _optional<T>(T? Function() parse) {
  try {
    return parse();
    // Optional media fields use casts and format checks while parsing JSON.
    // ignore: avoid_catching_errors
  } on TypeError catch (error) {
    if (error is MalformedReferenceError) rethrow;
    return null;
  } on FormatException {
    return null;
  }
}

Map<String, T>? _optionalMap<T>(Object? value, T Function(Object?) parse) {
  if (value is! Map<String, dynamic>) return null;
  return {
    for (final entry in value.entries)
      if (_optional(() => parse(entry.value)) case final T parsed)
        entry.key: parsed,
  };
}
