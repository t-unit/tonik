import 'package:collection/collection.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  final fileContent = {
    'openapi': '3.1.0',
    'info': {'title': 'Test', 'version': '1.0.0'},
    'paths': <String, dynamic>{},
    'components': {
      'schemas': {
        'MySchema': {'type': 'number'},
      },
      'headers': {
        'FooBar': {
          'schema': {'type': 'boolean'},
        },
      },
      'responses': {
        'SimpleResponse': {'description': 'A simple response'},
        'InlineBodyResponse': {
          'description': 'A response with inline body',
          'content': {
            'application/json': {
              'schema': {'type': 'string'},
            },
          },
        },
        'ReferenceBodyResponse': {
          'description': 'A response with a reference to a body',
          'content': {
            'application/json': {
              'schema': {r'$ref': '#/components/schemas/MySchema'},
            },
          },
        },
        'InlineHeaderResponse': {
          'description': 'A response with an inline header',
          'headers': {
            'X-YourHeader': {
              'schema': {
                'type': 'object',
                'properties': {
                  'foo': {'type': 'string'},
                  'bar': {'type': 'number'},
                },
              },
            },
          },
        },
        'ReferenceHeaderResponse': {
          'description': 'A response with a reference to a header',
          'headers': {
            'X-MyHeader': {r'$ref': '#/components/headers/FooBar'},
          },
        },
        'JsonLikeResponse': {
          'description': 'A response with a json-like body',
          'content': {
            'application/x-www-form-urlencoded': {
              'schema': {'type': 'boolean'},
            },
            'alto-endpointcost+json': {
              'schema': {'type': 'string'},
            },
          },
        },
        'InvalidResponse': {
          'description': 'A response with an invalid body content type',
          'content': {
            'concise-problem-details+cbor': {
              'schema': {'type': 'number'},
            },
          },
        },
        'DoubleReferenceResponse': {
          r'$ref': '#/components/responses/ReferenceResponse',
        },
        'ReferenceResponse': {r'$ref': '#/components/responses/SimpleResponse'},
      },
    },
  };

  test('imports response without body and headers', () {
    final api = Importer().import(fileContent);
    final simpleResponse = api.responses.firstWhereOrNull(
      (r) => r.name == 'SimpleResponse',
    );

    expect(simpleResponse, isNotNull);
    expect(simpleResponse, isA<ResponseObject>());
    expect(
      (simpleResponse as ResponseObject?)?.description,
      'A simple response',
    );
    expect(simpleResponse?.headers, isEmpty);
    expect(simpleResponse?.body, isNull);
  });

  test('imports response with inline body', () {
    final api = Importer().import(fileContent);
    final inlineBodyResponse = api.responses.firstWhereOrNull(
      (r) => r.name == 'InlineBodyResponse',
    );

    expect(inlineBodyResponse, isNotNull);
    expect(inlineBodyResponse, isA<ResponseObject>());
    expect(
      (inlineBodyResponse as ResponseObject?)?.body?.model,
      isA<StringModel>(),
    );
    expect(inlineBodyResponse?.body?.rawContentType, 'application/json');
  });

  test('imports response with reference body', () {
    final api = Importer().import(fileContent);
    final referenceBodyResponse = api.responses.firstWhereOrNull(
      (r) => r.name == 'ReferenceBodyResponse',
    );

    expect(referenceBodyResponse, isNotNull);
    expect(referenceBodyResponse, isA<ResponseObject>());
    expect(
      (referenceBodyResponse as ResponseObject?)?.body?.model,
      isA<AliasModel>(),
    );
    expect(
      (referenceBodyResponse?.body?.model as AliasModel?)?.name,
      'MySchema',
    );
  });

  test('imports response with inline header', () {
    final api = Importer().import(fileContent);
    final inlineHeaderResponse = api.responses.firstWhereOrNull(
      (r) => r.name == 'InlineHeaderResponse',
    );

    expect(inlineHeaderResponse, isNotNull);
    expect(inlineHeaderResponse, isA<ResponseObject>());
    expect((inlineHeaderResponse as ResponseObject?)?.headers, hasLength(1));

    final yourHeader = inlineHeaderResponse?.headers['X-YourHeader'];
    expect(yourHeader, isA<ResponseHeaderObject>());
    expect((yourHeader as ResponseHeaderObject?)?.model, isA<ClassModel>());
  });

  test('imports response with reference header', () {
    final api = Importer().import(fileContent);
    final referenceHeaderResponse = api.responses.firstWhereOrNull(
      (r) => r.name == 'ReferenceHeaderResponse',
    );

    expect(referenceHeaderResponse, isNotNull);
    expect(referenceHeaderResponse, isA<ResponseObject>());
    expect((referenceHeaderResponse as ResponseObject?)?.headers, hasLength(1));

    final myHeader = referenceHeaderResponse?.headers['X-MyHeader'];
    expect(myHeader, isA<ResponseHeaderObject>());
    expect((myHeader as ResponseHeaderObject?)?.name, 'FooBar');
  });

  test('imports response with json-like body', () {
    final api = Importer().import(fileContent);
    final jsonLikeResponse = api.responses.firstWhereOrNull(
      (r) => r.name == 'JsonLikeResponse',
    );

    expect(jsonLikeResponse, isNotNull);
    expect(jsonLikeResponse, isA<ResponseObject>());
    expect(
      (jsonLikeResponse as ResponseObject?)?.body?.model,
      isA<StringModel>(),
    );
    expect(jsonLikeResponse?.body?.rawContentType, 'alto-endpointcost+json');
  });

  test('imports response with invalid body content type as json', () {
    final api = Importer().import(fileContent);
    final invalidResponse = api.responses.firstWhereOrNull(
      (r) => r.name == 'InvalidResponse',
    );

    expect(invalidResponse, isNotNull);
    expect(invalidResponse, isA<ResponseObject>());
    expect(
      (invalidResponse as ResponseObject?)?.body?.model,
      isA<NumberModel>(),
    );
    expect(
      invalidResponse?.body?.rawContentType,
      'concise-problem-details+cbor',
    );
  });

  test('imports direct reference response', () {
    final api = Importer().import(fileContent);
    final referenceResponse = api.responses.firstWhereOrNull(
      (r) => r.name == 'ReferenceResponse',
    );

    expect(referenceResponse, isNotNull);
    expect(referenceResponse, isA<ResponseAlias>());

    final alias = referenceResponse as ResponseAlias?;
    expect(alias?.response, isA<ResponseObject>());
    expect((alias?.response as ResponseObject?)?.name, 'SimpleResponse');
    expect(
      (alias?.response as ResponseObject?)?.description,
      'A simple response',
    );
  });

  test('imports double reference response', () {
    final api = Importer().import(fileContent);
    final doubleReferenceResponse = api.responses.firstWhereOrNull(
      (r) => r.name == 'DoubleReferenceResponse',
    );

    expect(doubleReferenceResponse, isNotNull);
    expect(doubleReferenceResponse, isA<ResponseAlias>());

    final firstAlias = doubleReferenceResponse as ResponseAlias?;
    expect(firstAlias?.response, isA<ResponseAlias>());

    final secondAlias = firstAlias?.response as ResponseAlias?;
    expect(secondAlias?.response, isA<ResponseObject>());
    expect((secondAlias?.response as ResponseObject?)?.name, 'SimpleResponse');
    expect(
      (secondAlias?.response as ResponseObject?)?.description,
      'A simple response',
    );
  });
}
