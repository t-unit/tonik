import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  test('explicit multipart style takes precedence in OAS 3.0', () {
    final encoding = _importEncoding(
      version: '3.0.3',
      encoding: {
        'contentType': 'text/plain; charset=latin1',
        'style': 'deepObject',
        'explode': true,
        'allowReserved': true,
      },
    );

    expect(encoding.contentType, isNull);
    expect(encoding.rawContentType, isNull);
    expect(encoding.wireContentType, isNull);
    expect(encoding.style, EncodingStyle.deepObject);
    expect(encoding.explode, isTrue);
    expect(encoding.allowReserved, isNull);
  });

  test('explicit style suppresses media choices for every OAS version', () {
    final oas30 = _importStyleAndChoices('3.0.3');
    final oas31 = _importStyleAndChoices('3.1.0');
    final oas32 = _importStyleAndChoices('3.2.0');

    expect(oas30.requestModel, isA<ClassModel>());
    expect(oas31.requestModel, isA<ClassModel>());
    expect(oas32.requestModel, isA<ClassModel>());
    expect(
      (oas30.requestModel as ClassModel).properties.single.model,
      isA<StringModel>(),
    );
    expect(
      (oas31.requestModel as ClassModel).properties.single.model,
      isA<StringModel>(),
    );
    expect(
      (oas32.requestModel as ClassModel).properties.single.model,
      isA<StringModel>(),
    );
    expect(oas30.encoding['value']!.style, EncodingStyle.form);
    expect(oas31.encoding['value']!.style, EncodingStyle.form);
    expect(oas32.encoding['value']!.style, EncodingStyle.form);
  });

  test('OAS 3.1 explicit style fields select style-based encoding', () {
    final encoding = _importEncoding(
      encoding: {
        'contentType': 'application/json',
        'style': 'deepObject',
        'explode': false,
        'allowReserved': true,
        'headers': {
          'X-Trace': {
            'required': true,
            'schema': {'type': 'string'},
          },
        },
      },
    );

    expect(encoding.contentType, isNull);
    expect(encoding.rawContentType, isNull);
    expect(encoding.style, EncodingStyle.deepObject);
    expect(encoding.explode, isFalse);
    expect(encoding.allowReserved, isNull);
    expect(encoding.headers, contains('X-Trace'));
    final header = encoding.headers!['X-Trace']!;
    expect(header, isA<ResponseHeaderObject>());
    expect((header as ResponseHeaderObject).model, isA<StringModel>());
    expect(header.isRequired, isTrue);
  });

  test('OAS 3.1 defaults style mode from explode or allowReserved', () {
    final explodeOnly = _importEncoding(encoding: {'explode': false});
    expect(explodeOnly.style, EncodingStyle.form);
    expect(explodeOnly.explode, isFalse);
    expect(explodeOnly.allowReserved, isNull);

    final reservedOnly = _importEncoding(encoding: {'allowReserved': true});
    expect(reservedOnly.style, EncodingStyle.form);
    expect(reservedOnly.explode, isTrue);
    expect(reservedOnly.allowReserved, isNull);
    expect(reservedOnly.isStyleBased, isTrue);
  });

  test('style fields are inapplicable outside multipart/form-data', () {
    final api = Importer().import({
      'openapi': '3.2.0',
      'info': {'title': 'Multipart encoding', 'version': '1.0.0'},
      'paths': {
        '/upload': {
          'post': {
            'operationId': 'upload',
            'requestBody': {
              'content': {
                'multipart/mixed': {
                  'schema': {
                    'type': 'object',
                    'properties': {
                      'value': {'type': 'string'},
                    },
                  },
                  'encoding': {
                    'value': {
                      'style': 'form',
                      'explode': false,
                      'allowReserved': true,
                      'contentType': 'text/plain',
                    },
                  },
                },
              },
            },
            'responses': {
              '204': {'description': 'ok'},
            },
          },
        },
      },
    });

    final content = api.operations.single.requestBody!.resolvedContent.single;
    expect(content, isA<ModelRequestContent>());
  });

  test('configured multipart/mixed retains content encoding and siblings', () {
    final api =
        Importer(contentTypes: {'multipart/mixed': ContentType.multipart})
            .import({
              'openapi': '3.2.0',
              'info': {'title': 'Mixed multipart', 'version': '1.0.0'},
              'paths': {
                '/upload': {
                  'post': {
                    'operationId': 'upload',
                    'requestBody': {
                      'content': {
                        'multipart/mixed': {
                          'schema': {
                            'type': 'object',
                            'properties': {
                              'value': {'type': 'string'},
                              'sibling': {'type': 'string'},
                            },
                          },
                          'encoding': {
                            'value': {
                              'style': 'form',
                              'explode': false,
                              'allowReserved': true,
                              'contentType': 'text/plain',
                            },
                            'sibling': {'contentType': 'application/json'},
                          },
                        },
                      },
                    },
                    'responses': {
                      '204': {'description': 'ok'},
                    },
                  },
                },
              },
            });

    final content =
        api.operations.single.requestBody!.resolvedContent.single
            as MultipartRequestContent;
    expect((content.requestModel as ClassModel).properties, hasLength(2));
    expect(content.encoding['value']!.contentType, ContentType.text);
    expect(content.encoding['value']!.rawContentType, 'text/plain');
    expect(content.encoding['value']!.style, isNull);
    expect(content.encoding['value']!.explode, isNull);
    expect(content.encoding['value']!.allowReserved, isNull);
    expect(content.encoding['sibling']!.contentType, ContentType.json);
  });

  test('configured multipart custom subtype retains media choices', () {
    final api =
        Importer(
          contentTypes: {'multipart/form-data-custom': ContentType.multipart},
        ).import({
          'openapi': '3.2.0',
          'info': {'title': 'Custom multipart', 'version': '1.0.0'},
          'paths': {
            '/upload': {
              'post': {
                'operationId': 'upload',
                'requestBody': {
                  'content': {
                    'multipart/form-data-custom': {
                      'schema': {
                        'type': 'object',
                        'properties': {
                          'value': {'type': 'string'},
                          'sibling': {'type': 'string'},
                        },
                      },
                      'encoding': {
                        'value': {
                          'style': 'form',
                          'explode': false,
                          'allowReserved': true,
                          'contentType': 'text/plain, application/json',
                        },
                        'sibling': {'contentType': 'text/plain'},
                      },
                    },
                  },
                },
                'responses': {
                  '204': {'description': 'ok'},
                },
              },
            },
          },
        });

    final content =
        api.operations.single.requestBody!.resolvedContent.single
            as MultipartRequestContent;
    final projected = content.requestModel as ClassModel;
    expect(projected.properties, hasLength(2));
    expect(projected.properties.first.model, isA<MultipartChoiceModel>());
    final choices = projected.properties.first.model as MultipartChoiceModel;
    expect(choices.choices, hasLength(2));
    expect(choices.choices.first.contentType, ContentType.text);
    expect(choices.choices.last.contentType, ContentType.json);
    expect(content.encoding['value']!.style, isNull);
    expect(content.encoding['value']!.explode, isNull);
    expect(content.encoding['value']!.allowReserved, isNull);
    expect(content.encoding['sibling']!.contentType, ContentType.text);
  });

  test('form-data style applies with mixed case and media parameters', () {
    final encoding = _importEncoding(
      mediaType: 'Multipart/Form-Data; boundary=outer',
      encoding: {'style': 'form', 'contentType': 'application/json'},
    );

    expect(encoding.style, EncodingStyle.form);
    expect(encoding.explode, isTrue);
    expect(encoding.contentType, isNull);
    expect(encoding.rawContentType, isNull);
  });

  test('OAS 3.1 content-only encoding preserves text charset handling', () {
    final encoding = _importEncoding(
      encoding: {'contentType': 'text/plain; charset=us-ascii'},
    );

    expect(encoding.contentType, ContentType.text);
    expect(encoding.style, isNull);
    expect(encoding.explode, isNull);
    expect(encoding.allowReserved, isNull);
    expect(encoding.textEncoding, TextEncoding.ascii);
    expect(encoding.wireContentType, 'text/plain; charset=us-ascii');
  });

  test('wildcard-only part encoding uses the local string default', () {
    final encoding = _importEncoding(
      encoding: {'contentType': 'text/*; charset=shift_jis; profile=alpha'},
      contentTypes: {'text/*': ContentType.text},
    );

    expect(encoding.contentType, ContentType.text);
    expect(encoding.rawContentType, 'text/plain');
    expect(encoding.wireContentType, 'text/plain');
    expect(encoding.textEncoding, TextEncoding.utf8);
  });

  test('omits wildcard request content and keeps a concrete sibling', () {
    final api = Importer().import({
      'openapi': '3.2.0',
      'info': {'title': 'Request media', 'version': '1.0.0'},
      'paths': {
        '/send': {
          'post': {
            'operationId': 'send',
            'requestBody': {
              'content': {
                'application/*': {
                  'schema': {'type': 'integer'},
                },
                'application/*+json': {
                  'schema': {'type': 'boolean'},
                },
                'application/j*on': {
                  'schema': {'type': 'number'},
                },
                'application/json': {
                  'schema': {'type': 'string'},
                },
              },
            },
            'responses': {
              '204': {'description': 'ok'},
            },
          },
        },
      },
    });

    final contents = api.operations.single.requestBody!.resolvedContent;
    expect(contents, hasLength(1));
    final concrete = contents.single as ModelRequestContent;
    expect(concrete.rawContentType, 'application/json');
    expect(concrete.model, isA<StringModel>());
  });

  test('keeps concrete request content with an asterisk in a parameter', () {
    final api = Importer().import({
      'openapi': '3.2.0',
      'info': {'title': 'Request media', 'version': '1.0.0'},
      'paths': {
        '/send': {
          'post': {
            'operationId': 'send',
            'requestBody': {
              'content': {
                'application/json; profile="v*2"': {
                  'schema': {'type': 'string'},
                },
              },
            },
            'responses': {
              '204': {'description': 'ok'},
            },
          },
        },
      },
    });

    final contents = api.operations.single.requestBody!.resolvedContent;
    expect(contents, hasLength(1));
    final concrete = contents.single as ModelRequestContent;
    expect(concrete.rawContentType, 'application/json; profile="v*2"');
    expect(concrete.model, isA<StringModel>());
  });

  test('media choices preserve nullable referenced values and lists', () {
    final api = Importer().import({
      'openapi': '3.2.0',
      'info': {'title': 'Nullable choices', 'version': '1.0.0'},
      'components': {
        'schemas': {
          'MaybeText': {'type': 'string', 'nullable': true},
          'MaybeTexts': {
            'type': 'array',
            'nullable': true,
            'items': {'type': 'string'},
          },
        },
      },
      'paths': {
        '/send': {
          'post': {
            'operationId': 'send',
            'requestBody': {
              'content': {
                'multipart/form-data': {
                  'schema': {
                    'type': 'object',
                    'required': ['value', 'values'],
                    'properties': {
                      'value': {r'$ref': '#/components/schemas/MaybeText'},
                      'values': {r'$ref': '#/components/schemas/MaybeTexts'},
                    },
                  },
                  'encoding': {
                    'value': {'contentType': 'text/plain, application/json'},
                    'values': {'contentType': 'text/plain, application/json'},
                  },
                },
              },
            },
            'responses': {
              '204': {'description': 'ok'},
            },
          },
        },
      },
    });

    final content =
        api.operations.single.requestBody!.resolvedContent.single
            as MultipartRequestContent;
    final source = content.model as ClassModel;
    final projected = content.requestModel as ClassModel;
    expect(source.properties.first.isNullable, isFalse);
    expect(source.properties.first.model.isEffectivelyNullable, isTrue);
    expect(projected.properties.first.model, isA<MultipartChoiceModel>());
    expect(projected.properties.first.isNullable, isTrue);
    expect(projected.properties.first.model.isEffectivelyNullable, isTrue);
    expect(source.properties[1].model.isEffectivelyNullable, isTrue);
    final values = projected.properties[1].model as ListModel;
    expect(projected.properties[1].isNullable, isTrue);
    expect(values.isNullable, isTrue);
    expect(values.content, isA<MultipartChoiceModel>());
    expect(api.models, contains(projected));
    expect(api.models, contains(projected.properties.first.model));
    expect(api.models, contains(values.content));
  });

  test('projects named media alternatives without changing the schema', () {
    final api = Importer().import({
      'openapi': '3.2.0',
      'info': {'title': 'Multipart choices', 'version': '1.0.0'},
      'paths': {
        '/upload': {
          'post': {
            'operationId': 'upload',
            'requestBody': {
              'content': {
                'multipart/form-data': {
                  'schema': {
                    'type': 'object',
                    'properties': {
                      'payload': {
                        'type': 'object',
                        'properties': {
                          'message': {'type': 'string'},
                        },
                      },
                      'items': {
                        'type': 'array',
                        'items': {
                          'type': 'object',
                          'properties': {
                            'message': {'type': 'string'},
                          },
                        },
                      },
                      'nested': {
                        'type': 'array',
                        'items': {
                          'type': 'array',
                          'items': {'type': 'integer'},
                        },
                      },
                      'nestedMultipart': {
                        'type': 'object',
                        'properties': {
                          'message': {'type': 'string'},
                        },
                      },
                      'byteMultipart': {'type': 'string', 'format': 'byte'},
                      'byteJson': {'type': 'string', 'format': 'byte'},
                      'quotedBoundary': {
                        'type': 'object',
                        'properties': {
                          'message': {'type': 'string'},
                        },
                      },
                      'single': {'type': 'string'},
                    },
                  },
                  'encoding': {
                    'payload': {
                      'contentType': 'application/json, application/xml; profile="one,two", image/*, application/*+json, application/j*on',
                    },
                    'items': {
                      'contentType': 'application/json, application/xml',
                    },
                    'nested': {
                      'contentType': 'application/json, application/xml',
                    },
                    'nestedMultipart': {
                      'contentType': 'application/json, multipart/form-data; boundary=inner',
                    },
                    'byteMultipart': {
                      'contentType': 'application/octet-stream, multipart/form-data; boundary=inner',
                    },
                    'byteJson': {
                      'contentType': 'application/json, application/xml',
                    },
                    'quotedBoundary': {
                      'contentType': 'application/json, multipart/form-data; profile="x;boundary=inner"',
                    },
                    'single': {'contentType': 'image/*'},
                  },
                },
              },
            },
            'responses': {
              '204': {'description': 'ok'},
            },
          },
        },
      },
    });
    final content =
        api.operations.single.requestBody!.resolvedContent.single
            as MultipartRequestContent;
    final source = content.model as ClassModel;
    final projection = content.requestModel as ClassModel;
    expect(source.properties.first.model, isA<ClassModel>());
    final payload = projection.properties.first.model as MultipartChoiceModel;
    expect(payload.choices.map((choice) => choice.rawContentType), [
      'application/json',
      'application/xml; profile="one,two"',
    ]);
    expect(payload.models.first.model, isA<ClassModel>());
    expect(payload.models[1].model, isA<BinaryModel>());
    final items = projection.properties[1].model as ListModel;
    final itemChoices = items.content as MultipartChoiceModel;
    expect(itemChoices.models.first.model, isA<ClassModel>());
    expect(itemChoices.models.last.model, isA<BinaryModel>());
    final nested = projection.properties[2].model as ListModel;
    final innerChoices = nested.content as MultipartChoiceModel;
    expect(innerChoices.models.first.model, isA<ListModel>());
    expect(innerChoices.models.last.model, isA<BinaryModel>());
    final nestedMultipart =
        projection.properties[3].model as MultipartChoiceModel;
    expect(nestedMultipart.models.first.model, isA<ClassModel>());
    expect(nestedMultipart.models.last.model, isA<BinaryModel>());
    final byteMultipart =
        projection.properties[4].model as MultipartChoiceModel;
    expect(byteMultipart.models.first.model, isA<Base64Model>());
    expect(byteMultipart.models.last.model, isA<BinaryModel>());
    final byteJson = projection.properties[5].model as MultipartChoiceModel;
    expect(byteJson.models.first.model, isA<BinaryModel>());
    expect(byteJson.models.last.model, isA<Base64Model>());
    final quotedBoundary =
        projection.properties[6].model as MultipartChoiceModel;
    expect(quotedBoundary.models.last.model, isA<BinaryModel>());
    expect(quotedBoundary.choices.last.requiresWireContentType, isTrue);
    expect(projection.properties[7].model, isA<StringModel>());
    expect(content.encoding['single']!.rawContentType, 'text/plain');
  });
}

