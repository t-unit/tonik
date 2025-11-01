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
      expect(anyOf.toSimple(explode: false, allowEmpty: true), 'hello');
      expect(
        anyOf.toMatrix('anyOf', explode: false, allowEmpty: true),
        ';anyOf=hello',
      );
      expect(
        anyOf.toMatrix('anyOf', explode: true, allowEmpty: true),
        ';anyOf=hello',
      );
      expect(anyOf.toLabel(explode: true, allowEmpty: true), '.hello');
      expect(anyOf.toLabel(explode: false, allowEmpty: true), '.hello');

      expect(anyOf.currentEncodingShape, EncodingShape.simple);
    });

    test('integer', () {
      final anyOf = AnyOfPrimitive(int: 42);
      expect(anyOf.toJson(), 42);
      expect(anyOf.toForm(explode: true, allowEmpty: true), '42');
      expect(anyOf.toSimple(explode: true, allowEmpty: true), '42');
      expect(anyOf.toSimple(explode: false, allowEmpty: true), '42');
      expect(
        anyOf.toMatrix('anyOf', explode: false, allowEmpty: true),
        ';anyOf=42',
      );
      expect(
        anyOf.toMatrix('anyOf', explode: true, allowEmpty: true),
        ';anyOf=42',
      );
      expect(anyOf.toLabel(explode: true, allowEmpty: true), '.42');
      expect(anyOf.toLabel(explode: false, allowEmpty: true), '.42');

      expect(anyOf.currentEncodingShape, EncodingShape.simple);
    });

    test('boolean', () {
      final anyOf = AnyOfPrimitive(bool: true);
      expect(anyOf.toJson(), true);
      expect(anyOf.toForm(explode: true, allowEmpty: true), 'true');
      expect(anyOf.toSimple(explode: true, allowEmpty: true), 'true');
      expect(anyOf.toSimple(explode: false, allowEmpty: true), 'true');
      expect(
        anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
        ';asdf=true',
      );
      expect(
        anyOf.toMatrix('asdf', explode: true, allowEmpty: true),
        ';asdf=true',
      );
      expect(anyOf.toLabel(explode: true, allowEmpty: true), '.true');
      expect(anyOf.toLabel(explode: false, allowEmpty: true), '.true');

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
      expect(
        () => anyOf.toMatrix('paramName', explode: false, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
      expect(
        () => anyOf.toLabel(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );

      expect(anyOf.currentEncodingShape, EncodingShape.simple);
    });
  });

  group('AnyOfComplex', () {
    test('class1', () {
      final anyOf = AnyOfComplex(class1: Class1(name: 'Alice'));
      expect(anyOf.toJson(), {'name': 'Alice'});
      expect(anyOf.toForm(explode: true, allowEmpty: true), 'name=Alice');
      expect(anyOf.toSimple(explode: true, allowEmpty: true), 'name=Alice');
      expect(anyOf.toSimple(explode: false, allowEmpty: true), 'name,Alice');
      expect(
        anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
        ';asdf=name,Alice',
      );
      expect(
        anyOf.toMatrix('asdf', explode: true, allowEmpty: true),
        ';name=Alice',
      );
      expect(anyOf.toLabel(explode: true, allowEmpty: true), '.name=Alice');
      expect(anyOf.toLabel(explode: false, allowEmpty: true), '.name,Alice');

      expect(anyOf.currentEncodingShape, EncodingShape.complex);
    });

    test('class2', () {
      final anyOf = AnyOfComplex(class2: Class2(number: 123));
      expect(anyOf.toJson(), {'number': 123});
      expect(anyOf.toForm(explode: true, allowEmpty: true), 'number=123');
      expect(anyOf.toSimple(explode: true, allowEmpty: true), 'number=123');
      expect(anyOf.toSimple(explode: false, allowEmpty: true), 'number,123');
      expect(
        anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
        ';asdf=number,123',
      );
      expect(
        anyOf.toMatrix('asdf', explode: true, allowEmpty: true),
        ';number=123',
      );
      expect(anyOf.toLabel(explode: true, allowEmpty: true), '.number=123');
      expect(anyOf.toLabel(explode: false, allowEmpty: true), '.number,123');

      expect(anyOf.currentEncodingShape, EncodingShape.complex);
    });

    test('both classes', () {
      final anyOf = AnyOfComplex(
        class1: Class1(name: 'Alice'),
        class2: Class2(number: 123),
      );
      expect(anyOf.toJson(), {'name': 'Alice', 'number': 123});
      expect(
        anyOf.toForm(explode: true, allowEmpty: true),
        'name=Alice&number=123',
      );
      expect(
        anyOf.toSimple(explode: true, allowEmpty: true),
        'name=Alice,number=123',
      );
      expect(
        anyOf.toSimple(explode: false, allowEmpty: true),
        'name,Alice,number,123',
      );
      expect(
        anyOf.toMatrix('io', explode: false, allowEmpty: true),
        ';io=name,Alice,number,123',
      );
      expect(
        anyOf.toMatrix('io', explode: true, allowEmpty: true),
        ';name=Alice;number=123',
      );
      expect(
        anyOf.toLabel(explode: true, allowEmpty: true),
        '.name=Alice.number=123',
      );
      expect(
        anyOf.toLabel(explode: false, allowEmpty: true),
        '.name,Alice,number,123',
      );

      expect(anyOf.currentEncodingShape, EncodingShape.complex);
    });
  });

  group('AnyOfEnum', () {
    test('enum1', () {
      final anyOf = AnyOfEnum(enum1: Enum1.value1);
      expect(anyOf.toJson(), 'value1');
      expect(anyOf.toForm(explode: true, allowEmpty: true), 'value1');
      expect(anyOf.toSimple(explode: true, allowEmpty: true), 'value1');
      expect(anyOf.toSimple(explode: false, allowEmpty: true), 'value1');
      expect(
        anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
        ';asdf=value1',
      );
      expect(
        anyOf.toMatrix('asdf', explode: true, allowEmpty: true),
        ';asdf=value1',
      );
      expect(anyOf.toLabel(explode: true, allowEmpty: true), '.value1');
      expect(anyOf.toLabel(explode: false, allowEmpty: true), '.value1');

      expect(anyOf.currentEncodingShape, EncodingShape.simple);
    });

    test('enum2', () {
      final anyOf = AnyOfEnum(enum2: Enum2.two);
      expect(anyOf.toJson(), 2);
      expect(anyOf.toForm(explode: true, allowEmpty: true), '2');
      expect(anyOf.toSimple(explode: true, allowEmpty: true), '2');
      expect(anyOf.toSimple(explode: false, allowEmpty: true), '2');
      expect(
        anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
        ';asdf=2',
      );
      expect(
        anyOf.toMatrix('asdf', explode: true, allowEmpty: true),
        ';asdf=2',
      );
      expect(anyOf.toLabel(explode: true, allowEmpty: true), '.2');
      expect(anyOf.toLabel(explode: false, allowEmpty: true), '.2');

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
      expect(
        () => anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
      expect(
        () => anyOf.toLabel(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );

      expect(anyOf.currentEncodingShape, EncodingShape.simple);
    });
  });

  group('AnyOfMixed', () {
    test('integer', () {
      final anyOf = AnyOfMixed(int: 42);
      expect(anyOf.toJson(), 42);
      expect(anyOf.toForm(explode: true, allowEmpty: true), '42');
      expect(anyOf.toSimple(explode: true, allowEmpty: true), '42');
      expect(anyOf.toSimple(explode: false, allowEmpty: true), '42');
      expect(
        anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
        ';asdf=42',
      );
      expect(
        anyOf.toMatrix('asdf', explode: true, allowEmpty: true),
        ';asdf=42',
      );
      expect(anyOf.toLabel(explode: true, allowEmpty: true), '.42');
      expect(anyOf.toLabel(explode: false, allowEmpty: true), '.42');

      expect(anyOf.currentEncodingShape, EncodingShape.simple);
    });

    test('class2', () {
      final anyOf = AnyOfMixed(class2: Class2(number: 123));
      expect(anyOf.toJson(), {'number': 123});
      expect(anyOf.toForm(explode: true, allowEmpty: true), 'number=123');
      expect(anyOf.toSimple(explode: true, allowEmpty: true), 'number=123');
      expect(anyOf.toSimple(explode: false, allowEmpty: true), 'number,123');
      expect(
        anyOf.toMatrix('value', explode: false, allowEmpty: true),
        ';value=number,123',
      );
      expect(
        anyOf.toMatrix('value', explode: true, allowEmpty: true),
        ';number=123',
      );
      expect(anyOf.toLabel(explode: true, allowEmpty: true), '.number=123');
      expect(anyOf.toLabel(explode: false, allowEmpty: true), '.number,123');

      expect(anyOf.currentEncodingShape, EncodingShape.complex);
    });

    test('enum2', () {
      final anyOf = AnyOfMixed(enum2: Enum2.one);
      expect(anyOf.toJson(), 1);
      expect(anyOf.toForm(explode: true, allowEmpty: true), '1');
      expect(anyOf.toSimple(explode: true, allowEmpty: true), '1');
      expect(anyOf.toSimple(explode: false, allowEmpty: true), '1');
      expect(
        anyOf.toMatrix('value', explode: false, allowEmpty: true),
        ';value=1',
      );
      expect(
        anyOf.toMatrix('value', explode: true, allowEmpty: true),
        ';value=1',
      );
      expect(anyOf.toLabel(explode: true, allowEmpty: true), '.1');
      expect(anyOf.toLabel(explode: false, allowEmpty: true), '.1');

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
      expect(
        () => anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
      expect(
        () => anyOf.toLabel(explode: true, allowEmpty: true),
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
      expect(
        anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
        ';asdf=name,Bob,timestamp,123',
      );
      expect(
        anyOf.toMatrix('asdf', explode: true, allowEmpty: true),
        ';name=Bob;timestamp=123',
      );
      expect(
        anyOf.toLabel(explode: true, allowEmpty: true),
        '.name=Bob.timestamp=123',
      );
      expect(
        anyOf.toLabel(explode: false, allowEmpty: true),
        '.name,Bob,timestamp,123',
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
      expect(
        anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
        ';asdf=number,456,timestamp,123',
      );
      expect(
        anyOf.toMatrix('asdf', explode: true, allowEmpty: true),
        ';number=456;timestamp=123',
      );
      expect(
        anyOf.toLabel(explode: true, allowEmpty: true),
        '.number=456.timestamp=123',
      );
      expect(
        anyOf.toLabel(explode: false, allowEmpty: true),
        '.number,456,timestamp,123',
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
      expect(
        () => anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
      expect(
        () => anyOf.toLabel(explode: true, allowEmpty: true),
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
      expect(
        anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
        ';asdf=name,Charlie',
      );
      expect(
        anyOf.toMatrix('asdf', explode: true, allowEmpty: true),
        ';name=Charlie',
      );
      expect(anyOf.toLabel(explode: true, allowEmpty: true), '.name=Charlie');
      expect(anyOf.toLabel(explode: false, allowEmpty: true), '.name,Charlie');

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
      expect(anyOf.toSimple(explode: false, allowEmpty: true), 'value2');
      expect(
        anyOf.toMatrix('zxcv', explode: false, allowEmpty: true),
        ';zxcv=value2',
      );
      expect(
        anyOf.toMatrix('zxcv', explode: true, allowEmpty: true),
        ';zxcv=value2',
      );
      expect(anyOf.toLabel(explode: true, allowEmpty: true), '.value2');
      expect(anyOf.toLabel(explode: false, allowEmpty: true), '.value2');

      expect(anyOf.currentEncodingShape, EncodingShape.simple);
    });

    test('with number', () {
      final anyOf = NestedOneOfInAnyOf(oneOfEnum: null, num: 3.14);

      expect(anyOf.toJson(), 3.14);
      expect(anyOf.toForm(explode: true, allowEmpty: true), '3.14');
      expect(anyOf.toSimple(explode: true, allowEmpty: true), '3.14');
      expect(anyOf.toSimple(explode: false, allowEmpty: true), '3.14');
      expect(
        anyOf.toMatrix('zxcv', explode: false, allowEmpty: true),
        ';zxcv=3.14',
      );
      expect(
        anyOf.toMatrix('zxcv', explode: true, allowEmpty: true),
        ';zxcv=3.14',
      );
      expect(anyOf.toLabel(explode: true, allowEmpty: true), '.3.14');
      expect(anyOf.toLabel(explode: false, allowEmpty: true), '.3.14');

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
      expect(
        () => anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
      expect(
        () => anyOf.toLabel(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );

      expect(anyOf.currentEncodingShape, EncodingShape.simple);
    });
  });

  group('TwoLevelAnyOf', () {
    test('with string', () {
      final anyOf = TwoLevelAnyOf(string: 'test');

      expect(anyOf.toJson(), 'test');
      expect(anyOf.toForm(explode: true, allowEmpty: true), 'test');
      expect(anyOf.toSimple(explode: true, allowEmpty: true), 'test');
      expect(anyOf.toSimple(explode: false, allowEmpty: true), 'test');
      expect(
        anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
        ';asdf=test',
      );
      expect(
        anyOf.toMatrix('asdf', explode: true, allowEmpty: true),
        ';asdf=test',
      );
      expect(anyOf.toLabel(explode: true, allowEmpty: true), '.test');
      expect(anyOf.toLabel(explode: false, allowEmpty: true), '.test');

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
      expect(
        anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
        ';asdf=name,test',
      );
      expect(
        anyOf.toMatrix('asdf', explode: true, allowEmpty: true),
        ';name=test',
      );
      expect(anyOf.toLabel(explode: true, allowEmpty: true), '.name=test');
      expect(anyOf.toLabel(explode: false, allowEmpty: true), '.name,test');

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
      expect(
        anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
        ';asdf=number,42',
      );
      expect(
        anyOf.toMatrix('asdf', explode: true, allowEmpty: true),
        ';number=42',
      );
      expect(anyOf.toLabel(explode: true, allowEmpty: true), '.number=42');
      expect(anyOf.toLabel(explode: false, allowEmpty: true), '.number,42');

      expect(anyOf.currentEncodingShape, EncodingShape.complex);
    });
  });

  group('ThreeLevelAnyOf', () {
    test('with string', () {
      final anyOf = ThreeLevelAnyOf(string: 'deep');

      expect(anyOf.toJson(), 'deep');
      expect(anyOf.toForm(explode: true, allowEmpty: true), 'deep');
      expect(anyOf.toSimple(explode: true, allowEmpty: true), 'deep');
      expect(anyOf.toSimple(explode: false, allowEmpty: true), 'deep');
      expect(
        anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
        ';asdf=deep',
      );
      expect(
        anyOf.toMatrix('asdf', explode: true, allowEmpty: true),
        ';asdf=deep',
      );
      expect(anyOf.toLabel(explode: true, allowEmpty: true), '.deep');
      expect(anyOf.toLabel(explode: false, allowEmpty: true), '.deep');

      expect(anyOf.currentEncodingShape, EncodingShape.simple);
    });

    test('with enum1', () {
      final anyOf = ThreeLevelAnyOf(
        threeLevelAnyOfModel: ThreeLevelAnyOfModel(enum1: Enum1.value1),
      );

      expect(anyOf.toJson(), 'value1');
      expect(anyOf.toForm(explode: true, allowEmpty: true), 'value1');
      expect(anyOf.toSimple(explode: true, allowEmpty: true), 'value1');
      expect(anyOf.toSimple(explode: false, allowEmpty: true), 'value1');
      expect(
        anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
        ';asdf=value1',
      );
      expect(
        anyOf.toMatrix('asdf', explode: true, allowEmpty: true),
        ';asdf=value1',
      );
      expect(anyOf.toLabel(explode: true, allowEmpty: true), '.value1');
      expect(anyOf.toLabel(explode: false, allowEmpty: true), '.value1');

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
      expect(
        anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
        ';asdf=name,test',
      );
      expect(
        anyOf.toMatrix('asdf', explode: true, allowEmpty: true),
        ';name=test',
      );
      expect(anyOf.toLabel(explode: true, allowEmpty: true), '.name=test');
      expect(anyOf.toLabel(explode: false, allowEmpty: true), '.name,test');

      expect(anyOf.currentEncodingShape, EncodingShape.complex);
    });
  });

  group('DeepNestedAnyOf', () {
    test('with enum1', () {
      final anyOf = DeepNestedAnyOf(enum1: Enum1.value1);

      expect(anyOf.toJson(), 'value1');
      expect(anyOf.toForm(explode: true, allowEmpty: true), 'value1');
      expect(anyOf.toSimple(explode: true, allowEmpty: true), 'value1');
      expect(anyOf.toSimple(explode: false, allowEmpty: true), 'value1');
      expect(
        anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
        ';asdf=value1',
      );
      expect(
        anyOf.toMatrix('asdf', explode: true, allowEmpty: true),
        ';asdf=value1',
      );
      expect(anyOf.toLabel(explode: true, allowEmpty: true), '.value1');
      expect(anyOf.toLabel(explode: false, allowEmpty: true), '.value1');

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
      expect(anyOf.toSimple(explode: false, allowEmpty: true), 'test');
      expect(
        anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
        ';asdf=test',
      );
      expect(
        anyOf.toMatrix('asdf', explode: true, allowEmpty: true),
        ';asdf=test',
      );
      expect(anyOf.toLabel(explode: true, allowEmpty: true), '.test');
      expect(anyOf.toLabel(explode: false, allowEmpty: true), '.test');

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
      expect(anyOf.toSimple(explode: false, allowEmpty: true), 'value1');
      expect(
        anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
        ';asdf=value1',
      );
      expect(
        anyOf.toMatrix('asdf', explode: true, allowEmpty: true),
        ';asdf=value1',
      );
      expect(anyOf.toLabel(explode: true, allowEmpty: true), '.value1');
      expect(anyOf.toLabel(explode: false, allowEmpty: true), '.value1');

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
      expect(anyOf.toSimple(explode: false, allowEmpty: true), '2');
      expect(
        anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
        ';asdf=2',
      );
      expect(
        anyOf.toMatrix('asdf', explode: true, allowEmpty: true),
        ';asdf=2',
      );
      expect(anyOf.toLabel(explode: true, allowEmpty: true), '.2');
      expect(anyOf.toLabel(explode: false, allowEmpty: true), '.2');

      expect(anyOf.currentEncodingShape, EncodingShape.simple);
    });
  });

  group('AnyOfWithSimpleList', () {
    test('string list', () {
      final anyOf = AnyOfWithSimpleList(list2: ['test', 'test2']);

      expect(anyOf.toJson(), ['test', 'test2']);
      expect(anyOf.toForm(explode: true, allowEmpty: true), 'test,test2');
      expect(anyOf.toSimple(explode: true, allowEmpty: true), 'test,test2');
      expect(anyOf.toSimple(explode: false, allowEmpty: true), 'test,test2');
      expect(
        anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
        ';asdf=test,test2',
      );
      expect(
        anyOf.toMatrix('asdf', explode: true, allowEmpty: true),
        ';asdf=test;asdf=test2',
      );
      expect(anyOf.toLabel(explode: true, allowEmpty: true), '.test.test2');
      expect(anyOf.toLabel(explode: false, allowEmpty: true), '.test,test2');

      expect(anyOf.currentEncodingShape, EncodingShape.complex);
    });

    test('integer list', () {
      final anyOf = AnyOfWithSimpleList(list: [1, 2, 3]);

      expect(anyOf.toJson(), [1, 2, 3]);
      expect(anyOf.toForm(explode: true, allowEmpty: true), '1,2,3');
      expect(anyOf.toSimple(explode: true, allowEmpty: true), '1,2,3');
      expect(anyOf.toSimple(explode: false, allowEmpty: true), '1,2,3');
      expect(
        anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
        ';asdf=1,2,3',
      );
      expect(
        anyOf.toMatrix('asdf', explode: true, allowEmpty: true),
        ';asdf=1;asdf=2;asdf=3',
      );
      expect(anyOf.toLabel(explode: true, allowEmpty: true), '.1.2.3');
      expect(anyOf.toLabel(explode: false, allowEmpty: true), '.1,2,3');

      expect(anyOf.currentEncodingShape, EncodingShape.complex);
    });

    test('both lists', () {
      final anyOf = AnyOfWithSimpleList(
        list: [1, 2, 3],
        list2: ['test', 'test2'],
      );

      expect(anyOf.toJson, throwsA(isA<EncodingException>()));
      expect(
        () => anyOf.toForm(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
      expect(
        () => anyOf.toMatrix('asdf', explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
      expect(
        () => anyOf.toSimple(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );

      expect(anyOf.currentEncodingShape, EncodingShape.complex);
    });
  });

  group('AnyOfWithComplexList', () {
    test('class1 list', () {
      final anyOf = AnyOfWithComplexList(
        list: [
          Class1(name: 'test'),
          Class1(name: 'test2'),
        ],
      );

      expect(anyOf.toJson(), [
        {'name': 'test'},
        {'name': 'test2'},
      ]);
      expect(
        () => anyOf.toForm(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
      expect(
        () => anyOf.toSimple(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
      expect(
        () => anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
      expect(
        () => anyOf.toMatrix('asdf', explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
      expect(
        () => anyOf.toLabel(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );

      expect(anyOf.currentEncodingShape, EncodingShape.complex);
    });

    test('class2 list', () {
      final anyOf = AnyOfWithComplexList(
        list2: [Class2(number: 1), Class2(number: 2)],
      );

      expect(anyOf.toJson(), [
        {'number': 1},
        {'number': 2},
      ]);
      expect(
        () => anyOf.toForm(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
      expect(
        () => anyOf.toSimple(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
      expect(
        () => anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
      expect(
        () => anyOf.toMatrix('asdf', explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
      expect(
        () => anyOf.toLabel(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );

      expect(anyOf.currentEncodingShape, EncodingShape.complex);
    });

    test('string', () {
      final anyOf = AnyOfWithComplexList(string: 'asdf asdf');

      expect(anyOf.toJson(), 'asdf asdf');
      expect(anyOf.toForm(explode: true, allowEmpty: true), 'asdf%20asdf');
      expect(anyOf.toSimple(explode: true, allowEmpty: true), 'asdf%20asdf');
      expect(anyOf.toSimple(explode: false, allowEmpty: true), 'asdf%20asdf');
      expect(
        anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
        ';asdf=asdf%20asdf',
      );
      expect(
        anyOf.toMatrix('asdf', explode: true, allowEmpty: true),
        ';asdf=asdf%20asdf',
      );
      expect(anyOf.toLabel(explode: true, allowEmpty: true), '.asdf%20asdf');
      expect(anyOf.toLabel(explode: false, allowEmpty: true), '.asdf%20asdf');

      expect(anyOf.currentEncodingShape, EncodingShape.simple);
    });

    test('all together', () {
      final anyOf = AnyOfWithComplexList(
        list: [Class1(name: 'test')],
        list2: [Class2(number: 1)],
        string: 'asdf',
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
      expect(
        () => anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
      expect(
        () => anyOf.toLabel(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );

      expect(anyOf.currentEncodingShape, EncodingShape.mixed);
    });
  });

  group('AnyOfWithMixedLists', () {
    test('integer list', () {
      final anyOf = AnyOfWithMixedLists(list2: [1, 2, 3]);

      expect(anyOf.toJson(), [1, 2, 3]);
      expect(anyOf.toForm(explode: true, allowEmpty: true), '1,2,3');
      expect(anyOf.toSimple(explode: true, allowEmpty: true), '1,2,3');
      expect(anyOf.toSimple(explode: false, allowEmpty: true), '1,2,3');
      expect(
        anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
        ';asdf=1,2,3',
      );
      expect(
        anyOf.toMatrix('asdf', explode: true, allowEmpty: true),
        ';asdf=1;asdf=2;asdf=3',
      );
      expect(anyOf.toLabel(explode: true, allowEmpty: true), '.1.2.3');
      expect(anyOf.toLabel(explode: false, allowEmpty: true), '.1,2,3');

      expect(anyOf.currentEncodingShape, EncodingShape.complex);
    });

    test('class1 list', () {
      final anyOf = AnyOfWithMixedLists(
        list: [
          Class1(name: 'test'),
          Class1(name: 'test2'),
        ],
      );

      expect(anyOf.toJson(), [
        {'name': 'test'},
        {'name': 'test2'},
      ]);
      expect(
        () => anyOf.toForm(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
      expect(
        () => anyOf.toSimple(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
      expect(
        () => anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
      expect(
        () => anyOf.toMatrix('asdf', explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
      expect(
        () => anyOf.toLabel(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );

      expect(anyOf.currentEncodingShape, EncodingShape.complex);
    });

    test('boolean', () {
      final anyOf = AnyOfWithMixedLists(bool: true);

      expect(anyOf.toJson(), true);
      expect(anyOf.toForm(explode: true, allowEmpty: true), 'true');
      expect(anyOf.toSimple(explode: true, allowEmpty: true), 'true');
      expect(anyOf.toSimple(explode: false, allowEmpty: true), 'true');
      expect(
        anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
        ';asdf=true',
      );
      expect(
        anyOf.toMatrix('asdf', explode: true, allowEmpty: true),
        ';asdf=true',
      );
      expect(anyOf.toLabel(explode: true, allowEmpty: true), '.true');
      expect(anyOf.toLabel(explode: false, allowEmpty: true), '.true');

      expect(anyOf.currentEncodingShape, EncodingShape.simple);
    });

    test('all together', () {
      final anyOf = AnyOfWithMixedLists(
        list: [Class1(name: 'test')],
        list2: [1, 2, 3],
        bool: false,
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
      expect(
        () => anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
      expect(
        () => anyOf.toLabel(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );

      expect(anyOf.currentEncodingShape, EncodingShape.mixed);
    });
  });

  group('AnyOfWithEnumList', () {
    test('enum 1', () {
      final anyOf = AnyOfWithEnumList(list: [Enum1.value1, Enum1.value2]);

      expect(anyOf.toJson(), ['value1', 'value2']);
      expect(anyOf.toForm(explode: true, allowEmpty: true), 'value1,value2');
      expect(anyOf.toSimple(explode: true, allowEmpty: true), 'value1,value2');
      expect(anyOf.toSimple(explode: false, allowEmpty: true), 'value1,value2');
      expect(
        anyOf.toMatrix('anyOf', explode: false, allowEmpty: true),
        ';anyOf=value1,value2',
      );
      expect(
        anyOf.toMatrix('anyOf', explode: true, allowEmpty: true),
        ';anyOf=value1;anyOf=value2',
      );
      expect(anyOf.toLabel(explode: true, allowEmpty: true), '.value1.value2');
      expect(anyOf.toLabel(explode: false, allowEmpty: true), '.value1,value2');

      expect(anyOf.currentEncodingShape, EncodingShape.complex);
    });

    test('enum 2', () {
      final anyOf = AnyOfWithEnumList(list2: [Enum2.one, Enum2.two]);

      expect(anyOf.toJson(), [1, 2]);
      expect(anyOf.toForm(explode: true, allowEmpty: true), '1,2');
      expect(anyOf.toSimple(explode: true, allowEmpty: true), '1,2');
      expect(anyOf.toSimple(explode: false, allowEmpty: true), '1,2');
      expect(
        anyOf.toMatrix('anyOf', explode: false, allowEmpty: true),
        ';anyOf=1,2',
      );
      expect(
        anyOf.toMatrix('anyOf', explode: true, allowEmpty: true),
        ';anyOf=1;anyOf=2',
      );
      expect(anyOf.toLabel(explode: true, allowEmpty: true), '.1.2');
      expect(anyOf.toLabel(explode: false, allowEmpty: true), '.1,2');

      expect(anyOf.currentEncodingShape, EncodingShape.complex);
    });

    test('enum 1 and string', () {
      final anyOf = AnyOfWithEnumList(
        list: [Enum1.value1, Enum1.value2],
        string: 'test',
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
      expect(
        () => anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
      expect(
        () => anyOf.toLabel(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );

      expect(anyOf.currentEncodingShape, EncodingShape.mixed);
    });

    test('enum 2 and string', () {
      final anyOf = AnyOfWithEnumList(
        list2: [Enum2.one, Enum2.two],
        string: 'test',
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
      expect(
        () => anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
      expect(
        () => anyOf.toLabel(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );

      expect(anyOf.currentEncodingShape, EncodingShape.mixed);
    });
  });

  group('NestedListInAnyOf', () {
    test('list of strings', () {
      final anyOf = NestedListInAnyOf(
        list: [
          ['test', 'test2'],
        ],
      );

      expect(anyOf.toJson(), [
        ['test', 'test2'],
      ]);
      expect(
        () => anyOf.toForm(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
      expect(
        () => anyOf.toSimple(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
      expect(
        () => anyOf.toSimple(explode: false, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
      expect(
        () => anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
      expect(
        () => anyOf.toMatrix('asdf', explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
      expect(
        () => anyOf.toLabel(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );

      expect(anyOf.currentEncodingShape, EncodingShape.complex);
    });

    test('string', () {
      final anyOf = NestedListInAnyOf(string: 'just a string');

      expect(anyOf.toJson(), 'just a string');
      expect(
        anyOf.toForm(explode: true, allowEmpty: true),
        'just%20a%20string',
      );
      expect(
        anyOf.toSimple(explode: true, allowEmpty: true),
        'just%20a%20string',
      );
      expect(
        anyOf.toSimple(explode: false, allowEmpty: true),
        'just%20a%20string',
      );
      expect(
        anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
        ';asdf=just%20a%20string',
      );
      expect(
        anyOf.toMatrix('asdf', explode: true, allowEmpty: true),
        ';asdf=just%20a%20string',
      );
      expect(
        anyOf.toLabel(explode: true, allowEmpty: true),
        '.just%20a%20string',
      );
      expect(
        anyOf.toLabel(explode: false, allowEmpty: true),
        '.just%20a%20string',
      );

      expect(anyOf.currentEncodingShape, EncodingShape.simple);
    });

    test('both', () {
      final anyOf = NestedListInAnyOf(
        list: [
          ['test', 'test2'],
        ],
        string: 'just a string',
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
      expect(
        () => anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
      expect(
        () => anyOf.toLabel(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );

      expect(anyOf.currentEncodingShape, EncodingShape.mixed);
    });
  });

  group('AnyOfWithListOfComposites', () {
    test('array', () {
      final anyOf = AnyOfWithListOfComposites(
        list: [
          AnyOfWithListOfCompositesArrayAllOfModel(
            anyOfWithListOfCompositesArrayAllOfModel2:
                AnyOfWithListOfCompositesArrayAllOfModel2(extra: 'extra'),
            class1: Class1(name: 'name'),
          ),
        ],
      );

      expect(anyOf.toJson(), [
        {'extra': 'extra', 'name': 'name'},
      ]);
      expect(
        () => anyOf.toForm(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
      expect(
        () => anyOf.toSimple(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
      expect(
        () => anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
      expect(
        () => anyOf.toMatrix('asdf', explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );

      expect(anyOf.currentEncodingShape, EncodingShape.complex);
    });

    test('string', () {
      final anyOf = AnyOfWithListOfComposites(string: 'test string');

      expect(anyOf.toJson(), 'test string');
      expect(anyOf.toForm(explode: true, allowEmpty: true), 'test%20string');
      expect(anyOf.toSimple(explode: true, allowEmpty: true), 'test%20string');
      expect(anyOf.toSimple(explode: false, allowEmpty: true), 'test%20string');
      expect(
        anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
        ';asdf=test%20string',
      );
      expect(
        anyOf.toMatrix('asdf', explode: true, allowEmpty: true),
        ';asdf=test%20string',
      );
      expect(anyOf.toLabel(explode: true, allowEmpty: true), '.test%20string');
      expect(anyOf.toLabel(explode: false, allowEmpty: true), '.test%20string');

      expect(anyOf.currentEncodingShape, EncodingShape.simple);
    });

    test('both', () {
      final anyOf = AnyOfWithListOfComposites(
        list: [
          AnyOfWithListOfCompositesArrayAllOfModel(
            anyOfWithListOfCompositesArrayAllOfModel2:
                AnyOfWithListOfCompositesArrayAllOfModel2(extra: 'extra'),
            class1: Class1(name: 'name'),
          ),
        ],
        string: 'test string',
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
      expect(
        () => anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
      expect(
        () => anyOf.toLabel(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );

      expect(anyOf.currentEncodingShape, EncodingShape.mixed);
    });
  });
}
