import 'dart:convert';

import 'package:structured_syntax_suffix_api/structured_syntax_suffix_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';

void main() {
  test('selects the versioned string representation', () async {
    final server = await RawRequestServer.start(
      responseStatusCode: 200,
      responseHeaders: {
        'Content-Type': 'application/vnd.example.document+json;version=2',
      },
      responseBody: utf8.encode('"doc-42"'),
    );
    final api = WidgetsApi(CustomServer(baseUrl: server.baseUrl));

    final response = await api.getDocument();

    expect(
      requireSuccess(response).value,
      const DocumentGet200ResponseVndExampleDocumentJsonVersion2(
        body: 'doc-42',
      ),
    );
  });

  test('selects the unparameterized integer representation', () async {
    final server = await RawRequestServer.start(
      responseStatusCode: 200,
      responseHeaders: {
        'Content-Type': 'application/vnd.example.document+json',
      },
      responseBody: utf8.encode('42'),
    );
    final api = WidgetsApi(CustomServer(baseUrl: server.baseUrl));

    final response = await api.getDocument();

    expect(
      requireSuccess(response).value,
      const DocumentGet200ResponseVndExampleDocumentJson(body: 42),
    );
  });

  test(
    'falls back to the bare representation for an undeclared version',
    () async {
      final server = await RawRequestServer.start(
        responseStatusCode: 200,
        responseHeaders: {
          'Content-Type': 'application/vnd.example.document+json;version=3',
        },
        responseBody: utf8.encode('42'),
      );
      final api = WidgetsApi(CustomServer(baseUrl: server.baseUrl));

      final response = await api.getDocument();

      expect(
        requireSuccess(response).value,
        const DocumentGet200ResponseVndExampleDocumentJson(body: 42),
      );
    },
  );

  test('matches mixed case names and permits extra charset', () async {
    final server = await RawRequestServer.start(
      responseStatusCode: 200,
      responseHeaders: {
        'Content-Type':
            'Application/Vnd.Example.Document+JSON; CHARSET=UTF-8; VERSION="2"',
      },
      responseBody: utf8.encode('"doc-42"'),
    );
    final api = WidgetsApi(CustomServer(baseUrl: server.baseUrl));

    final response = await api.getDocument();

    expect(
      requireSuccess(response).value,
      const DocumentGet200ResponseVndExampleDocumentJsonVersion2(
        body: 'doc-42',
      ),
    );
  });

  test(
    'prefers the most specific declared parameters regardless of order',
    () async {
      final server = await RawRequestServer.start(
        responseStatusCode: 200,
        responseHeaders: {
          'Content-Type': 'application/vnd.example.document+json; profile="Full;V2"; version=2',
        },
        responseBody: utf8.encode('true'),
      );
      final api = WidgetsApi(CustomServer(baseUrl: server.baseUrl));

      final response = await api.getDocument();

      expect(
        requireSuccess(response).value,
        const DocumentGet200ResponseVndExampleDocumentJsonVersion2ProfileFullV2(
          body: true,
        ),
      );
    },
  );

  test('preserves case when comparing profile parameter values', () async {
    final server = await RawRequestServer.start(
      responseStatusCode: 200,
      responseHeaders: {
        'Content-Type': 'application/vnd.example.document+json; profile="full;v2"; version=2',
      },
      responseBody: utf8.encode('"doc-42"'),
    );
    final api = WidgetsApi(CustomServer(baseUrl: server.baseUrl));

    final response = await api.getDocument();

    expect(
      requireSuccess(response).value,
      const DocumentGet200ResponseVndExampleDocumentJsonVersion2(
        body: 'doc-42',
      ),
    );
  });

  test(
    'also selects the versioned representation when declared first',
    () async {
      final server = await RawRequestServer.start(
        responseStatusCode: 200,
        responseHeaders: {
          'Content-Type': 'application/vnd.example.document+json;version=2',
        },
        responseBody: utf8.encode('"doc-42"'),
      );
      final api = WidgetsApi(CustomServer(baseUrl: server.baseUrl));

      final response = await api.getDocumentReversed();

      expect(
        requireSuccess(response).value,
        const DocumentReversedGet200ResponseVndExampleDocumentJsonVersion2(
          body: 'doc-42',
        ),
      );
    },
  );
}
