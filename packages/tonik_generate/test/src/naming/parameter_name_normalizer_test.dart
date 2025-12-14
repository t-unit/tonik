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
        queryParameters: {param1, param2},
        headers: {},
      );

      final names =
          result.queryParameters.map((r) => r.normalizedName).toList();
      expect(names.length, 2, reason: 'Should have 2 parameters');
      expect(names.toSet().length, 2, reason: 'Should have unique names');
      expect(names.contains('value'), isTrue);
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
        queryParameters: {param},
        headers: {},
      );

      expect(result.queryParameters.first.normalizedName, 'sortBy');
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
