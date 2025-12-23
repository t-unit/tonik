import 'package:composition_api/composition_api.dart';
import 'package:test/test.dart';

void main() {
  group('copyWith - Class models', () {
    group('Class1', () {
      test('copyWith creates new instance with changed values', () {
        const original = Class1(name: 'Alice');
        final updated = original.copyWith(name: 'Bob');

        expect(updated.name, 'Bob');
        expect(original.name, 'Alice'); // Original unchanged
        expect(updated, isNot(same(original)));
      });

      test('copyWith without arguments returns identical copy', () {
        const original = Class1(name: 'Alice');
        final copy = original.copyWith();

        expect(copy.name, original.name);
        expect(copy, original);
        expect(copy, isNot(same(original)));
      });

      test('copyWith preserves equality', () {
        const original = Class1(name: 'Alice');
        final copy = original.copyWith();

        expect(copy, original);
        expect(copy.hashCode, original.hashCode);
      });
    });

    group('Class2', () {
      test('copyWith creates new instance with changed values', () {
        const original = Class2(number: 42);
        final updated = original.copyWith(number: 100);

        expect(updated.number, 100);
        expect(original.number, 42); // Original unchanged
      });

      test('copyWith without arguments returns identical copy', () {
        const original = Class2(number: 42);
        final copy = original.copyWith();

        expect(copy.number, original.number);
        expect(copy, original);
      });
    });
  });

  group('copyWith - AllOf composite models', () {
    group('AllOfComplex', () {
      test('copyWith can update individual class properties', () {
        const original = AllOfComplex(
          class1: Class1(name: 'Alice'),
          class2: Class2(number: 42),
        );

        final updatedClass1 = original.copyWith(
          class1: const Class1(name: 'Bob'),
        );

        expect(updatedClass1.class1.name, 'Bob');
        expect(updatedClass1.class2.number, 42);
        expect(original.class1.name, 'Alice'); // Original unchanged

        final updatedClass2 = original.copyWith(
          class2: const Class2(number: 100),
        );

        expect(updatedClass2.class1.name, 'Alice');
        expect(updatedClass2.class2.number, 100);
      });

      test('copyWith can update both properties at once', () {
        const original = AllOfComplex(
          class1: Class1(name: 'Alice'),
          class2: Class2(number: 42),
        );

        final updated = original.copyWith(
          class1: const Class1(name: 'Bob'),
          class2: const Class2(number: 100),
        );

        expect(updated.class1.name, 'Bob');
        expect(updated.class2.number, 100);
        expect(original.class1.name, 'Alice'); // Original unchanged
        expect(original.class2.number, 42);
      });

      test('copyWith without arguments returns identical copy', () {
        const original = AllOfComplex(
          class1: Class1(name: 'Alice'),
          class2: Class2(number: 42),
        );

        final copy = original.copyWith();

        expect(copy.class1, original.class1);
        expect(copy.class2, original.class2);
        expect(copy, original);
      });
    });
  });

  group('copyWith - Models with nullable properties', () {
    group('AllOfPrimitiveModel - nullable int field', () {
      test('copyWith can set nullable count to null', () {
        const original = AllOfPrimitiveModel(count: 42);
        final updated = original.copyWith(count: null);

        expect(updated.count, isNull);
        expect(original.count, 42); // Original unchanged
      });

      test('copyWith can update nullable count with new value', () {
        const original = AllOfPrimitiveModel(count: 42);
        final updated = original.copyWith(count: 100);

        expect(updated.count, 100);
        expect(original.count, 42);
      });

      test('copyWith preserves null when no argument provided', () {
        const original = AllOfPrimitiveModel();
        final copy = original.copyWith();

        expect(copy.count, isNull);
        expect(copy, original);
      });

      test('copyWith can set null to a value', () {
        const original = AllOfPrimitiveModel();
        final updated = original.copyWith(count: 42);

        expect(updated.count, 42);
        expect(original.count, isNull);
      });
    });
  });

  group('copyWith - AnyOf composite models', () {
    group('AnyOfComplex with Class1 variant', () {
      test('copyWith can update the class1 variant', () {
        const original = AnyOfComplex(class1: Class1(name: 'Alice'));
        final updated = original.copyWith(class1: const Class1(name: 'Bob'));

        expect(updated.class1?.name, 'Bob');
        expect(original.class1?.name, 'Alice'); // Original unchanged
      });

      test('copyWith without arguments returns identical copy', () {
        const original = AnyOfComplex(class1: Class1(name: 'Alice'));
        final copy = original.copyWith();

        expect(copy.class1, original.class1);
        expect(copy, original);
      });

      test('copyWith can set class1 to null when variant is nullable', () {
        const original = AnyOfComplex(class1: Class1(name: 'Alice'));
        final updated = original.copyWith(class1: null);

        expect(updated.class1, isNull);
        expect(original.class1?.name, 'Alice'); // Original unchanged
      });
    });

    group('AnyOfComplex with Class2 variant', () {
      test('copyWith can update the class2 variant', () {
        const original = AnyOfComplex(class2: Class2(number: 42));
        final updated = original.copyWith(class2: const Class2(number: 100));

        expect(updated.class2?.number, 100);
        expect(original.class2?.number, 42); // Original unchanged
      });

      test('copyWith can set class2 to null', () {
        const original = AnyOfComplex(class2: Class2(number: 42));
        final updated = original.copyWith(class2: null);

        expect(updated.class2, isNull);
        expect(original.class2?.number, 42); // Original unchanged
      });
    });

    group('AnyOfComplex switching variants', () {
      test('copyWith can switch from class1 to class2', () {
        const original = AnyOfComplex(class1: Class1(name: 'Alice'));
        final updated = original.copyWith(
          class1: null,
          class2: const Class2(number: 42),
        );

        expect(updated.class1, isNull);
        expect(updated.class2?.number, 42);
      });

      test('copyWith can switch from class2 to class1', () {
        const original = AnyOfComplex(class2: Class2(number: 42));
        final updated = original.copyWith(
          class2: null,
          class1: const Class1(name: 'Alice'),
        );

        expect(updated.class2, isNull);
        expect(updated.class1?.name, 'Alice');
      });
    });

    group('TwoLevelAnyOfModel - nested nullable variants', () {
      test('copyWith can set nested nullable class1 to null', () {
        const original = TwoLevelAnyOfModel(
          class1: Class1(name: 'Alice'),
          class2: Class2(number: 42),
        );
        final updated = original.copyWith(class1: null);

        expect(updated.class1, isNull);
        expect(updated.class2?.number, 42);
        expect(original.class1?.name, 'Alice');
      });

      test('copyWith can set nested nullable class2 to null', () {
        const original = TwoLevelAnyOfModel(
          class1: Class1(name: 'Alice'),
          class2: Class2(number: 42),
        );
        final updated = original.copyWith(class2: null);

        expect(updated.class1?.name, 'Alice');
        expect(updated.class2, isNull);
        expect(original.class2?.number, 42);
      });

      test('copyWith can set both nullable variants to null', () {
        const original = TwoLevelAnyOfModel(
          class1: Class1(name: 'Alice'),
          class2: Class2(number: 42),
        );
        final updated = original.copyWith(class1: null, class2: null);

        expect(updated.class1, isNull);
        expect(updated.class2, isNull);
        expect(original.class1?.name, 'Alice');
        expect(original.class2?.number, 42);
      });
    });
  });

  group('copyWith - Type safety', () {
    test('copyWith null sets nullable fields to null', () {
      const original = AnyOfComplex(class1: Class1(name: 'Alice'));

      // Setting nullable field to null
      final updated = original.copyWith(class1: null);

      expect(updated.class1, isNull);
    });

    test('copyWith null is distinguished from copyWith no-argument', () {
      const original = AnyOfComplex(
        class1: Class1(name: 'Alice'),
        class2: Class2(number: 42),
      );

      // No argument - keeps original
      final copy = original.copyWith();
      expect(copy.class1, isNotNull);
      expect(copy.class2, isNotNull);

      // Explicit null - sets to null
      final withNull = original.copyWith(class1: null);
      expect(withNull.class1, isNull);
      expect(withNull.class2, isNotNull); // Other field preserved
    });
  });

  group('copyWith - Chaining', () {
    test('copyWith calls can be chained', () {
      const original = AllOfComplex(
        class1: Class1(name: 'Alice'),
        class2: Class2(number: 42),
      );

      final updated = original
          .copyWith(class1: const Class1(name: 'Bob'))
          .copyWith(class2: const Class2(number: 100));

      expect(updated.class1.name, 'Bob');
      expect(updated.class2.number, 100);
    });

    test('chained copyWith preserves intermediate states', () {
      const original = AllOfComplex(
        class1: Class1(name: 'Alice'),
        class2: Class2(number: 42),
      );

      final step1 = original.copyWith(class1: const Class1(name: 'Bob'));
      expect(step1.class1.name, 'Bob');
      expect(step1.class2.number, 42);

      final step2 = step1.copyWith(class2: const Class2(number: 100));
      expect(step2.class1.name, 'Bob');
      expect(step2.class2.number, 100);

      // Original still unchanged
      expect(original.class1.name, 'Alice');
      expect(original.class2.number, 42);
    });
  });

  group('copyWith - JSON roundtrip', () {
    test('copyWith result serializes correctly', () {
      const original = AllOfComplex(
        class1: Class1(name: 'Alice'),
        class2: Class2(number: 42),
      );

      final updated = original.copyWith(class1: const Class1(name: 'Bob'));
      final json = updated.toJson();
      final reconstructed = AllOfComplex.fromJson(json);

      expect(reconstructed.class1.name, 'Bob');
      expect(reconstructed.class2.number, 42);
      expect(reconstructed, updated);
    });

    test('copyWith with null serializes correctly', () {
      const original = AnyOfComplex(
        class1: Class1(name: 'Alice'),
        class2: Class2(number: 42),
      );

      final updated = original.copyWith(class1: null);
      final json = updated.toJson();
      final reconstructed = AnyOfComplex.fromJson(json);

      expect(reconstructed.class1, isNull);
      expect(reconstructed.class2?.number, 42);
      expect(reconstructed, updated);
    });
  });
}
