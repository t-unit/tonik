import 'dart:convert';
import 'dart:typed_data';

import 'package:test_helpers/test_helpers.dart';

final class MultipartWire {
  MultipartWire(RawRequest request) {
    final contentType = request.header('content-type');
    final boundaryMatch = contentType == null
        ? null
        : RegExp('boundary=(?:"([^"]+)"|([^;]+))').firstMatch(contentType);
    final boundary = boundaryMatch?.group(1) ?? boundaryMatch?.group(2);
    if (boundary == null) {
      throw StateError('Request has no multipart boundary: $contentType');
    }

    parts = request.bodyText
        .split('--$boundary')
        .where((segment) => segment.contains('\r\n\r\n'))
        .map(MultipartWirePart.new)
        .toList(growable: false);
  }

  late final List<MultipartWirePart> parts;

  List<MultipartWirePart> named(String name) =>
      parts.where((part) => part.name == name).toList(growable: false);

  MultipartWirePart single(String name) => named(name).single;
}

final class MultipartWirePart {
  MultipartWirePart(String segment) {
    final normalized = segment.startsWith('\r\n')
        ? segment.substring(2)
        : segment;
    final separator = normalized.indexOf('\r\n\r\n');
    headers = normalized.substring(0, separator);
    var payload = normalized.substring(separator + 4);
    if (payload.endsWith('\r\n')) {
      payload = payload.substring(0, payload.length - 2);
    }
    bodyBytes = Uint8List.fromList(latin1.encode(payload));

    name = RegExp(r'(?:^|;)\s*name="([^"]*)"').firstMatch(headers)?.group(1);
    filename = RegExp(
      r'(?:^|;)\s*filename="([^"]*)"',
    ).firstMatch(headers)?.group(1);
    contentType = RegExp(
      r'^content-type:\s*([^\r\n]+)',
      caseSensitive: false,
      multiLine: true,
    ).firstMatch(headers)?.group(1);
  }

  late final String headers;
  late final String? name;
  late final String? filename;
  late final String? contentType;
  late final Uint8List bodyBytes;

  String? header(String name) => RegExp(
    '^${RegExp.escape(name)}:\\s*([^\\r\\n]+)',
    caseSensitive: false,
    multiLine: true,
  ).firstMatch(headers)?.group(1);

  String get bodyText => utf8.decode(bodyBytes);
}
