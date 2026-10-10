import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  test('resolves reusable media in 3.1 and preserves the raw media key', () {
    final document = Importer().import({
      'openapi': '3.1.0',
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
              'Application/X-Ndjson; profile=detail': {
                r'$ref': '#/components/mediaTypes/Items',
              },
              'application/jsonl': {
                'itemSchema': {'type': 'integer'},
              },
            },
          },
        },
      },
    });
    final bodies = document.responses.single.resolved.bodies.toList();
    expect(bodies[0].rawContentType, 'Application/X-Ndjson; profile=detail');
    expect(bodies[0].delivery, ResponseDelivery.ndjson);
    expect(bodies[0].model, isA<IntegerModel>());
    expect(bodies[1].delivery, ResponseDelivery.jsonLines);
    expect(bodies[1].model, isA<IntegerModel>());
  });

  test('resolves media chains in 3.2 and ignores reference siblings', () {
    final document = Importer().import({
      'openapi': '3.2.0',
      'info': {'title': 'Media', 'version': '1'},
      'paths': <String, dynamic>{},
      'components': {
        'mediaTypes': {
          'Alias': {
            r'$ref': '#/components/mediaTypes/Items',
            'itemSchema': {'type': 'boolean'},
          },
          'Items': {
            'itemSchema': {'type': 'integer'},
          },
        },
        'responses': {
          'Items': {
            'description': 'Items',
            'content': {
              'application/x-ndjson': {
                r'$ref': '#/components/mediaTypes/Alias',
                'itemSchema': {'type': 'string'},
                'schema': {'properties': 3},
                'encoding': 3,
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

  test('media reference item sibling cannot add streaming to its target', () {
    final document = Importer().import({
      'openapi': '3.0.3',
      'info': {'title': 'Media', 'version': '1'},
      'paths': <String, dynamic>{},
      'components': {
        'mediaTypes': {
          'Complete': {
            'schema': {
              'type': 'array',
              'items': {'type': 'integer'},
            },
          },
        },
        'responses': {
          'Items': {
            'description': 'Items',
            'content': {
              'application/x-ndjson': {
                r'$ref': '#/components/mediaTypes/Complete',
                'itemSchema': {'type': 'integer'},
              },
            },
          },
        },
      },
    });
    final normalized = const ContentTypeNormalizer().apply(document);
    final body = normalized.responses.single.resolved.bodies.single;
    expect(body.delivery, ResponseDelivery.complete);
    expect(body.model, isA<BinaryModel>());
  });

  test('retains properties beside an item schema reference', () {
    final document = Importer().import({
      'openapi': 'unknown',
      'info': {'title': 'Media', 'version': '1'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'Item': {
            'type': 'object',
            'properties': {
              'value': {'type': 'integer'},
            },
          },
        },
        'mediaTypes': {
          'Items': {
            'itemSchema': {
              r'$ref': '#/components/schemas/Item',
              'properties': {
                'extra': {'type': 'string'},
              },
              'required': ['extra'],
            },
          },
        },
        'responses': {
          'Items': {
            'description': 'Items',
            'content': {
              'application/jsonl': {r'$ref': '#/components/mediaTypes/Items'},
            },
          },
        },
      },
    });
    final body = document.responses.single.resolved.bodies.single;
    expect(body.delivery, ResponseDelivery.jsonLines);
    final model = body.model as AllOfModel;
    final base = model.models[0] as ClassModel;
    final sibling = model.models[1] as ClassModel;
    expect(base.properties.single.name, 'value');
    expect(base.properties.single.model, isA<IntegerModel>());
    expect(sibling.properties.single.name, 'extra');
    expect(sibling.properties.single.model, isA<StringModel>());
    expect(sibling.properties.single.isRequired, isTrue);
  });

  test('throws when a consumed media chain has a missing internal target', () {
    expect(
      () => Importer().import({
        'openapi': '3.2.0',
        'info': {'title': 'Media', 'version': '1'},
        'paths': <String, dynamic>{},
        'components': {
          'mediaTypes': {
            'Alias': {r'$ref': '#/components/mediaTypes/Missing'},
          },
          'responses': {
            'Items': {
              'description': 'Items',
              'content': {
                'application/x-ndjson': {
                  r'$ref': '#/components/mediaTypes/Alias',
                },
              },
            },
          },
        },
      }),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('does not resolve unused missing or cyclic media aliases', () {
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
          'Missing': {r'$ref': '#/components/mediaTypes/Absent'},
          'External': {r'$ref': 'other.yaml#/components/mediaTypes/Items'},
          'Cycle': {r'$ref': '#/components/mediaTypes/Cycle'},
          'UnconsumedItem': {
            'itemSchema': {r'$ref': '#/components/schemas/Absent'},
          },
        },
      },
    });
    expect(document.operations, hasLength(1));
    expect(document.responses.single.resolved.bodies, isEmpty);
  });

  test('consumed external media reference throws despite local siblings', () {
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
                  r'$ref': 'https://example.test/media.json#/Items',
                  'itemSchema': {'type': 'integer'},
                },
              },
            },
          },
        },
      }),
      throwsA(isA<UnimplementedError>()),
    );
  });

  test('relative external media reference throws for a complete response', () {
    expect(
      () => Importer().import({
        'openapi': '3.2.0',
        'info': {'title': 'Media', 'version': '1'},
        'paths': <String, dynamic>{},
        'components': {
          'responses': {
            'Item': {
              'description': 'Item',
              'content': {
                'application/json': {
                  r'$ref': 'other.yaml#/components/mediaTypes/Complete',
                },
              },
            },
          },
        },
      }),
      throwsA(isA<UnimplementedError>()),
    );
  });

  test('consumed external item schema throws', () {
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
                  'itemSchema': {
                    r'$ref': r'https://example.test/schema.json#/$defs/Item',
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

  test('complete JSON does not resolve an unused external item schema', () {
    final document = Importer().import({
      'openapi': '3.2.0',
      'info': {'title': 'Media', 'version': '1'},
      'paths': <String, dynamic>{},
      'components': {
        'responses': {
          'Items': {
            'description': 'Items',
            'content': {
              'application/json': {
                'schema': {'type': 'string'},
                'itemSchema': {
                  r'$ref': r'https://example.test/schema.json#/$defs/Item',
                },
              },
            },
          },
        },
      },
    });
    final body = document.responses.single.resolved.bodies.single;
    expect(body.delivery, ResponseDelivery.complete);
    expect(body.model, isA<StringModel>());
  });

  test('missing internal item schema is not an optional-field failure', () {
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
                  'itemSchema': {r'$ref': '#/components/schemas/Missing'},
                },
              },
            },
          },
        },
      }),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('unsupported local media target does not use external fallback', () {
    expect(
      () => Importer().import({
        'openapi': '3.2.0',
        'info': {'title': 'Media', 'version': '1'},
        'paths': <String, dynamic>{},
        'components': {
          'responses': {
            'Source': {
              'description': 'Source',
              'content': {
                'application/jsonl': {
                  'itemSchema': {'type': 'integer'},
                },
              },
            },
            'Items': {
              'description': 'Items',
              'content': {
                'application/jsonl': {
                  r'$ref':
                      '#/components/responses/Source/content/'
                      'application~1jsonl',
                },
              },
            },
          },
        },
      }),
      throwsA(isA<UnimplementedError>()),
    );
  });

  test('consumed cyclic media references throw an argument error', () {
    expect(
      () => Importer().import({
        'openapi': '3.2.0',
        'info': {'title': 'Media', 'version': '1'},
        'paths': <String, dynamic>{},
        'components': {
          'mediaTypes': {
            'First': {r'$ref': '#/components/mediaTypes/Second'},
            'Second': {r'$ref': '#/components/mediaTypes/First'},
          },
          'responses': {
            'Items': {
              'description': 'Items',
              'content': {
                'application/jsonl': {r'$ref': '#/components/mediaTypes/First'},
              },
            },
          },
        },
      }),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('malformed media reference retains its parse error', () {
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
                'application/jsonl': {r'$ref': 42},
              },
            },
          },
        },
      }),
      throwsA(isA<TypeError>()),
    );
  });

  test('request bodies reuse complete media schema and ignore item schema', () {
    final document = Importer().import({
      'openapi': '3.0.3',
      'info': {'title': 'Media', 'version': '1'},
      'paths': <String, dynamic>{},
      'components': {
        'mediaTypes': {
          'Complete': {
            'schema': {'type': 'string'},
            'itemSchema': {r'$ref': '#/components/schemas/Unconsumed'},
            'example': 'example value',
          },
          'Alias': {r'$ref': '#/components/mediaTypes/Complete'},
        },
        'requestBodies': {
          'Body': {
            'content': {
              'application/json': {r'$ref': '#/components/mediaTypes/Alias'},
            },
          },
        },
      },
    });
    final body = document.requestBodies.single as RequestBodyObject;
    final content = body.content.single as ModelRequestContent;
    expect(content.contentType, ContentType.json);
    expect(content.model, isA<StringModel>());
    expect(content.examples.single.value, 'example value');
  });

  test('header content keeps its unconsumed string fallback', () {
    final document = Importer().import({
      'openapi': '3.2.0',
      'info': {'title': 'Media', 'version': '1'},
      'paths': <String, dynamic>{},
      'components': {
        'headers': {
          'Value': {
            'content': {
              'application/json': {r'$ref': '#/components/mediaTypes/Missing'},
            },
          },
        },
      },
    });
    final header = document.responseHeaders.single as ResponseHeaderObject;
    expect(header.model, isA<StringModel>());
  });

  test('parameter content retains its existing unsupported-context error', () {
    expect(
      () => Importer().import({
        'openapi': '3.2.0',
        'info': {'title': 'Media', 'version': '1'},
        'paths': <String, dynamic>{},
        'components': {
          'parameters': {
            'Value': {
              'name': 'value',
              'in': 'query',
              'content': {
                'application/json': {
                  r'$ref': '#/components/mediaTypes/Missing',
                },
              },
            },
          },
        },
      }),
      throwsA(
        isA<ArgumentError>().having(
          (error) => error.message,
          'message',
          'Parameter Value must have a schema. '
              'Complex parameters via content are not supported.',
        ),
      ),
    );
  });
}
