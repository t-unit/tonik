import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  test('forward query aliases reuse the registered enum and parameter', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'parameters': {
          'SortAlias': {
            r'$ref': '#/components/parameters/Sort',
            'description': 'Alias sort.',
          },
          'Sort': {
            'name': 'sort',
            'in': 'query',
            'schema': {
              'type': 'string',
              'enum': ['asc', 'desc'],
            },
          },
        },
      },
    });

    final alias = api.queryParameters.whereType<QueryParameterAlias>().single;
    final target = api.queryParameters.whereType<QueryParameterObject>().single;
    expect(alias.parameter, same(target));
    expect(alias.description, 'Alias sort.');
    expect(target.context.path, ['components', 'parameters', 'Sort']);
    expect(
      api.models.whereType<EnumModel<String>>().single,
      same(target.model),
    );
  });

  test('forward header, path and cookie parameters retain target identity', () {
    final api = Importer().import({
      'openapi': '3.0.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'parameters': {
          'HeaderAlias': {r'$ref': '#/components/parameters/Header'},
          'Header': {
            'name': 'X-Value',
            'in': 'header',
            'schema': {'type': 'string'},
          },
          'PathAlias': {r'$ref': '#/components/parameters/Path'},
          'Path': {
            'name': 'id',
            'in': 'path',
            'required': true,
            'schema': {'type': 'integer'},
          },
          'CookieAlias': {r'$ref': '#/components/parameters/Cookie'},
          'Cookie': {
            'name': 'session',
            'in': 'cookie',
            'schema': {'type': 'string'},
          },
        },
      },
    });

    expect(
      api.requestHeaders.whereType<RequestHeaderAlias>().single.header,
      same(api.requestHeaders.whereType<RequestHeaderObject>().single),
    );
    expect(
      api.pathParameters.whereType<PathParameterAlias>().single.parameter,
      same(api.pathParameters.whereType<PathParameterObject>().single),
    );
    expect(
      api.cookieParameters.whereType<CookieParameterAlias>().single.parameter,
      same(api.cookieParameters.whereType<CookieParameterObject>().single),
    );
  });

  test('operation references reuse chained parameter components', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': {
        '/items': {
          'get': {
            'operationId': 'items',
            'parameters': [
              {r'$ref': '#/components/parameters/First'},
            ],
            'responses': <String, dynamic>{},
          },
        },
      },
      'components': {
        'parameters': {
          'First': {r'$ref': '#/components/parameters/Second'},
          'Second': {r'$ref': '#/components/parameters/Sort'},
          'Sort': {
            'name': 'sort',
            'in': 'query',
            'schema': {
              'type': 'string',
              'enum': ['asc', 'desc'],
            },
          },
        },
      },
    });

    final first = api.queryParameters
        .whereType<QueryParameterAlias>()
        .singleWhere((parameter) => parameter.name == 'First');
    final second = api.queryParameters
        .whereType<QueryParameterAlias>()
        .singleWhere((parameter) => parameter.name == 'Second');
    final target = api.queryParameters.whereType<QueryParameterObject>().single;
    final occurrence =
        api.operations.single.queryParameters.single as QueryParameterAlias;
    expect(occurrence.parameter, same(first));
    expect(first.parameter, same(second));
    expect(second.parameter, same(target));
    expect(
      api.models.whereType<EnumModel<String>>().single,
      same(target.model),
    );
  });

  test(
    'forward response header chains retain one model and canonical context',
    () {
      final api = Importer().import({
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'headers': {
            'First': {
              r'$ref': '#/components/headers/Second',
              'description': 'Alias state.',
            },
            'Second': {r'$ref': '#/components/headers/State'},
            'State': {
              'schema': {
                'type': 'string',
                'enum': ['ready', 'pending'],
              },
            },
          },
        },
      });

      final first = api.responseHeaders
          .whereType<ResponseHeaderAlias>()
          .singleWhere((header) => header.name == 'First');
      final second = api.responseHeaders
          .whereType<ResponseHeaderAlias>()
          .singleWhere((header) => header.name == 'Second');
      final target = api.responseHeaders
          .whereType<ResponseHeaderObject>()
          .single;
      expect(first.header, same(second));
      expect(second.header, same(target));
      expect(first.description, 'Alias state.');
      expect(target.context.path, ['components', 'headers', 'State']);
      expect(
        api.models.whereType<EnumModel<String>>().single,
        same(target.model),
      );
    },
  );

  test('response header component cycles fail with a reference diagnostic', () {
    expect(
      () => Importer().import({
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'headers': {
            'First': {r'$ref': '#/components/headers/Second'},
            'Second': {r'$ref': '#/components/headers/First'},
          },
        },
      }),
      throwsA(
        isA<ArgumentError>().having(
          (error) => error.message,
          'message',
          contains('Cyclic header reference'),
        ),
      ),
    );
  });
}
