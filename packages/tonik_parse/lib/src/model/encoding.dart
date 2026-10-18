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
  factory fromJson(Map<String, dynamic> json) {
    final contentType = switch (json['contentType']) {
      final String value => value,
      _ => null,
    };
    final headers = _parseHeaders(json['headers']);
    final style = _optionalStyle(json['style']);
    final explode = switch (json['explode']) {
      final bool value => value,
      _ => null,
    };
    final allowReserved = switch (json['allowReserved']) {
      final bool value => value,
      _ => null,
    };

    final rawHeaders = json['headers'];
    final hasMalformedField =
        (json['contentType'] != null && contentType == null) ||
        (json['style'] != null && style == null) ||
        (json['explode'] != null && explode == null) ||
        (json['allowReserved'] != null && allowReserved == null) ||
        (rawHeaders != null &&
            (rawHeaders is! Map<String, dynamic> ||
                (rawHeaders.isNotEmpty && (headers?.isEmpty ?? true))));
    final hasUsableField =
        contentType != null ||
        (headers?.isNotEmpty ?? false) ||
        style != null ||
        explode != null ||
        allowReserved != null;
    if (hasMalformedField && !hasUsableField) {
      throw const FormatException('Encoding has no usable fields');
    }

    return Encoding(
      contentType: contentType,
      headers: headers,
      style: style,
      explode: explode,
      allowReserved: allowReserved,
    );
  }

  @override
  String toString() =>
      'Encoding{contentType: $contentType, headers: $headers, style: $style, '
      'explode: $explode, allowReserved: $allowReserved}';
}

SerializationStyle? _optionalStyle(Object? value) {
  if (value == null) return null;
  try {
    return SerializationStyle.fromJson(value);
  } on FormatException {
    return null;
  }
}

Map<String, ReferenceWrapper<Header>>? _parseHeaders(Object? value) {
  if (value is! Map<String, dynamic>) return null;
  final headers = <String, ReferenceWrapper<Header>>{};
  for (final entry in value.entries) {
    try {
      headers[entry.key] = ReferenceWrapper<Header>.fromJson(entry.value);
      // Optional header definitions use casts and format checks.
      // ignore: avoid_catching_errors
    } on TypeError catch (error) {
      if (error is MalformedReferenceError) rethrow;
      continue;
    } on FormatException {
      continue;
    }
  }
  return headers;
}
