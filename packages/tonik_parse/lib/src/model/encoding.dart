import 'package:tonik_parse/src/model/header.dart';
import 'package:tonik_parse/src/model/reference.dart';
import 'package:tonik_parse/src/model/serialization_style.dart';

class Encoding {
  Encoding({
    required this.contentType,
    required this.headers,
    required this.style,
    required this.explode,
    required this.allowReserved,
  });

  factory Encoding.fromJson(Map<String, dynamic> json) => Encoding(
    contentType: json['contentType'] as String?,
    headers: (json['headers'] as Map<String, dynamic>?)?.map(
      (k, e) => MapEntry(k, ReferenceWrapper<Header>.fromJson(e)),
    ),
    style: json['style'] == null
        ? null
        : SerializationStyle.fromJson(json['style']),
    explode: json['explode'] as bool?,
    allowReserved: json['allowReserved'] as bool?,
  );

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
