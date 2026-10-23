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
      responseBody: utf8.encode('"café"'),
    );
    final api = WidgetsApi(CustomServer(baseUrl: server.baseUrl));

    final response = await api.getJsonCharset();

    expect(requireSuccess(response).value, 'café');
  });

  test(
    'uses the declared JSON charset when the wire charset is unknown',
    () async {
      final server = await RawRequestServer.start(
        responseStatusCode: 200,
        responseHeaders: {'Content-Type': 'application/json; charset=blub'},
        responseBody: utf8.encode('"café"'),
      );
      final api = WidgetsApi(CustomServer(baseUrl: server.baseUrl));

      final response = await api.getJsonCharset();

      expect(requireSuccess(response).value, 'café');
    },
  );

  test('still requires other declared JSON parameters', () async {
    final server = await RawRequestServer.start(
      responseStatusCode: 200,
      responseHeaders: {'Content-Type': 'application/json'},
      responseBody: utf8.encode('"café"'),
    );
    final api = WidgetsApi(CustomServer(baseUrl: server.baseUrl));

    final response = await api.getJsonCharsetProfile();

    expect(requireError(response).type, TonikErrorType.decoding);
  });

  test('matches other JSON parameters without requiring charset', () async {
    final server = await RawRequestServer.start(
      responseStatusCode: 200,
      responseHeaders: {'Content-Type': 'application/json; profile="Full"'},
      responseBody: utf8.encode('"café"'),
    );
    final api = WidgetsApi(CustomServer(baseUrl: server.baseUrl));

    final response = await api.getJsonCharsetProfile();

    expect(requireSuccess(response).value, 'café');
  });

  test(
    'prefers meaningful parameters over a charset-only declaration',
    () async {
      final server = await RawRequestServer.start(
        responseStatusCode: 200,
        responseHeaders: {'Content-Type': 'application/json; version=2'},
        responseBody: utf8.encode('"café"'),
      );
      final api = WidgetsApi(CustomServer(baseUrl: server.baseUrl));

      final response = await api.getJsonCharsetVariants();

      expect(
        requireSuccess(response).value,
        const JsonCharsetVariantsGet200ResponseJsonVersion2(body: 'café'),
      );
    },
  );

  test(
    'falls back to the first text charset when wire charset is absent',
    () async {
      final server = await RawRequestServer.start(
        responseStatusCode: 200,
        responseHeaders: {'Content-Type': 'text/plain'},
        responseBody: utf8.encode('café'),
      );
      final api = WidgetsApi(CustomServer(baseUrl: server.baseUrl));

      final response = await api.getTextCharset();

      expect(
        requireSuccess(response).value,
        const TextCharsetGet200ResponsePlainCharsetUtf8(body: 'café'),
      );
    },
  );

  test('selects the first text charset on an exact wire match', () async {
    final server = await RawRequestServer.start(
      responseStatusCode: 200,
      responseHeaders: {'Content-Type': 'text/plain; charset=utf-8'},
      responseBody: utf8.encode('café'),
    );
    final api = WidgetsApi(CustomServer(baseUrl: server.baseUrl));

    final response = await api.getTextCharset();

    expect(
      requireSuccess(response).value,
      const TextCharsetGet200ResponsePlainCharsetUtf8(body: 'café'),
    );
  });

  test('selects the second text charset on an exact wire match', () async {
    final server = await RawRequestServer.start(
      responseStatusCode: 200,
      responseHeaders: {'Content-Type': 'text/plain; charset=latin1'},
      responseBody: const [0x63, 0x61, 0x66, 0xe9],
    );
    final api = WidgetsApi(CustomServer(baseUrl: server.baseUrl));

    final response = await api.getTextCharset();

    expect(
      requireSuccess(response).value,
      const TextCharsetGet200ResponsePlainCharsetLatin1(body: 'café'),
    );
  });

  test(
    'uses the first text charset when the wire charset is unknown',
    () async {
      final server = await RawRequestServer.start(
        responseStatusCode: 200,
        responseHeaders: {'Content-Type': 'text/plain; charset=blub'},
        responseBody: utf8.encode('café'),
      );
      final api = WidgetsApi(CustomServer(baseUrl: server.baseUrl));

      final response = await api.getTextCharset();

      expect(
        requireSuccess(response).value,
        const TextCharsetGet200ResponsePlainCharsetUtf8(body: 'café'),
      );
    },
  );

  test(
    'fallback follows declaration order instead of preferring UTF-8',
    () async {
      final server = await RawRequestServer.start(
        responseStatusCode: 200,
        responseHeaders: {'Content-Type': 'text/plain'},
        responseBody: const [0x63, 0x61, 0x66, 0xe9],
      );
      final api = WidgetsApi(CustomServer(baseUrl: server.baseUrl));

      final response = await api.getTextCharsetReversed();

      expect(
        requireSuccess(response).value,
        const TextCharsetReversedGet200ResponsePlainCharsetLatin1(body: 'café'),
      );
    },
  );

  test('decodes JSON using the selected declared charset', () async {
    final server = await RawRequestServer.start(
      responseStatusCode: 200,
      responseHeaders: {'Content-Type': 'application/json; charset=blub'},
      responseBody: const [0x22, 0x63, 0x61, 0x66, 0xe9, 0x22],
    );
    final api = WidgetsApi(CustomServer(baseUrl: server.baseUrl));

    final response = await api.getJsonLatin1();

    expect(requireSuccess(response).value, 'café');
  });

  test('uses declared charsets for structured JSON suffixes', () async {
    final server = await RawRequestServer.start(
      responseStatusCode: 200,
      responseHeaders: {'Content-Type': 'application/problem+json'},
      responseBody: const [0x22, 0x63, 0x61, 0x66, 0xe9, 0x22],
    );
    final api = WidgetsApi(CustomServer(baseUrl: server.baseUrl));

    final response = await api.getProblemCharset();

    expect(requireSuccess(response).value, 'café');
  });

  test('uses the declared charset for percent-encoded form values', () async {
    final server = await RawRequestServer.start(
      responseStatusCode: 200,
      responseHeaders: {'Content-Type': 'application/x-www-form-urlencoded'},
      responseBody: ascii.encode('name=caf%E9'),
    );
    final api = WidgetsApi(CustomServer(baseUrl: server.baseUrl));

    final response = await api.getFormCharset();

    expect(requireSuccess(response).value.name, 'café');
  });
}
