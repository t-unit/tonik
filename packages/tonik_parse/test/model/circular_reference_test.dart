import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/tonik_parse.dart';
import 'package:tonik_util/tonik_util.dart';

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

        // Both schemas should be present and parsed as ListModel without
        // causing a stack overflow.
        final schemaA = api.models.firstWhere(
          (m) => m is NamedModel && m.name == 'SchemaA',
        );
        final schemaB = api.models.firstWhere(
          (m) => m is NamedModel && m.name == 'SchemaB',
        );

        // Top-level array schemas become ListModel instances.
        expect(schemaA, isA<ListModel>());
        expect(schemaB, isA<ListModel>());

        // Each list's content should reference the other list model.
        final listA = schemaA as ListModel;
        final listB = schemaB as ListModel;
        expect(listA.content, isA<ListModel>());
        expect(listB.content, isA<ListModel>());
        expect((listA.content as ListModel).name, 'SchemaB');
        expect((listB.content as ListModel).name, 'SchemaA');
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

    test(
      r'top-level array whose items $ref back to the array via a property '
      'produces exactly one ListModel (no duplicate)',
      () {
        // Reproduces the Cloudflare `request-tracer_trace` bug: a top-level
        // array schema with inline items that self-reference via a property.
        const spec = {
          'openapi': '3.0.0',
          'info': {'title': 'Test API', 'version': '1.0.0'},
          'paths': <String, dynamic>{},
          'components': {
            'schemas': {
              'TracerTrace': {
                'type': 'array',
                'items': {
                  'type': 'object',
                  'properties': {
                    'trace': {r'$ref': '#/components/schemas/TracerTrace'},
                  },
                },
              },
            },
          },
        };

        final api = Importer().import(spec);

        // Exactly ONE ListModel named 'TracerTrace' exists.
        final tracerTraceModels = api.models
            .whereType<ListModel>()
            .where((m) => m.name == 'TracerTrace')
            .toList();
        expect(tracerTraceModels.length, 1);

        final tracerTrace = tracerTraceModels.single;

        // The items ClassModel is present in api.models.
        final itemsModels = api.models.whereType<ClassModel>().toList();
        expect(itemsModels.length, 1);
        final itemsModel = itemsModels.single;

        // ListModel.content points to the items ClassModel.
        expect(identical(tracerTrace.content, itemsModel), isTrue);

        // The items ClassModel has a property 'trace' whose model is
        // identical to the registered TracerTrace ListModel.
        final traceProp = itemsModel.properties.firstWhere(
          (p) => p.name == 'trace',
        );
        expect(identical(traceProp.model, tracerTrace), isTrue);
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

      // For bare ref cycles, one alias wraps the other and the chain
      // terminates at AnyModel (since bare ref cycles have no concrete type).
      // AliasA (processed first) wraps AliasB.
      final aliasAModel = aliasA as AliasModel;
      final aliasBModel = aliasB as AliasModel;

      // AliasA wraps AliasB.
      expect(aliasAModel.model, isA<AliasModel>());
      expect((aliasAModel.model as AliasModel).name, 'AliasB');

      // AliasB keeps its AnyModel terminal to break the cycle,
      // confirming the cycle terminates rather than looping infinitely.
      expect(aliasBModel.model, isA<AnyModel>());
    });
  });

  group('oneOf+allOf discriminated polymorphism cycle prevention', () {
    test(
      'Shape oneOf [Circle], Circle allOf [Shape] produces acyclic graph',
      () {
        const spec = {
          'openapi': '3.0.0',
          'info': {'title': 'Test API', 'version': '1.0.0'},
          'paths': <String, dynamic>{},
          'components': {
            'schemas': {
              'Shape': {
                'oneOf': [
                  {r'$ref': '#/components/schemas/Circle'},
                ],
                'discriminator': {
                  'propertyName': 'type',
                },
              },
              'Circle': {
                'allOf': [
                  {r'$ref': '#/components/schemas/Shape'},
                  {
                    'type': 'object',
                    'properties': {
                      'radius': {'type': 'number'},
                    },
                  },
                ],
              },
            },
          },
        };

        final api = Importer().import(spec);

        final shape = api.models.firstWhere(
          (m) => m is NamedModel && m.name == 'Shape',
        ) as OneOfModel;
        final circle = api.models.firstWhere(
          (m) => m is NamedModel && m.name == 'Circle',
        ) as AllOfModel;

        // Shape's oneOf contains Circle.
        expect(
          shape.models.any((m) => identical(m.model, circle)),
          isTrue,
        );

        // Circle's allOf does NOT contain Shape (back-edge skipped).
        expect(
          circle.models.any((m) => identical(m, shape)),
          isFalse,
        );

        // Circle only contains the inline class with radius.
        expect(circle.models.length, 1);
        expect(circle.models.first, isA<ClassModel>());
        final inlineClass = circle.models.first as ClassModel;
        final radiusProp = inlineClass.properties.firstWhere(
          (p) => p.name == 'radius',
        );
        expect(radiusProp.model, isA<NumberModel>());

        // encodingShape works without stack overflow.
        expect(shape.encodingShape, EncodingShape.complex);
        expect(circle.encodingShape, EncodingShape.complex);
      },
    );

    test(
      'multi-child: Shape oneOf [Circle, Rectangle] produces acyclic graph',
      () {
        const spec = {
          'openapi': '3.0.0',
          'info': {'title': 'Test API', 'version': '1.0.0'},
          'paths': <String, dynamic>{},
          'components': {
            'schemas': {
              'Shape': {
                'oneOf': [
                  {r'$ref': '#/components/schemas/Circle'},
                  {r'$ref': '#/components/schemas/Rectangle'},
                ],
                'discriminator': {
                  'propertyName': 'type',
                },
              },
              'Circle': {
                'allOf': [
                  {r'$ref': '#/components/schemas/Shape'},
                  {
                    'type': 'object',
                    'properties': {
                      'radius': {'type': 'number'},
                    },
                  },
                ],
              },
              'Rectangle': {
                'allOf': [
                  {r'$ref': '#/components/schemas/Shape'},
                  {
                    'type': 'object',
                    'properties': {
                      'width': {'type': 'number'},
                      'height': {'type': 'number'},
                    },
                  },
                ],
              },
            },
          },
        };

        final api = Importer().import(spec);

        final shape = api.models.firstWhere(
          (m) => m is NamedModel && m.name == 'Shape',
        ) as OneOfModel;
        final circle = api.models.firstWhere(
          (m) => m is NamedModel && m.name == 'Circle',
        ) as AllOfModel;
        final rectangle = api.models.firstWhere(
          (m) => m is NamedModel && m.name == 'Rectangle',
        ) as AllOfModel;

        // Shape contains both Circle and Rectangle.
        expect(shape.models.length, 2);
        expect(
          shape.models.any((m) => identical(m.model, circle)),
          isTrue,
        );
        expect(
          shape.models.any((m) => identical(m.model, rectangle)),
          isTrue,
        );

        // Neither Circle nor Rectangle contains Shape.
        expect(
          circle.models.any((m) => identical(m, shape)),
          isFalse,
        );
        expect(
          rectangle.models.any((m) => identical(m, shape)),
          isFalse,
        );

        // Each contains only its inline class.
        expect(circle.models.length, 1);
        expect(rectangle.models.length, 1);

        // encodingShape works without stack overflow.
        expect(shape.encodingShape, EncodingShape.complex);
        expect(circle.encodingShape, EncodingShape.complex);
        expect(rectangle.encodingShape, EncodingShape.complex);
      },
    );

    test('discriminator values are preserved', () {
      const spec = {
        'openapi': '3.0.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Shape': {
              'oneOf': [
                {r'$ref': '#/components/schemas/Circle'},
                {r'$ref': '#/components/schemas/Rectangle'},
              ],
              'discriminator': {
                'propertyName': 'shapeType',
                'mapping': {
                  'circle': '#/components/schemas/Circle',
                  'rect': '#/components/schemas/Rectangle',
                },
              },
            },
            'Circle': {
              'allOf': [
                {r'$ref': '#/components/schemas/Shape'},
                {
                  'type': 'object',
                  'properties': {
                    'radius': {'type': 'number'},
                  },
                },
              ],
            },
            'Rectangle': {
              'allOf': [
                {r'$ref': '#/components/schemas/Shape'},
                {
                  'type': 'object',
                  'properties': {
                    'width': {'type': 'number'},
                  },
                },
              ],
            },
          },
        },
      };

      final api = Importer().import(spec);

      final shape = api.models.firstWhere(
        (m) => m is NamedModel && m.name == 'Shape',
      ) as OneOfModel;

      expect(shape.discriminator, 'shapeType');

      final circleEntry = shape.models.firstWhere(
        (m) => m.discriminatorValue == 'circle',
      );
      expect(circleEntry.model, isA<AllOfModel>());
      expect(
        (circleEntry.model as AllOfModel).name,
        'Circle',
      );

      final rectEntry = shape.models.firstWhere(
        (m) => m.discriminatorValue == 'rect',
      );
      expect(rectEntry.model, isA<AllOfModel>());
      expect(
        (rectEntry.model as AllOfModel).name,
        'Rectangle',
      );
    });

    test(
      'anyOf+allOf polymorphism cycle is broken',
      () {
        const spec = {
          'openapi': '3.0.0',
          'info': {'title': 'Test API', 'version': '1.0.0'},
          'paths': <String, dynamic>{},
          'components': {
            'schemas': {
              'Vehicle': {
                'anyOf': [
                  {r'$ref': '#/components/schemas/Car'},
                ],
              },
              'Car': {
                'allOf': [
                  {r'$ref': '#/components/schemas/Vehicle'},
                  {
                    'type': 'object',
                    'properties': {
                      'doors': {'type': 'integer'},
                    },
                  },
                ],
              },
            },
          },
        };

        final api = Importer().import(spec);

        final vehicle = api.models.firstWhere(
          (m) => m is NamedModel && m.name == 'Vehicle',
        ) as AnyOfModel;
        final car = api.models.firstWhere(
          (m) => m is NamedModel && m.name == 'Car',
        ) as AllOfModel;

        // Vehicle contains Car.
        expect(
          vehicle.models.any((m) => identical(m.model, car)),
          isTrue,
        );

        // Car does NOT contain Vehicle.
        expect(
          car.models.any((m) => identical(m, vehicle)),
          isFalse,
        );

        // encodingShape works without stack overflow.
        expect(vehicle.encodingShape, EncodingShape.complex);
        expect(car.encodingShape, EncodingShape.complex);
      },
    );

    test(
      'deep polymorphism: Base oneOf [Mid], Mid allOf [Base], '
      'Mid oneOf [Leaf], Leaf allOf [Mid]',
      () {
        const spec = {
          'openapi': '3.0.0',
          'info': {'title': 'Test API', 'version': '1.0.0'},
          'paths': <String, dynamic>{},
          'components': {
            'schemas': {
              'Base': {
                'oneOf': [
                  {r'$ref': '#/components/schemas/Mid'},
                ],
              },
              'Mid': {
                'allOf': [
                  {r'$ref': '#/components/schemas/Base'},
                  {
                    'oneOf': [
                      {r'$ref': '#/components/schemas/Leaf'},
                    ],
                  },
                ],
              },
              'Leaf': {
                'allOf': [
                  {r'$ref': '#/components/schemas/Mid'},
                  {
                    'type': 'object',
                    'properties': {
                      'value': {'type': 'string'},
                    },
                  },
                ],
              },
            },
          },
        };

        final api = Importer().import(spec);

        // All three schemas should be present.
        final base = api.models.firstWhere(
          (m) => m is NamedModel && m.name == 'Base',
        ) as OneOfModel;
        final mid = api.models.firstWhere(
          (m) => m is NamedModel && m.name == 'Mid',
        ) as AllOfModel;
        final leaf = api.models.firstWhere(
          (m) => m is NamedModel && m.name == 'Leaf',
        ) as AllOfModel;

        // No stack overflow on encodingShape.
        expect(base.encodingShape, isNotNull);
        expect(mid.encodingShape, isNotNull);
        expect(leaf.encodingShape, isNotNull);
      },
    );

    test(
      'mutual allOf cycle: NodeA allOf [NodeB], NodeB allOf [NodeA]',
      () {
        const spec = {
          'openapi': '3.0.0',
          'info': {'title': 'Test API', 'version': '1.0.0'},
          'paths': <String, dynamic>{},
          'components': {
            'schemas': {
              'NodeA': {
                'allOf': [
                  {r'$ref': '#/components/schemas/NodeB'},
                  {
                    'type': 'object',
                    'properties': {
                      'aField': {'type': 'string'},
                    },
                    'required': ['aField'],
                  },
                ],
              },
              'NodeB': {
                'allOf': [
                  {r'$ref': '#/components/schemas/NodeA'},
                  {
                    'type': 'object',
                    'properties': {
                      'bField': {'type': 'integer'},
                    },
                    'required': ['bField'],
                  },
                ],
              },
            },
          },
        };

        final api = Importer().import(spec);

        final nodeA = api.models.firstWhere(
          (m) => m is NamedModel && m.name == 'NodeA',
        ) as AllOfModel;
        final nodeB = api.models.firstWhere(
          (m) => m is NamedModel && m.name == 'NodeB',
        ) as AllOfModel;

        // One of the back-edges was skipped to break the cycle.
        // NodeA references NodeB (forward), NodeB's ref to NodeA
        // is skipped (back-edge).
        final nodeAContainsNodeB = nodeA.models.any(
          (m) => identical(m, nodeB),
        );
        final nodeBContainsNodeA = nodeB.models.any(
          (m) => identical(m, nodeA),
        );

        // Exactly one direction is kept, the other is skipped.
        expect(
          nodeAContainsNodeB || nodeBContainsNodeA,
          isTrue,
        );
        expect(
          nodeAContainsNodeB && nodeBContainsNodeA,
          isFalse,
        );

        // encodingShape works without stack overflow.
        expect(nodeA.encodingShape, EncodingShape.complex);
        expect(nodeB.encodingShape, EncodingShape.complex);
      },
    );
  });
}
