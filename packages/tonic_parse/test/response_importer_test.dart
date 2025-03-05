import 'package:collection/collection.dart';
import 'package:test/test.dart';
import 'package:tonic_core/tonic_core.dart';
import 'package:tonic_parse/tonic_parse.dart';

void main() {
  final fileContent = {
    'openapi': '3.1.0',
    'info': {
      'title': 'Test',
      'version': '1.0.0',
    },
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
        'SimpleResponse': {
          'description': 'A simple response',
        },
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
              'schema': {
                r'$ref': '#/components/schemas/MySchema',
              },
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
        'ReferenceResponse': {
          r'$ref': '#/components/responses/SimpleResponse',
        },
        'DoubleReferenceResponse': {
          r'$ref': '#/components/responses/ReferenceResponse',
        },
      },
    },
  };

  test('imports response without body and headers', () {
    final api = Importer().import(fileContent);
    final simpleResponse = api.responses.firstWhereOrNull(
      (r) => r.name == 'SimpleResponse',
    );

    expect(simpleResponse, isNotNull);
    expect(simpleResponse?.description, 'A simple response');
    expect(simpleResponse?.headers, isEmpty);
    expect(simpleResponse?.body, isNull);
  });

  test('imports response with inline body', () {
    final api = Importer().import(fileContent);
    final inlineBodyResponse = api.responses.firstWhereOrNull(
      (r) => r.name == 'InlineBodyResponse',
    );

    expect(inlineBodyResponse, isNotNull);
    expect(inlineBodyResponse?.body?.model, isA<StringModel>());
    expect(inlineBodyResponse?.body?.rawContentType, 'application/json');
  });

  test('imports response with reference body', () {
    final api = Importer().import(fileContent);
    final referenceBodyResponse = api.responses.firstWhereOrNull(
      (r) => r.name == 'ReferenceBodyResponse',
    );

    expect(referenceBodyResponse, isNotNull);
    expect(referenceBodyResponse?.body?.model, isA<AliasModel>());
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
    expect(inlineHeaderResponse?.headers, hasLength(1));

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
    expect(referenceHeaderResponse?.headers, hasLength(1));

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
    expect(jsonLikeResponse?.body?.model, isA<StringModel>());
    expect(
      jsonLikeResponse?.body?.rawContentType,
      'alto-endpointcost+json',
    );
  });

  test('imports response with invalid body content type as json', () {
    final api = Importer().import(fileContent);
    final invalidResponse = api.responses.firstWhereOrNull(
      (r) => r.name == 'InvalidResponse',
    );

    expect(invalidResponse, isNotNull);
    expect(invalidResponse?.body?.model, isA<NumberModel>());
    expect(
      invalidResponse?.body?.rawContentType,
      'concise-problem-details+cbor',
    );
  });
}
