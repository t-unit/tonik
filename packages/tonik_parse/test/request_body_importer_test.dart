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
        'NullableInlineBody': {
          'description': 'A request body with a nullable inline schema',
          'required': true,
          'content': {
            'application/json': {
              'schema': {'type': 'string', 'nullable': true},
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

  test('resolves request text encodings at the semantic boundary', () {
    Map<String, dynamic> textBody(String contentType) => {
      'required': true,
      'content': {
        contentType: {
          'schema': {'type': 'string'},
        },
      },
    };

    final api =
        Importer(
          contentTypes: {'application/vnd.custom-text': ContentType.text},
        ).import({
          'openapi': '3.0.3',
          'info': {'title': 'Text encoding', 'version': '1.0.0'},
          'paths': <String, dynamic>{},
          'components': {
            'requestBodies': {
              'DefaultUtf8': textBody('text/plain'),
              'Utf8Hyphen': textBody('text/plain; charset=UTF-8'),
              'Utf8Compact': textBody('text/plain; charset=utf8'),
              'Latin1Iso': textBody('text/plain; charset = "ISO-8859-1"'),
              'Latin1Alias': textBody('text/plain; CHARSET=LaTiN1'),
              'AsciiUs': textBody('text/plain; charset = "US-ASCII"'),
              'AsciiAlias': textBody('text/plain; charset=ASCII'),
              'Unsupported': textBody('text/plain; charset=utf-16'),
              'CustomText': textBody(
                'application/vnd.custom-text; charset=latin1',
              ),
              'Multipart': {
                'required': true,
                'content': {
                  'multipart/form-data': {
                    'schema': {
                      'type': 'object',
                      'properties': {
                        'latin': {'type': 'string'},
                        'ascii': {'type': 'integer'},
                        'jsonText': {
                          'type': 'object',
                          'properties': {
                            'value': {'type': 'string'},
                          },
                        },
                        'formText': {
                          'type': 'object',
                          'properties': {
                            'value': {'type': 'string'},
                          },
                        },
                        'repeated': {
                          'type': 'array',
                          'items': {'type': 'string'},
                        },
                        'defaulted': {'type': 'string'},
                        'unsupported': {'type': 'string'},
                        'binary': {'type': 'string', 'format': 'binary'},
                      },
                    },
                    'encoding': {
                      'latin': {
                        'contentType': 'text/plain; charset=iso-8859-1',
                      },
                      'ascii': {'contentType': 'text/plain; charset=us-ascii'},
                      'jsonText': {
                        'contentType': 'application/json; charset=latin1',
                      },
                      'formText': {
                        'contentType':
                            'application/x-www-form-urlencoded; charset=ascii',
                      },
                      'repeated': {'contentType': 'text/plain; charset=latin1'},
                      'unsupported': {
                        'contentType': 'text/plain; charset=utf-16',
                      },
                      'binary': {'contentType': 'application/octet-stream'},
                    },
                  },
                },
              },
            },
          },
        });

    RequestContent contentNamed(String name) =>
        (api.requestBodies.singleWhere((body) => body.name == name)
                as RequestBodyObject)
            .content
            .single;

    final expectedBodies = <String, TextEncoding>{
      'DefaultUtf8': TextEncoding.utf8,
      'Utf8Hyphen': TextEncoding.utf8,
      'Utf8Compact': TextEncoding.utf8,
      'Latin1Iso': TextEncoding.latin1,
      'Latin1Alias': TextEncoding.latin1,
      'AsciiUs': TextEncoding.ascii,
      'AsciiAlias': TextEncoding.ascii,
      'CustomText': TextEncoding.latin1,
    };
    for (final entry in expectedBodies.entries) {
      final content = contentNamed(entry.key);
      expect(content.textEncoding, entry.value, reason: entry.key);
      expect(content.wireContentType, content.rawContentType);
    }

    final unsupported = contentNamed('Unsupported');
    expect(unsupported.textEncoding, TextEncoding.utf8);
    expect(unsupported.rawContentType, 'text/plain; charset=utf-16');
    expect(unsupported.wireContentType, 'text/plain; charset=utf-8');

    final multipart = contentNamed('Multipart');
    final expectedParts = <String, TextEncoding>{
      'latin': TextEncoding.latin1,
      'ascii': TextEncoding.ascii,
      'jsonText': TextEncoding.latin1,
      'formText': TextEncoding.ascii,
      'repeated': TextEncoding.latin1,
      'unsupported': TextEncoding.utf8,
    };
    for (final entry in expectedParts.entries) {
      expect(
        partEncodingFor(multipart, entry.key)!.textEncoding,
        entry.value,
        reason: entry.key,
      );
    }
    expect(partEncodingFor(multipart, 'defaulted'), isNull);
    final unsupportedPart = partEncodingFor(multipart, 'unsupported')!;
    expect(unsupportedPart.rawContentType, 'text/plain; charset=utf-16');
    expect(unsupportedPart.wireContentType, 'text/plain; charset=utf-8');
  });

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
    expect((content as ModelRequestContent?)?.model, isA<StringModel>());
    expect(content?.rawContentType, 'application/json');
    expect(content?.contentType, ContentType.json);
  });

  test('imports request body with nullable inline schema', () {
    final api = Importer().import(fileContent);
    final nullableInlineBody = api.requestBodies.firstWhereOrNull(
      (r) => r.name == 'NullableInlineBody',
    );

    final model =
        ((nullableInlineBody as RequestBodyObject?)?.content.first
                as ModelRequestContent?)
            ?.model;
    expect(model?.isEffectivelyNullable, isTrue);
    expect(model?.resolved, isA<StringModel>());
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
    expect((content as ModelRequestContent?)?.model, isA<ClassModel>());
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
    expect((jsonContent as ModelRequestContent?)?.model, isA<StringModel>());
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
    expect((jsonContent as ModelRequestContent?)?.model, isA<StringModel>());
    expect(jsonContent?.contentType, ContentType.json);

    final problemContent = multipleJsonBody?.content.firstWhereOrNull(
      (c) => c.rawContentType == 'application/problem+json',
    );
    expect((problemContent as ModelRequestContent?)?.model, isA<NumberModel>());
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
    expect((content as ModelRequestContent?)?.model, isA<ClassModel>());

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
      ((alias?.requestBody as RequestBodyObject?)?.content.first
              as ModelRequestContent?)
          ?.model,
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
      ((aliasRequestBody?.requestBody as RequestBodyObject?)?.content.first
              as ModelRequestContent?)
          ?.model,
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
    expect(
      (duplicateBody.content.first as ModelRequestContent).model,
      isA<StringModel>(),
    );
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
                  'schema': {'type': 'string', 'format': 'binary'},
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
                  'schema': {'type': 'string', 'format': 'binary'},
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
                  'schema': {'type': 'string', 'format': 'binary'},
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

    test('resolves application/json to ContentType.json', () {
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
    });

    test('resolves application/x-www-form-urlencoded to ContentType.form', () {
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
    });

    test('resolves form body charset into semantic and wire encoding', () {
      final api = Importer().import({
        'openapi': '3.1.0',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'requestBodies': {
            'FormBody': {
              'content': {
                'application/x-www-form-urlencoded; charset=iso-8859-1': {
                  'schema': {'type': 'string'},
                },
              },
            },
          },
        },
      });

      final content =
          (api.requestBodies.single as RequestBodyObject).content.single;
      expect(content.contentType, ContentType.form);
      expect(content.textEncoding, TextEncoding.latin1);
      expect(
        content.wireContentType,
        'application/x-www-form-urlencoded; charset=iso-8859-1',
      );
    });
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
              'content': {'application/octet-stream': <String, dynamic>{}},
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
      expect((content as ModelRequestContent?)?.model, isA<BinaryModel>());
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
              'content': {'image/png': <String, dynamic>{}},
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
      expect((content as ModelRequestContent?)?.model, isA<BinaryModel>());
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
              'content': {'application/json': <String, dynamic>{}},
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
      expect((content as ModelRequestContent?)?.model, isA<AnyModel>());
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
              'content': {'text/plain': <String, dynamic>{}},
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
      expect((content as ModelRequestContent?)?.model, isA<StringModel>());
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
      expect((content as ModelRequestContent?)?.model, isA<BinaryModel>());
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
              'content': {'application/x-custom-unknown': <String, dynamic>{}},
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
      expect((content as ModelRequestContent?)?.model, isA<BinaryModel>());
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

  group('form-urlencoded encoding support', () {
    ModelRequestContent importFormContent(Map<String, dynamic> spec) {
      final api = Importer().import(spec);
      final body =
          api.requestBodies.firstWhereOrNull((r) => r.name == 'FormBody')!
              as RequestBodyObject;
      return body.content.first as ModelRequestContent;
    }

    Map<String, dynamic> formSpec({
      required Map<String, dynamic> properties,
      String version = '3.1.0',
      Map<String, dynamic>? encoding,
      Map<String, dynamic>? headers,
    }) {
      final mediaType = <String, dynamic>{
        'schema': {'type': 'object', 'properties': properties},
      };
      if (encoding != null) {
        mediaType['encoding'] = encoding;
      }
      final components = <String, dynamic>{
        'requestBodies': {
          'FormBody': {
            'description': 'Form body',
            'required': true,
            'content': {'application/x-www-form-urlencoded': mediaType},
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
          (r) => r.level == Level.WARNING && r.message.contains('nonExistent'),
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
      expect(logs.any((r) => r.level == Level.WARNING), isFalse);
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

PartEncoding? partEncodingFor(RequestContent content, String name) =>
    (content as MultipartRequestContent).encoding[name];

Property? _propertyNamed(ModelRequestContent content, String name) =>
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

FieldEncoding? fieldEncodingFor(ModelRequestContent content, String name) {
  final property = _propertyNamed(content, name);
  if (property == null) return null;
  return content.formEncoding?[property];
}
