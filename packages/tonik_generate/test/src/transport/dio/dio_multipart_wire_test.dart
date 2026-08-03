import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:mime/mime.dart';
import 'package:test/test.dart';

void main() {
  test(
    'decoded Dio multipart body preserves exact ordered duplicate parts',
    () async {
      final form = FormData()
        ..files.addAll([
          MapEntry(
            'item',
            MultipartFile.fromBytes(
              latin1.encode('Grüße'),
              contentType: DioMediaType.parse(
                'text/plain; charset=iso-8859-1',
              ),
            ),
          ),
          MapEntry(
            'metadata',
            MultipartFile.fromBytes(
              utf8.encode('{"empty":true}'),
              contentType: DioMediaType.parse('application/json'),
            ),
          ),
          MapEntry(
            'item',
            MultipartFile.fromBytes(
              const [0, 1, 2, 255],
              filename: 'first.bin',
              contentType: DioMediaType.parse('application/octet-stream'),
            ),
          ),
          MapEntry(
            'empty',
            MultipartFile.fromBytes(
              const [],
              contentType: DioMediaType.parse('text/plain'),
            ),
          ),
          MapEntry(
            'item',
            MultipartFile.fromBytes(
              const [3, 4],
              filename: 'second.bin',
              contentType: DioMediaType.parse('application/octet-stream'),
            ),
          ),
        ]);

      final wireBytes = await form.finalize().fold<List<int>>(
        [],
        (bytes, chunk) => bytes..addAll(chunk),
      );
      final decoded = await Stream<List<int>>.value(
        wireBytes,
      ).transform(MimeMultipartTransformer(form.boundary)).toList();
      final parts = <({Map<String, String> headers, List<int> bytes})>[];
      for (final part in decoded) {
        parts.add((
          headers: part.headers,
          bytes: await part.fold<List<int>>(
            [],
            (bytes, chunk) => bytes..addAll(chunk),
          ),
        ));
      }

      expect(parts, hasLength(5));
      expect(
        parts.map((part) => part.headers['content-disposition']).toList(),
        [
          'form-data; name="item"',
          'form-data; name="metadata"',
          'form-data; name="item"; filename="first.bin"',
          'form-data; name="empty"',
          'form-data; name="item"; filename="second.bin"',
        ],
      );
      expect(parts.map((part) => part.headers['content-type']).toList(), [
        'text/plain; charset=iso-8859-1',
        'application/json',
        'application/octet-stream',
        'text/plain',
        'application/octet-stream',
      ]);
      expect(parts.map((part) => part.bytes).toList(), [
        latin1.encode('Grüße'),
        utf8.encode('{"empty":true}'),
        [0, 1, 2, 255],
        <int>[],
        [3, 4],
      ]);
    },
  );
}
