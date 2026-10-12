import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  test('ordinary JSON preserves malformed schema reference errors', () {
    expect(
      () => Importer().import({
        'openapi': '3.0.3',
        'info': {'title': 'Media', 'version': '1'},
        'paths': <String, dynamic>{},
        'components': {
          'responses': {
            'Value': {
              'description': 'Value',
              'content': {
                'application/json': {
                  'schema': {r'$ref': 42},
                },
              },
            },
          },
        },
      }),
      throwsA(isA<TypeError>()),
    );
  });

  test('malformed item references are not omitted as optional fields', () {
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
                  'schema': {'type': 'string'},
                  'itemSchema': {r'$ref': 42},
                },
              },
            },
          },
        },
      }),
      throwsA(isA<TypeError>()),
    );
  });

  test('nested malformed item references retain their error', () {
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
                'application/jsonl': {
                  'itemSchema': {
                    'type': 'object',
                    'properties': {
                      'values': {
                        'type': 'array',
                        'items': {r'$ref': 42},
                      },
                    },
                  },
                },
              },
            },
          },
        },
      }),
      throwsA(isA<TypeError>()),
    );
  });

  test('nested malformed ordinary schema references retain their error', () {
    expect(
      () => Importer().import({
        'openapi': '3.1.0',
        'info': {'title': 'Media', 'version': '1'},
        'paths': <String, dynamic>{},
        'components': {
          'requestBodies': {
            'Body': {
              'content': {
                'application/json': {
                  'schema': {
                    'type': 'object',
                    'properties': {
                      'value': {r'$ref': 42},
                    },
                  },
                },
              },
            },
          },
        },
      }),
      throwsA(isA<TypeError>()),
    );
  });

  test('media reference annotations recover independently of the target', () {
    final document = Importer().import({
      'openapi': '3.2.0',
      'info': {'title': 'Media', 'version': '1'},
      'paths': <String, dynamic>{},
      'components': {
        'mediaTypes': {
          'Items': {
            'itemSchema': {'type': 'integer'},
          },
          'Alias': {r'$ref': '#/components/mediaTypes/Items', 'summary': 42},
        },
        'responses': {
          'Items': {
            'description': 'Items',
            'content': {
              'application/x-ndjson': {
                r'$ref': '#/components/mediaTypes/Alias',
                'description': 42,
                'itemSchema': {r'$ref': 42},
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

  test('unused media aliases with malformed annotations remain unconsumed', () {
    final document = Importer().import({
      'openapi': '3.2.0',
      'info': {'title': 'Media', 'version': '1'},
      'paths': {
        '/health': {
          'get': {
            'responses': {
              '204': {'description': 'Healthy'},
            },
          },
        },
      },
      'components': {
        'mediaTypes': {
          'Unused': {
            r'$ref': '#/components/mediaTypes/Missing',
            'description': 42,
            'summary': 42,
          },
        },
      },
    });
    expect(document.operations, hasLength(1));
    expect(document.responses.single.resolved.bodies, isEmpty);
  });

  test('external examples and chains retain valid examples and media', () {
    final document = Importer().import({
      'openapi': '3.2.0',
      'info': {'title': 'Media', 'version': '1'},
      'paths': <String, dynamic>{},
      'components': {
        'examples': {
          'Remote': {r'$ref': 'https://example.test/examples.yaml#/Value'},
          'Alias': {r'$ref': '#/components/examples/Remote'},
          'Local': {'value': 7},
        },
        'responses': {
          'Items': {
            'description': 'Items',
            'content': {
              'application/x-ndjson': {
                'itemSchema': {'type': 'integer'},
                'examples': {
                  'remote': {r'$ref': 'other.yaml#/Example'},
                  'chain': {r'$ref': '#/components/examples/Alias'},
                  'inline': {'value': 3},
                  'local': {r'$ref': '#/components/examples/Local'},
                },
              },
              'application/json': {
                'schema': {'type': 'string'},
                'example': 'complete',
              },
            },
          },
        },
      },
    });
    final bodies = document.responses.single.resolved.bodies.toList();
    expect(bodies[0].delivery, ResponseDelivery.ndjson);
    expect(bodies[0].model, isA<IntegerModel>());
    expect(bodies[0].examples.map((example) => example.name), [
      'inline',
      'local',
    ]);
    expect(bodies[0].examples.map((example) => example.value), [3, 7]);
    expect(bodies[1].delivery, ResponseDelivery.complete);
    expect(bodies[1].model, isA<StringModel>());
    expect(bodies[1].examples.single.value, 'complete');
  });

  test('malformed example references retain their parse error', () {
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
                  'itemSchema': {'type': 'integer'},
                  'examples': {
                    'invalid': {r'$ref': 42},
                  },
                },
              },
            },
          },
        },
      }),
      throwsA(isA<TypeError>()),
    );
  });

  test(
    'unsupported local example references retain their resolution error',
    () {
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
                    'itemSchema': {'type': 'integer'},
                    'examples': {
                      'unsupported': {r'$ref': '#/paths/Example'},
                    },
                  },
                },
              },
            },
          },
        }),
        throwsA(isA<UnimplementedError>()),
      );
    },
  );
}
