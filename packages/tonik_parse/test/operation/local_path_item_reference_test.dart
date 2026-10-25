import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  test('resolves chained path-item pointers and URI encoding', () {
    final api = Importer().import({
      'openapi': '3.0.3',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': {
        '/pets': {
          'get': {
            'responses': {
              '200': {'description': 'OK'},
            },
          },
        },
        '/animals': {r'$ref': '#%2Fpaths%2F~1pets'},
        '/creatures': {r'$ref': '#/paths/~1animals'},
      },
    });

    expect(api.operations.map((operation) => operation.path), [
      '/pets',
      '/animals',
      '/creatures',
    ]);
    expect(api.operations.last.method, HttpMethod.get);
    expect(api.operations.last.responses.keys, [
      const ExplicitResponseStatus(statusCode: 200),
    ]);
  });

  test('detects cyclic path-item pointers across equivalent encodings', () {
    expect(
      () => Importer().import({
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': {
          '/first': {r'$ref': '#/paths/~1second'},
          '/second': {r'$ref': '#%2Fpaths%2F~1first'},
        },
      }),
      throwsArgumentError,
    );
  });

  test('rejects missing path-item targets', () {
    expect(
      () => Importer().import({
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': {
          '/animals': {r'$ref': '#/paths/~1pets'},
        },
      }),
      throwsArgumentError,
    );
  });

  test(
    'raw path-item aliases and a schema pointer share one payload and enum',
    () {
      final api = Importer().import({
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': {
          '/first': {r'$ref': '#/x-items/Shared'},
          '/second': {r'$ref': '#%2Fx-items%2FShared'},
        },
        'x-items': {
          'Shared': {
            'get': {
              'responses': {
                '200': {
                  'description': 'OK',
                  'content': {
                    'application/json': {
                      'schema': {
                        'type': 'object',
                        'properties': {
                          'color': {
                            'type': 'string',
                            'enum': ['red', 'green'],
                          },
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
          'schemas': {
            'Payload': {
              r'$ref':
                  '#/x-items/Shared/get/responses/200'
                  '/content/application~1json/schema',
            },
          },
        },
      });

      final payload = api.models.whereType<AliasModel>().single;
      final first = api
          .operations
          .first
          .responses
          .values
          .single
          .resolved
          .bodies
          .single
          .model;
      final second = api
          .operations
          .last
          .responses
          .values
          .single
          .resolved
          .bodies
          .single
          .model;
      expect(first, same(payload.resolved));
      expect(second, same(first));
      expect(api.models.whereType<ClassModel>(), hasLength(1));
      expect(api.models.whereType<EnumModel<String>>(), hasLength(1));
    },
  );

  test('repeated raw path-item aliases reuse inline payload models', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': {
        '/first': {r'$ref': '#/x-items/Shared'},
        '/second': {r'$ref': '#/x-items/Shared'},
      },
      'x-items': {
        'Shared': {
          'get': {
            'responses': {
              '200': {
                'description': 'OK',
                'content': {
                  'application/json': {
                    'schema': {
                      'type': 'object',
                      'properties': {
                        'color': {
                          'type': 'string',
                          'enum': ['red', 'green'],
                        },
                      },
                    },
                  },
                },
              },
            },
          },
        },
      },
    });

    final first = api
        .operations
        .first
        .responses
        .values
        .single
        .resolved
        .bodies
        .single
        .model;
    final second = api
        .operations
        .last
        .responses
        .values
        .single
        .resolved
        .bodies
        .single
        .model;
    expect(second, same(first));
    expect(api.models.whereType<ClassModel>(), hasLength(1));
    expect(api.models.whereType<EnumModel<String>>(), hasLength(1));
  });

  test('parsed path-item aliases reuse an existing inline payload model', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': {
        '/source': {
          'get': {
            'responses': {
              '200': {
                'description': 'OK',
                'content': {
                  'application/json': {
                    'schema': {
                      'type': 'object',
                      'properties': {
                        'color': {
                          'type': 'string',
                          'enum': ['red', 'green'],
                        },
                      },
                    },
                  },
                },
              },
            },
          },
        },
        '/alias': {r'$ref': '#/paths/~1source'},
      },
    });

    final source = api
        .operations
        .first
        .responses
        .values
        .single
        .resolved
        .bodies
        .single
        .model;
    final alias = api
        .operations
        .last
        .responses
        .values
        .single
        .resolved
        .bodies
        .single
        .model;
    expect(alias, same(source));
    expect(api.models.whereType<ClassModel>(), hasLength(1));
    expect(api.models.whereType<EnumModel<String>>(), hasLength(1));
  });

  test(
    'referenced media share request and response payloads across path aliases',
    () {
      final api = Importer().import({
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': {
          '/source': {
            'post': {
              'requestBody': {
                'content': {
                  'application/json': {
                    r'$ref': '#/components/mediaTypes/Payload',
                  },
                },
              },
              'responses': {
                '200': {
                  'description': 'OK',
                  'content': {
                    'application/json': {
                      r'$ref': '#/components/mediaTypes/Payload',
                    },
                  },
                },
              },
            },
          },
          '/alias': {r'$ref': '#/paths/~1source'},
        },
        'components': {
          'mediaTypes': {
            'Payload': {
              'schema': {
                'type': 'object',
                'properties': {
                  'color': {
                    'type': 'string',
                    'enum': ['red', 'green'],
                  },
                },
              },
            },
          },
        },
      });

      final source = api.operations.first;
      final alias = api.operations.last;
      final sourceResponse =
          source.responses.values.single.resolved.bodies.single.model;
      final aliasResponse =
          alias.responses.values.single.resolved.bodies.single.model;
      final sourceRequest =
          source.requestBody!.resolvedContent.single as ModelRequestContent;
      final aliasRequest =
          alias.requestBody!.resolvedContent.single as ModelRequestContent;
      expect(aliasResponse, same(sourceResponse));
      expect(sourceRequest.model, same(sourceResponse));
      expect(aliasRequest.model, same(sourceResponse));
      expect(api.models.whereType<ClassModel>(), hasLength(1));
      expect(api.models.whereType<EnumModel<String>>(), hasLength(1));
    },
  );

  test('referenced streaming media share item schemas across path aliases', () {
    final api =
        Importer(
          contentTypes: {'application/x-ndjson': StreamingContentType.ndjson},
        ).import({
          'openapi': '3.1.0',
          'info': {'title': 'Test API', 'version': '1.0.0'},
          'paths': {
            '/source': {
              'get': {
                'responses': {
                  '200': {
                    'description': 'OK',
                    'content': {
                      'application/x-ndjson': {
                        r'$ref': '#/components/mediaTypes/Payload',
                      },
                    },
                  },
                },
              },
            },
            '/alias': {r'$ref': '#/paths/~1source'},
          },
          'components': {
            'mediaTypes': {
              'Payload': {
                'schema': {r'$ref': 'other.yaml#/Ignored'},
                'itemSchema': {
                  'type': 'object',
                  'properties': {
                    'color': {
                      'type': 'string',
                      'enum': ['red', 'green'],
                    },
                  },
                },
              },
            },
          },
        });

    final source =
        api.operations.first.responses.values.single.resolved.bodies.single;
    final alias =
        api.operations.last.responses.values.single.resolved.bodies.single;
    expect(source.delivery, ResponseDelivery.ndjson);
    expect(alias.model, same(source.model));
    expect(api.models.whereType<ClassModel>(), hasLength(1));
    expect(api.models.whereType<EnumModel<String>>(), hasLength(1));
  });

  test(
    'sharing referenced media does not resolve ignored content or item schemas',
    () {
      final api = Importer().import({
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': {
          '/source': {
            'get': {
              'responses': {
                '200': {
                  'description': 'OK',
                  'headers': {
                    'X-Note': {
                      'content': {
                        'application/json': {
                          r'$ref': 'other.yaml#/IgnoredMedia',
                        },
                      },
                    },
                  },
                  'content': {
                    'application/json': {
                      r'$ref': '#/components/mediaTypes/Payload',
                    },
                  },
                },
              },
            },
          },
          '/alias': {r'$ref': '#/paths/~1source'},
        },
        'components': {
          'mediaTypes': {
            'Payload': {
              'schema': {'type': 'string'},
              'itemSchema': {r'$ref': 'other.yaml#/IgnoredItem'},
            },
          },
        },
      });

      final source = api
          .operations
          .first
          .responses
          .values
          .single
          .resolved
          .bodies
          .single
          .model;
      final alias = api
          .operations
          .last
          .responses
          .values
          .single
          .resolved
          .bodies
          .single
          .model;
      expect(source, isA<StringModel>());
      expect(alias, same(source));
    },
  );
}
