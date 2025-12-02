import 'package:composition_api/composition_api.dart';
import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  group('AnyOfPrimitive', () {
    group('string', () {
      late AnyOfPrimitive anyOf;

      setUp(() {
        anyOf = AnyOfPrimitive(string: 'hello');
      });

      test('toJson', () {
        expect(anyOf.toJson(), 'hello');
      });

      test('json roundtrip', () {
        final json = anyOf.toJson();
        final reconstructed = AnyOfPrimitive.fromJson(json);
        expect(reconstructed, anyOf);
      });

      test('toForm - explode true', () {
        expect(anyOf.toForm(explode: true, allowEmpty: true), 'hello');
      });

      test('form roundtrip - explode true', () {
        final form = anyOf.toForm(explode: true, allowEmpty: true);
        final reconstructed = AnyOfPrimitive.fromForm(form, explode: true);
        expect(reconstructed, anyOf);
      });

      test('toForm - explode false', () {
        expect(anyOf.toForm(explode: false, allowEmpty: true), 'hello');
      });

      test('form roundtrip - explode false', () {
        final form = anyOf.toForm(explode: false, allowEmpty: true);
        final reconstructed = AnyOfPrimitive.fromForm(form, explode: false);
        expect(reconstructed, anyOf);
      });

      test('toSimple - explode true', () {
        expect(anyOf.toSimple(explode: true, allowEmpty: true), 'hello');
      });

      test('simple roundtrip - explode true', () {
        final simple = anyOf.toSimple(explode: true, allowEmpty: true);
        final reconstructed = AnyOfPrimitive.fromSimple(simple, explode: true);
        expect(reconstructed, anyOf);
      });

      test('toSimple - explode false', () {
        expect(anyOf.toSimple(explode: false, allowEmpty: true), 'hello');
      });

      test('simple roundtrip - explode false', () {
        final simple = anyOf.toSimple(explode: false, allowEmpty: true);
        final reconstructed = AnyOfPrimitive.fromSimple(simple, explode: false);
        expect(reconstructed, anyOf);
      });

      test('toMatrix - explode false', () {
        expect(
          anyOf.toMatrix('anyOf', explode: false, allowEmpty: true),
          ';anyOf=hello',
        );
      });

      test('toMatrix - explode true', () {
        expect(
          anyOf.toMatrix('anyOf', explode: true, allowEmpty: true),
          ';anyOf=hello',
        );
      });

      test('toLabel - explode true', () {
        expect(anyOf.toLabel(explode: true, allowEmpty: true), '.hello');
      });

      test('toLabel - explode false', () {
        expect(anyOf.toLabel(explode: false, allowEmpty: true), '.hello');
      });

      test('currentEncodingShape', () {
        expect(anyOf.currentEncodingShape, EncodingShape.simple);
      });
    });

    group('integer', () {
      late AnyOfPrimitive anyOf;

      setUp(() {
        anyOf = AnyOfPrimitive(int: 42);
      });

      test('toJson', () {
        expect(anyOf.toJson(), 42);
      });

      test('json roundtrip', () {
        final json = anyOf.toJson();
        final reconstructed = AnyOfPrimitive.fromJson(json);
        expect(reconstructed, anyOf);
      });

      test('toForm - explode true', () {
        expect(anyOf.toForm(explode: true, allowEmpty: true), '42');
      });

      test('form roundtrip - explode true', () {
        final form = anyOf.toForm(explode: true, allowEmpty: true);
        final reconstructed = AnyOfPrimitive.fromForm(form, explode: true);
        // After form roundtrip, both int and string fields are set because
        // "42" can be decoded as both an integer and a string.
        expect(reconstructed.int, 42);
        expect(reconstructed.string, '42');
        expect(reconstructed.toForm(explode: true, allowEmpty: true), form);
      });

      test('toForm - explode false', () {
        expect(anyOf.toForm(explode: false, allowEmpty: true), '42');
      });

      test('form roundtrip - explode false', () {
        final form = anyOf.toForm(explode: false, allowEmpty: true);
        final reconstructed = AnyOfPrimitive.fromForm(form, explode: false);
        // After form roundtrip, both int and string fields are set because
        // "42" can be decoded as both an integer and a string.
        expect(reconstructed.int, 42);
        expect(reconstructed.string, '42');
        expect(reconstructed.toForm(explode: false, allowEmpty: true), form);
      });

      test('toSimple - explode true', () {
        expect(anyOf.toSimple(explode: true, allowEmpty: true), '42');
      });

      test('simple roundtrip - explode true', () {
        final simple = anyOf.toSimple(explode: true, allowEmpty: true);
        final reconstructed = AnyOfPrimitive.fromSimple(simple, explode: true);
        // After simple roundtrip, both int and string fields are set because
        // "42" can be decoded as both an integer and a string.
        expect(reconstructed.int, 42);
        expect(reconstructed.string, '42');
        expect(reconstructed.toSimple(explode: true, allowEmpty: true), simple);
      });

      test('toSimple - explode false', () {
        expect(anyOf.toSimple(explode: false, allowEmpty: true), '42');
      });

      test('simple roundtrip - explode false', () {
        final simple = anyOf.toSimple(explode: false, allowEmpty: true);
        final reconstructed = AnyOfPrimitive.fromSimple(simple, explode: false);
        // After simple roundtrip, both int and string fields are set because
        // "42" can be decoded as both an integer and a string.
        expect(reconstructed.int, 42);
        expect(reconstructed.string, '42');
        expect(
          reconstructed.toSimple(explode: false, allowEmpty: true),
          simple,
        );
      });

      test('toMatrix - explode false', () {
        expect(
          anyOf.toMatrix('anyOf', explode: false, allowEmpty: true),
          ';anyOf=42',
        );
      });

      test('toMatrix - explode true', () {
        expect(
          anyOf.toMatrix('anyOf', explode: true, allowEmpty: true),
          ';anyOf=42',
        );
      });

      test('toLabel - explode true', () {
        expect(anyOf.toLabel(explode: true, allowEmpty: true), '.42');
      });

      test('toLabel - explode false', () {
        expect(anyOf.toLabel(explode: false, allowEmpty: true), '.42');
      });

      test('currentEncodingShape', () {
        expect(anyOf.currentEncodingShape, EncodingShape.simple);
      });
    });

    group('boolean', () {
      late AnyOfPrimitive anyOf;

      setUp(() {
        anyOf = AnyOfPrimitive(bool: true);
      });

      test('toJson', () {
        expect(anyOf.toJson(), true);
      });

      test('json roundtrip', () {
        final json = anyOf.toJson();
        final reconstructed = AnyOfPrimitive.fromJson(json);
        expect(reconstructed, anyOf);
      });

      test('toForm - explode true', () {
        expect(anyOf.toForm(explode: true, allowEmpty: true), 'true');
      });

      test('form roundtrip - explode true', () {
        final form = anyOf.toForm(explode: true, allowEmpty: true);
        final reconstructed = AnyOfPrimitive.fromForm(form, explode: true);
        // After form roundtrip, both bool and string fields are set because
        // "true" can be decoded as both a boolean and a string.
        expect(reconstructed.bool, true);
        expect(reconstructed.string, 'true');
        expect(reconstructed.toForm(explode: true, allowEmpty: true), form);
      });

      test('toForm - explode false', () {
        expect(anyOf.toForm(explode: false, allowEmpty: true), 'true');
      });

      test('form roundtrip - explode false', () {
        final form = anyOf.toForm(explode: false, allowEmpty: true);
        final reconstructed = AnyOfPrimitive.fromForm(form, explode: false);
        // After form roundtrip, both bool and string fields are set because
        // "true" can be decoded as both a boolean and a string.
        expect(reconstructed.bool, true);
        expect(reconstructed.string, 'true');
        expect(reconstructed.toForm(explode: false, allowEmpty: true), form);
      });

      test('toSimple - explode true', () {
        expect(anyOf.toSimple(explode: true, allowEmpty: true), 'true');
      });

      test('simple roundtrip - explode true', () {
        final simple = anyOf.toSimple(explode: true, allowEmpty: true);
        final reconstructed = AnyOfPrimitive.fromSimple(simple, explode: true);
        // After simple roundtrip, both bool and string fields are set because
        // "true" can be decoded as both a boolean and a string.
        expect(reconstructed.bool, true);
        expect(reconstructed.string, 'true');
        expect(reconstructed.toSimple(explode: true, allowEmpty: true), simple);
      });

      test('toSimple - explode false', () {
        expect(anyOf.toSimple(explode: false, allowEmpty: true), 'true');
      });

      test('simple roundtrip - explode false', () {
        final simple = anyOf.toSimple(explode: false, allowEmpty: true);
        final reconstructed = AnyOfPrimitive.fromSimple(simple, explode: false);
        // After simple roundtrip, both bool and string fields are set because
        // "true" can be decoded as both a boolean and a string.
        expect(reconstructed.bool, true);
        expect(reconstructed.string, 'true');
        expect(
          reconstructed.toSimple(explode: false, allowEmpty: true),
          simple,
        );
      });

      test('toMatrix - explode false', () {
        expect(
          anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
          ';asdf=true',
        );
      });

      test('toMatrix - explode true', () {
        expect(
          anyOf.toMatrix('asdf', explode: true, allowEmpty: true),
          ';asdf=true',
        );
      });

      test('toLabel - explode true', () {
        expect(anyOf.toLabel(explode: true, allowEmpty: true), '.true');
      });

      test('toLabel - explode false', () {
        expect(anyOf.toLabel(explode: false, allowEmpty: true), '.true');
      });

      test('currentEncodingShape', () {
        expect(anyOf.currentEncodingShape, EncodingShape.simple);
      });
    });

    group('multiple values', () {
      late AnyOfPrimitive anyOf;

      setUp(() {
        anyOf = AnyOfPrimitive(string: 'hello', int: 42);
      });

      test('toJson throws EncodingException', () {
        expect(anyOf.toJson, throwsA(isA<EncodingException>()));
      });

      test('toForm throws EncodingException', () {
        expect(
          () => anyOf.toForm(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toSimple throws EncodingException', () {
        expect(
          () => anyOf.toSimple(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toMatrix throws EncodingException', () {
        expect(
          () => anyOf.toMatrix('paramName', explode: false, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toLabel - explode true throws EncodingException', () {
        expect(
          () => anyOf.toLabel(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toLabel - explode false throws EncodingException', () {
        expect(
          () => anyOf.toLabel(explode: false, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('currentEncodingShape', () {
        expect(anyOf.currentEncodingShape, EncodingShape.simple);
      });
    });
  });

  group('AnyOfComplex', () {
    group('class1', () {
      late AnyOfComplex anyOf;

      setUp(() {
        anyOf = AnyOfComplex(class1: Class1(name: 'Alice'));
      });

      test('toJson', () {
        expect(anyOf.toJson(), {'name': 'Alice'});
      });

      test('json roundtrip', () {
        final json = anyOf.toJson();
        final reconstructed = AnyOfComplex.fromJson(json);
        expect(reconstructed, anyOf);
      });

      test('toForm - explode true', () {
        expect(anyOf.toForm(explode: true, allowEmpty: true), 'name=Alice');
      });

      test('form roundtrip - explode true', () {
        final form = anyOf.toForm(explode: true, allowEmpty: true);
        final reconstructed = AnyOfComplex.fromForm(form, explode: true);
        expect(reconstructed, anyOf);
      });

      test('toForm - explode false', () {
        expect(anyOf.toForm(explode: false, allowEmpty: true), 'name,Alice');
      });

      test('form roundtrip - explode false', () {
        final form = anyOf.toForm(explode: false, allowEmpty: true);
        final reconstructed = AnyOfComplex.fromForm(form, explode: false);
        expect(reconstructed, anyOf);
      });

      test('toSimple - explode true', () {
        expect(anyOf.toSimple(explode: true, allowEmpty: true), 'name=Alice');
      });

      test('simple roundtrip - explode true', () {
        final simple = anyOf.toSimple(explode: true, allowEmpty: true);
        final reconstructed = AnyOfComplex.fromSimple(simple, explode: true);
        expect(reconstructed, anyOf);
      });

      test('toSimple - explode false', () {
        expect(anyOf.toSimple(explode: false, allowEmpty: true), 'name,Alice');
      });

      test('simple roundtrip - explode false', () {
        final simple = anyOf.toSimple(explode: false, allowEmpty: true);
        final reconstructed = AnyOfComplex.fromSimple(simple, explode: false);
        expect(reconstructed, anyOf);
      });

      test('toMatrix - explode false', () {
        expect(
          anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
          ';asdf=name,Alice',
        );
      });

      test('toMatrix - explode true', () {
        expect(
          anyOf.toMatrix('asdf', explode: true, allowEmpty: true),
          ';name=Alice',
        );
      });

      test('toLabel - explode true', () {
        expect(anyOf.toLabel(explode: true, allowEmpty: true), '.name=Alice');
      });

      test('toLabel - explode false', () {
        expect(anyOf.toLabel(explode: false, allowEmpty: true), '.name,Alice');
      });

      test('currentEncodingShape', () {
        expect(anyOf.currentEncodingShape, EncodingShape.complex);
      });
    });

    group('class2', () {
      late AnyOfComplex anyOf;

      setUp(() {
        anyOf = AnyOfComplex(class2: Class2(number: 123));
      });

      test('toJson', () {
        expect(anyOf.toJson(), {'number': 123});
      });

      test('json roundtrip', () {
        final json = anyOf.toJson();
        final reconstructed = AnyOfComplex.fromJson(json);
        expect(reconstructed, anyOf);
      });

      test('toForm - explode true', () {
        expect(anyOf.toForm(explode: true, allowEmpty: true), 'number=123');
      });

      test('form roundtrip - explode true', () {
        final form = anyOf.toForm(explode: true, allowEmpty: true);
        final reconstructed = AnyOfComplex.fromForm(form, explode: true);
        expect(reconstructed, anyOf);
      });

      test('toForm - explode false', () {
        expect(anyOf.toForm(explode: false, allowEmpty: true), 'number,123');
      });

      test('form roundtrip - explode false', () {
        final form = anyOf.toForm(explode: false, allowEmpty: true);
        final reconstructed = AnyOfComplex.fromForm(form, explode: false);
        expect(reconstructed, anyOf);
      });

      test('toSimple - explode true', () {
        expect(anyOf.toSimple(explode: true, allowEmpty: true), 'number=123');
      });

      test('simple roundtrip - explode true', () {
        final simple = anyOf.toSimple(explode: true, allowEmpty: true);
        final reconstructed = AnyOfComplex.fromSimple(simple, explode: true);
        expect(reconstructed, anyOf);
      });

      test('toSimple - explode false', () {
        expect(anyOf.toSimple(explode: false, allowEmpty: true), 'number,123');
      });

      test('simple roundtrip - explode false', () {
        final simple = anyOf.toSimple(explode: false, allowEmpty: true);
        final reconstructed = AnyOfComplex.fromSimple(simple, explode: false);
        expect(reconstructed, anyOf);
      });

      test('toMatrix - explode false', () {
        expect(
          anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
          ';asdf=number,123',
        );
      });

      test('toMatrix - explode true', () {
        expect(
          anyOf.toMatrix('asdf', explode: true, allowEmpty: true),
          ';number=123',
        );
      });

      test('toLabel - explode true', () {
        expect(anyOf.toLabel(explode: true, allowEmpty: true), '.number=123');
      });

      test('toLabel - explode false', () {
        expect(anyOf.toLabel(explode: false, allowEmpty: true), '.number,123');
      });

      test('currentEncodingShape', () {
        expect(anyOf.currentEncodingShape, EncodingShape.complex);
      });
    });

    group('both classes', () {
      late AnyOfComplex anyOf;

      setUp(() {
        anyOf = AnyOfComplex(
          class1: Class1(name: 'Alice'),
          class2: Class2(number: 123),
        );
      });

      test('toJson', () {
        expect(anyOf.toJson(), {'name': 'Alice', 'number': 123});
      });

      test('json roundtrip', () {
        final json = anyOf.toJson();
        final reconstructed = AnyOfComplex.fromJson(json);
        expect(reconstructed, anyOf);
      });

      test('toForm - explode true', () {
        expect(
          anyOf.toForm(explode: true, allowEmpty: true),
          'name=Alice&number=123',
        );
      });

      test('form roundtrip - explode true', () {
        final form = anyOf.toForm(explode: true, allowEmpty: true);
        final reconstructed = AnyOfComplex.fromForm(form, explode: true);
        expect(reconstructed, anyOf);
      });

      test('toForm - explode false', () {
        expect(
          anyOf.toForm(explode: false, allowEmpty: true),
          'name,Alice,number,123',
        );
      });

      test('form roundtrip - explode false', () {
        final form = anyOf.toForm(explode: false, allowEmpty: true);
        final reconstructed = AnyOfComplex.fromForm(form, explode: false);
        expect(reconstructed, anyOf);
      });

      test('toSimple - explode true', () {
        expect(
          anyOf.toSimple(explode: true, allowEmpty: true),
          'name=Alice,number=123',
        );
      });

      test('simple roundtrip - explode true', () {
        final simple = anyOf.toSimple(explode: true, allowEmpty: true);
        final reconstructed = AnyOfComplex.fromSimple(simple, explode: true);
        expect(reconstructed, anyOf);
      });

      test('toSimple - explode false', () {
        expect(
          anyOf.toSimple(explode: false, allowEmpty: true),
          'name,Alice,number,123',
        );
      });

      test('simple roundtrip - explode false', () {
        final simple = anyOf.toSimple(explode: false, allowEmpty: true);
        final reconstructed = AnyOfComplex.fromSimple(simple, explode: false);
        expect(reconstructed, anyOf);
      });

      test('toMatrix - explode false', () {
        expect(
          anyOf.toMatrix('io', explode: false, allowEmpty: true),
          ';io=name,Alice,number,123',
        );
      });

      test('toMatrix - explode true', () {
        expect(
          anyOf.toMatrix('io', explode: true, allowEmpty: true),
          ';name=Alice;number=123',
        );
      });

      test('toLabel - explode true', () {
        expect(
          anyOf.toLabel(explode: true, allowEmpty: true),
          '.name=Alice.number=123',
        );
      });

      test('toLabel - explode false', () {
        expect(
          anyOf.toLabel(explode: false, allowEmpty: true),
          '.name,Alice,number,123',
        );
      });

      test('currentEncodingShape', () {
        expect(anyOf.currentEncodingShape, EncodingShape.complex);
      });
    });
  });

  group('AnyOfEnum', () {
    group('enum1', () {
      late AnyOfEnum anyOf;

      setUp(() {
        anyOf = AnyOfEnum(enum1: Enum1.value1);
      });

      test('toJson', () {
        expect(anyOf.toJson(), 'value1');
      });

      test('json roundtrip', () {
        final json = anyOf.toJson();
        final reconstructed = AnyOfEnum.fromJson(json);
        expect(reconstructed, anyOf);
      });

      test('toForm - explode true', () {
        expect(anyOf.toForm(explode: true, allowEmpty: true), 'value1');
      });

      test('form roundtrip - explode true', () {
        final form = anyOf.toForm(explode: true, allowEmpty: true);
        final reconstructed = AnyOfEnum.fromForm(form, explode: true);
        expect(reconstructed, anyOf);
      });

      test('toForm - explode false', () {
        expect(anyOf.toForm(explode: false, allowEmpty: true), 'value1');
      });

      test('form roundtrip - explode false', () {
        final form = anyOf.toForm(explode: false, allowEmpty: true);
        final reconstructed = AnyOfEnum.fromForm(form, explode: false);
        expect(reconstructed, anyOf);
      });

      test('toSimple - explode true', () {
        expect(anyOf.toSimple(explode: true, allowEmpty: true), 'value1');
      });

      test('simple roundtrip - explode true', () {
        final simple = anyOf.toSimple(explode: true, allowEmpty: true);
        final reconstructed = AnyOfEnum.fromSimple(simple, explode: true);
        expect(reconstructed, anyOf);
      });

      test('toSimple - explode false', () {
        expect(anyOf.toSimple(explode: false, allowEmpty: true), 'value1');
      });

      test('simple roundtrip - explode false', () {
        final simple = anyOf.toSimple(explode: false, allowEmpty: true);
        final reconstructed = AnyOfEnum.fromSimple(simple, explode: false);
        expect(reconstructed, anyOf);
      });

      test('toMatrix - explode false', () {
        expect(
          anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
          ';asdf=value1',
        );
      });

      test('toMatrix - explode true', () {
        expect(
          anyOf.toMatrix('asdf', explode: true, allowEmpty: true),
          ';asdf=value1',
        );
      });

      test('toLabel - explode true', () {
        expect(anyOf.toLabel(explode: true, allowEmpty: true), '.value1');
      });

      test('toLabel - explode false', () {
        expect(anyOf.toLabel(explode: false, allowEmpty: true), '.value1');
      });

      test('currentEncodingShape', () {
        expect(anyOf.currentEncodingShape, EncodingShape.simple);
      });
    });

    group('enum2', () {
      late AnyOfEnum anyOf;

      setUp(() {
        anyOf = AnyOfEnum(enum2: Enum2.two);
      });

      test('toJson', () {
        expect(anyOf.toJson(), 2);
      });

      test('json roundtrip', () {
        final json = anyOf.toJson();
        final reconstructed = AnyOfEnum.fromJson(json);
        expect(reconstructed, anyOf);
      });

      test('toForm - explode true', () {
        expect(anyOf.toForm(explode: true, allowEmpty: true), '2');
      });

      test('form roundtrip - explode true', () {
        final form = anyOf.toForm(explode: true, allowEmpty: true);
        final reconstructed = AnyOfEnum.fromForm(form, explode: true);
        expect(reconstructed, anyOf);
      });

      test('toForm - explode false', () {
        expect(anyOf.toForm(explode: false, allowEmpty: true), '2');
      });

      test('form roundtrip - explode false', () {
        final form = anyOf.toForm(explode: false, allowEmpty: true);
        final reconstructed = AnyOfEnum.fromForm(form, explode: false);
        expect(reconstructed, anyOf);
      });

      test('toSimple - explode true', () {
        expect(anyOf.toSimple(explode: true, allowEmpty: true), '2');
      });

      test('simple roundtrip - explode true', () {
        final simple = anyOf.toSimple(explode: true, allowEmpty: true);
        final reconstructed = AnyOfEnum.fromSimple(simple, explode: true);
        expect(reconstructed, anyOf);
      });

      test('toSimple - explode false', () {
        expect(anyOf.toSimple(explode: false, allowEmpty: true), '2');
      });

      test('simple roundtrip - explode false', () {
        final simple = anyOf.toSimple(explode: false, allowEmpty: true);
        final reconstructed = AnyOfEnum.fromSimple(simple, explode: false);
        expect(reconstructed, anyOf);
      });

      test('toMatrix - explode false', () {
        expect(
          anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
          ';asdf=2',
        );
      });

      test('toMatrix - explode true', () {
        expect(
          anyOf.toMatrix('asdf', explode: true, allowEmpty: true),
          ';asdf=2',
        );
      });

      test('toLabel - explode true', () {
        expect(anyOf.toLabel(explode: true, allowEmpty: true), '.2');
      });

      test('toLabel - explode false', () {
        expect(anyOf.toLabel(explode: false, allowEmpty: true), '.2');
      });

      test('currentEncodingShape', () {
        expect(anyOf.currentEncodingShape, EncodingShape.simple);
      });
    });

    group('both enums', () {
      late AnyOfEnum anyOf;

      setUp(() {
        anyOf = AnyOfEnum(enum1: Enum1.value1, enum2: Enum2.two);
      });

      test('toJson throws EncodingException', () {
        expect(anyOf.toJson, throwsA(isA<EncodingException>()));
      });

      test('toForm throws EncodingException', () {
        expect(
          () => anyOf.toForm(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toSimple throws EncodingException', () {
        expect(
          () => anyOf.toSimple(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toMatrix throws EncodingException', () {
        expect(
          () => anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toLabel - explode true throws EncodingException', () {
        expect(
          () => anyOf.toLabel(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toLabel - explode false throws EncodingException', () {
        expect(
          () => anyOf.toLabel(explode: false, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('currentEncodingShape', () {
        expect(anyOf.currentEncodingShape, EncodingShape.simple);
      });
    });
  });

  group('AnyOfMixed', () {
    group('integer', () {
      late AnyOfMixed anyOf;

      setUp(() {
        anyOf = AnyOfMixed(int: 42);
      });

      test('toJson', () {
        expect(anyOf.toJson(), 42);
      });

      test('json roundtrip', () {
        final json = anyOf.toJson();
        final reconstructed = AnyOfMixed.fromJson(json);
        expect(reconstructed, anyOf);
      });

      test('toForm - explode true', () {
        expect(anyOf.toForm(explode: true, allowEmpty: true), '42');
      });

      test('form roundtrip - explode true', () {
        final form = anyOf.toForm(explode: true, allowEmpty: true);
        final reconstructed = AnyOfMixed.fromForm(form, explode: true);
        expect(reconstructed, anyOf);
      });

      test('toForm - explode false', () {
        expect(anyOf.toForm(explode: false, allowEmpty: true), '42');
      });

      test('form roundtrip - explode false', () {
        final form = anyOf.toForm(explode: false, allowEmpty: true);
        final reconstructed = AnyOfMixed.fromForm(form, explode: false);
        expect(reconstructed, anyOf);
      });

      test('toSimple - explode true', () {
        expect(anyOf.toSimple(explode: true, allowEmpty: true), '42');
      });

      test('simple roundtrip - explode true', () {
        final simple = anyOf.toSimple(explode: true, allowEmpty: true);
        final reconstructed = AnyOfMixed.fromSimple(simple, explode: true);
        expect(reconstructed, anyOf);
      });

      test('toSimple - explode false', () {
        expect(anyOf.toSimple(explode: false, allowEmpty: true), '42');
      });

      test('simple roundtrip - explode false', () {
        final simple = anyOf.toSimple(explode: false, allowEmpty: true);
        final reconstructed = AnyOfMixed.fromSimple(simple, explode: false);
        expect(reconstructed, anyOf);
      });

      test('toMatrix - explode false', () {
        expect(
          anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
          ';asdf=42',
        );
      });

      test('toMatrix - explode true', () {
        expect(
          anyOf.toMatrix('asdf', explode: true, allowEmpty: true),
          ';asdf=42',
        );
      });

      test('toLabel - explode true', () {
        expect(anyOf.toLabel(explode: true, allowEmpty: true), '.42');
      });

      test('toLabel - explode false', () {
        expect(anyOf.toLabel(explode: false, allowEmpty: true), '.42');
      });

      test('currentEncodingShape', () {
        expect(anyOf.currentEncodingShape, EncodingShape.simple);
      });
    });

    group('class2', () {
      late AnyOfMixed anyOf;

      setUp(() {
        anyOf = AnyOfMixed(class2: Class2(number: 123));
      });

      test('toJson', () {
        expect(anyOf.toJson(), {'number': 123});
      });

      test('json roundtrip', () {
        final json = anyOf.toJson();
        final reconstructed = AnyOfMixed.fromJson(json);
        expect(reconstructed, anyOf);
      });

      test('toForm - explode true', () {
        expect(anyOf.toForm(explode: true, allowEmpty: true), 'number=123');
      });

      test('form roundtrip - explode true', () {
        final form = anyOf.toForm(explode: true, allowEmpty: true);
        final reconstructed = AnyOfMixed.fromForm(form, explode: true);
        expect(reconstructed, anyOf);
      });

      test('toForm - explode false', () {
        expect(anyOf.toForm(explode: false, allowEmpty: true), 'number,123');
      });

      test('form roundtrip - explode false', () {
        final form = anyOf.toForm(explode: false, allowEmpty: true);
        final reconstructed = AnyOfMixed.fromForm(form, explode: false);
        expect(reconstructed, anyOf);
      });

      test('toSimple - explode true', () {
        expect(anyOf.toSimple(explode: true, allowEmpty: true), 'number=123');
      });

      test('simple roundtrip - explode true', () {
        final simple = anyOf.toSimple(explode: true, allowEmpty: true);
        final reconstructed = AnyOfMixed.fromSimple(simple, explode: true);
        expect(reconstructed, anyOf);
      });

      test('toSimple - explode false', () {
        expect(anyOf.toSimple(explode: false, allowEmpty: true), 'number,123');
      });

      test('simple roundtrip - explode false', () {
        final simple = anyOf.toSimple(explode: false, allowEmpty: true);
        final reconstructed = AnyOfMixed.fromSimple(simple, explode: false);
        expect(reconstructed, anyOf);
      });

      test('toMatrix - explode false', () {
        expect(
          anyOf.toMatrix('value', explode: false, allowEmpty: true),
          ';value=number,123',
        );
      });

      test('toMatrix - explode true', () {
        expect(
          anyOf.toMatrix('value', explode: true, allowEmpty: true),
          ';number=123',
        );
      });

      test('toLabel - explode true', () {
        expect(anyOf.toLabel(explode: true, allowEmpty: true), '.number=123');
      });

      test('toLabel - explode false', () {
        expect(anyOf.toLabel(explode: false, allowEmpty: true), '.number,123');
      });

      test('currentEncodingShape', () {
        expect(anyOf.currentEncodingShape, EncodingShape.complex);
      });
    });

    group('enum2', () {
      late AnyOfMixed anyOf;

      setUp(() {
        // Setting both enum2 and int to avoid ambiguity.
        // Both can be decoded as the same value, 1.
        anyOf = AnyOfMixed(enum2: Enum2.one, int: 1);
      });

      test('toJson', () {
        expect(anyOf.toJson(), 1);
      });

      test('json roundtrip', () {
        final json = anyOf.toJson();
        final reconstructed = AnyOfMixed.fromJson(json);
        expect(reconstructed, anyOf);
      });

      test('toForm - explode true', () {
        expect(anyOf.toForm(explode: true, allowEmpty: true), '1');
      });

      test('form roundtrip - explode true', () {
        final form = anyOf.toForm(explode: true, allowEmpty: true);
        final reconstructed = AnyOfMixed.fromForm(form, explode: true);
        expect(reconstructed, anyOf);
      });

      test('toForm - explode false', () {
        expect(anyOf.toForm(explode: false, allowEmpty: true), '1');
      });

      test('form roundtrip - explode false', () {
        final form = anyOf.toForm(explode: false, allowEmpty: true);
        final reconstructed = AnyOfMixed.fromForm(form, explode: false);
        expect(reconstructed, anyOf);
      });

      test('toSimple - explode true', () {
        expect(anyOf.toSimple(explode: true, allowEmpty: true), '1');
      });

      test('simple roundtrip - explode true', () {
        final simple = anyOf.toSimple(explode: true, allowEmpty: true);
        final reconstructed = AnyOfMixed.fromSimple(simple, explode: true);
        expect(reconstructed, anyOf);
      });

      test('toSimple - explode false', () {
        expect(anyOf.toSimple(explode: false, allowEmpty: true), '1');
      });

      test('simple roundtrip - explode false', () {
        final simple = anyOf.toSimple(explode: false, allowEmpty: true);
        final reconstructed = AnyOfMixed.fromSimple(simple, explode: false);
        expect(reconstructed, anyOf);
      });

      test('toMatrix - explode false', () {
        expect(
          anyOf.toMatrix('value', explode: false, allowEmpty: true),
          ';value=1',
        );
      });

      test('toMatrix - explode true', () {
        expect(
          anyOf.toMatrix('value', explode: true, allowEmpty: true),
          ';value=1',
        );
      });

      test('toLabel - explode true', () {
        expect(anyOf.toLabel(explode: true, allowEmpty: true), '.1');
      });

      test('toLabel - explode false', () {
        expect(anyOf.toLabel(explode: false, allowEmpty: true), '.1');
      });

      test('currentEncodingShape', () {
        expect(anyOf.currentEncodingShape, EncodingShape.simple);
      });
    });

    group('multiple values', () {
      late AnyOfMixed anyOf;

      setUp(() {
        anyOf = AnyOfMixed(int: 42, class2: Class2(number: 123));
      });

      test('toJson throws EncodingException', () {
        expect(anyOf.toJson, throwsA(isA<EncodingException>()));
      });

      test('toForm throws EncodingException', () {
        expect(
          () => anyOf.toForm(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toSimple throws EncodingException', () {
        expect(
          () => anyOf.toSimple(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toMatrix throws EncodingException', () {
        expect(
          () => anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toLabel - explode true throws EncodingException', () {
        expect(
          () => anyOf.toLabel(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toLabel - explode false throws EncodingException', () {
        expect(
          () => anyOf.toLabel(explode: false, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('currentEncodingShape', () {
        expect(anyOf.currentEncodingShape, EncodingShape.mixed);
      });
    });
  });

  group('NestedAnyOfInAllOf', () {
    group('with class1', () {
      late NestedAnyOfInAllOf anyOf;

      setUp(() {
        anyOf = NestedAnyOfInAllOf(
          anyOfComplex: AnyOfComplex(class1: Class1(name: 'Bob')),
          nestedAnyOfInAllOfModel: NestedAnyOfInAllOfModel(timestamp: 123),
        );
      });

      test('toJson', () {
        expect(anyOf.toJson(), {'name': 'Bob', 'timestamp': 123});
      });

      test('json roundtrip', () {
        final json = anyOf.toJson();
        final reconstructed = NestedAnyOfInAllOf.fromJson(json);
        expect(reconstructed, anyOf);
      });

      test('toForm - explode true', () {
        expect(
          anyOf.toForm(explode: true, allowEmpty: true),
          'name=Bob&timestamp=123',
        );
      });

      test('form roundtrip - explode true', () {
        final form = anyOf.toForm(explode: true, allowEmpty: true);
        final reconstructed = NestedAnyOfInAllOf.fromForm(form, explode: true);
        expect(reconstructed, anyOf);
      });

      test('toForm - explode false', () {
        expect(
          anyOf.toForm(explode: false, allowEmpty: true),
          'name,Bob,timestamp,123',
        );
      });

      test('form roundtrip - explode false', () {
        final form = anyOf.toForm(explode: false, allowEmpty: true);
        final reconstructed = NestedAnyOfInAllOf.fromForm(form, explode: false);
        expect(reconstructed, anyOf);
      });

      test('toSimple - explode true', () {
        expect(
          anyOf.toSimple(explode: true, allowEmpty: true),
          'name=Bob,timestamp=123',
        );
      });

      test('simple roundtrip - explode true', () {
        final simple = anyOf.toSimple(explode: true, allowEmpty: true);
        final reconstructed = NestedAnyOfInAllOf.fromSimple(
          simple,
          explode: true,
        );
        expect(reconstructed, anyOf);
      });

      test('toSimple - explode false', () {
        expect(
          anyOf.toSimple(explode: false, allowEmpty: true),
          'name,Bob,timestamp,123',
        );
      });

      test('simple roundtrip - explode false', () {
        final simple = anyOf.toSimple(explode: false, allowEmpty: true);
        final reconstructed = NestedAnyOfInAllOf.fromSimple(
          simple,
          explode: false,
        );
        expect(reconstructed, anyOf);
      });

      test('toMatrix - explode false', () {
        expect(
          anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
          ';asdf=name,Bob,timestamp,123',
        );
      });

      test('toMatrix - explode true', () {
        expect(
          anyOf.toMatrix('asdf', explode: true, allowEmpty: true),
          ';name=Bob;timestamp=123',
        );
      });

      test('toLabel - explode true', () {
        expect(
          anyOf.toLabel(explode: true, allowEmpty: true),
          '.name=Bob.timestamp=123',
        );
      });

      test('toLabel - explode false', () {
        expect(
          anyOf.toLabel(explode: false, allowEmpty: true),
          '.name,Bob,timestamp,123',
        );
      });

      test('currentEncodingShape', () {
        expect(anyOf.currentEncodingShape, EncodingShape.complex);
      });
    });

    group('with class2', () {
      late NestedAnyOfInAllOf anyOf;

      setUp(() {
        anyOf = NestedAnyOfInAllOf(
          anyOfComplex: AnyOfComplex(class2: Class2(number: 456)),
          nestedAnyOfInAllOfModel: NestedAnyOfInAllOfModel(timestamp: 123),
        );
      });

      test('toJson', () {
        expect(anyOf.toJson(), {'number': 456, 'timestamp': 123});
      });

      test('json roundtrip', () {
        final json = anyOf.toJson();
        final reconstructed = NestedAnyOfInAllOf.fromJson(json);
        expect(reconstructed, anyOf);
      });

      test('toForm - explode true', () {
        expect(
          anyOf.toForm(explode: true, allowEmpty: true),
          'number=456&timestamp=123',
        );
      });

      test('form roundtrip - explode true', () {
        final form = anyOf.toForm(explode: true, allowEmpty: true);
        final reconstructed = NestedAnyOfInAllOf.fromForm(form, explode: true);
        expect(reconstructed, anyOf);
      });

      test('toForm - explode false', () {
        expect(
          anyOf.toForm(explode: false, allowEmpty: true),
          'number,456,timestamp,123',
        );
      });

      test('form roundtrip - explode false', () {
        final form = anyOf.toForm(explode: false, allowEmpty: true);
        final reconstructed = NestedAnyOfInAllOf.fromForm(form, explode: false);
        expect(reconstructed, anyOf);
      });

      test('toSimple - explode true', () {
        expect(
          anyOf.toSimple(explode: true, allowEmpty: true),
          'number=456,timestamp=123',
        );
      });

      test('simple roundtrip - explode true', () {
        final simple = anyOf.toSimple(explode: true, allowEmpty: true);
        final reconstructed = NestedAnyOfInAllOf.fromSimple(
          simple,
          explode: true,
        );
        expect(reconstructed, anyOf);
      });

      test('toSimple - explode false', () {
        expect(
          anyOf.toSimple(explode: false, allowEmpty: true),
          'number,456,timestamp,123',
        );
      });

      test('simple roundtrip - explode false', () {
        final simple = anyOf.toSimple(explode: false, allowEmpty: true);
        final reconstructed = NestedAnyOfInAllOf.fromSimple(
          simple,
          explode: false,
        );
        expect(reconstructed, anyOf);
      });

      test('toMatrix - explode false', () {
        expect(
          anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
          ';asdf=number,456,timestamp,123',
        );
      });

      test('toMatrix - explode true', () {
        expect(
          anyOf.toMatrix('asdf', explode: true, allowEmpty: true),
          ';number=456;timestamp=123',
        );
      });

      test('toLabel - explode true', () {
        expect(
          anyOf.toLabel(explode: true, allowEmpty: true),
          '.number=456.timestamp=123',
        );
      });

      test('toLabel - explode false', () {
        expect(
          anyOf.toLabel(explode: false, allowEmpty: true),
          '.number,456,timestamp,123',
        );
      });

      test('currentEncodingShape', () {
        expect(anyOf.currentEncodingShape, EncodingShape.complex);
      });
    });
  });

  group('NestedAllOfInAnyOf', () {
    group('with AllOfMixed', () {
      late NestedAllOfInAnyOf anyOf;

      setUp(() {
        anyOf = NestedAllOfInAnyOf(
          allOfMixed: AllOfMixed(
            string: 'test',
            class1: Class1(name: 'test'),
          ),
          class1: Class1(name: 'test'),
        );
      });

      test('toJson throws EncodingException', () {
        expect(anyOf.toJson, throwsA(isA<EncodingException>()));
      });

      test('toForm throws EncodingException', () {
        expect(
          () => anyOf.toForm(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toSimple throws EncodingException', () {
        expect(
          () => anyOf.toSimple(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toMatrix throws EncodingException', () {
        expect(
          () => anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toLabel - explode true throws EncodingException', () {
        expect(
          () => anyOf.toLabel(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toLabel - explode false throws EncodingException', () {
        expect(
          () => anyOf.toLabel(explode: false, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('currentEncodingShape', () {
        expect(anyOf.currentEncodingShape, EncodingShape.mixed);
      });
    });

    group('with Class1', () {
      late NestedAllOfInAnyOf anyOf;

      setUp(() {
        anyOf = NestedAllOfInAnyOf(class1: Class1(name: 'Charlie'));
      });

      test('toJson', () {
        expect(anyOf.toJson(), {'name': 'Charlie'});
      });

      test('json roundtrip', () {
        final json = anyOf.toJson();
        final reconstructed = NestedAllOfInAnyOf.fromJson(json);
        expect(reconstructed, anyOf);
      });

      test('toForm - explode true', () {
        expect(anyOf.toForm(explode: true, allowEmpty: true), 'name=Charlie');
      });

      test('form roundtrip - explode true', () {
        final form = anyOf.toForm(explode: true, allowEmpty: true);
        final reconstructed = NestedAllOfInAnyOf.fromForm(form, explode: true);
        // Both class1 and allOfMixed are set because AllOfMixed contains a String field.
        // Any string value can be decoded to String, so allOfMixed.string='name=Charlie'.
        expect(
          reconstructed,
          NestedAllOfInAnyOf(
            class1: Class1(name: 'Charlie'),
            allOfMixed: AllOfMixed(
              class1: Class1(name: 'Charlie'),
              string: 'name=Charlie',
            ),
          ),
        );
      });

      test('toForm - explode false', () {
        expect(anyOf.toForm(explode: false, allowEmpty: true), 'name,Charlie');
      });

      test('form roundtrip - explode false', () {
        final form = anyOf.toForm(explode: false, allowEmpty: true);
        final reconstructed = NestedAllOfInAnyOf.fromForm(form, explode: false);
        // Both class1 and allOfMixed are set because AllOfMixed contains a String field.
        // Any string value can be decoded to String, so allOfMixed.string='name,Charlie'.
        expect(
          reconstructed,
          NestedAllOfInAnyOf(
            class1: Class1(name: 'Charlie'),
            allOfMixed: AllOfMixed(
              class1: Class1(name: 'Charlie'),
              string: 'name,Charlie',
            ),
          ),
        );
      });

      test('toSimple - explode true', () {
        expect(anyOf.toSimple(explode: true, allowEmpty: true), 'name=Charlie');
      });

      test('simple roundtrip - explode true', () {
        final simple = anyOf.toSimple(explode: true, allowEmpty: true);
        final reconstructed = NestedAllOfInAnyOf.fromSimple(
          simple,
          explode: true,
        );
        // Both class1 and allOfMixed are set because AllOfMixed contains a String field.
        // Any string value can be decoded to String, so allOfMixed.string='name=Charlie'.
        expect(
          reconstructed,
          NestedAllOfInAnyOf(
            class1: Class1(name: 'Charlie'),
            allOfMixed: AllOfMixed(
              class1: Class1(name: 'Charlie'),
              string: 'name=Charlie',
            ),
          ),
        );
      });

      test('toSimple - explode false', () {
        expect(
          anyOf.toSimple(explode: false, allowEmpty: true),
          'name,Charlie',
        );
      });

      test('simple roundtrip - explode false', () {
        final simple = anyOf.toSimple(explode: false, allowEmpty: true);
        final reconstructed = NestedAllOfInAnyOf.fromSimple(
          simple,
          explode: false,
        );
        // Both class1 and allOfMixed are set because AllOfMixed contains a String field.
        // Any string value can be decoded to String, so allOfMixed.string='name,Charlie'.
        expect(
          reconstructed,
          NestedAllOfInAnyOf(
            class1: Class1(name: 'Charlie'),
            allOfMixed: AllOfMixed(
              class1: Class1(name: 'Charlie'),
              string: 'name,Charlie',
            ),
          ),
        );
      });

      test('toMatrix - explode false', () {
        expect(
          anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
          ';asdf=name,Charlie',
        );
      });

      test('toMatrix - explode true', () {
        expect(
          anyOf.toMatrix('asdf', explode: true, allowEmpty: true),
          ';name=Charlie',
        );
      });

      test('toLabel - explode true', () {
        expect(anyOf.toLabel(explode: true, allowEmpty: true), '.name=Charlie');
      });

      test('toLabel - explode false', () {
        expect(
          anyOf.toLabel(explode: false, allowEmpty: true),
          '.name,Charlie',
        );
      });

      test('currentEncodingShape', () {
        expect(anyOf.currentEncodingShape, EncodingShape.complex);
      });
    });
  });

  group('NestedOneOfInAnyOf', () {
    group('with OneOfEnum', () {
      late NestedOneOfInAnyOf anyOf;

      setUp(() {
        anyOf = NestedOneOfInAnyOf(
          oneOfEnum: OneOfEnumEnum1(Enum1.value2),
          num: null,
        );
      });

      test('toJson', () {
        expect(anyOf.toJson(), 'value2');
      });

      test('json roundtrip', () {
        final json = anyOf.toJson();
        final reconstructed = NestedOneOfInAnyOf.fromJson(json);
        expect(reconstructed, anyOf);
      });

      test('toForm - explode true', () {
        expect(anyOf.toForm(explode: true, allowEmpty: true), 'value2');
      });

      test('form roundtrip - explode true', () {
        final form = anyOf.toForm(explode: true, allowEmpty: true);
        final reconstructed = NestedOneOfInAnyOf.fromForm(form, explode: true);
        expect(reconstructed, anyOf);
      });

      test('toForm - explode false', () {
        expect(anyOf.toForm(explode: false, allowEmpty: true), 'value2');
      });

      test('form roundtrip - explode false', () {
        final form = anyOf.toForm(explode: false, allowEmpty: true);
        final reconstructed = NestedOneOfInAnyOf.fromForm(form, explode: false);
        expect(reconstructed, anyOf);
      });

      test('toSimple - explode true', () {
        expect(anyOf.toSimple(explode: true, allowEmpty: true), 'value2');
      });

      test('simple roundtrip - explode true', () {
        final simple = anyOf.toSimple(explode: true, allowEmpty: true);
        final reconstructed = NestedOneOfInAnyOf.fromSimple(
          simple,
          explode: true,
        );
        expect(reconstructed, anyOf);
      });

      test('toSimple - explode false', () {
        expect(anyOf.toSimple(explode: false, allowEmpty: true), 'value2');
      });

      test('simple roundtrip - explode false', () {
        final simple = anyOf.toSimple(explode: false, allowEmpty: true);
        final reconstructed = NestedOneOfInAnyOf.fromSimple(
          simple,
          explode: false,
        );
        expect(reconstructed, anyOf);
      });

      test('toMatrix - explode false', () {
        expect(
          anyOf.toMatrix('zxcv', explode: false, allowEmpty: true),
          ';zxcv=value2',
        );
      });

      test('toMatrix - explode true', () {
        expect(
          anyOf.toMatrix('zxcv', explode: true, allowEmpty: true),
          ';zxcv=value2',
        );
      });

      test('toLabel - explode true', () {
        expect(anyOf.toLabel(explode: true, allowEmpty: true), '.value2');
      });

      test('toLabel - explode false', () {
        expect(anyOf.toLabel(explode: false, allowEmpty: true), '.value2');
      });

      test('currentEncodingShape', () {
        expect(anyOf.currentEncodingShape, EncodingShape.simple);
      });
    });

    group('with number', () {
      late NestedOneOfInAnyOf anyOf;

      setUp(() {
        anyOf = NestedOneOfInAnyOf(oneOfEnum: null, num: 3.14);
      });

      test('toJson', () {
        expect(anyOf.toJson(), 3.14);
      });

      test('json roundtrip', () {
        final json = anyOf.toJson();
        final reconstructed = NestedOneOfInAnyOf.fromJson(json);
        expect(reconstructed, anyOf);
      });

      test('toForm - explode true', () {
        expect(anyOf.toForm(explode: true, allowEmpty: true), '3.14');
      });

      test('form roundtrip - explode true', () {
        final form = anyOf.toForm(explode: true, allowEmpty: true);
        final reconstructed = NestedOneOfInAnyOf.fromForm(form, explode: true);
        expect(reconstructed, anyOf);
      });

      test('toForm - explode false', () {
        expect(anyOf.toForm(explode: false, allowEmpty: true), '3.14');
      });

      test('form roundtrip - explode false', () {
        final form = anyOf.toForm(explode: false, allowEmpty: true);
        final reconstructed = NestedOneOfInAnyOf.fromForm(form, explode: false);
        expect(reconstructed, anyOf);
      });

      test('toSimple - explode true', () {
        expect(anyOf.toSimple(explode: true, allowEmpty: true), '3.14');
      });

      test('simple roundtrip - explode true', () {
        final simple = anyOf.toSimple(explode: true, allowEmpty: true);
        final reconstructed = NestedOneOfInAnyOf.fromSimple(
          simple,
          explode: true,
        );
        expect(reconstructed, anyOf);
      });

      test('toSimple - explode false', () {
        expect(anyOf.toSimple(explode: false, allowEmpty: true), '3.14');
      });

      test('simple roundtrip - explode false', () {
        final simple = anyOf.toSimple(explode: false, allowEmpty: true);
        final reconstructed = NestedOneOfInAnyOf.fromSimple(
          simple,
          explode: false,
        );
        expect(reconstructed, anyOf);
      });

      test('toMatrix - explode false', () {
        expect(
          anyOf.toMatrix('zxcv', explode: false, allowEmpty: true),
          ';zxcv=3.14',
        );
      });

      test('toMatrix - explode true', () {
        expect(
          anyOf.toMatrix('zxcv', explode: true, allowEmpty: true),
          ';zxcv=3.14',
        );
      });

      test('toLabel - explode true', () {
        expect(anyOf.toLabel(explode: true, allowEmpty: true), '.3.14');
      });

      test('toLabel - explode false', () {
        expect(anyOf.toLabel(explode: false, allowEmpty: true), '.3.14');
      });

      test('currentEncodingShape', () {
        expect(anyOf.currentEncodingShape, EncodingShape.simple);
      });
    });

    group('with both', () {
      late NestedOneOfInAnyOf anyOf;

      setUp(() {
        anyOf = NestedOneOfInAnyOf(
          oneOfEnum: OneOfEnumEnum1(Enum1.value2),
          num: 3.14,
        );
      });

      test('toJson throws EncodingException', () {
        expect(anyOf.toJson, throwsA(isA<EncodingException>()));
      });

      test('toForm throws EncodingException', () {
        expect(
          () => anyOf.toForm(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toSimple throws EncodingException', () {
        expect(
          () => anyOf.toSimple(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toMatrix throws EncodingException', () {
        expect(
          () => anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toLabel - explode true throws EncodingException', () {
        expect(
          () => anyOf.toLabel(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toLabel - explode false throws EncodingException', () {
        expect(
          () => anyOf.toLabel(explode: false, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('currentEncodingShape', () {
        expect(anyOf.currentEncodingShape, EncodingShape.simple);
      });
    });
  });

  group('TwoLevelAnyOf', () {
    group('with string', () {
      late TwoLevelAnyOf anyOf;

      setUp(() {
        anyOf = TwoLevelAnyOf(string: 'test');
      });

      test('toJson', () {
        expect(anyOf.toJson(), 'test');
      });

      test('json roundtrip', () {
        final json = anyOf.toJson();
        final reconstructed = TwoLevelAnyOf.fromJson(json);
        expect(reconstructed, anyOf);
      });

      test('toForm - explode true', () {
        expect(anyOf.toForm(explode: true, allowEmpty: true), 'test');
      });

      test('form roundtrip - explode true', () {
        final form = anyOf.toForm(explode: true, allowEmpty: true);
        final reconstructed = TwoLevelAnyOf.fromForm(form, explode: true);
        expect(reconstructed, anyOf);
      });

      test('toForm - explode false', () {
        expect(anyOf.toForm(explode: false, allowEmpty: true), 'test');
      });

      test('form roundtrip - explode false', () {
        final form = anyOf.toForm(explode: false, allowEmpty: true);
        final reconstructed = TwoLevelAnyOf.fromForm(form, explode: false);
        expect(reconstructed, anyOf);
      });

      test('toSimple - explode true', () {
        expect(anyOf.toSimple(explode: true, allowEmpty: true), 'test');
      });

      test('simple roundtrip - explode true', () {
        final simple = anyOf.toSimple(explode: true, allowEmpty: true);
        final reconstructed = TwoLevelAnyOf.fromSimple(simple, explode: true);
        expect(reconstructed, anyOf);
      });

      test('toSimple - explode false', () {
        expect(anyOf.toSimple(explode: false, allowEmpty: true), 'test');
      });

      test('simple roundtrip - explode false', () {
        final simple = anyOf.toSimple(explode: false, allowEmpty: true);
        final reconstructed = TwoLevelAnyOf.fromSimple(simple, explode: false);
        expect(reconstructed, anyOf);
      });

      test('toMatrix - explode false', () {
        expect(
          anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
          ';asdf=test',
        );
      });

      test('toMatrix - explode true', () {
        expect(
          anyOf.toMatrix('asdf', explode: true, allowEmpty: true),
          ';asdf=test',
        );
      });

      test('toLabel - explode true', () {
        expect(anyOf.toLabel(explode: true, allowEmpty: true), '.test');
      });

      test('toLabel - explode false', () {
        expect(anyOf.toLabel(explode: false, allowEmpty: true), '.test');
      });

      test('currentEncodingShape', () {
        expect(anyOf.currentEncodingShape, EncodingShape.simple);
      });
    });

    group('with class1', () {
      late TwoLevelAnyOf anyOf;

      setUp(() {
        anyOf = TwoLevelAnyOf(
          twoLevelAnyOfModel: TwoLevelAnyOfModel(class1: Class1(name: 'test')),
        );
      });

      test('toJson', () {
        expect(anyOf.toJson(), {'name': 'test'});
      });

      test('json roundtrip', () {
        final json = anyOf.toJson();
        final reconstructed = TwoLevelAnyOf.fromJson(json);
        expect(reconstructed, anyOf);
      });

      test('toForm - explode true', () {
        expect(anyOf.toForm(explode: true, allowEmpty: true), 'name=test');
      });

      test('form roundtrip - explode true', () {
        final form = anyOf.toForm(explode: true, allowEmpty: true);
        final reconstructed = TwoLevelAnyOf.fromForm(form, explode: true);
        // Both twoLevelAnyOfModel and string are set because any string can be decoded to String.
        expect(
          reconstructed,
          TwoLevelAnyOf(
            twoLevelAnyOfModel: TwoLevelAnyOfModel(
              class1: Class1(name: 'test'),
            ),
            string: 'name=test',
          ),
        );
      });

      test('toForm - explode false', () {
        expect(anyOf.toForm(explode: false, allowEmpty: true), 'name,test');
      });

      test('form roundtrip - explode false', () {
        final form = anyOf.toForm(explode: false, allowEmpty: true);
        final reconstructed = TwoLevelAnyOf.fromForm(form, explode: false);
        // Both twoLevelAnyOfModel and string are set because any string can be decoded to String.
        expect(
          reconstructed,
          TwoLevelAnyOf(
            twoLevelAnyOfModel: TwoLevelAnyOfModel(
              class1: Class1(name: 'test'),
            ),
            string: 'name,test',
          ),
        );
      });

      test('toSimple - explode true', () {
        expect(anyOf.toSimple(explode: true, allowEmpty: true), 'name=test');
      });

      test('simple roundtrip - explode true', () {
        final simple = anyOf.toSimple(explode: true, allowEmpty: true);
        final reconstructed = TwoLevelAnyOf.fromSimple(simple, explode: true);
        // Both twoLevelAnyOfModel and string are set because any string can be decoded to String.
        expect(
          reconstructed,
          TwoLevelAnyOf(
            twoLevelAnyOfModel: TwoLevelAnyOfModel(
              class1: Class1(name: 'test'),
            ),
            string: 'name=test',
          ),
        );
      });

      test('toSimple - explode false', () {
        expect(anyOf.toSimple(explode: false, allowEmpty: true), 'name,test');
      });

      test('simple roundtrip - explode false', () {
        final simple = anyOf.toSimple(explode: false, allowEmpty: true);
        final reconstructed = TwoLevelAnyOf.fromSimple(simple, explode: false);
        // Both twoLevelAnyOfModel and string are set because any string can be decoded to String.
        expect(
          reconstructed,
          TwoLevelAnyOf(
            twoLevelAnyOfModel: TwoLevelAnyOfModel(
              class1: Class1(name: 'test'),
            ),
            string: 'name,test',
          ),
        );
      });

      test('toMatrix - explode false', () {
        expect(
          anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
          ';asdf=name,test',
        );
      });

      test('toMatrix - explode true', () {
        expect(
          anyOf.toMatrix('asdf', explode: true, allowEmpty: true),
          ';name=test',
        );
      });

      test('toLabel - explode true', () {
        expect(anyOf.toLabel(explode: true, allowEmpty: true), '.name=test');
      });

      test('toLabel - explode false', () {
        expect(anyOf.toLabel(explode: false, allowEmpty: true), '.name,test');
      });

      test('currentEncodingShape', () {
        expect(anyOf.currentEncodingShape, EncodingShape.complex);
      });
    });

    group('with class2', () {
      late TwoLevelAnyOf anyOf;

      setUp(() {
        anyOf = TwoLevelAnyOf(
          twoLevelAnyOfModel: TwoLevelAnyOfModel(class2: Class2(number: 42)),
        );
      });

      test('toJson', () {
        expect(anyOf.toJson(), {'number': 42});
      });

      test('json roundtrip', () {
        final json = anyOf.toJson();
        final reconstructed = TwoLevelAnyOf.fromJson(json);
        expect(reconstructed, anyOf);
      });

      test('toForm - explode true', () {
        expect(anyOf.toForm(explode: true, allowEmpty: true), 'number=42');
      });

      test('form roundtrip - explode true', () {
        final form = anyOf.toForm(explode: true, allowEmpty: true);
        final reconstructed = TwoLevelAnyOf.fromForm(form, explode: true);
        // Both twoLevelAnyOfModel and string are set because any string can be decoded to String.
        expect(
          reconstructed,
          TwoLevelAnyOf(
            twoLevelAnyOfModel: TwoLevelAnyOfModel(class2: Class2(number: 42)),
            string: 'number=42',
          ),
        );
      });

      test('toForm - explode false', () {
        expect(anyOf.toForm(explode: false, allowEmpty: true), 'number,42');
      });

      test('form roundtrip - explode false', () {
        final form = anyOf.toForm(explode: false, allowEmpty: true);
        final reconstructed = TwoLevelAnyOf.fromForm(form, explode: false);
        // Both twoLevelAnyOfModel and string are set because any string can be decoded to String.
        expect(
          reconstructed,
          TwoLevelAnyOf(
            twoLevelAnyOfModel: TwoLevelAnyOfModel(class2: Class2(number: 42)),
            string: 'number,42',
          ),
        );
      });

      test('toSimple - explode true', () {
        expect(anyOf.toSimple(explode: true, allowEmpty: true), 'number=42');
      });

      test('simple roundtrip - explode true', () {
        final simple = anyOf.toSimple(explode: true, allowEmpty: true);
        final reconstructed = TwoLevelAnyOf.fromSimple(simple, explode: true);
        // Both twoLevelAnyOfModel and string are set because any string can be decoded to String.
        expect(
          reconstructed,
          TwoLevelAnyOf(
            twoLevelAnyOfModel: TwoLevelAnyOfModel(class2: Class2(number: 42)),
            string: 'number=42',
          ),
        );
      });

      test('toSimple - explode false', () {
        expect(anyOf.toSimple(explode: false, allowEmpty: true), 'number,42');
      });

      test('simple roundtrip - explode false', () {
        final simple = anyOf.toSimple(explode: false, allowEmpty: true);
        final reconstructed = TwoLevelAnyOf.fromSimple(simple, explode: false);
        // Both twoLevelAnyOfModel and string are set because any string can be decoded to String.
        expect(
          reconstructed,
          TwoLevelAnyOf(
            twoLevelAnyOfModel: TwoLevelAnyOfModel(class2: Class2(number: 42)),
            string: 'number,42',
          ),
        );
      });

      test('toMatrix - explode false', () {
        expect(
          anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
          ';asdf=number,42',
        );
      });

      test('toMatrix - explode true', () {
        expect(
          anyOf.toMatrix('asdf', explode: true, allowEmpty: true),
          ';number=42',
        );
      });

      test('toLabel - explode true', () {
        expect(anyOf.toLabel(explode: true, allowEmpty: true), '.number=42');
      });

      test('toLabel - explode false', () {
        expect(anyOf.toLabel(explode: false, allowEmpty: true), '.number,42');
      });

      test('currentEncodingShape', () {
        expect(anyOf.currentEncodingShape, EncodingShape.complex);
      });
    });
  });

  group('ThreeLevelAnyOf', () {
    group('with string', () {
      late ThreeLevelAnyOf anyOf;

      setUp(() {
        anyOf = ThreeLevelAnyOf(string: 'deep');
      });

      test('toJson', () {
        expect(anyOf.toJson(), 'deep');
      });

      test('json roundtrip', () {
        final json = anyOf.toJson();
        final reconstructed = ThreeLevelAnyOf.fromJson(json);
        expect(reconstructed, anyOf);
      });

      test('toForm - explode true', () {
        expect(anyOf.toForm(explode: true, allowEmpty: true), 'deep');
      });

      test('form roundtrip - explode true', () {
        final form = anyOf.toForm(explode: true, allowEmpty: true);
        final reconstructed = ThreeLevelAnyOf.fromForm(form, explode: true);
        expect(reconstructed, anyOf);
      });

      test('toForm - explode false', () {
        expect(anyOf.toForm(explode: false, allowEmpty: true), 'deep');
      });

      test('form roundtrip - explode false', () {
        final form = anyOf.toForm(explode: false, allowEmpty: true);
        final reconstructed = ThreeLevelAnyOf.fromForm(form, explode: false);
        expect(reconstructed, anyOf);
      });

      test('toSimple - explode true', () {
        expect(anyOf.toSimple(explode: true, allowEmpty: true), 'deep');
      });

      test('simple roundtrip - explode true', () {
        final simple = anyOf.toSimple(explode: true, allowEmpty: true);
        final reconstructed = ThreeLevelAnyOf.fromSimple(simple, explode: true);
        expect(reconstructed, anyOf);
      });

      test('toSimple - explode false', () {
        expect(anyOf.toSimple(explode: false, allowEmpty: true), 'deep');
      });

      test('simple roundtrip - explode false', () {
        final simple = anyOf.toSimple(explode: false, allowEmpty: true);
        final reconstructed = ThreeLevelAnyOf.fromSimple(
          simple,
          explode: false,
        );
        expect(reconstructed, anyOf);
      });

      test('toMatrix - explode false', () {
        expect(
          anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
          ';asdf=deep',
        );
      });

      test('toMatrix - explode true', () {
        expect(
          anyOf.toMatrix('asdf', explode: true, allowEmpty: true),
          ';asdf=deep',
        );
      });

      test('toLabel - explode true', () {
        expect(anyOf.toLabel(explode: true, allowEmpty: true), '.deep');
      });

      test('toLabel - explode false', () {
        expect(anyOf.toLabel(explode: false, allowEmpty: true), '.deep');
      });

      test('currentEncodingShape', () {
        expect(anyOf.currentEncodingShape, EncodingShape.simple);
      });
    });

    group('with enum1', () {
      late ThreeLevelAnyOf anyOf;

      setUp(() {
        anyOf = ThreeLevelAnyOf(
          threeLevelAnyOfModel: ThreeLevelAnyOfModel(enum1: Enum1.value1),
        );
      });

      test('toJson', () {
        expect(anyOf.toJson(), 'value1');
      });

      test('json roundtrip', () {
        final json = anyOf.toJson();
        final reconstructed = ThreeLevelAnyOf.fromJson(json);
        // Both threeLevelAnyOfModel and string are set because any string can be decoded to String.
        expect(
          reconstructed,
          ThreeLevelAnyOf(
            threeLevelAnyOfModel: ThreeLevelAnyOfModel(enum1: Enum1.value1),
            string: 'value1',
          ),
        );
      });

      test('toForm - explode true', () {
        expect(anyOf.toForm(explode: true, allowEmpty: true), 'value1');
      });

      test('form roundtrip - explode true', () {
        final form = anyOf.toForm(explode: true, allowEmpty: true);
        final reconstructed = ThreeLevelAnyOf.fromForm(form, explode: true);
        // Both threeLevelAnyOfModel and string are set because any string can be decoded to String.
        expect(
          reconstructed,
          ThreeLevelAnyOf(
            threeLevelAnyOfModel: ThreeLevelAnyOfModel(enum1: Enum1.value1),
            string: 'value1',
          ),
        );
      });

      test('toForm - explode false', () {
        expect(anyOf.toForm(explode: false, allowEmpty: true), 'value1');
      });

      test('form roundtrip - explode false', () {
        final form = anyOf.toForm(explode: false, allowEmpty: true);
        final reconstructed = ThreeLevelAnyOf.fromForm(form, explode: false);
        // Both threeLevelAnyOfModel and string are set because any string can be decoded to String.
        expect(
          reconstructed,
          ThreeLevelAnyOf(
            threeLevelAnyOfModel: ThreeLevelAnyOfModel(enum1: Enum1.value1),
            string: 'value1',
          ),
        );
      });

      test('toSimple - explode true', () {
        expect(anyOf.toSimple(explode: true, allowEmpty: true), 'value1');
      });

      test('simple roundtrip - explode true', () {
        final simple = anyOf.toSimple(explode: true, allowEmpty: true);
        final reconstructed = ThreeLevelAnyOf.fromSimple(simple, explode: true);
        // Both threeLevelAnyOfModel and string are set because any string can be decoded to String.
        expect(
          reconstructed,
          ThreeLevelAnyOf(
            threeLevelAnyOfModel: ThreeLevelAnyOfModel(enum1: Enum1.value1),
            string: 'value1',
          ),
        );
      });

      test('toSimple - explode false', () {
        expect(anyOf.toSimple(explode: false, allowEmpty: true), 'value1');
      });

      test('simple roundtrip - explode false', () {
        final simple = anyOf.toSimple(explode: false, allowEmpty: true);
        final reconstructed = ThreeLevelAnyOf.fromSimple(
          simple,
          explode: false,
        );
        // Both threeLevelAnyOfModel and string are set because any string can be decoded to String.
        expect(
          reconstructed,
          ThreeLevelAnyOf(
            threeLevelAnyOfModel: ThreeLevelAnyOfModel(enum1: Enum1.value1),
            string: 'value1',
          ),
        );
      });

      test('toMatrix - explode false', () {
        expect(
          anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
          ';asdf=value1',
        );
      });

      test('toMatrix - explode true', () {
        expect(
          anyOf.toMatrix('asdf', explode: true, allowEmpty: true),
          ';asdf=value1',
        );
      });

      test('toLabel - explode true', () {
        expect(anyOf.toLabel(explode: true, allowEmpty: true), '.value1');
      });

      test('toLabel - explode false', () {
        expect(anyOf.toLabel(explode: false, allowEmpty: true), '.value1');
      });

      test('currentEncodingShape', () {
        expect(anyOf.currentEncodingShape, EncodingShape.simple);
      });
    });

    group('with anyOf', () {
      late ThreeLevelAnyOf anyOf;

      setUp(() {
        anyOf = ThreeLevelAnyOf(
          threeLevelAnyOfModel: ThreeLevelAnyOfModel(
            threeLevelAnyOfAnyOfModel: ThreeLevelAnyOfAnyOfModel(
              class1: Class1(name: 'test'),
            ),
          ),
        );
      });

      test('toJson', () {
        expect(anyOf.toJson(), {'name': 'test'});
      });

      test('json roundtrip', () {
        final json = anyOf.toJson();
        final reconstructed = ThreeLevelAnyOf.fromJson(json);
        expect(reconstructed, anyOf);
      });

      test('toForm - explode true', () {
        expect(anyOf.toForm(explode: true, allowEmpty: true), 'name=test');
      });

      test('form roundtrip - explode true', () {
        final form = anyOf.toForm(explode: true, allowEmpty: true);
        final reconstructed = ThreeLevelAnyOf.fromForm(form, explode: true);
        // Both threeLevelAnyOfModel and string are set because any string can be decoded to String.
        expect(
          reconstructed,
          ThreeLevelAnyOf(
            threeLevelAnyOfModel: ThreeLevelAnyOfModel(
              threeLevelAnyOfAnyOfModel: ThreeLevelAnyOfAnyOfModel(
                class1: Class1(name: 'test'),
              ),
            ),
            string: 'name=test',
          ),
        );
      });

      test('toForm - explode false', () {
        expect(anyOf.toForm(explode: false, allowEmpty: true), 'name,test');
      });

      test('form roundtrip - explode false', () {
        final form = anyOf.toForm(explode: false, allowEmpty: true);
        final reconstructed = ThreeLevelAnyOf.fromForm(form, explode: false);
        // Both threeLevelAnyOfModel and string are set because any string can be decoded to String.
        expect(
          reconstructed,
          ThreeLevelAnyOf(
            threeLevelAnyOfModel: ThreeLevelAnyOfModel(
              threeLevelAnyOfAnyOfModel: ThreeLevelAnyOfAnyOfModel(
                class1: Class1(name: 'test'),
              ),
            ),
            string: 'name,test',
          ),
        );
      });

      test('toSimple - explode true', () {
        expect(anyOf.toSimple(explode: true, allowEmpty: true), 'name=test');
      });

      test('simple roundtrip - explode true', () {
        final simple = anyOf.toSimple(explode: true, allowEmpty: true);
        final reconstructed = ThreeLevelAnyOf.fromSimple(simple, explode: true);
        // Both threeLevelAnyOfModel and string are set because any string can be decoded to String.
        expect(
          reconstructed,
          ThreeLevelAnyOf(
            threeLevelAnyOfModel: ThreeLevelAnyOfModel(
              threeLevelAnyOfAnyOfModel: ThreeLevelAnyOfAnyOfModel(
                class1: Class1(name: 'test'),
              ),
            ),
            string: 'name=test',
          ),
        );
      });

      test('toSimple - explode false', () {
        expect(anyOf.toSimple(explode: false, allowEmpty: true), 'name,test');
      });

      test('simple roundtrip - explode false', () {
        final simple = anyOf.toSimple(explode: false, allowEmpty: true);
        final reconstructed = ThreeLevelAnyOf.fromSimple(
          simple,
          explode: false,
        );
        // Both threeLevelAnyOfModel and string are set because any string can be decoded to String.
        expect(
          reconstructed,
          ThreeLevelAnyOf(
            threeLevelAnyOfModel: ThreeLevelAnyOfModel(
              threeLevelAnyOfAnyOfModel: ThreeLevelAnyOfAnyOfModel(
                class1: Class1(name: 'test'),
              ),
            ),
            string: 'name,test',
          ),
        );
      });

      test('toMatrix - explode false', () {
        expect(
          anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
          ';asdf=name,test',
        );
      });

      test('toMatrix - explode true', () {
        expect(
          anyOf.toMatrix('asdf', explode: true, allowEmpty: true),
          ';name=test',
        );
      });

      test('toLabel - explode true', () {
        expect(anyOf.toLabel(explode: true, allowEmpty: true), '.name=test');
      });

      test('toLabel - explode false', () {
        expect(anyOf.toLabel(explode: false, allowEmpty: true), '.name,test');
      });

      test('currentEncodingShape', () {
        expect(anyOf.currentEncodingShape, EncodingShape.complex);
      });
    });
  });

  group('DeepNestedAnyOf', () {
    group('with enum1', () {
      late DeepNestedAnyOf anyOf;

      setUp(() {
        anyOf = DeepNestedAnyOf(enum1: Enum1.value1);
      });

      test('toJson', () {
        expect(anyOf.toJson(), 'value1');
      });

      test('json roundtrip', () {
        final json = anyOf.toJson();
        final reconstructed = DeepNestedAnyOf.fromJson(json);
        // Both nestedAnyOfInAnyOf and enum1 are set because NestedAnyOfInAnyOf.anyOfPrimitive contains a String variant.
        // Any string value can be decoded to String, so nestedAnyOfInAnyOf.anyOfPrimitive.string='value1'.
        expect(
          reconstructed,
          DeepNestedAnyOf(
            nestedAnyOfInAnyOf: NestedAnyOfInAnyOf(
              anyOfPrimitive: AnyOfPrimitive(string: 'value1'),
            ),
            enum1: Enum1.value1,
          ),
        );
      });

      test('toForm - explode true', () {
        expect(anyOf.toForm(explode: true, allowEmpty: true), 'value1');
      });

      test('form roundtrip - explode true', () {
        final form = anyOf.toForm(explode: true, allowEmpty: true);
        final reconstructed = DeepNestedAnyOf.fromForm(form, explode: true);
        // Both nestedAnyOfInAnyOf and enum1 are set because NestedAnyOfInAnyOf.anyOfPrimitive contains a String variant.
        // Any string value can be decoded to String, so nestedAnyOfInAnyOf.anyOfPrimitive.string='value1'.
        expect(
          reconstructed,
          DeepNestedAnyOf(
            nestedAnyOfInAnyOf: NestedAnyOfInAnyOf(
              anyOfPrimitive: AnyOfPrimitive(string: 'value1'),
            ),
            enum1: Enum1.value1,
          ),
        );
      });

      test('toForm - explode false', () {
        expect(anyOf.toForm(explode: false, allowEmpty: true), 'value1');
      });

      test('form roundtrip - explode false', () {
        final form = anyOf.toForm(explode: false, allowEmpty: true);
        final reconstructed = DeepNestedAnyOf.fromForm(form, explode: false);
        // Both nestedAnyOfInAnyOf and enum1 are set because NestedAnyOfInAnyOf.anyOfPrimitive contains a String variant.
        // Any string value can be decoded to String, so nestedAnyOfInAnyOf.anyOfPrimitive.string='value1'.
        expect(
          reconstructed,
          DeepNestedAnyOf(
            nestedAnyOfInAnyOf: NestedAnyOfInAnyOf(
              anyOfPrimitive: AnyOfPrimitive(string: 'value1'),
            ),
            enum1: Enum1.value1,
          ),
        );
      });

      test('toSimple - explode true', () {
        expect(anyOf.toSimple(explode: true, allowEmpty: true), 'value1');
      });

      test('simple roundtrip - explode true', () {
        final simple = anyOf.toSimple(explode: true, allowEmpty: true);
        final reconstructed = DeepNestedAnyOf.fromSimple(simple, explode: true);
        // Both nestedAnyOfInAnyOf and enum1 are set because NestedAnyOfInAnyOf.anyOfPrimitive contains a String variant.
        // Any string value can be decoded to String, so nestedAnyOfInAnyOf.anyOfPrimitive.string='value1'.
        expect(
          reconstructed,
          DeepNestedAnyOf(
            nestedAnyOfInAnyOf: NestedAnyOfInAnyOf(
              anyOfPrimitive: AnyOfPrimitive(string: 'value1'),
            ),
            enum1: Enum1.value1,
          ),
        );
      });

      test('toSimple - explode false', () {
        expect(anyOf.toSimple(explode: false, allowEmpty: true), 'value1');
      });

      test('simple roundtrip - explode false', () {
        final simple = anyOf.toSimple(explode: false, allowEmpty: true);
        final reconstructed = DeepNestedAnyOf.fromSimple(
          simple,
          explode: false,
        );
        // Both nestedAnyOfInAnyOf and enum1 are set because NestedAnyOfInAnyOf.anyOfPrimitive contains a String variant.
        // Any string value can be decoded to String, so nestedAnyOfInAnyOf.anyOfPrimitive.string='value1'.
        expect(
          reconstructed,
          DeepNestedAnyOf(
            nestedAnyOfInAnyOf: NestedAnyOfInAnyOf(
              anyOfPrimitive: AnyOfPrimitive(string: 'value1'),
            ),
            enum1: Enum1.value1,
          ),
        );
      });

      test('toMatrix - explode false', () {
        expect(
          anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
          ';asdf=value1',
        );
      });

      test('toMatrix - explode true', () {
        expect(
          anyOf.toMatrix('asdf', explode: true, allowEmpty: true),
          ';asdf=value1',
        );
      });

      test('toLabel - explode true', () {
        expect(anyOf.toLabel(explode: true, allowEmpty: true), '.value1');
      });

      test('toLabel - explode false', () {
        expect(anyOf.toLabel(explode: false, allowEmpty: true), '.value1');
      });

      test('currentEncodingShape', () {
        expect(anyOf.currentEncodingShape, EncodingShape.simple);
      });
    });

    group('with nestedAnyOfInAnyOf', () {
      late DeepNestedAnyOf anyOf;

      setUp(() {
        anyOf = DeepNestedAnyOf(
          nestedAnyOfInAnyOf: NestedAnyOfInAnyOf(
            anyOfPrimitive: AnyOfPrimitive(string: 'test'),
            anyOfComplex: null,
          ),
        );
      });

      test('toJson', () {
        expect(anyOf.toJson(), 'test');
      });

      test('json roundtrip', () {
        final json = anyOf.toJson();
        final reconstructed = DeepNestedAnyOf.fromJson(json);
        expect(reconstructed, anyOf);
      });

      test('toForm - explode true', () {
        expect(anyOf.toForm(explode: true, allowEmpty: true), 'test');
      });

      test('form roundtrip - explode true', () {
        final form = anyOf.toForm(explode: true, allowEmpty: true);
        final reconstructed = DeepNestedAnyOf.fromForm(form, explode: true);
        expect(reconstructed, anyOf);
      });

      test('toForm - explode false', () {
        expect(anyOf.toForm(explode: false, allowEmpty: true), 'test');
      });

      test('form roundtrip - explode false', () {
        final form = anyOf.toForm(explode: false, allowEmpty: true);
        final reconstructed = DeepNestedAnyOf.fromForm(form, explode: false);
        expect(reconstructed, anyOf);
      });

      test('toSimple - explode true', () {
        expect(anyOf.toSimple(explode: true, allowEmpty: true), 'test');
      });

      test('simple roundtrip - explode true', () {
        final simple = anyOf.toSimple(explode: true, allowEmpty: true);
        final reconstructed = DeepNestedAnyOf.fromSimple(simple, explode: true);
        expect(reconstructed, anyOf);
      });

      test('toSimple - explode false', () {
        expect(anyOf.toSimple(explode: false, allowEmpty: true), 'test');
      });

      test('simple roundtrip - explode false', () {
        final simple = anyOf.toSimple(explode: false, allowEmpty: true);
        final reconstructed = DeepNestedAnyOf.fromSimple(
          simple,
          explode: false,
        );
        expect(reconstructed, anyOf);
      });

      test('toMatrix - explode false', () {
        expect(
          anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
          ';asdf=test',
        );
      });

      test('toMatrix - explode true', () {
        expect(
          anyOf.toMatrix('asdf', explode: true, allowEmpty: true),
          ';asdf=test',
        );
      });

      test('toLabel - explode true', () {
        expect(anyOf.toLabel(explode: true, allowEmpty: true), '.test');
      });

      test('toLabel - explode false', () {
        expect(anyOf.toLabel(explode: false, allowEmpty: true), '.test');
      });

      test('currentEncodingShape', () {
        expect(anyOf.currentEncodingShape, EncodingShape.simple);
      });
    });
  });

  group('TwoLevelMixedAnyOfOneOf', () {
    group('with enum1', () {
      late TwoLevelMixedAnyOfOneOf anyOf;

      setUp(() {
        anyOf = TwoLevelMixedAnyOfOneOf(
          twoLevelMixedAnyOfOneOfModel: TwoLevelMixedAnyOfOneOfModelEnum1(
            Enum1.value1,
          ),
        );
      });

      test('toJson', () {
        expect(anyOf.toJson(), 'value1');
      });

      test('json roundtrip', () {
        final json = anyOf.toJson();
        final reconstructed = TwoLevelMixedAnyOfOneOf.fromJson(json);
        expect(reconstructed, anyOf);
      });

      test('toForm - explode true', () {
        expect(anyOf.toForm(explode: true, allowEmpty: true), 'value1');
      });

      test('form roundtrip - explode true', () {
        final form = anyOf.toForm(explode: true, allowEmpty: true);
        final reconstructed = TwoLevelMixedAnyOfOneOf.fromForm(
          form,
          explode: true,
        );
        expect(reconstructed, anyOf);
      });

      test('toForm - explode false', () {
        expect(anyOf.toForm(explode: false, allowEmpty: true), 'value1');
      });

      test('form roundtrip - explode false', () {
        final form = anyOf.toForm(explode: false, allowEmpty: true);
        final reconstructed = TwoLevelMixedAnyOfOneOf.fromForm(
          form,
          explode: false,
        );
        expect(reconstructed, anyOf);
      });

      test('toSimple - explode true', () {
        expect(anyOf.toSimple(explode: true, allowEmpty: true), 'value1');
      });

      test('simple roundtrip - explode true', () {
        final simple = anyOf.toSimple(explode: true, allowEmpty: true);
        final reconstructed = TwoLevelMixedAnyOfOneOf.fromSimple(
          simple,
          explode: true,
        );
        expect(reconstructed, anyOf);
      });

      test('toSimple - explode false', () {
        expect(anyOf.toSimple(explode: false, allowEmpty: true), 'value1');
      });

      test('simple roundtrip - explode false', () {
        final simple = anyOf.toSimple(explode: false, allowEmpty: true);
        final reconstructed = TwoLevelMixedAnyOfOneOf.fromSimple(
          simple,
          explode: false,
        );
        expect(reconstructed, anyOf);
      });

      test('toMatrix - explode false', () {
        expect(
          anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
          ';asdf=value1',
        );
      });

      test('toMatrix - explode true', () {
        expect(
          anyOf.toMatrix('asdf', explode: true, allowEmpty: true),
          ';asdf=value1',
        );
      });

      test('toLabel - explode true', () {
        expect(anyOf.toLabel(explode: true, allowEmpty: true), '.value1');
      });

      test('toLabel - explode false', () {
        expect(anyOf.toLabel(explode: false, allowEmpty: true), '.value1');
      });

      test('currentEncodingShape', () {
        expect(anyOf.currentEncodingShape, EncodingShape.simple);
      });
    });

    group('with enum2', () {
      late TwoLevelMixedAnyOfOneOf anyOf;

      setUp(() {
        anyOf = TwoLevelMixedAnyOfOneOf(
          twoLevelMixedAnyOfOneOfModel: TwoLevelMixedAnyOfOneOfModelEnum2(
            Enum2.two,
          ),
        );
      });

      test('toJson', () {
        expect(anyOf.toJson(), 2);
      });

      test('json roundtrip', () {
        final json = anyOf.toJson();
        final reconstructed = TwoLevelMixedAnyOfOneOf.fromJson(json);
        expect(reconstructed, anyOf);
      });

      test('toForm - explode true', () {
        expect(anyOf.toForm(explode: true, allowEmpty: true), '2');
      });

      test('form roundtrip - explode true', () {
        final form = anyOf.toForm(explode: true, allowEmpty: true);
        final reconstructed = TwoLevelMixedAnyOfOneOf.fromForm(
          form,
          explode: true,
        );
        expect(reconstructed, anyOf);
      });

      test('toForm - explode false', () {
        expect(anyOf.toForm(explode: false, allowEmpty: true), '2');
      });

      test('form roundtrip - explode false', () {
        final form = anyOf.toForm(explode: false, allowEmpty: true);
        final reconstructed = TwoLevelMixedAnyOfOneOf.fromForm(
          form,
          explode: false,
        );
        expect(reconstructed, anyOf);
      });

      test('toSimple - explode true', () {
        expect(anyOf.toSimple(explode: true, allowEmpty: true), '2');
      });

      test('simple roundtrip - explode true', () {
        final simple = anyOf.toSimple(explode: true, allowEmpty: true);
        final reconstructed = TwoLevelMixedAnyOfOneOf.fromSimple(
          simple,
          explode: true,
        );
        expect(reconstructed, anyOf);
      });

      test('toSimple - explode false', () {
        expect(anyOf.toSimple(explode: false, allowEmpty: true), '2');
      });

      test('simple roundtrip - explode false', () {
        final simple = anyOf.toSimple(explode: false, allowEmpty: true);
        final reconstructed = TwoLevelMixedAnyOfOneOf.fromSimple(
          simple,
          explode: false,
        );
        expect(reconstructed, anyOf);
      });

      test('toMatrix - explode false', () {
        expect(
          anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
          ';asdf=2',
        );
      });

      test('toMatrix - explode true', () {
        expect(
          anyOf.toMatrix('asdf', explode: true, allowEmpty: true),
          ';asdf=2',
        );
      });

      test('toLabel - explode true', () {
        expect(anyOf.toLabel(explode: true, allowEmpty: true), '.2');
      });

      test('toLabel - explode false', () {
        expect(anyOf.toLabel(explode: false, allowEmpty: true), '.2');
      });

      test('currentEncodingShape', () {
        expect(anyOf.currentEncodingShape, EncodingShape.simple);
      });
    });
  });

  group('AnyOfWithSimpleList', () {
    group('string list', () {
      late AnyOfWithSimpleList anyOf;

      setUp(() {
        anyOf = AnyOfWithSimpleList(list2: ['test', 'test2']);
      });

      test('toJson', () {
        expect(anyOf.toJson(), ['test', 'test2']);
      });

      test('json roundtrip', () {
        final json = anyOf.toJson();
        final reconstructed = AnyOfWithSimpleList.fromJson(json);
        expect(reconstructed, anyOf);
      });

      test('toForm - explode true', () {
        expect(anyOf.toForm(explode: true, allowEmpty: true), 'test,test2');
      });

      test('form roundtrip - explode true', () {
        final form = anyOf.toForm(explode: true, allowEmpty: true);
        final reconstructed = AnyOfWithSimpleList.fromForm(form, explode: true);
        // Both list2 and string are set because any string can be decoded to String.
        expect(
          reconstructed,
          AnyOfWithSimpleList(list2: ['test', 'test2'], string: 'test,test2'),
        );
      });

      test('toForm - explode false', () {
        expect(anyOf.toForm(explode: false, allowEmpty: true), 'test,test2');
      });

      test('form roundtrip - explode false', () {
        final form = anyOf.toForm(explode: false, allowEmpty: true);
        final reconstructed = AnyOfWithSimpleList.fromForm(
          form,
          explode: false,
        );
        // Both list2 and string are set because any string can be decoded to String.
        expect(
          reconstructed,
          AnyOfWithSimpleList(list2: ['test', 'test2'], string: 'test,test2'),
        );
      });

      test('toSimple - explode true', () {
        expect(anyOf.toSimple(explode: true, allowEmpty: true), 'test,test2');
      });

      test('simple roundtrip - explode true', () {
        final simple = anyOf.toSimple(explode: true, allowEmpty: true);
        final reconstructed = AnyOfWithSimpleList.fromSimple(
          simple,
          explode: true,
        );
        // Both list2 and string are set because any string can be decoded to String.
        expect(
          reconstructed,
          AnyOfWithSimpleList(list2: ['test', 'test2'], string: 'test,test2'),
        );
      });

      test('toSimple - explode false', () {
        expect(anyOf.toSimple(explode: false, allowEmpty: true), 'test,test2');
      });

      test('simple roundtrip - explode false', () {
        final simple = anyOf.toSimple(explode: false, allowEmpty: true);
        final reconstructed = AnyOfWithSimpleList.fromSimple(
          simple,
          explode: false,
        );
        // Both list2 and string are set because any string can be decoded to String.
        expect(
          reconstructed,
          AnyOfWithSimpleList(list2: ['test', 'test2'], string: 'test,test2'),
        );
      });

      test('toMatrix - explode false', () {
        expect(
          anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
          ';asdf=test,test2',
        );
      });

      test('toMatrix - explode true', () {
        expect(
          anyOf.toMatrix('asdf', explode: true, allowEmpty: true),
          ';asdf=test;asdf=test2',
        );
      });

      test('toLabel - explode true', () {
        expect(anyOf.toLabel(explode: true, allowEmpty: true), '.test.test2');
      });

      test('toLabel - explode false', () {
        expect(anyOf.toLabel(explode: false, allowEmpty: true), '.test,test2');
      });

      test('currentEncodingShape', () {
        expect(anyOf.currentEncodingShape, EncodingShape.complex);
      });
    });

    group('integer list', () {
      late AnyOfWithSimpleList anyOf;

      setUp(() {
        anyOf = AnyOfWithSimpleList(list: [1, 2, 3]);
      });

      test('toJson', () {
        expect(anyOf.toJson(), [1, 2, 3]);
      });

      test('json roundtrip', () {
        final json = anyOf.toJson();
        final reconstructed = AnyOfWithSimpleList.fromJson(json);
        expect(reconstructed, anyOf);
      });

      test('toForm - explode true', () {
        expect(anyOf.toForm(explode: true, allowEmpty: true), '1,2,3');
      });

      test('form roundtrip - explode true', () {
        final form = anyOf.toForm(explode: true, allowEmpty: true);
        final reconstructed = AnyOfWithSimpleList.fromForm(form, explode: true);
        // All three fields are set: list, list2, and string.
        // The string '1,2,3' can be decoded as List<int>, List<String>, and String.
        expect(
          reconstructed,
          AnyOfWithSimpleList(
            list: [1, 2, 3],
            list2: ['1', '2', '3'],
            string: '1,2,3',
          ),
        );
      });

      test('toForm - explode false', () {
        expect(anyOf.toForm(explode: false, allowEmpty: true), '1,2,3');
      });

      test('form roundtrip - explode false', () {
        final form = anyOf.toForm(explode: false, allowEmpty: true);
        final reconstructed = AnyOfWithSimpleList.fromForm(
          form,
          explode: false,
        );
        // All three fields are set: list, list2, and string.
        // The string '1,2,3' can be decoded as List<int>, List<String>, and String.
        expect(
          reconstructed,
          AnyOfWithSimpleList(
            list: [1, 2, 3],
            list2: ['1', '2', '3'],
            string: '1,2,3',
          ),
        );
      });

      test('toSimple - explode true', () {
        expect(anyOf.toSimple(explode: true, allowEmpty: true), '1,2,3');
      });

      test('simple roundtrip - explode true', () {
        final simple = anyOf.toSimple(explode: true, allowEmpty: true);
        final reconstructed = AnyOfWithSimpleList.fromSimple(
          simple,
          explode: true,
        );
        // All three fields are set: list, list2, and string.
        // The string '1,2,3' can be decoded as List<int>, List<String>, and String.
        expect(
          reconstructed,
          AnyOfWithSimpleList(
            list: [1, 2, 3],
            list2: ['1', '2', '3'],
            string: '1,2,3',
          ),
        );
      });

      test('toSimple - explode false', () {
        expect(anyOf.toSimple(explode: false, allowEmpty: true), '1,2,3');
      });

      test('simple roundtrip - explode false', () {
        final simple = anyOf.toSimple(explode: false, allowEmpty: true);
        final reconstructed = AnyOfWithSimpleList.fromSimple(
          simple,
          explode: false,
        );
        // All three fields are set: list, list2, and string.
        // The string '1,2,3' can be decoded as List<int>, List<String>, and String.
        expect(
          reconstructed,
          AnyOfWithSimpleList(
            list: [1, 2, 3],
            list2: ['1', '2', '3'],
            string: '1,2,3',
          ),
        );
      });

      test('toMatrix - explode false', () {
        expect(
          anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
          ';asdf=1,2,3',
        );
      });

      test('toMatrix - explode true', () {
        expect(
          anyOf.toMatrix('asdf', explode: true, allowEmpty: true),
          ';asdf=1;asdf=2;asdf=3',
        );
      });

      test('toLabel - explode true', () {
        expect(anyOf.toLabel(explode: true, allowEmpty: true), '.1.2.3');
      });

      test('toLabel - explode false', () {
        expect(anyOf.toLabel(explode: false, allowEmpty: true), '.1,2,3');
      });

      test('currentEncodingShape', () {
        expect(anyOf.currentEncodingShape, EncodingShape.complex);
      });
    });

    group('both lists', () {
      late AnyOfWithSimpleList anyOf;

      setUp(() {
        anyOf = AnyOfWithSimpleList(list: [1, 2, 3], list2: ['test', 'test2']);
      });

      test('toJson throws EncodingException', () {
        expect(anyOf.toJson, throwsA(isA<EncodingException>()));
      });

      test('toForm throws EncodingException', () {
        expect(
          () => anyOf.toForm(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toSimple throws EncodingException', () {
        expect(
          () => anyOf.toSimple(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toMatrix throws EncodingException', () {
        expect(
          () => anyOf.toMatrix('asdf', explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toLabel - explode true throws EncodingException', () {
        expect(
          () => anyOf.toLabel(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toLabel - explode false throws EncodingException', () {
        expect(
          () => anyOf.toLabel(explode: false, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('currentEncodingShape', () {
        expect(anyOf.currentEncodingShape, EncodingShape.complex);
      });
    });
  });

  group('AnyOfWithComplexList', () {
    group('class1 list', () {
      late AnyOfWithComplexList anyOf;

      setUp(() {
        anyOf = AnyOfWithComplexList(
          list: [
            Class1(name: 'test'),
            Class1(name: 'test2'),
          ],
        );
      });

      test('toJson', () {
        expect(anyOf.toJson(), [
          {'name': 'test'},
          {'name': 'test2'},
        ]);
      });

      test('json roundtrip', () {
        final json = anyOf.toJson();
        final reconstructed = AnyOfWithComplexList.fromJson(json);
        expect(reconstructed, anyOf);
      });

      test('toForm throws EncodingException', () {
        expect(
          () => anyOf.toForm(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toSimple throws EncodingException', () {
        expect(
          () => anyOf.toSimple(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toMatrix - explode false throws EncodingException', () {
        expect(
          () => anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toMatrix - explode true throws EncodingException', () {
        expect(
          () => anyOf.toMatrix('asdf', explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toLabel - explode true throws EncodingException', () {
        expect(
          () => anyOf.toLabel(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toLabel - explode false throws EncodingException', () {
        expect(
          () => anyOf.toLabel(explode: false, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('currentEncodingShape', () {
        expect(anyOf.currentEncodingShape, EncodingShape.complex);
      });
    });

    group('class2 list', () {
      late AnyOfWithComplexList anyOf;

      setUp(() {
        anyOf = AnyOfWithComplexList(
          list2: [Class2(number: 1), Class2(number: 2)],
        );
      });

      test('toJson', () {
        expect(anyOf.toJson(), [
          {'number': 1},
          {'number': 2},
        ]);
      });

      test('json roundtrip', () {
        final json = anyOf.toJson();
        final reconstructed = AnyOfWithComplexList.fromJson(json);
        expect(reconstructed, anyOf);
      });

      test('toForm throws EncodingException', () {
        expect(
          () => anyOf.toForm(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toSimple throws EncodingException', () {
        expect(
          () => anyOf.toSimple(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toMatrix - explode false throws EncodingException', () {
        expect(
          () => anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toMatrix - explode true throws EncodingException', () {
        expect(
          () => anyOf.toMatrix('asdf', explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toLabel - explode true throws EncodingException', () {
        expect(
          () => anyOf.toLabel(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toLabel - explode false throws EncodingException', () {
        expect(
          () => anyOf.toLabel(explode: false, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('currentEncodingShape', () {
        expect(anyOf.currentEncodingShape, EncodingShape.complex);
      });
    });

    group('string', () {
      late AnyOfWithComplexList anyOf;

      setUp(() {
        anyOf = AnyOfWithComplexList(string: 'asdf asdf');
      });

      test('toJson', () {
        expect(anyOf.toJson(), 'asdf asdf');
      });

      test('json roundtrip', () {
        final json = anyOf.toJson();
        final reconstructed = AnyOfWithComplexList.fromJson(json);
        expect(reconstructed, anyOf);
      });

      test('toForm - explode true', () {
        expect(anyOf.toForm(explode: true, allowEmpty: true), 'asdf%20asdf');
      });

      test('form roundtrip - explode true', () {
        final form = anyOf.toForm(explode: true, allowEmpty: true);
        final reconstructed = AnyOfWithComplexList.fromForm(
          form,
          explode: true,
        );
        expect(reconstructed, anyOf);
      });

      test('toForm - explode false', () {
        expect(anyOf.toForm(explode: false, allowEmpty: true), 'asdf%20asdf');
      });

      test('form roundtrip - explode false', () {
        final form = anyOf.toForm(explode: false, allowEmpty: true);
        final reconstructed = AnyOfWithComplexList.fromForm(
          form,
          explode: false,
        );
        expect(reconstructed, anyOf);
      });

      test('toSimple - explode true', () {
        expect(anyOf.toSimple(explode: true, allowEmpty: true), 'asdf%20asdf');
      });

      test('simple roundtrip - explode true', () {
        final simple = anyOf.toSimple(explode: true, allowEmpty: true);
        final reconstructed = AnyOfWithComplexList.fromSimple(
          simple,
          explode: true,
        );
        expect(reconstructed, anyOf);
      });

      test('toSimple - explode false', () {
        expect(anyOf.toSimple(explode: false, allowEmpty: true), 'asdf%20asdf');
      });

      test('simple roundtrip - explode false', () {
        final simple = anyOf.toSimple(explode: false, allowEmpty: true);
        final reconstructed = AnyOfWithComplexList.fromSimple(
          simple,
          explode: false,
        );
        expect(reconstructed, anyOf);
      });

      test('toMatrix - explode false', () {
        expect(
          anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
          ';asdf=asdf%20asdf',
        );
      });

      test('toMatrix - explode true', () {
        expect(
          anyOf.toMatrix('asdf', explode: true, allowEmpty: true),
          ';asdf=asdf%20asdf',
        );
      });

      test('toLabel - explode true', () {
        expect(anyOf.toLabel(explode: true, allowEmpty: true), '.asdf%20asdf');
      });

      test('toLabel - explode false', () {
        expect(anyOf.toLabel(explode: false, allowEmpty: true), '.asdf%20asdf');
      });

      test('currentEncodingShape', () {
        expect(anyOf.currentEncodingShape, EncodingShape.simple);
      });
    });

    group('all together', () {
      late AnyOfWithComplexList anyOf;

      setUp(() {
        anyOf = AnyOfWithComplexList(
          list: [Class1(name: 'test')],
          list2: [Class2(number: 1)],
          string: 'asdf',
        );
      });

      test('toJson throws EncodingException', () {
        expect(anyOf.toJson, throwsA(isA<EncodingException>()));
      });

      test('toForm throws EncodingException', () {
        expect(
          () => anyOf.toForm(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toSimple throws EncodingException', () {
        expect(
          () => anyOf.toSimple(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toMatrix throws EncodingException', () {
        expect(
          () => anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toLabel - explode true throws EncodingException', () {
        expect(
          () => anyOf.toLabel(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toLabel - explode false throws EncodingException', () {
        expect(
          () => anyOf.toLabel(explode: false, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('currentEncodingShape', () {
        expect(anyOf.currentEncodingShape, EncodingShape.mixed);
      });
    });
  });

  group('AnyOfWithMixedLists', () {
    group('integer list', () {
      late AnyOfWithMixedLists anyOf;

      setUp(() {
        anyOf = AnyOfWithMixedLists(list2: [1, 2, 3]);
      });

      test('toJson', () {
        expect(anyOf.toJson(), [1, 2, 3]);
      });

      test('json roundtrip', () {
        final json = anyOf.toJson();
        final reconstructed = AnyOfWithMixedLists.fromJson(json);
        expect(reconstructed, anyOf);
      });

      test('toForm - explode true', () {
        expect(anyOf.toForm(explode: true, allowEmpty: true), '1,2,3');
      });

      test('form roundtrip - explode true', () {
        final form = anyOf.toForm(explode: true, allowEmpty: true);
        final reconstructed = AnyOfWithMixedLists.fromForm(form, explode: true);
        expect(reconstructed, anyOf);
      });

      test('toForm - explode false', () {
        expect(anyOf.toForm(explode: false, allowEmpty: true), '1,2,3');
      });

      test('form roundtrip - explode false', () {
        final form = anyOf.toForm(explode: false, allowEmpty: true);
        final reconstructed = AnyOfWithMixedLists.fromForm(
          form,
          explode: false,
        );
        expect(reconstructed, anyOf);
      });

      test('toSimple - explode true', () {
        expect(anyOf.toSimple(explode: true, allowEmpty: true), '1,2,3');
      });

      test('simple roundtrip - explode true', () {
        final simple = anyOf.toSimple(explode: true, allowEmpty: true);
        final reconstructed = AnyOfWithMixedLists.fromSimple(
          simple,
          explode: true,
        );
        expect(reconstructed, anyOf);
      });

      test('toSimple - explode false', () {
        expect(anyOf.toSimple(explode: false, allowEmpty: true), '1,2,3');
      });

      test('simple roundtrip - explode false', () {
        final simple = anyOf.toSimple(explode: false, allowEmpty: true);
        final reconstructed = AnyOfWithMixedLists.fromSimple(
          simple,
          explode: false,
        );
        expect(reconstructed, anyOf);
      });

      test('toMatrix - explode false', () {
        expect(
          anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
          ';asdf=1,2,3',
        );
      });

      test('toMatrix - explode true', () {
        expect(
          anyOf.toMatrix('asdf', explode: true, allowEmpty: true),
          ';asdf=1;asdf=2;asdf=3',
        );
      });

      test('toLabel - explode true', () {
        expect(anyOf.toLabel(explode: true, allowEmpty: true), '.1.2.3');
      });

      test('toLabel - explode false', () {
        expect(anyOf.toLabel(explode: false, allowEmpty: true), '.1,2,3');
      });

      test('currentEncodingShape', () {
        expect(anyOf.currentEncodingShape, EncodingShape.complex);
      });
    });

    group('class1 list', () {
      late AnyOfWithMixedLists anyOf;

      setUp(() {
        anyOf = AnyOfWithMixedLists(
          list: [
            Class1(name: 'test'),
            Class1(name: 'test2'),
          ],
        );
      });

      test('toJson', () {
        expect(anyOf.toJson(), [
          {'name': 'test'},
          {'name': 'test2'},
        ]);
      });

      test('json roundtrip', () {
        final json = anyOf.toJson();
        final reconstructed = AnyOfWithMixedLists.fromJson(json);
        expect(reconstructed, anyOf);
      });

      test('toForm throws EncodingException', () {
        expect(
          () => anyOf.toForm(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toSimple throws EncodingException', () {
        expect(
          () => anyOf.toSimple(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toMatrix - explode false throws EncodingException', () {
        expect(
          () => anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toMatrix - explode true throws EncodingException', () {
        expect(
          () => anyOf.toMatrix('asdf', explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toLabel - explode true throws EncodingException', () {
        expect(
          () => anyOf.toLabel(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toLabel - explode false throws EncodingException', () {
        expect(
          () => anyOf.toLabel(explode: false, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('currentEncodingShape', () {
        expect(anyOf.currentEncodingShape, EncodingShape.complex);
      });
    });

    group('boolean', () {
      late AnyOfWithMixedLists anyOf;

      setUp(() {
        anyOf = AnyOfWithMixedLists(bool: true);
      });

      test('toJson', () {
        expect(anyOf.toJson(), true);
      });

      test('json roundtrip', () {
        final json = anyOf.toJson();
        final reconstructed = AnyOfWithMixedLists.fromJson(json);
        expect(reconstructed, anyOf);
      });

      test('toForm - explode true', () {
        expect(anyOf.toForm(explode: true, allowEmpty: true), 'true');
      });

      test('form roundtrip - explode true', () {
        final form = anyOf.toForm(explode: true, allowEmpty: true);
        final reconstructed = AnyOfWithMixedLists.fromForm(form, explode: true);
        expect(reconstructed, anyOf);
      });

      test('toForm - explode false', () {
        expect(anyOf.toForm(explode: false, allowEmpty: true), 'true');
      });

      test('form roundtrip - explode false', () {
        final form = anyOf.toForm(explode: false, allowEmpty: true);
        final reconstructed = AnyOfWithMixedLists.fromForm(
          form,
          explode: false,
        );
        expect(reconstructed, anyOf);
      });

      test('toSimple - explode true', () {
        expect(anyOf.toSimple(explode: true, allowEmpty: true), 'true');
      });

      test('simple roundtrip - explode true', () {
        final simple = anyOf.toSimple(explode: true, allowEmpty: true);
        final reconstructed = AnyOfWithMixedLists.fromSimple(
          simple,
          explode: true,
        );
        expect(reconstructed, anyOf);
      });

      test('toSimple - explode false', () {
        expect(anyOf.toSimple(explode: false, allowEmpty: true), 'true');
      });

      test('simple roundtrip - explode false', () {
        final simple = anyOf.toSimple(explode: false, allowEmpty: true);
        final reconstructed = AnyOfWithMixedLists.fromSimple(
          simple,
          explode: false,
        );
        expect(reconstructed, anyOf);
      });

      test('toMatrix - explode false', () {
        expect(
          anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
          ';asdf=true',
        );
      });

      test('toMatrix - explode true', () {
        expect(
          anyOf.toMatrix('asdf', explode: true, allowEmpty: true),
          ';asdf=true',
        );
      });

      test('toLabel - explode true', () {
        expect(anyOf.toLabel(explode: true, allowEmpty: true), '.true');
      });

      test('toLabel - explode false', () {
        expect(anyOf.toLabel(explode: false, allowEmpty: true), '.true');
      });

      test('currentEncodingShape', () {
        expect(anyOf.currentEncodingShape, EncodingShape.simple);
      });
    });

    group('all together', () {
      late AnyOfWithMixedLists anyOf;

      setUp(() {
        anyOf = AnyOfWithMixedLists(
          list: [Class1(name: 'test')],
          list2: [1, 2, 3],
          bool: false,
        );
      });

      test('toJson throws EncodingException', () {
        expect(anyOf.toJson, throwsA(isA<EncodingException>()));
      });

      test('toForm throws EncodingException', () {
        expect(
          () => anyOf.toForm(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toSimple throws EncodingException', () {
        expect(
          () => anyOf.toSimple(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toMatrix throws EncodingException', () {
        expect(
          () => anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toLabel - explode true throws EncodingException', () {
        expect(
          () => anyOf.toLabel(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toLabel - explode false throws EncodingException', () {
        expect(
          () => anyOf.toLabel(explode: false, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('currentEncodingShape', () {
        expect(anyOf.currentEncodingShape, EncodingShape.mixed);
      });
    });
  });

  group('AnyOfWithEnumList', () {
    group('enum 1', () {
      late AnyOfWithEnumList anyOf;

      setUp(() {
        anyOf = AnyOfWithEnumList(list: [Enum1.value1, Enum1.value2]);
      });

      test('toJson', () {
        expect(anyOf.toJson(), ['value1', 'value2']);
      });

      test('json roundtrip', () {
        final json = anyOf.toJson();
        final reconstructed = AnyOfWithEnumList.fromJson(json);
        expect(reconstructed, anyOf);
      });

      test('toForm - explode true', () {
        expect(anyOf.toForm(explode: true, allowEmpty: true), 'value1,value2');
      });

      test('form roundtrip - explode true', () {
        final form = anyOf.toForm(explode: true, allowEmpty: true);
        final reconstructed = AnyOfWithEnumList.fromForm(form, explode: true);
        // Both list and string are set because any string can be decoded to String.
        expect(
          reconstructed,
          AnyOfWithEnumList(
            list: [Enum1.value1, Enum1.value2],
            string: 'value1,value2',
          ),
        );
      });

      test('toForm - explode false', () {
        expect(anyOf.toForm(explode: false, allowEmpty: true), 'value1,value2');
      });

      test('form roundtrip - explode false', () {
        final form = anyOf.toForm(explode: false, allowEmpty: true);
        final reconstructed = AnyOfWithEnumList.fromForm(form, explode: false);
        // Both list and string are set because any string can be decoded to String.
        expect(
          reconstructed,
          AnyOfWithEnumList(
            list: [Enum1.value1, Enum1.value2],
            string: 'value1,value2',
          ),
        );
      });

      test('toSimple - explode true', () {
        expect(
          anyOf.toSimple(explode: true, allowEmpty: true),
          'value1,value2',
        );
      });

      test('simple roundtrip - explode true', () {
        final simple = anyOf.toSimple(explode: true, allowEmpty: true);
        final reconstructed = AnyOfWithEnumList.fromSimple(
          simple,
          explode: true,
        );
        // Both list and string are set because any string can be decoded to String.
        expect(
          reconstructed,
          AnyOfWithEnumList(
            list: [Enum1.value1, Enum1.value2],
            string: 'value1,value2',
          ),
        );
      });

      test('toSimple - explode false', () {
        expect(
          anyOf.toSimple(explode: false, allowEmpty: true),
          'value1,value2',
        );
      });

      test('simple roundtrip - explode false', () {
        final simple = anyOf.toSimple(explode: false, allowEmpty: true);
        final reconstructed = AnyOfWithEnumList.fromSimple(
          simple,
          explode: false,
        );
        // Both list and string are set because any string can be decoded to String.
        expect(
          reconstructed,
          AnyOfWithEnumList(
            list: [Enum1.value1, Enum1.value2],
            string: 'value1,value2',
          ),
        );
      });

      test('toMatrix - explode false', () {
        expect(
          anyOf.toMatrix('anyOf', explode: false, allowEmpty: true),
          ';anyOf=value1,value2',
        );
      });

      test('toMatrix - explode true', () {
        expect(
          anyOf.toMatrix('anyOf', explode: true, allowEmpty: true),
          ';anyOf=value1;anyOf=value2',
        );
      });

      test('toLabel - explode true', () {
        expect(
          anyOf.toLabel(explode: true, allowEmpty: true),
          '.value1.value2',
        );
      });

      test('toLabel - explode false', () {
        expect(
          anyOf.toLabel(explode: false, allowEmpty: true),
          '.value1,value2',
        );
      });

      test('currentEncodingShape', () {
        expect(anyOf.currentEncodingShape, EncodingShape.complex);
      });
    });

    group('enum 2', () {
      late AnyOfWithEnumList anyOf;

      setUp(() {
        anyOf = AnyOfWithEnumList(list2: [Enum2.one, Enum2.two]);
      });

      test('toJson', () {
        expect(anyOf.toJson(), [1, 2]);
      });

      test('json roundtrip', () {
        final json = anyOf.toJson();
        final reconstructed = AnyOfWithEnumList.fromJson(json);
        expect(reconstructed, anyOf);
      });

      test('toForm - explode true', () {
        expect(anyOf.toForm(explode: true, allowEmpty: true), '1,2');
      });

      test('form roundtrip - explode true', () {
        final form = anyOf.toForm(explode: true, allowEmpty: true);
        final reconstructed = AnyOfWithEnumList.fromForm(form, explode: true);
        // Both list2 and string are set because any string can be decoded to String.
        expect(
          reconstructed,
          AnyOfWithEnumList(list2: [Enum2.one, Enum2.two], string: '1,2'),
        );
      });

      test('toForm - explode false', () {
        expect(anyOf.toForm(explode: false, allowEmpty: true), '1,2');
      });

      test('form roundtrip - explode false', () {
        final form = anyOf.toForm(explode: false, allowEmpty: true);
        final reconstructed = AnyOfWithEnumList.fromForm(form, explode: false);
        // Both list2 and string are set because any string can be decoded to String.
        expect(
          reconstructed,
          AnyOfWithEnumList(list2: [Enum2.one, Enum2.two], string: '1,2'),
        );
      });

      test('toSimple - explode true', () {
        expect(anyOf.toSimple(explode: true, allowEmpty: true), '1,2');
      });

      test('simple roundtrip - explode true', () {
        final simple = anyOf.toSimple(explode: true, allowEmpty: true);
        final reconstructed = AnyOfWithEnumList.fromSimple(
          simple,
          explode: true,
        );
        // Both list2 and string are set because any string can be decoded to String.
        expect(
          reconstructed,
          AnyOfWithEnumList(list2: [Enum2.one, Enum2.two], string: '1,2'),
        );
      });

      test('toSimple - explode false', () {
        expect(anyOf.toSimple(explode: false, allowEmpty: true), '1,2');
      });

      test('simple roundtrip - explode false', () {
        final simple = anyOf.toSimple(explode: false, allowEmpty: true);
        final reconstructed = AnyOfWithEnumList.fromSimple(
          simple,
          explode: false,
        );
        // Both list2 and string are set because any string can be decoded to String.
        expect(
          reconstructed,
          AnyOfWithEnumList(list2: [Enum2.one, Enum2.two], string: '1,2'),
        );
      });

      test('toMatrix - explode false', () {
        expect(
          anyOf.toMatrix('anyOf', explode: false, allowEmpty: true),
          ';anyOf=1,2',
        );
      });

      test('toMatrix - explode true', () {
        expect(
          anyOf.toMatrix('anyOf', explode: true, allowEmpty: true),
          ';anyOf=1;anyOf=2',
        );
      });

      test('toLabel - explode true', () {
        expect(anyOf.toLabel(explode: true, allowEmpty: true), '.1.2');
      });

      test('toLabel - explode false', () {
        expect(anyOf.toLabel(explode: false, allowEmpty: true), '.1,2');
      });

      test('currentEncodingShape', () {
        expect(anyOf.currentEncodingShape, EncodingShape.complex);
      });
    });

    group('enum 1 and string', () {
      late AnyOfWithEnumList anyOf;

      setUp(() {
        anyOf = AnyOfWithEnumList(
          list: [Enum1.value1, Enum1.value2],
          string: 'test',
        );
      });

      test('toJson throws EncodingException', () {
        expect(anyOf.toJson, throwsA(isA<EncodingException>()));
      });

      test('toForm throws EncodingException', () {
        expect(
          () => anyOf.toForm(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toSimple throws EncodingException', () {
        expect(
          () => anyOf.toSimple(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toMatrix throws EncodingException', () {
        expect(
          () => anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toLabel - explode true throws EncodingException', () {
        expect(
          () => anyOf.toLabel(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toLabel - explode false throws EncodingException', () {
        expect(
          () => anyOf.toLabel(explode: false, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('currentEncodingShape', () {
        expect(anyOf.currentEncodingShape, EncodingShape.mixed);
      });
    });

    group('enum 2 and string', () {
      late AnyOfWithEnumList anyOf;

      setUp(() {
        anyOf = AnyOfWithEnumList(
          list2: [Enum2.one, Enum2.two],
          string: 'test',
        );
      });

      test('toJson throws EncodingException', () {
        expect(anyOf.toJson, throwsA(isA<EncodingException>()));
      });

      test('toForm throws EncodingException', () {
        expect(
          () => anyOf.toForm(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toSimple throws EncodingException', () {
        expect(
          () => anyOf.toSimple(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toMatrix throws EncodingException', () {
        expect(
          () => anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toLabel - explode true throws EncodingException', () {
        expect(
          () => anyOf.toLabel(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toLabel - explode false throws EncodingException', () {
        expect(
          () => anyOf.toLabel(explode: false, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('currentEncodingShape', () {
        expect(anyOf.currentEncodingShape, EncodingShape.mixed);
      });
    });
  });

  group('NestedListInAnyOf', () {
    group('list of strings', () {
      late NestedListInAnyOf anyOf;

      setUp(() {
        anyOf = NestedListInAnyOf(
          list: [
            ['test', 'test2'],
          ],
        );
      });

      test('toJson', () {
        expect(anyOf.toJson(), [
          ['test', 'test2'],
        ]);
      });

      test('json roundtrip', () {
        final json = anyOf.toJson();
        final reconstructed = NestedListInAnyOf.fromJson(json);
        expect(reconstructed, anyOf);
      });

      test('toForm throws EncodingException', () {
        expect(
          () => anyOf.toForm(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toSimple - explode true throws EncodingException', () {
        expect(
          () => anyOf.toSimple(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toSimple - explode false throws EncodingException', () {
        expect(
          () => anyOf.toSimple(explode: false, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toMatrix - explode false throws EncodingException', () {
        expect(
          () => anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toMatrix - explode true throws EncodingException', () {
        expect(
          () => anyOf.toMatrix('asdf', explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toLabel - explode true throws EncodingException', () {
        expect(
          () => anyOf.toLabel(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toLabel - explode false throws EncodingException', () {
        expect(
          () => anyOf.toLabel(explode: false, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('currentEncodingShape', () {
        expect(anyOf.currentEncodingShape, EncodingShape.complex);
      });
    });

    group('string', () {
      late NestedListInAnyOf anyOf;

      setUp(() {
        anyOf = NestedListInAnyOf(string: 'just a string');
      });

      test('toJson', () {
        expect(anyOf.toJson(), 'just a string');
      });

      test('json roundtrip', () {
        final json = anyOf.toJson();
        final reconstructed = NestedListInAnyOf.fromJson(json);
        expect(reconstructed, anyOf);
      });

      test('toForm - explode true', () {
        expect(
          anyOf.toForm(explode: true, allowEmpty: true),
          'just%20a%20string',
        );
      });

      test('form roundtrip - explode true', () {
        final form = anyOf.toForm(explode: true, allowEmpty: true);
        final reconstructed = NestedListInAnyOf.fromForm(form, explode: true);
        expect(reconstructed, anyOf);
      });

      test('toForm - explode false', () {
        expect(
          anyOf.toForm(explode: false, allowEmpty: true),
          'just%20a%20string',
        );
      });

      test('form roundtrip - explode false', () {
        final form = anyOf.toForm(explode: false, allowEmpty: true);
        final reconstructed = NestedListInAnyOf.fromForm(form, explode: false);
        expect(reconstructed, anyOf);
      });

      test('toSimple - explode true', () {
        expect(
          anyOf.toSimple(explode: true, allowEmpty: true),
          'just%20a%20string',
        );
      });

      test('simple roundtrip - explode true', () {
        final simple = anyOf.toSimple(explode: true, allowEmpty: true);
        final reconstructed = NestedListInAnyOf.fromSimple(
          simple,
          explode: true,
        );
        expect(reconstructed, anyOf);
      });

      test('toSimple - explode false', () {
        expect(
          anyOf.toSimple(explode: false, allowEmpty: true),
          'just%20a%20string',
        );
      });

      test('simple roundtrip - explode false', () {
        final simple = anyOf.toSimple(explode: false, allowEmpty: true);
        final reconstructed = NestedListInAnyOf.fromSimple(
          simple,
          explode: false,
        );
        expect(reconstructed, anyOf);
      });

      test('toMatrix - explode false', () {
        expect(
          anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
          ';asdf=just%20a%20string',
        );
      });

      test('toMatrix - explode true', () {
        expect(
          anyOf.toMatrix('asdf', explode: true, allowEmpty: true),
          ';asdf=just%20a%20string',
        );
      });

      test('toLabel - explode true', () {
        expect(
          anyOf.toLabel(explode: true, allowEmpty: true),
          '.just%20a%20string',
        );
      });

      test('toLabel - explode false', () {
        expect(
          anyOf.toLabel(explode: false, allowEmpty: true),
          '.just%20a%20string',
        );
      });

      test('currentEncodingShape', () {
        expect(anyOf.currentEncodingShape, EncodingShape.simple);
      });
    });

    group('both', () {
      late NestedListInAnyOf anyOf;

      setUp(() {
        anyOf = NestedListInAnyOf(
          list: [
            ['test', 'test2'],
          ],
          string: 'just a string',
        );
      });

      test('toJson throws EncodingException', () {
        expect(anyOf.toJson, throwsA(isA<EncodingException>()));
      });

      test('toForm throws EncodingException', () {
        expect(
          () => anyOf.toForm(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toSimple throws EncodingException', () {
        expect(
          () => anyOf.toSimple(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toMatrix throws EncodingException', () {
        expect(
          () => anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toLabel - explode true throws EncodingException', () {
        expect(
          () => anyOf.toLabel(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toLabel - explode false throws EncodingException', () {
        expect(
          () => anyOf.toLabel(explode: false, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('currentEncodingShape', () {
        expect(anyOf.currentEncodingShape, EncodingShape.mixed);
      });
    });
  });

  group('AnyOfWithListOfComposites', () {
    group('array', () {
      late AnyOfWithListOfComposites anyOf;

      setUp(() {
        anyOf = AnyOfWithListOfComposites(
          list: [
            AnyOfWithListOfCompositesArrayAllOfModel(
              anyOfWithListOfCompositesArrayAllOfModel2:
                  AnyOfWithListOfCompositesArrayAllOfModel2(extra: 'extra'),
              class1: Class1(name: 'name'),
            ),
          ],
        );
      });

      test('toJson', () {
        expect(anyOf.toJson(), [
          {'extra': 'extra', 'name': 'name'},
        ]);
      });

      test('json roundtrip', () {
        final json = anyOf.toJson();
        final reconstructed = AnyOfWithListOfComposites.fromJson(json);
        expect(reconstructed, anyOf);
      });

      test('toForm throws EncodingException', () {
        expect(
          () => anyOf.toForm(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toSimple throws EncodingException', () {
        expect(
          () => anyOf.toSimple(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toMatrix - explode false throws EncodingException', () {
        expect(
          () => anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toMatrix - explode true throws EncodingException', () {
        expect(
          () => anyOf.toMatrix('asdf', explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toLabel - explode true throws EncodingException', () {
        expect(
          () => anyOf.toLabel(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toLabel - explode false throws EncodingException', () {
        expect(
          () => anyOf.toLabel(explode: false, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('currentEncodingShape', () {
        expect(anyOf.currentEncodingShape, EncodingShape.complex);
      });
    });

    group('string', () {
      late AnyOfWithListOfComposites anyOf;

      setUp(() {
        anyOf = AnyOfWithListOfComposites(string: 'test string');
      });

      test('toJson', () {
        expect(anyOf.toJson(), 'test string');
      });

      test('json roundtrip', () {
        final json = anyOf.toJson();
        final reconstructed = AnyOfWithListOfComposites.fromJson(json);
        expect(reconstructed, anyOf);
      });

      test('toForm - explode true', () {
        expect(anyOf.toForm(explode: true, allowEmpty: true), 'test%20string');
      });

      test('form roundtrip - explode true', () {
        final form = anyOf.toForm(explode: true, allowEmpty: true);
        final reconstructed = AnyOfWithListOfComposites.fromForm(
          form,
          explode: true,
        );
        expect(reconstructed, anyOf);
      });

      test('toForm - explode false', () {
        expect(anyOf.toForm(explode: false, allowEmpty: true), 'test%20string');
      });

      test('form roundtrip - explode false', () {
        final form = anyOf.toForm(explode: false, allowEmpty: true);
        final reconstructed = AnyOfWithListOfComposites.fromForm(
          form,
          explode: false,
        );
        expect(reconstructed, anyOf);
      });

      test('toSimple - explode true', () {
        expect(
          anyOf.toSimple(explode: true, allowEmpty: true),
          'test%20string',
        );
      });

      test('simple roundtrip - explode true', () {
        final simple = anyOf.toSimple(explode: true, allowEmpty: true);
        final reconstructed = AnyOfWithListOfComposites.fromSimple(
          simple,
          explode: true,
        );
        expect(reconstructed, anyOf);
      });

      test('toSimple - explode false', () {
        expect(
          anyOf.toSimple(explode: false, allowEmpty: true),
          'test%20string',
        );
      });

      test('simple roundtrip - explode false', () {
        final simple = anyOf.toSimple(explode: false, allowEmpty: true);
        final reconstructed = AnyOfWithListOfComposites.fromSimple(
          simple,
          explode: false,
        );
        expect(reconstructed, anyOf);
      });

      test('toMatrix - explode false', () {
        expect(
          anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
          ';asdf=test%20string',
        );
      });

      test('toMatrix - explode true', () {
        expect(
          anyOf.toMatrix('asdf', explode: true, allowEmpty: true),
          ';asdf=test%20string',
        );
      });

      test('toLabel - explode true', () {
        expect(
          anyOf.toLabel(explode: true, allowEmpty: true),
          '.test%20string',
        );
      });

      test('toLabel - explode false', () {
        expect(
          anyOf.toLabel(explode: false, allowEmpty: true),
          '.test%20string',
        );
      });

      test('currentEncodingShape', () {
        expect(anyOf.currentEncodingShape, EncodingShape.simple);
      });
    });

    group('both', () {
      late AnyOfWithListOfComposites anyOf;

      setUp(() {
        anyOf = AnyOfWithListOfComposites(
          list: [
            AnyOfWithListOfCompositesArrayAllOfModel(
              anyOfWithListOfCompositesArrayAllOfModel2:
                  AnyOfWithListOfCompositesArrayAllOfModel2(extra: 'extra'),
              class1: Class1(name: 'name'),
            ),
          ],
          string: 'test string',
        );
      });

      test('toJson throws EncodingException', () {
        expect(anyOf.toJson, throwsA(isA<EncodingException>()));
      });

      test('toForm throws EncodingException', () {
        expect(
          () => anyOf.toForm(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toSimple throws EncodingException', () {
        expect(
          () => anyOf.toSimple(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toMatrix throws EncodingException', () {
        expect(
          () => anyOf.toMatrix('asdf', explode: false, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toLabel - explode true throws EncodingException', () {
        expect(
          () => anyOf.toLabel(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toLabel - explode false throws EncodingException', () {
        expect(
          () => anyOf.toLabel(explode: false, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('currentEncodingShape', () {
        expect(anyOf.currentEncodingShape, EncodingShape.mixed);
      });
    });
  });
}
