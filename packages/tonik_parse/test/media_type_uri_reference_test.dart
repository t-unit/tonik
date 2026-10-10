import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  test('query-only external media reference keeps complete fallback', () {
    final document = Importer().import({
      'openapi': '3.2.0',
      'info': {'title': 'Media', 'version': '1'},
      'paths': <String, dynamic>{},
      'components': {
        'responses': {
          'Items': {
            'description': 'Items',
            'content': {
              'application/x-ndjson': {
                r'$ref': '?revision=2#/components/mediaTypes/Items',
                'itemSchema': {'type': 'integer'},
              },
            },
          },
        },
      },
    });
    final body = document.responses.single.resolved.bodies.single;
    expect(body.delivery, ResponseDelivery.complete);
    expect(body.model, isA<BinaryModel>());
  });

  test('query-only external item schema throws when consumed', () {
    expect(
      () => Importer().import({
        'openapi': '3.2.0',
        'info': {'title': 'Media', 'version': '1'},
        'paths': <String, dynamic>{},
        'components': {
          'responses': {
            'Items': {
              'description': 'Items',
              'content': {
                'application/x-ndjson': {
                  'itemSchema': {r'$ref': '?revision=2#/Item'},
                },
              },
            },
          },
        },
      }),
      throwsA(isA<UnimplementedError>()),
    );
  });

  test('query-only external example omits only that example', () {
    final document = Importer().import({
      'openapi': '3.2.0',
      'info': {'title': 'Media', 'version': '1'},
      'paths': <String, dynamic>{},
      'components': {
        'responses': {
          'Items': {
            'description': 'Items',
            'content': {
              'application/x-ndjson': {
                'itemSchema': {'type': 'integer'},
                'examples': {
                  'remote': {r'$ref': '?revision=2#/Example'},
                  'local': {'value': 7},
                },
              },
            },
          },
        },
      },
    });
    final body = document.responses.single.resolved.bodies.single;
    expect(body.delivery, ResponseDelivery.ndjson);
    expect(body.model, isA<IntegerModel>());
    expect(body.examples.single.name, 'local');
    expect(body.examples.single.value, 7);
  });

  test('percent-encoded media pointer separators resolve before lookup', () {
    final document = Importer().import({
      'openapi': '3.2.0',
      'info': {'title': 'Media', 'version': '1'},
      'paths': <String, dynamic>{},
      'components': {
        'mediaTypes': {
          'Items': {
            'itemSchema': {'type': 'integer'},
          },
        },
        'responses': {
          'Items': {
            'description': 'Items',
            'content': {
              'application/x-ndjson': {
                r'$ref': '#%2Fcomponents%2FmediaTypes%2FItems',
              },
            },
          },
        },
      },
    });
    final body = document.responses.single.resolved.bodies.single;
    expect(body.delivery, ResponseDelivery.ndjson);
    expect(body.model, isA<IntegerModel>());
  });

  test('percent-encoded nested media targets remain unsupported', () {
    expect(
      () => Importer().import({
        'openapi': '3.2.0',
        'info': {'title': 'Media', 'version': '1'},
        'paths': <String, dynamic>{},
        'components': {
          'mediaTypes': {
            'Items/schema': {
              'itemSchema': {'type': 'integer'},
            },
          },
          'responses': {
            'Items': {
              'description': 'Items',
              'content': {
                'application/x-ndjson': {
                  r'$ref': '#/components/mediaTypes/Items%2Fschema',
                },
              },
            },
          },
        },
      }),
      throwsA(isA<UnimplementedError>()),
    );
  });

  test('JSON Pointer escapes stay within one media component name', () {
    final document = Importer().import({
      'openapi': '3.2.0',
      'info': {'title': 'Media', 'version': '1'},
      'paths': <String, dynamic>{},
      'components': {
        'mediaTypes': {
          'Items/~schema': {
            'itemSchema': {'type': 'integer'},
          },
        },
        'responses': {
          'Items': {
            'description': 'Items',
            'content': {
              'application/x-ndjson': {
                r'$ref': '#/components/mediaTypes/Items~1~0schema',
              },
            },
          },
        },
      },
    });
    final body = document.responses.single.resolved.bodies.single;
    expect(body.delivery, ResponseDelivery.ndjson);
    expect(body.model, isA<IntegerModel>());
  });
}
