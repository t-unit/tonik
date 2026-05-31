import 'package:collection/collection.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  group('Parameter defaultValue from schema-level default', () {
    const fileContent = {
      'openapi': '3.0.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': {
        '/items/{itemId}': {
          'get': {
            'operationId': 'getItem',
            'parameters': [
              {
                'name': 'itemId',
                'in': 'path',
                'required': true,
                'schema': {'type': 'string', 'default': 'main'},
              },
              {
                'name': 'limit',
                'in': 'query',
                'required': false,
                'schema': {'type': 'integer', 'default': 10},
              },
              {
                'name': 'X-Locale',
                'in': 'header',
                'required': false,
                'schema': {'type': 'string', 'default': 'en'},
              },
              {
                'name': 'session',
                'in': 'cookie',
                'required': false,
                'schema': {'type': 'string', 'default': 'anonymous'},
              },
            ],
            'responses': {
              '200': {'description': 'OK'},
            },
          },
        },
      },
    };

    test('path parameter carries schema default', () {
      final api = Importer().import(fileContent);
      final pathParams = api.pathParameters
          .whereType<PathParameterObject>()
          .toList();
      final itemId = pathParams.firstWhereOrNull((p) => p.rawName == 'itemId');
      expect(itemId, isNotNull);
      expect(itemId!.defaultValue, 'main');
    });

    test('query parameter carries schema default', () {
      final api = Importer().import(fileContent);
      final queryParams = api.queryParameters
          .whereType<QueryParameterObject>()
          .toList();
      final limit = queryParams.firstWhereOrNull((p) => p.rawName == 'limit');
      expect(limit, isNotNull);
      expect(limit!.defaultValue, 10);
    });

    test('header parameter carries schema default', () {
      final api = Importer().import(fileContent);
      final headers = api.requestHeaders
          .whereType<RequestHeaderObject>()
          .toList();
      final locale = headers.firstWhereOrNull((h) => h.rawName == 'X-Locale');
      expect(locale, isNotNull);
      expect(locale!.defaultValue, 'en');
    });

    test('cookie parameter carries schema default', () {
      final api = Importer().import(fileContent);
      final cookies = api.cookieParameters
          .whereType<CookieParameterObject>()
          .toList();
      final session = cookies.firstWhereOrNull((c) => c.rawName == 'session');
      expect(session, isNotNull);
      expect(session!.defaultValue, 'anonymous');
    });

    test('parameter without schema default leaves defaultValue null', () {
      final api = Importer().import({
        'openapi': '3.0.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': {
          '/things': {
            'get': {
              'operationId': 'listThings',
              'parameters': [
                {
                  'name': 'tag',
                  'in': 'query',
                  'required': false,
                  'schema': {'type': 'string'},
                },
              ],
              'responses': {
                '200': {'description': 'OK'},
              },
            },
          },
        },
      });

      final queryParams = api.queryParameters
          .whereType<QueryParameterObject>()
          .toList();
      final tag = queryParams.firstWhereOrNull((p) => p.rawName == 'tag');
      expect(tag, isNotNull);
      expect(tag!.defaultValue, isNull);
    });
  });

  group('Parameter resolve propagates defaultValue', () {
    test('QueryParameterAlias.resolve propagates defaultValue', () {
      final context = Context.initial();
      final inner = QueryParameterObject(
        name: 'limit',
        rawName: 'limit',
        description: null,
        isRequired: false,
        isDeprecated: false,
        allowEmptyValue: false,
        allowReserved: false,
        explode: false,
        model: IntegerModel(context: context),
        encoding: QueryParameterEncoding.form,
        context: context,
        examples: const [],
        defaultValue: 10,
      );
      final alias = QueryParameterAlias(
        name: 'limitAlias',
        parameter: inner,
        context: context,
      );

      final resolved = alias.resolve();
      expect(resolved.defaultValue, 10);
    });

    test('PathParameterAlias.resolve propagates defaultValue', () {
      final context = Context.initial();
      final inner = PathParameterObject(
        name: 'id',
        rawName: 'id',
        description: null,
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: false,
        model: StringModel(context: context),
        encoding: PathParameterEncoding.simple,
        context: context,
        examples: const [],
        defaultValue: 'main',
      );
      final alias = PathParameterAlias(
        name: 'idAlias',
        parameter: inner,
        context: context,
      );

      final resolved = alias.resolve();
      expect(resolved.defaultValue, 'main');
    });

    test('RequestHeaderAlias.resolve propagates defaultValue', () {
      final context = Context.initial();
      final inner = RequestHeaderObject(
        name: 'X-Locale',
        rawName: 'X-Locale',
        description: null,
        isRequired: false,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: false,
        model: StringModel(context: context),
        encoding: HeaderParameterEncoding.simple,
        context: context,
        examples: const [],
        defaultValue: 'en',
      );
      final alias = RequestHeaderAlias(
        name: 'LocaleAlias',
        header: inner,
        context: context,
      );

      final resolved = alias.resolve();
      expect(resolved.defaultValue, 'en');
    });

    test('CookieParameterAlias.resolve propagates defaultValue', () {
      final context = Context.initial();
      final inner = CookieParameterObject(
        name: 'session',
        rawName: 'session',
        description: null,
        isRequired: false,
        isDeprecated: false,
        explode: true,
        model: StringModel(context: context),
        encoding: CookieParameterEncoding.form,
        context: context,
        examples: const [],
        defaultValue: 'anonymous',
      );
      final alias = CookieParameterAlias(
        name: 'sessionAlias',
        parameter: inner,
        context: context,
      );

      final resolved = alias.resolve();
      expect(resolved.defaultValue, 'anonymous');
    });
  });
}
