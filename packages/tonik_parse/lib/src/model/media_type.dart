import 'package:json_annotation/json_annotation.dart';
import 'package:tonik_parse/src/model/encoding.dart';
import 'package:tonik_parse/src/model/reference.dart';
import 'package:tonik_parse/src/model/schema.dart';

part 'media_type.g.dart';

@JsonSerializable(createToJson: false)
class MediaType {
  MediaType({required this.schema, required this.encoding});

  factory MediaType.fromJson(Map<String, dynamic> json) =>
      _$MediaTypeFromJson(json);

  final ReferenceWrapper<Schema>? schema;
  final Map<String, Encoding>? encoding;

  // We ignore the example and examples properties.

  @override
  String toString() => 'MediaType{schema: $schema, encoding: $encoding}';
}
