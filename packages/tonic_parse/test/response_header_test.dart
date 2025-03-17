import 'package:collection/collection.dart';
import 'package:test/test.dart';
import 'package:tonic_core/tonic_core.dart';
import 'package:tonic_parse/tonic_parse.dart';

void main() {
  const fileContent = {
    'openapi': '3.0.0',
    'info': {'title': 'Test API', 'version': '1.0.0'},
    'paths': <String, dynamic>{},
    'components': {
      'headers': {
        'simple': {
          'schema': {'type': 'string'},
        },
        'rateLimit': {
          'schema': {'type': 'string'},
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
              'id': {'type': 'string'},
              'value': {'type': 'integer'},
            },
            'required': ['id'],
          },
          'description': 'Header with schema',
          'required': true,
        },
        'reference': {r'$ref': '#/components/headers/simple'},
        'referenceReference': {r'$ref': '#/components/headers/reference'},
        'withContent': {
          'content': {
            'application/json': {
              'schema': {
                'type': 'object',
                'properties': {
                  'test': {'type': 'string'},
                },
              },
            },
          },
        },
      },
    },
  };

  final api = Importer().import(fileContent);

  final headers = api.responseHeaders;
  final simple = headers.whereType<ResponseHeaderObject>().firstWhereOrNull(
    (h) => h.name == 'simple',
  );
  final rateLimit = headers.whereType<ResponseHeaderObject>().firstWhereOrNull(
    (h) => h.name == 'rateLimit',
  );
  final content = headers.whereType<ResponseHeaderObject>().firstWhereOrNull(
    (h) => h.name == 'content',
  );
  final withSchema = headers.whereType<ResponseHeaderObject>().firstWhereOrNull(
    (h) => h.name == 'withSchema',
  );
  final withContent = headers
      .whereType<ResponseHeaderObject>()
      .firstWhereOrNull((h) => h.name == 'withContent');
  final reference = headers.whereType<ResponseHeaderAlias>().firstWhereOrNull(
    (h) => h.name == 'reference',
  );
  final referenceReference = headers
      .whereType<ResponseHeaderAlias>()
      .firstWhereOrNull((h) => h.name == 'referenceReference');

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

    final valueProperty = model?.properties.firstWhere(
      (p) => p.name == 'value',
    );
    expect(valueProperty?.model, isA<IntegerModel>());
    expect(valueProperty?.isRequired, isFalse);
  });

  test('falls back to string model for header with content', () {
    expect(withContent, isNotNull);
    expect(withContent?.model, isA<StringModel>());
  });

  test('imports reference', () {
    expect(reference, isNotNull);
    final target = reference?.header as ResponseHeaderObject?;
    expect(target?.name, 'simple');
  });

  test('imports nested reference', () {
    expect(referenceReference, isNotNull);
    expect(referenceReference?.header, isA<ResponseHeaderAlias>());

    final target =
        (referenceReference?.header as ResponseHeaderAlias?)?.header
            as ResponseHeaderObject?;
    expect(target?.name, 'simple');
  });

  test('does not duplicate headers when importing references', () {
    final simple = headers.where((h) => h.name == 'simple');
    final reference = headers.where((h) => h.name == 'reference');

    expect(simple, hasLength(1));
    expect(reference, hasLength(1));
  });
}