MultipartRequestContent _importStyleAndChoices(String version) {
  final api = Importer().import({
    'openapi': version,
    'info': {'title': 'Multipart encoding', 'version': '1.0.0'},
    'paths': {
      '/upload': {
        'post': {
          'operationId': 'upload',
          'requestBody': {
            'content': {
              'multipart/form-data': {
                'schema': {
                  'type': 'object',
                  'properties': {
                    'value': {'type': 'string'},
                  },
                },
                'encoding': {
                  'value': {
                    'contentType': 'application/json, application/xml',
                    'style': 'form',
                  },
                },
              },
            },
          },
          'responses': {
            '204': {'description': 'ok'},
          },
        },
      },
    },
  });
  return api.operations.single.requestBody!.resolvedContent.single
      as MultipartRequestContent;
}

PartEncoding _importEncoding({
  required Map<String, dynamic> encoding,
  String version = '3.1.0',
  String mediaType = 'multipart/form-data',
  Map<String, ContentTypeMapping> contentTypes = const {},
}) {
  final api = Importer(contentTypes: contentTypes).import({
    'openapi': version,
    'info': {'title': 'Multipart encoding', 'version': '1.0.0'},
    'paths': {
      '/upload': {
        'post': {
          'operationId': 'upload',
          'requestBody': {
            'content': {
              mediaType: {
                'schema': {
                  'type': 'object',
                  'properties': {
                    'value': {'type': 'string'},
                  },
                },
                'encoding': {'value': encoding},
              },
            },
          },
          'responses': {
            '204': {'description': 'ok'},
          },
        },
      },
    },
  });
  final content =
      api.operations.single.requestBody!.resolvedContent.single
          as MultipartRequestContent;
  return content.encoding['value']!;
}
