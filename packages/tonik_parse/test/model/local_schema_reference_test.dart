import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  test('resolves a deep property despite a same-named component', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'id': {'type': 'string'},
          'Pet': {
            'type': 'object',
            'properties': {
              'id': {'type': 'integer'},
            },
          },
          'PetId': {r'$ref': '#/components/schemas/Pet/properties/id'},
        },
      },
    });

    final petId = api.models.whereType<AliasModel>().singleWhere(
      (model) => model.name == 'PetId',
    );
    expect(petId.resolved, isA<IntegerModel>());
  });

  test('resolves a deep property without a same-named component', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'Pet': {
            'type': 'object',
            'properties': {
              'id': {'type': 'integer'},
            },
          },
          'PetId': {r'$ref': '#/components/schemas/Pet/properties/id'},
        },
      },
    });

    final petId = api.models.whereType<AliasModel>().singleWhere(
      (model) => model.name == 'PetId',
    );
    expect(petId.name, 'PetId');
    expect(petId.resolved, isA<IntegerModel>());
  });

  test(
    'reuses a deep object and its recursive references across URI aliases',
    () {
      final api = Importer().import({
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Container': {
              'type': 'object',
              'properties': {
                'node': {
                  'type': 'object',
                  'properties': {
                    'next': {
                      r'$ref':
                          '#%2Fcomponents%2Fschemas%2FContainer'
                          '%2Fproperties%2Fnode',
                    },
                  },
                },
              },
            },
            'First': {
              r'$ref': '#/components/schemas/Container/properties/node',
            },
            'Second': {
              r'$ref':
                  '#%2Fcomponents%2Fschemas%2FContainer%2Fproperties%2Fnode',
            },
          },
        },
      });

      final container = api.models.whereType<ClassModel>().singleWhere(
        (model) => model.name == 'Container',
      );
      final node = container.properties.single.model as ClassModel;
      final first = api.models.whereType<AliasModel>().singleWhere(
        (model) => model.name == 'First',
      );
      final second = api.models.whereType<AliasModel>().singleWhere(
        (model) => model.name == 'Second',
      );
      expect(first.resolved, same(node));
      expect(second.resolved, same(node));
      expect(node.properties.single.model.resolved, same(node));
    },
  );

  test(
    'decodes slash, tilde and empty property names without losing tokens',
    () {
      final api = Importer().import({
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Container': {
              'type': 'object',
              'properties': {
                'a/b': {'type': 'integer'},
                '~1': {'type': 'boolean'},
                '': {'type': 'string'},
              },
            },
            'Slash': {
              r'$ref':
                  '#%2Fcomponents%2Fschemas%2FContainer%2Fproperties%2Fa~1b',
            },
            'Tilde': {r'$ref': '#/components/schemas/Container/properties/~01'},
            'Empty': {r'$ref': '#/components/schemas/Container/properties/'},
          },
        },
      });

      final slash = api.models.whereType<AliasModel>().singleWhere(
        (model) => model.name == 'Slash',
      );
      final tilde = api.models.whereType<AliasModel>().singleWhere(
        (model) => model.name == 'Tilde',
      );
      final empty = api.models.whereType<AliasModel>().singleWhere(
        (model) => model.name == 'Empty',
      );
      expect(slash.resolved, isA<IntegerModel>());
      expect(tilde.resolved, isA<BooleanModel>());
      expect(empty.resolved, isA<StringModel>());
    },
  );

  test('resolves schema pointers through composition array indices', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'Choice': {
            'oneOf': [
              {'type': 'string'},
              {'type': 'integer'},
            ],
          },
          'IntegerChoice': {r'$ref': '#/components/schemas/Choice/oneOf/1'},
        },
      },
    });

    final integer = api.models.whereType<AliasModel>().singleWhere(
      (model) => model.name == 'IntegerChoice',
    );
    expect(integer.name, 'IntegerChoice');
    expect(integer.resolved, isA<IntegerModel>());
  });

  test(
    'resolves schemas in operation content and reuses their parsed model',
    () {
      final api = Importer().import({
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': {
          '/pets': {
            'get': {
              'responses': {
                '200': {
                  'description': 'OK',
                  'content': {
                    'application/json': {
                      'schema': {
                        'type': 'object',
                        'properties': {
                          'id': {'type': 'integer'},
                        },
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
            'Payload': {
              r'$ref': '#/paths/~1pets/get/responses/200/content/application~1json/schema',
            },
          },
        },
      });

      final payload = api.models.whereType<AliasModel>().single;
      final body =
          api.operations.single.responses.values.single.resolved.bodies.single;
      expect(payload.resolved, isA<ClassModel>());
      expect(body.model, same(payload.resolved));
      expect(
        (payload.resolved as ClassModel).properties.single.model,
        isA<IntegerModel>(),
      );
    },
  );

  test('resolves an arbitrary local schema outside parsed containers', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'x-types': {
        'Value': {'type': 'integer'},
      },
      'components': {
        'schemas': {
          'Value': {r'$ref': '#/x-types/Value'},
        },
      },
    });

    final value = api.models.whereType<AliasModel>().singleWhere(
      (model) => model.context.path.first == 'components',
    );
    expect(value.resolved, isA<IntegerModel>());
  });

  test('rejects missing deep targets instead of using their last segment', () {
    expect(
      () => Importer().import({
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'id': {'type': 'string'},
            'Pet': {'type': 'object'},
            'Missing': {r'$ref': '#/components/schemas/Pet/properties/id'},
          },
        },
      }),
      throwsArgumentError,
    );
  });

  test(
    'uses decoded schema names and equivalent discriminator mapping refs',
    () {
      final api = Importer().import({
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Dog': {
              'type': 'object',
              'properties': {
                'bark': {'type': 'boolean'},
              },
            },
            'Cat': {
              'type': 'object',
              'properties': {
                'meow': {'type': 'string'},
              },
            },
            'Choice': {
              'oneOf': [
                {r'$ref': '#%2Fcomponents%2Fschemas%2FDog'},
                {r'$ref': '#%2Fcomponents%2Fschemas%2FCat'},
              ],
              'discriminator': {
                'propertyName': 'kind',
                'mapping': {'dog': '#/components/schemas/Dog'},
              },
            },
          },
        },
      });

      final choice = api.models.whereType<OneOfModel>().single;
      expect(choice.models.first.discriminatorValue, 'dog');
      expect(choice.models.last.discriminatorValue, 'Cat');
    },
  );

  test('detects encoded direct component self-references', () {
    expect(
      () => Importer().import({
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Self': {r'$ref': '#%2Fcomponents%2Fschemas%2FSelf'},
          },
        },
      }),
      throwsArgumentError,
    );
  });

  test(
    'retains nullable primitive metadata when the owner is parsed first',
    () {
      final api = Importer().import({
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Container': {
              'type': 'object',
              'properties': {
                'id': {
                  'type': ['string', 'null'],
                  'default': 'fallback',
                  'readOnly': true,
                },
              },
            },
            'Use': {r'$ref': '#/components/schemas/Container/properties/id'},
          },
        },
      });

      final use = api.models.whereType<AliasModel>().singleWhere(
        (model) => model.name == 'Use',
      );
      final target = use.model as AliasModel;
      expect(use.isEffectivelyNullable, isTrue);
      expect(use.defaultValue, 'fallback');
      expect(target.isReadOnly, isTrue);
      expect(target.isWriteOnly, isFalse);
      expect(target.resolved, isA<StringModel>());
    },
  );

  test(
    'retains nullable primitive metadata when its reference is parsed first',
    () {
      final api = Importer().import({
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Use': {r'$ref': '#/components/schemas/Container/properties/id'},
            'Container': {
              'type': 'object',
              'properties': {
                'id': {
                  'type': ['string', 'null'],
                  'default': 'fallback',
                  'writeOnly': true,
                },
              },
            },
          },
        },
      });

      final use = api.models.whereType<AliasModel>().singleWhere(
        (model) => model.name == 'Use',
      );
      final target = use.model as AliasModel;
      expect(use.isEffectivelyNullable, isTrue);
      expect(use.defaultValue, 'fallback');
      expect(target.isReadOnly, isFalse);
      expect(target.isWriteOnly, isTrue);
      expect(target.resolved, isA<StringModel>());
    },
  );

  test(
    'reuses an inline list shell before resolving recursive object items',
    () {
      final api = Importer().import({
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Container': {
              'type': 'object',
              'properties': {
                'nodes': {
                  'type': 'array',
                  'items': {
                    'type': 'object',
                    'properties': {
                      'next': {
                        r'$ref':
                            '#/components/schemas/Container/properties/nodes',
                      },
                    },
                  },
                },
              },
            },
          },
        },
      });

      final container = api.models.whereType<ClassModel>().singleWhere(
        (model) => model.name == 'Container',
      );
      final nodes = container.properties.single.model as ListModel;
      final item = nodes.content as ClassModel;
      expect(item.properties.single.model, same(nodes));
      expect((item.properties.single.model as ListModel).content, same(item));
      expect(api.models.whereType<ClassModel>(), hasLength(2));
      expect(api.models.whereType<ListModel>().single, same(nodes));
      expect(nodes.name, 'nodes');
    },
  );

  test(
    'reuses an inline map shell before resolving recursive object values',
    () {
      final api = Importer().import({
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Container': {
              'type': 'object',
              'properties': {
                'nodes': {
                  'type': 'object',
                  'additionalProperties': {
                    'type': 'object',
                    'properties': {
                      'next': {
                        r'$ref':
                            '#/components/schemas/Container/properties/nodes',
                      },
                    },
                  },
                },
              },
            },
          },
        },
      });

      final container = api.models.whereType<ClassModel>().singleWhere(
        (model) => model.name == 'Container',
      );
      final nodes = container.properties.single.model as MapModel;
      final item = nodes.valueModel as ClassModel;
      expect(item.properties.single.model, same(nodes));
      expect((item.properties.single.model as MapModel).valueModel, same(item));
      expect(api.models.whereType<ClassModel>(), hasLength(2));
      expect(api.models.whereType<MapModel>().single, same(nodes));
      expect(nodes.name, 'nodes');
    },
  );

  test(
    'keeps a raw descendant canonical when its ancestor is parsed later',
    () {
      final api = Importer().import({
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'x-types': {
          'Parent': {
            'type': 'object',
            'properties': {
              'child': {
                'type': 'object',
                'properties': {
                  'label': {'type': 'string'},
                },
              },
            },
          },
        },
        'components': {
          'schemas': {
            'Child': {r'$ref': '#/x-types/Parent/properties/child'},
            'Parent': {r'$ref': '#/x-types/Parent'},
            'ChildAgain': {r'$ref': '#/x-types/Parent/properties/child'},
          },
        },
      });

      final child = api.models
          .whereType<AliasModel>()
          .singleWhere((model) => model.name == 'Child')
          .resolved;
      final parent =
          api.models
                  .whereType<AliasModel>()
                  .singleWhere(
                    (model) =>
                        model.name == 'Parent' &&
                        model.context.path.first == 'components',
                  )
                  .resolved
              as ClassModel;
      final again = api.models
          .whereType<AliasModel>()
          .singleWhere((model) => model.name == 'ChildAgain')
          .resolved;
      expect(parent.properties.single.model.resolved, same(child));
      expect(again, same(child));
      expect(api.models.whereType<ClassModel>(), hasLength(2));
    },
  );

  test('keeps raw ancestor and descendant refs on the same parsed model', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'x-types': {
        'Parent': {
          'type': 'object',
          'properties': {
            'child': {
              'type': 'object',
              'properties': {
                'label': {'type': 'string'},
              },
            },
          },
        },
      },
      'components': {
        'schemas': {
          'Parent': {r'$ref': '#/x-types/Parent'},
          'Child': {r'$ref': '#/x-types/Parent/properties/child'},
          'ChildAgain': {r'$ref': '#/x-types/Parent/properties/child'},
        },
      },
    });

    final parent =
        api.models
                .whereType<AliasModel>()
                .singleWhere(
                  (model) =>
                      model.name == 'Parent' &&
                      model.context.path.first == 'components',
                )
                .resolved
            as ClassModel;
    final child = api.models
        .whereType<AliasModel>()
        .singleWhere((model) => model.name == 'Child')
        .resolved;
    final again = api.models
        .whereType<AliasModel>()
        .singleWhere((model) => model.name == 'ChildAgain')
        .resolved;
    expect(child, same(parent.properties.single.model.resolved));
    expect(again, same(child));
    expect(api.models.whereType<ClassModel>(), hasLength(2));
  });

  test('reuses a structurally extended target when its reference is first', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'Use': {r'$ref': '#/components/schemas/Owner/properties/child'},
          'Owner': {
            'type': 'object',
            'properties': {
              'child': {
                r'$ref': '#/components/schemas/Base',
                'properties': {
                  'extra': {'type': 'integer'},
                },
              },
            },
          },
          'Base': {
            'type': 'object',
            'required': ['base'],
            'properties': {
              'base': {'type': 'string'},
            },
          },
        },
      },
    });

    final use = api.models
        .whereType<AliasModel>()
        .singleWhere((model) => model.name == 'Use')
        .resolved;
    final owner = api.models.whereType<ClassModel>().singleWhere(
      (model) => model.name == 'Owner',
    );
    expect(owner.properties.single.model.resolved, same(use));
    expect(api.models.whereType<AllOfModel>(), hasLength(1));
    expect(api.models.whereType<ClassModel>(), hasLength(3));
  });

  test('reuses a structurally extended target when its owner is first', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'Owner': {
            'type': 'object',
            'properties': {
              'child': {
                r'$ref': '#/components/schemas/Base',
                'properties': {
                  'extra': {'type': 'integer'},
                },
              },
            },
          },
          'Use': {r'$ref': '#/components/schemas/Owner/properties/child'},
          'Base': {
            'type': 'object',
            'required': ['base'],
            'properties': {
              'base': {'type': 'string'},
            },
          },
        },
      },
    });

    final owner = api.models.whereType<ClassModel>().singleWhere(
      (model) => model.name == 'Owner',
    );
    final use = api.models
        .whereType<AliasModel>()
        .singleWhere((model) => model.name == 'Use')
        .resolved;
    expect(use, same(owner.properties.single.model.resolved));
    expect(api.models.whereType<AllOfModel>(), hasLength(1));
    expect(api.models.whereType<ClassModel>(), hasLength(3));
  });

  test('recursive structural targets keep the complete merged base model', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'Use': {r'$ref': '#/components/schemas/Owner/properties/child'},
          'Owner': {
            'type': 'object',
            'properties': {
              'child': {
                r'$ref': '#/components/schemas/Base',
                'properties': {
                  'extra': {'type': 'integer'},
                  'next': {
                    r'$ref': '#/components/schemas/Owner/properties/child',
                  },
                },
              },
            },
          },
          'Base': {
            'type': 'object',
            'required': ['base'],
            'properties': {
              'base': {'type': 'string'},
            },
          },
        },
      },
    });

    final merged =
        api.models
                .whereType<AliasModel>()
                .singleWhere((model) => model.name == 'Use')
                .resolved
            as AllOfModel;
    final base = merged.models.first as ClassModel;
    final extension = merged.models.last as ClassModel;
    expect(base.properties.single.name, 'base');
    expect(base.properties.single.isRequired, isTrue);
    expect(extension.properties.last.model.resolved, same(merged));
    expect(api.models.whereType<AllOfModel>(), hasLength(1));
  });

  test('allOf and union siblings retain the enclosing target identity', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'UseAll': {r'$ref': '#/components/schemas/Owner/properties/all'},
          'UseOne': {r'$ref': '#/components/schemas/Owner/properties/one'},
          'UseAny': {r'$ref': '#/components/schemas/Owner/properties/any'},
          'Owner': {
            'type': 'object',
            'properties': {
              'all': {
                r'$ref': '#/components/schemas/Base',
                'allOf': [
                  {
                    'type': 'object',
                    'properties': {
                      'extra': {'type': 'integer'},
                    },
                  },
                ],
              },
              'one': {
                r'$ref': '#/components/schemas/Base',
                'oneOf': [
                  {
                    'type': 'object',
                    'properties': {
                      'first': {'type': 'integer'},
                    },
                  },
                  {
                    'type': 'object',
                    'properties': {
                      'second': {'type': 'string'},
                    },
                  },
                ],
              },
              'any': {
                r'$ref': '#/components/schemas/Base',
                'anyOf': [
                  {
                    'type': 'object',
                    'properties': {
                      'first': {'type': 'integer'},
                    },
                  },
                  {
                    'type': 'object',
                    'properties': {
                      'second': {'type': 'string'},
                    },
                  },
                ],
              },
            },
          },
          'Base': {
            'type': 'object',
            'properties': {
              'base': {'type': 'string'},
            },
          },
        },
      },
    });

    final owner = api.models.whereType<ClassModel>().singleWhere(
      (model) => model.name == 'Owner',
    );
    final all =
        api.models
                .whereType<AliasModel>()
                .singleWhere((model) => model.name == 'UseAll')
                .resolved
            as AllOfModel;
    final one =
        api.models
                .whereType<AliasModel>()
                .singleWhere((model) => model.name == 'UseOne')
                .resolved
            as AllOfModel;
    final any =
        api.models
                .whereType<AliasModel>()
                .singleWhere((model) => model.name == 'UseAny')
                .resolved
            as AllOfModel;
    expect(owner.properties[0].model, same(all));
    expect(owner.properties[1].model, same(one));
    expect(owner.properties[2].model, same(any));
    expect(one.models.last, isA<OneOfModel>());
    expect(any.models.last, isA<AnyOfModel>());
    expect(api.models.whereType<AllOfModel>(), hasLength(3));
  });

  test('reuses a nested union before parsing its recursive array member', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'Owner': {
            'type': 'object',
            'properties': {
              'child': {
                'type': ['string', 'array'],
                'items': {
                  r'$ref': '#/components/schemas/Owner/properties/child',
                },
              },
            },
          },
        },
      },
    });

    final owner = api.models.whereType<ClassModel>().single;
    final child = owner.properties.single.model as OneOfModel;
    final list = child.models.last.model as ListModel;
    expect(list.content, same(child));
    expect(api.models.whereType<OneOfModel>(), hasLength(1));
    expect(api.models.whereType<ListModel>().single, same(list));
  });

  test('populates a named union without replacing its recursive shell', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'Value': {
            'type': ['string', 'array'],
            'items': {r'$ref': '#/components/schemas/Value'},
          },
        },
      },
    });

    final value = api.models.whereType<OneOfModel>().single;
    final list = value.models.last.model as ListModel;
    expect(list.content, same(value));
    expect(api.models.whereType<ListModel>().single, same(list));
  });

  test('reuses an allOf before resolving recursive additional properties', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'Owner': {
            'type': 'object',
            'properties': {
              'child': {
                'allOf': [
                  {
                    'type': 'object',
                    'properties': {
                      'name': {'type': 'string'},
                    },
                  },
                ],
                'additionalProperties': {
                  r'$ref': '#/components/schemas/Owner/properties/child',
                },
              },
            },
          },
        },
      },
    });

    final owner = api.models.whereType<ClassModel>().singleWhere(
      (model) => model.name == 'Owner',
    );
    final child = owner.properties.single.model as AllOfModel;
    final additional =
        child.additionalPropertiesPolicy as AllowedAdditionalProperties;
    expect(additional.valueModel, same(child));
    expect(api.models.whereType<AllOfModel>(), hasLength(1));
    expect((child.models.single as ClassModel).properties.single.name, 'name');
  });

  test('reuses a class before resolving recursive additional properties', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'Owner': {
            'type': 'object',
            'properties': {
              'child': {
                'type': 'object',
                'properties': {
                  'name': {'type': 'string'},
                },
                'additionalProperties': {
                  r'$ref': '#/components/schemas/Owner/properties/child',
                },
              },
            },
          },
        },
      },
    });

    final owner = api.models.whereType<ClassModel>().singleWhere(
      (model) => model.name == 'Owner',
    );
    final child = owner.properties.single.model as ClassModel;
    final additional =
        child.additionalPropertiesPolicy as AllowedAdditionalProperties;
    expect(additional.valueModel, same(child));
    expect(child.properties.single.name, 'name');
    expect(api.models.whereType<ClassModel>(), hasLength(2));
  });

  test(
    'cached reference targets retain readOnly defaults in multipart layouts',
    () {
      final api = Importer().import({
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
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
                        'secret': {r'$ref': '#/components/schemas/Use'},
                        'visible': {'type': 'string'},
                      },
                    },
                  },
                },
              },
              'responses': <String, dynamic>{},
            },
          },
        },
        'components': {
          'schemas': {
            'Owner': {
              'type': 'object',
              'properties': {
                'child': {
                  r'$ref': '#/components/schemas/Value',
                  'readOnly': true,
                  'default': 'yes',
                },
              },
            },
            'Use': {r'$ref': '#/components/schemas/Owner/properties/child'},
            'Value': {'type': 'string'},
          },
        },
      });

      final owner = api.models.whereType<ClassModel>().singleWhere(
        (model) => model.name == 'Owner',
      );
      final use = api.models.whereType<AliasModel>().singleWhere(
        (model) => model.name == 'Use',
      );
      final target = use.model as AliasModel;
      final body =
          api.operations.single.requestBody!.resolvedContent.single
              as MultipartRequestContent;
      expect(target, same(owner.properties.single.model));
      expect(target.isReadOnly, isTrue);
      expect(target.isWriteOnly, isFalse);
      expect(use.defaultValue, 'yes');
      expect(body.layout.fields.map((field) => field.wireName), ['visible']);
    },
  );

  test('forward reference targets retain writeOnly without a default', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'Use': {r'$ref': '#/components/schemas/Owner/properties/child'},
          'Owner': {
            'type': 'object',
            'properties': {
              'child': {
                r'$ref': '#/components/schemas/Value',
                'writeOnly': true,
              },
            },
          },
          'Value': {'type': 'string'},
          'ReadOnlyValue': {
            r'$ref': '#/components/schemas/Value',
            'readOnly': true,
          },
          'WriteOnlyValue': {
            r'$ref': '#/components/schemas/Value',
            'writeOnly': true,
          },
        },
      },
    });

    final owner = api.models.whereType<ClassModel>().single;
    final use = api.models.whereType<AliasModel>().singleWhere(
      (model) => model.name == 'Use',
    );
    final target = use.model as AliasModel;
    final readOnly = api.models.whereType<AliasModel>().singleWhere(
      (model) => model.name == 'ReadOnlyValue',
    );
    final writeOnly = api.models.whereType<AliasModel>().singleWhere(
      (model) => model.name == 'WriteOnlyValue',
    );
    expect(target, same(owner.properties.single.model));
    expect(target.isWriteOnly, isTrue);
    expect(target.isReadOnly, isFalse);
    expect(readOnly.isReadOnly, isTrue);
    expect(writeOnly.isWriteOnly, isTrue);
    expect(target.resolved, isA<StringModel>());
  });

  test('skips a raw oneOf self-edge and retains its concrete member', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'Choice': {r'$ref': '#/x-schemas/choice'},
        },
      },
      'x-schemas': {
        'choice': {
          'oneOf': [
            {r'$ref': '#/x-schemas/choice'},
            {'type': 'string'},
          ],
        },
      },
    });

    final choice = api.models.whereType<OneOfModel>().single;
    expect(choice.models.single.model, isA<StringModel>());
  });

  test('skips a raw anyOf self-edge and retains its concrete member', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'Choice': {r'$ref': '#/x-schemas/choice'},
        },
      },
      'x-schemas': {
        'choice': {
          'anyOf': [
            {r'$ref': '#/x-schemas/choice'},
            {'type': 'string'},
          ],
        },
      },
    });

    final choice = api.models.whereType<AnyOfModel>().single;
    expect(choice.models.single.model, isA<StringModel>());
  });

  test('skips a raw allOf self-edge and retains its concrete member', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'Choice': {r'$ref': '#/x-schemas/choice'},
        },
      },
      'x-schemas': {
        'choice': {
          'allOf': [
            {r'$ref': '#/x-schemas/choice'},
            {'type': 'string'},
          ],
        },
      },
    });

    final choice = api.models.whereType<AllOfModel>().single;
    expect(choice.models.single, isA<StringModel>());
  });

  test('skips transitive back-edges through inline composite members', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'Choice': {r'$ref': '#/x-schemas/choice'},
        },
      },
      'x-schemas': {
        'choice': {
          'oneOf': [
            {
              'anyOf': [
                {r'$ref': '#/x-schemas/choice'},
                {'type': 'string'},
              ],
            },
            {'type': 'integer'},
          ],
        },
      },
    });

    final choice = api.models.whereType<OneOfModel>().single;
    expect(choice.models.single.model, isA<IntegerModel>());
    expect(
      api.models.whereType<AnyOfModel>().single.models.first.model,
      same(choice),
    );
  });

  test(
    'fresh unconstrained pointer targets retain defaults and multipart flags',
    () {
      final api = Importer().import({
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
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
                        'secret': {r'$ref': '#/components/schemas/Use'},
                        'visible': {'type': 'string'},
                      },
                    },
                  },
                },
              },
              'responses': <String, dynamic>{},
            },
          },
        },
        'components': {
          'schemas': {
            'Use': {r'$ref': '#/x-schemas/defaulted'},
            'NullUse': {r'$ref': '#/x-schemas/nullValue'},
          },
        },
        'x-schemas': {
          'defaulted': {'readOnly': true, 'default': 42},
          'nullValue': {'type': 'null', 'writeOnly': true},
        },
      });

      final use = api.models.whereType<AliasModel>().singleWhere(
        (model) => model.name == 'Use',
      );
      final target = use.model as AliasModel;
      final nullUse = api.models.whereType<AliasModel>().singleWhere(
        (model) => model.name == 'NullUse',
      );
      final nullTarget = nullUse.model as AliasModel;
      final body =
          api.operations.single.requestBody!.resolvedContent.single
              as MultipartRequestContent;
      expect(use.defaultValue, 42);
      expect(target.isReadOnly, isTrue);
      expect(target.resolved, isA<AnyModel>());
      expect(nullTarget.isWriteOnly, isTrue);
      expect(nullUse.isEffectivelyNullable, isTrue);
      expect(nullTarget.resolved, isA<NeverModel>());
      expect(body.layout.fields.single.wireName, 'visible');
    },
  );

  test(
    'cached unconstrained pointer targets retain canonical annotated aliases',
    () {
      final api = Importer().import({
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Owner': {
              'type': 'object',
              'properties': {
                'value': {'readOnly': true, 'default': 42},
                'nullValue': {'type': 'null', 'writeOnly': true},
              },
            },
            'Use': {r'$ref': '#/components/schemas/Owner/properties/value'},
            'NullUse': {
              r'$ref': '#/components/schemas/Owner/properties/nullValue',
            },
          },
        },
      });

      final owner = api.models.whereType<ClassModel>().single;
      final use = api.models.whereType<AliasModel>().singleWhere(
        (model) => model.name == 'Use',
      );
      final nullUse = api.models.whereType<AliasModel>().singleWhere(
        (model) => model.name == 'NullUse',
      );
      expect(use.model, same(owner.properties.first.model));
      expect((use.model as AliasModel).isReadOnly, isTrue);
      expect(use.defaultValue, 42);
      expect(nullUse.model, same(owner.properties.last.model));
      expect((nullUse.model as AliasModel).isWriteOnly, isTrue);
      expect(nullUse.isEffectivelyNullable, isTrue);
    },
  );

  test('discriminator inheritance stops at a raw allOf self-edge', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'Choice': {
            'oneOf': [
              {r'$ref': '#/x-types/Base'},
              {'type': 'integer'},
            ],
          },
        },
      },
      'x-types': {
        'Base': {
          'allOf': [
            {r'$ref': '#/x-types/Base'},
            {'type': 'string'},
          ],
        },
      },
    });

    final choice = api.models.whereType<OneOfModel>().single;
    expect(choice.discriminator, isNull);
    expect(choice.models.last.model, isA<IntegerModel>());
    expect(
      (choice.models.first.model as AllOfModel).models.single,
      isA<StringModel>(),
    );
  });

  test('discriminator inheritance continues after a cyclic branch', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'Choice': {
            'oneOf': [
              {r'$ref': '#/x-types/Base'},
            ],
          },
          'Parent': {
            'type': 'object',
            'discriminator': {'propertyName': 'kind'},
            'properties': {
              'kind': {'type': 'string'},
            },
          },
        },
      },
      'x-types': {
        'Base': {
          'allOf': [
            {r'$ref': '#/x-types/Base'},
            {r'$ref': '#/components/schemas/Parent'},
          ],
        },
      },
    });

    final choice = api.models.whereType<OneOfModel>().single;
    expect(choice.discriminator, 'kind');
    final base = choice.models.single.model as AllOfModel;
    expect((base.models.single as ClassModel).name, 'Parent');
  });

  test('owner-first self collections gain names without replacing shells', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'Owner': {
            'type': 'object',
            'properties': {
              'list': {
                'type': 'array',
                'items': {
                  r'$ref': '#/components/schemas/Owner/properties/list',
                },
              },
              'map': {
                'type': 'object',
                'additionalProperties': {
                  r'$ref': '#/components/schemas/Owner/properties/map',
                },
              },
            },
          },
        },
      },
    });

    final owner = api.models.whereType<ClassModel>().single;
    final list = owner.properties.first.model as ListModel;
    final map = owner.properties.last.model as MapModel;
    expect(list.content, same(list));
    expect(map.valueModel, same(map));
    expect(list.name, 'list');
    expect(map.name, 'map');
    expect(api.models.whereType<ListModel>().single, same(list));
    expect(api.models.whereType<MapModel>().single, same(map));
  });

  test('reference-first self collections share the owner models and names', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'ListUse': {r'$ref': '#/components/schemas/Owner/properties/list'},
          'MapUse': {r'$ref': '#/components/schemas/Owner/properties/map'},
          'Owner': {
            'type': 'object',
            'properties': {
              'list': {
                'type': 'array',
                'items': {
                  r'$ref': '#/components/schemas/Owner/properties/list',
                },
              },
              'map': {
                'type': 'object',
                'additionalProperties': {
                  r'$ref': '#/components/schemas/Owner/properties/map',
                },
              },
            },
          },
        },
      },
    });

    final owner = api.models.whereType<ClassModel>().single;
    final list = api.models.whereType<ListModel>().single;
    final map = api.models.whereType<MapModel>().single;
    final listUse = api.models.whereType<AliasModel>().singleWhere(
      (model) => model.name == 'ListUse',
    );
    final mapUse = api.models.whereType<AliasModel>().singleWhere(
      (model) => model.name == 'MapUse',
    );
    expect(listUse.model, same(list));
    expect(mapUse.model, same(map));
    expect(owner.properties.first.model, same(list));
    expect(owner.properties.last.model, same(map));
    expect(list.content, same(list));
    expect(map.valueModel, same(map));
    expect(list.name, 'list');
    expect(map.name, 'map');
  });

  test('unreferenced inline collections remain anonymous', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'Owner': {
            'type': 'object',
            'properties': {
              'list': {
                'type': 'array',
                'items': {'type': 'string'},
              },
              'map': {
                'type': 'object',
                'additionalProperties': {'type': 'integer'},
              },
            },
          },
        },
      },
    });

    final owner = api.models.whereType<ClassModel>().single;
    expect((owner.properties.first.model as ListModel).name, isNull);
    expect((owner.properties.last.model as MapModel).name, isNull);
    expect(api.models.whereType<ListModel>(), isEmpty);
    expect(api.models.whereType<MapModel>(), isEmpty);
  });

  test('encoded component refs retain schema-name and canonical mappings', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'Dog': {
            'type': 'object',
            'properties': {
              'bark': {'type': 'boolean'},
            },
          },
          'Cat': {
            'type': 'object',
            'properties': {
              'meow': {'type': 'string'},
            },
          },
          'Choice': {
            'oneOf': [
              {r'$ref': '#%2Fcomponents%2Fschemas%2FDog'},
              {r'$ref': '#/components/schemas/%43at'},
            ],
            'discriminator': {
              'propertyName': 'kind',
              'mapping': {'dog': 'Dog', 'cat': '#/components/schemas/Cat'},
            },
          },
        },
      },
    });

    final choice = api.models.whereType<OneOfModel>().single;
    expect(choice.models.first.discriminatorValue, 'dog');
    expect(choice.models.last.discriminatorValue, 'cat');
  });

  test('deep typeless targets retain enum values and fallback annotations', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'Owner': {
            'type': 'object',
            'properties': {
              'color': {
                'enum': ['red', 'green', null],
                'format': 'uri',
              },
              'items': {
                'items': {'type': 'string'},
                'readOnly': true,
                'default': [1, 'two'],
              },
              'mixed': {
                'enum': ['red', 42],
                'writeOnly': true,
                'default': 42,
              },
            },
          },
          'ColorUse': {r'$ref': '#/components/schemas/Owner/properties/color'},
          'ItemsUse': {r'$ref': '#/components/schemas/Owner/properties/items'},
          'MixedUse': {r'$ref': '#/components/schemas/Owner/properties/mixed'},
        },
      },
    });

    final color =
        api.models
                .whereType<AliasModel>()
                .singleWhere((model) => model.name == 'ColorUse')
                .resolved
            as EnumModel<String>;
    final items = api.models.whereType<AliasModel>().singleWhere(
      (model) => model.name == 'ItemsUse',
    );
    final mixed = api.models.whereType<AliasModel>().singleWhere(
      (model) => model.name == 'MixedUse',
    );
    expect(color.values.map((entry) => entry.value), ['red', 'green']);
    expect(color.isNullable, isTrue);
    expect(items.resolved, isA<AnyModel>());
    expect((items.model as AliasModel).isReadOnly, isTrue);
    expect(items.defaultValue, [1, 'two']);
    expect(mixed.resolved, isA<AnyModel>());
    expect((mixed.model as AliasModel).isWriteOnly, isTrue);
    expect(mixed.defaultValue, 42);
    expect(api.models.whereType<ClassModel>(), hasLength(1));
  });
}
