import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  test('ignores inline Content-Type without importing its enum schema', () {
    final api = Importer().import({
      'openapi': '3.0.4',
      'info': {'title': 'Reserved response headers', 'version': '1.0.0'},
      'paths': {
        '/status': {
          'get': {
            'operationId': 'getStatus',
            'responses': {
              '200': {
                'description': 'Status',
                'headers': {
                  'Content-Type': {
                    'schema': {
                      'type': 'string',
                      'enum': ['text/plain'],
                    },
                  },
                },
                'content': {
                  'application/json': {
                    'schema': {'type': 'string'},
                  },
                },
              },
            },
          },
        },
      },
    });

    final response = api.operations.single.responses.values.single.resolved;
    expect(api.responseHeaders, isEmpty);
    expect(response.headers, isEmpty);
    expect(api.models, isEmpty);
    expect(response.bodies.single.contentType, ContentType.json);
    expect(response.bodies.single.rawContentType, 'application/json');
    expect(response.bodies.single.model, isA<StringModel>());
  });

  test('ignores mixed-case headers in component responses and header refs', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Reserved response headers', 'version': '1.0.0'},
      'paths': {
        '/component': {
          'get': {
            'operationId': 'getComponent',
            'responses': {
              '200': {r'$ref': '#/components/responses/Status'},
            },
          },
        },
        '/header-ref': {
          'get': {
            'operationId': 'getHeaderRef',
            'responses': {
              '200': {
                'description': 'Status',
                'headers': {
                  'CONTENT-TYPE': {r'$ref': '#/components/headers/MediaType'},
                },
              },
            },
          },
        },
      },
      'components': {
        'responses': {
          'Status': {
            'description': 'Status',
            'headers': {
              'cOnTeNt-TyPe': {
                'schema': {
                  'type': 'object',
                  'properties': {
                    'value': {'type': 'string'},
                  },
                },
              },
            },
          },
        },
        'headers': {
          'MediaType': {
            'schema': {
              'type': 'string',
              'enum': ['application/json'],
            },
          },
        },
      },
    });

    final componentOperation = api.operations.firstWhere(
      (operation) => operation.operationId == 'getComponent',
    );
    final headerRefOperation = api.operations.firstWhere(
      (operation) => operation.operationId == 'getHeaderRef',
    );
    expect(
      componentOperation.responses.values.single.resolved.headers,
      isEmpty,
    );
    expect(
      headerRefOperation.responses.values.single.resolved.headers,
      isEmpty,
    );
    expect(
      api.responses
          .singleWhere((response) => response.name == 'Status')
          .resolved
          .headers,
      isEmpty,
    );
    expect(api.responseHeaders.single.name, 'MediaType');
    expect(api.models.single, isA<EnumModel<String>>());
  });

  test('preserves response headers and Content-Type component identifiers', () {
    final api = Importer().import({
      'openapi': '3.0.4',
      'info': {'title': 'Reserved response headers', 'version': '1.0.0'},
      'paths': {
        '/status': {
          'get': {
            'operationId': 'getStatus',
            'responses': {
              '200': {
                'description': 'Status',
                'headers': {
                  'content-type': {
                    r'$ref': '#/components/headers/Content-Type',
                  },
                  'Accept': {
                    'schema': {'type': 'string'},
                  },
                  'Authorization': {
                    'schema': {'type': 'string'},
                  },
                  'X-Media-Type': {
                    r'$ref': '#/components/headers/Content-Type',
                  },
                },
              },
            },
          },
        },
      },
      'components': {
        'headers': {
          'Content-Type': {
            'description': 'A reusable header identifier',
            'schema': {
              'type': 'string',
              'enum': ['application/json'],
            },
          },
        },
      },
    });

    final headers =
        api.operations.single.responses.values.single.resolved.headers;
    expect(
      headers.keys,
      unorderedEquals(['Accept', 'Authorization', 'X-Media-Type']),
    );
    expect(headers['Accept']?.resolve().model, isA<StringModel>());
    expect(headers['Authorization']?.resolve().model, isA<StringModel>());
    expect(headers['X-Media-Type']?.resolve().model, isA<EnumModel<String>>());
    expect(headers['X-Media-Type']?.name, 'Content-Type');
    expect(
      headers['X-Media-Type']?.description,
      'A reusable header identifier',
    );
    expect(api.responseHeaders, hasLength(3));
  });
}
