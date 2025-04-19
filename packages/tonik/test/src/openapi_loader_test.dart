import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:tonik/src/openapi_loader.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('openapi_loader_test_');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('loadOpenApiDocument', () {
    test('loads valid JSON file', () {
      final jsonFile = File(path.join(tempDir.path, 'test.json'));
      jsonFile.writeAsStringSync('''
{
  "openapi": "3.0.0",
  "info": {
    "title": "Test API",
    "version": "1.0.0"
  }
}''');

      final result = loadOpenApiDocument(jsonFile.path);

      expect(result, {
        'openapi': '3.0.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
      });
    });

    test('loads valid YAML file', () {
      final yamlFile = File(path.join(tempDir.path, 'test.yaml'));
      yamlFile.writeAsStringSync('''
openapi: 3.0.0
info:
  title: Test API
  version: 1.0.0
''');

      final result = loadOpenApiDocument(yamlFile.path);

      expect(result, {
        'openapi': '3.0.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
      });
    });

    test('throws when file does not exist', () {
      expect(
        () => loadOpenApiDocument('nonexistent.json'),
        throwsA(
          isA<OpenApiLoaderException>().having(
            (e) => e.toString(),
            'message',
            'OpenAPI document not found',
          ),
        ),
      );
    });

    test('throws on unsupported file extension', () {
      final txtFile = File(path.join(tempDir.path, 'test.txt'));
      txtFile.writeAsStringSync('invalid');

      expect(
        () => loadOpenApiDocument(txtFile.path),
        throwsA(isA<OpenApiLoaderException>()),
      );
    });

    test('throws on invalid JSON', () {
      final jsonFile = File(path.join(tempDir.path, 'invalid.json'));
      jsonFile.writeAsStringSync('invalid json');

      expect(
        () => loadOpenApiDocument(jsonFile.path),
        throwsA(
          isA<OpenApiLoaderException>().having(
            (e) => e.toString(),
            'message',
            'Failed to parse OpenAPI document.',
          ),
        ),
      );
    });

    test('throws on invalid YAML', () {
      final yamlFile = File(path.join(tempDir.path, 'invalid.yaml'));
      yamlFile.writeAsStringSync('''
invalid yaml:
  - misaligned:
 wrong indentation
  unclosed "string
      ''');

      expect(
        () => loadOpenApiDocument(yamlFile.path),
        throwsA(isA<OpenApiLoaderException>()),
      );
    });

    test('handles complex YAML structures', () {
      final yamlFile = File(path.join(tempDir.path, 'complex.yaml'));
      yamlFile.writeAsStringSync('''
openapi: 3.0.0
info:
  title: Complex API
  version: 1.0.0
paths:
  /test:
    get:
      responses:
        '200':
          description: OK
          content:
            application/json:
              schema:
                type: array
                items:
                  type: string
''');

      final result = loadOpenApiDocument(yamlFile.path);

      expect(result, {
        'openapi': '3.0.0',
        'info': {'title': 'Complex API', 'version': '1.0.0'},
        'paths': {
          '/test': {
            'get': {
              'responses': {
                '200': {
                  'description': 'OK',
                  'content': {
                    'application/json': {
                      'schema': {
                        'type': 'array',
                        'items': {'type': 'string'},
                      },
                    },
                  },
                },
              },
            },
          },
        },
      });
    });
  });
}
