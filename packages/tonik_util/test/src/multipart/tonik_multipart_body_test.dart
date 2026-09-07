import 'dart:convert';
import 'dart:io';

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

  test('quotes backslashes in multipart names and filenames exactly once', () {
    final body = TonikMultipartBody([
      TonikMultipartPart(
        name: r'profile\name',
        bytes: utf8.encode('Ada'),
        contentType: 'text/plain',
        filename: r'directory\name.txt',
        headers: const {'X-Part-Meta': r'keep\value'},
      ),
    ], boundary: 'test');

    final wire = latin1.decode(body.bodyBytes);
    expect(
      wire,
      '--test\r\n'
      r'content-disposition: form-data; name="profile\\name"; '
      r'filename="directory\\name.txt"'
      '\r\ncontent-type: text/plain\r\n'
      r'X-Part-Meta: keep\value'
      '\r\n\r\nAda\r\n--test--\r\n',
    );
    final disposition = HeaderValue.parse(
      wire.split('\r\n')[1].substring('content-disposition: '.length),
    );
    expect(disposition.parameters['name'], r'profile\name');
    expect(disposition.parameters['filename'], r'directory\name.txt');
  });

  test('preserves trailing and consecutive backslashes when MIME parsed', () {
    final body = TonikMultipartBody([
      TonikMultipartPart(
        name: r'trailing\',
        bytes: const [65],
        contentType: 'text/plain',
      ),
      TonikMultipartPart(
        name: r'consecutive\\slashes',
        bytes: const [66],
        contentType: 'text/plain',
      ),
    ], boundary: 'test');

    final wire = latin1.decode(body.bodyBytes);
    expect(wire, contains(r'name="trailing\\"'));
    expect(wire, contains(r'name="consecutive\\\\slashes"'));
    final trailing = HeaderValue.parse(
      wire.split('\r\n')[1].substring('content-disposition: '.length),
    );
    final consecutive = HeaderValue.parse(
      wire.split('\r\n')[6].substring('content-disposition: '.length),
    );
    expect(trailing.parameters['name'], r'trailing\');
    expect(consecutive.parameters['name'], r'consecutive\\slashes');
  });

  test('retains percent escaping for quotes and line breaks', () {
    final body = TonikMultipartBody([
      TonikMultipartPart(
        name: 'quote"line\r\nnext',
        bytes: const [65],
        contentType: 'text/plain',
        filename: 'line\nquote"',
      ),
    ], boundary: 'test');

    expect(
      latin1.decode(body.bodyBytes),
      '--test\r\n'
      'content-disposition: form-data; name="quote%22line%0D%0Anext"; '
      'filename="line%0D%0Aquote%22"\r\n'
      'content-type: text/plain\r\n\r\nA\r\n--test--\r\n',
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
