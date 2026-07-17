import 'package:collection/collection.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/src/example_importer.dart';
import 'package:tonik_parse/src/model/open_api_object.dart' as parse;
import 'package:tonik_parse/src/model/reference.dart';
import 'package:tonik_parse/src/model/request_body.dart' as parse;
import 'package:tonik_parse/src/model_importer.dart';
import 'package:tonik_parse/src/request_body_importer.dart';
import 'package:tonik_parse/src/response_header_importer.dart';
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
            'application/vnd.custom+type': {
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

    final body = jsonLikeBody as RequestBodyObject?;
    expect(body?.isRequired, isTrue);
    expect(body?.content, hasLength(2));

    final jsonSuffixContent = body?.content.firstWhere(
      (c) => c.rawContentType == 'alto-endpointcost+json',
    );
    expect(jsonSuffixContent?.contentType, ContentType.json);

    final unknownContent = body?.content.firstWhere(
      (c) => c.rawContentType == 'application/vnd.custom+type',
    );
    expect(unknownContent?.contentType, ContentType.bytes);
  });

  test('imports custom content type with configuration', () {
    final api = Importer(
      contentTypes: {'alto-endpointcost+json': ContentType.json},
    ).import(fileContent);
    final jsonLikeBody = api.requestBodies.firstWhereOrNull(
      (r) => r.name == 'JsonLikeBody',
    );

    expect(jsonLikeBody, isNotNull);
    expect(jsonLikeBody, isA<RequestBodyObject>());
    expect((jsonLikeBody as RequestBodyObject?)?.isRequired, isTrue);

    expect(jsonLikeBody?.content, hasLength(2));

    final jsonContent = jsonLikeBody?.content.firstWhere(
      (c) => c.rawContentType == 'alto-endpointcost+json',
    );
    expect(jsonContent?.model, isA<StringModel>());
    expect(jsonContent?.contentType, ContentType.json);

    final bytesContent = jsonLikeBody?.content.firstWhere(
      (c) => c.rawContentType == 'application/vnd.custom+type',
    );
    expect(bytesContent?.contentType, ContentType.bytes);
  });

  test('skips non-JSON content types', () {
    final api = Importer().import(fileContent);
    final invalidBody = api.requestBodies.firstWhereOrNull(
      (r) => r.name == 'InvalidBody',
    );

    expect(invalidBody, isNotNull);
    expect(invalidBody, isA<RequestBodyObject>());
    // text/plain maps to ContentType.text
    final content = (invalidBody as RequestBodyObject?)?.content;
    expect(content, hasLength(1));
    expect(content?.first.contentType, ContentType.text);
  });

  test('imports all JSON content types', () {
    final api = Importer(
      contentTypes: {'application/problem+json': ContentType.json},
    ).import(fileContent);
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

    final duplicateBodies = api.requestBodies
        .where((r) => r.name == 'DuplicateBody')
        .toList();

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
    final exampleImporter = ExampleImporter(openApiObject: openApiObject);
    final modelImporter = ModelImporter(
      openApiObject,
      exampleImporter: exampleImporter,
    )..import();

    final responseHeaderImporter = ResponseHeaderImporter(
      openApiObject: openApiObject,
      modelImporter: modelImporter,
      exampleImporter: exampleImporter,
    )..import();
    final importer = RequestBodyImporter(
      openApiObject: openApiObject,
      modelImporter: modelImporter,
      contentTypes: {},
      responseHeaderImporter: responseHeaderImporter,
      exampleImporter: exampleImporter,
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

  group('content type resolution', () {
    test('resolves text/plain to ContentType.text', () {
      final fileContentWithText = {
        'openapi': '3.1.0',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'requestBodies': {
            'TextBody': {
              'description': 'A plain text request body',
              'required': true,
              'content': {
                'text/plain': {
                  'schema': {'type': 'string'},
                },
              },
            },
          },
        },
      };

      final api = Importer().import(fileContentWithText);
      final textBody = api.requestBodies.firstWhereOrNull(
        (r) => r.name == 'TextBody',
      );

      expect(textBody, isNotNull);
      expect(textBody, isA<RequestBodyObject>());
      expect((textBody as RequestBodyObject?)?.content, hasLength(1));
      final content = textBody?.content.first;
      expect(content?.contentType, ContentType.text);
      expect(content?.rawContentType, 'text/plain');
    });

    test('resolves application/octet-stream to ContentType.bytes', () {
      final fileContentWithBinary = {
        'openapi': '3.1.0',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'requestBodies': {
            'BinaryBody': {
              'description': 'A binary request body',
              'required': true,
              'content': {
                'application/octet-stream': {
                  'schema': {
                    'type': 'string',
                    'format': 'binary',
                  },
                },
              },
            },
          },
        },
      };

      final api = Importer().import(fileContentWithBinary);
      final binaryBody = api.requestBodies.firstWhereOrNull(
        (r) => r.name == 'BinaryBody',
      );

      expect(binaryBody, isNotNull);
      expect(binaryBody, isA<RequestBodyObject>());
      expect((binaryBody as RequestBodyObject?)?.content, hasLength(1));
      final content = binaryBody?.content.first;
      expect(content?.contentType, ContentType.bytes);
      expect(content?.rawContentType, 'application/octet-stream');
    });

    test('defaults unknown content type to bytes with warning', () {
      final fileContentWithUnknown = {
        'openapi': '3.1.0',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'requestBodies': {
            'UnknownBody': {
              'description': 'A request body with unknown content type',
              'required': true,
              'content': {
                'image/jpeg': {
                  'schema': {
                    'type': 'string',
                    'format': 'binary',
                  },
                },
              },
            },
          },
        },
      };

      final api = Importer().import(fileContentWithUnknown);
      final unknownBody = api.requestBodies.firstWhereOrNull(
        (r) => r.name == 'UnknownBody',
      );

      expect(unknownBody, isNotNull);
      expect(unknownBody, isA<RequestBodyObject>());
      expect((unknownBody as RequestBodyObject?)?.content, hasLength(1));
      final content = unknownBody?.content.first;
      expect(content?.contentType, ContentType.bytes);
      expect(content?.rawContentType, 'image/jpeg');
    });

    test('respects explicit content type configuration overrides', () {
      final fileContentWithCustom = {
        'openapi': '3.1.0',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'requestBodies': {
            'CustomBody': {
              'description': 'A request body with custom content type',
              'required': true,
              'content': {
                'application/pdf': {
                  'schema': {
                    'type': 'string',
                    'format': 'binary',
                  },
                },
              },
            },
          },
        },
      };

      final api = Importer(
        contentTypes: {'application/pdf': ContentType.bytes},
      ).import(fileContentWithCustom);
      final customBody = api.requestBodies.firstWhereOrNull(
        (r) => r.name == 'CustomBody',
      );

      expect(customBody, isNotNull);
      expect(customBody, isA<RequestBodyObject>());
      expect((customBody as RequestBodyObject?)?.content, hasLength(1));
      final content = customBody?.content.first;
      expect(content?.contentType, ContentType.bytes);
      expect(content?.rawContentType, 'application/pdf');
    });

    test(
      'resolves application/json to ContentType.json',
      () {
        final fileContentWithJson = {
          'openapi': '3.1.0',
          'info': {'title': 'Test', 'version': '1.0.0'},
          'paths': <String, dynamic>{},
          'components': {
            'requestBodies': {
              'JsonBody': {
                'description': 'A JSON request body',
                'required': true,
                'content': {
                  'application/json': {
                    'schema': {'type': 'object'},
                  },
                },
              },
            },
          },
        };

        final api = Importer().import(fileContentWithJson);
        final jsonBody = api.requestBodies.firstWhereOrNull(
          (r) => r.name == 'JsonBody',
        );

        expect(jsonBody, isNotNull);
        expect(jsonBody, isA<RequestBodyObject>());
        expect((jsonBody as RequestBodyObject?)?.content, hasLength(1));
        final content = jsonBody?.content.first;
        expect(content?.contentType, ContentType.json);
        expect(content?.rawContentType, 'application/json');
      },
    );

    test(
      'resolves application/x-www-form-urlencoded to ContentType.form',
      () {
        final fileContentWithForm = {
          'openapi': '3.1.0',
          'info': {'title': 'Test', 'version': '1.0.0'},
          'paths': <String, dynamic>{},
          'components': {
            'requestBodies': {
              'FormBody': {
                'description': 'A form-urlencoded request body',
                'required': true,
                'content': {
                  'application/x-www-form-urlencoded': {
                    'schema': {'type': 'object'},
                  },
                },
              },
            },
          },
        };

        final api = Importer().import(fileContentWithForm);
        final formBody = api.requestBodies.firstWhereOrNull(
          (r) => r.name == 'FormBody',
        );

        expect(formBody, isNotNull);
        expect(formBody, isA<RequestBodyObject>());
        expect((formBody as RequestBodyObject?)?.content, hasLength(1));
        final content = formBody?.content.first;
        expect(content?.contentType, ContentType.form);
        expect(content?.rawContentType, 'application/x-www-form-urlencoded');
      },
    );
  });

  group('OAS 3.1 empty schema support', () {
    test('infers BinaryModel for application/octet-stream without schema', () {
      final fileContent = {
        'openapi': '3.1.0',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'requestBodies': {
            'BinaryBody': {
              'description': 'Binary content without explicit schema',
              'required': true,
              'content': {
                'application/octet-stream': <String, dynamic>{},
              },
            },
          },
        },
      };

      final api = Importer().import(fileContent);
      final binaryBody = api.requestBodies.firstWhereOrNull(
        (r) => r.name == 'BinaryBody',
      );

      expect(binaryBody, isNotNull);
      expect(binaryBody, isA<RequestBodyObject>());
      expect((binaryBody as RequestBodyObject?)?.content, hasLength(1));

      final content = binaryBody?.content.first;
      expect(content?.model, isA<BinaryModel>());
      expect(content?.rawContentType, 'application/octet-stream');
      expect(content?.contentType, ContentType.bytes);
    });

    test('infers BinaryModel for image/png without schema', () {
      final fileContent = {
        'openapi': '3.1.0',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'requestBodies': {
            'ImageBody': {
              'description': 'Image content without explicit schema',
              'required': true,
              'content': {
                'image/png': <String, dynamic>{},
              },
            },
          },
        },
      };

      final api = Importer().import(fileContent);
      final imageBody = api.requestBodies.firstWhereOrNull(
        (r) => r.name == 'ImageBody',
      );

      expect(imageBody, isNotNull);
      expect(imageBody, isA<RequestBodyObject>());
      expect((imageBody as RequestBodyObject?)?.content, hasLength(1));

      final content = imageBody?.content.first;
      expect(content?.model, isA<BinaryModel>());
      expect(content?.rawContentType, 'image/png');
      expect(content?.contentType, ContentType.bytes);
    });

    test('infers AnyModel for application/json without schema', () {
      final fileContent = {
        'openapi': '3.1.0',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'requestBodies': {
            'JsonBody': {
              'description': 'JSON content without explicit schema',
              'required': true,
              'content': {
                'application/json': <String, dynamic>{},
              },
            },
          },
        },
      };

      final api = Importer().import(fileContent);
      final jsonBody = api.requestBodies.firstWhereOrNull(
        (r) => r.name == 'JsonBody',
      );

      expect(jsonBody, isNotNull);
      expect(jsonBody, isA<RequestBodyObject>());
      expect((jsonBody as RequestBodyObject?)?.content, hasLength(1));

      final content = jsonBody?.content.first;
      expect(content?.model, isA<AnyModel>());
      expect(content?.rawContentType, 'application/json');
      expect(content?.contentType, ContentType.json);
    });

    test('infers StringModel for text/plain without schema', () {
      final fileContent = {
        'openapi': '3.1.0',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'requestBodies': {
            'TextBody': {
              'description': 'Text content without explicit schema',
              'required': true,
              'content': {
                'text/plain': <String, dynamic>{},
              },
            },
          },
        },
      };

      final api = Importer().import(fileContent);
      final textBody = api.requestBodies.firstWhereOrNull(
        (r) => r.name == 'TextBody',
      );

      expect(textBody, isNotNull);
      expect(textBody, isA<RequestBodyObject>());
      expect((textBody as RequestBodyObject?)?.content, hasLength(1));

      final content = textBody?.content.first;
      expect(content?.model, isA<StringModel>());
      expect(content?.rawContentType, 'text/plain');
      expect(content?.contentType, ContentType.text);
    });

    test('infers BinaryModel for form without schema with warning', () {
      final fileContent = {
        'openapi': '3.1.0',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'requestBodies': {
            'FormBody': {
              'description': 'Form content without explicit schema',
              'required': true,
              'content': {
                'application/x-www-form-urlencoded': <String, dynamic>{},
              },
            },
          },
        },
      };

      final api = Importer().import(fileContent);
      final formBody = api.requestBodies.firstWhereOrNull(
        (r) => r.name == 'FormBody',
      );

      expect(formBody, isNotNull);
      expect(formBody, isA<RequestBodyObject>());
      expect((formBody as RequestBodyObject?)?.content, hasLength(1));

      final content = formBody?.content.first;
      expect(content?.model, isA<BinaryModel>());
      expect(content?.rawContentType, 'application/x-www-form-urlencoded');
      expect(content?.contentType, ContentType.form);
    });

    test('infers BinaryModel for unknown content type without schema', () {
      final fileContent = {
        'openapi': '3.1.0',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'requestBodies': {
            'UnknownBody': {
              'description': 'Unknown content type without explicit schema',
              'required': true,
              'content': {
                'application/x-custom-unknown': <String, dynamic>{},
              },
            },
          },
        },
      };

      final api = Importer().import(fileContent);
      final unknownBody = api.requestBodies.firstWhereOrNull(
        (r) => r.name == 'UnknownBody',
      );

      expect(unknownBody, isNotNull);
      expect(unknownBody, isA<RequestBodyObject>());
      expect((unknownBody as RequestBodyObject?)?.content, hasLength(1));

      final content = unknownBody?.content.first;
      expect(content?.model, isA<BinaryModel>());
      expect(content?.rawContentType, 'application/x-custom-unknown');
      expect(content?.contentType, ContentType.bytes);
    });
  });

  group('content type resolution', () {
    test('resolves multipart/form-data to ContentType.multipart', () {
      final fileContentWithMultipart = {
        'openapi': '3.1.0',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'requestBodies': {
            'MultipartBody': {
              'description': 'A multipart request body',
              'required': true,
              'content': {
                'multipart/form-data': {
                  'schema': {
                    'type': 'object',
                    'properties': {
                      'file': {'type': 'string', 'format': 'binary'},
                    },
                  },
                },
              },
            },
          },
        },
      };

      final api = Importer().import(fileContentWithMultipart);
      final multipartBody = api.requestBodies.firstWhereOrNull(
        (r) => r.name == 'MultipartBody',
      );

      expect(multipartBody, isNotNull);
      expect(multipartBody, isA<RequestBodyObject>());
      expect((multipartBody as RequestBodyObject?)?.content, hasLength(1));
      final content = multipartBody?.content.first;
      expect(content?.contentType, ContentType.multipart);
      expect(content?.rawContentType, 'multipart/form-data');
    });
  });

  group('multipart/form-data support', () {
    test('imports multipart/form-data request body with schema', () {
      final fileContentWithMultipart = {
        'openapi': '3.1.0',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'requestBodies': {
            'FileUpload': {
              'description': 'Upload a file',
              'required': true,
              'content': {
                'multipart/form-data': {
                  'schema': {
                    'type': 'object',
                    'properties': {
                      'file': {'type': 'string', 'format': 'binary'},
                      'description': {'type': 'string'},
                    },
                  },
                },
              },
            },
          },
        },
      };

      final api = Importer().import(fileContentWithMultipart);
      final body = api.requestBodies.firstWhereOrNull(
        (r) => r.name == 'FileUpload',
      );

      expect(body, isNotNull);
      expect(body, isA<RequestBodyObject>());
      final bodyObj = body! as RequestBodyObject;
      expect(bodyObj.content, hasLength(1));

      final content = bodyObj.content.first;
      expect(content.contentType, ContentType.multipart);
      expect(content.model, isA<ClassModel>());

      // Default encoding should be populated for all properties
      expect(content.multipartEncoding, isNotNull);
      expect(content.multipartEncoding, hasLength(2));

      final fileEncoding = partEncodingFor(content, 'file')!;
      expect(fileEncoding.contentType, ContentType.bytes);
      expect(fileEncoding.rawContentType, 'application/octet-stream');

      final descriptionEncoding = partEncodingFor(content, 'description')!;
      expect(descriptionEncoding.contentType, ContentType.text);
      expect(descriptionEncoding.rawContentType, 'text/plain');
    });

    test(
      'format: byte property defaults to application/octet-stream in multipart',
      () {
        final fileContentWithBase64 = {
          'openapi': '3.1.0',
          'info': {'title': 'Test', 'version': '1.0.0'},
          'paths': <String, dynamic>{},
          'components': {
            'requestBodies': {
              'Base64Upload': {
                'description': 'Upload with base64 field',
                'required': true,
                'content': {
                  'multipart/form-data': {
                    'schema': {
                      'type': 'object',
                      'properties': {
                        'data': {'type': 'string', 'format': 'byte'},
                        'name': {'type': 'string'},
                      },
                    },
                  },
                },
              },
            },
          },
        };

        final api = Importer().import(fileContentWithBase64);
        final body =
            api.requestBodies.firstWhereOrNull(
                  (r) => r.name == 'Base64Upload',
                )!
                as RequestBodyObject;

        final content = body.content.first;
        expect(content.multipartEncoding, isNotNull);
        expect(content.multipartEncoding, hasLength(2));

        // format: byte → Base64Model → application/octet-stream (spec-correct)
        final dataEncoding = partEncodingFor(content, 'data')!;
        expect(dataEncoding.contentType, ContentType.bytes);
        expect(dataEncoding.rawContentType, 'application/octet-stream');

        // plain string → text/plain
        final nameEncoding = partEncodingFor(content, 'name')!;
        expect(nameEncoding.contentType, ContentType.text);
        expect(nameEncoding.rawContentType, 'text/plain');
      },
    );

    test('imports multipart/form-data with encoding', () {
      final fileContentWithEncoding = {
        'openapi': '3.1.0',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'requestBodies': {
            'EncodedUpload': {
              'description': 'Upload with encoding',
              'required': true,
              'content': {
                'multipart/form-data': {
                  'schema': {
                    'type': 'object',
                    'properties': {
                      'id': {'type': 'string'},
                      'address': {
                        'type': 'object',
                        'properties': {
                          'street': {'type': 'string'},
                        },
                      },
                      'profileImage': {
                        'type': 'string',
                        'format': 'binary',
                      },
                    },
                  },
                  'encoding': {
                    'id': {
                      'contentType': 'text/plain',
                      'style': 'form',
                      'explode': true,
                      'allowReserved': false,
                    },
                    'address': {
                      'contentType': 'application/json',
                      'style': 'deepObject',
                      'explode': true,
                    },
                    'profileImage': {
                      'contentType': 'image/png',
                    },
                  },
                },
              },
            },
          },
        },
      };

      final api = Importer().import(fileContentWithEncoding);
      final body =
          api.requestBodies.firstWhereOrNull(
                (r) => r.name == 'EncodedUpload',
              )!
              as RequestBodyObject;

      final content = body.content.first;
      expect(content.multipartEncoding, isNotNull);
      expect(content.multipartEncoding, hasLength(3));

      final idEncoding = partEncodingFor(content, 'id')!;
      // OAS 3.1: contentType SHALL be ignored when style fields are present
      expect(idEncoding.contentType, isNull);
      expect(idEncoding.rawContentType, isNull);
      expect(idEncoding.style, EncodingStyle.form);
      expect(idEncoding.explode, isTrue);
      expect(idEncoding.allowReserved, isFalse);

      final addressEncoding = partEncodingFor(content, 'address')!;
      // OAS 3.1: contentType SHALL be ignored when style fields are present
      expect(addressEncoding.contentType, isNull);
      expect(addressEncoding.rawContentType, isNull);
      expect(addressEncoding.style, EncodingStyle.deepObject);
      expect(addressEncoding.explode, isTrue);
      expect(addressEncoding.allowReserved, isFalse);

      final imageEncoding = partEncodingFor(content, 'profileImage')!;
      expect(imageEncoding.rawContentType, 'image/png');
      expect(imageEncoding.style, isNull);
      expect(imageEncoding.explode, isNull);
    });

    test('imports multipart/form-data with encoding headers', () {
      final fileContentWithHeaders = {
        'openapi': '3.1.0',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'headers': {
            'X-Custom': {
              'description': 'A custom header',
              'schema': {'type': 'string'},
            },
          },
          'requestBodies': {
            'HeaderUpload': {
              'description': 'Upload with encoding headers',
              'required': true,
              'content': {
                'multipart/form-data': {
                  'schema': {
                    'type': 'object',
                    'properties': {
                      'file': {'type': 'string', 'format': 'binary'},
                    },
                  },
                  'encoding': {
                    'file': {
                      'contentType': 'application/octet-stream',
                      'headers': {
                        'X-Custom': {
                          r'$ref': '#/components/headers/X-Custom',
                        },
                      },
                    },
                  },
                },
              },
            },
          },
        },
      };

      final api = Importer().import(fileContentWithHeaders);
      final body =
          api.requestBodies.firstWhereOrNull(
                (r) => r.name == 'HeaderUpload',
              )!
              as RequestBodyObject;

      final content = body.content.first;
      expect(content.multipartEncoding, isNotNull);

      final fileEncoding = partEncodingFor(content, 'file')!;
      expect(fileEncoding.contentType, ContentType.bytes);
      expect(fileEncoding.rawContentType, 'application/octet-stream');
      expect(fileEncoding.style, isNull);
      expect(fileEncoding.explode, isNull);
      expect(fileEncoding.allowReserved, isNull);
      expect(fileEncoding.headers, isNotNull);
      expect(fileEncoding.headers, hasLength(1));
      expect(fileEncoding.headers!['X-Custom'], isA<ResponseHeaderObject>());
    });

    test('imports multipart/form-data without encoding', () {
      final fileContentNoEncoding = {
        'openapi': '3.1.0',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'requestBodies': {
            'SimpleMultipart': {
              'description': 'Simple multipart',
              'required': true,
              'content': {
                'multipart/form-data': {
                  'schema': {
                    'type': 'object',
                    'properties': {
                      'name': {'type': 'string'},
                    },
                  },
                },
              },
            },
          },
        },
      };

      final api = Importer().import(fileContentNoEncoding);
      final body =
          api.requestBodies.firstWhereOrNull(
                (r) => r.name == 'SimpleMultipart',
              )!
              as RequestBodyObject;

      final content = body.content.first;
      expect(content.contentType, ContentType.multipart);
      expect(content.multipartEncoding, isNotNull);
      expect(content.multipartEncoding, hasLength(1));

      final nameEncoding = partEncodingFor(content, 'name')!;
      expect(nameEncoding.contentType, ContentType.text);
      expect(nameEncoding.rawContentType, 'text/plain');
      expect(nameEncoding.style, isNull);
      expect(nameEncoding.explode, isNull);
      expect(nameEncoding.allowReserved, isNull);
    });

    group('multipart default encoding', () {
      Map<String, dynamic> multipartSpec({
        required Map<String, dynamic> properties,
        String version = '3.1.0',
        Map<String, dynamic>? encoding,
        Map<String, dynamic>? schemas,
      }) {
        final mediaType = <String, dynamic>{
          'schema': {
            'type': 'object',
            'properties': properties,
          },
        };
        if (encoding != null) {
          mediaType['encoding'] = encoding;
        }
        final components = <String, dynamic>{
          'requestBodies': {
            'TestBody': {
              'description': 'Test',
              'required': true,
              'content': {
                'multipart/form-data': mediaType,
              },
            },
          },
        };
        if (schemas != null) {
          components['schemas'] = schemas;
        }
        return {
          'openapi': version,
          'info': {'title': 'Test', 'version': '1.0.0'},
          'paths': <String, dynamic>{},
          'components': components,
        };
      }

      RequestContent importMultipartContent(Map<String, dynamic> spec) {
        final api = Importer().import(spec);
        final body =
            api.requestBodies.firstWhereOrNull(
                  (r) => r.name == 'TestBody',
                )!
                as RequestBodyObject;
        return body.content.first;
      }

      test('string property gets text/plain default', () {
        final content = importMultipartContent(
          multipartSpec(
            properties: {
              'name': {'type': 'string'},
            },
          ),
        );

        expect(content.multipartEncoding, isNotNull);
        expect(content.multipartEncoding, hasLength(1));

        final encoding = partEncodingFor(content, 'name')!;
        expect(encoding.contentType, ContentType.text);
        expect(encoding.rawContentType, 'text/plain');
        expect(encoding.style, isNull);
        expect(encoding.explode, isNull);
        expect(encoding.allowReserved, isNull);
      });

      test('integer property gets text/plain default', () {
        final content = importMultipartContent(
          multipartSpec(
            properties: {
              'count': {'type': 'integer'},
            },
          ),
        );

        final encoding = partEncodingFor(content, 'count')!;
        expect(encoding.contentType, ContentType.text);
        expect(encoding.rawContentType, 'text/plain');
        expect(encoding.style, isNull);
        expect(encoding.explode, isNull);
        expect(encoding.allowReserved, isNull);
      });

      test('boolean property gets text/plain default', () {
        final content = importMultipartContent(
          multipartSpec(
            properties: {
              'active': {'type': 'boolean'},
            },
          ),
        );

        final encoding = partEncodingFor(content, 'active')!;
        expect(encoding.contentType, ContentType.text);
        expect(encoding.rawContentType, 'text/plain');
      });

      test('binary property gets application/octet-stream default', () {
        final content = importMultipartContent(
          multipartSpec(
            properties: {
              'file': {'type': 'string', 'format': 'binary'},
            },
          ),
        );

        final encoding = partEncodingFor(content, 'file')!;
        expect(encoding.contentType, ContentType.bytes);
        expect(encoding.rawContentType, 'application/octet-stream');
        expect(encoding.style, isNull);
        expect(encoding.explode, isNull);
        expect(encoding.allowReserved, isNull);
      });

      test('object property gets application/json default', () {
        final content = importMultipartContent(
          multipartSpec(
            properties: {
              'address': {
                'type': 'object',
                'properties': {
                  'street': {'type': 'string'},
                },
              },
            },
          ),
        );

        final encoding = partEncodingFor(content, 'address')!;
        expect(encoding.contentType, ContentType.json);
        expect(encoding.rawContentType, 'application/json');
      });

      test('AnyModel property gets application/json default', () {
        // AnyModel is created from boolean schemas (true/false), which are
        // OAS 3.1 only (JSON Schema 2020-12). In OAS 3.0, {} becomes a
        // ClassModel, not AnyModel, so AnyModel in 3.0 is unreachable.
        final content = importMultipartContent(
          multipartSpec(
            properties: {
              'data': {r'$ref': '#/components/schemas/AnyValue'},
            },
            schemas: {
              'AnyValue': true,
            },
          ),
        );

        final encoding = partEncodingFor(content, 'data')!;
        expect(encoding.contentType, ContentType.json);
        expect(encoding.rawContentType, 'application/json');
      });

      test('array of objects gets application/json default', () {
        final content = importMultipartContent(
          multipartSpec(
            properties: {
              'items': {
                'type': 'array',
                'items': {
                  'type': 'object',
                  'properties': {
                    'name': {'type': 'string'},
                  },
                },
              },
            },
          ),
        );

        final encoding = partEncodingFor(content, 'items')!;
        expect(encoding.contentType, ContentType.json);
        expect(encoding.rawContentType, 'application/json');
      });

      test('array of strings gets text/plain default', () {
        final content = importMultipartContent(
          multipartSpec(
            properties: {
              'tags': {
                'type': 'array',
                'items': {'type': 'string'},
              },
            },
          ),
        );

        final encoding = partEncodingFor(content, 'tags')!;
        expect(encoding.contentType, ContentType.text);
        expect(encoding.rawContentType, 'text/plain');
      });

      test('nested array of strings gets text/plain default (recursive)', () {
        final content = importMultipartContent(
          multipartSpec(
            properties: {
              'matrix': {
                'type': 'array',
                'items': {
                  'type': 'array',
                  'items': {'type': 'string'},
                },
              },
            },
          ),
        );

        final encoding = partEncodingFor(content, 'matrix')!;
        expect(encoding.contentType, ContentType.text);
        expect(encoding.rawContentType, 'text/plain');
      });

      test('self-recursive array property gets application/json default', () {
        final content = importMultipartContent(
          multipartSpec(
            properties: {
              'tree': {r'$ref': '#/components/schemas/RecursiveList'},
            },
            schemas: {
              'RecursiveList': {
                'type': 'array',
                'items': {r'$ref': '#/components/schemas/RecursiveList'},
              },
            },
          ),
        );

        final encoding = partEncodingFor(content, 'tree')!;
        expect(encoding.contentType, ContentType.json);
        expect(encoding.rawContentType, 'application/json');
      });

      test(
        'mutually recursive array property gets application/json default',
        () {
          final content = importMultipartContent(
            multipartSpec(
              properties: {
                'chain': {r'$ref': '#/components/schemas/LinkA'},
              },
              schemas: {
                'LinkA': {
                  'type': 'array',
                  'items': {r'$ref': '#/components/schemas/LinkB'},
                },
                'LinkB': {
                  'type': 'array',
                  'items': {r'$ref': '#/components/schemas/LinkA'},
                },
              },
            ),
          );

          final encoding = partEncodingFor(content, 'chain')!;
          expect(encoding.contentType, ContentType.json);
          expect(encoding.rawContentType, 'application/json');
        },
      );

      test('array of AnyModel gets application/json default', () {
        // See AnyModel test above — AnyModel is OAS 3.1 only.
        final content = importMultipartContent(
          multipartSpec(
            properties: {
              'values': {
                'type': 'array',
                'items': {r'$ref': '#/components/schemas/AnyValue'},
              },
            },
            schemas: {
              'AnyValue': true,
            },
          ),
        );

        final encoding = partEncodingFor(content, 'values')!;
        expect(encoding.contentType, ContentType.json);
        expect(encoding.rawContentType, 'application/json');
      });

      test('AliasModel wrapping string gets text/plain default', () {
        final content = importMultipartContent(
          multipartSpec(
            properties: {
              'label': {r'$ref': '#/components/schemas/MyString'},
            },
            schemas: {
              'MyString': {'type': 'string'},
            },
          ),
        );

        final encoding = partEncodingFor(content, 'label')!;
        expect(encoding.contentType, ContentType.text);
        expect(encoding.rawContentType, 'text/plain');
      });

      test('enum property gets text/plain default', () {
        final content = importMultipartContent(
          multipartSpec(
            properties: {
              'status': {
                'type': 'string',
                'enum': ['active', 'inactive'],
              },
            },
          ),
        );

        final encoding = partEncodingFor(content, 'status')!;
        expect(encoding.contentType, ContentType.text);
        expect(encoding.rawContentType, 'text/plain');
      });

      test(
        'explicit encoding (OAS 3.1) preserves values and fills defaults',
        () {
          final content = importMultipartContent(
            multipartSpec(
              properties: {
                'data': {
                  'type': 'object',
                  'properties': {
                    'name': {'type': 'string'},
                  },
                },
              },
              encoding: {
                'data': {
                  'contentType': 'application/xml',
                  'style': 'deepObject',
                },
              },
            ),
          );

          final encoding = partEncodingFor(content, 'data')!;
          // OAS 3.1: when style fields are present, contentType SHALL be
          // ignored
          expect(encoding.rawContentType, isNull);
          expect(encoding.contentType, isNull);
          expect(encoding.style, EncodingStyle.deepObject);
          // deepObject: explode defaults to false per OAS spec
          expect(encoding.explode, isFalse);
          expect(encoding.allowReserved, isFalse);
        },
      );

      test('OAS 3.0 ignores explicit style fields (always content-based)', () {
        final content = importMultipartContent(
          multipartSpec(
            version: '3.0.3',
            properties: {
              'data': {
                'type': 'object',
                'properties': {
                  'name': {'type': 'string'},
                },
              },
            },
            encoding: {
              'data': {
                'contentType': 'application/xml',
                'style': 'deepObject',
                'explode': false,
                'allowReserved': true,
              },
            },
          ),
        );

        final encoding = partEncodingFor(content, 'data')!;
        // contentType is preserved (not affected by version)
        expect(encoding.rawContentType, 'application/xml');
        // OAS 3.0 always uses content-based mode: style fields are null
        expect(encoding.style, isNull);
        expect(encoding.explode, isNull);
        expect(encoding.allowReserved, isNull);
      });

      test(
        'content-based when only contentType is explicit (no style fields)',
        () {
          final content = importMultipartContent(
            multipartSpec(
              properties: {
                'data': {
                  'type': 'object',
                  'properties': {
                    'name': {'type': 'string'},
                  },
                },
              },
              encoding: {
                'data': {'contentType': 'application/xml'},
              },
            ),
          );

          final encoding = partEncodingFor(content, 'data')!;
          expect(encoding.rawContentType, 'application/xml');
          // No style fields set → content-based mode
          expect(encoding.style, isNull);
          expect(encoding.explode, isNull);
          expect(encoding.allowReserved, isNull);
        },
      );

      test('style-based when only explode is explicit', () {
        final content = importMultipartContent(
          multipartSpec(
            properties: {
              'data': {
                'type': 'object',
                'properties': {
                  'name': {'type': 'string'},
                },
              },
            },
            encoding: {
              'data': {'explode': false},
            },
          ),
        );

        final encoding = partEncodingFor(content, 'data')!;
        // explode explicitly set → style-based mode with defaults filled
        expect(encoding.style, EncodingStyle.form);
        expect(encoding.explode, isFalse);
        expect(encoding.allowReserved, isFalse);
      });

      test('style-based when explode is explicitly true (default value)', () {
        final content = importMultipartContent(
          multipartSpec(
            properties: {
              'data': {
                'type': 'object',
                'properties': {
                  'name': {'type': 'string'},
                },
              },
            },
            encoding: {
              'data': {'explode': true},
            },
          ),
        );

        final encoding = partEncodingFor(content, 'data')!;
        // explode explicitly set to true (even though it's the form default)
        // still triggers style-based mode
        expect(encoding.style, EncodingStyle.form);
        expect(encoding.explode, isTrue);
        expect(encoding.allowReserved, isFalse);
      });

      test('style-based when only allowReserved is explicit', () {
        final content = importMultipartContent(
          multipartSpec(
            properties: {
              'data': {
                'type': 'object',
                'properties': {
                  'name': {'type': 'string'},
                },
              },
            },
            encoding: {
              'data': {'allowReserved': true},
            },
          ),
        );

        final encoding = partEncodingFor(content, 'data')!;
        // allowReserved explicitly set → style-based mode with defaults filled
        expect(encoding.style, EncodingStyle.form);
        expect(encoding.explode, isTrue);
        expect(encoding.allowReserved, isTrue);
      });

      test('style-based when only style (form) is explicit: '
          'explode defaults true', () {
        final content = importMultipartContent(
          multipartSpec(
            properties: {
              'data': {
                'type': 'object',
                'properties': {
                  'name': {'type': 'string'},
                },
              },
            },
            encoding: {
              'data': {'style': 'form'},
            },
          ),
        );

        final encoding = partEncodingFor(content, 'data')!;
        // form style → explode defaults to true per OAS spec
        expect(encoding.style, EncodingStyle.form);
        expect(encoding.explode, isTrue);
        expect(encoding.allowReserved, isFalse);
      });

      test('style-based when only style (deepObject) is explicit: '
          'explode defaults false', () {
        final content = importMultipartContent(
          multipartSpec(
            properties: {
              'data': {
                'type': 'object',
                'properties': {
                  'name': {'type': 'string'},
                },
              },
            },
            encoding: {
              'data': {'style': 'deepObject'},
            },
          ),
        );

        final encoding = partEncodingFor(content, 'data')!;
        // non-form style → explode defaults to false per OAS spec
        expect(encoding.style, EncodingStyle.deepObject);
        expect(encoding.explode, isFalse);
        expect(encoding.allowReserved, isFalse);
      });

      test('multipart encoding map is keyed by the declared Property '
          'instance', () {
        final content = importMultipartContent(
          multipartSpec(
            properties: {
              'name': {'type': 'string'},
            },
          ),
        );

        final classModel = content.model.resolved as ClassModel;
        final nameProperty = classModel.properties.single;
        expect(content.multipartEncoding!.keys.single, same(nameProperty));
      });

      test('multipart encoding on an alias-chain property keys by declared '
          'Property', () {
        final content = importMultipartContent(
          multipartSpec(
            properties: {
              'label': {r'$ref': '#/components/schemas/MyString'},
            },
            schemas: {
              'MyString': {'type': 'string'},
            },
          ),
        );

        final classModel = content.model.resolved as ClassModel;
        final labelProperty = classModel.properties.single;
        expect(labelProperty.model, isA<AliasModel>());
        expect(content.multipartEncoding!.keys.single, same(labelProperty));
        expect(
          content.multipartEncoding![labelProperty]!.contentType,
          ContentType.text,
        );
      });

      test('mixed map: style-based property and content-based property '
          'coexist correctly', () {
        final content = importMultipartContent(
          multipartSpec(
            properties: {
              'styled': {
                'type': 'object',
                'properties': {
                  'key': {'type': 'string'},
                },
              },
              'plain': {'type': 'string'},
            },
            encoding: {
              'styled': {'style': 'deepObject'},
            },
          ),
        );

        // 'styled' has explicit style → style-based mode
        final styledEncoding = partEncodingFor(content, 'styled')!;
        expect(styledEncoding.style, EncodingStyle.deepObject);
        expect(styledEncoding.explode, isFalse);
        expect(styledEncoding.allowReserved, isFalse);
        expect(styledEncoding.isStyleBased, isTrue);

        // 'plain' has no explicit encoding → content-based mode
        final plainEncoding = partEncodingFor(content, 'plain')!;
        expect(plainEncoding.style, isNull);
        expect(plainEncoding.explode, isNull);
        expect(plainEncoding.allowReserved, isNull);
        expect(plainEncoding.isStyleBased, isFalse);
      });

      test('readOnly properties are dropped from encoding map', () {
        final content = importMultipartContent(
          multipartSpec(
            properties: {
              'id': {
                'type': 'string',
                'readOnly': true,
              },
              'name': {'type': 'string'},
            },
          ),
        );

        expect(content.multipartEncoding, hasLength(1));
        expect(partEncodingFor(content, 'id'), isNull);
        expect(partEncodingFor(content, 'name'), isNotNull);
      });

      test('writeOnly properties are included in encoding map', () {
        final content = importMultipartContent(
          multipartSpec(
            properties: {
              'password': {
                'type': 'string',
                'writeOnly': true,
              },
            },
          ),
        );

        expect(content.multipartEncoding, hasLength(1));
        final password = partEncodingFor(content, 'password')!;
        expect(password.contentType, ContentType.text);
        expect(password.rawContentType, 'text/plain');
      });

      test(
        'format: byte string property gets application/octet-stream',
        () {
          final content = importMultipartContent(
            multipartSpec(
              properties: {
                'encoded': {'type': 'string', 'format': 'byte'},
              },
            ),
          );

          final encoding = partEncodingFor(content, 'encoded')!;
          expect(encoding.contentType, ContentType.bytes);
          expect(encoding.rawContentType, 'application/octet-stream');
        },
      );

      test('explicit contentType overrides format:byte text/plain default', () {
        final content = importMultipartContent(
          multipartSpec(
            properties: {
              'data': {'type': 'string', 'format': 'byte'},
            },
            encoding: {
              'data': {'contentType': 'text/plain'},
            },
          ),
        );
        final encoding = partEncodingFor(content, 'data')!;
        expect(encoding.contentType, ContentType.text);
        expect(encoding.rawContentType, 'text/plain');
      });

      test(
        r'format:byte via $ref property schema gets application/octet-stream',
        () {
          final content = importMultipartContent(
            multipartSpec(
              properties: {
                'data': {r'$ref': '#/components/schemas/ByteData'},
              },
              schemas: {
                'ByteData': {'type': 'string', 'format': 'byte'},
              },
            ),
          );
          final encoding = partEncodingFor(content, 'data')!;
          expect(encoding.contentType, ContentType.bytes);
          expect(encoding.rawContentType, 'application/octet-stream');
        },
      );

      test('form-urlencoded body does not get default encoding populated', () {
        final spec = {
          'openapi': '3.1.0',
          'info': {'title': 'Test', 'version': '1.0.0'},
          'paths': <String, dynamic>{},
          'components': {
            'requestBodies': {
              'FormBody': {
                'description': 'Form body',
                'required': true,
                'content': {
                  'application/x-www-form-urlencoded': {
                    'schema': {
                      'type': 'object',
                      'properties': {
                        'name': {'type': 'string'},
                      },
                    },
                  },
                },
              },
            },
          },
        };

        final api = Importer().import(spec);
        final body =
            api.requestBodies.firstWhereOrNull(
                  (r) => r.name == 'FormBody',
                )!
                as RequestBodyObject;

        final content = body.content.first;
        expect(content.contentType, ContentType.form);
        expect(content.formEncoding, isNull);
      });

      test('encoding keys not matching any property log warning '
          'and are dropped', () {
        final logs = <LogRecord>[];
        final sub = Logger.root.onRecord.listen(logs.add);

        addTearDown(sub.cancel);

        final content = importMultipartContent(
          multipartSpec(
            properties: {
              'name': {'type': 'string'},
            },
            encoding: {
              'name': {'contentType': 'text/plain'},
              'nonExistent': {'contentType': 'application/json'},
            },
          ),
        );

        expect(content.multipartEncoding, hasLength(1));
        expect(partEncodingFor(content, 'name'), isNotNull);
        expect(_propertyNamed(content, 'nonExistent'), isNull);
        expect(
          logs.any(
            (r) =>
                r.level == Level.WARNING && r.message.contains('nonExistent'),
          ),
          isTrue,
        );
      });

      test('multiple properties each get correct default content type', () {
        final content = importMultipartContent(
          multipartSpec(
            properties: {
              'name': {'type': 'string'},
              'age': {'type': 'integer'},
              'photo': {'type': 'string', 'format': 'binary'},
              'metadata': {
                'type': 'object',
                'properties': {
                  'key': {'type': 'string'},
                },
              },
            },
          ),
        );

        expect(content.multipartEncoding, hasLength(4));
        expect(partEncodingFor(content, 'name')!.contentType, ContentType.text);
        expect(partEncodingFor(content, 'age')!.contentType, ContentType.text);
        expect(
          partEncodingFor(content, 'photo')!.contentType,
          ContentType.bytes,
        );
        expect(
          partEncodingFor(content, 'metadata')!.contentType,
          ContentType.json,
        );
      });

      test('non-ClassModel multipart body does not get encoding populated '
          'and logs warning', () {
        final logs = <LogRecord>[];
        final sub = Logger.root.onRecord.listen(logs.add);

        addTearDown(sub.cancel);

        final spec = {
          'openapi': '3.1.0',
          'info': {'title': 'Test', 'version': '1.0.0'},
          'paths': <String, dynamic>{},
          'components': {
            'requestBodies': {
              'BareString': {
                'description': 'Bare string multipart',
                'required': true,
                'content': {
                  'multipart/form-data': {
                    'schema': {'type': 'string'},
                  },
                },
              },
            },
          },
        };

        final api = Importer().import(spec);
        final body =
            api.requestBodies.firstWhereOrNull(
                  (r) => r.name == 'BareString',
                )!
                as RequestBodyObject;

        final content = body.content.first;
        expect(content.multipartEncoding, isNull);
        expect(
          logs.any(
            (r) =>
                r.level == Level.WARNING &&
                r.message.contains('BareString') &&
                r.message.contains('non-object schema'),
          ),
          isTrue,
        );
      });
    });

    test('infers BinaryModel for multipart/form-data without schema', () {
      final fileContentNoSchema = {
        'openapi': '3.1.0',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'requestBodies': {
            'NoSchemaMultipart': {
              'description': 'Multipart without schema',
              'required': true,
              'content': {
                'multipart/form-data': <String, dynamic>{},
              },
            },
          },
        },
      };

      final api = Importer().import(fileContentNoSchema);
      final body =
          api.requestBodies.firstWhereOrNull(
                (r) => r.name == 'NoSchemaMultipart',
              )!
              as RequestBodyObject;

      final content = body.content.first;
      expect(content.model, isA<BinaryModel>());
      expect(content.contentType, ContentType.multipart);
    });
  });

  group('form-urlencoded encoding support', () {
    RequestContent importFormContent(Map<String, dynamic> spec) {
      final api = Importer().import(spec);
      final body =
          api.requestBodies.firstWhereOrNull(
                (r) => r.name == 'FormBody',
              )!
              as RequestBodyObject;
      return body.content.first;
    }

    Map<String, dynamic> formSpec({
      required Map<String, dynamic> properties,
      String version = '3.1.0',
      Map<String, dynamic>? encoding,
      Map<String, dynamic>? headers,
    }) {
      final mediaType = <String, dynamic>{
        'schema': {
          'type': 'object',
          'properties': properties,
        },
      };
      if (encoding != null) {
        mediaType['encoding'] = encoding;
      }
      final components = <String, dynamic>{
        'requestBodies': {
          'FormBody': {
            'description': 'Form body',
            'required': true,
            'content': {
              'application/x-www-form-urlencoded': mediaType,
            },
          },
        },
      };
      if (headers != null) {
        components['headers'] = headers;
      }
      return {
        'openapi': version,
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': components,
      };
    }

    test('captures allowReserved true from encoding object', () {
      final content = importFormContent(
        formSpec(
          properties: {
            'filter': {'type': 'string'},
          },
          encoding: {
            'filter': {'allowReserved': true},
          },
        ),
      );

      expect(content.contentType, ContentType.form);
      expect(content.formEncoding, isNotNull);
      expect(content.formEncoding, hasLength(1));
      final filterEncoding = fieldEncodingFor(content, 'filter')!;
      expect(filterEncoding.allowReserved, isTrue);
      expect(filterEncoding.style, isNull);
      expect(filterEncoding.explode, isNull);
    });

    test('encoding is null when no encoding object is present', () {
      final content = importFormContent(
        formSpec(
          properties: {
            'name': {'type': 'string'},
          },
        ),
      );

      expect(content.contentType, ContentType.form);
      expect(content.formEncoding, isNull);
    });

    test(
      'allowReserved defaults to false when absent from encoding object',
      () {
        final content = importFormContent(
          formSpec(
            properties: {
              'name': {'type': 'string'},
            },
            encoding: {
              'name': {'style': 'form'},
            },
          ),
        );

        expect(fieldEncodingFor(content, 'name')!.allowReserved, isFalse);
      },
    );

    test('captures allowReserved true under OAS 3.0', () {
      final content = importFormContent(
        formSpec(
          version: '3.0.3',
          properties: {
            'filter': {'type': 'string'},
          },
          encoding: {
            'filter': {'allowReserved': true},
          },
        ),
      );

      expect(fieldEncodingFor(content, 'filter')!.allowReserved, isTrue);
    });

    test('captures allowReserved true under OAS 3.1', () {
      final content = importFormContent(
        formSpec(
          properties: {
            'filter': {'type': 'string'},
          },
          encoding: {
            'filter': {'allowReserved': true},
          },
        ),
      );

      expect(fieldEncodingFor(content, 'filter')!.allowReserved, isTrue);
    });

    test('resolves an encoding key against an allOf member property', () {
      final content = importFormContent({
        'openapi': '3.1.0',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'requestBodies': {
            'FormBody': {
              'description': 'Form body',
              'required': true,
              'content': {
                'application/x-www-form-urlencoded': {
                  'schema': {
                    'allOf': [
                      {
                        'type': 'object',
                        'properties': {
                          'reserved': {'type': 'string'},
                        },
                      },
                    ],
                  },
                  'encoding': {
                    'reserved': {'allowReserved': true},
                  },
                },
              },
            },
          },
        },
      });

      expect(content.formEncoding, isNotNull);
      expect(content.formEncoding, hasLength(1));
      expect(fieldEncodingFor(content, 'reserved')!.allowReserved, isTrue);
    });

    test('does not apply multipart per-property content type defaults', () {
      final content = importFormContent(
        formSpec(
          properties: {
            'name': {'type': 'string'},
            'meta': {
              'type': 'object',
              'properties': {
                'key': {'type': 'string'},
              },
            },
          },
          encoding: {
            'name': {'allowReserved': true},
          },
        ),
      );

      expect(content.formEncoding, hasLength(1));
      expect(fieldEncodingFor(content, 'name'), isNotNull);
      final metaProperty = _propertyNamed(content, 'meta');
      expect(metaProperty, isNotNull);
      expect(content.formEncoding!.containsKey(metaProperty), isFalse);
    });

    test('captures style and explode from encoding object', () {
      final content = importFormContent(
        formSpec(
          properties: {
            'ids': {
              'type': 'array',
              'items': {'type': 'string'},
            },
          },
          encoding: {
            'ids': {'style': 'spaceDelimited', 'explode': false},
          },
        ),
      );

      final idsEncoding = fieldEncodingFor(content, 'ids')!;
      expect(idsEncoding.style, EncodingStyle.spaceDelimited);
      expect(idsEncoding.explode, isFalse);
      expect(idsEncoding.allowReserved, isFalse);
    });

    test('encoding key not matching any property logs warning', () {
      final logs = <LogRecord>[];
      final sub = Logger.root.onRecord.listen(logs.add);

      addTearDown(sub.cancel);

      final content = importFormContent(
        formSpec(
          properties: {
            'name': {'type': 'string'},
          },
          encoding: {
            'name': {'allowReserved': true},
            'nonExistent': {'allowReserved': true},
          },
        ),
      );

      expect(content.contentType, ContentType.form);
      expect(fieldEncodingFor(content, 'name'), isNotNull);
      expect(content.formEncoding, hasLength(1));
      expect(_propertyNamed(content, 'nonExistent'), isNull);
      expect(
        content.formEncoding!.keys.any((p) => p.name == 'nonExistent'),
        isFalse,
      );
      expect(
        logs.any(
          (r) =>
              r.level == Level.WARNING && r.message.contains('nonExistent'),
        ),
        isTrue,
      );
    });

    test('matching encoding key does not log warning', () {
      final logs = <LogRecord>[];
      final sub = Logger.root.onRecord.listen(logs.add);

      addTearDown(sub.cancel);

      final content = importFormContent(
        formSpec(
          properties: {
            'name': {'type': 'string'},
          },
          encoding: {
            'name': {'allowReserved': true},
          },
        ),
      );

      expect(fieldEncodingFor(content, 'name')!.allowReserved, isTrue);
      expect(
        logs.any(
          (r) =>
              r.level == Level.WARNING &&
              r.message.contains('form-urlencoded schema'),
        ),
        isFalse,
      );
    });

    test('non-object schema with an encoding block logs a warning', () {
      final logs = <LogRecord>[];
      final sub = Logger.root.onRecord.listen(logs.add);

      addTearDown(sub.cancel);

      final content = importFormContent({
        'openapi': '3.1.0',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'requestBodies': {
            'FormBody': {
              'description': 'Form body',
              'required': true,
              'content': {
                'application/x-www-form-urlencoded': {
                  'schema': {
                    'type': 'array',
                    'items': {'type': 'string'},
                  },
                  'encoding': {
                    'ids': {'allowReserved': true},
                  },
                },
              },
            },
          },
        },
      });

      expect(content.formEncoding, isEmpty);
      expect(
        logs.any(
          (r) =>
              r.level == Level.WARNING &&
              r.message.contains('non-object schema'),
        ),
        isTrue,
      );
    });

    test('unmapped form style is dropped to null while entry is imported', () {
      final content = importFormContent(
        formSpec(
          properties: {
            'name': {'type': 'string'},
          },
          encoding: {
            'name': {'style': 'matrix'},
          },
        ),
      );

      expect(content.formEncoding, hasLength(1));
      final nameEncoding = fieldEncodingFor(content, 'name')!;
      expect(nameEncoding.style, isNull);
    });

    test('form encoding captures the property with default field values', () {
      final content = importFormContent(
        formSpec(
          properties: {
            'name': {'type': 'string'},
          },
          encoding: {
            'name': {'contentType': 'text/plain'},
          },
        ),
      );

      final nameEncoding = fieldEncodingFor(content, 'name')!;
      expect(nameEncoding.allowReserved, isFalse);
      expect(nameEncoding.style, isNull);
      expect(nameEncoding.explode, isNull);
    });

    test('form encoding map is keyed by the declared Property instance', () {
      final content = importFormContent(
        formSpec(
          properties: {
            'name': {'type': 'string'},
          },
          encoding: {
            'name': {'allowReserved': true},
          },
        ),
      );

      final classModel = content.model.resolved as ClassModel;
      final nameProperty = classModel.properties.single;
      expect(content.formEncoding!.keys.single, same(nameProperty));
      expect(content.formEncoding![nameProperty]!.allowReserved, isTrue);
    });

    test('read-only form property is dropped from the encoding map '
        'without a warning', () {
      final logs = <LogRecord>[];
      final sub = Logger.root.onRecord.listen(logs.add);

      addTearDown(sub.cancel);

      final content = importFormContent(
        formSpec(
          properties: {
            'id': {'type': 'string', 'readOnly': true},
            'name': {'type': 'string'},
          },
          encoding: {
            'id': {'allowReserved': true},
            'name': {'allowReserved': true},
          },
        ),
      );

      expect(content.formEncoding, hasLength(1));
      expect(fieldEncodingFor(content, 'id'), isNull);
      expect(fieldEncodingFor(content, 'name'), isNotNull);
      expect(
        logs.any((r) => r.level == Level.WARNING),
        isFalse,
      );
    });

    test('form encoding on an alias-chain property keys by declared '
        'Property', () {
      final content = importFormContent({
        'openapi': '3.1.0',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'MyString': {'type': 'string'},
          },
          'requestBodies': {
            'FormBody': {
              'description': 'Form body',
              'required': true,
              'content': {
                'application/x-www-form-urlencoded': {
                  'schema': {
                    'type': 'object',
                    'properties': {
                      'label': {r'$ref': '#/components/schemas/MyString'},
                    },
                  },
                  'encoding': {
                    'label': {'allowReserved': true},
                  },
                },
              },
            },
          },
        },
      });

      final classModel = content.model.resolved as ClassModel;
      final labelProperty = classModel.properties.single;
      expect(labelProperty.model, isA<AliasModel>());
      expect(content.formEncoding!.keys.single, same(labelProperty));
      expect(content.formEncoding![labelProperty]!.allowReserved, isTrue);
    });
  });
}

Property? _propertyNamed(RequestContent content, String name) =>
    _propertyNamedIn(content.model, name);

Property? _propertyNamedIn(Model model, String name) {
  switch (model.resolved) {
    case final ClassModel resolved:
      return resolved.properties.firstWhereOrNull((p) => p.name == name);
    case final AllOfModel resolved:
      for (final member in resolved.models) {
        final property = _propertyNamedIn(member, name);
        if (property != null) return property;
      }
      return null;
    default:
      return null;
  }
}

PartEncoding? partEncodingFor(RequestContent content, String name) {
  final property = _propertyNamed(content, name);
  if (property == null) return null;
  return content.multipartEncoding?[property];
}

FieldEncoding? fieldEncodingFor(RequestContent content, String name) {
  final property = _propertyNamed(content, name);
  if (property == null) return null;
  return content.formEncoding?[property];
}
