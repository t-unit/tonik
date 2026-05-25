import 'package:logging/logging.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart' as core;
import 'package:tonik_parse/src/example_importer.dart';
import 'package:tonik_parse/src/model/header.dart';
import 'package:tonik_parse/src/model/media_type.dart';
import 'package:tonik_parse/src/model/open_api_object.dart';
import 'package:tonik_parse/src/model/parameter.dart';

void main() {
  group('ExampleImporter.fromSchema', () {
    test('extracts OAS 3.0 singular example as a one-element list', () {
      final api = OpenApiObject.fromJson(<String, dynamic>{
        'openapi': '3.0.4',
        'info': {'title': 'T', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Item': {'type': 'string', 'example': 'hello'},
          },
        },
      });
      final importer = ExampleImporter(openApiObject: api);

      final schema = api.components!.schemas!['Item']!;
      final result = importer.fromSchema(schema);

      expect(result, const [
        core.Example(
          name: null,
          summary: null,
          description: null,
          value: 'hello',
        ),
      ]);
    });

    test('extracts OAS 3.1 examples array entries', () {
      final api = OpenApiObject.fromJson(<String, dynamic>{
        'openapi': '3.1.0',
        'info': {'title': 'T', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Item': {
              'type': 'string',
              'examples': ['a', 'b', 'c'],
            },
          },
        },
      });
      final importer = ExampleImporter(openApiObject: api);

      final schema = api.components!.schemas!['Item']!;
      final result = importer.fromSchema(schema);

      expect(result, const [
        core.Example(name: null, summary: null, description: null, value: 'a'),
        core.Example(name: null, summary: null, description: null, value: 'b'),
        core.Example(name: null, summary: null, description: null, value: 'c'),
      ]);
    });
  });

  group('ExampleImporter.fromMediaType', () {
    OpenApiObject loadApi({Map<String, dynamic> components = const {}}) {
      return OpenApiObject.fromJson(<String, dynamic>{
        'openapi': '3.1.0',
        'info': {'title': 'T', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': components,
      });
    }

    MediaType media(Map<String, dynamic> json) => MediaType.fromJson(json);

    test('normalizes singular example', () {
      final api = loadApi();
      final importer = ExampleImporter(openApiObject: api);

      final result = importer.fromMediaType(
        media({
          'example': {'k': 1},
        }),
      );

      expect(result, const [
        core.Example(
          name: null,
          summary: null,
          description: null,
          value: {'k': 1},
        ),
      ]);
    });

    test('normalizes examples map populating name from keys', () {
      final api = loadApi();
      final importer = ExampleImporter(openApiObject: api);

      final result = importer.fromMediaType(
        media({
          'examples': {
            'first': {
              'summary': 'First case',
              'description': 'desc',
              'value': {'k': 1},
            },
            'second': {'value': 42},
          },
        }),
      );

      expect(result, const [
        core.Example(
          name: 'first',
          summary: 'First case',
          description: 'desc',
          value: {'k': 1},
        ),
        core.Example(
          name: 'second',
          summary: null,
          description: null,
          value: 42,
        ),
      ]);
    });

    test('falls back to schema-level examples when media-level absent', () {
      final api = loadApi();
      final importer = ExampleImporter(openApiObject: api);

      final result = importer.fromMediaType(
        media({
          'schema': {
            'type': 'string',
            'examples': ['a', 'b'],
          },
        }),
      );

      expect(result, const [
        core.Example(name: null, summary: null, description: null, value: 'a'),
        core.Example(name: null, summary: null, description: null, value: 'b'),
      ]);
    });

    test('media-level overrides schema-level (no merge)', () {
      final api = loadApi();
      final importer = ExampleImporter(openApiObject: api);

      final result = importer.fromMediaType(
        media({
          'schema': {'type': 'string', 'example': 'schema-level'},
          'example': 'media-level',
        }),
      );

      expect(result, const [
        core.Example(
          name: null,
          summary: null,
          description: null,
          value: 'media-level',
        ),
      ]);
    });

    test('drops examples that only carry externalValue', () {
      final api = loadApi();
      final importer = ExampleImporter(openApiObject: api);

      final result = importer.fromMediaType(
        media({
          'examples': {
            'remote': {'externalValue': 'https://example.com/value.json'},
            'inline': {'value': 1},
          },
        }),
      );

      expect(result, const [
        core.Example(
          name: 'inline',
          summary: null,
          description: null,
          value: 1,
        ),
      ]);
    });

    test(
      'drops Example with neither value nor externalValue and logs warning',
      () {
        final api = loadApi();
        final importer = ExampleImporter(openApiObject: api);

        final logs = <LogRecord>[];
        final sub = Logger.root.onRecord.listen(logs.add);
        addTearDown(sub.cancel);

        final result = importer.fromMediaType(
          media({
            'examples': {
              'empty': {'summary': 'no payload'},
            },
          }),
        );

        expect(result, isEmpty);
        expect(
          logs.where((r) => r.level == Level.WARNING),
          hasLength(1),
        );
      },
    );

    test('preserves examples whose value is explicitly null', () {
      final api = loadApi();
      final importer = ExampleImporter(openApiObject: api);

      final result = importer.fromMediaType(
        media({
          'examples': {
            'nullValue': {'value': null, 'summary': 'null is valid JSON'},
          },
        }),
      );

      expect(result, const [
        core.Example(
          name: 'nullValue',
          summary: 'null is valid JSON',
          description: null,
          value: null,
        ),
      ]);
    });

    test(r'resolves $ref examples from components.examples', () {
      final api = loadApi(
        components: {
          'examples': {
            'Shared': {
              'summary': 'Shared example',
              'description': 'shared desc',
              'value': {'k': 'v'},
            },
          },
        },
      );
      final importer = ExampleImporter(openApiObject: api);

      final result = importer.fromMediaType(
        media({
          'examples': {
            'shared': {r'$ref': '#/components/examples/Shared'},
          },
        }),
      );

      expect(result, const [
        core.Example(
          name: 'shared',
          summary: 'Shared example',
          description: 'shared desc',
          value: {'k': 'v'},
        ),
      ]);
    });

    test(r'throws UnimplementedError on non-local example $ref', () {
      final api = loadApi();
      final importer = ExampleImporter(openApiObject: api);

      expect(
        () => importer.fromMediaType(
          media({
            'examples': {
              'remote': {r'$ref': 'https://example.com/examples.json#/x'},
            },
          }),
        ),
        throwsUnimplementedError,
      );
    });

    test('throws ArgumentError on missing example target', () {
      final api = loadApi();
      final importer = ExampleImporter(openApiObject: api);

      expect(
        () => importer.fromMediaType(
          media({
            'examples': {
              'missing': {r'$ref': '#/components/examples/Missing'},
            },
          }),
        ),
        throwsArgumentError,
      );
    });

    test(r'throws ArgumentError on cyclic example $ref chain', () {
      final api = loadApi(
        components: {
          'examples': {
            'A': {r'$ref': '#/components/examples/B'},
            'B': {r'$ref': '#/components/examples/A'},
          },
        },
      );
      final importer = ExampleImporter(openApiObject: api);

      expect(
        () => importer.fromMediaType(
          media({
            'examples': {
              'start': {r'$ref': '#/components/examples/A'},
            },
          }),
        ),
        throwsA(
          isA<ArgumentError>()
              .having(
                (e) => e.message,
                'message',
                startsWith('Cyclic example reference:'),
              )
              .having(
                (e) => e.message,
                'message',
                contains('#/components/examples/A'),
              )
              .having(
                (e) => e.message,
                'message',
                contains('#/components/examples/B'),
              ),
        ),
      );
    });
  });

  group('ExampleImporter.fromParameter', () {
    Parameter buildParameter(Map<String, dynamic> extra) {
      final base = <String, dynamic>{
        'name': 'p',
        'in': 'query',
        'schema': {'type': 'string'},
      };
      return Parameter.fromJson({...base, ...extra});
    }

    test('normalizes singular parameter example', () {
      final api = OpenApiObject.fromJson(<String, dynamic>{
        'openapi': '3.1.0',
        'info': {'title': 'T', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
      });
      final importer = ExampleImporter(openApiObject: api);

      final parameter = buildParameter({'example': 'value'});
      final result = importer.fromParameter(parameter);

      expect(result, const [
        core.Example(
          name: null,
          summary: null,
          description: null,
          value: 'value',
        ),
      ]);
    });

    test('normalizes parameter examples map', () {
      final api = OpenApiObject.fromJson(<String, dynamic>{
        'openapi': '3.1.0',
        'info': {'title': 'T', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
      });
      final importer = ExampleImporter(openApiObject: api);

      final parameter = buildParameter({
        'examples': {
          'one': {'summary': 'first', 'value': 1},
        },
      });
      final result = importer.fromParameter(parameter);

      expect(result, const [
        core.Example(
          name: 'one',
          summary: 'first',
          description: null,
          value: 1,
        ),
      ]);
    });
  });

  group('ExampleImporter.fromHeader', () {
    Header buildHeader(Map<String, dynamic> extra) {
      final base = <String, dynamic>{
        'schema': {'type': 'string'},
      };
      return Header.fromJson({...base, ...extra});
    }

    test('normalizes singular header example', () {
      final api = OpenApiObject.fromJson(<String, dynamic>{
        'openapi': '3.1.0',
        'info': {'title': 'T', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
      });
      final importer = ExampleImporter(openApiObject: api);

      final header = buildHeader({'example': 'hv'});
      final result = importer.fromHeader(header);

      expect(result, const [
        core.Example(
          name: null,
          summary: null,
          description: null,
          value: 'hv',
        ),
      ]);
    });

    test('normalizes header examples map', () {
      final api = OpenApiObject.fromJson(<String, dynamic>{
        'openapi': '3.1.0',
        'info': {'title': 'T', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
      });
      final importer = ExampleImporter(openApiObject: api);

      final header = buildHeader({
        'examples': {
          'ok': {'value': 'ok-value'},
        },
      });
      final result = importer.fromHeader(header);

      expect(result, const [
        core.Example(
          name: 'ok',
          summary: null,
          description: null,
          value: 'ok-value',
        ),
      ]);
    });
  });
}
