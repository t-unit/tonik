import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  test('ignores reserved operation headers before importing their models', () {
    final api = Importer().import({
      'openapi': '3.0.4',
      'info': {'title': 'Reserved headers', 'version': '1.0.0'},
      'paths': {
        '/ping': {
          'get': {
            'operationId': 'getPing',
            'parameters': [
              {
                'name': 'Accept',
                'in': 'header',
                'required': true,
                'schema': {
                  'type': 'string',
                  'enum': ['application/json'],
                },
              },
              {
                'name': 'Content-Type',
                'in': 'header',
                'schema': {
                  'type': 'object',
                  'properties': {
                    'value': {'type': 'string'},
                  },
                },
              },
              {
                'name': 'Authorization',
                'in': 'header',
                'schema': {'type': 'string'},
              },
            ],
            'responses': {
              '204': {'description': 'No content'},
            },
          },
        },
      },
    });

    expect(api.requestHeaders, isEmpty);
    expect(api.operations.single.headers, isEmpty);
    expect(api.models, isEmpty);
  });

  test('ignores path-item headers case-insensitively', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Reserved headers', 'version': '1.0.0'},
      'paths': {
        '/probe': {
          'parameters': [
            {
              'name': 'aCcEpT',
              'in': 'header',
              'schema': {'type': 'string'},
            },
            {
              'name': 'CONTENT-TYPE',
              'in': 'header',
              'schema': {'type': 'string'},
            },
            {
              'name': 'authorization',
              'in': 'header',
              'schema': {'type': 'string'},
            },
          ],
          'get': {
            'operationId': 'probe',
            'responses': {
              '200': {'description': 'Success'},
            },
          },
        },
      },
    });

    expect(api.requestHeaders, isEmpty);
    expect(api.operations.single.headers, isEmpty);
    expect(api.models, isEmpty);
  });

  test('ignores referenced components and forward component aliases', () {
    final api = Importer().import({
      'openapi': '3.0.4',
      'info': {'title': 'Reserved headers', 'version': '1.0.0'},
      'paths': {
        '/probe': {
          'parameters': [
            {r'$ref': '#/components/parameters/MediaPreference'},
          ],
          'get': {
            'operationId': 'probe',
            'parameters': [
              {r'$ref': '#/components/parameters/MediaType'},
              {r'$ref': '#/components/parameters/Credentials'},
            ],
            'responses': {
              '200': {'description': 'Success'},
            },
          },
        },
      },
      'components': {
        'parameters': {
          'ForwardCredentials': {
            r'$ref': '#/components/parameters/Credentials',
          },
          'MediaPreference': {
            'name': 'accept',
            'in': 'header',
            'schema': {
              'type': 'string',
              'enum': ['application/json'],
            },
          },
          'MediaType': {
            'name': 'content-type',
            'in': 'header',
            'schema': {'type': 'string'},
          },
          'Credentials': {
            'name': 'AUTHORIZATION',
            'in': 'header',
            'schema': {
              'type': 'object',
              'properties': {
                'token': {'type': 'string'},
              },
            },
          },
        },
      },
    });

    expect(api.requestHeaders, isEmpty);
    expect(api.operations.single.headers, isEmpty);
    expect(api.models, isEmpty);
  });

  test('ignores reserved content parameters before requiring a schema', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Reserved headers', 'version': '1.0.0'},
      'paths': {
        '/probe': {
          'parameters': [
            {
              'name': 'Authorization',
              'in': 'header',
              'content': {
                'application/json': {
                  'schema': {'type': 'string'},
                },
              },
            },
          ],
          'get': {
            'operationId': 'probe',
            'parameters': [
              {
                'name': 'Accept',
                'in': 'header',
                'content': {
                  'application/json': {
                    'schema': {'type': 'string'},
                  },
                },
              },
              {r'$ref': '#/components/parameters/MediaType'},
            ],
            'responses': {
              '200': {'description': 'Success'},
            },
          },
        },
      },
      'components': {
        'parameters': {
          'MediaType': {
            'name': 'Content-Type',
            'in': 'header',
            'content': {
              'application/json': {
                'schema': {'type': 'string'},
              },
            },
          },
        },
      },
    });

    expect(api.requestHeaders, isEmpty);
    expect(api.operations.single.headers, isEmpty);
    expect(api.models, isEmpty);
  });

  test('preserves ordinary headers and reserved names in other locations', () {
    final api = Importer().import({
      'openapi': '3.0.4',
      'info': {'title': 'Reserved headers', 'version': '1.0.0'},
      'paths': {
        '/probe/{Content-Type}': {
          'get': {
            'operationId': 'probe',
            'parameters': [
              {r'$ref': '#/components/parameters/Authorization'},
              {
                'name': 'Accept-Language',
                'in': 'header',
                'schema': {'type': 'string'},
              },
              {
                'name': 'Accept',
                'in': 'query',
                'schema': {'type': 'string'},
              },
              {
                'name': 'Content-Type',
                'in': 'path',
                'required': true,
                'schema': {'type': 'string'},
              },
              {
                'name': 'Authorization',
                'in': 'cookie',
                'schema': {'type': 'string'},
              },
            ],
            'responses': {
              '200': {'description': 'Success'},
            },
          },
        },
      },
      'components': {
        'parameters': {
          'Authorization': {
            'name': 'X-Authorization',
            'in': 'header',
            'schema': {'type': 'string'},
          },
        },
      },
    });

    final operation = api.operations.single;
    expect(api.requestHeaders, hasLength(2));
    expect(
      operation.headers.map((header) => header.resolve().rawName),
      unorderedEquals(['X-Authorization', 'Accept-Language']),
    );
    expect(api.queryParameters.single, isA<QueryParameterObject>());
    expect(operation.queryParameters.single.resolve().rawName, 'Accept');
    expect(api.pathParameters.single, isA<PathParameterObject>());
    expect(operation.pathParameters.single.resolve().rawName, 'Content-Type');
    expect(api.cookieParameters.single, isA<CookieParameterObject>());
    expect(
      operation.cookieParameters.single.resolve().rawName,
      'Authorization',
    );
  });

  test('preserves security schemes and response headers', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Reserved headers', 'version': '1.0.0'},
      'paths': {
        '/probe': {
          'get': {
            'operationId': 'probe',
            'parameters': [
              {
                'name': 'Authorization',
                'in': 'header',
                'schema': {'type': 'string'},
              },
            ],
            'security': [
              {'BearerAuth': <String>[]},
            ],
            'responses': {
              '200': {
                'description': 'Success',
                'headers': {
                  'Authorization': {
                    'schema': {'type': 'string'},
                  },
                },
              },
            },
          },
        },
      },
      'components': {
        'securitySchemes': {
          'BearerAuth': {'type': 'http', 'scheme': 'bearer'},
        },
      },
    });

    expect(api.requestHeaders, isEmpty);
    expect(api.operations.single.headers, isEmpty);
    expect(
      api.operations.single.securitySchemes.single,
      isA<HttpSecurityScheme>().having(
        (scheme) => scheme.scheme,
        'scheme',
        'bearer',
      ),
    );
    expect(
      api.operations.single.responses.values.single.resolved.headers.keys,
      ['Authorization'],
    );
    expect(api.responseHeaders.single, isA<ResponseHeaderObject>());
  });
}
