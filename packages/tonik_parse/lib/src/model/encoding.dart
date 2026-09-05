import 'package:tonik_parse/src/model/header.dart';
import 'package:tonik_parse/src/model/reference.dart';
import 'package:tonik_parse/src/model/serialization_style.dart';

class Encoding({
  required final String? contentType,
  required final Map<String, ReferenceWrapper<Header>>? headers,
  required final SerializationStyle? style,
  required final bool? explode,
  required final bool? allowReserved,
}) {
  factory fromJson(Map<String, dynamic> json) => Encoding(
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

  @override
  String toString() =>
      'Encoding{contentType: $contentType, headers: $headers, style: $style, '
      'explode: $explode, allowReserved: $allowReserved}';
}
