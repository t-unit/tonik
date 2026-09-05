import 'package:tonik_parse/src/model/encoding.dart';
import 'package:tonik_parse/src/model/example.dart';
import 'package:tonik_parse/src/model/reference.dart';
import 'package:tonik_parse/src/model/schema.dart';

class MediaType({
  required final Schema? schema,
  required final Map<String, Encoding>? encoding,

  /// Single example inline value.
  final Object? example,

  /// Multiple named examples; each value may be inline or a `$ref`.
  final Map<String, ReferenceWrapper<Example>>? examples,
}) {
  factory fromJson(Map<String, dynamic> json) => MediaType(
    schema: const SchemaConverter().fromJson(json['schema']),
    encoding: (json['encoding'] as Map<String, dynamic>?)?.map(
      (k, e) => MapEntry(k, Encoding.fromJson(e as Map<String, dynamic>)),
    ),
    example: json['example'],
    examples: (json['examples'] as Map<String, dynamic>?)?.map(
      (k, e) => MapEntry(k, ReferenceWrapper<Example>.fromJson(e)),
    ),
  );

  @override
  String toString() =>
      'MediaType{schema: $schema, encoding: $encoding, '
      'example: $example, examples: $examples}';
}
