import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  group('additionalProperties parsing', () {
    test('typed AP with non-nullable string value', () {
      const spec = {
        'openapi': '3.0.0',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Tags': {
              'type': 'object',
              'properties': {
                'name': {'type': 'string'},
              },
              'additionalProperties': {'type': 'string'},
            },
          },
        },
      };

      final api = Importer().import(spec);
      final model = api.models.whereType<ClassModel>().first;

      expect(model.additionalProperties, isA<TypedAdditionalProperties>());
      final ap = model.additionalProperties! as TypedAdditionalProperties;
      expect(ap.valueModel, isA<StringModel>());
      expect(ap.valueModel.isEffectivelyNullable, isFalse);
    });

    test('typed AP with nullable string value', () {
      const spec = {
        'openapi': '3.0.0',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Tags': {
              'type': 'object',
              'properties': {
                'name': {'type': 'string'},
              },
              'additionalProperties': {'type': 'string', 'nullable': true},
            },
          },
        },
      };

      final api = Importer().import(spec);
      final model = api.models.whereType<ClassModel>().first;

      expect(model.additionalProperties, isA<TypedAdditionalProperties>());
      final ap = model.additionalProperties! as TypedAdditionalProperties;
      expect(ap.valueModel.isEffectivelyNullable, isTrue);
    });

    test('typed AP with nullable integer value', () {
      const spec = {
        'openapi': '3.0.0',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Counts': {
              'type': 'object',
              'properties': {
                'name': {'type': 'string'},
              },
              'additionalProperties': {'type': 'integer', 'nullable': true},
            },
          },
        },
      };

      final api = Importer().import(spec);
      final model = api.models.whereType<ClassModel>().first;

      expect(model.additionalProperties, isA<TypedAdditionalProperties>());
      final ap = model.additionalProperties! as TypedAdditionalProperties;
      expect(ap.valueModel.isEffectivelyNullable, isTrue);
    });

    test('empty schema AP treated as unrestricted', () {
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

      expect(
        model.additionalProperties,
        isA<UnrestrictedAdditionalProperties>(),
      );
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
      expect(mapModel.valueModel.isEffectivelyNullable, isTrue);
    });
  });
}
