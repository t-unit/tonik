import 'package:test/test.dart';
import 'package:tonik_core/src/transformer/deprecation_handler.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  test('named primitive shells retain description and deprecation', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'UserId': {
            'type': 'string',
            'description': 'Legacy user identifier.',
            'deprecated': true,
          },
          'Count': {'type': 'integer'},
        },
      },
    });

    final id = api.models.whereType<AliasModel>().singleWhere(
      (model) => model.name == 'UserId',
    );
    final count = api.models.whereType<AliasModel>().singleWhere(
      (model) => model.name == 'Count',
    );
    expect(id.description, 'Legacy user identifier.');
    expect(id.isDeprecated, isTrue);
    expect(id.resolved, isA<StringModel>());
    expect(count.description, isNull);
    expect(count.isDeprecated, isFalse);
  });

  test('fresh and cached pointer primitive aliases retain annotations', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'Owner': {
            'type': 'object',
            'properties': {
              'count': {
                'type': 'integer',
                'description': 'Legacy count.',
                'deprecated': true,
              },
            },
            r'$defs': {
              'Id': {
                'type': 'string',
                'description': 'Legacy identifier.',
                'deprecated': true,
              },
            },
          },
          'Count': {r'$ref': '#/components/schemas/Owner/properties/count'},
          'Id': {r'$ref': r'#/components/schemas/Owner/$defs/Id'},
        },
      },
    });

    final count =
        api.models
                .whereType<AliasModel>()
                .singleWhere((model) => model.name == 'Count')
                .model
            as AliasModel;
    final id =
        api.models
                .whereType<AliasModel>()
                .singleWhere(
                  (model) => model.name == 'Id' && model.model is AliasModel,
                )
                .model
            as AliasModel;
    expect(count.description, 'Legacy count.');
    expect(count.isDeprecated, isTrue);
    expect(count.resolved, isA<IntegerModel>());
    expect(id.description, 'Legacy identifier.');
    expect(id.isDeprecated, isTrue);
    expect(id.resolved, isA<StringModel>());
  });

  test('schema exclusion applies to deprecated primitive aliases', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'LegacyId': {'type': 'string', 'deprecated': true},
          'CurrentId': {'type': 'integer'},
        },
      },
    });
    final filtered = const DeprecationHandler().handleSchemas(
      models: api.models,
      mode: DeprecatedHandling.exclude,
    );

    expect(filtered.whereType<AliasModel>().single.name, 'CurrentId');
  });

  test(
    'excluded aliases retain identity, defaults and read-write metadata',
    () {
      final api = Importer().import({
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'LegacyId': {
              'type': 'string',
              'deprecated': true,
              'readOnly': true,
              'default': 'fallback',
            },
            'LegacySecret': {
              'type': 'string',
              'deprecated': true,
              'writeOnly': true,
            },
            'Holder': {
              'type': 'object',
              'properties': {
                'id': {r'$ref': '#/components/schemas/LegacyId'},
                'secret': {r'$ref': '#/components/schemas/LegacySecret'},
              },
            },
          },
        },
      });
      final holder = api.models.whereType<ClassModel>().single;
      final id = holder.properties.first.model as AliasModel;
      final secret = holder.properties.last.model as AliasModel;
      final filtered = const DeprecationHandler().handleSchemas(
        models: api.models,
        mode: DeprecatedHandling.exclude,
      );

      expect(filtered.single, same(holder));
      expect(holder.properties.first.model, same(id));
      expect(holder.properties.last.model, same(secret));
      expect(id.name, isNull);
      expect(secret.name, isNull);
      expect(id.defaultValue, 'fallback');
      expect(id.isReadOnly, isTrue);
      expect(secret.isWriteOnly, isTrue);
      expect(id.resolved, isA<StringModel>());
      expect(secret.resolved, isA<StringModel>());
    },
  );
}
