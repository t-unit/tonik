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
      );

      expect(mapModel.encodingShape, EncodingShape.complex);
    });

    test('isEffectivelyNullable returns isNullable value', () {
      final nullableMap = MapModel(
        valueModel: StringModel(context: context),
        context: context,
        isNullable: true,
      );
      final nonNullableMap = MapModel(
        valueModel: StringModel(context: context),
        context: context,
      );

      expect(nullableMap.isEffectivelyNullable, isTrue);
      expect(nonNullableMap.isEffectivelyNullable, isFalse);
    });

    test('toString includes name and valueModel ref', () {
      final mapModel = MapModel(
        name: 'Tags',
        valueModel: StringModel(context: context),
        context: context,
      );

      expect(
        mapModel.toString(),
        'MapModel{name: Tags, nameOverride: null, valueModel: StringModel}',
      );
    });
  });

  group('AdditionalProperties', () {
    test('UnrestrictedAdditionalProperties can be instantiated', () {
      const ap = UnrestrictedAdditionalProperties();
      expect(ap, isA<AdditionalProperties>());
    });

    test('TypedAdditionalProperties holds valueModel', () {
      final ap = TypedAdditionalProperties(
        valueModel: StringModel(context: context),
      );
      expect(ap, isA<AdditionalProperties>());
      expect(ap.valueModel, isA<StringModel>());
    });

    test('NoAdditionalProperties can be instantiated', () {
      const ap = NoAdditionalProperties();
      expect(ap, isA<AdditionalProperties>());
    });
  });

  group('ClassModel with additionalProperties', () {
    test('additionalProperties defaults to null', () {
      final model = ClassModel(
        name: 'Test',
        properties: const [],
        context: context,
        isDeprecated: false,
      );

      expect(model.additionalProperties, isNull);
    });

    test('toString includes additionalProperties', () {
      final model = ClassModel(
        name: 'Test',
        properties: const [],
        context: context,
        isDeprecated: false,
        additionalProperties: const UnrestrictedAdditionalProperties(),
      );

      expect(
        model.toString(),
        'ClassModel{name: Test, nameOverride: null, properties: [], '
        "additionalProperties: Instance of 'UnrestrictedAdditionalProperties', "
        'description: null, isDeprecated: false}',
      );
    });
  });

  group('AllOfModel with additionalProperties', () {
    test('additionalProperties defaults to null', () {
      final model = AllOfModel(
        name: 'Test',
        models: {StringModel(context: context)},
        context: context,
        isDeprecated: false,
      );

      expect(model.additionalProperties, isNull);
    });

    test('toString includes additionalProperties', () {
      final model = AllOfModel(
        name: 'Test',
        models: {StringModel(context: context)},
        context: context,
        isDeprecated: false,
        additionalProperties: const UnrestrictedAdditionalProperties(),
      );

      expect(
        model.toString(),
        'AllOfModel{name: Test, nameOverride: null, models: {StringModel}, '
        "additionalProperties: Instance of 'UnrestrictedAdditionalProperties', "
        'description: null, isDeprecated: false}',
      );
    });
  });
}
