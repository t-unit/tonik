import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  group('EncodingShape property', () {
    test('Primitive models are simple', () {
      expect(
        StringModel(context: Context.initial()).encodingShape,
        EncodingShape.simple,
      );
      expect(
        IntegerModel(context: Context.initial()).encodingShape,
        EncodingShape.simple,
      );
      expect(
        DoubleModel(context: Context.initial()).encodingShape,
        EncodingShape.simple,
      );
      expect(
        NumberModel(context: Context.initial()).encodingShape,
        EncodingShape.simple,
      );
      expect(
        BooleanModel(context: Context.initial()).encodingShape,
        EncodingShape.simple,
      );
      expect(
        DateTimeModel(context: Context.initial()).encodingShape,
        EncodingShape.simple,
      );
      expect(
        DateModel(context: Context.initial()).encodingShape,
        EncodingShape.simple,
      );
      expect(
        DecimalModel(context: Context.initial()).encodingShape,
        EncodingShape.simple,
      );
      expect(
        UriModel(context: Context.initial()).encodingShape,
        EncodingShape.simple,
      );
    });

    test('Enum models are simple', () {
      expect(
        EnumModel<String>(
          values: const {'a', 'b'},
          isNullable: false,
          context: Context.initial(),
          description: null,
          isDeprecated: false,
        ).encodingShape,
        EncodingShape.simple,
      );
    });

    test('Class and List models are complex', () {
      expect(
        ClassModel(
          properties: const [],
          context: Context.initial(),
          description: null,
          isDeprecated: false,
        ).encodingShape,
        EncodingShape.complex,
      );
      expect(
        ListModel(
          content: StringModel(context: Context.initial()),
          context: Context.initial(),
        ).encodingShape,
        EncodingShape.complex,
      );
    });

    test('Alias reflects underlying model', () {
      expect(
        AliasModel(
          name: 'Alias',
          model: StringModel(context: Context.initial()),
          context: Context.initial(),
        ).encodingShape,
        EncodingShape.simple,
      );
      expect(
        AliasModel(
          name: 'Alias',
          model: ClassModel(
            properties: const [],
            context: Context.initial(),
            description: null,
            isDeprecated: false,
          ),
          context: Context.initial(),
        ).encodingShape,
        EncodingShape.complex,
      );
    });

    test('AllOf/OneOf/AnyOf: simple, complex, mixed', () {
      final simpleAllOf = AllOfModel(
        name: 'SimpleAllOf',
        models: {
          StringModel(context: Context.initial()),
          IntegerModel(context: Context.initial()),
        },
        context: Context.initial(),
        description: null,
        isDeprecated: false,
      );
      expect(simpleAllOf.encodingShape, EncodingShape.simple);

      final complexAllOf = AllOfModel(
        name: 'ComplexAllOf',
        models: {
          ClassModel(
            properties: const [],
            context: Context.initial(),
            description: null,
            isDeprecated: false,
          ),
          ListModel(
            content: StringModel(context: Context.initial()),
            context: Context.initial(),
          ),
        },
        context: Context.initial(),
        description: null,
        isDeprecated: false,
      );
      expect(complexAllOf.encodingShape, EncodingShape.complex);

      final mixedAllOf = AllOfModel(
        name: 'MixedAllOf',
        models: {
          StringModel(context: Context.initial()),
          ClassModel(
            properties: const [],
            context: Context.initial(),
            description: null,
            isDeprecated: false,
          ),
        },
        context: Context.initial(),
        description: null,
        isDeprecated: false,
      );
      expect(mixedAllOf.encodingShape, EncodingShape.mixed);
    });
  });
}
