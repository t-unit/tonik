import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/parameter_name_normalizer.dart';

void main() {
  group('normalizeRequestParameters', () {
    test('normalizes path parameters', () {
      final result = normalizeRequestParameters(
        pathParameters: {
          createPathParameter('user_id'),
          createPathParameter('order_number'),
        },
        queryParameters: {},
        headers: {},
      );

      expect(result.pathParameters.map((r) => r.normalizedName).toList(), [
        'userId',
        'orderNumber',
      ]);
    });

    test('normalizes query parameters', () {
      final result = normalizeRequestParameters(
        pathParameters: {},
        cookieParameters: {},
        queryParameters: {
          createQueryParameter('sort_by'),
          createQueryParameter('filter'),
        },
        headers: {},
      );

      expect(result.queryParameters.map((r) => r.normalizedName).toList(), [
        'sortBy',
        'filter',
      ]);
    });

    test('normalizes header parameters and removes x- prefix', () {
      final result = normalizeRequestParameters(
        pathParameters: {},
        cookieParameters: {},
        queryParameters: {},
        headers: {
          createHeader('x-api-key'),
          createHeader('x-trace-id'),
          createHeader('content-type'),
        },
      );

      expect(result.headers.map((r) => r.normalizedName).toList(), [
        'apiKey',
        'traceId',
        'contentType',
      ]);
    });

    test(
      'makes duplicates unique across parameter types by adding type suffixes',
      () {
        final result = normalizeRequestParameters(
          pathParameters: {createPathParameter('id')},
          queryParameters: {createQueryParameter('id')},
          headers: {createHeader('id')},
        );

        expect(result.pathParameters.map((r) => r.normalizedName).toList(), [
          'idPath',
        ]);
        expect(result.queryParameters.map((r) => r.normalizedName).toList(), [
          'idQuery',
        ]);
        expect(result.headers.map((r) => r.normalizedName).toList(), [
          'idHeader',
        ]);
      },
    );

    test('handles Dart keywords', () {
      final result = normalizeRequestParameters(
        pathParameters: {createPathParameter('class')},
        queryParameters: {createQueryParameter('void')},
        headers: {createHeader('switch')},
      );

      expect(result.pathParameters.map((r) => r.normalizedName).toList(), [
        r'$class',
      ]);
      expect(result.queryParameters.map((r) => r.normalizedName).toList(), [
        r'$void',
      ]);
      expect(result.headers.map((r) => r.normalizedName).toList(), [
        r'$switch',
      ]);
    });

    test('preserves parameter metadata', () {
      final result = normalizeRequestParameters(
        pathParameters: {createPathParameter('id', isRequired: true)},
        queryParameters: {createQueryParameter('filter', isDeprecated: true)},
        headers: {createHeader('api-key', isRequired: true)},
      );

      expect(result.pathParameters.first.parameter.isRequired, isTrue);
      expect(result.queryParameters.first.parameter.isDeprecated, isTrue);
      expect(result.headers.first.parameter.isRequired, isTrue);
    });
  });

  group('nameOverride support', () {
    test('uses nameOverride for path parameters', () {
      final param = createPathParameter('user_id')..nameOverride = 'userId';

      final result = normalizeRequestParameters(
        pathParameters: {param},
        queryParameters: {},
        headers: {},
      );

      expect(result.pathParameters.first.normalizedName, 'userId');
      expect(
        result.pathParameters.first.parameter.rawName,
        'user_id',
        reason: 'Original raw name should be preserved for URL encoding',
      );
    });

    test('uses nameOverride for query parameters', () {
      final param = createQueryParameter('sort-by')..nameOverride = 'orderBy';

      final result = normalizeRequestParameters(
        pathParameters: {},
        cookieParameters: {},
        queryParameters: {param},
        headers: {},
      );

      expect(result.queryParameters.first.normalizedName, 'orderBy');
      expect(
        result.queryParameters.first.parameter.rawName,
        'sort-by',
        reason: 'Original raw name should be preserved for query string',
      );
    });

    test('uses nameOverride for headers', () {
      final header = createHeader('x-api-key')..nameOverride = 'apiToken';

      final result = normalizeRequestParameters(
        pathParameters: {},
        cookieParameters: {},
        queryParameters: {},
        headers: {header},
      );

      expect(result.headers.first.normalizedName, 'apiToken');
      expect(
        result.headers.first.parameter.rawName,
        'x-api-key',
        reason: 'Original raw name should be preserved for HTTP headers',
      );
    });

    test('sanitizes nameOverride values', () {
      final param = createQueryParameter('filter')
        ..nameOverride = 'my-custom_filter';

      final result = normalizeRequestParameters(
        pathParameters: {},
        cookieParameters: {},
        queryParameters: {param},
        headers: {},
      );

      expect(result.queryParameters.first.normalizedName, 'myCustomFilter');
    });

    test('makes nameOverride unique when duplicate', () {
      final param1 = createQueryParameter('field1')..nameOverride = 'value';

      final param2 = createQueryParameter('field2')..nameOverride = 'value';

      final result = normalizeRequestParameters(
        pathParameters: {},
        cookieParameters: {},
        queryParameters: {param1, param2},
        headers: {},
      );

      final names = result.queryParameters
          .map((r) => r.normalizedName)
          .toList();
      expect(names.length, 2, reason: 'Should have 2 parameters');
      expect(names.toSet().length, 2, reason: 'Should have unique names');
      expect(names.contains('value'), isTrue);
      expect(
        names.contains('value2'),
        isTrue,
        reason: 'Second duplicate must be deterministically pinned to value2',
      );
    });

    test('applies type suffixes to nameOverride duplicates across types', () {
      final path = createPathParameter('id')..nameOverride = 'identifier';
      final query = createQueryParameter('id')..nameOverride = 'identifier';
      final header = createHeader('id')..nameOverride = 'identifier';

      final result = normalizeRequestParameters(
        pathParameters: {path},
        queryParameters: {query},
        headers: {header},
      );

      expect(result.pathParameters.first.normalizedName, 'identifierPath');
      expect(result.queryParameters.first.normalizedName, 'identifierQuery');
      expect(result.headers.first.normalizedName, 'identifierHeader');
    });

    test('falls back to generated name when nameOverride is null', () {
      final param = createQueryParameter('sort_by');

      final result = normalizeRequestParameters(
        pathParameters: {},
        cookieParameters: {},
        queryParameters: {param},
        headers: {},
      );

      expect(result.queryParameters.first.normalizedName, 'sortBy');
    });

    test('uses nameOverride for cookie parameters', () {
      final cookie = createCookieParameter('session_id')
        ..nameOverride = 'mySession';

      final result = normalizeRequestParameters(
        pathParameters: {},
        queryParameters: {},
        headers: {},
        cookieParameters: {cookie},
      );

      expect(result.cookieParameters.first.normalizedName, 'mySession');
      expect(
        result.cookieParameters.first.parameter.rawName,
        'session_id',
        reason: 'Original raw name should be preserved for Cookie header',
      );
    });

    test(
      'applies type suffixes to nameOverride duplicates including cookies',
      () {
        final path = createPathParameter('id')..nameOverride = 'identifier';
        final query = createQueryParameter('id')..nameOverride = 'identifier';
        final header = createHeader('id')..nameOverride = 'identifier';
        final cookie = createCookieParameter('id')..nameOverride = 'identifier';

        final result = normalizeRequestParameters(
          pathParameters: {path},
          queryParameters: {query},
          headers: {header},
          cookieParameters: {cookie},
        );

        expect(result.pathParameters.first.normalizedName, 'identifierPath');
        expect(result.queryParameters.first.normalizedName, 'identifierQuery');
        expect(result.headers.first.normalizedName, 'identifierHeader');
        expect(
          result.cookieParameters.first.normalizedName,
          'identifierCookie',
        );
      },
    );
  });

  group('cookie parameter normalization', () {
    test('normalizes cookie parameter names', () {
      final result = normalizeRequestParameters(
        pathParameters: {},
        queryParameters: {},
        headers: {},
        cookieParameters: {
          createCookieParameter('session_id'),
          createCookieParameter('user-token'),
        },
      );

      expect(result.cookieParameters.map((r) => r.normalizedName).toList(), [
        'sessionId',
        'userToken',
      ]);
    });

    test('handles Dart keywords in cookie names', () {
      final result = normalizeRequestParameters(
        pathParameters: {},
        queryParameters: {},
        headers: {},
        cookieParameters: {createCookieParameter('class')},
      );

      expect(result.cookieParameters.map((r) => r.normalizedName).toList(), [
        r'$class',
      ]);
    });

    test('preserves cookie parameter metadata', () {
      final result = normalizeRequestParameters(
        pathParameters: {},
        queryParameters: {},
        headers: {},
        cookieParameters: {
          createCookieParameter(
            'session',
            isRequired: true,
            isDeprecated: true,
          ),
        },
      );

      expect(result.cookieParameters.first.parameter.isRequired, isTrue);
      expect(result.cookieParameters.first.parameter.isDeprecated, isTrue);
    });

    test(
      'makes duplicates unique across parameter types including cookies',
      () {
        final result = normalizeRequestParameters(
          pathParameters: {createPathParameter('id')},
          queryParameters: {createQueryParameter('id')},
          headers: {createHeader('id')},
          cookieParameters: {createCookieParameter('id')},
        );

        expect(result.pathParameters.map((r) => r.normalizedName).toList(), [
          'idPath',
        ]);
        expect(result.queryParameters.map((r) => r.normalizedName).toList(), [
          'idQuery',
        ]);
        expect(result.headers.map((r) => r.normalizedName).toList(), [
          'idHeader',
        ]);
        expect(result.cookieParameters.map((r) => r.normalizedName).toList(), [
          'idCookie',
        ]);
      },
    );
  });

  group('reservedNames', () {
    test('adds type suffix when parameter collides with reserved name', () {
      final result = normalizeRequestParameters(
        pathParameters: {},
        queryParameters: {createQueryParameter('body')},
        headers: {createHeader('body')},
        cookieParameters: {createCookieParameter('body')},
        reservedNames: {'body'},
      );

      expect(result.queryParameters.map((r) => r.normalizedName).toList(), [
        'bodyQuery',
      ]);
      expect(result.headers.map((r) => r.normalizedName).toList(), [
        'bodyHeader',
      ]);
      expect(result.cookieParameters.map((r) => r.normalizedName).toList(), [
        'bodyCookie',
      ]);
    });

    test('does not add suffix when no reserved names are set', () {
      final result = normalizeRequestParameters(
        pathParameters: {},
        queryParameters: {createQueryParameter('body')},
        headers: {},
      );

      expect(result.queryParameters.map((r) => r.normalizedName).toList(), [
        'body',
      ]);
    });
  });

  group('counter-suffix collision avoidance', () {
    test(
      'reproducing spec: path token + query token + token_query + '
      'token_query2 produces four distinct names',
      () {
        final result = normalizeRequestParameters(
          pathParameters: {createPathParameter('token')},
          queryParameters: {
            createQueryParameter('token_query'),
            createQueryParameter('token_query2'),
            createQueryParameter('token'),
          },
          headers: {},
        );

        expect(result.pathParameters.map((r) => r.normalizedName), [
          'tokenPath',
        ]);
        expect(result.queryParameters.map((r) => r.normalizedName), [
          'tokenQuery',
          'tokenQuery2',
          'tokenQuery3',
        ]);
      },
    );

    test(
      'within-group dedup skips counter values that already collide with '
      'an existing name (e.g. [a, a2, a] -> [a, a2, a3])',
      () {
        final result = normalizeRequestParameters(
          pathParameters: {},
          queryParameters: {
            createQueryParameter('a'),
            createQueryParameter('a2'),
            createQueryParameter('a'),
          },
          headers: {},
        );

        expect(result.queryParameters.map((r) => r.normalizedName), [
          'a',
          'a2',
          'a3',
        ]);
      },
    );

    test(
      'within-group dedup advances past multiple consecutive collisions',
      () {
        final result = normalizeRequestParameters(
          pathParameters: {},
          queryParameters: {
            createQueryParameter('x'),
            createQueryParameter('x2'),
            createQueryParameter('x3'),
            createQueryParameter('x'),
          },
          headers: {},
        );

        expect(result.queryParameters.map((r) => r.normalizedName), [
          'x',
          'x2',
          'x3',
          'x4',
        ]);
      },
    );

    test(
      'type-suffix application creates a within-group collision that the '
      'counter-loop must resolve (path foo + query foo_query + query foo)',
      () {
        final result = normalizeRequestParameters(
          pathParameters: {createPathParameter('foo')},
          queryParameters: {
            createQueryParameter('foo_query'),
            createQueryParameter('foo'),
          },
          headers: {},
        );

        expect(result.pathParameters.map((r) => r.normalizedName), [
          'fooPath',
        ]);
        expect(result.queryParameters.map((r) => r.normalizedName), [
          'fooQuery',
          'fooQuery2',
        ]);
      },
    );

    test(
      'within-group dedup applies to header parameters '
      '(non-query group coverage)',
      () {
        final result = normalizeRequestParameters(
          pathParameters: {},
          queryParameters: {},
          headers: {
            createHeader('trace'),
            createHeader('trace2'),
            createHeader('trace'),
          },
        );

        expect(result.headers.map((r) => r.normalizedName), [
          'trace',
          'trace2',
          'trace3',
        ]);
      },
    );

    test(
      'within-group dedup applies to path parameters '
      '(non-query group coverage)',
      () {
        final result = normalizeRequestParameters(
          pathParameters: {
            createPathParameter('id'),
            createPathParameter('id2'),
            createPathParameter('id'),
          },
          queryParameters: {},
          headers: {},
        );

        expect(result.pathParameters.map((r) => r.normalizedName), [
          'id',
          'id2',
          'id3',
        ]);
      },
    );

    test(
      'within-group dedup applies to cookie parameters '
      '(non-query group coverage)',
      () {
        final result = normalizeRequestParameters(
          pathParameters: {},
          queryParameters: {},
          headers: {},
          cookieParameters: {
            createCookieParameter('session'),
            createCookieParameter('session2'),
            createCookieParameter('session'),
          },
        );

        expect(result.cookieParameters.map((r) => r.normalizedName), [
          'session',
          'session2',
          'session3',
        ]);
      },
    );
  });

  group('normalizeMultipartHeaderName', () {
    test('combines property name and header name', () {
      expect(
        normalizeMultipartHeaderName('profileImage', 'X-Rate-Limit-Limit'),
        'profileImageRateLimitLimit',
      );
    });

    test('handles simple header name', () {
      expect(
        normalizeMultipartHeaderName('file', 'X-Custom'),
        'fileCustom',
      );
    });

    test('handles header name without x- prefix', () {
      expect(
        normalizeMultipartHeaderName('document', 'Cache-Control'),
        'documentCacheControl',
      );
    });

    test('handles single-word header name', () {
      expect(
        normalizeMultipartHeaderName('avatar', 'Authorization'),
        'avatarAuthorization',
      );
    });

    test('different properties produce different names for same header', () {
      final name1 = normalizeMultipartHeaderName('file', 'X-Custom');
      final name2 = normalizeMultipartHeaderName('avatar', 'X-Custom');
      expect(name1, isNot(name2));
    });
  });
}

