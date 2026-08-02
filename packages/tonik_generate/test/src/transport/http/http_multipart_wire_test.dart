import 'dart:convert';

import 'package:http/http.dart';
import 'package:mime/mime.dart';
import 'package:test/test.dart';

void main() {
  test(
    'decoded multipart body preserves exact ordered duplicate parts',
    () async {
      final request = AbortableMultipartRequest(
        'POST',
        Uri.parse('https://example.com/upload'),
      );
      request.files.addAll([
        MultipartFile.fromBytes(
          'item',
          latin1.encode('Grüße'),
          contentType: MediaType.parse('text/plain; charset=iso-8859-1'),
        ),
        MultipartFile.fromBytes(
          'metadata',
          utf8.encode('{"empty":true}'),
          contentType: MediaType.parse('application/json'),
        ),
        MultipartFile.fromBytes(
          'item',
          const [0, 1, 2, 255],
          filename: 'first.bin',
          contentType: MediaType.parse('application/octet-stream'),
        ),
        MultipartFile.fromBytes(
          'empty',
          const [],
          contentType: MediaType.parse('text/plain'),
        ),
        MultipartFile.fromBytes(
          'item',
          const [3, 4],
          filename: 'second.bin',
          contentType: MediaType.parse('application/octet-stream'),
        ),
      ]);

      final wireBytes = await request.finalize().toBytes();
      final requestContentType = MediaType.parse(
        request.headers['content-type']!,
      );
      final boundary = requestContentType.parameters['boundary']!;
      final decoded = await Stream<List<int>>.value(
        wireBytes,
      ).transform(MimeMultipartTransformer(boundary)).toList();
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
