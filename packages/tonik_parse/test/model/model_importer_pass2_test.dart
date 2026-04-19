import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  group('pass 2 population methods', () {
    group('multi-type schema (top-level)', () {
      test('creates and populates a multi-type OneOfModel shell', () {
        const spec = {
          'openapi': '3.1.0',
          'info': {'title': 'Test API', 'version': '1.0.0'},
          'paths': <String, dynamic>{},
          'components': {
            'schemas': {
              'StringOrInt': {
                'type': ['string', 'integer'],
              },
            },
          },
        };

        final api = Importer().import(spec);

        final model = api.models.firstWhere(
          (m) => m is NamedModel && m.name == 'StringOrInt',
        );
        expect(model, isA<OneOfModel>());

        final oneOf = model as OneOfModel;
        expect(oneOf.name, 'StringOrInt');
        expect(oneOf.models.length, 2);
        expect(
          oneOf.models.map((m) => m.model).toList(),
          containsAll([isA<StringModel>(), isA<IntegerModel>()]),
        );
      });

      test('multi-type schema with null type is nullable', () {
        const spec = {
          'openapi': '3.1.0',
          'info': {'title': 'Test API', 'version': '1.0.0'},
          'paths': <String, dynamic>{},
          'components': {
            'schemas': {
              'NullableStringOrInt': {
                'type': ['string', 'integer', 'null'],
              },
            },
          },
        };

        final api = Importer().import(spec);

        final model = api.models.firstWhere(
          (m) => m is NamedModel && m.name == 'NullableStringOrInt',
        );
        expect(model, isA<OneOfModel>());

        final oneOf = model as OneOfModel;
        expect(oneOf.isNullable, isTrue);
        expect(oneOf.models.length, 2);
      });
    });

    group('pure map schema (top-level)', () {
      test('creates and populates a MapModel shell with typed value', () {
        const spec = {
          'openapi': '3.0.0',
          'info': {'title': 'Test API', 'version': '1.0.0'},
          'paths': <String, dynamic>{},
          'components': {
            'schemas': {
              'StringMap': {
                'additionalProperties': {'type': 'string'},
              },
            },
          },
        };

        final api = Importer().import(spec);

        final model = api.models.firstWhere(
          (m) => m is NamedModel && m.name == 'StringMap',
        );
        expect(model, isA<MapModel>());

        final mapModel = model as MapModel;
        expect(mapModel.name, 'StringMap');
        expect(mapModel.valueModel, isA<StringModel>());
      });

      test(
        'creates and populates MapModel with additionalProperties',
        () {
          const spec = {
            'openapi': '3.0.0',
            'info': {'title': 'Test API', 'version': '1.0.0'},
            'paths': <String, dynamic>{},
            'components': {
              'schemas': {
                'AnyMap': {
                  'additionalProperties': true,
                },
              },
            },
          };

          final api = Importer().import(spec);

          final model = api.models.firstWhere(
            (m) => m is NamedModel && m.name == 'AnyMap',
          );
          expect(model, isA<MapModel>());

          final mapModel = model as MapModel;
          expect(mapModel.valueModel, isA<AnyModel>());
        },
      );

      test('creates MapModel with ref value', () {
        const spec = {
          'openapi': '3.0.0',
          'info': {'title': 'Test API', 'version': '1.0.0'},
          'paths': <String, dynamic>{},
          'components': {
            'schemas': {
              'Widget': {
                'type': 'object',
                'properties': {
                  'id': {'type': 'integer'},
                },
              },
              'WidgetMap': {
                'additionalProperties': {
                  r'$ref': '#/components/schemas/Widget',
                },
              },
            },
          },
        };

        final api = Importer().import(spec);

        final model = api.models.firstWhere(
          (m) => m is NamedModel && m.name == 'WidgetMap',
        );
        expect(model, isA<MapModel>());

        final mapModel = model as MapModel;
        expect(mapModel.valueModel, isA<ClassModel>());
        expect((mapModel.valueModel as ClassModel).name, 'Widget');
      });
    });

    group('array schema (top-level)', () {
      test('creates and populates a ListModel shell with items', () {
        const spec = {
          'openapi': '3.0.0',
          'info': {'title': 'Test API', 'version': '1.0.0'},
          'paths': <String, dynamic>{},
          'components': {
            'schemas': {
              'IntList': {
                'type': 'array',
                'items': {'type': 'integer'},
              },
            },
          },
        };

        final api = Importer().import(spec);

        final model = api.models.firstWhere(
          (m) => m is NamedModel && m.name == 'IntList',
        );
        expect(model, isA<ListModel>());

        final listModel = model as ListModel;
        expect(listModel.name, 'IntList');
        expect(listModel.content, isA<IntegerModel>());
      });

      test('creates ListModel shell with no items as AnyModel', () {
        const spec = {
          'openapi': '3.0.0',
          'info': {'title': 'Test API', 'version': '1.0.0'},
          'paths': <String, dynamic>{},
          'components': {
            'schemas': {
              'OpenArray': {
                'type': 'array',
              },
            },
          },
        };

        final api = Importer().import(spec);

        final model = api.models.firstWhere(
          (m) => m is NamedModel && m.name == 'OpenArray',
        );
        expect(model, isA<ListModel>());

        final listModel = model as ListModel;
        expect(listModel.content, isA<AnyModel>());
      });

      test('creates ListModel with ref items', () {
        const spec = {
          'openapi': '3.0.0',
          'info': {'title': 'Test API', 'version': '1.0.0'},
          'paths': <String, dynamic>{},
          'components': {
            'schemas': {
              'Tag': {
                'type': 'object',
                'properties': {
                  'label': {'type': 'string'},
                },
              },
              'TagList': {
                'type': 'array',
                'items': {r'$ref': '#/components/schemas/Tag'},
              },
            },
          },
        };

        final api = Importer().import(spec);

        final model = api.models.firstWhere(
          (m) => m is NamedModel && m.name == 'TagList',
        );
        expect(model, isA<ListModel>());

        final listModel = model as ListModel;
        expect(listModel.content, isA<ClassModel>());
        expect((listModel.content as ClassModel).name, 'Tag');
      });
    });

    group('enum schema (no shell in pass 1)', () {
      test('string enum is created during pass 2 fallback', () {
        const spec = {
          'openapi': '3.0.0',
          'info': {'title': 'Test API', 'version': '1.0.0'},
          'paths': <String, dynamic>{},
          'components': {
            'schemas': {
              'Color': {
                'type': 'string',
                'enum': ['red', 'green', 'blue'],
              },
            },
          },
        };

        final api = Importer().import(spec);

        final model = api.models.firstWhere(
          (m) => m is NamedModel && m.name == 'Color',
        );
        expect(model, isA<EnumModel<String>>());

        final enumModel = model as EnumModel<String>;
        expect(
          enumModel.values.map((e) => e.value).toSet(),
          {'red', 'green', 'blue'},
        );
      });

      test('integer enum is created during pass 2 fallback', () {
        const spec = {
          'openapi': '3.0.0',
          'info': {'title': 'Test API', 'version': '1.0.0'},
          'paths': <String, dynamic>{},
          'components': {
            'schemas': {
              'Priority': {
                'type': 'integer',
                'enum': [1, 2, 3],
              },
            },
          },
        };

        final api = Importer().import(spec);

        final model = api.models.firstWhere(
          (m) => m is NamedModel && m.name == 'Priority',
        );
        expect(model, isA<EnumModel<int>>());

        final enumModel = model as EnumModel<int>;
        expect(enumModel.values.map((e) => e.value).toSet(), {1, 2, 3});
      });
    });

    group('number format branch in _createPrimitiveModel', () {
      test('top-level number schema without format creates NumberModel', () {
        const spec = {
          'openapi': '3.0.0',
          'info': {'title': 'Test API', 'version': '1.0.0'},
          'paths': <String, dynamic>{},
          'components': {
            'schemas': {
              'Measurement': {
                'type': 'number',
              },
            },
          },
        };

        final api = Importer().import(spec);

        final model = api.models.firstWhere(
          (m) => m is NamedModel && m.name == 'Measurement',
        );
        expect(model, isA<AliasModel>());

        final alias = model as AliasModel;
        expect(alias.model, isA<NumberModel>());
      });
    });

    group('contentEncoding string in _createPrimitiveModel', () {
      test(
        'top-level string with contentEncoding creates BinaryModel alias',
        () {
          const spec = {
            'openapi': '3.0.0',
            'info': {'title': 'Test API', 'version': '1.0.0'},
            'paths': <String, dynamic>{},
            'components': {
              'schemas': {
                'FileData': {
                  'type': 'string',
                  'contentEncoding': 'base64',
                },
              },
            },
          };

          final api = Importer().import(spec);

          final model = api.models.firstWhere(
            (m) => m is NamedModel && m.name == 'FileData',
          );
          expect(model, isA<AliasModel>());

          final alias = model as AliasModel;
          expect(alias.model, isA<BinaryModel>());
        },
      );
    });

    group('ClassModel shell with not schema', () {
      test('populates ClassModel shell and ignores not keyword', () {
        const spec = {
          'openapi': '3.0.0',
          'info': {'title': 'Test API', 'version': '1.0.0'},
          'paths': <String, dynamic>{},
          'components': {
            'schemas': {
              'Filtered': {
                'type': 'object',
                'properties': {
                  'name': {'type': 'string'},
                },
                'not': {'type': 'integer'},
              },
            },
          },
        };

        final api = Importer().import(spec);

        final model = api.models.firstWhere(
          (m) => m is NamedModel && m.name == 'Filtered',
        );
        expect(model, isA<ClassModel>());

        final classModel = model as ClassModel;
        expect(classModel.properties.length, 1);
        expect(classModel.properties.first.name, 'name');
        expect(classModel.properties.first.model, isA<StringModel>());
      });
    });

    group('_populateClassShell — empty property names', () {
      test('handles empty string property name without throwing', () {
        const spec = {
          'openapi': '3.0.0',
          'info': {'title': 'Test API', 'version': '1.0.0'},
          'paths': <String, dynamic>{},
          'components': {
            'schemas': {
              'WeirdProps': {
                'type': 'object',
                'properties': {
                  '': {'type': 'string'},
                  'normal': {'type': 'integer'},
                },
              },
            },
          },
        };

        final api = Importer().import(spec);

        final model = api.models.firstWhere(
          (m) => m is NamedModel && m.name == 'WeirdProps',
        );
        expect(model, isA<ClassModel>());

        final classModel = model as ClassModel;
        expect(classModel.properties.length, 2);
        expect(classModel.properties.map((p) => p.name), contains(''));
        expect(classModel.properties.map((p) => p.name), contains('normal'));
      });

      test('handles whitespace-only property name without throwing', () {
        const spec = {
          'openapi': '3.0.0',
          'info': {'title': 'Test API', 'version': '1.0.0'},
          'paths': <String, dynamic>{},
          'components': {
            'schemas': {
              'SpaceProps': {
                'type': 'object',
                'properties': {
                  ' ': {'type': 'boolean'},
                },
              },
            },
          },
        };

        final api = Importer().import(spec);

        final model = api.models.firstWhere(
          (m) => m is NamedModel && m.name == 'SpaceProps',
        );
        expect(model, isA<ClassModel>());

        final classModel = model as ClassModel;
        expect(classModel.properties.length, 1);
        expect(classModel.properties.first.name, ' ');
      });
    });

    group(r'_populateAliasShell — $defs resolution', () {
      test(r'top-level $ref to $defs is resolved during pass 2', () {
        const spec = {
          'openapi': '3.1.0',
          'info': {'title': 'Test API', 'version': '1.0.0'},
          'paths': <String, dynamic>{},
          'components': {
            'schemas': {
              'Outer': {
                'type': 'object',
                r'$defs': {
                  'Inner': {
                    'type': 'object',
                    'properties': {
                      'value': {'type': 'string'},
                    },
                  },
                },
                'properties': {
                  'child': {
                    r'$ref': r'#/components/schemas/Outer/$defs/Inner',
                  },
                },
              },
              'InnerAlias': {
                r'$ref': r'#/components/schemas/Outer/$defs/Inner',
              },
            },
          },
        };

        final api = Importer().import(spec);

        final innerAlias = api.models.firstWhere(
          (m) => m is NamedModel && m.name == 'InnerAlias',
        );
        expect(innerAlias, isA<AliasModel>());

        final alias = innerAlias as AliasModel;
        expect(alias.model, isA<ClassModel>());
      });
    });

    group('_populateAliasShell — structural siblings', () {
      test(
        r'$ref with properties sibling creates AllOfModel',
        () {
          const spec = {
            'openapi': '3.1.0',
            'info': {'title': 'Test API', 'version': '1.0.0'},
            'paths': <String, dynamic>{},
            'components': {
              'schemas': {
                'Base': {
                  'type': 'object',
                  'properties': {
                    'id': {'type': 'integer'},
                  },
                },
                'Extended': {
                  r'$ref': '#/components/schemas/Base',
                  'properties': {
                    'extra': {'type': 'string'},
                  },
                },
              },
            },
          };

          final api = Importer().import(spec);

          final extended = api.models.firstWhere(
            (m) => m is NamedModel && m.name == 'Extended',
          );

          // The shell is replaced by the AllOfModel from
          // _mergeRefWithStructuralSiblings.
          expect(extended, isA<AllOfModel>());

          final allOf = extended as AllOfModel;
          expect(allOf.name, 'Extended');
          expect(allOf.models.length, 2);

          // One model is the Base ClassModel, the other is the inline class.
          final baseRef = allOf.models.whereType<ClassModel>().firstWhere(
            (m) => m.name == 'Base',
          );
          expect(baseRef.properties.map((p) => p.name), contains('id'));

          final inlineClass = allOf.models.whereType<ClassModel>().firstWhere(
            (m) => m.name != 'Base',
          );
          expect(inlineClass.properties.map((p) => p.name), contains('extra'));
        },
      );
    });

    group('_populateAliasShell — error paths', () {
      test('throws UnimplementedError for non-local ref', () {
        const spec = {
          'openapi': '3.0.0',
          'info': {'title': 'Test API', 'version': '1.0.0'},
          'paths': <String, dynamic>{},
          'components': {
            'schemas': {
              'Remote': {
                r'$ref': 'https://example.com/schemas/Foo',
              },
            },
          },
        };

        expect(
          () => Importer().import(spec),
          throwsA(isA<UnimplementedError>()),
        );
      });

      test('throws ArgumentError for missing ref target', () {
        const spec = {
          'openapi': '3.0.0',
          'info': {'title': 'Test API', 'version': '1.0.0'},
          'paths': <String, dynamic>{},
          'components': {
            'schemas': {
              'Broken': {
                r'$ref': '#/components/schemas/DoesNotExist',
              },
            },
          },
        };

        expect(
          () => Importer().import(spec),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws ArgumentError for direct self-reference via pass 2', () {
        // This is the self-reference case caught in _populateAliasShell
        // (lines 474-477). The pass 1 _createShell skips this,
        // but the existing test already covers this throwing via
        // _resolveReference. However, the _populateAliasShell path at
        // line 474-476 is also a codepath. The self-ref check in _createShell
        // prevents the alias shell from being created, so _populateShell
        // falls through to the existingModel == null path, which calls
        // _resolveSchemaRef -> _resolveReference -> throws.
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
    });
  });
}
