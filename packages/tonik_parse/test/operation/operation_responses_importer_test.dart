import 'package:collection/collection.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  final fileContent = {
    'openapi': '3.0.0',
    'info': {'title': 'Test API', 'version': '1.0.0'},
    'paths': {
      '/test': {
        'get': {
          'operationId': 'getTest',
          'responses': {
            '200': {
              'description': 'Successful response',
              'content': {
                'application/json': {
                  'schema': {'type': 'string'},
                },
              },
            },
            'default': {
              'description': 'Default error response',
              'content': {
                'application/json': {
                  'schema': {
                    'type': 'object',
                    'properties': {
                      'error': {'type': 'string'},
                    },
                  },
                },
              },
            },
          },
        },
        'post': {
          'operationId': 'postTest',
          'responses': {
            '4XX': {
              'description': 'Client error response range',
              'content': {
                'application/json': {
                  'schema': {
                    'type': 'object',
                    'properties': {
                      'code': {'type': 'integer'},
                      'message': {'type': 'string'},
                    },
                  },
                },
              },
            },
            '201': {r'$ref': '#/components/responses/CreatedResponse'},
          },
        },
        'delete': {
          'operationId': 'deleteTest',
          'responses': <String, dynamic>{},
        },
        'head': {
          'operationId': 'headTest',
          'responses': {
            '200': {
              'description': 'Headers only response',
              'headers': {
                'X-Rate-Limit': {
                  'description': 'Rate limit per hour',
                  'schema': {'type': 'integer'},
                },
                'X-Rate-Limit-Reset': {
                  'description': 'Time until rate limit resets',
                  'schema': {'type': 'string', 'format': 'date-time'},
                },
              },
            },
          },
        },
      },
    },
    'components': {
      'responses': {
        'CreatedResponse': {
          'description': 'Resource created successfully',
          'content': {
            'application/json': {
              'schema': {
                'type': 'object',
                'properties': {
                  'id': {'type': 'string'},
                },
              },
            },
          },
        },
        'AnotherCreatedResponse': {
          r'$ref': '#/components/responses/CreatedResponse',
        },
      },
    },
  };

  test('imports inline response correctly', () {
    final api = Importer().import(fileContent);

    final getOperation = api.operations.firstWhereOrNull(
      (o) => o.operationId == 'getTest',
    );
    expect(getOperation, isNotNull);

    final successResponse =
        getOperation?.responses[const ExplicitResponseStatus(statusCode: 200)];
    expect(successResponse, isNotNull);
    expect(successResponse, isA<ResponseObject>());
    expect(
      (successResponse as ResponseObject?)?.bodies.first.model,
      isA<StringModel>(),
    );
  });

  test('imports default response correctly', () {
    final api = Importer().import(fileContent);

    final getOperation = api.operations.firstWhereOrNull(
      (o) => o.operationId == 'getTest',
    );
    expect(getOperation, isNotNull);

    final defaultResponse =
        getOperation?.responses[const DefaultResponseStatus()];
    expect(defaultResponse, isNotNull);
    expect(defaultResponse, isA<ResponseObject>());
    expect(
      (defaultResponse as ResponseObject?)?.bodies.first.model,
      isA<ClassModel>(),
    );
  });

  test('imports response range correctly', () {
    final api = Importer().import(fileContent);

    final postOperation = api.operations.firstWhereOrNull(
      (o) => o.operationId == 'postTest',
    );
    expect(postOperation, isNotNull);

    final rangeResponse =
        postOperation?.responses[const RangeResponseStatus(min: 400, max: 499)];
    expect(rangeResponse, isNotNull);
    expect(rangeResponse, isA<ResponseObject>());
    expect(
      (rangeResponse as ResponseObject?)?.bodies.first.model,
      isA<ClassModel>(),
    );
  });

  test('imports referenced response correctly', () {
    final api = Importer().import(fileContent);

    final postOperation = api.operations.firstWhereOrNull(
      (o) => o.operationId == 'postTest',
    );
    expect(postOperation, isNotNull);

    final createdResponse =
        postOperation?.responses[const ExplicitResponseStatus(statusCode: 201)];
    expect(createdResponse, isNotNull);
    expect(createdResponse, isA<ResponseAlias>());

    final resolvedResponse = (createdResponse as ResponseAlias?)?.response;
    expect(resolvedResponse, isA<ResponseObject>());
    expect(
      (resolvedResponse as ResponseObject?)?.bodies.first.model,
      isA<ClassModel>(),
    );

    final model = resolvedResponse?.bodies.first.model as ClassModel?;
    expect(model?.properties, hasLength(1));

    final idProperty = model?.properties.firstWhere((p) => p.name == 'id');
    expect(idProperty?.model, isA<StringModel>());
  });

  test('handles operation without responses correctly', () {
    final api = Importer().import(fileContent);

    final deleteOperation = api.operations.firstWhereOrNull(
      (o) => o.operationId == 'deleteTest',
    );
    expect(deleteOperation, isNotNull);
    expect(deleteOperation?.responses, isEmpty);
  });

  test('imports component response referencing another response', () {
    final api = Importer().import(fileContent);

    final anotherCreatedResponse = api.responses.firstWhereOrNull(
      (r) => r.name == 'AnotherCreatedResponse',
    );
    expect(anotherCreatedResponse, isNotNull);
    expect(anotherCreatedResponse, isA<ResponseAlias>());

    final firstAlias = anotherCreatedResponse as ResponseAlias?;
    expect(firstAlias?.response, isA<ResponseObject>());

    final resolvedResponse = firstAlias?.response as ResponseObject?;
    expect(resolvedResponse?.name, 'CreatedResponse');
    expect(resolvedResponse?.bodies.first.model, isA<ClassModel>());

    final model = resolvedResponse?.bodies.first.model as ClassModel?;
    expect(model?.properties, hasLength(1));

    final idProperty = model?.properties.firstWhere((p) => p.name == 'id');
    expect(idProperty?.model, isA<StringModel>());
  });

  test('imports response with only headers correctly', () {
    final api = Importer().import(fileContent);

    final headOperation = api.operations.firstWhereOrNull(
      (o) => o.operationId == 'headTest',
    );
    expect(headOperation, isNotNull);

    final headResponse =
        headOperation?.responses[const ExplicitResponseStatus(statusCode: 200)];
    expect(headResponse, isNotNull);
    expect(headResponse, isA<ResponseObject>());

    final responseObject = headResponse as ResponseObject?;
    expect(responseObject?.bodies, isEmpty);
    expect(responseObject?.headers, hasLength(2));

    final rateLimit = responseObject?.headers['X-Rate-Limit'];
    expect(rateLimit, isA<ResponseHeaderObject>());
    expect((rateLimit as ResponseHeaderObject?)?.model, isA<IntegerModel>());
    expect(rateLimit?.description, 'Rate limit per hour');

    final rateLimitReset = responseObject?.headers['X-Rate-Limit-Reset'];
    expect(rateLimitReset, isA<ResponseHeaderObject>());
    expect(
      (rateLimitReset as ResponseHeaderObject?)?.model,
      isA<DateTimeModel>(),
    );
    expect(rateLimitReset?.description, 'Time until rate limit resets');
  });
}
