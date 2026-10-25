import 'package:test/test.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  test(
    'rejects unsupported deep parameter refs instead of a last-name match',
    () {
      expect(
        () => Importer().import({
          'openapi': '3.1.0',
          'info': {'title': 'Test API', 'version': '1.0.0'},
          'paths': <String, dynamic>{},
          'components': {
            'parameters': {
              'Target': {
                'in': 'query',
                'name': 'sort',
                'schema': {'type': 'string'},
              },
              'Alias': {r'$ref': '#/components/parameters/Owner/Target'},
            },
          },
        }),
        throwsA(isA<UnimplementedError>()),
      );
    },
  );

  test('rejects unsupported deep header refs instead of a last-name match', () {
    expect(
      () => Importer().import({
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'headers': {
            'Target': {
              'schema': {'type': 'string'},
            },
            'Alias': {r'$ref': '#/components/headers/Owner/Target'},
          },
        },
      }),
      throwsA(isA<UnimplementedError>()),
    );
  });

  test(
    'rejects unsupported deep response refs instead of a last-name match',
    () {
      expect(
        () => Importer().import({
          'openapi': '3.1.0',
          'info': {'title': 'Test API', 'version': '1.0.0'},
          'paths': <String, dynamic>{},
          'components': {
            'responses': {
              'Target': {'description': 'OK'},
              'Alias': {r'$ref': '#/components/responses/Owner/Target'},
            },
          },
        }),
        throwsA(isA<UnimplementedError>()),
      );
    },
  );

  test(
    'rejects unsupported deep request-body refs instead of a last-name match',
    () {
      expect(
        () => Importer().import({
          'openapi': '3.1.0',
          'info': {'title': 'Test API', 'version': '1.0.0'},
          'paths': <String, dynamic>{},
          'components': {
            'requestBodies': {
              'Target': {
                'content': {
                  'application/json': {
                    'schema': {'type': 'string'},
                  },
                },
              },
              'Alias': {r'$ref': '#/components/requestBodies/Owner/Target'},
            },
          },
        }),
        throwsA(isA<UnimplementedError>()),
      );
    },
  );

  test(
    'rejects unsupported deep example refs instead of a last-name match',
    () {
      expect(
        () => Importer().import({
          'openapi': '3.1.0',
          'info': {'title': 'Test API', 'version': '1.0.0'},
          'paths': {
            '/value': {
              'get': {
                'responses': {
                  '200': {
                    'description': 'OK',
                    'content': {
                      'application/json': {
                        'schema': {'type': 'string'},
                        'examples': {
                          'example': {
                            r'$ref': '#/components/examples/Owner/Target',
                          },
                        },
                      },
                    },
                  },
                },
              },
            },
          },
          'components': {
            'examples': {
              'Target': {'value': 'wrong target'},
            },
          },
        }),
        throwsA(isA<UnimplementedError>()),
      );
    },
  );
}
