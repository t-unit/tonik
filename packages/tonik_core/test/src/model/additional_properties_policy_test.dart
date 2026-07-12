import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';

void main() {
  late Context context;

  setUp(() {
    context = Context.initial();
  });

  group('AdditionalPropertiesPolicy equality', () {
    test('allowed policies with same value model and origin are equal', () {
      final valueModel = StringModel(context: context);
      final a = AllowedAdditionalProperties(
        valueModel: valueModel,
        origin: AdditionalPropertiesOrigin.explicit,
      );
      final b = AllowedAdditionalProperties(
        valueModel: valueModel,
        origin: AdditionalPropertiesOrigin.explicit,
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('allowed policies with different origins are not equal', () {
      final valueModel = AnyModel(context: context);
      final implicit = AllowedAdditionalProperties(
        valueModel: valueModel,
        origin: AdditionalPropertiesOrigin.implicitDefault,
      );
      final explicit = AllowedAdditionalProperties(
        valueModel: valueModel,
        origin: AdditionalPropertiesOrigin.explicit,
      );

      expect(implicit, isNot(explicit));
    });

    test('forbidden policies are equal', () {
      expect(
        const ForbiddenAdditionalProperties(),
        const ForbiddenAdditionalProperties(),
      );
    });

    test('forbidden and allowed policies are not equal', () {
      expect(
        const ForbiddenAdditionalProperties(),
        isNot(
          AllowedAdditionalProperties(
            valueModel: AnyModel(context: context),
            origin: AdditionalPropertiesOrigin.explicit,
          ),
        ),
      );
    });
  });

  group('ClassModel additional-properties policy', () {
    ClassModel classModel({
      AdditionalProperties? additionalProperties,
      AdditionalPropertiesPolicy? additionalPropertiesPolicy,
    }) => ClassModel(
      properties: const [],
      context: context,
      isDeprecated: false,
      examples: const [],
      additionalProperties: additionalProperties,
      additionalPropertiesPolicy: additionalPropertiesPolicy,
    );

    test('omitted legacy additional properties yields implicit Any policy', () {
      final model = classModel();

      final policy =
          model.additionalPropertiesPolicy as AllowedAdditionalProperties;
      expect(policy.valueModel, isA<AnyModel>());
      expect(policy.origin, AdditionalPropertiesOrigin.implicitDefault);
    });

    test(
      'unrestricted legacy additional properties yields explicit Any policy',
      () {
        final model = classModel(
          additionalProperties: const UnrestrictedAdditionalProperties(),
        );

        final policy =
            model.additionalPropertiesPolicy as AllowedAdditionalProperties;
        expect(policy.valueModel, isA<AnyModel>());
        expect(policy.origin, AdditionalPropertiesOrigin.explicit);
      },
    );

    test('typed legacy additional properties yields explicit typed policy', () {
      final valueModel = StringModel(context: context);
      final model = classModel(
        additionalProperties: TypedAdditionalProperties(valueModel: valueModel),
      );

      final policy =
          model.additionalPropertiesPolicy as AllowedAdditionalProperties;
      expect(policy.valueModel, valueModel);
      expect(policy.origin, AdditionalPropertiesOrigin.explicit);
    });

    test('legacy false yields forbidden policy', () {
      final model = classModel(
        additionalProperties: const NoAdditionalProperties(),
      );

      expect(
        model.additionalPropertiesPolicy,
        const ForbiddenAdditionalProperties(),
      );
    });

    test('legacy setter replaces the stored policy', () {
      final model = classModel()
        ..additionalProperties = const UnrestrictedAdditionalProperties();

      final policy =
          model.additionalPropertiesPolicy as AllowedAdditionalProperties;
      expect(policy.valueModel, isA<AnyModel>());
      expect(policy.origin, AdditionalPropertiesOrigin.explicit);
    });

    test('legacy getter projects implicit Any policy as null', () {
      expect(classModel().additionalProperties, isNull);
    });

    test('legacy getter projects explicit Any policy as unrestricted', () {
      final model = classModel(
        additionalPropertiesPolicy: AllowedAdditionalProperties(
          valueModel: AnyModel(context: context),
          origin: AdditionalPropertiesOrigin.explicit,
        ),
      );

      expect(
        model.additionalProperties,
        isA<UnrestrictedAdditionalProperties>(),
      );
    });

    test('legacy getter projects typed policy with its value model', () {
      final valueModel = IntegerModel(context: context);
      final model = classModel(
        additionalPropertiesPolicy: AllowedAdditionalProperties(
          valueModel: valueModel,
          origin: AdditionalPropertiesOrigin.explicit,
        ),
      );

      final legacy = model.additionalProperties! as TypedAdditionalProperties;
      expect(legacy.valueModel, valueModel);
    });

    test('legacy getter projects forbidden policy as no additional '
        'properties', () {
      final model = classModel(
        additionalPropertiesPolicy: const ForbiddenAdditionalProperties(),
      );

      expect(model.additionalProperties, isA<NoAdditionalProperties>());
    });

    test('explicit policy constructor argument wins over legacy argument', () {
      final model = classModel(
        additionalProperties: const NoAdditionalProperties(),
        additionalPropertiesPolicy: AllowedAdditionalProperties(
          valueModel: StringModel(context: context),
          origin: AdditionalPropertiesOrigin.explicit,
        ),
      );

      expect(
        model.additionalPropertiesPolicy,
        isA<AllowedAdditionalProperties>(),
      );
    });
  });

  group('AllOfModel additional-properties policy', () {
    AllOfModel allOfModel({AdditionalProperties? additionalProperties}) =>
        AllOfModel(
          models: {StringModel(context: context)},
          context: context,
          isDeprecated: false,
          examples: const [],
          additionalProperties: additionalProperties,
        );

    test('omitted legacy additional properties yields implicit Any policy', () {
      final model = allOfModel();

      final policy =
          model.additionalPropertiesPolicy as AllowedAdditionalProperties;
      expect(policy.valueModel, isA<AnyModel>());
      expect(policy.origin, AdditionalPropertiesOrigin.implicitDefault);
    });

    test('typed legacy additional properties yields explicit typed policy', () {
      final valueModel = StringModel(context: context);
      final model = allOfModel(
        additionalProperties: TypedAdditionalProperties(valueModel: valueModel),
      );

      final policy =
          model.additionalPropertiesPolicy as AllowedAdditionalProperties;
      expect(policy.valueModel, valueModel);
      expect(policy.origin, AdditionalPropertiesOrigin.explicit);
    });

    test('legacy setter replaces the stored policy', () {
      final model = allOfModel()
        ..additionalProperties = const NoAdditionalProperties();

      expect(
        model.additionalPropertiesPolicy,
        const ForbiddenAdditionalProperties(),
      );
    });
  });
}
