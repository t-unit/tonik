import 'package:composition_api/composition_api.dart';
import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  group('AnyOfPrimitive', () {
    test('string', () {
      final anyOf = AnyOfPrimitive(string: 'hello');
      expect(anyOf.toJson(), 'hello');
      expect(anyOf.toForm(explode: true, allowEmpty: true), 'hello');
      expect(anyOf.toSimple(explode: true, allowEmpty: true), 'hello');

      expect(anyOf.currentEncodingShape, EncodingShape.simple);
    });

    test('integer', () {
      final anyOf = AnyOfPrimitive(int: 42);
      expect(anyOf.toJson(), 42);
      expect(anyOf.toForm(explode: true, allowEmpty: true), '42');
      expect(anyOf.toSimple(explode: true, allowEmpty: true), '42');

      expect(anyOf.currentEncodingShape, EncodingShape.simple);
    });

    test('boolean', () {
      final anyOf = AnyOfPrimitive(bool: true);
      expect(anyOf.toJson(), true);
      expect(anyOf.toForm(explode: true, allowEmpty: true), 'true');
      expect(anyOf.toSimple(explode: true, allowEmpty: true), 'true');

      expect(anyOf.currentEncodingShape, EncodingShape.simple);
    });

    test('multiple values', () {
      final anyOf = AnyOfPrimitive(string: 'hello', int: 42);
      expect(anyOf.toJson, throwsA(isA<EncodingException>()));
      expect(
        () => anyOf.toForm(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
      expect(
        () => anyOf.toSimple(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );

      expect(anyOf.currentEncodingShape, EncodingShape.mixed);
    });
  });

  group('AnyOfComplex', () {
    test('class1', () {
      final anyOf = AnyOfComplex(class1: Class1(name: 'Alice'));
      expect(anyOf.toJson(), {'name': 'Alice'});
      expect(anyOf.toForm(explode: true, allowEmpty: true), 'name=Alice');
      expect(anyOf.toSimple(explode: true, allowEmpty: true), 'name=Alice');
      expect(anyOf.toSimple(explode: false, allowEmpty: true), 'name,Alice');

      expect(anyOf.currentEncodingShape, EncodingShape.complex);
    });

    test('class2', () {
      final anyOf = AnyOfComplex(class2: Class2(number: 123));
      expect(anyOf.toJson(), {'number': 123});
      expect(anyOf.toForm(explode: true, allowEmpty: true), 'number=123');
      expect(anyOf.toSimple(explode: true, allowEmpty: true), 'number=123');
      expect(anyOf.toSimple(explode: false, allowEmpty: true), 'number,123');

      expect(anyOf.currentEncodingShape, EncodingShape.complex);
    });

    test('both classes', () {
      final anyOf = AnyOfComplex(
        class1: Class1(name: 'Alice'),
        class2: Class2(number: 123),
      );
      expect(anyOf.toJson, throwsA(isA<EncodingException>()));
      expect(
        () => anyOf.toForm(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
      expect(
        () => anyOf.toSimple(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );

      expect(anyOf.currentEncodingShape, EncodingShape.mixed);
    });
  });

  group('AnyOfEnum', () {
    test('enum1', () {
      final anyOf = AnyOfEnum(enum1: Enum1.value1);
      expect(anyOf.toJson(), 'value1');
      expect(anyOf.toForm(explode: true, allowEmpty: true), 'value1');
      expect(anyOf.toSimple(explode: true, allowEmpty: true), 'value1');

      expect(anyOf.currentEncodingShape, EncodingShape.simple);
    });

    test('enum2', () {
      final anyOf = AnyOfEnum(enum2: Enum2.two);
      expect(anyOf.toJson(), 2);
      expect(anyOf.toForm(explode: true, allowEmpty: true), '2');
      expect(anyOf.toSimple(explode: true, allowEmpty: true), '2');

      expect(anyOf.currentEncodingShape, EncodingShape.simple);
    });

    test('both enums', () {
      final anyOf = AnyOfEnum(enum1: Enum1.value1, enum2: Enum2.two);
      expect(anyOf.toJson, throwsA(isA<EncodingException>()));
      expect(
        () => anyOf.toForm(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
      expect(
        () => anyOf.toSimple(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );

      expect(anyOf.currentEncodingShape, EncodingShape.mixed);
    });
  });

  group('AnyOfMixed', () {
    test('integer', () {
      final anyOf = AnyOfMixed(int: 42);
      expect(anyOf.toJson(), 42);
      expect(anyOf.toForm(explode: true, allowEmpty: true), '42');
      expect(anyOf.toSimple(explode: true, allowEmpty: true), '42');

      expect(anyOf.currentEncodingShape, EncodingShape.simple);
    });

    test('class2', () {
      final anyOf = AnyOfMixed(class2: Class2(number: 123));
      expect(anyOf.toJson(), {'number': 123});
      expect(anyOf.toForm(explode: true, allowEmpty: true), 'number=123');
      expect(anyOf.toSimple(explode: true, allowEmpty: true), 'number=123');
      expect(anyOf.toSimple(explode: false, allowEmpty: true), 'number,123');

      expect(anyOf.currentEncodingShape, EncodingShape.complex);
    });

    test('enum2', () {
      final anyOf = AnyOfMixed(enum2: Enum2.one);
      expect(anyOf.toJson(), 1);
      expect(anyOf.toForm(explode: true, allowEmpty: true), '1');
      expect(anyOf.toSimple(explode: true, allowEmpty: true), '1');

      expect(anyOf.currentEncodingShape, EncodingShape.simple);
    });

    test('multiple values', () {
      final anyOf = AnyOfMixed(int: 42, class2: Class2(number: 123));
      expect(anyOf.toJson, throwsA(isA<EncodingException>()));
      expect(
        () => anyOf.toForm(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
      expect(
        () => anyOf.toSimple(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );

      expect(anyOf.currentEncodingShape, EncodingShape.mixed);
    });
  });

  group('NestedAnyOfInAllOf', () {
    test('with class1', () {
      final anyOf = NestedAnyOfInAllOf(
        anyOfComplex: AnyOfComplex(class1: Class1(name: 'Bob')),
        nestedAnyOfInAllOfModel: NestedAnyOfInAllOfModel(timestamp: 123),
      );

      expect(anyOf.toJson(), {'name': 'Bob', 'timestamp': 123});
      expect(
        anyOf.toForm(explode: true, allowEmpty: true),
        'name=Bob&timestamp=123',
      );
      expect(
        anyOf.toSimple(explode: true, allowEmpty: true),
        'name=Bob,timestamp=123',
      );
      expect(
        anyOf.toSimple(explode: false, allowEmpty: true),
        'name,Bob,timestamp,123',
      );

      expect(anyOf.currentEncodingShape, EncodingShape.complex);
    });

    test('with class2', () {
      final anyOf = NestedAnyOfInAllOf(
        anyOfComplex: AnyOfComplex(class2: Class2(number: 456)),
        nestedAnyOfInAllOfModel: NestedAnyOfInAllOfModel(timestamp: 123),
      );

      expect(anyOf.toJson(), {'number': 456, 'timestamp': 123});
      expect(
        anyOf.toForm(explode: true, allowEmpty: true),
        'number=456&timestamp=123',
      );
      expect(
        anyOf.toSimple(explode: true, allowEmpty: true),
        'number=456,timestamp=123',
      );
      expect(
        anyOf.toSimple(explode: false, allowEmpty: true),
        'number,456,timestamp,123',
      );

      expect(anyOf.currentEncodingShape, EncodingShape.complex);
    });
  });

  group('NestedAllOfInAnyOf', () {
    test('with AllOfMixed', () {
      final anyOf = NestedAllOfInAnyOf(
        allOfMixed: AllOfMixed(
          string: 'test',
          class1: Class1(name: 'test'),
        ),
        class1: Class1(name: 'test'),
      );

      expect(anyOf.toJson, throwsA(isA<EncodingException>()));
      expect(
        () => anyOf.toForm(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
      expect(
        () => anyOf.toSimple(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );

      expect(anyOf.currentEncodingShape, EncodingShape.mixed);
    });

    test('with Class1', () {
      final anyOf = NestedAllOfInAnyOf(
        allOfMixed: null,
        class1: Class1(name: 'Charlie'),
      );

      expect(anyOf.toJson(), {'name': 'Charlie'});
      expect(anyOf.toForm(explode: true, allowEmpty: true), 'name=Charlie');
      expect(anyOf.toSimple(explode: true, allowEmpty: true), 'name=Charlie');
      expect(anyOf.toSimple(explode: false, allowEmpty: true), 'name,Charlie');

      expect(anyOf.currentEncodingShape, EncodingShape.complex);
    });
  });

  group('NestedOneOfInAnyOf', () {
    test('with OneOfEnum', () {
      final anyOf = NestedOneOfInAnyOf(
        oneOfEnum: OneOfEnumEnum1(Enum1.value2),
        num: null,
      );

      expect(anyOf.toJson(), 'value2');
      expect(anyOf.toForm(explode: true, allowEmpty: true), 'value2');
      expect(anyOf.toSimple(explode: true, allowEmpty: true), 'value2');

      expect(anyOf.currentEncodingShape, EncodingShape.simple);
    });

    test('with number', () {
      final anyOf = NestedOneOfInAnyOf(oneOfEnum: null, num: 3.14);

      expect(anyOf.toJson(), 3.14);
      expect(anyOf.toForm(explode: true, allowEmpty: true), '3.14');
      expect(anyOf.toSimple(explode: true, allowEmpty: true), '3.14');

      expect(anyOf.currentEncodingShape, EncodingShape.simple);
    });

    test('with both', () {
      final anyOf = NestedOneOfInAnyOf(
        oneOfEnum: OneOfEnumEnum1(Enum1.value2),
        num: 3.14,
      );

      expect(anyOf.toJson, throwsA(isA<EncodingException>()));
      expect(
        () => anyOf.toForm(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
      expect(
        () => anyOf.toSimple(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );

      expect(anyOf.currentEncodingShape, EncodingShape.mixed);
    });
  });

  group('TwoLevelAnyOf', () {
    test('with string', () {
      final anyOf = TwoLevelAnyOf(string: 'test');

      expect(anyOf.toJson(), 'test');
      expect(anyOf.toForm(explode: true, allowEmpty: true), 'test');
      expect(anyOf.toSimple(explode: true, allowEmpty: true), 'test');

      expect(anyOf.currentEncodingShape, EncodingShape.simple);
    });

    test('with class1', () {
      final anyOf = TwoLevelAnyOf(
        twoLevelAnyOfModel: TwoLevelAnyOfModel(class1: Class1(name: 'test')),
      );

      expect(anyOf.toJson(), {'name': 'test'});
      expect(anyOf.toForm(explode: true, allowEmpty: true), 'name=test');
      expect(anyOf.toSimple(explode: true, allowEmpty: true), 'name=test');
      expect(anyOf.toSimple(explode: false, allowEmpty: true), 'name,test');

      expect(anyOf.currentEncodingShape, EncodingShape.complex);
    });

    test('with class2', () {
      final anyOf = TwoLevelAnyOf(
        twoLevelAnyOfModel: TwoLevelAnyOfModel(class2: Class2(number: 42)),
      );

      expect(anyOf.toJson(), {'number': 42});
      expect(anyOf.toForm(explode: true, allowEmpty: true), 'number=42');
      expect(anyOf.toSimple(explode: true, allowEmpty: true), 'number=42');
      expect(anyOf.toSimple(explode: false, allowEmpty: true), 'number,42');

      expect(anyOf.currentEncodingShape, EncodingShape.complex);
    });
  });

  group('ThreeLevelAnyOf', () {
    test('with string', () {
      final anyOf = ThreeLevelAnyOf(string: 'deep');

      expect(anyOf.toJson(), 'deep');
      expect(anyOf.toForm(explode: true, allowEmpty: true), 'deep');
      expect(anyOf.toSimple(explode: true, allowEmpty: true), 'deep');

      expect(anyOf.currentEncodingShape, EncodingShape.simple);
    });

    test('with enum1', () {
      final anyOf = ThreeLevelAnyOf(
        threeLevelAnyOfModel: ThreeLevelAnyOfModel(enum1: Enum1.value1),
      );

      expect(anyOf.toJson(), 'value1');
      expect(anyOf.toForm(explode: true, allowEmpty: true), 'value1');
      expect(anyOf.toSimple(explode: true, allowEmpty: true), 'value1');

      expect(anyOf.currentEncodingShape, EncodingShape.simple);
    });

    test('with anyOf', () {
      final anyOf = ThreeLevelAnyOf(
        threeLevelAnyOfModel: ThreeLevelAnyOfModel(
          threeLevelAnyOfAnyOfModel: ThreeLevelAnyOfAnyOfModel(
            class1: Class1(name: 'test'),
          ),
        ),
      );

      expect(anyOf.toJson(), {'name': 'test'});
      expect(anyOf.toForm(explode: true, allowEmpty: true), 'name=test');
      expect(anyOf.toSimple(explode: true, allowEmpty: true), 'name=test');
      expect(anyOf.toSimple(explode: false, allowEmpty: true), 'name,test');

      expect(anyOf.currentEncodingShape, EncodingShape.complex);
    });
  });

  group('DeepNestedAnyOf', () {
    test('with enum1', () {
      final anyOf = DeepNestedAnyOf(enum1: Enum1.value1);

      expect(anyOf.toJson(), 'value1');
      expect(anyOf.toForm(explode: true, allowEmpty: true), 'value1');
      expect(anyOf.toSimple(explode: true, allowEmpty: true), 'value1');

      expect(anyOf.currentEncodingShape, EncodingShape.simple);
    });

    test('with nestedAnyOfInAnyOf', () {
      final anyOf = DeepNestedAnyOf(
        nestedAnyOfInAnyOf: NestedAnyOfInAnyOf(
          anyOfPrimitive: AnyOfPrimitive(string: 'test'),
          anyOfComplex: null,
        ),
      );

      expect(anyOf.toJson(), 'test');
      expect(anyOf.toForm(explode: true, allowEmpty: true), 'test');
      expect(anyOf.toSimple(explode: true, allowEmpty: true), 'test');

      expect(anyOf.currentEncodingShape, EncodingShape.simple);
    });
  });

  group('TwoLevelMixedAnyOfOneOf', () {
    test('with enum1', () {
      final anyOf = TwoLevelMixedAnyOfOneOf(
        twoLevelMixedAnyOfOneOfModel: TwoLevelMixedAnyOfOneOfModelEnum1(
          Enum1.value1,
        ),
      );

      expect(anyOf.toJson(), 'value1');
      expect(anyOf.toForm(explode: true, allowEmpty: true), 'value1');
      expect(anyOf.toSimple(explode: true, allowEmpty: true), 'value1');

      expect(anyOf.currentEncodingShape, EncodingShape.simple);
    });

    test('with enum2', () {
      final anyOf = TwoLevelMixedAnyOfOneOf(
        twoLevelMixedAnyOfOneOfModel: TwoLevelMixedAnyOfOneOfModelEnum2(
          Enum2.two,
        ),
      );

      expect(anyOf.toJson(), 2);
      expect(anyOf.toForm(explode: true, allowEmpty: true), '2');
      expect(anyOf.toSimple(explode: true, allowEmpty: true), '2');

      expect(anyOf.currentEncodingShape, EncodingShape.simple);
    });
  });
}
