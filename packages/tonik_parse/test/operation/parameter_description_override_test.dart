import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  const spec = {
    'info': {'title': 'Descriptions', 'version': '1'},
    'paths': {
      '/items/{id}': {
        'get': {
          'operationId': 'getItem',
          'parameters': [
            {
              r'$ref': '#/components/parameters/Id',
              'description': 'Specific path',
            },
            {
              r'$ref': '#/components/parameters/Limit',
              'description': 'Specific query',
            },
            {
              r'$ref': '#/components/parameters/Token',
              'description': 'Specific header',
            },
            {
              r'$ref': '#/components/parameters/Session',
              'description': 'Specific cookie',
            },
          ],
          'responses': {
            '200': {
              'description': 'OK',
              'headers': {
                'X-Rate-Limit': {
                  r'$ref': '#/components/headers/RateLimit',
                  'description': 'Specific response header',
                },
              },
            },
          },
        },
      },
    },
    'components': {
      'parameters': {
        'Id': {
          'name': 'id',
          'in': 'path',
          'required': true,
          'description': 'Generic path',
          'schema': {'type': 'string'},
        },
        'Limit': {
          'name': 'limit',
          'in': 'query',
          'description': 'Generic query',
          'schema': {'type': 'integer'},
        },
        'Token': {
          'name': 'x-token',
          'in': 'header',
          'description': 'Generic header',
          'schema': {'type': 'string'},
        },
        'Session': {
          'name': 'session',
          'in': 'cookie',
          'description': 'Generic cookie',
          'schema': {'type': 'string'},
        },
      },
      'headers': {
        'RateLimit': {
          'description': 'Generic response header',
          'schema': {'type': 'integer'},
        },
      },
    },
  };

  test('3.0 ignores reference description siblings', () {
    final api = Importer().import({'openapi': '3.0.4', ...spec});
    final operation = api.operations.single;
    final response = operation.responses.values.single.resolved;

    expect(operation.pathParameters.single, isA<PathParameterAlias>());
    expect(
      operation.pathParameters.single.resolve().description,
      'Generic path',
    );
    expect(operation.queryParameters.single, isA<QueryParameterAlias>());
    expect(
      operation.queryParameters.single.resolve().description,
      'Generic query',
    );
    expect(operation.headers.single, isA<RequestHeaderAlias>());
    expect(operation.headers.single.resolve().description, 'Generic header');
    expect(operation.cookieParameters.single, isA<CookieParameterAlias>());
    expect(
      operation.cookieParameters.single.resolve().description,
      'Generic cookie',
    );
    expect(response.headers.values.single, isA<ResponseHeaderAlias>());
    expect(
      response.headers.values.single.resolve().description,
      'Generic response header',
    );
  });

  test('3.1 retains reference description siblings', () {
    final api = Importer().import({'openapi': '3.1.1', ...spec});
    final operation = api.operations.single;
    final response = operation.responses.values.single.resolved;

    expect(api.queryParameters.single.resolve().description, 'Generic query');
    expect(
      operation.pathParameters.single.resolve().description,
      'Specific path',
    );
    expect(
      operation.queryParameters.single.resolve().description,
      'Specific query',
    );
    expect(operation.headers.single.resolve().description, 'Specific header');
    expect(
      operation.cookieParameters.single.resolve().description,
      'Specific cookie',
    );
    expect(
      response.headers.values.single.resolve().description,
      'Specific response header',
    );
  });

  test('3.2 retains reference description siblings', () {
    final api = Importer().import({'openapi': '3.2.0', ...spec});
    final operation = api.operations.single;
    final response = operation.responses.values.single.resolved;

    expect(
      operation.pathParameters.single.resolve().description,
      'Specific path',
    );
    expect(
      operation.queryParameters.single.resolve().description,
      'Specific query',
    );
    expect(operation.headers.single.resolve().description, 'Specific header');
    expect(
      operation.cookieParameters.single.resolve().description,
      'Specific cookie',
    );
    expect(
      response.headers.values.single.resolve().description,
      'Specific response header',
    );
  });

  test('unknown versions retain reference description siblings', () {
    final api = Importer().import({'openapi': '4.0.0', ...spec});
    final operation = api.operations.single;

    expect(
      operation.queryParameters.single.resolve().description,
      'Specific query',
    );
  });

  const chainedSpec = {
    'info': {'title': 'Chained descriptions', 'version': '1'},
    'paths': {
      '/outer': {
        'get': {
          'operationId': 'outer',
          'parameters': [
            {
              r'$ref': '#/components/parameters/Use',
              'description': 'Operation description',
            },
          ],
          'responses': {
            '200': {'description': 'OK'},
          },
        },
      },
      '/fallback': {
        'get': {
          'operationId': 'fallback',
          'parameters': [
            {r'$ref': '#/components/parameters/Use'},
          ],
          'responses': {
            '200': {'description': 'OK'},
          },
        },
      },
    },
    'components': {
      'parameters': {
        'Use': {
          r'$ref': '#/components/parameters/Base',
          'description': 'Component alias description',
        },
        'Base': {
          'name': 'limit',
          'in': 'query',
          'description': 'Base description',
          'schema': {'type': 'integer'},
        },
      },
    },
  };

  test('3.1 uses the outer description and falls back through the chain', () {
    final api = Importer().import({'openapi': '3.1.1', ...chainedSpec});
    final outer = api.operations.firstWhere((op) => op.operationId == 'outer');
    final fallback = api.operations.firstWhere(
      (op) => op.operationId == 'fallback',
    );

    expect(outer.queryParameters.single, isA<QueryParameterAlias>());
    expect(
      outer.queryParameters.single.resolve().description,
      'Operation description',
    );
    expect(
      fallback.queryParameters.single.resolve().description,
      'Component alias description',
    );
    expect(outer.queryParameters.single.resolve().rawName, 'limit');
  });

  test('3.0 ignores descriptions at both reference levels', () {
    final api = Importer().import({'openapi': '3.0.4', ...chainedSpec});
    final outer = api.operations.firstWhere((op) => op.operationId == 'outer');
    final fallback = api.operations.firstWhere(
      (op) => op.operationId == 'fallback',
    );

    expect(
      outer.queryParameters.single.resolve().description,
      'Base description',
    );
    expect(
      fallback.queryParameters.single.resolve().description,
      'Base description',
    );
  });

  test('3.2 retains descriptions in a parameter reference chain', () {
    final api = Importer().import({'openapi': '3.2.0', ...chainedSpec});
    final fallback = api.operations.firstWhere(
      (op) => op.operationId == 'fallback',
    );

    expect(
      fallback.queryParameters.single.resolve().description,
      'Component alias description',
    );
  });

  test('unused cyclic parameter aliases remain inert', () {
    final api = Importer().import({
      'openapi': '3.1.1',
      'info': {'title': 'Cycles', 'version': '1'},
      'paths': <String, dynamic>{},
      'components': {
        'parameters': {
          'First': {r'$ref': '#/components/parameters/Second'},
          'Second': {r'$ref': '#/components/parameters/First'},
        },
      },
    });

    expect(api.queryParameters, isEmpty);
  });

  test('external reference is not skipped when its name matches an alias', () {
    expect(
      () => Importer().import({
        'openapi': '3.1.1',
        'info': {'title': 'External parameter', 'version': '1'},
        'paths': <String, dynamic>{},
        'components': {
          'parameters': {
            'External': {r'$ref': 'https://example.com/Base'},
            'Base': {r'$ref': '#/components/parameters/Actual'},
            'Actual': {
              'name': 'limit',
              'in': 'query',
              'schema': {'type': 'integer'},
            },
          },
        },
      }),
      throwsUnimplementedError,
    );
  });

  test('a consumed missing target in a chain throws', () {
    expect(
      () => Importer().import({
        'openapi': '3.1.1',
        'info': {'title': 'Missing parameter', 'version': '1'},
        'paths': {
          '/items': {
            'get': {
              'parameters': [
                {r'$ref': '#/components/parameters/Use'},
              ],
              'responses': {
                '200': {'description': 'OK'},
              },
            },
          },
        },
        'components': {
          'parameters': {
            'Use': {r'$ref': '#/components/parameters/Missing'},
          },
        },
      }),
      throwsArgumentError,
    );
  });

  const malformedTextSpec = {
    'info': {'title': 'Malformed description', 'version': '1'},
    'paths': {
      '/items': {
        'get': {
          'parameters': [
            {
              r'$ref': '#/components/parameters/Limit',
              'description': 7,
              'summary': 7,
            },
          ],
          'responses': {
            '200': {'description': 'OK'},
          },
        },
      },
    },
    'components': {
      'parameters': {
        'Limit': {
          'name': 'limit',
          'in': 'query',
          'description': 'Generic limit',
          'schema': {'type': 'integer'},
        },
      },
    },
  };

  test('3.0 omits malformed optional reference text', () {
    final api = Importer().import({'openapi': '3.0.4', ...malformedTextSpec});

    expect(
      api.operations.single.queryParameters.single.resolve().description,
      'Generic limit',
    );
  });

  test('3.1 omits malformed optional reference text', () {
    final api = Importer().import({'openapi': '3.1.1', ...malformedTextSpec});

    expect(
      api.operations.single.queryParameters.single.resolve().description,
      'Generic limit',
    );
  });
}
