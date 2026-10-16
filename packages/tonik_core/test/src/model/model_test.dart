import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  late Context context;

  setUp(() {
    context = Context.initial();
  });

  test(
    'date-time enum retains string behavior and identifies its model type',
    () {
      final model = DateTimeEnumModel(
        name: 'Timestamp',
        values: {
          const EnumEntry(
            value: '2026-09-06T12:00:00.1000+02:00',
            nameOverride: null,
          ),
        },
        isNullable: true,
        isDeprecated: false,
        context: context,
        examples: const [],
        nameOverride: null,
        description: null,
        defaultValue: null,
        fallbackValue: null,
        isReadOnly: false,
        isWriteOnly: false,
      );
      final alias = AliasModel(
        model: model,
        context: context,
        examples: const [],
        defaultValue: null,
        name: null,
        nameOverride: null,
        description: null,
        isDeprecated: false,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
      );

      expect(model, isA<EnumModel<String>>());
      expect(model.encodingShape, EncodingShape.simple);
      expect(model.isEffectivelyNullable, isTrue);
      expect(
        model.toString(),
        startsWith('DateTimeEnumModel{name: Timestamp,'),
      );
      expect(
        alias.toString(),
        contains('model: DateTimeEnumModel(Timestamp),'),
      );
    },
  );

  group('MapModel', () {
    test('has correct name and valueModel', () {
      final mapModel = MapModel(
        name: 'Tags',
        valueModel: StringModel(context: context),
        context: context,
        examples: const [],
        nameOverride: null,
        isNullable: false,
        isValueNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
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
        name: null,
        nameOverride: null,
        isNullable: false,
        isValueNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
      );

      expect(mapModel.encodingShape, EncodingShape.complex);
    });

    test('isEffectivelyNullable returns isNullable value', () {
      final nullableMap = MapModel(
        valueModel: StringModel(context: context),
        context: context,
        isNullable: true,
        examples: const [],
        name: null,
        nameOverride: null,
        isValueNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
      );
      final nonNullableMap = MapModel(
        valueModel: StringModel(context: context),
        context: context,
        examples: const [],
        name: null,
        nameOverride: null,
        isNullable: false,
        isValueNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
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
        nameOverride: null,
        isNullable: false,
        isValueNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
      );

      expect(
        mapModel.toString(),
        'MapModel{name: Tags, nameOverride: null, '
        'valueModel: StringModel, isValueNullable: false, examples: []}',
      );
    });
  });

  group('ClassModel with additionalProperties', () {
    test('a null policy resolves to the implicit Any policy', () {
      final model = ClassModel(
        name: 'Test',
        properties: const [],
        context: context,
        isDeprecated: false,
        examples: const [],
        nameOverride: null,
        description: null,
        additionalPropertiesPolicy: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
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
          origin: AdditionalPropertiesOrigin.explicit,
        ),
        examples: const [],
        nameOverride: null,
        description: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
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
    test('a null policy resolves to the implicit Any policy', () {
      final model = AllOfModel(
        name: 'Test',
        models: [StringModel(context: context)],
        context: context,
        isDeprecated: false,
        examples: const [],
        nameOverride: null,
        description: null,
        additionalPropertiesPolicy: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
        defaultValue: null,
      );

      final policy =
          model.additionalPropertiesPolicy as AllowedAdditionalProperties;
      expect(policy.origin, AdditionalPropertiesOrigin.implicitDefault);
    });

    test('toString includes the additional-properties policy', () {
      final model = AllOfModel(
        name: 'Test',
        models: [StringModel(context: context)],
        context: context,
        isDeprecated: false,
        additionalPropertiesPolicy: AllowedAdditionalProperties(
          valueModel: AnyModel(context: context),
          origin: AdditionalPropertiesOrigin.explicit,
        ),
        examples: const [],
        nameOverride: null,
        description: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
        defaultValue: null,
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
