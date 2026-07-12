import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/tonik_parse.dart';

Map<String, dynamic> specWithSchemas(Map<String, dynamic> schemas) => {
  'openapi': '3.0.0',
  'info': {'title': 'Test', 'version': '1.0.0'},
  'paths': <String, dynamic>{},
  'components': {'schemas': schemas},
};

Map<String, dynamic> classSchema({required Object? additionalProperties}) => {
  'type': 'object',
  'properties': {
    'name': {'type': 'string'},
  },
  if (additionalProperties != null)
    'additionalProperties': additionalProperties,
};

void main() {
  group('additional-properties policy import', () {
    test('omitted keyword imports as implicit Any policy', () {
      final api = Importer().import(
        specWithSchemas({'Item': classSchema(additionalProperties: null)}),
      );
      final model = api.models.whereType<ClassModel>().first;

      final policy =
          model.additionalPropertiesPolicy as AllowedAdditionalProperties;
      expect(policy.valueModel, isA<AnyModel>());
      expect(policy.origin, AdditionalPropertiesOrigin.implicitDefault);
    });

    test('true imports as explicit Any policy', () {
      final api = Importer().import(
        specWithSchemas({'Item': classSchema(additionalProperties: true)}),
      );
      final model = api.models.whereType<ClassModel>().first;

      final policy =
          model.additionalPropertiesPolicy as AllowedAdditionalProperties;
      expect(policy.valueModel, isA<AnyModel>());
      expect(policy.origin, AdditionalPropertiesOrigin.explicit);
    });

    test('empty schema imports as explicit Any policy', () {
      final api = Importer().import(
        specWithSchemas({
          'Item': classSchema(additionalProperties: <String, dynamic>{}),
        }),
      );
      final model = api.models.whereType<ClassModel>().first;

      final policy =
          model.additionalPropertiesPolicy as AllowedAdditionalProperties;
      expect(policy.valueModel, isA<AnyModel>());
      expect(policy.origin, AdditionalPropertiesOrigin.explicit);
    });

    test('typed schema imports as explicit typed policy', () {
      final api = Importer().import(
        specWithSchemas({
          'Item': classSchema(additionalProperties: {'type': 'integer'}),
        }),
      );
      final model = api.models.whereType<ClassModel>().first;

      final policy =
          model.additionalPropertiesPolicy as AllowedAdditionalProperties;
      expect(policy.valueModel, isA<IntegerModel>());
      expect(policy.origin, AdditionalPropertiesOrigin.explicit);
    });

    test('typed nullable schema imports a nullable policy value model', () {
      final api = Importer().import(
        specWithSchemas({
          'Item': classSchema(
            additionalProperties: {'type': 'string', 'nullable': true},
          ),
        }),
      );
      final model = api.models.whereType<ClassModel>().first;

      final policy =
          model.additionalPropertiesPolicy as AllowedAdditionalProperties;
      expect(policy.valueModel.isEffectivelyNullable, isTrue);
    });

    test('false imports as forbidden policy', () {
      final api = Importer().import(
        specWithSchemas({'Item': classSchema(additionalProperties: false)}),
      );
      final model = api.models.whereType<ClassModel>().first;

      expect(
        model.additionalPropertiesPolicy,
        const ForbiddenAdditionalProperties(),
      );
    });

    test('allOf sibling additionalProperties imports as explicit typed '
        'policy on the composite', () {
      final api = Importer().import(
        specWithSchemas({
          'Base': classSchema(additionalProperties: null),
          'Extended': {
            'allOf': [
              {r'$ref': '#/components/schemas/Base'},
            ],
            'additionalProperties': {'type': 'string'},
          },
        }),
      );
      final model = api.models.whereType<AllOfModel>().first;

      final policy =
          model.additionalPropertiesPolicy as AllowedAdditionalProperties;
      expect(policy.valueModel, isA<StringModel>());
      expect(policy.origin, AdditionalPropertiesOrigin.explicit);
    });

    test('allOf without sibling additionalProperties imports as implicit '
        'Any policy', () {
      final api = Importer().import(
        specWithSchemas({
          'Base': classSchema(additionalProperties: null),
          'Extended': {
            'allOf': [
              {r'$ref': '#/components/schemas/Base'},
            ],
          },
        }),
      );
      final model = api.models.whereType<AllOfModel>().first;

      final policy =
          model.additionalPropertiesPolicy as AllowedAdditionalProperties;
      expect(policy.valueModel, isA<AnyModel>());
      expect(policy.origin, AdditionalPropertiesOrigin.implicitDefault);
    });
  });
}
