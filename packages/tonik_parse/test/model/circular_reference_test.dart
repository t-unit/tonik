import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  group('circular reference cycle detection', () {
    test('cycle through array and class: A -> array of B -> ref A', () {
      const spec = {
        'openapi': '3.0.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'SchemaA': {
              'type': 'object',
              'properties': {
                'children': {
                  'type': 'array',
                  'items': {r'$ref': '#/components/schemas/SchemaB'},
                },
              },
            },
            'SchemaB': {
              'type': 'object',
              'properties': {
                'parent': {r'$ref': '#/components/schemas/SchemaA'},
              },
            },
          },
        },
      };

      final api = Importer().import(spec);

      final schemaA = api.models.firstWhere(
        (m) => m is NamedModel && m.name == 'SchemaA',
      ) as ClassModel;
      expect(schemaA.name, 'SchemaA');

      final schemaB = api.models.firstWhere(
        (m) => m is NamedModel && m.name == 'SchemaB',
      ) as ClassModel;
      expect(schemaB.name, 'SchemaB');

      // SchemaA.children is a list of SchemaB
      final childrenProp =
          schemaA.properties.firstWhere((p) => p.name == 'children');
      expect(childrenProp.model, isA<ListModel>());
      final listModel = childrenProp.model as ListModel;
      expect(listModel.content, isA<ClassModel>());
      expect((listModel.content as ClassModel).name, 'SchemaB');

      // SchemaB.parent is SchemaA
      final parentProp =
          schemaB.properties.firstWhere((p) => p.name == 'parent');
      expect(parentProp.model, isA<ClassModel>());
      expect((parentProp.model as ClassModel).name, 'SchemaA');
    });

    test('cycle through allOf: A -> allOf [ref B], B -> property ref A', () {
      const spec = {
        'openapi': '3.0.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'SchemaA': {
              'allOf': [
                {r'$ref': '#/components/schemas/SchemaB'},
                {
                  'type': 'object',
                  'properties': {
                    'extra': {'type': 'string'},
                  },
                },
              ],
            },
            'SchemaB': {
              'type': 'object',
              'properties': {
                'back': {r'$ref': '#/components/schemas/SchemaA'},
              },
            },
          },
        },
      };

      final api = Importer().import(spec);

      final schemaA = api.models.firstWhere(
        (m) => m is NamedModel && m.name == 'SchemaA',
      );
      expect(schemaA, isA<AllOfModel>());

      final schemaB = api.models.firstWhere(
        (m) => m is NamedModel && m.name == 'SchemaB',
      ) as ClassModel;
      expect(schemaB.name, 'SchemaB');

      // SchemaB.back should reference SchemaA (the AllOfModel)
      final backProp =
          schemaB.properties.firstWhere((p) => p.name == 'back');
      expect(backProp.model, isA<AllOfModel>());
      expect((backProp.model as AllOfModel).name, 'SchemaA');
    });

    test('longer cycle: A -> B -> C -> A through properties', () {
      const spec = {
        'openapi': '3.0.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'SchemaA': {
              'type': 'object',
              'properties': {
                'b': {r'$ref': '#/components/schemas/SchemaB'},
              },
            },
            'SchemaB': {
              'type': 'object',
              'properties': {
                'c': {r'$ref': '#/components/schemas/SchemaC'},
              },
            },
            'SchemaC': {
              'type': 'object',
              'properties': {
                'a': {r'$ref': '#/components/schemas/SchemaA'},
              },
            },
          },
        },
      };

      final api = Importer().import(spec);

      final schemaA = api.models.firstWhere(
        (m) => m is NamedModel && m.name == 'SchemaA',
      ) as ClassModel;
      final schemaB = api.models.firstWhere(
        (m) => m is NamedModel && m.name == 'SchemaB',
      ) as ClassModel;
      final schemaC = api.models.firstWhere(
        (m) => m is NamedModel && m.name == 'SchemaC',
      ) as ClassModel;

      expect(schemaA.name, 'SchemaA');
      expect(schemaB.name, 'SchemaB');
      expect(schemaC.name, 'SchemaC');

      // A.b -> SchemaB
      final bProp = schemaA.properties.firstWhere((p) => p.name == 'b');
      expect(bProp.model, isA<ClassModel>());
      expect((bProp.model as ClassModel).name, 'SchemaB');

      // B.c -> SchemaC
      final cProp = schemaB.properties.firstWhere((p) => p.name == 'c');
      expect(cProp.model, isA<ClassModel>());
      expect((cProp.model as ClassModel).name, 'SchemaC');

      // C.a -> SchemaA
      final aProp = schemaC.properties.firstWhere((p) => p.name == 'a');
      expect(aProp.model, isA<ClassModel>());
      expect((aProp.model as ClassModel).name, 'SchemaA');
    });

    test('cycle through array in longer chain: A -> array of B -> C -> ref A',
        () {
      const spec = {
        'openapi': '3.0.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'SchemaA': {
              'type': 'object',
              'properties': {
                'items': {
                  'type': 'array',
                  'items': {r'$ref': '#/components/schemas/SchemaB'},
                },
              },
            },
            'SchemaB': {
              'type': 'object',
              'properties': {
                'next': {r'$ref': '#/components/schemas/SchemaC'},
              },
            },
            'SchemaC': {
              'type': 'object',
              'properties': {
                'root': {r'$ref': '#/components/schemas/SchemaA'},
              },
            },
          },
        },
      };

      final api = Importer().import(spec);

      final schemaA = api.models.firstWhere(
        (m) => m is NamedModel && m.name == 'SchemaA',
      ) as ClassModel;
      final schemaB = api.models.firstWhere(
        (m) => m is NamedModel && m.name == 'SchemaB',
      ) as ClassModel;
      final schemaC = api.models.firstWhere(
        (m) => m is NamedModel && m.name == 'SchemaC',
      ) as ClassModel;

      // A.items is array of B
      final itemsProp =
          schemaA.properties.firstWhere((p) => p.name == 'items');
      expect(itemsProp.model, isA<ListModel>());
      expect((itemsProp.model as ListModel).content, isA<ClassModel>());
      expect(
        ((itemsProp.model as ListModel).content as ClassModel).name,
        'SchemaB',
      );

      // B.next is C
      final nextProp = schemaB.properties.firstWhere((p) => p.name == 'next');
      expect(nextProp.model, isA<ClassModel>());
      expect((nextProp.model as ClassModel).name, 'SchemaC');

      // C.root is A
      final rootProp = schemaC.properties.firstWhere((p) => p.name == 'root');
      expect(rootProp.model, isA<ClassModel>());
      expect((rootProp.model as ClassModel).name, 'SchemaA');
    });

    test('cycle through oneOf: A has oneOf [ref B], B has property ref A', () {
      const spec = {
        'openapi': '3.0.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'SchemaA': {
              'oneOf': [
                {r'$ref': '#/components/schemas/SchemaB'},
                {'type': 'string'},
              ],
            },
            'SchemaB': {
              'type': 'object',
              'properties': {
                'back': {r'$ref': '#/components/schemas/SchemaA'},
              },
            },
          },
        },
      };

      final api = Importer().import(spec);

      final schemaA = api.models.firstWhere(
        (m) => m is NamedModel && m.name == 'SchemaA',
      );
      expect(schemaA, isA<OneOfModel>());

      final schemaB = api.models.firstWhere(
        (m) => m is NamedModel && m.name == 'SchemaB',
      ) as ClassModel;
      expect(schemaB.name, 'SchemaB');

      // SchemaB.back should reference SchemaA
      final backProp =
          schemaB.properties.firstWhere((p) => p.name == 'back');
      expect(backProp.model, isA<OneOfModel>());
      expect((backProp.model as OneOfModel).name, 'SchemaA');
    });

    test('cycle through anyOf: A has anyOf [ref B], B has property ref A', () {
      const spec = {
        'openapi': '3.0.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'SchemaA': {
              'anyOf': [
                {r'$ref': '#/components/schemas/SchemaB'},
                {'type': 'string'},
              ],
            },
            'SchemaB': {
              'type': 'object',
              'properties': {
                'back': {r'$ref': '#/components/schemas/SchemaA'},
              },
            },
          },
        },
      };

      final api = Importer().import(spec);

      final schemaA = api.models.firstWhere(
        (m) => m is NamedModel && m.name == 'SchemaA',
      );
      expect(schemaA, isA<AnyOfModel>());

      final schemaB = api.models.firstWhere(
        (m) => m is NamedModel && m.name == 'SchemaB',
      ) as ClassModel;
      expect(schemaB.name, 'SchemaB');

      // SchemaB.back should reference SchemaA
      final backProp =
          schemaB.properties.firstWhere((p) => p.name == 'back');
      expect(backProp.model, isA<AnyOfModel>());
      expect((backProp.model as AnyOfModel).name, 'SchemaA');
    });

    test('self-referencing through array: A has property that is array of A',
        () {
      const spec = {
        'openapi': '3.0.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'TreeNode': {
              'type': 'object',
              'properties': {
                'value': {'type': 'string'},
                'children': {
                  'type': 'array',
                  'items': {r'$ref': '#/components/schemas/TreeNode'},
                },
              },
            },
          },
        },
      };

      final api = Importer().import(spec);

      final treeNode = api.models.firstWhere(
        (m) => m is NamedModel && m.name == 'TreeNode',
      ) as ClassModel;
      expect(treeNode.name, 'TreeNode');

      final valueProp =
          treeNode.properties.firstWhere((p) => p.name == 'value');
      expect(valueProp.model, isA<StringModel>());

      final childrenProp =
          treeNode.properties.firstWhere((p) => p.name == 'children');
      expect(childrenProp.model, isA<ListModel>());
      final listModel = childrenProp.model as ListModel;
      expect(listModel.content, isA<ClassModel>());
      expect((listModel.content as ClassModel).name, 'TreeNode');
      // The content should be the same TreeNode object
      expect(identical(listModel.content, treeNode), isTrue);
    });

    test('mutual reference through arrays: A has array of B, B has array of A',
        () {
      const spec = {
        'openapi': '3.0.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'SchemaA': {
              'type': 'object',
              'properties': {
                'bList': {
                  'type': 'array',
                  'items': {r'$ref': '#/components/schemas/SchemaB'},
                },
              },
            },
            'SchemaB': {
              'type': 'object',
              'properties': {
                'aList': {
                  'type': 'array',
                  'items': {r'$ref': '#/components/schemas/SchemaA'},
                },
              },
            },
          },
        },
      };

      final api = Importer().import(spec);

      final schemaA = api.models.firstWhere(
        (m) => m is NamedModel && m.name == 'SchemaA',
      ) as ClassModel;
      final schemaB = api.models.firstWhere(
        (m) => m is NamedModel && m.name == 'SchemaB',
      ) as ClassModel;

      // A.bList is array of B
      final bListProp =
          schemaA.properties.firstWhere((p) => p.name == 'bList');
      expect(bListProp.model, isA<ListModel>());
      expect(
        ((bListProp.model as ListModel).content as ClassModel).name,
        'SchemaB',
      );

      // B.aList is array of A
      final aListProp =
          schemaB.properties.firstWhere((p) => p.name == 'aList');
      expect(aListProp.model, isA<ListModel>());
      expect(
        ((aListProp.model as ListModel).content as ClassModel).name,
        'SchemaA',
      );
    });

    test(
      'cycle through top-level array schemas: '
      'A(array of B) and B(array of A)',
      () {
        const spec = {
          'openapi': '3.0.0',
          'info': {'title': 'Test API', 'version': '1.0.0'},
          'paths': <String, dynamic>{},
          'components': {
            'schemas': {
              'SchemaA': {
                'type': 'array',
                'items': {r'$ref': '#/components/schemas/SchemaB'},
              },
              'SchemaB': {
                'type': 'array',
                'items': {r'$ref': '#/components/schemas/SchemaA'},
              },
            },
          },
        };

        final api = Importer().import(spec);

        // Both schemas should be parsed as ListModel (wrapped in AliasModel)
        // without causing a stack overflow.
        expect(api.models.length, greaterThanOrEqualTo(2));
      },
    );

    test(
      'deep cycle: class -> array(named) -> class -> array(named) -> first',
      () {
        // SchemaA: object with property refs ArrayB
        // ArrayB: array of SchemaC
        // SchemaC: object with property refs ArrayD
        // ArrayD: array of SchemaA
        const spec = {
          'openapi': '3.0.0',
          'info': {'title': 'Test API', 'version': '1.0.0'},
          'paths': <String, dynamic>{},
          'components': {
            'schemas': {
              'SchemaA': {
                'type': 'object',
                'properties': {
                  'list': {r'$ref': '#/components/schemas/ArrayB'},
                },
              },
              'ArrayB': {
                'type': 'array',
                'items': {r'$ref': '#/components/schemas/SchemaC'},
              },
              'SchemaC': {
                'type': 'object',
                'properties': {
                  'list': {r'$ref': '#/components/schemas/ArrayD'},
                },
              },
              'ArrayD': {
                'type': 'array',
                'items': {r'$ref': '#/components/schemas/SchemaA'},
              },
            },
          },
        };

        final api = Importer().import(spec);

        final schemaA = api.models.firstWhere(
          (m) => m is NamedModel && m.name == 'SchemaA',
        ) as ClassModel;
        expect(schemaA.name, 'SchemaA');

        final schemaC = api.models.firstWhere(
          (m) => m is NamedModel && m.name == 'SchemaC',
        ) as ClassModel;
        expect(schemaC.name, 'SchemaC');
      },
    );

    test('existing direct self-reference still throws', () {
      const spec = {
        'openapi': '3.0.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'SelfRef': {
              r'$ref': '#/components/schemas/SelfRef',
            },
          },
        },
      };

      expect(
        () => Importer().import(spec),
        throwsA(isA<ArgumentError>()),
      );
    });

    test(
      'cycle through chained allOfs: '
      'A(allOf) -> B(allOf) -> C(class) -> ref A',
      () {
        const spec = {
          'openapi': '3.0.0',
          'info': {'title': 'Test API', 'version': '1.0.0'},
          'paths': <String, dynamic>{},
          'components': {
            'schemas': {
              'SchemaA': {
                'allOf': [
                  {r'$ref': '#/components/schemas/SchemaB'},
                  {
                    'type': 'object',
                    'properties': {
                      'extraA': {'type': 'string'},
                    },
                  },
                ],
              },
              'SchemaB': {
                'allOf': [
                  {r'$ref': '#/components/schemas/SchemaC'},
                  {
                    'type': 'object',
                    'properties': {
                      'extraB': {'type': 'string'},
                    },
                  },
                ],
              },
              'SchemaC': {
                'type': 'object',
                'properties': {
                  'back': {r'$ref': '#/components/schemas/SchemaA'},
                },
              },
            },
          },
        };

        final api = Importer().import(spec);

        final schemaA = api.models.firstWhere(
          (m) => m is NamedModel && m.name == 'SchemaA',
        );
        expect(schemaA, isA<AllOfModel>());

        final schemaB = api.models.firstWhere(
          (m) => m is NamedModel && m.name == 'SchemaB',
        );
        expect(schemaB, isA<AllOfModel>());

        final schemaC = api.models.firstWhere(
          (m) => m is NamedModel && m.name == 'SchemaC',
        ) as ClassModel;
        expect(schemaC.name, 'SchemaC');

        // SchemaC.back should reference SchemaA
        final backProp =
            schemaC.properties.firstWhere((p) => p.name == 'back');
        expect(backProp.model, isA<AllOfModel>());
        expect((backProp.model as AllOfModel).name, 'SchemaA');
      },
    );

    test(
      'cycle through allOf and array: '
      'A(allOf) -> B(class with array of C) -> C(class) -> ref A',
      () {
        const spec = {
          'openapi': '3.0.0',
          'info': {'title': 'Test API', 'version': '1.0.0'},
          'paths': <String, dynamic>{},
          'components': {
            'schemas': {
              'SchemaA': {
                'allOf': [
                  {r'$ref': '#/components/schemas/SchemaB'},
                  {
                    'type': 'object',
                    'properties': {
                      'extraA': {'type': 'string'},
                    },
                  },
                ],
              },
              'SchemaB': {
                'type': 'object',
                'properties': {
                  'items': {
                    'type': 'array',
                    'items': {r'$ref': '#/components/schemas/SchemaC'},
                  },
                },
              },
              'SchemaC': {
                'type': 'object',
                'properties': {
                  'root': {r'$ref': '#/components/schemas/SchemaA'},
                },
              },
            },
          },
        };

        final api = Importer().import(spec);

        final schemaA = api.models.firstWhere(
          (m) => m is NamedModel && m.name == 'SchemaA',
        );
        expect(schemaA, isA<AllOfModel>());

        final schemaC = api.models.firstWhere(
          (m) => m is NamedModel && m.name == 'SchemaC',
        ) as ClassModel;

        // SchemaC.root should reference SchemaA
        final rootProp =
            schemaC.properties.firstWhere((p) => p.name == 'root');
        expect(rootProp.model, isA<AllOfModel>());
        expect((rootProp.model as AllOfModel).name, 'SchemaA');
      },
    );

    test('bare ref cycle produces valid AliasModels', () {
      const spec = {
        'openapi': '3.0.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'AliasA': {
              r'$ref': '#/components/schemas/AliasB',
            },
            'AliasB': {
              r'$ref': '#/components/schemas/AliasA',
            },
          },
        },
      };

      final api = Importer().import(spec);

      // Both schemas should be present as AliasModel instances.
      final aliasA = api.models.firstWhere(
        (m) => m is NamedModel && m.name == 'AliasA',
      );
      final aliasB = api.models.firstWhere(
        (m) => m is NamedModel && m.name == 'AliasB',
      );

      expect(aliasA, isA<AliasModel>());
      expect(aliasB, isA<AliasModel>());
    });
  });
}
