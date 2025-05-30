import 'package:collection/collection.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  const fileContent = {
    'openapi': '3.0.0',
    'info': {'title': 'Test API', 'version': '1.0.0'},
    'paths': {
      '/test': {
        'get': {
          'operationId': 'getTest',
          'summary': 'Get test operation',
          'description': 'This is a test GET operation',
          'deprecated': false,
          'responses': {
            '200': {'description': 'Successful response'},
          },
        },
        'post': {
          'operationId': 'postTest',
          'summary': 'Post test operation',
          'description': 'This is a test POST operation',
          'deprecated': true,
          'requestBody': {
            'required': true,
            'content': {
              'application/json': {
                'schema': {
                  'type': 'object',
                  'properties': {
                    'name': {'type': 'string'},
                    'age': {'type': 'integer'},
                  },
                },
              },
            },
          },
          'responses': {
            '201': {'description': 'Created response'},
          },
        },
        'put': {
          'operationId': 'putTest',
          'summary': 'Put test operation',
          'description': 'This is a test PUT operation',
          'responses': {
            '200': {'description': 'Successful response'},
          },
        },
      },
      '/test-ref': {
        'post': {
          'operationId': 'postTestRef',
          'requestBody': {r'$ref': '#/components/requestBodies/TestBody'},
          'responses': {
            '200': {'description': 'Successful response'},
          },
        },
      },
    },
    'components': {
      'requestBodies': {
        'TestBody': {
          'required': true,
          'content': {
            'application/json': {
              'schema': {
                'type': 'object',
                'properties': {
                  'test': {'type': 'string'},
                },
              },
            },
          },
        },
      },
    },
  };

  test('imports operation method correctly', () {
    final api = Importer().import(fileContent);

    final getOperation = api.operations.firstWhereOrNull(
      (o) => o.operationId == 'getTest',
    );
    expect(getOperation, isNotNull);
    expect(getOperation?.method, HttpMethod.get);

    final postOperation = api.operations.firstWhereOrNull(
      (o) => o.operationId == 'postTest',
    );
    expect(postOperation, isNotNull);
    expect(postOperation?.method, HttpMethod.post);

    final putOperation = api.operations.firstWhereOrNull(
      (o) => o.operationId == 'putTest',
    );
    expect(putOperation, isNotNull);
    expect(putOperation?.method, HttpMethod.put);
  });

  test('imports operation deprecated status correctly', () {
    final api = Importer().import(fileContent);

    final getOperation = api.operations.firstWhereOrNull(
      (o) => o.operationId == 'getTest',
    );
    expect(getOperation, isNotNull);
    expect(getOperation?.isDeprecated, false);

    final postOperation = api.operations.firstWhereOrNull(
      (o) => o.operationId == 'postTest',
    );
    expect(postOperation, isNotNull);
    expect(postOperation?.isDeprecated, true);

    final putOperation = api.operations.firstWhereOrNull(
      (o) => o.operationId == 'putTest',
    );
    expect(putOperation, isNotNull);
    expect(putOperation?.isDeprecated, false);
  });

  test('imports operation summary correctly', () {
    final api = Importer().import(fileContent);

    final getOperation = api.operations.firstWhereOrNull(
      (o) => o.operationId == 'getTest',
    );
    expect(getOperation, isNotNull);
    expect(getOperation?.summary, 'Get test operation');

    final postOperation = api.operations.firstWhereOrNull(
      (o) => o.operationId == 'postTest',
    );
    expect(postOperation, isNotNull);
    expect(postOperation?.summary, 'Post test operation');

    final putOperation = api.operations.firstWhereOrNull(
      (o) => o.operationId == 'putTest',
    );
    expect(putOperation, isNotNull);
    expect(putOperation?.summary, 'Put test operation');
  });

  test('imports operation description correctly', () {
    final api = Importer().import(fileContent);

    final getOperation = api.operations.firstWhereOrNull(
      (o) => o.operationId == 'getTest',
    );
    expect(getOperation, isNotNull);
    expect(getOperation?.description, 'This is a test GET operation');

    final postOperation = api.operations.firstWhereOrNull(
      (o) => o.operationId == 'postTest',
    );
    expect(postOperation, isNotNull);
    expect(postOperation?.description, 'This is a test POST operation');

    final putOperation = api.operations.firstWhereOrNull(
      (o) => o.operationId == 'putTest',
    );
    expect(putOperation, isNotNull);
    expect(putOperation?.description, 'This is a test PUT operation');
  });

  test('imports operation request body correctly', () {
    final api = Importer().import(fileContent);

    final postOperation = api.operations.firstWhereOrNull(
      (o) => o.operationId == 'postTest',
    );
    expect(postOperation, isNotNull);
    expect(postOperation?.requestBody, isNotNull);
    expect(postOperation?.requestBody?.isRequired, isTrue);
    expect(
      postOperation?.requestBody?.resolvedContent.any(
        (content) => content.rawContentType == 'application/json',
      ),
      isTrue,
    );

    final getOperation = api.operations.firstWhereOrNull(
      (o) => o.operationId == 'getTest',
    );
    expect(getOperation, isNotNull);
    expect(getOperation?.requestBody, isNull);
  });

  test('imports referenced request body correctly', () {
    final api = Importer().import(fileContent);

    final postOperation = api.operations.firstWhereOrNull(
      (o) => o.operationId == 'postTestRef',
    );
    expect(postOperation, isNotNull);
    expect(postOperation?.requestBody, isNotNull);
    expect(postOperation?.requestBody?.isRequired, isTrue);
    expect(
      postOperation?.requestBody?.resolvedContent.any(
        (content) => content.rawContentType == 'application/json',
      ),
      isTrue,
    );

    final content = postOperation?.requestBody?.resolvedContent.firstWhere(
      (content) => content.rawContentType == 'application/json',
    );
    expect(content, isNotNull);
    expect(content?.model, isA<ClassModel>());
    expect(
      (content?.model as ClassModel?)?.properties.any((p) => p.name == 'test'),
      isTrue,
    );
  });
}
