import 'package:collection/collection.dart';
import 'package:test/test.dart';
import 'package:tonic_core/tonic_core.dart';
import 'package:tonic_parse/tonic_parse.dart';

void main() {
  final fileContent = {
    'openapi': '3.0.0',
    'info': {
      'title': 'Test API',
      'version': '1.0.0',
    },
    'paths': {
      '/test': {
        'get': {
          'operationId': 'getTest',
          'responses': {
            '200': {
              'description': 'Successful response',
              'content': {
                'application/json': {
                  'schema': {
                    'type': 'string',
                  },
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
            '201': {
              r'$ref': '#/components/responses/CreatedResponse',
            },
          },
        },
        'delete': {
          'operationId': 'deleteTest',
          // Empty responses map instead of no responses.
          'responses': <String, dynamic>{},
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
      },
    },
    'servers': <dynamic>[],
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
    expect(successResponse?.model, isA<StringModel>());
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
    expect(defaultResponse?.model, isA<ClassModel>());
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
    expect(rangeResponse?.model, isA<ClassModel>());
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
    expect(createdResponse?.model, isA<ClassModel>());

    final model = createdResponse?.model as ClassModel?;
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
}
