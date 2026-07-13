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
      final a = AllowedAdditionalProperties(valueModel: valueModel);
      final b = AllowedAdditionalProperties(valueModel: valueModel);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('allowed policies with different origins are not equal', () {
      final valueModel = AnyModel(context: context);
      final implicit = AllowedAdditionalProperties(
        valueModel: valueModel,
        origin: AdditionalPropertiesOrigin.implicitDefault,
      );
      final explicit = AllowedAdditionalProperties(valueModel: valueModel);

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
          AllowedAdditionalProperties(valueModel: AnyModel(context: context)),
        ),
      );
    });
  });

  group('ClassModel additional-properties policy', () {
    ClassModel classModel({
      AdditionalPropertiesPolicy? additionalPropertiesPolicy,
    }) => ClassModel(
      properties: const [],
      context: context,
      isDeprecated: false,
      examples: const [],
      additionalPropertiesPolicy: additionalPropertiesPolicy,
    );

    test('an omitted policy defaults to the implicit Any policy', () {
      final model = classModel();

      final policy =
          model.additionalPropertiesPolicy as AllowedAdditionalProperties;
      expect(policy.valueModel, isA<AnyModel>());
      expect(policy.origin, AdditionalPropertiesOrigin.implicitDefault);
    });

    test('an explicit policy is stored as given', () {
      final policy = AllowedAdditionalProperties(
        valueModel: StringModel(context: context),
      );
      final model = classModel(additionalPropertiesPolicy: policy);

      expect(model.additionalPropertiesPolicy, policy);
    });

    test('the policy is replaceable for two-pass shell population', () {
      final model = classModel()
        ..additionalPropertiesPolicy = const ForbiddenAdditionalProperties();

      expect(
        model.additionalPropertiesPolicy,
        const ForbiddenAdditionalProperties(),
      );
    });
  });

  group('AllOfModel additional-properties policy', () {
    AllOfModel allOfModel({
      AdditionalPropertiesPolicy? additionalPropertiesPolicy,
    }) => AllOfModel(
      models: {StringModel(context: context)},
      context: context,
      isDeprecated: false,
      examples: const [],
      additionalPropertiesPolicy: additionalPropertiesPolicy,
    );

    test('an omitted policy defaults to the implicit Any policy', () {
      final model = allOfModel();

      final policy =
          model.additionalPropertiesPolicy as AllowedAdditionalProperties;
      expect(policy.valueModel, isA<AnyModel>());
      expect(policy.origin, AdditionalPropertiesOrigin.implicitDefault);
    });

    test('an explicit policy is stored as given', () {
      final policy = AllowedAdditionalProperties(
        valueModel: IntegerModel(context: context),
      );
      final model = allOfModel(additionalPropertiesPolicy: policy);

      expect(model.additionalPropertiesPolicy, policy);
    });

    test('the policy is replaceable for two-pass shell population', () {
      final model = allOfModel()
        ..additionalPropertiesPolicy = const ForbiddenAdditionalProperties();

      expect(
        model.additionalPropertiesPolicy,
        const ForbiddenAdditionalProperties(),
      );
    });
  });
}
