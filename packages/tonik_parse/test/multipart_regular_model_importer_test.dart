import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/src/model/header.dart' as parse;
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  test('preserves valid header fields beside malformed optional entries', () {
    final header = parse.Header.fromJson({
      'schema': {'type': 'string'},
      'content': {
        'application/json': {
          'schema': {'type': 'string'},
        },
        'application/xml': 42,
      },
      'examples': {
        'Broken': 42,
        'Good': {'value': 'example'},
      },
    });

    expect(header.schema!.type, ['string']);
    expect(header.content!.keys, ['application/json']);
    expect(header.examples!.keys, ['Good']);

    final contentOnly = parse.Header.fromJson({
      'schema': 42,
      'content': {'text/plain': <String, dynamic>{}},
    });
    expect(contentOnly.schema, isNull);
    expect(contentOnly.content!.keys, ['text/plain']);

    expect(
      () => parse.Header.fromJson({
        'schema': {r'$ref': 42},
      }),
      throwsA(isA<TypeError>()),
    );
  });

  test('imports inline multipart schemas as regular class models', () {
    final api = Importer().import(
      _document(
        paths: {
          '/inline': {
            'post': {
              'operationId': 'inline',
              'requestBody': {
                'content': {
                  'multipart/form-data': {
                    'schema': {
                      'type': 'object',
                      'properties': {
                        'file': {'type': 'string', 'format': 'binary'},
                        'label': {'type': 'string'},
                      },
                    },
                  },
                },
              },
              'responses': _responses,
            },
          },
        },
      ),
    );

    final content = _multipart(api, 'inline');
    final model = content.model as ClassModel;
    expect(model.properties.map((property) => property.name), [
      'file',
      'label',
    ]);
    expect(model.properties.first.model, isA<BinaryModel>());
    expect(content.encoding['file']!.contentType, ContentType.bytes);
    expect(
      content.encoding['file']!.wireContentType,
      'application/octet-stream',
    );
    expect(content.encoding['label']!.contentType, ContentType.text);
    expect(content.encoding['label']!.wireContentType, 'text/plain');
  });

  test('sets named part defaults from each value or array item', () {
    final api = Importer().import(
      _document(
        paths: {
          '/defaults': {
            'post': {
              'operationId': 'defaults',
              'requestBody': {
                'content': {
                  'multipart/form-data': {
                    'schema': {
                      'type': 'object',
                      'properties': {
                        'count': {'type': 'integer'},
                        'active': {'type': 'boolean'},
                        'object': {
                          'type': 'object',
                          'properties': {
                            'x': {'type': 'string'},
                          },
                        },
                        'items': {
                          'type': 'array',
                          'items': {'type': 'object'},
                        },
                        'nested': {
                          'type': 'array',
                          'items': {
                            'type': 'array',
                            'items': {'type': 'integer'},
                          },
                        },
                        'unknown': <String, dynamic>{},
                        'encoded': {
                          'type': 'string',
                          'contentEncoding': 'base64',
                        },
                      },
                    },
                  },
                },
              },
              'responses': _responses,
            },
          },
        },
      ),
    );

    final encoding = _multipart(api, 'defaults').encoding;
    expect(encoding['count']!.wireContentType, 'text/plain');
    expect(encoding['active']!.wireContentType, 'text/plain');
    expect(encoding['object']!.wireContentType, 'application/json');
    expect(encoding['items']!.wireContentType, 'application/json');
    expect(encoding['nested']!.wireContentType, 'application/json');
    expect(encoding['unknown']!.wireContentType, 'application/octet-stream');
    expect(encoding['encoded']!.wireContentType, 'application/octet-stream');
  });

  test('keeps existing binary and base64 array request models', () {
    final api = Importer().import(
      _document(
        paths: {
          '/existing': {
            'post': {
              'operationId': 'existing',
              'requestBody': {
                'content': {
                  'multipart/form-data': {
                    'schema': {
                      'type': 'object',
                      'properties': {
                        'files': {
                          'type': 'array',
                          'items': {'type': 'string', 'format': 'binary'},
                        },
                        'encoded': {
                          'type': 'array',
                          'items': {'type': 'string', 'format': 'byte'},
                        },
                      },
                    },
                    'encoding': {
                      'encoded': {'contentType': 'image/png'},
                    },
                  },
                },
              },
              'responses': _responses,
            },
          },
        },
      ),
    );

    final content = _multipart(api, 'existing');
    expect(identical(content.model, content.requestModel), isTrue);
  });

  test('does not default read-only allOf members or property models', () {
    final api = Importer().import(
      _document(
        paths: {
          '/read-only': {
            'post': {
              'operationId': 'readOnly',
              'requestBody': {
                'content': {
                  'multipart/form-data': {
                    'schema': {
                      'allOf': [
                        {
                          'type': 'object',
                          'readOnly': true,
                          'properties': {
                            'serverId': {'type': 'string'},
                          },
                        },
                        {
                          'type': 'object',
                          'properties': {
                            'name': {'type': 'string'},
                            'hidden': {'type': 'string', 'readOnly': true},
                          },
                        },
                      ],
                    },
                    'encoding': {
                      'serverId': {'contentType': 'text/plain'},
                      'hidden': {'contentType': 'text/plain'},
                    },
                  },
                },
              },
              'responses': _responses,
            },
          },
        },
      ),
    );

    final encoding = _multipart(api, 'readOnly').encoding;
    expect(encoding.keys, ['name']);
    expect(encoding['name']!.wireContentType, 'text/plain');
  });

  test('ignores unmatched encoding before importing its headers', () {
    final api = Importer().import(
      _document(
        paths: {
          '/unmatched': {
            'post': {
              'operationId': 'unmatched',
              'requestBody': {
                'content': {
                  'multipart/form-data': {
                    'schema': {
                      'type': 'object',
                      'properties': {
                        'name': {'type': 'string'},
                      },
                    },
                    'encoding': {
                      'ghost': {
                        'contentType': 'text/plain',
                        'headers': {
                          'X-Ghost': {r'$ref': '#/components/headers/Missing'},
                        },
                      },
                    },
                  },
                },
              },
              'responses': _responses,
            },
          },
        },
      ),
    );

    final encoding = _multipart(api, 'unmatched').encoding;
    expect(encoding.keys, ['name']);
    expect(encoding['name']!.wireContentType, 'text/plain');
  });

  test('ignores encoding keys on a dynamic map root', () {
    final api = Importer().import(
      _document(
        paths: {
          '/dynamic': {
            'post': {
              'operationId': 'dynamic',
              'requestBody': {
                'content': {
                  'multipart/form-data': {
                    'schema': {
                      'type': 'object',
                      'additionalProperties': {'type': 'string'},
                    },
                    'encoding': {
                      'ghost': {'contentType': 'text/plain'},
                    },
                  },
                },
              },
              'responses': _responses,
            },
          },
        },
      ),
    );

    final content = _multipart(api, 'dynamic');
    expect(content.model.resolved, isA<MapModel>());
    expect(content.encoding, isEmpty);
  });

  test('missing internal header reference on a named part still throws', () {
    expect(
      () => Importer().import(
        _document(
          headers: {'Broken': <String, dynamic>{}},
          paths: {
            '/used': {
              'post': {
                'operationId': 'used',
                'requestBody': {
                  'content': {
                    'multipart/form-data': {
                      'schema': {
                        'type': 'object',
                        'properties': {
                          'name': {'type': 'string'},
                        },
                      },
                      'encoding': {
                        'name': {
                          'headers': {
                            'X-Required': {
                              r'$ref': '#/components/headers/Missing',
                            },
                          },
                        },
                      },
                    },
                  },
                },
                'responses': _responses,
              },
            },
          },
        ),
      ),
      throwsArgumentError,
    );
  });

  test('omits unusable reusable and malformed part headers locally', () {
    final api = Importer().import(
      _document(
        headers: {
          'Empty': <String, dynamic>{},
          'FormStyle': {
            'schema': {'type': 'string'},
            'style': 'form',
          },
          'EmptyAlias': {r'$ref': '#/components/headers/Empty'},
          'BadContent': {
            'content': {'application/xml': 42},
          },
          'Good': {
            'schema': {'type': 'string'},
          },
        },
        paths: {
          '/upload': {
            'post': {
              'operationId': 'upload',
              'requestBody': {
                'content': {
                  'multipart/form-data': {
                    'schema': {
                      'type': 'object',
                      'properties': {
                        'payload': {'type': 'object'},
                        'label': {'type': 'string'},
                      },
                    },
                    'encoding': {
                      'payload': {
                        'contentType': 'application/xml',
                        'headers': {
                          'X-Empty': {r'$ref': '#/components/headers/Empty'},
                          'X-Form': {r'$ref': '#/components/headers/FormStyle'},
                          'X-Alias': {
                            r'$ref': '#/components/headers/EmptyAlias',
                          },
                          'X-Bad': 42,
                          'X-Bad-Content': {
                            r'$ref': '#/components/headers/BadContent',
                          },
                          'X-Empty-Content': {'content': <String, dynamic>{}},
                          'X-Good': {r'$ref': '#/components/headers/Good'},
                        },
                      },
                    },
                  },
                },
              },
              'responses': _responses,
            },
          },
        },
      ),
    );

    final content = _multipart(api, 'upload');
    final projected = content.requestModel.resolved as ClassModel;
    expect(projected.properties.first.model.resolved, isA<BinaryModel>());
    expect(content.encoding.keys, ['payload', 'label']);
    expect(content.encoding['payload']!.rawContentType, 'application/xml');
    expect(content.encoding['payload']!.headers!.keys, ['X-Good']);
    expect(content.encoding['label']!.contentType, ContentType.text);
  });

  test('keeps inline and reusable header schemas with unknown styles', () {
    final api = Importer().import(
      _document(
        headers: {
          'Reusable': {
            'description': 'Reusable identifier',
            'schema': {'type': 'integer'},
            'style': 'bogus',
          },
        },
        paths: {
          '/upload': {
            'post': {
              'operationId': 'upload',
              'requestBody': {
                'content': {
                  'multipart/form-data': {
                    'schema': {
                      'type': 'object',
                      'properties': {
                        'payload': {'type': 'object'},
                        'label': {'type': 'string'},
                      },
                    },
                    'encoding': {
                      'payload': {
                        'contentType': 'application/xml',
                        'headers': {
                          'X-Inline': {
                            'description': 'Inline name',
                            'required': true,
                            'schema': {'type': 'string'},
                            'style': 'bogus',
                          },
                          'X-Reusable': {
                            r'$ref': '#/components/headers/Reusable',
                          },
                        },
                      },
                    },
                  },
                },
              },
              'responses': _responses,
            },
          },
        },
      ),
    );

    final content = _multipart(api, 'upload');
    final headers = content.encoding['payload']!.headers!;
    final inline = headers['X-Inline']!.resolve();
    final reusable = headers['X-Reusable']!.resolve();

    expect(content.requestModel.resolved, isA<ClassModel>());
    expect(content.encoding['payload']!.rawContentType, 'application/xml');
    expect(content.encoding['label']!.contentType, ContentType.text);
    expect(headers.keys, ['X-Inline', 'X-Reusable']);
    expect(inline.description, 'Inline name');
    expect(inline.isRequired, isTrue);
    expect(inline.model, isA<StringModel>());
    expect(reusable.description, 'Reusable identifier');
    expect(reusable.model, isA<IntegerModel>());
  });

  test('keeps XML encoding when optional flags are malformed', () {
    final api = Importer().import(
      _document(
        headers: {
          'Trace': {
            'schema': {'type': 'string'},
          },
        },
        paths: {
          '/upload': {
            'post': {
              'operationId': 'upload',
              'requestBody': {
                'content': {
                  'multipart/form-data': {
                    'schema': {
                      'type': 'object',
                      'properties': {
                        'payload': {'type': 'object'},
                        'label': {'type': 'string'},
                      },
                    },
                    'encoding': {
                      'payload': {
                        'contentType': 'application/xml',
                        'style': 'bogus',
                        'explode': 'bad',
                        'allowReserved': 42,
                        'headers': {
                          'X-Trace': {r'$ref': '#/components/headers/Trace'},
                        },
                      },
                    },
                  },
                },
              },
              'responses': _responses,
            },
          },
        },
      ),
    );

    final content = _multipart(api, 'upload');
    final projected = content.requestModel.resolved as ClassModel;

    expect(projected.properties.first.model.resolved, isA<BinaryModel>());
    expect(content.encoding['payload']!.rawContentType, 'application/xml');
    expect(content.encoding['payload']!.contentType, ContentType.bytes);
    expect(content.encoding['payload']!.headers!.keys, ['X-Trace']);
    expect(content.encoding['label']!.contentType, ContentType.text);
  });

  test('omits external reusable part headers and their local aliases', () {
    final api = Importer().import(
      _document(
        headers: {
          'Bad': 42,
          'External': {r'$ref': 'headers.yaml#/components/headers/Trace'},
          'ExternalAlias': {r'$ref': '#/components/headers/External'},
          'Good': {
            'schema': {'type': 'string'},
          },
        },
        paths: {
          '/upload': {
            'post': {
              'operationId': 'upload',
              'requestBody': {
                'content': {
                  'multipart/form-data': {
                    'schema': {
                      'type': 'object',
                      'properties': {
                        'payload': {'type': 'object'},
                        'label': {'type': 'string'},
                      },
                    },
                    'encoding': {
                      'payload': {
                        'contentType': 'application/xml',
                        'headers': {
                          'X-Bad': {r'$ref': '#/components/headers/Bad'},
                          'X-External': {
                            r'$ref': '#/components/headers/External',
                          },
                          'X-Alias': {
                            r'$ref': '#/components/headers/ExternalAlias',
                          },
                          'X-Good': {r'$ref': '#/components/headers/Good'},
                        },
                      },
                    },
                  },
                },
              },
              'responses': _responses,
            },
          },
        },
      ),
    );

    final content = _multipart(api, 'upload');
    final projected = content.requestModel.resolved as ClassModel;
    expect(projected.properties.first.model.resolved, isA<BinaryModel>());
    expect(content.encoding.keys, ['payload', 'label']);
    expect(content.encoding['payload']!.rawContentType, 'application/xml');
    expect(content.encoding['payload']!.headers!.keys, ['X-Good']);
    expect(content.encoding['label']!.contentType, ContentType.text);
  });

  test('malformed reusable header references still throw', () {
    expect(
      () => Importer().import(
        _document(
          headers: {
            'Broken': {r'$ref': 42},
          },
        ),
      ),
      throwsA(isA<TypeError>()),
    );
  });

  test('omits unusable inline part headers and keeps usable parts', () {
    final api = Importer().import(
      _document(
        paths: {
          '/upload': {
            'post': {
              'operationId': 'upload',
              'requestBody': {
                'content': {
                  'multipart/form-data': {
                    'schema': {
                      'type': 'object',
                      'properties': {
                        'payload': {'type': 'object'},
                        'label': {'type': 'string'},
                      },
                    },
                    'encoding': {
                      'payload': {
                        'contentType': 'application/xml',
                        'headers': {
                          'X-Unusable': <String, dynamic>{},
                          'X-UnsupportedStyle': {
                            'schema': {'type': 'string'},
                            'style': 'form',
                          },
                          'X-Usable': {
                            'schema': {'type': 'string'},
                          },
                        },
                      },
                    },
                  },
                },
              },
              'responses': _responses,
            },
          },
        },
      ),
    );

    final content = _multipart(api, 'upload');
    final projected = content.requestModel.resolved as ClassModel;
    expect(projected.properties.first.model.resolved, isA<BinaryModel>());
    expect(content.encoding.keys, ['payload', 'label']);
    expect(content.encoding['payload']!.headers!.keys, ['X-Usable']);
    expect(content.encoding['label']!.contentType, ContentType.text);
  });

  test('omits an external part header reference and keeps usable parts', () {
    final api = Importer().import(
      _document(
        paths: {
          '/upload': {
            'post': {
              'operationId': 'upload',
              'requestBody': {
                'content': {
                  'multipart/form-data': {
                    'schema': {
                      'type': 'object',
                      'properties': {
                        'payload': {'type': 'object'},
                        'label': {'type': 'string'},
                      },
                    },
                    'encoding': {
                      'payload': {
                        'contentType': 'application/xml',
                        'headers': {
                          'X-External': {
                            r'$ref': 'headers.yaml#/components/headers/Id',
                          },
                          'X-Usable': {
                            'schema': {'type': 'string'},
                          },
                        },
                      },
                    },
                  },
                },
              },
              'responses': _responses,
            },
          },
        },
      ),
    );

    final content = _multipart(api, 'upload');
    final projected = content.requestModel.resolved as ClassModel;
    expect(projected.properties.first.model.resolved, isA<BinaryModel>());
    expect(content.encoding.keys, ['payload', 'label']);
    expect(content.encoding['payload']!.headers!.keys, ['X-Usable']);
    expect(content.encoding['label']!.contentType, ContentType.text);
  });

  test('malformed part header references still throw', () {
    expect(
      () => Importer().import(
        _document(
          paths: {
            '/upload': {
              'post': {
                'operationId': 'upload',
                'requestBody': {
                  'content': {
                    'multipart/form-data': {
                      'schema': {
                        'type': 'object',
                        'properties': {
                          'payload': {'type': 'object'},
                        },
                      },
                      'encoding': {
                        'payload': {
                          'contentType': 'application/xml',
                          'headers': {
                            'X-Broken': {r'$ref': 42},
                          },
                        },
                      },
                    },
                  },
                },
                'responses': _responses,
              },
            },
          },
        ),
      ),
      throwsA(isA<TypeError>()),
    );
  });

  test('reuses schema models across JSON, multipart, and responses', () {
    final api = Importer().import(
      _document(
        schemas: _sharedSchemas,
        paths: {
          '/multipart': {
            'post': {
              'operationId': 'multipart',
              'requestBody': {
                'content': {
                  'multipart/form-data': {
                    'schema': {r'$ref': '#/components/schemas/Shared'},
                  },
                },
              },
              'responses': _responses,
            },
          },
          '/json': {
            'post': {
              'operationId': 'json',
              'requestBody': {
                'content': {
                  'application/json': {
                    'schema': {r'$ref': '#/components/schemas/Shared'},
                  },
                },
              },
              'responses': {
                '200': {
                  'description': 'ok',
                  'content': {
                    'application/json': {
                      'schema': {r'$ref': '#/components/schemas/Shared'},
                    },
                  },
                },
              },
            },
          },
        },
      ),
    );

    final multipart = _multipart(api, 'multipart');
    final json = _modelContent(api, 'json');
    final responseModel = api.operations
        .singleWhere((operation) => operation.operationId == 'json')
        .responses
        .values
        .single
        .resolved
        .bodies
        .single
        .model;
    expect(multipart.model, same(json.model));
    expect(responseModel, same(json.model));
    expect(json.model, same(api.models.singleWhere(_named('Shared'))));
  });

  test('document includes multipart alias and nested class projections', () {
    final api = Importer().import(
      _document(
        schemas: {
          'Payload': {
            'type': 'object',
            'properties': {
              'payload': {'type': 'object'},
            },
          },
          'UploadAlias': {r'$ref': '#/components/schemas/Payload'},
        },
        paths: {
          '/upload': {
            'post': {
              'operationId': 'upload',
              'requestBody': {
                'content': {
                  'multipart/form-data': {
                    'schema': {r'$ref': '#/components/schemas/UploadAlias'},
                    'encoding': {
                      'payload': {'contentType': 'application/xml'},
                    },
                  },
                },
              },
              'responses': _responses,
            },
          },
        },
      ),
    );

    final content = _multipart(api, 'upload');
    final alias = content.requestModel as AliasModel;
    final projected = alias.model as ClassModel;
    expect(alias.name, 'UploadAliasMultipart');
    expect(projected.name, 'PayloadMultipart');
    expect(projected.properties.single.model.resolved, isA<BinaryModel>());
    expect(api.models, contains(content.model));
    expect(api.models, contains(alias));
    expect(api.models, contains(projected));
  });

  test('keeps encoding settings on each multipart use', () {
    final api = Importer().import(
      _document(
        schemas: _sharedSchemas,
        paths: {
          '/plain': {
            'post': {
              'operationId': 'plain',
              'requestBody': {
                'content': {
                  'multipart/form-data': {
                    'schema': {r'$ref': '#/components/schemas/Shared'},
                    'encoding': {
                      'label': {'contentType': 'text/plain; charset=us-ascii'},
                    },
                  },
                },
              },
              'responses': _responses,
            },
          },
          '/json': {
            'post': {
              'operationId': 'json',
              'requestBody': {
                'content': {
                  'multipart/form-data': {
                    'schema': {r'$ref': '#/components/schemas/Shared'},
                    'encoding': {
                      'label': {'contentType': 'application/json'},
                    },
                  },
                },
              },
              'responses': _responses,
            },
          },
        },
      ),
    );

    final plain = _multipart(api, 'plain');
    final json = _multipart(api, 'json');
    expect(plain.model, same(json.model));
    expect(plain.encoding.keys.toSet(), {'file', 'label'});
    expect(plain.encoding['label']!.contentType, ContentType.text);
    expect(plain.encoding['label']!.textEncoding, TextEncoding.ascii);
    expect(json.encoding.keys.toSet(), {'file', 'label'});
    expect(json.encoding['label']!.contentType, ContentType.json);
  });

  test('reuses referenced request bodies and resolves aliases and defs', () {
    final api = Importer().import(
      _document(
        schemas: {
          ..._sharedSchemas,
          'SharedAlias': {r'$ref': '#/components/schemas/Shared'},
          'WithDefs': {
            'type': 'object',
            r'$defs': {
              'Local': {
                'type': 'object',
                'properties': {
                  'value': {'type': 'string'},
                },
              },
            },
            'properties': {
              'local': {r'$ref': r'#/components/schemas/WithDefs/$defs/Local'},
            },
          },
        },
        requestBodies: {
          'Upload': {
            'content': {
              'multipart/form-data': {
                'schema': {r'$ref': '#/components/schemas/SharedAlias'},
                'encoding': {
                  'label': {'contentType': 'text/plain'},
                },
              },
            },
          },
        },
        paths: {
          '/one': _requestBodyRefPath('one'),
          '/two': _requestBodyRefPath('two'),
          '/defs': {
            'post': {
              'operationId': 'defs',
              'requestBody': {
                'content': {
                  'multipart/form-data': {
                    'schema': {r'$ref': '#/components/schemas/WithDefs'},
                  },
                },
              },
              'responses': _responses,
            },
          },
        },
      ),
    );

    final one = _multipart(api, 'one');
    final two = _multipart(api, 'two');
    expect(one, same(two));
    expect(one.model, isA<AliasModel>());
    expect((one.model as AliasModel).name, 'SharedAlias');
    expect(one.encoding.keys.toSet(), {'file', 'label'});

    final defs = _multipart(api, 'defs').model as ClassModel;
    final local = defs.properties.single.model.resolved as ClassModel;
    expect(local.properties.single.name, 'value');
  });

  test('preserves compound member declaration order and duplicates', () {
    final api = Importer().import(
      _document(
        schemas: {
          'A': {'type': 'string'},
          'B': {'type': 'integer'},
          'All': {
            'allOf': [
              {r'$ref': '#/components/schemas/A'},
              {r'$ref': '#/components/schemas/B'},
              {r'$ref': '#/components/schemas/A'},
            ],
          },
          'One': {
            'oneOf': [
              {r'$ref': '#/components/schemas/B'},
              {r'$ref': '#/components/schemas/A'},
              {r'$ref': '#/components/schemas/B'},
            ],
          },
          'Any': {
            'anyOf': [
              {r'$ref': '#/components/schemas/A'},
              {r'$ref': '#/components/schemas/B'},
              {r'$ref': '#/components/schemas/A'},
            ],
          },
        },
      ),
    );

    final all = api.models.singleWhere(_named('All')) as AllOfModel;
    final one = api.models.singleWhere(_named('One')) as OneOfModel;
    final any = api.models.singleWhere(_named('Any')) as AnyOfModel;
    expect(all.models.map(_modelName), ['A', 'B', 'A']);
    expect(one.models.map((member) => _modelName(member.model)), [
      'B',
      'A',
      'B',
    ]);
    expect(any.models.map((member) => _modelName(member.model)), [
      'A',
      'B',
      'A',
    ]);
    expect(all.models.first, same(all.models.last));
  });

  test('projects opaque input without changing a shared JSON schema', () {
    final api = Importer().import(
      _document(
        schemas: {
          'Shared': {
            'type': 'object',
            'required': ['payload'],
            'additionalProperties': {'type': 'string'},
            'properties': {
              'payload': {
                'type': 'object',
                'properties': {
                  'value': {'type': 'string'},
                },
              },
              'internal': {'type': 'string', 'readOnly': true},
            },
          },
        },
        paths: {
          '/upload': {
            'post': {
              'operationId': 'upload',
              'requestBody': {
                'content': {
                  'multipart/form-data': {
                    'schema': {r'$ref': '#/components/schemas/Shared'},
                    'encoding': {
                      'payload': {'contentType': 'application/xml; profile=v1'},
                    },
                  },
                },
              },
              'responses': _responses,
            },
          },
          '/json': {
            'post': {
              'operationId': 'json',
              'requestBody': {
                'content': {
                  'application/json': {
                    'schema': {r'$ref': '#/components/schemas/Shared'},
                  },
                },
              },
              'responses': _responses,
            },
          },
        },
      ),
    );

    final upload = _multipart(api, 'upload');
    final shared = _modelContent(api, 'json').model.resolved as ClassModel;
    final projection = upload.requestModel.resolved as ClassModel;
    final source = shared.properties.first;
    final input = projection.properties.first;
    expect(upload.model.resolved, same(shared));
    expect(projection, isNot(same(shared)));
    expect(source.model.resolved, isA<ClassModel>());
    expect(input.model.resolved, isA<BinaryModel>());
    expect(upload.requestSources[input], same(source));
    expect(
      upload.requestSources[projection.properties.last],
      same(shared.properties.last),
    );
    expect(
      projection.additionalPropertiesPolicy,
      same(shared.additionalPropertiesPolicy),
    );
    expect(projection.properties.last.isReadOnly, isTrue);
    expect(api.models, contains(projection));
  });

  test('configured bytes content type projects a JSON suffix part', () {
    final api =
        Importer(
          contentTypes: {'application/vnd.opaque+json': ContentType.bytes},
        ).import(
          _document(
            paths: {
              '/upload': {
                'post': {
                  'operationId': 'upload',
                  'requestBody': {
                    'content': {
                      'multipart/form-data': {
                        'schema': {
                          'type': 'object',
                          'properties': {
                            'payload': {'type': 'object'},
                          },
                        },
                        'encoding': {
                          'payload': {
                            'contentType':
                                'application/vnd.opaque+json; version=1',
                          },
                        },
                      },
                    },
                  },
                  'responses': _responses,
                },
              },
            },
          ),
        );

    final content = _multipart(api, 'upload');
    final projected = content.requestModel.resolved as ClassModel;
    expect(projected.properties.single.model.resolved, isA<BinaryModel>());
    expect(
      content.encoding['payload']!.wireContentType,
      'application/vnd.opaque+json; version=1',
    );
  });

  test('opaque part keeps an unsupported declared charset', () {
    final api = Importer().import(
      _document(
        paths: {
          '/upload': {
            'post': {
              'operationId': 'upload',
              'requestBody': {
                'content': {
                  'multipart/form-data': {
                    'schema': {
                      'type': 'object',
                      'properties': {
                        'payload': {'type': 'object'},
                      },
                    },
                    'encoding': {
                      'payload': {
                        'contentType':
                            'application/xml; charset=shift_jis; profile=v1',
                      },
                    },
                  },
                },
              },
              'responses': _responses,
            },
          },
        },
      ),
    );

    final content = _multipart(api, 'upload');
    expect(content.encoding['payload']!.contentType, ContentType.bytes);
    expect(
      content.encoding['payload']!.wireContentType,
      'application/xml; charset=shift_jis; profile=v1',
    );
  });

  test('projects explicit untyped extra values for multipart only', () {
    final api = Importer().import(
      _document(
        schemas: {
          'Shared': {
            'type': 'object',
            'additionalProperties': <String, dynamic>{},
            'properties': {
              'payload': {'type': 'object'},
            },
          },
        },
        paths: {
          '/upload': {
            'post': {
              'operationId': 'upload',
              'requestBody': {
                'content': {
                  'multipart/form-data': {
                    'schema': {r'$ref': '#/components/schemas/Shared'},
                    'encoding': {
                      'payload': {'contentType': 'application/xml'},
                    },
                  },
                },
              },
              'responses': _responses,
            },
          },
          '/json': {
            'post': {
              'operationId': 'json',
              'requestBody': {
                'content': {
                  'application/json': {
                    'schema': {r'$ref': '#/components/schemas/Shared'},
                  },
                },
              },
              'responses': _responses,
            },
          },
        },
      ),
    );

    final upload = _multipart(api, 'upload');
    final shared = _modelContent(api, 'json').model.resolved as ClassModel;
    final projection = upload.requestModel.resolved as ClassModel;
    final sourcePolicy =
        shared.additionalPropertiesPolicy as AllowedAdditionalProperties;
    final requestPolicy =
        projection.additionalPropertiesPolicy as AllowedAdditionalProperties;
    expect(upload.model.resolved, same(shared));
    expect(sourcePolicy.valueModel.resolved, isA<AnyModel>());
    expect(requestPolicy.valueModel.resolved, isA<BinaryModel>());
    expect(requestPolicy.origin, AdditionalPropertiesOrigin.explicit);
    expect(
      upload.requestSources[projection.properties.single],
      same(shared.properties.single),
    );
  });

  test('projects an untyped root map without changing shared JSON use', () {
    final api = Importer().import(
      _document(
        schemas: {
          'Root': {
            'type': 'object',
            'additionalProperties': <String, dynamic>{},
          },
        },
        paths: {
          '/upload': {
            'post': {
              'operationId': 'upload',
              'requestBody': {
                'content': {
                  'multipart/form-data': {
                    'schema': {r'$ref': '#/components/schemas/Root'},
                  },
                },
              },
              'responses': _responses,
            },
          },
          '/json': {
            'post': {
              'operationId': 'json',
              'requestBody': {
                'content': {
                  'application/json': {
                    'schema': {r'$ref': '#/components/schemas/Root'},
                  },
                },
              },
              'responses': _responses,
            },
          },
        },
      ),
    );

    final upload = _multipart(api, 'upload');
    final shared = _modelContent(api, 'json').model.resolved as MapModel;
    final projection = upload.requestModel.resolved as MapModel;
    expect(upload.model.resolved, same(shared));
    expect(projection, isNot(same(shared)));
    expect(shared.valueModel.resolved, isA<AnyModel>());
    expect(projection.valueModel.resolved, isA<BinaryModel>());
    expect(api.models, contains(projection));
  });

  test('projects untyped extra arrays on a named multipart body', () {
    final api = Importer().import(
      _document(
        schemas: {
          'Shared': {
            'type': 'object',
            'additionalProperties': {
              'type': 'array',
              'items': <String, dynamic>{},
            },
            'properties': {
              'payload': {'type': 'object'},
            },
          },
        },
        paths: {
          '/upload': {
            'post': {
              'operationId': 'upload',
              'requestBody': {
                'content': {
                  'multipart/form-data': {
                    'schema': {r'$ref': '#/components/schemas/Shared'},
                    'encoding': {
                      'payload': {'contentType': 'application/xml'},
                    },
                  },
                },
              },
              'responses': _responses,
            },
          },
          '/json': {
            'post': {
              'operationId': 'json',
              'requestBody': {
                'content': {
                  'application/json': {
                    'schema': {r'$ref': '#/components/schemas/Shared'},
                  },
                },
              },
              'responses': _responses,
            },
          },
        },
      ),
    );

    final shared = _modelContent(api, 'json').model.resolved as ClassModel;
    final projected =
        _multipart(api, 'upload').requestModel.resolved as ClassModel;
    final sourcePolicy =
        shared.additionalPropertiesPolicy as AllowedAdditionalProperties;
    final requestPolicy =
        projected.additionalPropertiesPolicy as AllowedAdditionalProperties;
    expect(
      (sourcePolicy.valueModel.resolved as ListModel).content.resolved,
      isA<AnyModel>(),
    );
    expect(
      (requestPolicy.valueModel.resolved as ListModel).content.resolved,
      isA<BinaryModel>(),
    );
    expect(projected.properties.single.model.resolved, isA<BinaryModel>());
  });

  test('projects untyped extra arrays on a root multipart map', () {
    final api = Importer().import(
      _document(
        schemas: {
          'Shared': {
            'type': 'object',
            'additionalProperties': {
              'type': 'array',
              'items': <String, dynamic>{},
            },
          },
        },
        paths: {
          '/upload': {
            'post': {
              'operationId': 'upload',
              'requestBody': {
                'content': {
                  'multipart/form-data': {
                    'schema': {r'$ref': '#/components/schemas/Shared'},
                  },
                },
              },
              'responses': _responses,
            },
          },
          '/json': {
            'post': {
              'operationId': 'json',
              'requestBody': {
                'content': {
                  'application/json': {
                    'schema': {r'$ref': '#/components/schemas/Shared'},
                  },
                },
              },
              'responses': _responses,
            },
          },
        },
      ),
    );

    final shared = _modelContent(api, 'json').model.resolved as MapModel;
    final projected =
        _multipart(api, 'upload').requestModel.resolved as MapModel;
    expect(
      (shared.valueModel.resolved as ListModel).content.resolved,
      isA<AnyModel>(),
    );
    expect(
      (projected.valueModel.resolved as ListModel).content.resolved,
      isA<BinaryModel>(),
    );
  });

  test('allOf projection retains member paths and source identities', () {
    final api = Importer().import(
      _document(
        schemas: {
          'Upload': {
            'allOf': [
              {r'$ref': '#/components/schemas/Payload'},
              {r'$ref': '#/components/schemas/Note'},
            ],
          },
          'Payload': {
            'type': 'object',
            'properties': {
              'payload': {'type': 'object'},
            },
          },
          'Note': {
            'type': 'object',
            'properties': {
              'note': {'type': 'string'},
            },
          },
        },
        paths: {
          '/upload': {
            'post': {
              'operationId': 'upload',
              'requestBody': {
                'content': {
                  'multipart/form-data': {
                    'schema': {r'$ref': '#/components/schemas/Upload'},
                    'encoding': {
                      'payload': {'contentType': 'application/xml'},
                    },
                  },
                },
              },
              'responses': _responses,
            },
          },
        },
      ),
    );
    const AllOfNormalizer(normalizeSingleMembers: true).apply(api);

    final content = _multipart(api, 'upload');
    final shared = content.model.resolved as AllOfModel;
    final projection = content.requestModel.resolved as AllOfModel;
    final source =
        (shared.models.first.resolved as ClassModel).properties.single;
    final input =
        (projection.models.first.resolved as ClassModel).properties.single;
    expect(projection.models, hasLength(2));
    expect(projection.models.last, same(shared.models.last));
    expect(input.model.resolved, isA<BinaryModel>());
    expect(source.model.resolved, isA<MapModel>());
    expect(content.requestSources[input], same(source));
    expect(api.models, contains(projection));
  });

  test('missing internal part schema reference still throws', () {
    expect(
      () => Importer().import(
        _document(
          paths: {
            '/upload': {
              'post': {
                'operationId': 'upload',
                'requestBody': {
                  'content': {
                    'multipart/form-data': {
                      'schema': {
                        'type': 'object',
                        'properties': {
                          'payload': {r'$ref': '#/components/schemas/Missing'},
                        },
                      },
                      'encoding': {
                        'payload': {'contentType': 'application/xml'},
                      },
                    },
                  },
                },
                'responses': _responses,
              },
            },
          },
        ),
      ),
      throwsArgumentError,
    );
  });
}

