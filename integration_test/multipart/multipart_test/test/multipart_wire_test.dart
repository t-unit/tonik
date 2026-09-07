import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';

import 'multipart_wire.dart';

void main() {
  test('rejects a closing-boundary-only body', () {
    final request = RawRequest(
      uri: Uri.parse('http://localhost/upload'),
      method: 'POST',
      headers: const {
        'content-type': ['multipart/form-data; boundary=test'],
      },
      bodyBytes: Uint8List.fromList(ascii.encode('--test--\r\n')),
    );

    expect(() => MultipartWire(request), throwsStateError);
  });

  test('rejects boundaries without a body part', () {
    final request = RawRequest(
      uri: Uri.parse('http://localhost/upload'),
      method: 'POST',
      headers: const {
        'content-type': ['multipart/form-data; boundary=test'],
      },
      bodyBytes: Uint8List.fromList(ascii.encode('--test\r\n--test--\r\n')),
    );

    expect(() => MultipartWire(request), throwsStateError);
  });

  test('accepts one part with an empty value', () {
    final request = RawRequest(
      uri: Uri.parse('http://localhost/upload'),
      method: 'POST',
      headers: const {
        'content-type': ['multipart/form-data; boundary=test'],
      },
      bodyBytes: Uint8List.fromList(
        ascii.encode(
          '--test\r\n'
          'content-disposition: form-data; name="value"\r\n'
          'content-type: text/plain\r\n'
          '\r\n\r\n'
          '--test--\r\n',
        ),
      ),
    );

    final wire = MultipartWire(request);
    expect(wire.parts, hasLength(1));
    expect(wire.single('value').bodyText, '');
  });
}
