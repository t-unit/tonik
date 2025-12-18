import 'package:collection/collection.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/src/model/open_api_object.dart';
import 'package:tonik_parse/src/model_importer.dart';
import 'package:tonik_parse/src/response_header_importer.dart';
import 'package:tonik_parse/src/response_importer.dart';
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
        'MultiJsonResponse': {
          'description': 'A response with multiple JSON content types',
          'content': {
            'application/json': {
              'schema': {
                'type': 'object',
                'properties': {
                  'id': {'type': 'string'},
                },
              },
            },
            'application/problem+json': {
              'schema': {
                'type': 'object',
                'properties': {
                  'error': {'type': 'string'},
                },
              },
            },
            'application/ld+json': {
              'schema': {
                'type': 'object',
                'properties': {
                  'context': {'type': 'string'},
                },
              },
            },
            'application/geo+json': {
              'schema': {
                'type': 'object',
                'properties': {
                  'coordinates': {
                    'type': 'array',
                    'items': {'type': 'number'},
                  },
                },
              },
            },
          },
        },
        'DuplicateResponse': {
          'description': 'First definition',
          'content': {
            'application/json': {
              'schema': {'type': 'string'},
            },
          },
        },
        'AnotherResponse': {
          'description': 'Second definition with same content',
          'content': {
            'application/json': {
              'schema': {'type': 'string'},
            },
          },
        },
        'DuplicateResponseRef': {
          r'$ref': '#/components/responses/DuplicateResponse',
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
    expect(simpleResponse, isA<ResponseObject>());
    expect(
      (simpleResponse as ResponseObject?)?.description,
      'A simple response',
    );
    expect(simpleResponse?.headers, isEmpty);
    expect(simpleResponse?.bodies, isEmpty);
  });

  test('imports response with inline body', () {
    final api = Importer().import(fileContent);
    final inlineBodyResponse = api.responses.firstWhereOrNull(
      (r) => r.name == 'InlineBodyResponse',
    );

    expect(inlineBodyResponse, isNotNull);
    expect(inlineBodyResponse, isA<ResponseObject>());
    expect(
      (inlineBodyResponse as ResponseObject?)?.bodies.first.model,
      isA<StringModel>(),
    );
    expect(inlineBodyResponse?.bodies.first.rawContentType, 'application/json');
  });

  test('imports response with reference body', () {
    final api = Importer().import(fileContent);
    final referenceBodyResponse = api.responses.firstWhereOrNull(
      (r) => r.name == 'ReferenceBodyResponse',
    );

    expect(referenceBodyResponse, isNotNull);
    expect(referenceBodyResponse, isA<ResponseObject>());
    expect(
      (referenceBodyResponse as ResponseObject?)?.bodies.first.model,
      isA<AliasModel>(),
    );
    expect(
      (referenceBodyResponse?.bodies.first.model as AliasModel?)?.name,
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
    // Without explicit contentTypes config, non-standard types are skipped
    expect((jsonLikeResponse as ResponseObject?)?.bodies, isEmpty);
  });

  test('imports custom content type response with configuration', () {
    final api = Importer(
      contentTypes: {'alto-endpointcost+json': ContentType.json},
    ).import(fileContent);
    final jsonLikeResponse = api.responses.firstWhereOrNull(
      (r) => r.name == 'JsonLikeResponse',
    );

    expect(jsonLikeResponse, isNotNull);
    expect(jsonLikeResponse, isA<ResponseObject>());
    expect(
      (jsonLikeResponse as ResponseObject?)?.bodies.first.model,
      isA<StringModel>(),
    );
    expect(
      jsonLikeResponse?.bodies.first.rawContentType,
      'alto-endpointcost+json',
    );
  });

  test('ignores body of response with invalid body content type', () {
    final api = Importer().import(fileContent);
    final invalidResponse = api.responses.firstWhereOrNull(
      (r) => r.name == 'InvalidResponse',
    );

    expect(invalidResponse, isNotNull);
    expect(invalidResponse, isA<ResponseObject>());
    expect((invalidResponse as ResponseObject?)?.bodies, isEmpty);
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

  test('imports multiple json content types as response objects', () {
    final api = Importer(
      contentTypes: {
        'application/problem+json': ContentType.json,
        'application/ld+json': ContentType.json,
        'application/geo+json': ContentType.json,
      },
    ).import(fileContent);
    final multiJsonResponse = api.responses.firstWhereOrNull(
      (r) => r.name == 'MultiJsonResponse',
    );

    expect(multiJsonResponse, isNotNull);
    expect(multiJsonResponse, isA<ResponseObject>());

    final response = multiJsonResponse as ResponseObject?;
    expect(response?.bodies, hasLength(4));

    // Verify all content types are preserved
    final contentTypes = response?.bodies.map((b) => b.rawContentType).toList();
    expect(
      contentTypes,
      containsAll([
        'application/json',
        'application/problem+json',
        'application/ld+json',
        'application/geo+json',
      ]),
    );

    // Verify all bodies are parsed as ClassModel
    for (final body in response?.bodies ?? <ResponseBody>[]) {
      expect(body.model, isA<ClassModel>());
    }
  });

  test('adds single imported response to responses set', () {
    final openApiObject = OpenApiObject.fromJson(fileContent);
    final modelImporter = ModelImporter(openApiObject);
    final headerImporter = ResponseHeaderImporter(
      openApiObject: openApiObject,
      modelImporter: modelImporter,
    );
    final responseImporter =
        ResponseImporter(
            openApiObject: openApiObject,
            modelImporter: modelImporter,
            headerImporter: headerImporter,
          )
          // Initialize the responses set
          ..responses = {};

    // Import a single response
    final simpleResponse =
        openApiObject.components?.responses?['SimpleResponse'];
    expect(simpleResponse, isNotNull);

    final importedResponse = responseImporter.importResponse(
      name: 'SimpleResponse',
      wrapper: simpleResponse!,
      context: ResponseImporter.rootContext.push('SimpleResponse'),
    );

    // Verify the response was added to the responses set
    expect(responseImporter.responses, contains(importedResponse));
  });

  test('handles duplicate responses correctly', () {
    final api = Importer().import(fileContent);

    final duplicateResponses = api.responses
        .where((r) => r.name == 'DuplicateResponse')
        .toList();

    expect(duplicateResponses, hasLength(1));

    final duplicateResponse = duplicateResponses.first;
    expect(duplicateResponse, isA<ResponseObject>());
    expect(
      (duplicateResponse as ResponseObject).description,
      'First definition',
    );
    expect(duplicateResponse.bodies.first.model, isA<StringModel>());
  });
}
