import 'package:json_annotation/json_annotation.dart';
import 'package:tonik_parse/src/model/header.dart';
import 'package:tonik_parse/src/model/reference.dart';
import 'package:tonik_parse/src/model/serialization_style.dart';

part 'encoding.g.dart';

@JsonSerializable(createToJson: false)
class Encoding {
  Encoding({
    required this.contentType,
    required this.headers,
    required this.style,
    required this.explode,
    required this.allowReserved,
  });

  factory Encoding.fromJson(Map<String, dynamic> json) =>
      _$EncodingFromJson(json);

  final String? contentType;
  final Map<String, ReferenceWrapper<Header>>? headers;
  final SerializationStyle? style;
  final bool? explode;
  final bool? allowReserved;

  @override
  String toString() =>
      'Encoding{contentType: $contentType, headers: $headers, style: $style, '
      'explode: $explode, allowReserved: $allowReserved}';
}
