import 'package:collection/collection.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  const fileContent = {
    'openapi': '3.0.0',
    'info': {'title': 'Test API', 'version': '1.0.0'},
    'paths': {
      '/users/{userId}/items/{itemId}': {
        'parameters': [
          {
            'name': 'userId',
            'in': 'path',
            'required': true,
            'description': 'ID of the user',
            'schema': {'type': 'string'},
          },
          {r'$ref': '#/components/parameters/ApiVersion'},
          {r'$ref': '#/components/parameters/IncludeDeleted'},
        ],
        'get': {
          'operationId': 'getUserItem',
          'parameters': [
            {r'$ref': '#/components/parameters/ItemId'},
            {
              'name': 'fields',
              'in': 'query',
              'required': false,
              'description': 'Fields to include in response',
              'schema': {
                'type': 'array',
                'items': {'type': 'string'},
              },
            },
            {r'$ref': '#/components/parameters/Authorization'},
          ],
          'responses': {
            '200': {'description': 'Successful response'},
          },
        },
      },
    },
    'components': {
      'parameters': {
        'ApiVersion': {
          'name': 'api-version',
          'in': 'header',
          'required': true,
          'description': 'API Version header',
          'schema': {'type': 'string'},
        },
        'Authorization': {
          'name': 'authorization',
          'in': 'header',
          'required': true,
          'description': 'Bearer token',
          'schema': {'type': 'string'},
        },
        'ItemId': {
          'name': 'itemId',
          'in': 'path',
          'required': true,
          'description': 'ID of the item',
          'schema': {'type': 'string'},
        },
        'IncludeDeleted': {
          'name': 'include-deleted',
          'in': 'query',
          'required': false,
          'description': 'Include deleted items',
          'schema': {'type': 'boolean'},
        },
      },
    },
  };

  test('imports path parameters from both path and operation level', () {
    final api = Importer().import(fileContent);

    final pathParams = api.pathParameters
        .whereType<PathParameterObject>()
        .toList();
    expect(pathParams, hasLength(2));

    final userIdParam = pathParams.firstWhereOrNull(
      (p) => p.rawName == 'userId',
    );
    expect(userIdParam?.isRequired, true);
    expect(userIdParam?.description, 'ID of the user');

    final itemIdParam = pathParams.firstWhereOrNull(
      (p) => p.rawName == 'itemId',
    );
    expect(itemIdParam?.isRequired, true);
    expect(itemIdParam?.description, 'ID of the item');
  });

  test('imports query parameters from both path and operation level', () {
    final api = Importer().import(fileContent);

    final queryParams = api.queryParameters
        .whereType<QueryParameterObject>()
        .toList();
    expect(queryParams, hasLength(2));

    final includeDeletedParam = queryParams.firstWhereOrNull(
      (p) => p.rawName == 'include-deleted',
    );
    expect(includeDeletedParam?.isRequired, false);
    expect(includeDeletedParam?.description, 'Include deleted items');
    expect(includeDeletedParam?.model, isA<BooleanModel>());

    final fieldsParam = queryParams.firstWhereOrNull(
      (p) => p.rawName == 'fields',
    );
    expect(fieldsParam?.isRequired, false);
    expect(fieldsParam?.description, 'Fields to include in response');
    expect(fieldsParam?.model, isA<ListModel>());
    expect((fieldsParam?.model as ListModel?)?.content, isA<StringModel>());
  });

  test('imports header parameters from both path and operation level', () {
    final api = Importer().import(fileContent);

    final headerParams = api.requestHeaders
        .whereType<RequestHeaderObject>()
        .toList();
    expect(headerParams, hasLength(2));

    final apiVersionHeader = headerParams.firstWhereOrNull(
      (h) => h.rawName == 'api-version',
    );
    expect(apiVersionHeader?.isRequired, true);
    expect(apiVersionHeader?.description, 'API Version header');
    expect(apiVersionHeader?.model, isA<StringModel>());

    final authHeader = headerParams.firstWhereOrNull(
      (h) => h.rawName == 'authorization',
    );
    expect(authHeader?.isRequired, true);
    expect(authHeader?.description, 'Bearer token');
    expect(authHeader?.model, isA<StringModel>());
  });

  test('parameters are correctly associated with operation', () {
    final api = Importer().import(fileContent);

    final operation = api.operations.firstWhereOrNull(
      (o) => o.operationId == 'getUserItem',
    );

    final pathParams = operation?.pathParameters
        .whereType<PathParameterObject>()
        .toList();
    expect(pathParams, hasLength(2));

    final pathParamNames = pathParams?.map((p) => p.rawName).toSet();
    expect(pathParamNames, containsAll(['userId', 'itemId']));

    final userIdParam = pathParams?.firstWhereOrNull(
      (p) => p.rawName == 'userId',
    );
    expect(userIdParam?.isRequired, true);
    expect(userIdParam?.description, 'ID of the user');

    final itemIdParam = pathParams?.firstWhereOrNull(
      (p) => p.rawName == 'itemId',
    );
    expect(itemIdParam?.isRequired, true);
    expect(itemIdParam?.description, 'ID of the item');

    final queryParams = operation?.queryParameters
        .whereType<QueryParameterObject>()
        .toList();
    expect(queryParams, hasLength(2));

    final queryParamNames = queryParams?.map((p) => p.rawName).toSet();
    expect(queryParamNames, containsAll(['include-deleted', 'fields']));

    final includeDeletedParam = queryParams?.firstWhereOrNull(
      (p) => p.rawName == 'include-deleted',
    );
    expect(includeDeletedParam?.isRequired, false);
    expect(includeDeletedParam?.description, 'Include deleted items');

    final fieldsParam = queryParams?.firstWhereOrNull(
      (p) => p.rawName == 'fields',
    );
    expect(fieldsParam?.isRequired, false);
    expect(fieldsParam?.description, 'Fields to include in response');

    final headerParams = operation?.headers
        .whereType<RequestHeaderObject>()
        .toList();
    expect(headerParams, hasLength(2));

    final headerParamNames = headerParams?.map((h) => h.rawName).toSet();
    expect(headerParamNames, containsAll(['api-version', 'authorization']));

    final apiVersionHeader = headerParams?.firstWhereOrNull(
      (h) => h.rawName == 'api-version',
    );
    expect(apiVersionHeader?.isRequired, true);
    expect(apiVersionHeader?.description, 'API Version header');

    final authHeader = headerParams?.firstWhereOrNull(
      (h) => h.rawName == 'authorization',
    );
    expect(authHeader?.isRequired, true);
    expect(authHeader?.description, 'Bearer token');
  });

  test('handles parameter references correctly', () {
    final api = Importer().import(fileContent);

    final operation = api.operations.firstWhereOrNull(
      (o) => o.operationId == 'getUserItem',
    );

    final itemIdParam = operation?.pathParameters
        .whereType<PathParameterObject>()
        .firstWhereOrNull((p) => p.rawName == 'itemId');
    expect(itemIdParam?.description, 'ID of the item');
    expect(itemIdParam?.isRequired, true);

    final includeDeletedParam = operation?.queryParameters
        .whereType<QueryParameterObject>()
        .firstWhereOrNull((p) => p.rawName == 'include-deleted');
    expect(includeDeletedParam?.description, 'Include deleted items');
    expect(includeDeletedParam?.isRequired, false);

    final authHeader = operation?.headers
        .whereType<RequestHeaderObject>()
        .firstWhereOrNull((h) => h.rawName == 'authorization');
    expect(authHeader?.description, 'Bearer token');
    expect(authHeader?.isRequired, true);

    final apiVersionHeader = operation?.headers
        .whereType<RequestHeaderObject>()
        .firstWhereOrNull((h) => h.rawName == 'api-version');
    expect(apiVersionHeader?.description, 'API Version header');
    expect(apiVersionHeader?.isRequired, true);
  });
}
