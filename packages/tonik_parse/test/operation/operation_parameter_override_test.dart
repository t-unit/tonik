import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  Operation operationFor(Map<String, dynamic> fileContent) {
    final api = Importer().import(fileContent);
    return api.operations.firstWhere((o) => o.operationId == 'listItems');
  }

  Map<String, dynamic> specWith({
    required Map<String, dynamic> pathParameter,
    required Map<String, dynamic> operationParameter,
    Map<String, dynamic>? components,
  }) => {
    'openapi': '3.0.3',
    'info': {'title': 'Test API', 'version': '1.0.0'},
    'paths': {
      '/items': {
        'parameters': [pathParameter],
        'get': {
          'operationId': 'listItems',
          'parameters': [operationParameter],
          'responses': {
            '200': {'description': 'OK'},
          },
        },
      },
    },
    if (components != null) 'components': {'parameters': components},
  };

  test('operation-level query param overrides path-item query param of '
      'same name', () {
    final operation = operationFor(
      specWith(
        pathParameter: {
          'name': 'status',
          'in': 'query',
          'required': false,
          'schema': {'type': 'string'},
        },
        operationParameter: {
          'name': 'status',
          'in': 'query',
          'required': true,
          'schema': {'type': 'string'},
        },
      ),
    );

    final params = operation.queryParameters
        .whereType<QueryParameterObject>()
        .where((p) => p.rawName == 'status')
        .toList();
    expect(params, hasLength(1));
    expect(params.single.isRequired, isTrue);
  });

  test('operation-level header param overrides path-item header param of '
      'same name', () {
    final operation = operationFor(
      specWith(
        pathParameter: {
          'name': 'x-token',
          'in': 'header',
          'required': false,
          'schema': {'type': 'string'},
        },
        operationParameter: {
          'name': 'x-token',
          'in': 'header',
          'required': true,
          'schema': {'type': 'string'},
        },
      ),
    );

    final params = operation.headers
        .whereType<RequestHeaderObject>()
        .where((h) => h.rawName == 'x-token')
        .toList();
    expect(params, hasLength(1));
    expect(params.single.isRequired, isTrue);
  });

  test('operation-level path param overrides path-item path param of '
      'same name', () {
    final operation = operationFor(
      specWith(
        pathParameter: {
          'name': 'id',
          'in': 'path',
          'required': true,
          'description': 'path-item id',
          'schema': {'type': 'string'},
        },
        operationParameter: {
          'name': 'id',
          'in': 'path',
          'required': true,
          'description': 'operation id',
          'schema': {'type': 'string'},
        },
      ),
    );

    final params = operation.pathParameters
        .whereType<PathParameterObject>()
        .where((p) => p.rawName == 'id')
        .toList();
    expect(params, hasLength(1));
    expect(params.single.description, 'operation id');
  });

  test('operation-level cookie param overrides path-item cookie param of '
      'same name', () {
    final operation = operationFor(
      specWith(
        pathParameter: {
          'name': 'session',
          'in': 'cookie',
          'required': false,
          'schema': {'type': 'string'},
        },
        operationParameter: {
          'name': 'session',
          'in': 'cookie',
          'required': true,
          'schema': {'type': 'string'},
        },
      ),
    );

    final params = operation.cookieParameters
        .whereType<CookieParameterObject>()
        .where((p) => p.rawName == 'session')
        .toList();
    expect(params, hasLength(1));
    expect(params.single.isRequired, isTrue);
  });

  test(r'operation inline param overrides path-item $ref param of '
      'same name and location', () {
    final operation = operationFor(
      specWith(
        pathParameter: {r'$ref': '#/components/parameters/Status'},
        operationParameter: {
          'name': 'status',
          'in': 'query',
          'required': true,
          'schema': {'type': 'string'},
        },
        components: {
          'Status': {
            'name': 'status',
            'in': 'query',
            'required': false,
            'schema': {'type': 'string'},
          },
        },
      ),
    );

    final params = operation.queryParameters
        .whereType<QueryParameterObject>()
        .where((p) => p.rawName == 'status')
        .toList();
    expect(params, hasLength(1));
    expect(params.single.isRequired, isTrue);
  });

  test(r'operation $ref param overrides path-item inline param of '
      'same name and location', () {
    final operation = operationFor(
      specWith(
        pathParameter: {
          'name': 'status',
          'in': 'query',
          'required': false,
          'schema': {'type': 'string'},
        },
        operationParameter: {r'$ref': '#/components/parameters/Status'},
        components: {
          'Status': {
            'name': 'status',
            'in': 'query',
            'required': true,
            'schema': {'type': 'string'},
          },
        },
      ),
    );

    final params = operation.queryParameters
        .whereType<QueryParameterObject>()
        .where((p) => p.rawName == 'status')
        .toList();
    expect(params, hasLength(1));
    expect(params.single.isRequired, isTrue);
  });

  test('same name in different locations are both preserved', () {
    final operation = operationFor(
      specWith(
        pathParameter: {
          'name': 'status',
          'in': 'query',
          'required': false,
          'schema': {'type': 'string'},
        },
        operationParameter: {
          'name': 'status',
          'in': 'header',
          'required': true,
          'schema': {'type': 'string'},
        },
      ),
    );

    final queryStatus = operation.queryParameters
        .whereType<QueryParameterObject>()
        .where((p) => p.rawName == 'status')
        .toList();
    final headerStatus = operation.headers
        .whereType<RequestHeaderObject>()
        .where((h) => h.rawName == 'status')
        .toList();
    expect(queryStatus, hasLength(1));
    expect(headerStatus, hasLength(1));
  });

  test('different names in same location are both preserved', () {
    final operation = operationFor(
      specWith(
        pathParameter: {
          'name': 'status',
          'in': 'query',
          'required': false,
          'schema': {'type': 'string'},
        },
        operationParameter: {
          'name': 'kind',
          'in': 'query',
          'required': true,
          'schema': {'type': 'string'},
        },
      ),
    );

    final names = operation.queryParameters
        .whereType<QueryParameterObject>()
        .map((p) => p.rawName)
        .toSet();
    expect(names, containsAll(['status', 'kind']));
  });

  test(r'chained path-item $ref is overridden by operation inline param of '
      'same name and location', () {
    final operation = operationFor(
      specWith(
        pathParameter: {r'$ref': '#/components/parameters/StatusAlias'},
        operationParameter: {
          'name': 'status',
          'in': 'query',
          'required': true,
          'schema': {'type': 'string'},
        },
        components: {
          'StatusAlias': {r'$ref': '#/components/parameters/Status'},
          'Status': {
            'name': 'status',
            'in': 'query',
            'required': false,
            'schema': {'type': 'string'},
          },
        },
      ),
    );

    final params = operation.queryParameters
        .whereType<QueryParameterObject>()
        .where((p) => p.rawName == 'status')
        .toList();
    expect(params, hasLength(1));
    expect(params.single.isRequired, isTrue);
  });

  test(r'same $ref used by both path-item and operation resolves to one '
      'param without cycle detection', () {
    final operation = operationFor(
      specWith(
        pathParameter: {r'$ref': '#/components/parameters/Status'},
        operationParameter: {r'$ref': '#/components/parameters/Status'},
        components: {
          'Status': {
            'name': 'status',
            'in': 'query',
            'required': true,
            'schema': {'type': 'string'},
          },
        },
      ),
    );

    final params = operation.queryParameters
        .whereType<QueryParameterObject>()
        .where((p) => p.rawName == 'status')
        .toList();
    expect(params, hasLength(1));
    expect(params.single.isRequired, isTrue);
  });

  test(r'cyclic parameter $ref chain throws ArgumentError', () {
    final fileContent = specWith(
      pathParameter: {r'$ref': '#/components/parameters/A'},
      operationParameter: {
        'name': 'kind',
        'in': 'query',
        'required': true,
        'schema': {'type': 'string'},
      },
      components: {
        'A': {r'$ref': '#/components/parameters/B'},
        'B': {r'$ref': '#/components/parameters/A'},
      },
    );

    expect(
      () => Importer().import(fileContent),
      throwsA(isA<ArgumentError>()),
    );
  });

  test(r'unresolvable parameter $ref is passed through to the importer '
      'and throws', () {
    final fileContent = specWith(
      pathParameter: {r'$ref': '#/components/parameters/DoesNotExist'},
      operationParameter: {
        'name': 'kind',
        'in': 'query',
        'required': true,
        'schema': {'type': 'string'},
      },
    );

    expect(
      () => Importer().import(fileContent),
      throwsA(isA<ArgumentError>()),
    );
  });
}