const _responses = <String, dynamic>{
  '204': {'description': 'ok'},
};

const _sharedSchemas = <String, dynamic>{
  'Shared': {
    'type': 'object',
    'properties': {
      'file': {'type': 'string', 'format': 'binary'},
      'label': {'type': 'string'},
    },
  },
};

Map<String, dynamic> _document({
  Map<String, dynamic> schemas = const {},
  Map<String, dynamic> requestBodies = const {},
  Map<String, dynamic> headers = const {},
  Map<String, dynamic> paths = const {},
}) => {
  'openapi': '3.1.0',
  'info': {'title': 'Multipart models', 'version': '1.0.0'},
  'paths': paths,
  'components': {
    'schemas': schemas,
    'requestBodies': requestBodies,
    'headers': headers,
  },
};

Map<String, dynamic> _requestBodyRefPath(String operationId) => {
  'post': {
    'operationId': operationId,
    'requestBody': {r'$ref': '#/components/requestBodies/Upload'},
    'responses': _responses,
  },
};

MultipartRequestContent _multipart(ApiDocument api, String operationId) =>
    api.operations
            .singleWhere((operation) => operation.operationId == operationId)
            .requestBody!
            .resolvedContent
            .single
        as MultipartRequestContent;

ModelRequestContent _modelContent(ApiDocument api, String operationId) =>
    api.operations
            .singleWhere((operation) => operation.operationId == operationId)
            .requestBody!
            .resolvedContent
            .single
        as ModelRequestContent;

bool Function(Model) _named(String name) =>
    (model) => model is NamedModel && model.name == name;

String? _modelName(Model model) => model is NamedModel ? model.name : null;
