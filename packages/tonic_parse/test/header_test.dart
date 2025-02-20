import 'package:collection/collection.dart';
import 'package:test/test.dart';
import 'package:tonic_core/tonic_core.dart';
import 'package:tonic_parse/src/header_importer.dart';
import 'package:tonic_parse/src/model/open_api_object.dart';
import 'package:tonic_parse/src/model_importer.dart';

void main() {
  const fileContent = {
    'openapi': '3.0.0',
    'info': {
      'title': 'Test API',
      'version': '1.0.0',
    },
    'paths': <String, dynamic>{},
    'components': {
      'headers': {
        'simple': {
          'schema': {'type': 'string'},
        },
        'schema': {'type': 'string'},
        'rateLimit': {
          'explode': false,
          'required': false,
          'deprecated': true,
        },
        'content': {
          'schema': {'type': 'string'},
          'explode': true,
          'required': true,
          'deprecated': false,
          'description': 'Content-Type header',
          'style': 'simple',
        },
        'withSchema': {
          'schema': {
            'type': 'object',
            'properties': {
              'id': {
                'type': 'string',
              },
              'value': {
                'type': 'integer',
              },
            },
            'required': ['id'],
          },
          'description': 'Header with schema',
          'required': true,
        },
        'withContent': {
          'content': {
            'application/json': {
              'schema': {
                'type': 'object',
                'properties': {
                  'test': {'type': 'string'}
                }
              }
            }
          }
        },
      },
    },
  };

  final openApiObject = OpenApiObject.fromJson(fileContent);
  final modelImporter = ModelImporter(openApiObject);
  final headerImporter = HeaderImporter(
    openApiObject: openApiObject,
    modelImporter: modelImporter,
  );

  modelImporter.import();
  headerImporter.import();

  final headers = headerImporter.headers;
  final simple = headers.firstWhereOrNull((h) => h.name == 'simple');
  final rateLimit = headers.firstWhereOrNull((h) => h.name == 'rateLimit');
  final content = headers.firstWhereOrNull((h) => h.name == 'content');
  final withSchema = headers.firstWhereOrNull((h) => h.name == 'withSchema');
  final withContent = headers.firstWhereOrNull((h) => h.name == 'withContent');

  test('import explode', () {
    expect(simple?.explode, isFalse);
    expect(rateLimit?.explode, isFalse);
    expect(content?.explode, isTrue);
  });

  test('optionally imports description', () {
    expect(simple?.description, isNull);
    expect(rateLimit?.description, isNull);
    expect(content?.description, 'Content-Type header');
  });

  test('imports isRequired', () {
    expect(simple?.isRequired, isFalse);
    expect(rateLimit?.isRequired, isFalse);
    expect(content?.isRequired, isTrue);
  });

  test('imports isDeprecated', () {
    expect(simple?.isDeprecated, isFalse);
    expect(rateLimit?.isDeprecated, isTrue);
    expect(content?.isDeprecated, isFalse);
  });

  test('imports simple style', () {
    expect(content, isNotNull);
  });

  test('imports header with inline schema', () {
    expect(withSchema, isNotNull);
    expect(withSchema?.model, isA<ClassModel>());

    final model = withSchema?.model as ClassModel?;
    expect(model?.properties, hasLength(2));

    final idProperty = model?.properties.firstWhere((p) => p.name == 'id');
    expect(idProperty?.model, isA<StringModel>());
    expect(idProperty?.isRequired, isTrue);

    final valueProperty =
        model?.properties.firstWhere((p) => p.name == 'value');
    expect(valueProperty?.model, isA<IntegerModel>());
    expect(valueProperty?.isRequired, isFalse);
  });

  test('falls back to string model for header with content', () {
    expect(withContent, isNotNull);
    expect(withContent?.model, isA<StringModel>());
  });
}
