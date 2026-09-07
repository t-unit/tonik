import 'dart:convert';

import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  test('encodes ordered duplicate multipart parts with custom headers', () {
    final body = TonikMultipartBody([
      TonikMultipartPart(
        name: 'item',
        bytes: utf8.encode('first'),
        contentType: 'text/plain',
        headers: const {'X-Part-Meta': 'alpha'},
      ),
      TonikMultipartPart(
        name: 'item',
        bytes: const [0, 1, 2],
        contentType: 'application/octet-stream',
        filename: 'item.bin',
        headers: const {'X-File-Hash': 'abc123'},
      ),
    ], boundary: 'tonik-test-boundary');

    expect(
      body.contentType,
      'multipart/form-data; boundary=tonik-test-boundary',
    );
    expect(
      latin1.decode(body.bodyBytes),
      '--tonik-test-boundary\r\n'
      'content-disposition: form-data; name="item"\r\n'
      'content-type: text/plain\r\n'
      'X-Part-Meta: alpha\r\n'
      '\r\n'
      'first\r\n'
      '--tonik-test-boundary\r\n'
      'content-disposition: form-data; name="item"; filename="item.bin"\r\n'
      'content-type: application/octet-stream\r\n'
      'X-File-Hash: abc123\r\n'
      '\r\n'
      '\u0000\u0001\u0002\r\n'
      '--tonik-test-boundary--\r\n',
    );
  });

  test('encodes Unicode filenames and custom header values as UTF-8', () {
    final body = TonikMultipartBody([
      TonikMultipartPart(
        name: 'upload',
        bytes: const [72, 105],
        contentType: 'application/octet-stream',
        filename: '報告.txt',
        headers: const {'X-Part-Meta': 'café'},
      ),
    ], boundary: 'test');

    expect(
      utf8.decode(body.bodyBytes),
      '--test\r\n'
      'content-disposition: form-data; name="upload"; filename="報告.txt"\r\n'
      'content-type: application/octet-stream\r\n'
      'X-Part-Meta: café\r\n'
      '\r\n'
      'Hi\r\n'
      '--test--\r\n',
    );
  });

  test('rejects line breaks in custom header values', () {
    final body = TonikMultipartBody([
      TonikMultipartPart(
        name: 'item',
        bytes: const [],
        contentType: 'text/plain',
        headers: const {'X-Part-Meta': 'safe\r\ninjected: value'},
      ),
    ], boundary: 'tonik-test-boundary');

    expect(() => body.bodyBytes, throwsFormatException);
  });
}
