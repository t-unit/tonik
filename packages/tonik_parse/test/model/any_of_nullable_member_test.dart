import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  test('inline anyOf inherits nullability from an unconstrained member', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'Profile': {
            'type': 'object',
            'required': ['value'],
            'properties': {
              'value': {
                'anyOf': [
                  true,
                  {'type': 'integer'},
                ],
              },
            },
          },
        },
      },
    });

    final profile = api.models.whereType<ClassModel>().single;
    final property = profile.properties.single;
    final model = property.model as AnyOfModel;
    expect(property.isRequired, isTrue);
    expect(model.isNullable, isTrue);
    expect(model.models, hasLength(2));
  });

  test('named anyOf inherits nullability through an unconstrained alias', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'Value': {
            'anyOf': [
              {r'$ref': '#/components/schemas/Anything'},
              {'type': 'integer'},
            ],
          },
          'Anything': {r'$ref': '#/components/schemas/Unconstrained'},
          'Unconstrained': true,
        },
      },
    });

    final model = api.models.whereType<AnyOfModel>().single;
    expect(model.isNullable, isTrue);
    expect(model.models, hasLength(2));
  });

  test('a forward alias to a string does not make anyOf nullable', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'Value': {
            'anyOf': [
              {r'$ref': '#/components/schemas/TextAlias'},
              {'type': 'integer'},
            ],
          },
          'TextAlias': {r'$ref': '#/components/schemas/Text'},
          'Text': {'type': 'string'},
        },
      },
    });

    final model = api.models.whereType<AnyOfModel>().single;
    expect(model.isNullable, isFalse);
    expect(model.models.first.model.resolved, isA<StringModel>());
  });

  test('a recursive definition alias does not make anyOf nullable', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'Namespace': {
            r'$defs': {
              'Alias': {r'$ref': r'#/components/schemas/Namespace/$defs/Node'},
              'Node': {
                'type': 'object',
                'required': ['value'],
                'properties': {
                  'value': {
                    'anyOf': [
                      {r'$ref': r'#/components/schemas/Namespace/$defs/Alias'},
                      {'type': 'integer'},
                    ],
                  },
                },
              },
            },
          },
          'Root': {r'$ref': r'#/components/schemas/Namespace/$defs/Alias'},
        },
      },
    });

    final root = api.models.whereType<AliasModel>().firstWhere(
      (model) => model.name == 'Root',
    );
    final node = root.resolved as ClassModel;
    final value = node.properties.single.model as AnyOfModel;
    expect(value.isNullable, isFalse);
    expect(value.models.first.model.resolved, same(node));
  });

  test('response anyOf inherits nullability after recursive refs resolve', () {
    final api = Importer().import({
      'openapi': '3.2.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': {
        '/nodes': {
          'get': {
            'responses': {
              '200': {
                'description': 'Nodes',
                'content': {
                  'application/x-ndjson': {
                    'itemSchema': {
                      r'$ref': r'#/components/schemas/Namespace/$defs/OpenNode',
                    },
                  },
                },
              },
            },
          },
        },
        '/values': {
          'get': {
            'responses': {
              '200': {
                'description': 'Values',
                'content': {
                  'application/x-ndjson': {
                    'itemSchema': {
                      r'$ref':
                          r'#/components/schemas/Namespace/$defs/NodeValue',
                    },
                  },
                },
              },
            },
          },
        },
      },
      'components': {
        'schemas': {
          'Namespace': {
            r'$defs': {
              'NodeAlias': {
                r'$ref': r'#/components/schemas/Namespace/$defs/OpenNode',
              },
              'OpenNode': {
                'anyOf': [
                  {
                    'type': 'object',
                    'properties': {
                      'value': {
                        r'$ref':
                            r'#/components/schemas/Namespace/$defs/NodeValue',
                      },
                    },
                  },
                  true,
                ],
              },
              'NodeValue': {
                'anyOf': [
                  {r'$ref': r'#/components/schemas/Namespace/$defs/NodeAlias'},
                  {'type': 'integer'},
                ],
              },
            },
          },
        },
      },
    });

    final node = api.models.whereType<AnyOfModel>().singleWhere(
      (model) => model.name == 'OpenNode',
    );
    final value = api.models.whereType<AnyOfModel>().singleWhere(
      (model) => model.name == 'NodeValue',
    );
    expect(node.isNullable, isTrue);
    expect(value.isNullable, isTrue);
    expect(value.models.first.model.resolved, same(node));
  });

  test('inline anyOf inherits nullability from a type array member', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'Profile': {
            'type': 'object',
            'required': ['externalId'],
            'properties': {
              'externalId': {
                'anyOf': [
                  {
                    'type': ['string', 'null'],
                  },
                  {'type': 'integer'},
                ],
              },
            },
          },
        },
      },
    });

    final profile = api.models.whereType<ClassModel>().single;
    final property = profile.properties.single;
    final model = property.model as AnyOfModel;
    expect(property.isRequired, isTrue);
    expect(model.isNullable, isTrue);
    expect(model.models, hasLength(2));
  });

  test('named anyOf inherits nullability through a referenced union', () {
    final api = Importer().import({
      'openapi': '3.0.3',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'Identifier': {
            'anyOf': [
              {r'$ref': '#/components/schemas/TextOrInteger'},
              {'type': 'boolean'},
            ],
          },
          'TextOrInteger': {
            'anyOf': [
              {r'$ref': '#/components/schemas/NullableText'},
              {'type': 'integer'},
            ],
          },
          'NullableText': {'type': 'string', 'nullable': true},
          'Nonnullable': {
            'anyOf': [
              {'type': 'string'},
              {'type': 'integer'},
            ],
          },
        },
      },
    });

    final identifier = api.models.whereType<AnyOfModel>().singleWhere(
      (model) => model.name == 'Identifier',
    );
    final textOrInteger = api.models.whereType<AnyOfModel>().singleWhere(
      (model) => model.name == 'TextOrInteger',
    );
    final nonnullable = api.models.whereType<AnyOfModel>().singleWhere(
      (model) => model.name == 'Nonnullable',
    );
    expect(identifier.isNullable, isTrue);
    expect(textOrInteger.isNullable, isTrue);
    expect(nonnullable.isNullable, isFalse);
  });
}
