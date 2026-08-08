import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:meta/meta.dart';

/// One ordered part in a [TonikMultipartBody].
@immutable
final class TonikMultipartPart {
  /// Creates a multipart part from its already-encoded body bytes.
  TonikMultipartPart({
    required this.name,
    required List<int> bytes,
    required this.contentType,
    this.filename,
    Map<String, String> headers = const {},
  }) : bytes = List.unmodifiable(bytes),
       headers = Map.unmodifiable(headers);

  /// The multipart form field name.
  final String name;

  /// The encoded body bytes for this part.
  final List<int> bytes;

  /// The media type emitted for this part.
  final String contentType;

  /// The optional uploaded filename.
  final String? filename;

  /// Additional headers emitted for this part.
  final Map<String, String> headers;
}

/// A transport-neutral, fully encoded multipart request body.
@immutable
final class TonikMultipartBody {
  /// Creates a multipart body while preserving part order and duplicate names.
  TonikMultipartBody(
    List<TonikMultipartPart> parts, {
    String? boundary,
  }) : parts = List.unmodifiable(parts),
       boundary = boundary ?? _newBoundary() {
    _validateBoundary(this.boundary);
  }

  static final Random _random = Random();
  static const _boundaryCharacters =
      '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';

  /// The ordered multipart parts.
  final List<TonikMultipartPart> parts;

  /// The boundary separating the encoded parts.
  final String boundary;

  /// The request Content-Type value, including [boundary].
  String get contentType => 'multipart/form-data; boundary=$boundary';

  /// The complete RFC 7578 request body.
  late final List<int> bodyBytes = _encode();

  List<int> _encode() {
    final bytes = BytesBuilder(copy: false);
    for (final part in parts) {
      _validatePart(part);
      bytes
        ..add(ascii.encode('--$boundary\r\n'))
        ..add(
          latin1.encode(
            _partHeaders(part),
          ),
        )
        ..add(part.bytes)
        ..add(const [13, 10]);
    }
    bytes.add(ascii.encode('--$boundary--\r\n'));
    return bytes.takeBytes();
  }

  String _partHeaders(TonikMultipartPart part) {
    final filename = part.filename == null
        ? ''
        : '; filename="${_browserEncode(part.filename!)}"';
    final buffer = StringBuffer()
      ..writeln(
        'content-disposition: form-data; '
        'name="${_browserEncode(part.name)}"$filename\r',
      )
      ..writeln('content-type: ${part.contentType}\r');
    for (final entry in part.headers.entries) {
      buffer.writeln('${entry.key}: ${entry.value}\r');
    }
    buffer.writeln('\r');
    return buffer.toString();
  }

  static void _validateBoundary(String boundary) {
    if (boundary.isEmpty ||
        boundary.length > 70 ||
        boundary.contains('\r') ||
        boundary.contains('\n')) {
      throw FormatException('Invalid multipart boundary: $boundary');
    }
  }

  static void _validatePart(TonikMultipartPart part) {
    _validateHeaderValue('content-type', part.contentType);
    for (final entry in part.headers.entries) {
      if (!_headerName.hasMatch(entry.key)) {
        throw FormatException('Invalid multipart header name: ${entry.key}');
      }
      _validateHeaderValue(entry.key, entry.value);
    }
  }

  static final RegExp _headerName = RegExp(
    r"^[!#$%&'*+.^_`|~0-9A-Za-z-]+$",
  );

  static void _validateHeaderValue(String name, String value) {
    if (value.contains('\r') || value.contains('\n')) {
      throw FormatException('Invalid line break in multipart header $name');
    }
  }

  static String _browserEncode(String value) =>
      value.replaceAll(RegExp(r'\r\n|\r|\n'), '%0D%0A').replaceAll('"', '%22');

  static String _newBoundary() {
    final suffix = List.generate(
      48,
      (_) => _boundaryCharacters[_random.nextInt(_boundaryCharacters.length)],
    ).join();
    return 'tonik-$suffix';
  }
}
