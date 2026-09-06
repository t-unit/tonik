import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
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
    expect(content.encoding, isEmpty);
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

  test('keeps encoding settings on each multipart use', () {
    final api = Importer().import(
      _document(
        schemas: _sharedSchemas,
        paths: {
          for (final entry in {
            '/plain': 'text/plain; charset=us-ascii',
            '/json': 'application/json',
          }.entries)
            entry.key: {
              'post': {
                'operationId': entry.key.substring(1),
                'requestBody': {
                  'content': {
                    'multipart/form-data': {
                      'schema': {r'$ref': '#/components/schemas/Shared'},
                      'encoding': {
                        'label': {'contentType': entry.value},
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
    expect(plain.encoding.keys, ['label']);
    expect(plain.encoding['label']!.contentType, ContentType.text);
    expect(plain.encoding['label']!.textEncoding, TextEncoding.ascii);
    expect(json.encoding.keys, ['label']);
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
    expect(one.encoding.keys, ['label']);

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
  Map<String, dynamic> paths = const {},
}) => {
  'openapi': '3.1.0',
  'info': {'title': 'Multipart models', 'version': '1.0.0'},
  'paths': paths,
  'components': {'schemas': schemas, 'requestBodies': requestBodies},
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
