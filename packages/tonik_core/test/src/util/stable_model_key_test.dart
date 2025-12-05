import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';

void main() {
  late Context context;

  setUp(() {
    context = Context.initial();
  });

  group('stableKey', () {
    test('generates same key for primitive models regardless of context', () {
      final model1 = StringModel(context: context.push('path1'));
      final model2 = StringModel(context: context.push('path2'));

      expect(model1.stableKey, model2.stableKey);
      expect(model1.stableKey, 'StringModel');
    });

    test('generates different keys for different primitive types', () {
      final stringModel = StringModel(context: context);
      final intModel = IntegerModel(context: context);
      final boolModel = BooleanModel(context: context);

      expect(stringModel.stableKey, 'StringModel');
      expect(intModel.stableKey, 'IntegerModel');
      expect(boolModel.stableKey, 'BooleanModel');
    });

    test('generates stable key for AllOfModel with sorted children', () {
      final sharedContext = context.push('Test').push('allOf');

      final model1 = AllOfModel(
        name: null,
        models: {
          StringModel(context: sharedContext),
          IntegerModel(context: sharedContext),
          BooleanModel(context: sharedContext),
        },
        context: sharedContext,
        description: null,
        isDeprecated: false,
      );

      final model2 = AllOfModel(
        name: null,
        models: {
          BooleanModel(context: sharedContext),
          StringModel(context: sharedContext),
          IntegerModel(context: sharedContext),
        },
        context: sharedContext,
        description: null,
        isDeprecated: false,
      );

      final key1 = model1.stableKey;
      final key2 = model2.stableKey;

      expect(key1, key2);
      expect(key1, contains('BooleanModel'));
      expect(key1, contains('IntegerModel'));
      expect(key1, contains('StringModel'));
    });

    test(
      'generates different keys for AllOfModels with different children',
      () {
        final sharedContext = context.push('Test').push('allOf');

        final model1 = AllOfModel(
          name: null,
          models: {
            StringModel(context: sharedContext),
          },
          context: sharedContext,
          description: null,
          isDeprecated: false,
        );

        final model2 = AllOfModel(
          name: null,
          models: {
            IntegerModel(context: sharedContext),
          },
          context: sharedContext,
          description: null,
          isDeprecated: false,
        );

        expect(model1.stableKey, isNot(model2.stableKey));
      },
    );

    test('generates stable key for OneOfModel with discriminator', () {
      final sharedContext = context.push('Test').push('oneOf');

      final model1 = OneOfModel(
        isDeprecated: false,
        name: null,
        models: {
          (
            discriminatorValue: 'zebra',
            model: StringModel(context: sharedContext),
          ),
          (
            discriminatorValue: 'apple',
            model: IntegerModel(context: sharedContext),
          ),
        },
        discriminator: 'type',
        context: sharedContext,
        description: null,
      );

      final model2 = OneOfModel(
        isDeprecated: false,
        name: null,
        models: {
          (
            discriminatorValue: 'apple',
            model: IntegerModel(context: sharedContext),
          ),
          (
            discriminatorValue: 'zebra',
            model: StringModel(context: sharedContext),
          ),
        },
        discriminator: 'type',
        context: sharedContext,
        description: null,
      );

      expect(model1.stableKey, model2.stableKey);
    });

    test('generates stable key for AnyOfModel', () {
      final sharedContext = context.push('Test').push('anyOf');

      final model1 = AnyOfModel(
        isDeprecated: false,
        name: null,
        models: {
          (
            discriminatorValue: null,
            model: StringModel(context: sharedContext),
          ),
          (
            discriminatorValue: null,
            model: IntegerModel(context: sharedContext),
          ),
        },
        discriminator: null,
        context: sharedContext,
        description: null,
      );

      final model2 = AnyOfModel(
        isDeprecated: false,
        name: null,
        models: {
          (
            discriminatorValue: null,
            model: IntegerModel(context: sharedContext),
          ),
          (
            discriminatorValue: null,
            model: StringModel(context: sharedContext),
          ),
        },
        discriminator: null,
        context: sharedContext,
        description: null,
      );

      expect(model1.stableKey, model2.stableKey);
    });

    test('generates stable key for ListModel', () {
      final model1 = ListModel(
        name: 'TestList',
        content: StringModel(context: context),
        context: context,
      );

      final model2 = ListModel(
        name: 'TestList',
        content: StringModel(context: context.push('other')),
        context: context.push('different'),
      );

      expect(model1.stableKey, model2.stableKey);
      expect(model1.stableKey, 'ListModel{TestList,StringModel}');
    });

    test('generates stable key for ClassModel with sorted properties', () {
      final model1 = ClassModel(
        isDeprecated: false,
        name: 'TestClass',
        properties: [
          Property(
            name: 'id',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            description: null,
          ),
          Property(
            name: 'count',
            model: IntegerModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            description: null,
          ),
        ],
        context: context,
        description: null,
      );

      final key = model1.stableKey;
      expect(key, contains('TestClass'));
      expect(key, contains('id:StringModel'));
      expect(key, contains('count:IntegerModel'));
    });

    test('generates stable key for EnumModel with sorted values', () {
      final model1 = EnumModel(
        name: 'Status',
        values: const {'zebra', 'apple', 'banana'},
        isNullable: false,
        context: context,
        description: null,
        isDeprecated: false,
      );

      final model2 = EnumModel(
        name: 'Status',
        values: const {'banana', 'zebra', 'apple'},
        isNullable: false,
        context: context,
        description: null,
        isDeprecated: false,
      );

      expect(model1.stableKey, model2.stableKey);
    });

    test('generates stable key for nested composite models', () {
      final innerAllOf = AllOfModel(
        name: null,
        models: {
          StringModel(context: context),
          IntegerModel(context: context),
        },
        context: context.push('inner'),
        description: null,
        isDeprecated: false,
      );

      final outerAllOf = AllOfModel(
        name: null,
        models: {
          innerAllOf,
          BooleanModel(context: context),
        },
        context: context.push('outer'),
        description: null,
        isDeprecated: false,
      );

      final key = outerAllOf.stableKey;
      expect(key, contains('AllOfModel'));
      expect(key, contains('BooleanModel'));
    });
  });

  group('StableSortedModels extension', () {
    test('toSortedList returns consistently ordered list', () {
      final sharedContext = context.push('Test');

      final set1 = {
        StringModel(context: sharedContext),
        IntegerModel(context: sharedContext),
        BooleanModel(context: sharedContext),
      };

      final set2 = {
        BooleanModel(context: sharedContext),
        StringModel(context: sharedContext),
        IntegerModel(context: sharedContext),
      };

      final list1 = set1.toSortedList();
      final list2 = set2.toSortedList();

      expect(list1.length, list2.length);
      for (var i = 0; i < list1.length; i++) {
        expect(
          list1[i].stableKey,
          list2[i].stableKey,
        );
      }
    });

    test('toSortedList sorts by stable model key', () {
      final sharedContext = context.push('Test');

      final models = {
        StringModel(context: sharedContext),
        IntegerModel(context: sharedContext),
        BooleanModel(context: sharedContext),
      };

      final sorted = models.toSortedList();
      final keys = sorted.map((m) => m.stableKey).toList();

      expect(keys[0], 'BooleanModel');
      expect(keys[1], 'IntegerModel');
      expect(keys[2], 'StringModel');
    });
  });

  group('StableSortedDiscriminatedModels extension', () {
    test('toSortedList returns consistently ordered list', () {
      final sharedContext = context.push('Test');

      final set1 = {
        (
          discriminatorValue: 'zebra',
          model: StringModel(context: sharedContext),
        ),
        (
          discriminatorValue: 'apple',
          model: IntegerModel(context: sharedContext),
        ),
      };

      final set2 = {
        (
          discriminatorValue: 'apple',
          model: IntegerModel(context: sharedContext),
        ),
        (
          discriminatorValue: 'zebra',
          model: StringModel(context: sharedContext),
        ),
      };

      final list1 = set1.toSortedList();
      final list2 = set2.toSortedList();

      expect(list1.length, list2.length);
      expect(list1[0].discriminatorValue, list2[0].discriminatorValue);
      expect(list1[1].discriminatorValue, list2[1].discriminatorValue);
    });

    test('toSortedList sorts by discriminator value first', () {
      final sharedContext = context.push('Test');

      final models = {
        (
          discriminatorValue: 'zebra',
          model: StringModel(context: sharedContext),
        ),
        (
          discriminatorValue: 'apple',
          model: IntegerModel(context: sharedContext),
        ),
        (
          discriminatorValue: 'banana',
          model: BooleanModel(context: sharedContext),
        ),
      };

      final sorted = models.toSortedList();

      expect(sorted[0].discriminatorValue, 'apple');
      expect(sorted[1].discriminatorValue, 'banana');
      expect(sorted[2].discriminatorValue, 'zebra');
    });
  });
}
