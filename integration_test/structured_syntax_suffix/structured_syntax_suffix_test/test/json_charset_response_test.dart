import 'dart:convert';

import 'package:structured_syntax_suffix_api/structured_syntax_suffix_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  test('decodes plain JSON for a charset-qualified declaration', () async {
    final server = await RawRequestServer.start(
      responseStatusCode: 200,
      responseHeaders: {'Content-Type': 'application/json'},
      responseBody: utf8.encode('"x"'),
    );
    final api = WidgetsApi(CustomServer(baseUrl: server.baseUrl));

    final response = await api.getJsonCharset();

    expect(requireSuccess(response).value, 'x');
  });

  test('ignores a different charset on an application/json response', () async {
    final server = await RawRequestServer.start(
      responseStatusCode: 200,
      responseHeaders: {'Content-Type': 'application/json; charset=us-ascii'},
      responseBody: utf8.encode('"x"'),
    );
    final api = WidgetsApi(CustomServer(baseUrl: server.baseUrl));

    final response = await api.getJsonCharset();

    expect(requireSuccess(response).value, 'x');
  });

  test('still requires other declared JSON parameters', () async {
    final server = await RawRequestServer.start(
      responseStatusCode: 200,
      responseHeaders: {'Content-Type': 'application/json'},
      responseBody: utf8.encode('"x"'),
    );
    final api = WidgetsApi(CustomServer(baseUrl: server.baseUrl));

    final response = await api.getJsonCharsetProfile();

    expect(requireError(response).type, TonikErrorType.decoding);
  });

  test('matches other JSON parameters without requiring charset', () async {
    final server = await RawRequestServer.start(
      responseStatusCode: 200,
      responseHeaders: {'Content-Type': 'application/json; profile="Full"'},
      responseBody: utf8.encode('"x"'),
    );
    final api = WidgetsApi(CustomServer(baseUrl: server.baseUrl));

    final response = await api.getJsonCharsetProfile();

    expect(requireSuccess(response).value, 'x');
  });

  test(
    'prefers meaningful parameters over a charset-only declaration',
    () async {
      final server = await RawRequestServer.start(
        responseStatusCode: 200,
        responseHeaders: {'Content-Type': 'application/json; version=2'},
        responseBody: utf8.encode('"x"'),
      );
      final api = WidgetsApi(CustomServer(baseUrl: server.baseUrl));

      final response = await api.getJsonCharsetVariants();

      expect(
        requireSuccess(response).value,
        const JsonCharsetVariantsGet200ResponseJsonVersion2(body: 'x'),
      );
    },
  );

  test('requires charset for a text/plain declaration', () async {
    final server = await RawRequestServer.start(
      responseStatusCode: 200,
      responseHeaders: {'Content-Type': 'text/plain'},
      responseBody: utf8.encode('x'),
    );
    final api = WidgetsApi(CustomServer(baseUrl: server.baseUrl));

    final response = await api.getTextCharset();

    expect(requireError(response).type, TonikErrorType.decoding);
  });

  test('decodes text/plain when its declared charset matches', () async {
    final server = await RawRequestServer.start(
      responseStatusCode: 200,
      responseHeaders: {'Content-Type': 'text/plain; charset=utf-8'},
      responseBody: utf8.encode('x'),
    );
    final api = WidgetsApi(CustomServer(baseUrl: server.baseUrl));

    final response = await api.getTextCharset();

    expect(requireSuccess(response).value, 'x');
  });

  test('retains charset matching for structured JSON suffixes', () async {
    final server = await RawRequestServer.start(
      responseStatusCode: 200,
      responseHeaders: {'Content-Type': 'application/problem+json'},
      responseBody: utf8.encode('"x"'),
    );
    final api = WidgetsApi(CustomServer(baseUrl: server.baseUrl));

    final response = await api.getProblemCharset();

    expect(requireError(response).type, TonikErrorType.decoding);
  });
}
