import 'package:collection/collection.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/src/model/open_api_object.dart' as parse;
import 'package:tonik_parse/src/model/reference.dart';
import 'package:tonik_parse/src/model/request_body.dart' as parse;
import 'package:tonik_parse/src/model_importer.dart';
import 'package:tonik_parse/src/request_body_importer.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  final fileContent = {
    'openapi': '3.1.0',
    'info': {'title': 'Test', 'version': '1.0.0'},
    'paths': <String, dynamic>{},
    'components': {
      'schemas': {
        'MySchema': {
          'type': 'object',
          'properties': {
            'name': {'type': 'string'},
          },
        },
      },
      'requestBodies': {
        'SimpleBody': {
          'description': 'A simple request body',
          'required': true,
          'content': {
            'application/json': {
              'schema': {'type': 'string'},
            },
          },
        },
        'ReferenceBody': {
          'description': 'A request body with a reference schema',
          'required': false,
          'content': {
            'application/json': {
              'schema': {r'$ref': '#/components/schemas/MySchema'},
            },
          },
        },
        'JsonLikeBody': {
          'description': 'A request body with json-like content',
          'required': true,
          'content': {
            'application/x-www-form-urlencoded': {
              'schema': {'type': 'boolean'},
            },
            'alto-endpointcost+json': {
              'schema': {'type': 'string'},
            },
          },
        },
        'InvalidBody': {
          'description': 'A request body with invalid content type',
          'required': true,
          'content': {
            'text/plain': {
              'schema': {'type': 'number'},
            },
          },
        },
        'MultipleJsonBody': {
          'description': 'A request body with multiple JSON content types',
          'required': true,
          'content': {
            'application/json': {
              'schema': {'type': 'string'},
            },
            'application/problem+json': {
              'schema': {'type': 'number'},
            },
          },
        },
        'InlineClassBody': {
          'description': 'A request body with an inline class schema',
          'required': true,
          'content': {
            'application/json': {
              'schema': {
                'type': 'object',
                'properties': {
                  'name': {'type': 'string'},
                  'age': {'type': 'integer'},
                  'email': {'type': 'string'},
                },
              },
            },
          },
        },
        'AliasBody': {r'$ref': '#/components/requestBodies/SimpleBody'},
        'DoubleAliasBody': {r'$ref': '#/components/requestBodies/AliasBody'},
        'DuplicateBody': {
          'description': 'First definition',
          'required': true,
          'content': {
            'application/json': {
              'schema': {'type': 'string'},
            },
          },
        },
        'AnotherBody': {
          'description': 'Second definition with same content',
          'required': true,
          'content': {
            'application/json': {
              'schema': {'type': 'string'},
            },
          },
        },
        'DuplicateBodyRef': {
          r'$ref': '#/components/requestBodies/DuplicateBody',
        },
      },
    },
  };

  test('imports simple request body with JSON content', () {
    final api = Importer().import(fileContent);
    final simpleBody = api.requestBodies.firstWhereOrNull(
      (r) => r.name == 'SimpleBody',
    );

    expect(simpleBody, isNotNull);
    expect(simpleBody, isA<RequestBodyObject>());
    expect((simpleBody as RequestBodyObject?)?.isRequired, isTrue);
    expect(simpleBody?.content, hasLength(1));

    final content = simpleBody?.content.first;
    expect(content?.model, isA<StringModel>());
    expect(content?.rawContentType, 'application/json');
    expect(content?.contentType, ContentType.json);
  });

  test('imports request body with reference schema', () {
    final api = Importer().import(fileContent);
    final referenceBody = api.requestBodies.firstWhereOrNull(
      (r) => r.name == 'ReferenceBody',
    );

    expect(referenceBody, isNotNull);
    expect(referenceBody, isA<RequestBodyObject>());
    expect((referenceBody as RequestBodyObject?)?.isRequired, isFalse);
    expect(referenceBody?.content, hasLength(1));

    final content = referenceBody?.content.first;
    expect(content?.model, isA<ClassModel>());
    expect((content?.model as ClassModel?)?.name, 'MySchema');
    expect(content?.rawContentType, 'application/json');
    expect(content?.contentType, ContentType.json);
  });

  test('imports request body with json-like content', () {
    final api = Importer().import(fileContent);
    final jsonLikeBody = api.requestBodies.firstWhereOrNull(
      (r) => r.name == 'JsonLikeBody',
    );

    expect(jsonLikeBody, isNotNull);
    expect(jsonLikeBody, isA<RequestBodyObject>());
    expect((jsonLikeBody as RequestBodyObject?)?.isRequired, isTrue);
    expect(jsonLikeBody?.content, hasLength(1));

    final content = jsonLikeBody?.content.first;
    expect(content?.model, isA<StringModel>());
    expect(content?.rawContentType, 'alto-endpointcost+json');
    expect(content?.contentType, ContentType.json);
  });

  test('skips non-JSON content types', () {
    final api = Importer().import(fileContent);
    final invalidBody = api.requestBodies.firstWhereOrNull(
      (r) => r.name == 'InvalidBody',
    );

    expect(invalidBody, isNotNull);
    expect(invalidBody, isA<RequestBodyObject>());
    expect((invalidBody as RequestBodyObject?)?.content, isEmpty);
  });

  test('imports all JSON content types', () {
    final api = Importer().import(fileContent);
    final multipleJsonBody = api.requestBodies.firstWhereOrNull(
      (r) => r.name == 'MultipleJsonBody',
    );

    expect(multipleJsonBody, isNotNull);
    expect(multipleJsonBody, isA<RequestBodyObject>());
    expect((multipleJsonBody as RequestBodyObject?)?.content, hasLength(2));

    final jsonContent = multipleJsonBody?.content.firstWhereOrNull(
      (c) => c.rawContentType == 'application/json',
    );
    expect(jsonContent?.model, isA<StringModel>());
    expect(jsonContent?.contentType, ContentType.json);

    final problemContent = multipleJsonBody?.content.firstWhereOrNull(
      (c) => c.rawContentType == 'application/problem+json',
    );
    expect(problemContent?.model, isA<NumberModel>());
    expect(problemContent?.contentType, ContentType.json);
  });

  test('imports request body with inline class schema', () {
    final api = Importer().import(fileContent);
    final inlineClassBody = api.requestBodies.firstWhereOrNull(
      (r) => r.name == 'InlineClassBody',
    );

    expect(inlineClassBody, isNotNull);
    expect(inlineClassBody, isA<RequestBodyObject>());
    expect((inlineClassBody as RequestBodyObject?)?.isRequired, isTrue);
    expect(inlineClassBody?.content, hasLength(1));

    final content = inlineClassBody?.content.first;
    expect(content?.model, isA<ClassModel>());

    final model = content?.model as ClassModel?;
    expect(model?.properties, hasLength(3));

    final nameProperty = model?.properties.firstWhereOrNull(
      (p) => p.name == 'name',
    );
    final ageProperty = model?.properties.firstWhereOrNull(
      (p) => p.name == 'age',
    );
    final emailProperty = model?.properties.firstWhereOrNull(
      (p) => p.name == 'email',
    );

    expect(nameProperty?.model, isA<StringModel>());
    expect(ageProperty?.model, isA<IntegerModel>());
    expect(emailProperty?.model, isA<StringModel>());

    expect(api.models, contains(model));
  });

  test('imports request body alias', () {
    final api = Importer().import(fileContent);
    final aliasBody = api.requestBodies.firstWhereOrNull(
      (r) => r.name == 'AliasBody',
    );

    expect(aliasBody, isNotNull);
    expect(aliasBody, isA<RequestBodyAlias>());

    final alias = aliasBody as RequestBodyAlias?;
    expect(alias?.requestBody, isA<RequestBodyObject>());
    expect(
      (alias?.requestBody as RequestBodyObject?)?.content.first.model,
      isA<StringModel>(),
    );
  });

  test('imports double request body alias', () {
    final api = Importer().import(fileContent);
    final doubleAliasBody = api.requestBodies.firstWhereOrNull(
      (r) => r.name == 'DoubleAliasBody',
    );

    expect(doubleAliasBody, isNotNull);
    expect(doubleAliasBody, isA<RequestBodyAlias>());

    final alias = doubleAliasBody as RequestBodyAlias?;
    expect(alias?.requestBody.name, 'AliasBody');
    expect(alias?.requestBody, isA<RequestBodyAlias>());

    final aliasRequestBody = alias?.requestBody as RequestBodyAlias?;
    expect(aliasRequestBody?.requestBody, isA<RequestBodyObject>());
    expect(
      (aliasRequestBody?.requestBody as RequestBodyObject?)
          ?.content
          .first
          .model,
      isA<StringModel>(),
    );
  });

  test('handles duplicate request bodies correctly', () {
    final api = Importer().import(fileContent);

    final duplicateBodies =
        api.requestBodies.where((r) => r.name == 'DuplicateBody').toList();

    expect(duplicateBodies, hasLength(1));

    final duplicateBody = duplicateBodies.first;
    expect(duplicateBody, isA<RequestBodyObject>());
    expect(
      (duplicateBody as RequestBodyObject).description,
      'First definition',
    );
    expect(duplicateBody.isRequired, isTrue);
    expect(duplicateBody.content.first.model, isA<StringModel>());
  });

  test('adds request body when importing a single one', () {
    final openApiObject = parse.OpenApiObject.fromJson(fileContent);
    final modelImporter = ModelImporter(openApiObject)..import();

    final importer = RequestBodyImporter(
      openApiObject: openApiObject,
      modelImporter: modelImporter,
    )..import();

    final imported = importer.importRequestBody(
      name: 'SimpleBody',
      wrapper: InlinedObject(
        parse.RequestBody.fromJson({
          'description': 'A simple request body',
          'required': true,
          'content': {
            'application/json': {
              'schema': {'type': 'string'},
            },
          },
        }),
      ),
      context: RequestBodyImporter.rootContext.push('SimpleBody'),
    );

    expect(importer.requestBodies, contains(imported));
  });
}
