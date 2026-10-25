import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/src/model/open_api_object.dart';
import 'package:tonik_parse/src/model/operation.dart' as parse;
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  test('imports a components-only document without paths', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'components': {
        'schemas': {
          'Value': {'type': 'integer'},
        },
      },
    });

    final value = api.models.whereType<AliasModel>().single;
    expect(value.name, 'Value');
    expect(value.model, isA<IntegerModel>());
    expect(api.operations, isEmpty);
  });

  test('imports a webhooks-only document without paths', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'webhooks': {
        'notification': {
          'post': {
            'responses': {
              '204': {'description': 'Accepted'},
            },
          },
        },
      },
    });

    expect(api.title, 'Test API');
    expect(api.operations, isEmpty);
    expect(api.models, isEmpty);
  });

  test('imports an operation with no responses', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': {
        '/ping': {
          'get': {'operationId': 'ping'},
        },
      },
    });

    final operation = api.operations.single;
    expect(operation.operationId, 'ping');
    expect(operation.path, '/ping');
    expect(operation.method, HttpMethod.get);
    expect(operation.responses, isEmpty);
  });

  test('ignores Paths and Responses extensions in OpenAPI 3.1', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': {
        'x-generated-by': 'tool',
        '/ping': {
          'get': {
            'operationId': 'ping',
            'responses': {
              'x-internal-note': 'text',
              '200': {'description': 'OK'},
              '4XX': {'description': 'Client error'},
              'default': {'description': 'Other response'},
            },
          },
        },
      },
    });

    final operation = api.operations.single;
    expect(operation.path, '/ping');
    expect(operation.responses.keys, [
      const ExplicitResponseStatus(statusCode: 200),
      const RangeResponseStatus(min: 400, max: 499),
      const DefaultResponseStatus(),
    ]);
  });

  test('ignores Paths and Responses extensions in OpenAPI 3.0', () {
    final api = Importer().import({
      'openapi': '3.0.3',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': {
        'x-generated-by': {'tool': 'example'},
        '/ping': {
          'get': {
            'operationId': 'ping',
            'responses': {
              'x-note': false,
              '204': {'description': 'Accepted'},
            },
          },
        },
      },
    });

    final operation = api.operations.single;
    expect(operation.path, '/ping');
    expect(operation.responses.keys, [
      const ExplicitResponseStatus(statusCode: 204),
    ]);
  });

  test('retains components whose names start with x-', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': {
        '/ping': {
          'get': {
            'responses': {
              '200': {r'$ref': '#/components/responses/x-Reply'},
            },
          },
        },
      },
      'components': {
        'schemas': {
          'x-Value': {'type': 'integer'},
        },
        'responses': {
          'x-Reply': {'description': 'OK'},
        },
      },
    });

    final value = api.models.whereType<AliasModel>().single;
    expect(value.name, 'x-Value');
    expect(value.model, isA<IntegerModel>());
    expect(api.operations.single.responses, hasLength(1));
    expect(api.responses, isNotEmpty);
  });

  test('rejects a non-map Paths object', () {
    expect(
      () => OpenApiObject.fromJson({
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': ['invalid'],
      }),
      throwsA(isA<TypeError>()),
    );
  });

  test('rejects an explicitly null Paths object', () {
    expect(
      () => OpenApiObject.fromJson({
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': null,
      }),
      throwsA(isA<TypeError>()),
    );
  });

  test('rejects malformed real path entries', () {
    expect(
      () => OpenApiObject.fromJson({
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': {'/ping': 'invalid'},
      }),
      throwsA(isA<TypeError>()),
    );
  });

  test('rejects a non-map Responses object', () {
    expect(
      () => parse.Operation.fromJson({'responses': 'invalid'}),
      throwsA(isA<TypeError>()),
    );
  });

  test('rejects an explicitly null Responses object', () {
    expect(
      () => parse.Operation.fromJson({'responses': null}),
      throwsA(isA<TypeError>()),
    );
  });

  test('rejects malformed real response entries', () {
    expect(
      () => parse.Operation.fromJson({
        'responses': {'200': 'invalid'},
      }),
      throwsA(isA<TypeError>()),
    );
  });
}
