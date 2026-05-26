import 'package:json_annotation/json_annotation.dart';
import 'package:tonik_parse/src/model/encoding.dart';
import 'package:tonik_parse/src/model/example.dart';
import 'package:tonik_parse/src/model/reference.dart';
import 'package:tonik_parse/src/model/schema.dart';

part 'media_type.g.dart';

@JsonSerializable(createToJson: false)
class MediaType {
  MediaType({
    required this.schema,
    required this.encoding,
    this.example,
    this.examples,
  });

  factory MediaType.fromJson(Map<String, dynamic> json) =>
      _$MediaTypeFromJson(json);

  @SchemaConverter()
  final Schema? schema;
  final Map<String, Encoding>? encoding;

  /// Single example inline value.
  final Object? example;

  /// Multiple named examples; each value may be inline or a `$ref`.
  final Map<String, ReferenceWrapper<Example>>? examples;

  @override
  String toString() =>
      'MediaType{schema: $schema, encoding: $encoding, '
      'example: $example, examples: $examples}';
}
