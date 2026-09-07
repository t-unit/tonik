import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/tonik_generate.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  const spec = {
    'openapi': '3.0.4',
    'info': {'title': 'Reserved response headers', 'version': '1.0.0'},
    'servers': [
      {'url': 'https://example.test'},
    ],
    'paths': {
      '/status': {
        'get': {
          'operationId': 'getStatus',
          'responses': {
            '200': {
              'description': 'Status',
              'headers': {
                'Content-Type': {
                  'schema': {
                    'type': 'string',
                    'enum': ['text/plain'],
                  },
                },
              },
              'content': {
                'application/json': {
                  'schema': {'type': 'string'},
                },
              },
            },
          },
        },
      },
    },
  };

  late Directory tempDirectory;

  setUp(() {
    tempDirectory = Directory.systemTemp.createTempSync(
      'reserved_response_header_',
    );
  });

  tearDown(() {
    tempDirectory.deleteSync(recursive: true);
  });

  test(
    'Dio omits Content-Type properties and keeps media type decoding',
    () async {
      final api = Importer().import(spec);
      await const Generator().generate(
        apiDocument: api,
        outputDirectory: tempDirectory.path,
        package: 'reserved_response_api',
      );

      final operation = File(
        path.join(
          tempDirectory.path,
          'reserved_response_api',
          'lib',
          'src',
          'operation',
          'get_status.dart',
        ),
      ).readAsStringSync();
      final client = File(
        path.join(
          tempDirectory.path,
          'reserved_response_api',
          'lib',
          'src',
          'api_client',
          'default_api.dart',
        ),
      ).readAsStringSync();

      expect(api.models, isEmpty);
      expect(operation, contains('DioOperation<_i2.String>'));
      expect(operation, isNot(contains('contentType:')));
      expect(operation, isNot(contains('fromSimple')));
      expect(operation, isNot(contains('text/plain')));
      expect(operation, contains("response.headers.value('content-type')"));
      expect(operation, contains("case (200, r'application/json'):"));
      expect(operation, contains('decodeJsonString()'));
      expect(operation, contains('ResponseDecodingException('));
      expect(client, contains('getStatus({'));
      expect(client, isNot(contains('HeaderContentTypeModel')));
    },
  );

  test(
    'http omits Content-Type properties and keeps media type decoding',
    () async {
      final api = Importer().import(spec);
      await const Generator().generate(
        apiDocument: api,
        outputDirectory: tempDirectory.path,
        package: 'reserved_response_api',
        config: const TonikConfig(
          transport: TransportConfig(backend: TransportBackend.http),
        ),
      );

      final operation = File(
        path.join(
          tempDirectory.path,
          'reserved_response_api',
          'lib',
          'src',
          'operation',
          'get_status.dart',
        ),
      ).readAsStringSync();
      final client = File(
        path.join(
          tempDirectory.path,
          'reserved_response_api',
          'lib',
          'src',
          'api_client',
          'default_api.dart',
        ),
      ).readAsStringSync();

      expect(api.models, isEmpty);
      expect(operation, contains('HttpOperation<_i2.String>'));
      expect(operation, isNot(contains('contentType:')));
      expect(operation, isNot(contains('fromSimple')));
      expect(operation, isNot(contains('text/plain')));
      expect(operation, contains("response.headers['content-type']"));
      expect(operation, contains("case (200, r'application/json'):"));
      expect(operation, contains('decodeJsonString()'));
      expect(operation, contains('ResponseDecodingException('));
      expect(client, contains('getStatus({'));
      expect(client, isNot(contains('HeaderContentTypeModel')));
    },
  );
}
