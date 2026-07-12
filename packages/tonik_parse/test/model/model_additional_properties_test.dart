import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  group('additionalProperties parsing', () {
    test('empty schema AP imports as an explicit Any policy in '
        'OpenAPI 3.1', () {
      const spec = {
        'openapi': '3.1.0',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Flexible': {
              'type': 'object',
              'properties': {
                'name': {'type': 'string'},
              },
              'additionalProperties': <String, dynamic>{},
            },
          },
        },
      };

      final api = Importer().import(spec);
      final model = api.models.whereType<ClassModel>().first;

      final policy =
          model.additionalPropertiesPolicy as AllowedAdditionalProperties;
      expect(policy.valueModel, isA<AnyModel>());
      expect(policy.origin, AdditionalPropertiesOrigin.explicit);
    });

    test('pure map with nullable string value', () {
      const spec = {
        'openapi': '3.0.0',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'NullableStringMap': {
              'type': 'object',
              'additionalProperties': {'type': 'string', 'nullable': true},
            },
          },
        },
      };

      final api = Importer().import(spec);
      final model = api.models.first;
      expect(model, isA<MapModel>());
      final mapModel = model as MapModel;
      expect(mapModel.isValueNullable, isTrue);
      expect(mapModel.valueModel, isA<StringModel>());
    });

    test('inline pure map property sets isValueNullable when value '
        'is nullable', () {
      const spec = {
        'openapi': '3.0.0',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Container': {
              'type': 'object',
              'properties': {
                'lookup': {
                  'type': 'object',
                  'additionalProperties': {
                    'type': 'string',
                    'nullable': true,
                  },
                },
              },
            },
          },
        },
      };

      final api = Importer().import(spec);
      final container = api.models.whereType<ClassModel>().firstWhere(
        (m) => m.name == 'Container',
      );
      final lookup = container.properties.firstWhere((p) => p.name == 'lookup');

      expect(lookup.model, isA<MapModel>());
      final mapModel = lookup.model as MapModel;
      expect(mapModel.isValueNullable, isTrue);
      expect(mapModel.valueModel, isA<StringModel>());
    });
  });
}