PathParameterObject createPathParameter(
  String name, {
  bool isRequired = false,
  bool isDeprecated = false,
}) {
  final context = Context.initial();
  return PathParameterObject(
    name: null,
    rawName: name,
    description: null,
    isRequired: isRequired,
    isDeprecated: isDeprecated,
    allowEmptyValue: false,
    explode: false,
    model: StringModel(context: context),
    encoding: PathParameterEncoding.simple,
    context: context,
  );
}

QueryParameterObject createQueryParameter(
  String name, {
  bool isRequired = false,
  bool isDeprecated = false,
}) {
  final context = Context.initial();
  return QueryParameterObject(
    name: null,
    rawName: name,
    description: null,
    isRequired: isRequired,
    isDeprecated: isDeprecated,
    allowEmptyValue: false,
    allowReserved: false,
    explode: false,
    model: StringModel(context: context),
    encoding: QueryParameterEncoding.form,
    context: context,
  );
}

RequestHeaderObject createHeader(
  String name, {
  bool isRequired = false,
  bool isDeprecated = false,
}) {
  final context = Context.initial();
  return RequestHeaderObject(
    name: null,
    rawName: name,
    description: null,
    isRequired: isRequired,
    isDeprecated: isDeprecated,
    allowEmptyValue: false,
    explode: false,
    model: StringModel(context: context),
    encoding: HeaderParameterEncoding.simple,
    context: context,
  );
}

CookieParameterObject createCookieParameter(
  String name, {
  bool isRequired = false,
  bool isDeprecated = false,
}) {
  final context = Context.initial();
  return CookieParameterObject(
    name: null,
    rawName: name,
    description: null,
    isRequired: isRequired,
    isDeprecated: isDeprecated,
    explode: false,
    model: StringModel(context: context),
    encoding: CookieParameterEncoding.form,
    context: context,
  );
}
