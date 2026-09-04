import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/src/example_importer.dart';
import 'package:tonik_parse/src/model/open_api_object.dart';
import 'package:tonik_parse/src/model/schema.dart';
import 'package:tonik_parse/src/model_importer.dart';

ModelImporter importerFor(Map<String, dynamic> schemas) {
  final document = OpenApiObject.fromJson({
    'openapi': '3.1.0',
    'info': {'title': 'Lookup tests', 'version': '1'},
    'paths': <String, dynamic>{},
    'components': {'schemas': schemas},
  });
  return ModelImporter(
    document,
    exampleImporter: ExampleImporter(openApiObject: document),
  )..import();
}

Model named(ModelImporter importer, String name) => importer.models.firstWhere(
  (model) => model is NamedModel && model.name == name,
);

Schema ref(String path) => Schema.fromJson({r'$ref': path});

void main() {
  test('forward, repeated and recursive references share populated shells', () {
    final importer = importerFor({
      'Before': {
        'properties': {
          'first': {r'$ref': '#/components/schemas/Node'},
          'second': {r'$ref': '#/components/schemas/Node'},
        },
      },
      'Node': {
        'properties': {
          'next': {r'$ref': '#/components/schemas/Node'},
          'parent': {r'$ref': '#/components/schemas/Before'},
        },
      },
    });
    final before = named(importer, 'Before') as ClassModel;
    final node = named(importer, 'Node') as ClassModel;
    expect(before.properties.map((p) => p.model), everyElement(same(node)));
    expect(node.properties.first.model, same(node));
    expect(node.properties.last.model, same(before));
    expect(
      importer.importSchema(
        ref('#/components/schemas/Node'),
        Context.initial().push('response'),
      ),
      same(node),
    );
  });

  test('multi-type removal restores the original shell at the end', () {
    final importer = importerFor({
      'Before': {
        'properties': {
          'value': {r'$ref': '#/components/schemas/Choice'},
        },
      },
      'Choice': {
        'type': ['string', 'integer'],
      },
      'After': {'type': 'boolean'},
    });
    final choice = named(importer, 'Choice') as OneOfModel;
    expect(
      (named(importer, 'Before') as ClassModel).properties.single.model,
      same(choice),
    );
    expect(choice.models.map((m) => m.model), [
      isA<StringModel>(),
      isA<IntegerModel>(),
    ]);
    expect(importer.models.whereType<NamedModel>().map((m) => m.name), [
      'Before',
      'After',
      'Choice',
    ]);
  });

  test(r'$ref sibling replacement preserves old references and new lookup', () {
    final importer = importerFor({
      'Before': {
        'properties': {
          'value': {r'$ref': '#/components/schemas/Extended'},
        },
      },
      'Extended': {
        r'$ref': '#/components/schemas/Base',
        'properties': {
          'extra': {'type': 'integer'},
        },
      },
      'Base': {
        'properties': {
          'text': {'type': 'string'},
        },
      },
      'After': {
        'properties': {
          'value': {r'$ref': '#/components/schemas/Extended'},
        },
      },
    });
    final oldShell =
        (named(importer, 'Before') as ClassModel).properties.single.model
            as AliasModel;
    final replacement = named(importer, 'Extended') as AllOfModel;
    expect(oldShell.model, same(replacement));
    expect(importer.models.contains(oldShell), isFalse);
    expect(
      (named(importer, 'After') as ClassModel).properties.single.model,
      same(replacement),
    );
    expect(replacement.models.first, same(named(importer, 'Base')));
  });

  test(r'$defs alias removal preserves the existing shell reference', () {
    final importer = importerFor({
      'Before': {
        'properties': {
          'value': {r'$ref': '#/components/schemas/Alias'},
        },
      },
      'Alias': {r'$ref': r'#/components/schemas/Namespace/$defs/Value'},
      'Namespace': {
        r'$defs': {
          'Value': {'type': 'string'},
        },
      },
    });
    final oldShell =
        (named(importer, 'Before') as ClassModel).properties.single.model
            as AliasModel;
    final registered = named(importer, 'Alias') as AliasModel;
    expect(oldShell, isNot(same(registered)));
    expect(oldShell.model, same(registered.model));
    expect(oldShell.model, same(named(importer, 'Value')));
    expect(importer.models.contains(oldShell), isFalse);
  });

  // Characterize the current name-only lookup. Context-aware resolution is
  // deliberately outside this optimization.
  test(r'component names retain precedence over overlapping $defs names', () {
    final importer = importerFor({
      'Value': {'type': 'string'},
      'Namespace': {
        r'$defs': {
          'Value': {'type': 'integer'},
        },
      },
    });
    final component = named(importer, 'Value');
    expect(
      importer.importSchema(
        ref(r'#/components/schemas/Namespace/$defs/Value'),
        Context.initial().push('response'),
      ),
      same(component),
    );
  });

  test(r'overlapping nested $defs retain the first imported name', () {
    final importer = importerFor({
      'Namespace': {
        r'$defs': {
          'Outer': {
            r'$defs': {
              'Value': {'type': 'string'},
            },
          },
          'Value': {'type': 'integer'},
        },
      },
    });
    final first = importer.importPropertySchema(
      ref(r'#/components/schemas/Namespace/$defs/Outer/$defs/Value'),
      Context.initial().push('first'),
    );
    final second = importer.importSchema(
      ref(r'#/components/schemas/Namespace/$defs/Value'),
      Context.initial().push('second'),
    );
    expect(second, same(first));
    expect((first as AliasModel).model, isA<StringModel>());
  });

  test(
    r'bare $defs cycles keep completed first matches ahead of placeholders',
    () {
      final importer = importerFor({
        'Namespace': {
          r'$defs': {
            'A': {r'$ref': r'#/components/schemas/Namespace/$defs/B'},
            'B': {r'$ref': r'#/components/schemas/Namespace/$defs/A'},
          },
        },
      });
      final schema = ref(r'#/components/schemas/Namespace/$defs/A');
      final first = importer.importSchema(
        schema,
        Context.initial().push('first'),
      );
      final second = importer.importSchema(
        schema,
        Context.initial().push('second'),
      );
      expect(second, same(first));
      expect(first.resolved, isA<AnyModel>());
      final duplicates = importer.models.whereType<NamedModel>().where(
        (m) => m.name == 'A',
      );
      expect(duplicates.length, greaterThan(1));
      expect(first, same(duplicates.first));
    },
  );

  test(
    'resolved recursive map placeholders never shadow the completed map',
    () {
      final importer = importerFor({
        'Namespace': {
          r'$defs': {
            'Recursive': {
              'type': 'object',
              'additionalProperties': {
                r'$ref': r'#/components/schemas/Namespace/$defs/Recursive',
              },
            },
          },
        },
      });
      final schema = ref(r'#/components/schemas/Namespace/$defs/Recursive');
      final model =
          importer.importSchema(schema, Context.initial().push('map'))
              as MapModel;
      final placeholder = model.valueModel as AliasModel;
      expect(placeholder.model, same(model));
      expect(importer.models.contains(placeholder), isFalse);
      expect(named(importer, 'Recursive'), same(model));
      expect(
        importer.importSchema(schema, Context.initial().push('again')),
        same(model),
      );
    },
  );

  test(
    're-registering an old shell does not shadow its earlier replacement',
    () {
      final importer = importerFor({
        'Holder': {
          'oneOf': [
            {r'$ref': '#/components/schemas/Extended'},
          ],
        },
        'Extended': {
          r'$ref': '#/components/schemas/Base',
          'properties': {
            'extra': {'type': 'integer'},
          },
        },
        'Base': {'type': 'string'},
        'Reuse': {
          'oneOf': [
            {r'$ref': '#/components/schemas/Holder'},
          ],
        },
        'Last': {
          'properties': {
            'value': {r'$ref': '#/components/schemas/Extended'},
          },
        },
      });
      final oldShell =
          (named(importer, 'Holder') as OneOfModel).models.single.model
              as AliasModel;
      final replacement = named(importer, 'Extended') as AllOfModel;
      expect(oldShell.model, same(replacement));
      expect(
        importer.models.whereType<NamedModel>().where(
          (m) => m.name == 'Extended',
        ),
        [same(replacement), same(oldShell)],
      );
      expect(
        (named(importer, 'Last') as ClassModel).properties.single.model,
        same(replacement),
      );
    },
  );

  test(
    'anonymous schemas remain distinct and named collections are reused',
    () {
      final importer = importerFor({
        'Items': {
          'type': 'array',
          'items': {'type': 'string'},
        },
        'Mapping': {
          'type': 'object',
          'additionalProperties': {'type': 'integer'},
        },
        'Alias': {r'$ref': '#/components/schemas/Items'},
      });
      final context = Context.initial().push('inline');
      final schema = Schema.fromJson({
        'properties': {
          'value': {'type': 'string'},
        },
      });
      final first = importer.importSchema(schema, context);
      final second = importer.importSchema(schema, context);
      expect(first, isNot(same(second)));
      expect(importer.models, containsAll([first, second]));
      expect(
        (named(importer, 'Alias') as AliasModel).model,
        same(named(importer, 'Items')),
      );
      for (final name in ['Items', 'Mapping']) {
        expect(
          importer.importPropertySchema(
            ref('#/components/schemas/$name'),
            context,
          ),
          same(named(importer, name)),
        );
      }
    },
  );

  test(
    'repeated imports reset lookups and preserve deterministic ordering',
    () {
      final importer = importerFor({
        'Choice': {
          'type': ['string', 'integer'],
        },
        'Node': {
          'properties': {
            'next': {r'$ref': '#/components/schemas/Node'},
          },
        },
        'Namespace': {
          r'$defs': {
            'Late': {'type': 'string'},
          },
        },
      });
      final originalModels = importer.models.toList();
      final originalOrder = originalModels
          .whereType<NamedModel>()
          .map(
            (m) => (m.name, m.context),
          )
          .toList();
      final lateRef = ref(r'#/components/schemas/Namespace/$defs/Late');
      final context = Context.initial().push('response');
      final lateModel = importer.importSchema(lateRef, context);
      importer.import();
      expect(
        importer.models.whereType<NamedModel>().map(
          (m) => (m.name, m.context),
        ),
        originalOrder,
      );
      for (final model in importer.models) {
        expect(originalModels, isNot(contains(same(model))));
      }
      final node = named(importer, 'Node') as ClassModel;
      expect(node.properties.single.model, same(node));
      final newLateModel = importer.importSchema(lateRef, context);
      expect(newLateModel, isNot(same(lateModel)));
      expect(
        importer.importPropertySchema(lateRef, context),
        same(newLateModel),
      );
    },
  );

  test(
    'missing and unsupported references retain their errors after import',
    () {
      final importer = importerFor({});
      final context = Context.initial().push('response');
      for (final path in [
        '#/components/schemas/Missing',
        r'#/components/schemas/Namespace/$defs/Missing',
      ]) {
        expect(
          () => importer.importSchema(ref(path), context),
          throwsArgumentError,
        );
        expect(
          () => importer.importPropertySchema(ref(path), context),
          throwsArgumentError,
        );
      }
      expect(
        () => importer.importSchema(ref('other.json#/Schema'), context),
        throwsUnimplementedError,
      );
      expect(
        () => importer.importPropertySchema(ref('other.json#/Schema'), context),
        throwsUnimplementedError,
      );
    },
  );
}
