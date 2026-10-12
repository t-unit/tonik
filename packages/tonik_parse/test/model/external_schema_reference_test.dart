import 'package:test/test.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  test('external component reference rejects structural siblings', () {
    expect(
      () => Importer().import({
        'openapi': '3.1.0',
        'info': {'title': 'External', 'version': '1'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Extended': {
              r'$ref': r'https://example.test/schema.json#/$defs/Item',
              'properties': {
                'label': {'type': 'string'},
              },
              'required': ['label'],
            },
          },
        },
      }),
      throwsA(isA<UnimplementedError>()),
    );
  });

  test('nested external property references throw', () {
    expect(
      () => Importer().import({
        'openapi': '3.1.0',
        'info': {'title': 'External', 'version': '1'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Container': {
              'type': 'object',
              'properties': {
                'value': {r'$ref': 'other.yaml#/Value'},
              },
            },
          },
        },
      }),
      throwsA(isA<UnimplementedError>()),
    );
  });

  test('nested external array item references throw', () {
    expect(
      () => Importer().import({
        'openapi': '3.1.0',
        'info': {'title': 'External', 'version': '1'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Container': {
              'type': 'object',
              'properties': {
                'values': {
                  'type': 'array',
                  'items': {r'$ref': 'other.yaml#/Value'},
                },
              },
            },
          },
        },
      }),
      throwsA(isA<UnimplementedError>()),
    );
  });

  test('nested external references reject structural siblings', () {
    expect(
      () => Importer().import({
        'openapi': '3.1.0',
        'info': {'title': 'External', 'version': '1'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Container': {
              'type': 'object',
              'properties': {
                'extended': {
                  r'$ref': 'other.yaml#/Value',
                  'properties': {
                    'label': {'type': 'string'},
                  },
                },
              },
            },
          },
        },
      }),
      throwsA(isA<UnimplementedError>()),
    );
  });

  test('unsupported local schema targets are not external references', () {
    expect(
      () => Importer().import({
        'openapi': '3.1.0',
        'info': {'title': 'External', 'version': '1'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Local': {r'$ref': '#/paths/Other'},
          },
        },
      }),
      throwsA(isA<UnimplementedError>()),
    );
  });

  test('malformed schema reference retains its parsing error', () {
    expect(
      () => Importer().import({
        'openapi': '3.1.0',
        'info': {'title': 'External', 'version': '1'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Malformed': {r'$ref': 42},
          },
        },
      }),
      throwsA(isA<TypeError>()),
    );
  });
}
