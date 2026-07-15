import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  late Context context;

  setUp(() {
    context = Context.initial();
  });

  group('MapModel', () {
    test('has correct name and valueModel', () {
      final mapModel = MapModel(
        name: 'Tags',
        valueModel: StringModel(context: context),
        context: context,
        examples: const [],
      );

      expect(mapModel.name, 'Tags');
      expect(mapModel.valueModel, isA<StringModel>());
      expect(mapModel.isNullable, isFalse);
      expect(mapModel.isReadOnly, isFalse);
      expect(mapModel.isWriteOnly, isFalse);
    });

    test('encodingShape returns complex', () {
      final mapModel = MapModel(
        valueModel: StringModel(context: context),
        context: context,
        examples: const [],
      );

      expect(mapModel.encodingShape, EncodingShape.complex);
    });

    test('isEffectivelyNullable returns isNullable value', () {
      final nullableMap = MapModel(
        valueModel: StringModel(context: context),
        context: context,
        isNullable: true,
        examples: const [],
      );
      final nonNullableMap = MapModel(
        valueModel: StringModel(context: context),
        context: context,
        examples: const [],
      );

      expect(nullableMap.isEffectivelyNullable, isTrue);
      expect(nonNullableMap.isEffectivelyNullable, isFalse);
    });

    test('toString includes name and valueModel ref', () {
      final mapModel = MapModel(
        name: 'Tags',
        valueModel: StringModel(context: context),
        context: context,
        examples: const [],
      );

      expect(
        mapModel.toString(),
        'MapModel{name: Tags, nameOverride: null, '
        'valueModel: StringModel, isValueNullable: false, examples: []}',
      );
    });
  });

  group('ClassModel with additionalProperties', () {
    test('an omitted policy defaults to the implicit Any policy', () {
      final model = ClassModel(
        name: 'Test',
        properties: const [],
        context: context,
        isDeprecated: false,
        examples: const [],
      );

      final policy =
          model.additionalPropertiesPolicy as AllowedAdditionalProperties;
      expect(policy.origin, AdditionalPropertiesOrigin.implicitDefault);
    });

    test('toString includes the additional-properties policy', () {
      final model = ClassModel(
        name: 'Test',
        properties: const [],
        context: context,
        isDeprecated: false,
        additionalPropertiesPolicy: AllowedAdditionalProperties(
          valueModel: AnyModel(context: context),
        ),
        examples: const [],
      );

      expect(
        model.toString(),
        'ClassModel{name: Test, nameOverride: null, properties: [], '
        'additionalPropertiesPolicy: '
        'AllowedAdditionalProperties{origin: explicit, valueModel: AnyModel}, '
        'description: null, isDeprecated: false, examples: []}',
      );
    });
  });

  group('AllOfModel with additionalProperties', () {
    test('an omitted policy defaults to the implicit Any policy', () {
      final model = AllOfModel(
        name: 'Test',
        models: {StringModel(context: context)},
        context: context,
        isDeprecated: false,
        examples: const [],
      );

      final policy =
          model.additionalPropertiesPolicy as AllowedAdditionalProperties;
      expect(policy.origin, AdditionalPropertiesOrigin.implicitDefault);
    });

    test('toString includes the additional-properties policy', () {
      final model = AllOfModel(
        name: 'Test',
        models: {StringModel(context: context)},
        context: context,
        isDeprecated: false,
        additionalPropertiesPolicy: AllowedAdditionalProperties(
          valueModel: AnyModel(context: context),
        ),
        examples: const [],
      );

      expect(
        model.toString(),
        'AllOfModel{name: Test, nameOverride: null, models: {StringModel}, '
        'additionalPropertiesPolicy: '
        'AllowedAdditionalProperties{origin: explicit, valueModel: AnyModel}, '
        'description: null, isDeprecated: false, examples: []}',
      );
    });
  });

  group('NeverModel', () {
    test('isEffectivelyNullable returns isNullable value', () {
      final nullableNever = NeverModel(context: context, isNullable: true);
      final nonNullableNever = NeverModel(context: context, isNullable: false);

      expect(nullableNever.isEffectivelyNullable, isTrue);
      expect(nonNullableNever.isEffectivelyNullable, isFalse);
    });
  });
}
