import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  const document = {
    'openapi': '3.0.3',
    'info': {'title': 'JSON query parameters', 'version': '1.0.0'},
    'paths': <String, dynamic>{},
  };

  test('imports the minimal optional arbitrary object query parameter', () {
    final api = Importer().import({
      ...document,
      'paths': {
        '/items': {
          'get': {
            'parameters': [
              {
                'name': 'filter',
                'in': 'query',
                'content': {
                  'application/json': {
                    'schema': {'type': 'object'},
                  },
                },
              },
            ],
            'responses': {
              '204': {'description': 'No content'},
            },
          },
        },
      },
    });

    final parameter = api.operations.single.queryParameters.single.resolve();
    expect(parameter.rawName, 'filter');
    expect(parameter.isRequired, isFalse);
    expect(parameter.encoding, QueryParameterEncoding.json);
    expect(parameter.model, isA<MapModel>());
    expect((parameter.model as MapModel).valueModel, isA<AnyModel>());
    expect(parameter.defaultValue, isNull);
  });

  test('imports a required inline object and media type example', () {
    final api = Importer().import({
      ...document,
      'components': {
        'parameters': {
          'Filter': {
            'name': 'filter',
            'in': 'query',
            'required': true,
            'content': {
              'application/json': {
                'schema': {
                  'type': 'object',
                  'properties': {
                    'status': {'type': 'string'},
                  },
                },
                'example': {'status': 'active'},
              },
            },
          },
        },
      },
    });

    final parameter = api.queryParameters.single.resolve();
    final model = parameter.model as ClassModel;
    expect(parameter.isRequired, isTrue);
    expect(parameter.encoding, QueryParameterEncoding.json);
    expect(model.properties.single.name, 'status');
    expect(model.properties.single.model, isA<StringModel>());
    expect(parameter.examples.single.value, {'status': 'active'});
  });

  test('preserves JSON encoding through parameter and schema references', () {
    final api = Importer().import({
      ...document,
      'paths': {
        '/items': {
          'get': {
            'parameters': [
              {r'$ref': '#/components/parameters/Filter'},
            ],
            'responses': {
              '204': {'description': 'No content'},
            },
          },
        },
      },
      'components': {
        'parameters': {
          'Filter': {
            'name': 'filter',
            'in': 'query',
            'required': true,
            'content': {
              'application/json': {
                'schema': {r'$ref': '#/components/schemas/Filter'},
              },
            },
          },
        },
        'schemas': {
          'Filter': {
            'type': 'object',
            'properties': {
              'status': {'type': 'string'},
            },
          },
        },
      },
    });

    final parameter = api.operations.single.queryParameters.single.resolve();
    expect(parameter.encoding, QueryParameterEncoding.json);
    expect(parameter.isRequired, isTrue);
    expect(parameter.model, same(api.models.whereType<ClassModel>().single));
  });

  test('imports a default from an inline JSON content schema', () {
    final api = Importer().import({
      ...document,
      'components': {
        'parameters': {
          'Limit': {
            'name': 'limit',
            'in': 'query',
            'content': {
              'application/json': {
                'schema': {'type': 'integer', 'default': 10},
              },
            },
          },
        },
      },
    });

    final parameter = api.queryParameters.single.resolve();
    expect(parameter.defaultValue, 10);
    expect(parameter.effectiveDefaultValue, 10);
    expect(parameter.isRequired, isFalse);
  });

  test('inherits defaults from referenced JSON content schemas', () {
    final api = Importer().import({
      ...document,
      'components': {
        'parameters': {
          'Status': {
            'name': 'status',
            'in': 'query',
            'content': {
              'application/json': {
                'schema': {r'$ref': '#/components/schemas/Status'},
              },
            },
          },
        },
        'schemas': {
          'Status': {'type': 'string', 'default': 'active'},
        },
      },
    });

    final parameter = api.queryParameters.single.resolve();
    expect(parameter.defaultValue, isNull);
    expect(parameter.effectiveDefaultValue, 'active');
    expect(parameter.isRequired, isFalse);
  });

  test('recognizes JSON suffix media types with parameters', () {
    final api = Importer().import({
      ...document,
      'components': {
        'parameters': {
          'Filter': {
            'name': 'filter',
            'in': 'query',
            'content': {
              'application/vnd.filter+json; charset=utf-8': {
                'schema': {'type': 'object'},
              },
            },
          },
        },
      },
    });

    expect(
      api.queryParameters.single.resolve().encoding,
      QueryParameterEncoding.json,
    );
  });

  test('rejects parameters with both schema and content', () {
    expect(
      () => Importer().import({
        ...document,
        'components': {
          'parameters': {
            'Filter': {
              'name': 'filter',
              'in': 'query',
              'schema': {'type': 'string'},
              'content': {
                'application/json': {
                  'schema': {'type': 'object'},
                },
              },
            },
          },
        },
      }),
      throwsA(
        isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          'Parameter filter must have exactly one of schema or content.',
        ),
      ),
    );
  });

  test('rejects parameters with neither schema nor content', () {
    expect(
      () => Importer().import({
        ...document,
        'components': {
          'parameters': {
            'Filter': {'name': 'filter', 'in': 'query'},
          },
        },
      }),
      throwsA(
        isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          'Parameter filter must have exactly one of schema or content.',
        ),
      ),
    );
  });

  test('rejects empty parameter content', () {
    expect(
      () => Importer().import({
        ...document,
        'components': {
          'parameters': {
            'Filter': {
              'name': 'filter',
              'in': 'query',
              'content': <String, dynamic>{},
            },
          },
        },
      }),
      throwsA(
        isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          'Parameter filter content must have exactly one media type.',
        ),
      ),
    );
  });

  test('rejects multiple parameter content media types', () {
    expect(
      () => Importer().import({
        ...document,
        'components': {
          'parameters': {
            'Filter': {
              'name': 'filter',
              'in': 'query',
              'content': {
                'application/json': {
                  'schema': {'type': 'object'},
                },
                'text/plain': {
                  'schema': {'type': 'string'},
                },
              },
            },
          },
        },
      }),
      throwsA(
        isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          'Parameter filter content must have exactly one media type.',
        ),
      ),
    );
  });

  test('rejects non-JSON content explicitly', () {
    expect(
      () => Importer().import({
        ...document,
        'components': {
          'parameters': {
            'Filter': {
              'name': 'filter',
              'in': 'query',
              'content': {
                'text/plain': {
                  'schema': {'type': 'string'},
                },
              },
            },
          },
        },
      }),
      throwsA(
        isA<UnimplementedError>().having(
          (e) => e.message,
          'message',
          'Unsupported content media type text/plain for query parameter filter. Only JSON content is supported.',
        ),
      ),
    );
  });

  test('rejects content on non-query parameters explicitly', () {
    expect(
      () => Importer().import({
        ...document,
        'components': {
          'parameters': {
            'Filter': {
              'name': 'filter',
              'in': 'header',
              'content': {
                'application/json': {
                  'schema': {'type': 'object'},
                },
              },
            },
          },
        },
      }),
      throwsA(
        isA<UnimplementedError>().having(
          (e) => e.message,
          'message',
          'Parameter content is only supported for query parameters, '
              'found header parameter filter.',
        ),
      ),
    );
  });

  test('rejects JSON content without a schema explicitly', () {
    expect(
      () => Importer().import({
        ...document,
        'components': {
          'parameters': {
            'Filter': {
              'name': 'filter',
              'in': 'query',
              'content': {'application/json': <String, dynamic>{}},
            },
          },
        },
      }),
      throwsA(
        isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          'Content for query parameter filter must have a schema.',
        ),
      ),
    );
  });
}
