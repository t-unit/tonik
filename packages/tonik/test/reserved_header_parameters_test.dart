import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/tonik_generate.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  const spec = {
    'openapi': '3.0.4',
    'info': {'title': 'Reserved headers', 'version': '1.0.0'},
    'paths': {
      '/ping': {
        'get': {
          'operationId': 'getPing',
          'parameters': [
            {
              'name': 'Accept',
              'in': 'header',
              'required': true,
              'schema': {'type': 'string'},
            },
          ],
          'responses': {
            '204': {'description': 'No content'},
          },
        },
      },
      '/probe': {
        'get': {
          'operationId': 'probe',
          'parameters': [
            {
              'name': 'Authorization',
              'in': 'header',
              'schema': {'type': 'string'},
            },
          ],
          'responses': {
            '200': {'description': 'Success'},
          },
        },
      },
      '/json': {
        'parameters': [
          {
            'name': 'CONTENT-TYPE',
            'in': 'header',
            'required': true,
            'x-dart-name': 'ignoredContentType',
            'schema': {'type': 'string'},
          },
        ],
        'post': {
          'operationId': 'postJson',
          'parameters': [
            {r'$ref': '#/components/parameters/MediaPreference'},
            {
              'name': 'authorization',
              'in': 'header',
              'x-dart-name': 'ignoredAuthorization',
              'schema': {'type': 'string'},
            },
            {
              'name': 'X-Trace-Id',
              'in': 'header',
              'required': true,
              'schema': {'type': 'string'},
            },
          ],
          'requestBody': {
            'required': true,
            'content': {
              'application/json': {
                'schema': {'type': 'string'},
              },
            },
          },
          'responses': {
            '200': {
              'description': 'Success',
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
    'components': {
      'parameters': {
        'MediaPreference': {
          'name': 'aCcEpT',
          'in': 'header',
          'required': true,
          'x-dart-name': 'ignoredAccept',
          'schema': {'type': 'string'},
        },
      },
    },
  };

  late Directory tempDirectory;

  setUp(() {
    tempDirectory = Directory.systemTemp.createTempSync('reserved_headers_');
  });

  tearDown(() {
    tempDirectory.deleteSync(recursive: true);
  });

  test('Dio omits reserved arguments and derives media type headers', () async {
    final api = Importer().import(spec);
    await const Generator().generate(
      apiDocument: api,
      outputDirectory: tempDirectory.path,
      package: 'reserved_headers_api',
    );

    final operationsPath = path.join(
      tempDirectory.path,
      'reserved_headers_api',
      'lib',
      'src',
      'operation',
    );
    final ping = File(path.join(operationsPath, 'get_ping.dart'))
        .readAsStringSync();
    final probe = File(path.join(operationsPath, 'probe.dart'))
        .readAsStringSync();
    final json = File(path.join(operationsPath, 'post_json.dart'))
        .readAsStringSync();

    final client = File(
      path.join(
        tempDirectory.path,
        'reserved_headers_api',
        'lib',
        'src',
        'api_client',
        'default_api.dart',
      ),
    ).readAsStringSync();

    expect(client, contains('getPing({'));
    expect(client, contains('probe({'));
    expect(client, contains('postJson({'));
    expect(client, isNot(contains('accept')));
    expect(client, isNot(contains('authorization')));
    expect(client, isNot(contains('ignoredAccept')));
    expect(client, isNot(contains('ignoredAuthorization')));
    expect(client, isNot(contains('ignoredContentType')));
    expect(client, contains('String body'));
    expect(client, contains('String traceId'));
    expect(client, contains('traceId: traceId'));
    expect(ping, isNot(contains('accept')));
    expect(ping, contains(r"_$headers['Accept'] = r'*/*';"));
    expect(probe, isNot(contains('authorization')));
    expect(probe, isNot(contains('Authorization')));
    expect(json, isNot(contains('ignoredAccept')));
    expect(json, isNot(contains('ignoredContentType')));
    expect(json, isNot(contains('ignoredAuthorization')));
    expect(json, isNot(contains('authorization')));
    expect(json, contains('required _i2.String traceId'));
    expect(json, contains("r'X-Trace-Id'"));
    expect(json, contains(r"_$headers['Accept'] = r'application/json';"));
    expect(json, contains("contentType: r'application/json'"));
  });

  test(
    'http omits reserved arguments and derives media type headers',
    () async {
      final api = Importer().import(spec);
      await const Generator().generate(
        apiDocument: api,
        outputDirectory: tempDirectory.path,
        package: 'reserved_headers_api',
        config: const TonikConfig(
          transport: TransportConfig(backend: TransportBackend.http),
        ),
      );

      final operationsPath = path.join(
        tempDirectory.path,
        'reserved_headers_api',
        'lib',
        'src',
        'operation',
      );
      final ping = File(path.join(operationsPath, 'get_ping.dart'))
          .readAsStringSync();
      final probe = File(path.join(operationsPath, 'probe.dart'))
          .readAsStringSync();
      final json = File(path.join(operationsPath, 'post_json.dart'))
          .readAsStringSync();

      final client = File(
        path.join(
          tempDirectory.path,
          'reserved_headers_api',
          'lib',
          'src',
          'api_client',
          'default_api.dart',
        ),
      ).readAsStringSync();

      expect(client, contains('getPing({'));
      expect(client, contains('probe({'));
      expect(client, contains('postJson({'));
      expect(client, isNot(contains('accept')));
      expect(client, isNot(contains('authorization')));
      expect(client, isNot(contains('ignoredAccept')));
      expect(client, isNot(contains('ignoredAuthorization')));
      expect(client, isNot(contains('ignoredContentType')));
      expect(client, contains('String body'));
      expect(client, contains('String traceId'));
      expect(client, contains('traceId: traceId'));
      expect(ping, isNot(contains('accept')));
      expect(ping, contains(r"_$headers['Accept'] = r'*/*';"));
      expect(probe, isNot(contains('authorization')));
      expect(probe, isNot(contains('Authorization')));
      expect(json, isNot(contains('ignoredAccept')));
      expect(json, isNot(contains('ignoredContentType')));
      expect(json, isNot(contains('ignoredAuthorization')));
      expect(json, isNot(contains('authorization')));
      expect(json, contains('required _i2.String traceId'));
      expect(json, contains("r'X-Trace-Id'"));
      expect(json, contains(r"_$headers['Accept'] = r'application/json';"));
      expect(
        json,
        contains(r"_$headers[r'Content-Type'] = r'application/json';"),
      );
    },
  );
}
