import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';

void main() {
  late Context context;
  late StableModelSorter sorter;

  setUp(() {
    context = Context.initial();
    sorter = StableModelSorter();
  });

  group('stableKeyOf cycle detection', () {
    test(
      'does not stack overflow for direct circular ClassModel reference',
      () {
        final modelA = ClassModel(
          name: 'A',
          properties: [],
          context: context,
          isDeprecated: false,
        );
        final modelB = ClassModel(
          name: 'B',
          properties: [],
          context: context,
          isDeprecated: false,
        );
        // A → B → A
        modelA.properties = [
          Property(
            name: 'b',
            model: modelB,
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ];
        modelB.properties = [
          Property(
            name: 'a',
            model: modelA,
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ];

        expect(() => sorter.stableKeyOf(modelA), returnsNormally);
        expect(sorter.stableKeyOf(modelA), contains('<cycle>'));
      },
    );

    test('does not stack overflow for self-referential ClassModel', () {
      final modelA = ClassModel(
        name: 'A',
        properties: [],
        context: context,
        isDeprecated: false,
      );
      // A → A
      modelA.properties = [
        Property(
          name: 'self',
          model: modelA,
          isRequired: false,
          isNullable: true,
          isDeprecated: false,
        ),
      ];

      expect(() => sorter.stableKeyOf(modelA), returnsNormally);
      expect(sorter.stableKeyOf(modelA), contains('<cycle>'));
    });

    test(
      'does not stack overflow for transitive cycle A → B → C → A',
      () {
        final modelA = ClassModel(
          name: 'A',
          properties: [],
          context: context,
          isDeprecated: false,
        );
        final modelB = ClassModel(
          name: 'B',
          properties: [],
          context: context,
          isDeprecated: false,
        );
        final modelC = ClassModel(
          name: 'C',
          properties: [],
          context: context,
          isDeprecated: false,
        );
        modelA.properties = [
          Property(
            name: 'b',
            model: modelB,
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ];
        modelB.properties = [
          Property(
            name: 'c',
            model: modelC,
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ];
        modelC.properties = [
          Property(
            name: 'a',
            model: modelA,
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ];

        expect(() => sorter.stableKeyOf(modelA), returnsNormally);
        expect(sorter.stableKeyOf(modelA), contains('<cycle>'));
      },
    );

    test(
      'cycle keys are deterministic (same result on repeated calls)',
      () {
        final modelA = ClassModel(
          name: 'A',
          properties: [],
          context: context,
          isDeprecated: false,
        );
        final modelB = ClassModel(
          name: 'B',
          properties: [],
          context: context,
          isDeprecated: false,
        );
        modelA.properties = [
          Property(
            name: 'b',
            model: modelB,
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ];
        modelB.properties = [
          Property(
            name: 'a',
            model: modelA,
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ];

        expect(
          sorter.stableKeyOf(modelA),
          sorter.stableKeyOf(modelA),
        );
        expect(
          sorter.stableKeyOf(modelB),
          sorter.stableKeyOf(modelB),
        );
      },
    );
  });

  group('stableKeyOf', () {
    test(
      'generates same key for primitive models regardless of context',
      () {
        final model1 = StringModel(context: context.push('path1'));
        final model2 = StringModel(context: context.push('path2'));

        expect(
          sorter.stableKeyOf(model1),
          sorter.stableKeyOf(model2),
        );
        expect(sorter.stableKeyOf(model1), 'StringModel');
      },
    );

    test('generates different keys for different primitive types', () {
      final stringModel = StringModel(context: context);
      final intModel = IntegerModel(context: context);
      final boolModel = BooleanModel(context: context);

      expect(sorter.stableKeyOf(stringModel), 'StringModel');
      expect(sorter.stableKeyOf(intModel), 'IntegerModel');
      expect(sorter.stableKeyOf(boolModel), 'BooleanModel');
    });

    test(
      'generates stable key for AllOfModel with sorted children',
      () {
        final sharedContext = context.push('Test').push('allOf');

        final model1 = AllOfModel(
          models: {
            StringModel(context: sharedContext),
            IntegerModel(context: sharedContext),
            BooleanModel(context: sharedContext),
          },
          context: sharedContext,
          isDeprecated: false,
        );

        final model2 = AllOfModel(
          models: {
            BooleanModel(context: sharedContext),
            StringModel(context: sharedContext),
            IntegerModel(context: sharedContext),
          },
          context: sharedContext,
          isDeprecated: false,
        );

        final key1 = sorter.stableKeyOf(model1);
        final key2 = sorter.stableKeyOf(model2);

        expect(key1, key2);
        expect(key1, contains('BooleanModel'));
        expect(key1, contains('IntegerModel'));
        expect(key1, contains('StringModel'));
      },
    );

    test(
      'generates different keys for AllOfModels with different children',
      () {
        final sharedContext = context.push('Test').push('allOf');

        final model1 = AllOfModel(
          models: {
            StringModel(context: sharedContext),
          },
          context: sharedContext,
          isDeprecated: false,
        );

        final model2 = AllOfModel(
          models: {
            IntegerModel(context: sharedContext),
          },
          context: sharedContext,
          isDeprecated: false,
        );

        expect(
          sorter.stableKeyOf(model1),
          isNot(sorter.stableKeyOf(model2)),
        );
      },
    );

    test(
      'generates stable key for OneOfModel with discriminator',
      () {
        final sharedContext = context.push('Test').push('oneOf');

        final model1 = OneOfModel(
          isDeprecated: false,
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
        );

        final model2 = OneOfModel(
          isDeprecated: false,
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
        );

        expect(
          sorter.stableKeyOf(model1),
          sorter.stableKeyOf(model2),
        );
      },
    );

    test('generates stable key for AnyOfModel', () {
      final sharedContext = context.push('Test').push('anyOf');

      final model1 = AnyOfModel(
        isDeprecated: false,
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
        context: sharedContext,
      );

      final model2 = AnyOfModel(
        isDeprecated: false,
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
        context: sharedContext,
      );

      expect(
        sorter.stableKeyOf(model1),
        sorter.stableKeyOf(model2),
      );
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

      expect(
        sorter.stableKeyOf(model1),
        sorter.stableKeyOf(model2),
      );
      expect(
        sorter.stableKeyOf(model1),
        'ListModel{TestList,StringModel}',
      );
    });

    test(
      'generates stable key for ClassModel with sorted properties',
      () {
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
            ),
            Property(
              name: 'count',
              model: IntegerModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          context: context,
        );

        final key = sorter.stableKeyOf(model1);
        expect(key, contains('TestClass'));
        expect(key, contains('id:StringModel'));
        expect(key, contains('count:IntegerModel'));
      },
    );

    test('generates stable key for EnumModel with sorted values', () {
      final model1 = EnumModel<String>(
        name: 'Status',
        values: {
          const EnumEntry(value: 'zebra'),
          const EnumEntry(value: 'apple'),
          const EnumEntry(value: 'banana'),
        },
        isNullable: false,
        context: context,
        isDeprecated: false,
      );

      final model2 = EnumModel<String>(
        name: 'Status',
        values: {
          const EnumEntry(value: 'banana'),
          const EnumEntry(value: 'zebra'),
          const EnumEntry(value: 'apple'),
        },
        isNullable: false,
        context: context,
        isDeprecated: false,
      );

      expect(
        sorter.stableKeyOf(model1),
        sorter.stableKeyOf(model2),
      );
    });

    test('generates stable key for nested composite models', () {
      final innerAllOf = AllOfModel(
        models: {
          StringModel(context: context),
          IntegerModel(context: context),
        },
        context: context.push('inner'),
        isDeprecated: false,
      );

      final outerAllOf = AllOfModel(
        models: {
          innerAllOf,
          BooleanModel(context: context),
        },
        context: context.push('outer'),
        isDeprecated: false,
      );

      final key = sorter.stableKeyOf(outerAllOf);
      expect(key, contains('AllOfModel'));
      expect(key, contains('BooleanModel'));
    });
  });

  group('stableKeyOf performance with circular models', () {
    test(
      'repeated stableKeyOf calls on circular graph are efficient',
      () {
        const modelCount = 13;
        final classModels = <ClassModel>[];
        final sharedContext = context.push('schemas');

        for (var i = 0; i < modelCount; i++) {
          classModels.add(
            ClassModel(
              name: 'Model$i',
              properties: [],
              context: sharedContext,
              isDeprecated: false,
            ),
          );
        }

        const offsets = [1, 3, 5, 7];
        for (var i = 0; i < modelCount; i++) {
          classModels[i].properties = [
            for (final offset in offsets)
              Property(
                name: 'ref$offset',
                model: classModels[(i + offset) % modelCount],
                isRequired: false,
                isNullable: true,
                isDeprecated: false,
              ),
          ];
        }

        const iterations = 200;
        final sw = Stopwatch()..start();
        for (var i = 0; i < iterations; i++) {
          classModels.forEach(sorter.stableKeyOf);
        }
        sw.stop();

        expect(
          sw.elapsedMilliseconds,
          lessThan(500),
          reason:
              '${iterations * modelCount} stableKeyOf calls took '
              '${sw.elapsedMilliseconds}ms. '
              'stableKeyOf is likely being recomputed on every '
              'call instead of being cached.',
        );
      },
    );
  });

  group('sortModels', () {
    test('returns consistently ordered list', () {
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

      final list1 = sorter.sortModels(set1);
      final list2 = sorter.sortModels(set2);

      expect(list1.length, list2.length);
      for (var i = 0; i < list1.length; i++) {
        expect(
          sorter.stableKeyOf(list1[i]),
          sorter.stableKeyOf(list2[i]),
        );
      }
    });

    test('sorts by stable model key', () {
      final sharedContext = context.push('Test');

      final models = {
        StringModel(context: sharedContext),
        IntegerModel(context: sharedContext),
        BooleanModel(context: sharedContext),
      };

      final sorted = sorter.sortModels(models);
      final keys = sorted.map((m) => sorter.stableKeyOf(m)).toList();

      expect(keys[0], 'BooleanModel');
      expect(keys[1], 'IntegerModel');
      expect(keys[2], 'StringModel');
    });
  });

  group('sortDiscriminatedModels', () {
    test('returns consistently ordered list', () {
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

      final list1 = sorter.sortDiscriminatedModels(set1);
      final list2 = sorter.sortDiscriminatedModels(set2);

      expect(list1.length, list2.length);
      expect(
        list1[0].discriminatorValue,
        list2[0].discriminatorValue,
      );
      expect(
        list1[1].discriminatorValue,
        list2[1].discriminatorValue,
      );
    });

    test('sorts by discriminator value first', () {
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

      final sorted = sorter.sortDiscriminatedModels(models);

      expect(sorted[0].discriminatorValue, 'apple');
      expect(sorted[1].discriminatorValue, 'banana');
      expect(sorted[2].discriminatorValue, 'zebra');
    });
  });
}
