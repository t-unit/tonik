import 'package:composition_api/composition_api.dart';
import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  group('OneOfPrimitive', () {
    group('string', () {
      late OneOfPrimitive oneOf;

      setUp(() {
        oneOf = OneOfPrimitiveString('string');
      });

      test('toJson', () {
        expect(oneOf.toJson(), 'string');
      });

      test('json roundtrip', () {
        final json = oneOf.toJson();
        final reconstructed = OneOfPrimitive.fromJson(json);
        expect(reconstructed, oneOf);
      });

      test('toForm - explode true', () {
        expect(oneOf.toForm(explode: true, allowEmpty: true), 'string');
      });

      test('form roundtrip - explode true', () {
        final form = oneOf.toForm(explode: true, allowEmpty: true);
        final reconstructed = OneOfPrimitive.fromForm(form, explode: true);
        expect(reconstructed, oneOf);
      });

      test('toForm - explode false', () {
        expect(oneOf.toForm(explode: false, allowEmpty: true), 'string');
      });

      test('form roundtrip - explode false', () {
        final form = oneOf.toForm(explode: false, allowEmpty: true);
        final reconstructed = OneOfPrimitive.fromForm(form, explode: false);
        expect(reconstructed, oneOf);
      });

      test('toSimple - explode true', () {
        expect(oneOf.toSimple(explode: true, allowEmpty: true), 'string');
      });

      test('simple roundtrip - explode true', () {
        final simple = oneOf.toSimple(explode: true, allowEmpty: true);
        final reconstructed = OneOfPrimitive.fromSimple(simple, explode: true);
        expect(reconstructed, oneOf);
      });

      test('toSimple - explode false', () {
        expect(oneOf.toSimple(explode: false, allowEmpty: true), 'string');
      });

      test('simple roundtrip - explode false', () {
        final simple = oneOf.toSimple(explode: false, allowEmpty: true);
        final reconstructed = OneOfPrimitive.fromSimple(simple, explode: false);
        expect(reconstructed, oneOf);
      });

      test('toMatrix - explode false', () {
        expect(
          oneOf.toMatrix('asdf', explode: false, allowEmpty: true),
          ';asdf=string',
        );
      });

      test('toMatrix - explode true', () {
        expect(
          oneOf.toMatrix('asdf', explode: true, allowEmpty: true),
          ';asdf=string',
        );
      });

      test('toLabel - explode true', () {
        expect(oneOf.toLabel(explode: true, allowEmpty: true), '.string');
      });

      test('toLabel - explode false', () {
        expect(oneOf.toLabel(explode: false, allowEmpty: true), '.string');
      });

      test('currentEncodingShape', () {
        expect(oneOf.currentEncodingShape, EncodingShape.simple);
      });
    });

    group('integer', () {
      late OneOfPrimitive oneOf;

      setUp(() {
        oneOf = OneOfPrimitiveInt(1);
      });

      test('toJson', () {
        expect(oneOf.toJson(), 1);
      });

      test('json roundtrip', () {
        final json = oneOf.toJson();
        final reconstructed = OneOfPrimitive.fromJson(json);
        expect(reconstructed, oneOf);
      });

      test('toForm - explode true', () {
        expect(oneOf.toForm(explode: true, allowEmpty: true), '1');
      });

      test('form roundtrip - explode true', () {
        final form = oneOf.toForm(explode: true, allowEmpty: true);
        final reconstructed = OneOfPrimitive.fromForm(form, explode: true);
        expect(reconstructed, oneOf);
      });

      test('toForm - explode false', () {
        expect(oneOf.toForm(explode: false, allowEmpty: true), '1');
      });

      test('form roundtrip - explode false', () {
        final form = oneOf.toForm(explode: false, allowEmpty: true);
        final reconstructed = OneOfPrimitive.fromForm(form, explode: false);
        expect(reconstructed, oneOf);
      });

      test('toSimple - explode true', () {
        expect(oneOf.toSimple(explode: true, allowEmpty: true), '1');
      });

      test('simple roundtrip - explode true', () {
        final simple = oneOf.toSimple(explode: true, allowEmpty: true);
        final reconstructed = OneOfPrimitive.fromSimple(simple, explode: true);
        expect(reconstructed, oneOf);
      });

      test('toSimple - explode false', () {
        expect(oneOf.toSimple(explode: false, allowEmpty: true), '1');
      });

      test('simple roundtrip - explode false', () {
        final simple = oneOf.toSimple(explode: false, allowEmpty: true);
        final reconstructed = OneOfPrimitive.fromSimple(simple, explode: false);
        expect(reconstructed, oneOf);
      });

      test('toMatrix - explode false', () {
        expect(
          oneOf.toMatrix('asdf', explode: false, allowEmpty: true),
          ';asdf=1',
        );
      });

      test('toMatrix - explode true', () {
        expect(
          oneOf.toMatrix('asdf', explode: true, allowEmpty: true),
          ';asdf=1',
        );
      });

      test('toLabel - explode true', () {
        expect(oneOf.toLabel(explode: true, allowEmpty: true), '.1');
      });

      test('toLabel - explode false', () {
        expect(oneOf.toLabel(explode: false, allowEmpty: true), '.1');
      });

      test('currentEncodingShape', () {
        expect(oneOf.currentEncodingShape, EncodingShape.simple);
      });
    });
  });

  group('OneOfComplex', () {
    group('class1', () {
      late OneOfComplex oneOf;

      setUp(() {
        oneOf = OneOfComplexClass1(Class1(name: 'Kate'));
      });

      test('toJson', () {
        expect(oneOf.toJson(), {'name': 'Kate'});
      });

      test('json roundtrip', () {
        final json = oneOf.toJson();
        final reconstructed = OneOfComplex.fromJson(json);
        expect(reconstructed, oneOf);
      });

      test('toForm - explode true', () {
        expect(oneOf.toForm(explode: true, allowEmpty: true), 'name=Kate');
      });

      test('form roundtrip - explode true', () {
        final form = oneOf.toForm(explode: true, allowEmpty: true);
        final reconstructed = OneOfComplex.fromForm(form, explode: true);
        expect(reconstructed, oneOf);
      });

      test('toForm - explode false', () {
        expect(oneOf.toForm(explode: false, allowEmpty: true), 'name,Kate');
      });

      test('form roundtrip - explode false', () {
        final form = oneOf.toForm(explode: false, allowEmpty: true);
        final reconstructed = OneOfComplex.fromForm(form, explode: false);
        expect(reconstructed, oneOf);
      });

      test('toSimple - explode true', () {
        expect(oneOf.toSimple(explode: true, allowEmpty: true), 'name=Kate');
      });

      test('simple roundtrip - explode true', () {
        final simple = oneOf.toSimple(explode: true, allowEmpty: true);
        final reconstructed = OneOfComplex.fromSimple(simple, explode: true);
        expect(reconstructed, oneOf);
      });

      test('toSimple - explode false', () {
        expect(oneOf.toSimple(explode: false, allowEmpty: true), 'name,Kate');
      });

      test('simple roundtrip - explode false', () {
        final simple = oneOf.toSimple(explode: false, allowEmpty: true);
        final reconstructed = OneOfComplex.fromSimple(simple, explode: false);
        expect(reconstructed, oneOf);
      });

      test('toMatrix - explode false', () {
        expect(
          oneOf.toMatrix('asdf', explode: false, allowEmpty: true),
          ';asdf=name,Kate',
        );
      });

      test('toMatrix - explode true', () {
        expect(
          oneOf.toMatrix('asdf', explode: true, allowEmpty: true),
          ';name=Kate',
        );
      });

      test('toLabel - explode true', () {
        expect(oneOf.toLabel(explode: true, allowEmpty: true), '.name=Kate');
      });

      test('toLabel - explode false', () {
        expect(oneOf.toLabel(explode: false, allowEmpty: true), '.name,Kate');
      });

      test('currentEncodingShape', () {
        expect(oneOf.currentEncodingShape, EncodingShape.complex);
      });
    });

    group('class2', () {
      late OneOfComplex oneOf;

      setUp(() {
        oneOf = OneOfComplexClass2(Class2(number: 1));
      });

      test('toJson', () {
        expect(oneOf.toJson(), {'number': 1});
      });

      test('json roundtrip', () {
        final json = oneOf.toJson();
        final reconstructed = OneOfComplex.fromJson(json);
        expect(reconstructed, oneOf);
      });

      test('toForm - explode true', () {
        expect(oneOf.toForm(explode: true, allowEmpty: true), 'number=1');
      });

      test('form roundtrip - explode true', () {
        final form = oneOf.toForm(explode: true, allowEmpty: true);
        final reconstructed = OneOfComplex.fromForm(form, explode: true);
        expect(reconstructed, oneOf);
      });

      test('toForm - explode false', () {
        expect(oneOf.toForm(explode: false, allowEmpty: true), 'number,1');
      });

      test('form roundtrip - explode false', () {
        final form = oneOf.toForm(explode: false, allowEmpty: true);
        final reconstructed = OneOfComplex.fromForm(form, explode: false);
        expect(reconstructed, oneOf);
      });

      test('toSimple - explode true', () {
        expect(oneOf.toSimple(explode: true, allowEmpty: true), 'number=1');
      });

      test('simple roundtrip - explode true', () {
        final simple = oneOf.toSimple(explode: true, allowEmpty: true);
        final reconstructed = OneOfComplex.fromSimple(simple, explode: true);
        expect(reconstructed, oneOf);
      });

      test('toSimple - explode false', () {
        expect(oneOf.toSimple(explode: false, allowEmpty: true), 'number,1');
      });

      test('simple roundtrip - explode false', () {
        final simple = oneOf.toSimple(explode: false, allowEmpty: true);
        final reconstructed = OneOfComplex.fromSimple(simple, explode: false);
        expect(reconstructed, oneOf);
      });

      test('toMatrix - explode false', () {
        expect(
          oneOf.toMatrix('asdf', explode: false, allowEmpty: true),
          ';asdf=number,1',
        );
      });

      test('toMatrix - explode true', () {
        expect(
          oneOf.toMatrix('asdf', explode: true, allowEmpty: true),
          ';number=1',
        );
      });

      test('toLabel - explode true', () {
        expect(oneOf.toLabel(explode: true, allowEmpty: true), '.number=1');
      });

      test('toLabel - explode false', () {
        expect(oneOf.toLabel(explode: false, allowEmpty: true), '.number,1');
      });

      test('currentEncodingShape', () {
        expect(oneOf.currentEncodingShape, EncodingShape.complex);
      });
    });
  });

  group('OneOfEnum', () {
    group('enum1', () {
      late OneOfEnum oneOf;

      setUp(() {
        oneOf = OneOfEnumEnum1(Enum1.value1);
      });

      test('toJson', () {
        expect(oneOf.toJson(), 'value1');
      });

      test('json roundtrip', () {
        final json = oneOf.toJson();
        final reconstructed = OneOfEnum.fromJson(json);
        expect(reconstructed, oneOf);
      });

      test('toForm - explode true', () {
        expect(oneOf.toForm(explode: true, allowEmpty: true), 'value1');
      });

      test('form roundtrip - explode true', () {
        final form = oneOf.toForm(explode: true, allowEmpty: true);
        final reconstructed = OneOfEnum.fromForm(form, explode: true);
        expect(reconstructed, oneOf);
      });

      test('toForm - explode false', () {
        expect(oneOf.toForm(explode: false, allowEmpty: true), 'value1');
      });

      test('form roundtrip - explode false', () {
        final form = oneOf.toForm(explode: false, allowEmpty: true);
        final reconstructed = OneOfEnum.fromForm(form, explode: false);
        expect(reconstructed, oneOf);
      });

      test('toSimple - explode true', () {
        expect(oneOf.toSimple(explode: true, allowEmpty: true), 'value1');
      });

      test('simple roundtrip - explode true', () {
        final simple = oneOf.toSimple(explode: true, allowEmpty: true);
        final reconstructed = OneOfEnum.fromSimple(simple, explode: true);
        expect(reconstructed, oneOf);
      });

      test('toSimple - explode false', () {
        expect(oneOf.toSimple(explode: false, allowEmpty: true), 'value1');
      });

      test('simple roundtrip - explode false', () {
        final simple = oneOf.toSimple(explode: false, allowEmpty: true);
        final reconstructed = OneOfEnum.fromSimple(simple, explode: false);
        expect(reconstructed, oneOf);
      });

      test('toMatrix - explode false', () {
        expect(
          oneOf.toMatrix('asdf', explode: false, allowEmpty: true),
          ';asdf=value1',
        );
      });

      test('toMatrix - explode true', () {
        expect(
          oneOf.toMatrix('asdf', explode: true, allowEmpty: true),
          ';asdf=value1',
        );
      });

      test('toLabel - explode true', () {
        expect(oneOf.toLabel(explode: true, allowEmpty: true), '.value1');
      });

      test('toLabel - explode false', () {
        expect(oneOf.toLabel(explode: false, allowEmpty: true), '.value1');
      });

      test('currentEncodingShape', () {
        expect(oneOf.currentEncodingShape, EncodingShape.simple);
      });
    });

    group('enum2', () {
      late OneOfEnum oneOf;

      setUp(() {
        oneOf = OneOfEnumEnum2(Enum2.one);
      });

      test('toJson', () {
        expect(oneOf.toJson(), 1);
      });

      test('json roundtrip', () {
        final json = oneOf.toJson();
        final reconstructed = OneOfEnum.fromJson(json);
        expect(reconstructed, oneOf);
      });

      test('toForm - explode true', () {
        expect(oneOf.toForm(explode: true, allowEmpty: true), '1');
      });

      test('form roundtrip - explode true', () {
        final form = oneOf.toForm(explode: true, allowEmpty: true);
        final reconstructed = OneOfEnum.fromForm(form, explode: true);
        expect(reconstructed, oneOf);
      });

      test('toForm - explode false', () {
        expect(oneOf.toForm(explode: false, allowEmpty: true), '1');
      });

      test('form roundtrip - explode false', () {
        final form = oneOf.toForm(explode: false, allowEmpty: true);
        final reconstructed = OneOfEnum.fromForm(form, explode: false);
        expect(reconstructed, oneOf);
      });

      test('toSimple - explode true', () {
        expect(oneOf.toSimple(explode: true, allowEmpty: true), '1');
      });

      test('simple roundtrip - explode true', () {
        final simple = oneOf.toSimple(explode: true, allowEmpty: true);
        final reconstructed = OneOfEnum.fromSimple(simple, explode: true);
        expect(reconstructed, oneOf);
      });

      test('toSimple - explode false', () {
        expect(oneOf.toSimple(explode: false, allowEmpty: true), '1');
      });

      test('simple roundtrip - explode false', () {
        final simple = oneOf.toSimple(explode: false, allowEmpty: true);
        final reconstructed = OneOfEnum.fromSimple(simple, explode: false);
        expect(reconstructed, oneOf);
      });

      test('toMatrix - explode false', () {
        expect(
          oneOf.toMatrix('asdf', explode: false, allowEmpty: true),
          ';asdf=1',
        );
      });

      test('toMatrix - explode true', () {
        expect(
          oneOf.toMatrix('asdf', explode: true, allowEmpty: true),
          ';asdf=1',
        );
      });

      test('toLabel - explode true', () {
        expect(oneOf.toLabel(explode: true, allowEmpty: true), '.1');
      });

      test('toLabel - explode false', () {
        expect(oneOf.toLabel(explode: false, allowEmpty: true), '.1');
      });

      test('currentEncodingShape', () {
        expect(oneOf.currentEncodingShape, EncodingShape.simple);
      });
    });
  });

  group('OneOfMixed', () {
    group('string', () {
      late OneOfMixed oneOf;

      setUp(() {
        oneOf = OneOfMixedString('my value');
      });

      test('toJson', () {
        expect(oneOf.toJson(), 'my value');
      });

      test('json roundtrip', () {
        final json = oneOf.toJson();
        final reconstructed = OneOfMixed.fromJson(json);
        expect(reconstructed, oneOf);
      });

      test('toForm - explode true', () {
        expect(oneOf.toForm(explode: true, allowEmpty: true), 'my%20value');
      });

      test('form roundtrip - explode true', () {
        final form = oneOf.toForm(explode: true, allowEmpty: true);
        final reconstructed = OneOfMixed.fromForm(form, explode: true);
        expect(reconstructed, oneOf);
      });

      test('toForm - explode false', () {
        expect(oneOf.toForm(explode: false, allowEmpty: true), 'my%20value');
      });

      test('form roundtrip - explode false', () {
        final form = oneOf.toForm(explode: false, allowEmpty: true);
        final reconstructed = OneOfMixed.fromForm(form, explode: false);
        expect(reconstructed, oneOf);
      });

      test('toSimple - explode true', () {
        expect(oneOf.toSimple(explode: true, allowEmpty: true), 'my%20value');
      });

      test('simple roundtrip - explode true', () {
        final simple = oneOf.toSimple(explode: true, allowEmpty: true);
        final reconstructed = OneOfMixed.fromSimple(simple, explode: true);
        expect(reconstructed, oneOf);
      });

      test('toSimple - explode false', () {
        expect(oneOf.toSimple(explode: false, allowEmpty: true), 'my%20value');
      });

      test('simple roundtrip - explode false', () {
        final simple = oneOf.toSimple(explode: false, allowEmpty: true);
        final reconstructed = OneOfMixed.fromSimple(simple, explode: false);
        expect(reconstructed, oneOf);
      });

      test('toMatrix - explode false', () {
        expect(
          oneOf.toMatrix('asdf', explode: false, allowEmpty: true),
          ';asdf=my%20value',
        );
      });

      test('toMatrix - explode true', () {
        expect(
          oneOf.toMatrix('asdf', explode: true, allowEmpty: true),
          ';asdf=my%20value',
        );
      });

      test('toLabel - explode true', () {
        expect(oneOf.toLabel(explode: true, allowEmpty: true), '.my%20value');
      });

      test('toLabel - explode false', () {
        expect(oneOf.toLabel(explode: false, allowEmpty: true), '.my%20value');
      });

      test('currentEncodingShape', () {
        expect(oneOf.currentEncodingShape, EncodingShape.simple);
      });
    });

    group('class1', () {
      late OneOfMixed oneOf;

      setUp(() {
        oneOf = OneOfMixedClass1(Class1(name: 'Kate'));
      });

      test('toJson', () {
        expect(oneOf.toJson(), {'name': 'Kate'});
      });

      test('json roundtrip', () {
        final json = oneOf.toJson();
        final reconstructed = OneOfMixed.fromJson(json);
        expect(reconstructed, oneOf);
      });

      test('toForm - explode true', () {
        expect(oneOf.toForm(explode: true, allowEmpty: true), 'name=Kate');
      });

      test('form roundtrip - explode true', () {
        final form = oneOf.toForm(explode: true, allowEmpty: true);
        final reconstructed = OneOfMixed.fromForm(form, explode: true);
        expect(reconstructed, oneOf);
      });

      test('toForm - explode false', () {
        expect(oneOf.toForm(explode: false, allowEmpty: true), 'name,Kate');
      });

      test('form roundtrip - explode false', () {
        final form = oneOf.toForm(explode: false, allowEmpty: true);
        final reconstructed = OneOfMixed.fromForm(form, explode: false);
        expect(reconstructed, oneOf);
      });

      test('toSimple - explode true', () {
        expect(oneOf.toSimple(explode: true, allowEmpty: true), 'name=Kate');
      });

      test('simple roundtrip - explode true', () {
        final simple = oneOf.toSimple(explode: true, allowEmpty: true);
        final reconstructed = OneOfMixed.fromSimple(simple, explode: true);
        expect(reconstructed, oneOf);
      });

      test('toSimple - explode false', () {
        expect(oneOf.toSimple(explode: false, allowEmpty: true), 'name,Kate');
      });

      test('simple roundtrip - explode false', () {
        final simple = oneOf.toSimple(explode: false, allowEmpty: true);
        final reconstructed = OneOfMixed.fromSimple(simple, explode: false);
        expect(reconstructed, oneOf);
      });

      test('toMatrix - explode false', () {
        expect(
          oneOf.toMatrix('asdf', explode: false, allowEmpty: true),
          ';asdf=name,Kate',
        );
      });

      test('toMatrix - explode true', () {
        expect(
          oneOf.toMatrix('asdf', explode: true, allowEmpty: true),
          ';name=Kate',
        );
      });

      test('toLabel - explode true', () {
        expect(oneOf.toLabel(explode: true, allowEmpty: true), '.name=Kate');
      });

      test('toLabel - explode false', () {
        expect(oneOf.toLabel(explode: false, allowEmpty: true), '.name,Kate');
      });

      test('currentEncodingShape', () {
        expect(oneOf.currentEncodingShape, EncodingShape.complex);
      });
    });

    group('enum1', () {
      late OneOfMixed oneOf;

      setUp(() {
        oneOf = OneOfMixedEnum1(Enum1.value2);
      });

      test('toJson', () {
        expect(oneOf.toJson(), 'value2');
      });

      test('json roundtrip', () {
        final json = oneOf.toJson();
        final reconstructed = OneOfMixed.fromJson(json);
        // Ambiguous: Enum1.value2 serializes to 'value2', which is indistinguishable
        // from a plain string. Without discriminators, any valid variant is acceptable.
        expect(
          reconstructed,
          anyOf([
            isA<OneOfMixedEnum1>().having(
              (e) => e.value,
              'value',
              Enum1.value2,
            ),
            isA<OneOfMixedString>().having((s) => s.value, 'value', 'value2'),
          ]),
        );
      });

      test('toForm - explode true', () {
        expect(oneOf.toForm(explode: true, allowEmpty: true), 'value2');
      });

      test('form roundtrip - explode true', () {
        final form = oneOf.toForm(explode: true, allowEmpty: true);
        final reconstructed = OneOfMixed.fromForm(form, explode: true);
        // Ambiguous: Enum1.value2 encodes to 'value2', which is indistinguishable
        // from a plain string. Without discriminators, any valid variant is acceptable.
        expect(
          reconstructed,
          anyOf([
            isA<OneOfMixedEnum1>().having(
              (e) => e.value,
              'value',
              Enum1.value2,
            ),
            isA<OneOfMixedString>().having((s) => s.value, 'value', 'value2'),
          ]),
        );
      });

      test('toForm - explode false', () {
        expect(oneOf.toForm(explode: false, allowEmpty: true), 'value2');
      });

      test('form roundtrip - explode false', () {
        final form = oneOf.toForm(explode: false, allowEmpty: true);
        final reconstructed = OneOfMixed.fromForm(form, explode: false);
        // Ambiguous: Enum1.value2 encodes to 'value2', which is indistinguishable
        // from a plain string. Without discriminators, any valid variant is acceptable.
        expect(
          reconstructed,
          anyOf([
            isA<OneOfMixedEnum1>().having(
              (e) => e.value,
              'value',
              Enum1.value2,
            ),
            isA<OneOfMixedString>().having((s) => s.value, 'value', 'value2'),
          ]),
        );
      });

      test('toSimple - explode true', () {
        expect(oneOf.toSimple(explode: true, allowEmpty: true), 'value2');
      });

      test('simple roundtrip - explode true', () {
        final simple = oneOf.toSimple(explode: true, allowEmpty: true);
        final reconstructed = OneOfMixed.fromSimple(simple, explode: true);
        // Ambiguous: Enum1.value2 encodes to 'value2', which is indistinguishable
        // from a plain string. Without discriminators, any valid variant is acceptable.
        expect(
          reconstructed,
          anyOf([
            isA<OneOfMixedEnum1>().having(
              (e) => e.value,
              'value',
              Enum1.value2,
            ),
            isA<OneOfMixedString>().having((s) => s.value, 'value', 'value2'),
          ]),
        );
      });

      test('toSimple - explode false', () {
        expect(oneOf.toSimple(explode: true, allowEmpty: true), 'value2');
      });

      test('simple roundtrip - explode false', () {
        final simple = oneOf.toSimple(explode: false, allowEmpty: true);
        final reconstructed = OneOfMixed.fromSimple(simple, explode: false);
        // Ambiguous: Enum1.value2 encodes to 'value2', which is indistinguishable
        // from a plain string. Without discriminators, any valid variant is acceptable.
        expect(
          reconstructed,
          anyOf([
            isA<OneOfMixedEnum1>().having(
              (e) => e.value,
              'value',
              Enum1.value2,
            ),
            isA<OneOfMixedString>().having((s) => s.value, 'value', 'value2'),
          ]),
        );
      });

      test('toMatrix - explode false', () {
        expect(
          oneOf.toMatrix('asdf', explode: false, allowEmpty: true),
          ';asdf=value2',
        );
      });

      test('toMatrix - explode true', () {
        expect(
          oneOf.toMatrix('asdf', explode: true, allowEmpty: true),
          ';asdf=value2',
        );
      });

      test('toLabel - explode true', () {
        expect(oneOf.toLabel(explode: true, allowEmpty: true), '.value2');
      });

      test('toLabel - explode false', () {
        expect(oneOf.toLabel(explode: false, allowEmpty: true), '.value2');
      });

      test('currentEncodingShape', () {
        expect(oneOf.currentEncodingShape, EncodingShape.simple);
      });
    });
  });

  group('NestedOneOfInOneOf', () {
    group('oneOfPrimitive', () {
      group('string', () {
        late NestedOneOfInOneOf oneOf;

        setUp(() {
          oneOf = NestedOneOfInOneOfOneOfPrimitive(
            OneOfPrimitiveString('string'),
          );
        });

        test('toJson', () {
          expect(oneOf.toJson(), 'string');
        });

        test('json roundtrip', () {
          final json = oneOf.toJson();
          final reconstructed = NestedOneOfInOneOf.fromJson(json);
          expect(reconstructed, oneOf);
        });

        test('toForm - explode true', () {
          expect(oneOf.toForm(explode: true, allowEmpty: true), 'string');
        });

        test('form roundtrip - explode true', () {
          final form = oneOf.toForm(explode: true, allowEmpty: true);
          final reconstructed = NestedOneOfInOneOf.fromForm(
            form,
            explode: true,
          );
          expect(reconstructed, oneOf);
        });

        test('toForm - explode false', () {
          expect(oneOf.toForm(explode: false, allowEmpty: true), 'string');
        });

        test('form roundtrip - explode false', () {
          final form = oneOf.toForm(explode: false, allowEmpty: true);
          final reconstructed = NestedOneOfInOneOf.fromForm(
            form,
            explode: false,
          );
          expect(reconstructed, oneOf);
        });

        test('toSimple - explode true', () {
          expect(oneOf.toSimple(explode: true, allowEmpty: true), 'string');
        });

        test('simple roundtrip - explode true', () {
          final simple = oneOf.toSimple(explode: true, allowEmpty: true);
          final reconstructed = NestedOneOfInOneOf.fromSimple(
            simple,
            explode: true,
          );
          expect(reconstructed, oneOf);
        });

        test('toSimple - explode false', () {
          expect(oneOf.toSimple(explode: false, allowEmpty: true), 'string');
        });

        test('simple roundtrip - explode false', () {
          final simple = oneOf.toSimple(explode: false, allowEmpty: true);
          final reconstructed = NestedOneOfInOneOf.fromSimple(
            simple,
            explode: false,
          );
          expect(reconstructed, oneOf);
        });

        test('toMatrix - explode false', () {
          expect(
            oneOf.toMatrix('asdf', explode: false, allowEmpty: true),
            ';asdf=string',
          );
        });

        test('toMatrix - explode true', () {
          expect(
            oneOf.toMatrix('asdf', explode: true, allowEmpty: true),
            ';asdf=string',
          );
        });

        test('toLabel - explode true', () {
          expect(oneOf.toLabel(explode: true, allowEmpty: true), '.string');
        });

        test('toLabel - explode false', () {
          expect(oneOf.toLabel(explode: false, allowEmpty: true), '.string');
        });

        test('currentEncodingShape', () {
          expect(oneOf.currentEncodingShape, EncodingShape.simple);
        });
      });

      group('integer', () {
        late NestedOneOfInOneOf oneOf;

        setUp(() {
          oneOf = NestedOneOfInOneOfOneOfPrimitive(OneOfPrimitiveInt(1));
        });

        test('toJson', () {
          expect(oneOf.toJson(), 1);
        });

        test('json roundtrip', () {
          final json = oneOf.toJson();
          final reconstructed = NestedOneOfInOneOf.fromJson(json);
          expect(reconstructed, oneOf);
        });

        test('toForm - explode true', () {
          expect(oneOf.toForm(explode: true, allowEmpty: true), '1');
        });

        test('form roundtrip - explode true', () {
          final form = oneOf.toForm(explode: true, allowEmpty: true);
          final reconstructed = NestedOneOfInOneOf.fromForm(
            form,
            explode: true,
          );
          expect(reconstructed, oneOf);
        });

        test('toForm - explode false', () {
          expect(oneOf.toForm(explode: false, allowEmpty: true), '1');
        });

        test('form roundtrip - explode false', () {
          final form = oneOf.toForm(explode: false, allowEmpty: true);
          final reconstructed = NestedOneOfInOneOf.fromForm(
            form,
            explode: false,
          );
          expect(reconstructed, oneOf);
        });

        test('toSimple - explode true', () {
          expect(oneOf.toSimple(explode: true, allowEmpty: true), '1');
        });

        test('simple roundtrip - explode true', () {
          final simple = oneOf.toSimple(explode: true, allowEmpty: true);
          final reconstructed = NestedOneOfInOneOf.fromSimple(
            simple,
            explode: true,
          );
          expect(reconstructed, oneOf);
        });

        test('toSimple - explode false', () {
          expect(oneOf.toSimple(explode: false, allowEmpty: true), '1');
        });

        test('simple roundtrip - explode false', () {
          final simple = oneOf.toSimple(explode: false, allowEmpty: true);
          final reconstructed = NestedOneOfInOneOf.fromSimple(
            simple,
            explode: false,
          );
          expect(reconstructed, oneOf);
        });

        test('toMatrix - explode false', () {
          expect(
            oneOf.toMatrix('asdf', explode: false, allowEmpty: true),
            ';asdf=1',
          );
        });

        test('toMatrix - explode true', () {
          expect(
            oneOf.toMatrix('asdf', explode: true, allowEmpty: true),
            ';asdf=1',
          );
        });

        test('toLabel - explode true', () {
          expect(oneOf.toLabel(explode: true, allowEmpty: true), '.1');
        });

        test('toLabel - explode false', () {
          expect(oneOf.toLabel(explode: false, allowEmpty: true), '.1');
        });

        test('currentEncodingShape', () {
          expect(oneOf.currentEncodingShape, EncodingShape.simple);
        });
      });
    });

    group('oneOfComplex', () {
      group('class1', () {
        late NestedOneOfInOneOf oneOf;

        setUp(() {
          oneOf = NestedOneOfInOneOfOneOfComplex(
            OneOfComplexClass1(Class1(name: 'Mark')),
          );
        });

        test('toJson', () {
          expect(oneOf.toJson(), {'name': 'Mark'});
        });

        test('json roundtrip', () {
          final json = oneOf.toJson();
          final reconstructed = NestedOneOfInOneOf.fromJson(json);
          expect(reconstructed, oneOf);
        });

        test('toForm - explode true', () {
          expect(oneOf.toForm(explode: true, allowEmpty: true), 'name=Mark');
        });

        test('form roundtrip - explode true', () {
          final form = oneOf.toForm(explode: true, allowEmpty: true);
          final reconstructed = NestedOneOfInOneOf.fromForm(
            form,
            explode: true,
          );
          expect(reconstructed, oneOf);
        });

        test('toForm - explode false', () {
          expect(oneOf.toForm(explode: false, allowEmpty: true), 'name,Mark');
        });

        test('form roundtrip - explode false', () {
          final form = oneOf.toForm(explode: false, allowEmpty: true);
          final reconstructed = NestedOneOfInOneOf.fromForm(
            form,
            explode: false,
          );
          expect(reconstructed, oneOf);
        });

        test('toSimple - explode true', () {
          expect(oneOf.toSimple(explode: true, allowEmpty: true), 'name=Mark');
        });

        test('simple roundtrip - explode true', () {
          final simple = oneOf.toSimple(explode: true, allowEmpty: true);
          final reconstructed = NestedOneOfInOneOf.fromSimple(
            simple,
            explode: true,
          );
          expect(reconstructed, oneOf);
        });

        test('toSimple - explode false', () {
          expect(oneOf.toSimple(explode: false, allowEmpty: true), 'name,Mark');
        });

        test('simple roundtrip - explode false', () {
          final simple = oneOf.toSimple(explode: false, allowEmpty: true);
          final reconstructed = NestedOneOfInOneOf.fromSimple(
            simple,
            explode: false,
          );
          expect(reconstructed, oneOf);
        });

        test('toMatrix - explode false', () {
          expect(
            oneOf.toMatrix('asdf', explode: false, allowEmpty: true),
            ';asdf=name,Mark',
          );
        });

        test('toMatrix - explode true', () {
          expect(
            oneOf.toMatrix('asdf', explode: true, allowEmpty: true),
            ';name=Mark',
          );
        });

        test('toLabel - explode true', () {
          expect(oneOf.toLabel(explode: true, allowEmpty: true), '.name=Mark');
        });

        test('toLabel - explode false', () {
          expect(oneOf.toLabel(explode: false, allowEmpty: true), '.name,Mark');
        });

        test('currentEncodingShape', () {
          expect(oneOf.currentEncodingShape, EncodingShape.complex);
        });
      });

      group('class2', () {
        late NestedOneOfInOneOf oneOf;

        setUp(() {
          oneOf = NestedOneOfInOneOfOneOfComplex(
            OneOfComplexClass2(Class2(number: 2)),
          );
        });

        test('toJson', () {
          expect(oneOf.toJson(), {'number': 2});
        });

        test('json roundtrip', () {
          final json = oneOf.toJson();
          final reconstructed = NestedOneOfInOneOf.fromJson(json);
          expect(reconstructed, oneOf);
        });

        test('toForm - explode true', () {
          expect(oneOf.toForm(explode: true, allowEmpty: true), 'number=2');
        });

        test('form roundtrip - explode true', () {
          final form = oneOf.toForm(explode: true, allowEmpty: true);
          final reconstructed = NestedOneOfInOneOf.fromForm(
            form,
            explode: true,
          );
          expect(reconstructed, oneOf);
        });

        test('toForm - explode false', () {
          expect(oneOf.toForm(explode: false, allowEmpty: true), 'number,2');
        });

        test('form roundtrip - explode false', () {
          final form = oneOf.toForm(explode: false, allowEmpty: true);
          final reconstructed = NestedOneOfInOneOf.fromForm(
            form,
            explode: false,
          );
          expect(reconstructed, oneOf);
        });

        test('toSimple - explode true', () {
          expect(oneOf.toSimple(explode: true, allowEmpty: true), 'number=2');
        });

        test('simple roundtrip - explode true', () {
          final simple = oneOf.toSimple(explode: true, allowEmpty: true);
          final reconstructed = NestedOneOfInOneOf.fromSimple(
            simple,
            explode: true,
          );
          expect(reconstructed, oneOf);
        });

        test('toSimple - explode false', () {
          expect(oneOf.toSimple(explode: false, allowEmpty: true), 'number,2');
        });

        test('simple roundtrip - explode false', () {
          final simple = oneOf.toSimple(explode: false, allowEmpty: true);
          final reconstructed = NestedOneOfInOneOf.fromSimple(
            simple,
            explode: false,
          );
          expect(reconstructed, oneOf);
        });

        test('toMatrix - explode false', () {
          expect(
            oneOf.toMatrix('asdf', explode: false, allowEmpty: true),
            ';asdf=number,2',
          );
        });

        test('toMatrix - explode true', () {
          expect(
            oneOf.toMatrix('asdf', explode: true, allowEmpty: true),
            ';number=2',
          );
        });

        test('toLabel - explode true', () {
          expect(oneOf.toLabel(explode: true, allowEmpty: true), '.number=2');
        });

        test('toLabel - explode false', () {
          expect(oneOf.toLabel(explode: false, allowEmpty: true), '.number,2');
        });

        test('currentEncodingShape', () {
          expect(oneOf.currentEncodingShape, EncodingShape.complex);
        });
      });
    });
  });

  group('NestedAllOfInOneOf', () {
    group('allOfComplex', () {
      group('allOfComplex', () {
        late NestedAllOfInOneOf oneOf;

        setUp(() {
          oneOf = NestedAllOfInOneOfAllOfComplex(
            AllOfComplex(
              class1: Class1(name: 'Mark'),
              class2: Class2(number: 2),
            ),
          );
        });

        test('toJson', () {
          expect(oneOf.toJson(), {'name': 'Mark', 'number': 2});
        });

        test('json roundtrip', () {
          final json = oneOf.toJson();
          final reconstructed = NestedAllOfInOneOf.fromJson(json);
          expect(reconstructed, oneOf);
        });

        test('toForm - explode true', () {
          expect(
            oneOf.toForm(explode: true, allowEmpty: true),
            'name=Mark&number=2',
          );
        });

        test('form roundtrip - explode true', () {
          final form = oneOf.toForm(explode: true, allowEmpty: true);
          final reconstructed = NestedAllOfInOneOf.fromForm(
            form,
            explode: true,
          );
          expect(reconstructed, oneOf);
        });

        test('toForm - explode false', () {
          expect(
            oneOf.toForm(explode: false, allowEmpty: true),
            'name,Mark,number,2',
          );
        });

        test('form roundtrip - explode false', () {
          final form = oneOf.toForm(explode: false, allowEmpty: true);
          final reconstructed = NestedAllOfInOneOf.fromForm(
            form,
            explode: false,
          );
          expect(reconstructed, oneOf);
        });

        test('toSimple - explode true', () {
          expect(
            oneOf.toSimple(explode: true, allowEmpty: true),
            'name=Mark,number=2',
          );
        });

        test('simple roundtrip - explode true', () {
          final simple = oneOf.toSimple(explode: true, allowEmpty: true);
          final reconstructed = NestedAllOfInOneOf.fromSimple(
            simple,
            explode: true,
          );
          expect(reconstructed, oneOf);
        });

        test('toSimple - explode false', () {
          expect(
            oneOf.toSimple(explode: false, allowEmpty: true),
            'name,Mark,number,2',
          );
        });

        test('simple roundtrip - explode false', () {
          final simple = oneOf.toSimple(explode: false, allowEmpty: true);
          final reconstructed = NestedAllOfInOneOf.fromSimple(
            simple,
            explode: false,
          );
          expect(reconstructed, oneOf);
        });

        test('toMatrix - explode false', () {
          expect(
            oneOf.toMatrix('asdf', explode: false, allowEmpty: true),
            ';asdf=name,Mark,number,2',
          );
        });

        test('toMatrix - explode true', () {
          expect(
            oneOf.toMatrix('asdf', explode: true, allowEmpty: true),
            ';name=Mark;number=2',
          );
        });

        test('toLabel - explode true', () {
          expect(
            oneOf.toLabel(explode: true, allowEmpty: true),
            '.name=Mark.number=2',
          );
        });

        test('toLabel - explode false', () {
          expect(
            oneOf.toLabel(explode: false, allowEmpty: true),
            '.name,Mark,number,2',
          );
        });

        test('currentEncodingShape', () {
          expect(oneOf.currentEncodingShape, EncodingShape.complex);
        });
      });
    });

    group('string', () {
      group('string', () {
        late NestedAllOfInOneOf oneOf;

        setUp(() {
          oneOf = NestedAllOfInOneOfString('Peter');
        });

        test('toJson', () {
          expect(oneOf.toJson(), 'Peter');
        });

        test('json roundtrip', () {
          final json = oneOf.toJson();
          final reconstructed = NestedAllOfInOneOf.fromJson(json);
          expect(reconstructed, oneOf);
        });

        test('toForm - explode true', () {
          expect(oneOf.toForm(explode: true, allowEmpty: true), 'Peter');
        });

        test('form roundtrip - explode true', () {
          final form = oneOf.toForm(explode: true, allowEmpty: true);
          final reconstructed = NestedAllOfInOneOf.fromForm(
            form,
            explode: true,
          );
          expect(reconstructed, oneOf);
        });

        test('toForm - explode false', () {
          expect(oneOf.toForm(explode: false, allowEmpty: true), 'Peter');
        });

        test('form roundtrip - explode false', () {
          final form = oneOf.toForm(explode: false, allowEmpty: true);
          final reconstructed = NestedAllOfInOneOf.fromForm(
            form,
            explode: false,
          );
          expect(reconstructed, oneOf);
        });

        test('toSimple - explode true', () {
          expect(oneOf.toSimple(explode: true, allowEmpty: true), 'Peter');
        });

        test('simple roundtrip - explode true', () {
          final simple = oneOf.toSimple(explode: true, allowEmpty: true);
          final reconstructed = NestedAllOfInOneOf.fromSimple(
            simple,
            explode: true,
          );
          expect(reconstructed, oneOf);
        });

        test('toSimple - explode false', () {
          expect(oneOf.toSimple(explode: false, allowEmpty: true), 'Peter');
        });

        test('simple roundtrip - explode false', () {
          final simple = oneOf.toSimple(explode: false, allowEmpty: true);
          final reconstructed = NestedAllOfInOneOf.fromSimple(
            simple,
            explode: false,
          );
          expect(reconstructed, oneOf);
        });

        test('toMatrix - explode false', () {
          expect(
            oneOf.toMatrix('asdf', explode: false, allowEmpty: true),
            ';asdf=Peter',
          );
        });

        test('toMatrix - explode true', () {
          expect(
            oneOf.toMatrix('asdf', explode: true, allowEmpty: true),
            ';asdf=Peter',
          );
        });

        test('toLabel - explode true', () {
          expect(oneOf.toLabel(explode: true, allowEmpty: true), '.Peter');
        });

        test('toLabel - explode false', () {
          expect(oneOf.toLabel(explode: false, allowEmpty: true), '.Peter');
        });

        test('currentEncodingShape', () {
          expect(oneOf.currentEncodingShape, EncodingShape.simple);
        });
      });
    });
  });

  group('NestedAnyOfInOneOf', () {
    group('AnyOfMixed', () {
      group('integer', () {
        late NestedAnyOfInOneOf oneOf;

        setUp(() {
          oneOf = NestedAnyOfInOneOfAnyOfMixed(AnyOfMixed(int: 1));
        });

        test('toJson', () {
          expect(oneOf.toJson(), 1);
        });

        test('json roundtrip', () {
          final json = oneOf.toJson();
          final reconstructed = NestedAnyOfInOneOf.fromJson(json);
          // Ambiguous: integer 1 matches both int and Enum2.one.
          // Decoder will match all valid variants.
          expect(
            reconstructed,
            NestedAnyOfInOneOfAnyOfMixed(AnyOfMixed(int: 1, enum2: Enum2.one)),
          );
        });

        test('toForm - explode true', () {
          expect(oneOf.toForm(explode: true, allowEmpty: true), '1');
        });

        test('form roundtrip - explode true', () {
          final form = oneOf.toForm(explode: true, allowEmpty: true);
          final reconstructed = NestedAnyOfInOneOf.fromForm(
            form,
            explode: true,
          );
          // Ambiguous: integer 1 matches both int and Enum2.one.
          // Decoder will match all valid variants.
          expect(
            reconstructed,
            NestedAnyOfInOneOfAnyOfMixed(AnyOfMixed(int: 1, enum2: Enum2.one)),
          );
        });

        test('toForm - explode false', () {
          expect(oneOf.toForm(explode: false, allowEmpty: true), '1');
        });

        test('form roundtrip - explode false', () {
          final form = oneOf.toForm(explode: false, allowEmpty: true);
          final reconstructed = NestedAnyOfInOneOf.fromForm(
            form,
            explode: false,
          );
          // Ambiguous: integer 1 matches both int and Enum2.one.
          // Decoder will match all valid variants.
          expect(
            reconstructed,
            NestedAnyOfInOneOfAnyOfMixed(AnyOfMixed(int: 1, enum2: Enum2.one)),
          );
        });

        test('toSimple - explode true', () {
          expect(oneOf.toSimple(explode: true, allowEmpty: true), '1');
        });

        test('simple roundtrip - explode true', () {
          final simple = oneOf.toSimple(explode: true, allowEmpty: true);
          final reconstructed = NestedAnyOfInOneOf.fromSimple(
            simple,
            explode: true,
          );
          // Ambiguous: integer 1 matches both int and Enum2.one.
          // Decoder will match all valid variants.
          expect(
            reconstructed,
            NestedAnyOfInOneOfAnyOfMixed(AnyOfMixed(int: 1, enum2: Enum2.one)),
          );
        });

        test('toSimple - explode false', () {
          expect(oneOf.toSimple(explode: true, allowEmpty: true), '1');
        });

        test('simple roundtrip - explode false', () {
          final simple = oneOf.toSimple(explode: false, allowEmpty: true);
          final reconstructed = NestedAnyOfInOneOf.fromSimple(
            simple,
            explode: false,
          );
          // Ambiguous: integer 1 matches both int and Enum2.one.
          // Decoder will match all valid variants.
          expect(
            reconstructed,
            NestedAnyOfInOneOfAnyOfMixed(AnyOfMixed(int: 1, enum2: Enum2.one)),
          );
        });

        test('toMatrix - explode false', () {
          expect(
            oneOf.toMatrix('asdf', explode: false, allowEmpty: true),
            ';asdf=1',
          );
        });

        test('toMatrix - explode true', () {
          expect(
            oneOf.toMatrix('asdf', explode: true, allowEmpty: true),
            ';asdf=1',
          );
        });

        test('toLabel - explode true', () {
          expect(oneOf.toLabel(explode: true, allowEmpty: true), '.1');
        });

        test('toLabel - explode false', () {
          expect(oneOf.toLabel(explode: false, allowEmpty: true), '.1');
        });

        test('currentEncodingShape', () {
          expect(oneOf.currentEncodingShape, EncodingShape.simple);
        });
      });

      group('class2', () {
        late NestedAnyOfInOneOf oneOf;

        setUp(() {
          oneOf = NestedAnyOfInOneOfAnyOfMixed(
            AnyOfMixed(class2: Class2(number: 2)),
          );
        });

        test('toJson', () {
          expect(oneOf.toJson(), {'number': 2});
        });

        test('json roundtrip', () {
          final json = oneOf.toJson();
          final reconstructed = NestedAnyOfInOneOf.fromJson(json);
          expect(reconstructed, oneOf);
        });

        test('toForm - explode true', () {
          expect(oneOf.toForm(explode: true, allowEmpty: true), 'number=2');
        });

        test('form roundtrip - explode true', () {
          final form = oneOf.toForm(explode: true, allowEmpty: true);
          final reconstructed = NestedAnyOfInOneOf.fromForm(
            form,
            explode: true,
          );
          expect(reconstructed, oneOf);
        });

        test('toForm - explode false', () {
          expect(oneOf.toForm(explode: false, allowEmpty: true), 'number,2');
        });

        test('form roundtrip - explode false', () {
          final form = oneOf.toForm(explode: false, allowEmpty: true);
          final reconstructed = NestedAnyOfInOneOf.fromForm(
            form,
            explode: false,
          );
          expect(reconstructed, oneOf);
        });

        test('toSimple - explode true', () {
          expect(oneOf.toSimple(explode: true, allowEmpty: true), 'number=2');
        });

        test('simple roundtrip - explode true', () {
          final simple = oneOf.toSimple(explode: true, allowEmpty: true);
          final reconstructed = NestedAnyOfInOneOf.fromSimple(
            simple,
            explode: true,
          );
          expect(reconstructed, oneOf);
        });

        test('toSimple - explode false', () {
          expect(oneOf.toSimple(explode: false, allowEmpty: true), 'number,2');
        });

        test('simple roundtrip - explode false', () {
          final simple = oneOf.toSimple(explode: false, allowEmpty: true);
          final reconstructed = NestedAnyOfInOneOf.fromSimple(
            simple,
            explode: false,
          );
          expect(reconstructed, oneOf);
        });

        test('toMatrix - explode false', () {
          expect(
            oneOf.toMatrix('asdf', explode: false, allowEmpty: true),
            ';asdf=number,2',
          );
        });

        test('toMatrix - explode true', () {
          expect(
            oneOf.toMatrix('asdf', explode: true, allowEmpty: true),
            ';number=2',
          );
        });

        test('toLabel - explode true', () {
          expect(oneOf.toLabel(explode: true, allowEmpty: true), '.number=2');
        });

        test('toLabel - explode false', () {
          expect(oneOf.toLabel(explode: false, allowEmpty: true), '.number,2');
        });

        test('currentEncodingShape', () {
          expect(oneOf.currentEncodingShape, EncodingShape.complex);
        });
      });

      group('enum2', () {
        late NestedAnyOfInOneOf oneOf;

        setUp(() {
          oneOf = NestedAnyOfInOneOfAnyOfMixed(AnyOfMixed(enum2: Enum2.two));
        });

        test('toJson', () {
          expect(oneOf.toJson(), 2);
        });

        test('json roundtrip', () {
          final json = oneOf.toJson();
          final reconstructed = NestedAnyOfInOneOf.fromJson(json);
          // Ambiguous: integer 2 matches both int and Enum2.two.
          // Decoder will match all valid variants.
          expect(
            reconstructed,
            NestedAnyOfInOneOfAnyOfMixed(AnyOfMixed(int: 2, enum2: Enum2.two)),
          );
        });

        test('toForm - explode true', () {
          expect(oneOf.toForm(explode: true, allowEmpty: true), '2');
        });

        test('form roundtrip - explode true', () {
          final form = oneOf.toForm(explode: true, allowEmpty: true);
          final reconstructed = NestedAnyOfInOneOf.fromForm(
            form,
            explode: true,
          );
          // Ambiguous: integer 2 matches both int and Enum2.two.
          // Decoder will match all valid variants.
          expect(
            reconstructed,
            NestedAnyOfInOneOfAnyOfMixed(AnyOfMixed(int: 2, enum2: Enum2.two)),
          );
        });

        test('toForm - explode false', () {
          expect(oneOf.toForm(explode: false, allowEmpty: true), '2');
        });

        test('form roundtrip - explode false', () {
          final form = oneOf.toForm(explode: false, allowEmpty: true);
          final reconstructed = NestedAnyOfInOneOf.fromForm(
            form,
            explode: false,
          );
          // Ambiguous: integer 2 matches both int and Enum2.two.
          // Decoder will match all valid variants.
          expect(
            reconstructed,
            NestedAnyOfInOneOfAnyOfMixed(AnyOfMixed(int: 2, enum2: Enum2.two)),
          );
        });

        test('toSimple - explode true', () {
          expect(oneOf.toSimple(explode: true, allowEmpty: true), '2');
        });

        test('simple roundtrip - explode true', () {
          final simple = oneOf.toSimple(explode: true, allowEmpty: true);
          final reconstructed = NestedAnyOfInOneOf.fromSimple(
            simple,
            explode: true,
          );
          // Ambiguous: integer 2 matches both int and Enum2.two.
          // Decoder will match all valid variants.
          expect(
            reconstructed,
            NestedAnyOfInOneOfAnyOfMixed(AnyOfMixed(int: 2, enum2: Enum2.two)),
          );
        });

        test('toSimple - explode false', () {
          expect(oneOf.toSimple(explode: false, allowEmpty: true), '2');
        });

        test('simple roundtrip - explode false', () {
          final simple = oneOf.toSimple(explode: false, allowEmpty: true);
          final reconstructed = NestedAnyOfInOneOf.fromSimple(
            simple,
            explode: false,
          );
          // Ambiguous: integer 2 matches both int and Enum2.two.
          // Decoder will match all valid variants.
          expect(
            reconstructed,
            NestedAnyOfInOneOfAnyOfMixed(AnyOfMixed(int: 2, enum2: Enum2.two)),
          );
        });

        test('toMatrix - explode false', () {
          expect(
            oneOf.toMatrix('asdf', explode: false, allowEmpty: true),
            ';asdf=2',
          );
        });

        test('toMatrix - explode true', () {
          expect(
            oneOf.toMatrix('asdf', explode: true, allowEmpty: true),
            ';asdf=2',
          );
        });

        test('toLabel - explode true', () {
          expect(oneOf.toLabel(explode: true, allowEmpty: true), '.2');
        });

        test('toLabel - explode false', () {
          expect(oneOf.toLabel(explode: false, allowEmpty: true), '.2');
        });

        test('currentEncodingShape', () {
          expect(oneOf.currentEncodingShape, EncodingShape.simple);
        });
      });

      group('multiple values', () {
        late NestedAnyOfInOneOf oneOf;

        setUp(() {
          oneOf = NestedAnyOfInOneOfAnyOfMixed(
            AnyOfMixed(int: 1, class2: Class2(number: 2), enum2: Enum2.two),
          );
        });

        test('toJson throws EncodingException', () {
          expect(oneOf.toJson, throwsA(isA<EncodingException>()));
        });

        test('toForm throws EncodingException', () {
          expect(
            () => oneOf.toForm(explode: true, allowEmpty: true),
            throwsA(isA<EncodingException>()),
          );
        });

        test('toSimple throws EncodingException', () {
          expect(
            () => oneOf.toSimple(explode: true, allowEmpty: true),
            throwsA(isA<EncodingException>()),
          );
        });

        test('toMatrix throws EncodingException', () {
          expect(
            () => oneOf.toMatrix('asdf', explode: false, allowEmpty: true),
            throwsA(isA<EncodingException>()),
          );
        });

        test('toLabel - explode true throws EncodingException', () {
          expect(
            () => oneOf.toLabel(explode: true, allowEmpty: true),
            throwsA(isA<EncodingException>()),
          );
        });

        test('toLabel - explode false throws EncodingException', () {
          expect(
            () => oneOf.toLabel(explode: false, allowEmpty: true),
            throwsA(isA<EncodingException>()),
          );
        });

        test('currentEncodingShape', () {
          expect(oneOf.currentEncodingShape, EncodingShape.mixed);
        });
      });
    });

    group('boolean', () {
      group('boolean', () {
        late NestedAnyOfInOneOf oneOf;

        setUp(() {
          oneOf = NestedAnyOfInOneOfBool(false);
        });

        test('toJson', () {
          expect(oneOf.toJson(), false);
        });

        test('toForm - explode true', () {
          expect(oneOf.toForm(explode: true, allowEmpty: true), 'false');
        });

        test('toForm - explode false', () {
          expect(oneOf.toForm(explode: false, allowEmpty: true), 'false');
        });

        test('toSimple - explode true', () {
          expect(oneOf.toSimple(explode: true, allowEmpty: true), 'false');
        });

        test('toSimple - explode false', () {
          expect(oneOf.toSimple(explode: false, allowEmpty: true), 'false');
        });

        test('toMatrix - explode false', () {
          expect(
            oneOf.toMatrix('asdf', explode: false, allowEmpty: true),
            ';asdf=false',
          );
        });

        test('toMatrix - explode true', () {
          expect(
            oneOf.toMatrix('asdf', explode: true, allowEmpty: true),
            ';asdf=false',
          );
        });

        test('toLabel - explode true', () {
          expect(oneOf.toLabel(explode: true, allowEmpty: true), '.false');
        });

        test('toLabel - explode false', () {
          expect(oneOf.toLabel(explode: false, allowEmpty: true), '.false');
        });

        test('currentEncodingShape', () {
          expect(oneOf.currentEncodingShape, EncodingShape.simple);
        });
      });
    });
  });

  group('DeepNestedOneOf', () {
    group('NestedOneOfInOneOf', () {
      group('OneOfPrimitive', () {
        group('string', () {
          late DeepNestedOneOf oneOf;

          setUp(() {
            oneOf = DeepNestedOneOfNestedOneOfInOneOf(
              NestedOneOfInOneOfOneOfPrimitive(OneOfPrimitiveString('string')),
            );
          });

          test('toJson', () {
            expect(oneOf.toJson(), 'string');
          });

          test('json roundtrip', () {
            final json = oneOf.toJson();
            final reconstructed = DeepNestedOneOf.fromJson(json);
            expect(reconstructed, oneOf);
          });

          test('toForm - explode true', () {
            expect(oneOf.toForm(explode: true, allowEmpty: true), 'string');
          });

          test('form roundtrip - explode true', () {
            final form = oneOf.toForm(explode: true, allowEmpty: true);
            final reconstructed = DeepNestedOneOf.fromForm(form, explode: true);
            expect(reconstructed, oneOf);
          });

          test('toForm - explode false', () {
            expect(oneOf.toForm(explode: false, allowEmpty: true), 'string');
          });

          test('form roundtrip - explode false', () {
            final form = oneOf.toForm(explode: false, allowEmpty: true);
            final reconstructed = DeepNestedOneOf.fromForm(
              form,
              explode: false,
            );
            expect(reconstructed, oneOf);
          });

          test('toSimple - explode true', () {
            expect(oneOf.toSimple(explode: true, allowEmpty: true), 'string');
          });

          test('simple roundtrip - explode true', () {
            final simple = oneOf.toSimple(explode: true, allowEmpty: true);
            final reconstructed = DeepNestedOneOf.fromSimple(
              simple,
              explode: true,
            );
            expect(reconstructed, oneOf);
          });

          test('toSimple - explode false', () {
            expect(oneOf.toSimple(explode: false, allowEmpty: true), 'string');
          });

          test('simple roundtrip - explode false', () {
            final simple = oneOf.toSimple(explode: false, allowEmpty: true);
            final reconstructed = DeepNestedOneOf.fromSimple(
              simple,
              explode: false,
            );
            expect(reconstructed, oneOf);
          });

          test('toMatrix - explode false', () {
            expect(
              oneOf.toMatrix('asdf', explode: false, allowEmpty: true),
              ';asdf=string',
            );
          });

          test('toMatrix - explode true', () {
            expect(
              oneOf.toMatrix('asdf', explode: true, allowEmpty: true),
              ';asdf=string',
            );
          });

          test('toLabel - explode true', () {
            expect(oneOf.toLabel(explode: true, allowEmpty: true), '.string');
          });

          test('toLabel - explode false', () {
            expect(oneOf.toLabel(explode: false, allowEmpty: true), '.string');
          });

          test('currentEncodingShape', () {
            expect(oneOf.currentEncodingShape, EncodingShape.simple);
          });
        });

        group('integer', () {
          late DeepNestedOneOf oneOf;

          setUp(() {
            oneOf = DeepNestedOneOfNestedOneOfInOneOf(
              NestedOneOfInOneOfOneOfPrimitive(OneOfPrimitiveInt(1)),
            );
          });

          test('toJson', () {
            expect(oneOf.toJson(), 1);
          });

          test('json roundtrip', () {
            final json = oneOf.toJson();
            final reconstructed = DeepNestedOneOf.fromJson(json);
            expect(reconstructed, oneOf);
          });

          test('toForm - explode true', () {
            expect(oneOf.toForm(explode: true, allowEmpty: true), '1');
          });

          test('form roundtrip - explode true', () {
            final form = oneOf.toForm(explode: true, allowEmpty: true);
            final reconstructed = DeepNestedOneOf.fromForm(form, explode: true);
            expect(reconstructed, oneOf);
          });

          test('toForm - explode false', () {
            expect(oneOf.toForm(explode: false, allowEmpty: true), '1');
          });

          test('form roundtrip - explode false', () {
            final form = oneOf.toForm(explode: false, allowEmpty: true);
            final reconstructed = DeepNestedOneOf.fromForm(
              form,
              explode: false,
            );
            expect(reconstructed, oneOf);
          });

          test('toSimple - explode true', () {
            expect(oneOf.toSimple(explode: true, allowEmpty: true), '1');
          });

          test('simple roundtrip - explode true', () {
            final simple = oneOf.toSimple(explode: true, allowEmpty: true);
            final reconstructed = DeepNestedOneOf.fromSimple(
              simple,
              explode: true,
            );
            expect(reconstructed, oneOf);
          });

          test('toSimple - explode false', () {
            expect(oneOf.toSimple(explode: false, allowEmpty: true), '1');
          });

          test('simple roundtrip - explode false', () {
            final simple = oneOf.toSimple(explode: false, allowEmpty: true);
            final reconstructed = DeepNestedOneOf.fromSimple(
              simple,
              explode: false,
            );
            expect(reconstructed, oneOf);
          });

          test('toMatrix - explode false', () {
            expect(
              oneOf.toMatrix('asdf', explode: false, allowEmpty: true),
              ';asdf=1',
            );
          });

          test('toMatrix - explode true', () {
            expect(
              oneOf.toMatrix('asdf', explode: true, allowEmpty: true),
              ';asdf=1',
            );
          });

          test('toLabel - explode true', () {
            expect(oneOf.toLabel(explode: true, allowEmpty: true), '.1');
          });

          test('toLabel - explode false', () {
            expect(oneOf.toLabel(explode: false, allowEmpty: true), '.1');
          });

          test('currentEncodingShape', () {
            expect(oneOf.currentEncodingShape, EncodingShape.simple);
          });
        });
      });

      group('OneOfComplex', () {
        group('class1', () {
          late DeepNestedOneOf oneOf;

          setUp(() {
            oneOf = DeepNestedOneOfNestedOneOfInOneOf(
              NestedOneOfInOneOfOneOfComplex(
                OneOfComplexClass1(Class1(name: 'Mark')),
              ),
            );
          });

          test('toJson', () {
            expect(oneOf.toJson(), {'name': 'Mark'});
          });

          test('json roundtrip', () {
            final json = oneOf.toJson();
            final reconstructed = DeepNestedOneOf.fromJson(json);
            // Ambiguous oneOf: Class1 appears both as a direct variant and nested in NestedOneOfInOneOf.
            // The decoder tries variants in order and returns the first match (DeepNestedOneOfClass1).
            expect(
              reconstructed,
              anyOf(oneOf, DeepNestedOneOfClass1(Class1(name: 'Mark'))),
            );
          });

          test('toForm - explode true', () {
            expect(oneOf.toForm(explode: true, allowEmpty: true), 'name=Mark');
          });

          test('form roundtrip - explode true', () {
            final form = oneOf.toForm(explode: true, allowEmpty: true);
            final reconstructed = DeepNestedOneOf.fromForm(form, explode: true);
            // Ambiguous oneOf: Class1 appears both as a direct variant and nested in NestedOneOfInOneOf.
            // The decoder tries variants in order and returns the first match (DeepNestedOneOfClass1).
            expect(
              reconstructed,
              anyOf(oneOf, DeepNestedOneOfClass1(Class1(name: 'Mark'))),
            );
          });

          test('toForm - explode false', () {
            expect(oneOf.toForm(explode: false, allowEmpty: true), 'name,Mark');
          });

          test('form roundtrip - explode false', () {
            final form = oneOf.toForm(explode: false, allowEmpty: true);
            final reconstructed = DeepNestedOneOf.fromForm(
              form,
              explode: false,
            );
            // Ambiguous oneOf: Class1 appears both as a direct variant and nested in NestedOneOfInOneOf.
            // The decoder tries variants in order and returns the first match (DeepNestedOneOfClass1).
            expect(
              reconstructed,
              anyOf(oneOf, DeepNestedOneOfClass1(Class1(name: 'Mark'))),
            );
          });

          test('toSimple - explode true', () {
            expect(
              oneOf.toSimple(explode: true, allowEmpty: true),
              'name=Mark',
            );
          });

          test('simple roundtrip - explode true', () {
            final simple = oneOf.toSimple(explode: true, allowEmpty: true);
            final reconstructed = DeepNestedOneOf.fromSimple(
              simple,
              explode: true,
            );
            // Ambiguous oneOf: Class1 appears both as a direct variant and nested in NestedOneOfInOneOf.
            // The decoder tries variants in order and returns the first match (DeepNestedOneOfClass1).
            expect(
              reconstructed,
              anyOf(oneOf, DeepNestedOneOfClass1(Class1(name: 'Mark'))),
            );
          });

          test('toSimple - explode false', () {
            expect(
              oneOf.toSimple(explode: false, allowEmpty: true),
              'name,Mark',
            );
          });

          test('simple roundtrip - explode false', () {
            final simple = oneOf.toSimple(explode: false, allowEmpty: true);
            final reconstructed = DeepNestedOneOf.fromSimple(
              simple,
              explode: false,
            );
            // Ambiguous oneOf: Class1 appears both as a direct variant and nested in NestedOneOfInOneOf.
            // The decoder tries variants in order and returns the first match (DeepNestedOneOfClass1).
            expect(
              reconstructed,
              anyOf(oneOf, DeepNestedOneOfClass1(Class1(name: 'Mark'))),
            );
          });

          test('toMatrix - explode false', () {
            expect(
              oneOf.toMatrix('asdf', explode: false, allowEmpty: true),
              ';asdf=name,Mark',
            );
          });

          test('toMatrix - explode true', () {
            expect(
              oneOf.toMatrix('asdf', explode: true, allowEmpty: true),
              ';name=Mark',
            );
          });

          test('toLabel - explode true', () {
            expect(
              oneOf.toLabel(explode: true, allowEmpty: true),
              '.name=Mark',
            );
          });

          test('toLabel - explode false', () {
            expect(
              oneOf.toLabel(explode: false, allowEmpty: true),
              '.name,Mark',
            );
          });

          test('currentEncodingShape', () {
            expect(oneOf.currentEncodingShape, EncodingShape.complex);
          });
        });

        group('class2', () {
          late DeepNestedOneOf oneOf;

          setUp(() {
            oneOf = DeepNestedOneOfNestedOneOfInOneOf(
              NestedOneOfInOneOfOneOfComplex(
                OneOfComplexClass2(Class2(number: 2)),
              ),
            );
          });

          test('toJson', () {
            expect(oneOf.toJson(), {'number': 2});
          });

          test('json roundtrip', () {
            final json = oneOf.toJson();
            final reconstructed = DeepNestedOneOf.fromJson(json);
            expect(reconstructed, oneOf);
          });

          test('toForm - explode true', () {
            expect(oneOf.toForm(explode: true, allowEmpty: true), 'number=2');
          });

          test('form roundtrip - explode true', () {
            final form = oneOf.toForm(explode: true, allowEmpty: true);
            final reconstructed = DeepNestedOneOf.fromForm(form, explode: true);
            expect(reconstructed, oneOf);
          });

          test('toForm - explode false', () {
            expect(oneOf.toForm(explode: false, allowEmpty: true), 'number,2');
          });

          test('form roundtrip - explode false', () {
            final form = oneOf.toForm(explode: false, allowEmpty: true);
            final reconstructed = DeepNestedOneOf.fromForm(
              form,
              explode: false,
            );
            expect(reconstructed, oneOf);
          });

          test('toSimple - explode true', () {
            expect(oneOf.toSimple(explode: true, allowEmpty: true), 'number=2');
          });

          test('simple roundtrip - explode true', () {
            final simple = oneOf.toSimple(explode: true, allowEmpty: true);
            final reconstructed = DeepNestedOneOf.fromSimple(
              simple,
              explode: true,
            );
            expect(reconstructed, oneOf);
          });

          test('toSimple - explode false', () {
            expect(
              oneOf.toSimple(explode: false, allowEmpty: true),
              'number,2',
            );
          });

          test('simple roundtrip - explode false', () {
            final simple = oneOf.toSimple(explode: false, allowEmpty: true);
            final reconstructed = DeepNestedOneOf.fromSimple(
              simple,
              explode: false,
            );
            expect(reconstructed, oneOf);
          });

          test('toMatrix - explode false', () {
            expect(
              oneOf.toMatrix('asdf', explode: false, allowEmpty: true),
              ';asdf=number,2',
            );
          });

          test('toMatrix - explode true', () {
            expect(
              oneOf.toMatrix('asdf', explode: true, allowEmpty: true),
              ';number=2',
            );
          });

          test('toLabel - explode true', () {
            expect(oneOf.toLabel(explode: true, allowEmpty: true), '.number=2');
          });

          test('toLabel - explode false', () {
            expect(
              oneOf.toLabel(explode: false, allowEmpty: true),
              '.number,2',
            );
          });

          test('currentEncodingShape', () {
            expect(oneOf.currentEncodingShape, EncodingShape.complex);
          });
        });
      });
    });

    group('Class1', () {
      group('class1', () {
        late DeepNestedOneOf oneOf;

        setUp(() {
          oneOf = DeepNestedOneOfClass1(Class1(name: 'Mark'));
        });

        test('toJson', () {
          expect(oneOf.toJson(), {'name': 'Mark'});
        });

        test('json roundtrip', () {
          final json = oneOf.toJson();
          final reconstructed = DeepNestedOneOf.fromJson(json);
          expect(reconstructed, oneOf);
        });

        test('toForm - explode true', () {
          expect(oneOf.toForm(explode: true, allowEmpty: true), 'name=Mark');
        });

        test('form roundtrip - explode true', () {
          final form = oneOf.toForm(explode: true, allowEmpty: true);
          final reconstructed = DeepNestedOneOf.fromForm(form, explode: true);
          expect(reconstructed, oneOf);
        });

        test('toForm - explode false', () {
          expect(oneOf.toForm(explode: false, allowEmpty: true), 'name,Mark');
        });

        test('form roundtrip - explode false', () {
          final form = oneOf.toForm(explode: false, allowEmpty: true);
          final reconstructed = DeepNestedOneOf.fromForm(form, explode: false);
          expect(reconstructed, oneOf);
        });

        test('toSimple - explode true', () {
          expect(oneOf.toSimple(explode: true, allowEmpty: true), 'name=Mark');
        });

        test('simple roundtrip - explode true', () {
          final simple = oneOf.toSimple(explode: true, allowEmpty: true);
          final reconstructed = DeepNestedOneOf.fromSimple(
            simple,
            explode: true,
          );
          expect(reconstructed, oneOf);
        });

        test('toSimple - explode false', () {
          expect(oneOf.toSimple(explode: false, allowEmpty: true), 'name,Mark');
        });

        test('simple roundtrip - explode false', () {
          final simple = oneOf.toSimple(explode: false, allowEmpty: true);
          final reconstructed = DeepNestedOneOf.fromSimple(
            simple,
            explode: false,
          );
          expect(reconstructed, oneOf);
        });

        test('toMatrix - explode false', () {
          expect(
            oneOf.toMatrix('asdf', explode: false, allowEmpty: true),
            ';asdf=name,Mark',
          );
        });

        test('toMatrix - explode true', () {
          expect(
            oneOf.toMatrix('asdf', explode: true, allowEmpty: true),
            ';name=Mark',
          );
        });

        test('toLabel - explode true', () {
          expect(oneOf.toLabel(explode: true, allowEmpty: true), '.name=Mark');
        });

        test('toLabel - explode false', () {
          expect(oneOf.toLabel(explode: false, allowEmpty: true), '.name,Mark');
        });

        test('currentEncodingShape', () {
          expect(oneOf.currentEncodingShape, EncodingShape.complex);
        });
      });
    });
  });

  group('TowLevelOneOf', () {
    group('oneOf', () {
      group('string', () {
        late TwoLevelOneOf oneOf;

        setUp(() {
          oneOf = TwoLevelOneOfOneOf(TwoLevelOneOfModelString('Mark'));
        });

        test('toJson', () {
          expect(oneOf.toJson(), 'Mark');
        });

        test('json roundtrip', () {
          final json = oneOf.toJson();
          final reconstructed = TwoLevelOneOf.fromJson(json);
          expect(reconstructed, oneOf);
        });

        test('toForm - explode true', () {
          expect(oneOf.toForm(explode: true, allowEmpty: true), 'Mark');
        });

        test('form roundtrip - explode true', () {
          final form = oneOf.toForm(explode: true, allowEmpty: true);
          final reconstructed = TwoLevelOneOf.fromForm(form, explode: true);
          expect(reconstructed, oneOf);
        });

        test('toForm - explode false', () {
          expect(oneOf.toForm(explode: false, allowEmpty: true), 'Mark');
        });

        test('form roundtrip - explode false', () {
          final form = oneOf.toForm(explode: false, allowEmpty: true);
          final reconstructed = TwoLevelOneOf.fromForm(form, explode: false);
          expect(reconstructed, oneOf);
        });

        test('toSimple - explode true', () {
          expect(oneOf.toSimple(explode: true, allowEmpty: true), 'Mark');
        });

        test('simple roundtrip - explode true', () {
          final simple = oneOf.toSimple(explode: true, allowEmpty: true);
          final reconstructed = TwoLevelOneOf.fromSimple(simple, explode: true);
          expect(reconstructed, oneOf);
        });

        test('toSimple - explode false', () {
          expect(oneOf.toSimple(explode: false, allowEmpty: true), 'Mark');
        });

        test('simple roundtrip - explode false', () {
          final simple = oneOf.toSimple(explode: false, allowEmpty: true);
          final reconstructed = TwoLevelOneOf.fromSimple(
            simple,
            explode: false,
          );
          expect(reconstructed, oneOf);
        });

        test('toMatrix - explode false', () {
          expect(
            oneOf.toMatrix('asdf', explode: false, allowEmpty: true),
            ';asdf=Mark',
          );
        });

        test('toMatrix - explode true', () {
          expect(
            oneOf.toMatrix('asdf', explode: true, allowEmpty: true),
            ';asdf=Mark',
          );
        });

        test('toLabel - explode true', () {
          expect(oneOf.toLabel(explode: true, allowEmpty: true), '.Mark');
        });

        test('toLabel - explode false', () {
          expect(oneOf.toLabel(explode: false, allowEmpty: true), '.Mark');
        });

        test('currentEncodingShape', () {
          expect(oneOf.currentEncodingShape, EncodingShape.simple);
        });
      });

      group('integer', () {
        late TwoLevelOneOf oneOf;

        setUp(() {
          oneOf = TwoLevelOneOfOneOf(TwoLevelOneOfModelInt(1));
        });

        test('toJson', () {
          expect(oneOf.toJson(), 1);
        });

        test('json roundtrip', () {
          final json = oneOf.toJson();
          final reconstructed = TwoLevelOneOf.fromJson(json);
          expect(reconstructed, oneOf);
        });

        test('toForm - explode true', () {
          expect(oneOf.toForm(explode: true, allowEmpty: true), '1');
        });

        test('form roundtrip - explode true', () {
          final form = oneOf.toForm(explode: true, allowEmpty: true);
          final reconstructed = TwoLevelOneOf.fromForm(form, explode: true);
          expect(reconstructed, oneOf);
        });

        test('toForm - explode false', () {
          expect(oneOf.toForm(explode: false, allowEmpty: true), '1');
        });

        test('form roundtrip - explode false', () {
          final form = oneOf.toForm(explode: false, allowEmpty: true);
          final reconstructed = TwoLevelOneOf.fromForm(form, explode: false);
          expect(reconstructed, oneOf);
        });

        test('toSimple - explode true', () {
          expect(oneOf.toSimple(explode: true, allowEmpty: true), '1');
        });

        test('simple roundtrip - explode true', () {
          final simple = oneOf.toSimple(explode: true, allowEmpty: true);
          final reconstructed = TwoLevelOneOf.fromSimple(simple, explode: true);
          expect(reconstructed, oneOf);
        });

        test('toSimple - explode false', () {
          expect(oneOf.toSimple(explode: false, allowEmpty: true), '1');
        });

        test('simple roundtrip - explode false', () {
          final simple = oneOf.toSimple(explode: false, allowEmpty: true);
          final reconstructed = TwoLevelOneOf.fromSimple(
            simple,
            explode: false,
          );
          expect(reconstructed, oneOf);
        });

        test('toMatrix - explode false', () {
          expect(
            oneOf.toMatrix('asdf', explode: false, allowEmpty: true),
            ';asdf=1',
          );
        });

        test('toMatrix - explode true', () {
          expect(
            oneOf.toMatrix('asdf', explode: true, allowEmpty: true),
            ';asdf=1',
          );
        });

        test('toLabel - explode true', () {
          expect(oneOf.toLabel(explode: true, allowEmpty: true), '.1');
        });

        test('toLabel - explode false', () {
          expect(oneOf.toLabel(explode: false, allowEmpty: true), '.1');
        });

        test('currentEncodingShape', () {
          expect(oneOf.currentEncodingShape, EncodingShape.simple);
        });
      });
    });

    group('boolean', () {
      group('boolean', () {
        late TwoLevelOneOf oneOf;

        setUp(() {
          oneOf = TwoLevelOneOfBool(false);
        });

        test('toJson', () {
          expect(oneOf.toJson(), false);
        });

        test('json roundtrip', () {
          final json = oneOf.toJson();
          final reconstructed = TwoLevelOneOf.fromJson(json);
          expect(reconstructed, oneOf);
        });

        test('toForm - explode true', () {
          expect(oneOf.toForm(explode: true, allowEmpty: true), 'false');
        });

        test('form roundtrip - explode true', () {
          final form = oneOf.toForm(explode: true, allowEmpty: true);
          final reconstructed = TwoLevelOneOf.fromForm(form, explode: true);
          expect(reconstructed, oneOf);
        });

        test('toForm - explode false', () {
          expect(oneOf.toForm(explode: false, allowEmpty: true), 'false');
        });

        test('form roundtrip - explode false', () {
          final form = oneOf.toForm(explode: false, allowEmpty: true);
          final reconstructed = TwoLevelOneOf.fromForm(form, explode: false);
          expect(reconstructed, oneOf);
        });

        test('toSimple - explode true', () {
          expect(oneOf.toSimple(explode: true, allowEmpty: true), 'false');
        });

        test('simple roundtrip - explode true', () {
          final simple = oneOf.toSimple(explode: true, allowEmpty: true);
          final reconstructed = TwoLevelOneOf.fromSimple(simple, explode: true);
          expect(reconstructed, oneOf);
        });

        test('toSimple - explode false', () {
          expect(oneOf.toSimple(explode: false, allowEmpty: true), 'false');
        });

        test('simple roundtrip - explode false', () {
          final simple = oneOf.toSimple(explode: false, allowEmpty: true);
          final reconstructed = TwoLevelOneOf.fromSimple(
            simple,
            explode: false,
          );
          expect(reconstructed, oneOf);
        });

        test('toMatrix - explode false', () {
          expect(
            oneOf.toMatrix('asdf', explode: false, allowEmpty: true),
            ';asdf=false',
          );
        });

        test('toMatrix - explode true', () {
          expect(
            oneOf.toMatrix('asdf', explode: true, allowEmpty: true),
            ';asdf=false',
          );
        });

        test('toLabel - explode true', () {
          expect(oneOf.toLabel(explode: true, allowEmpty: true), '.false');
        });

        test('toLabel - explode false', () {
          expect(oneOf.toLabel(explode: false, allowEmpty: true), '.false');
        });

        test('currentEncodingShape', () {
          expect(oneOf.currentEncodingShape, EncodingShape.simple);
        });
      });
    });
  });

  group('TwoLevelMixedOneOfAllOf', () {
    group('allOf', () {
      group('allOf', () {
        late TwoLevelMixedOneOfAllOf oneOf;

        setUp(() {
          oneOf = TwoLevelMixedOneOfAllOfAllOf(
            TwoLevelMixedOneOfAllOfAllOfModel(
              class1: Class1(name: 'Mark'),
              twoLevelMixedOneOfAllOfAllOfModel2:
                  TwoLevelMixedOneOfAllOfAllOfModel2(timestamp: 400),
            ),
          );
        });

        test('toJson', () {
          expect(oneOf.toJson(), {'name': 'Mark', 'timestamp': 400});
        });

        test('json roundtrip', () {
          final json = oneOf.toJson();
          final reconstructed = TwoLevelMixedOneOfAllOf.fromJson(json);
          expect(reconstructed, oneOf);
        });

        test('toForm - explode true', () {
          expect(
            oneOf.toForm(explode: true, allowEmpty: true),
            'name=Mark&timestamp=400',
          );
        });

        test('form roundtrip - explode true', () {
          final form = oneOf.toForm(explode: true, allowEmpty: true);
          final reconstructed = TwoLevelMixedOneOfAllOf.fromForm(
            form,
            explode: true,
          );
          // Ambiguous oneOf: AllOf variant encodes to string form that matches the string variant.
          // The decoder tries string first and succeeds, returning TwoLevelMixedOneOfAllOfString.
          expect(
            reconstructed,
            anyOf(
              oneOf,
              TwoLevelMixedOneOfAllOfString('name=Mark&timestamp=400'),
            ),
          );
        });

        test('toForm - explode false', () {
          expect(
            oneOf.toForm(explode: false, allowEmpty: true),
            'name,Mark,timestamp,400',
          );
        });

        test('form roundtrip - explode false', () {
          final form = oneOf.toForm(explode: false, allowEmpty: true);
          final reconstructed = TwoLevelMixedOneOfAllOf.fromForm(
            form,
            explode: false,
          );
          // Ambiguous oneOf: AllOf variant encodes to string form that matches the string variant.
          // The decoder tries string first and succeeds, returning TwoLevelMixedOneOfAllOfString.
          expect(
            reconstructed,
            anyOf(
              oneOf,
              TwoLevelMixedOneOfAllOfString('name,Mark,timestamp,400'),
            ),
          );
        });

        test('toSimple - explode true', () {
          expect(
            oneOf.toSimple(explode: true, allowEmpty: true),
            'name=Mark,timestamp=400',
          );
        });

        test('simple roundtrip - explode true', () {
          final simple = oneOf.toSimple(explode: true, allowEmpty: true);
          final reconstructed = TwoLevelMixedOneOfAllOf.fromSimple(
            simple,
            explode: true,
          );
          // Ambiguous oneOf: AllOf variant encodes to string form that matches the string variant.
          // The decoder tries string first and succeeds, returning TwoLevelMixedOneOfAllOfString.
          expect(
            reconstructed,
            anyOf(
              oneOf,
              TwoLevelMixedOneOfAllOfString('name=Mark,timestamp=400'),
            ),
          );
        });

        test('toSimple - explode false', () {
          expect(
            oneOf.toSimple(explode: false, allowEmpty: true),
            'name,Mark,timestamp,400',
          );
        });

        test('simple roundtrip - explode false', () {
          final simple = oneOf.toSimple(explode: false, allowEmpty: true);
          final reconstructed = TwoLevelMixedOneOfAllOf.fromSimple(
            simple,
            explode: false,
          );
          // Ambiguous oneOf: AllOf variant encodes to string form that matches the string variant.
          // The decoder tries string first and succeeds, returning TwoLevelMixedOneOfAllOfString.
          expect(
            reconstructed,
            anyOf(
              oneOf,
              TwoLevelMixedOneOfAllOfString('name,Mark,timestamp,400'),
            ),
          );
        });

        test('toMatrix - explode false', () {
          expect(
            oneOf.toMatrix('asdf', explode: false, allowEmpty: true),
            ';asdf=name,Mark,timestamp,400',
          );
        });

        test('toMatrix - explode true', () {
          expect(
            oneOf.toMatrix('asdf', explode: true, allowEmpty: true),
            ';name=Mark;timestamp=400',
          );
        });

        test('toLabel - explode true', () {
          expect(
            oneOf.toLabel(explode: true, allowEmpty: true),
            '.name=Mark.timestamp=400',
          );
        });

        test('toLabel - explode false', () {
          expect(
            oneOf.toLabel(explode: false, allowEmpty: true),
            '.name,Mark,timestamp,400',
          );
        });

        test('currentEncodingShape', () {
          expect(oneOf.currentEncodingShape, EncodingShape.complex);
        });
      });
    });

    group('string', () {
      late TwoLevelMixedOneOfAllOf oneOf;

      setUp(() {
        oneOf = TwoLevelMixedOneOfAllOfString('Mark');
      });

      test('toJson', () {
        expect(oneOf.toJson(), 'Mark');
      });

      test('json roundtrip', () {
        final json = oneOf.toJson();
        final reconstructed = TwoLevelMixedOneOfAllOf.fromJson(json);
        expect(reconstructed, oneOf);
      });

      test('toForm - explode true', () {
        expect(oneOf.toForm(explode: true, allowEmpty: true), 'Mark');
      });

      test('form roundtrip - explode true', () {
        final form = oneOf.toForm(explode: true, allowEmpty: true);
        final reconstructed = TwoLevelMixedOneOfAllOf.fromForm(
          form,
          explode: true,
        );
        expect(reconstructed, oneOf);
      });

      test('toForm - explode false', () {
        expect(oneOf.toForm(explode: false, allowEmpty: true), 'Mark');
      });

      test('form roundtrip - explode false', () {
        final form = oneOf.toForm(explode: false, allowEmpty: true);
        final reconstructed = TwoLevelMixedOneOfAllOf.fromForm(
          form,
          explode: false,
        );
        expect(reconstructed, oneOf);
      });

      test('toSimple - explode true', () {
        expect(oneOf.toSimple(explode: true, allowEmpty: true), 'Mark');
      });

      test('simple roundtrip - explode true', () {
        final simple = oneOf.toSimple(explode: true, allowEmpty: true);
        final reconstructed = TwoLevelMixedOneOfAllOf.fromSimple(
          simple,
          explode: true,
        );
        expect(reconstructed, oneOf);
      });

      test('toSimple - explode false', () {
        expect(oneOf.toSimple(explode: false, allowEmpty: true), 'Mark');
      });

      test('simple roundtrip - explode false', () {
        final simple = oneOf.toSimple(explode: false, allowEmpty: true);
        final reconstructed = TwoLevelMixedOneOfAllOf.fromSimple(
          simple,
          explode: false,
        );
        expect(reconstructed, oneOf);
      });

      test('toMatrix - explode false', () {
        expect(
          oneOf.toMatrix('asdf', explode: false, allowEmpty: true),
          ';asdf=Mark',
        );
      });

      test('toMatrix - explode true', () {
        expect(
          oneOf.toMatrix('asdf', explode: true, allowEmpty: true),
          ';asdf=Mark',
        );
      });

      test('toLabel - explode true', () {
        expect(oneOf.toLabel(explode: true, allowEmpty: true), '.Mark');
      });

      test('toLabel - explode false', () {
        expect(oneOf.toLabel(explode: false, allowEmpty: true), '.Mark');
      });

      test('currentEncodingShape', () {
        expect(oneOf.currentEncodingShape, EncodingShape.simple);
      });
    });
  });

  group('ThreeLevelOneOf', () {
    group('oneOf', () {
      group('oneOf', () {
        group('string', () {
          late ThreeLevelOneOf oneOf;

          setUp(() {
            oneOf = ThreeLevelOneOfOneOf(
              ThreeLevelOneOfModelOneOf(
                ThreeLevelOneOfOneOfModelString('string'),
              ),
            );
          });

          test('toJson', () {
            expect(oneOf.toJson(), 'string');
          });

          test('json roundtrip', () {
            final json = oneOf.toJson();
            final reconstructed = ThreeLevelOneOf.fromJson(json);
            expect(reconstructed, oneOf);
          });

          test('toForm - explode true', () {
            expect(oneOf.toForm(explode: true, allowEmpty: true), 'string');
          });

          test('form roundtrip - explode true', () {
            final form = oneOf.toForm(explode: true, allowEmpty: true);
            final reconstructed = ThreeLevelOneOf.fromForm(form, explode: true);
            expect(reconstructed, oneOf);
          });

          test('toForm - explode false', () {
            expect(oneOf.toForm(explode: false, allowEmpty: true), 'string');
          });

          test('form roundtrip - explode false', () {
            final form = oneOf.toForm(explode: false, allowEmpty: true);
            final reconstructed = ThreeLevelOneOf.fromForm(
              form,
              explode: false,
            );
            expect(reconstructed, oneOf);
          });

          test('toSimple - explode true', () {
            expect(oneOf.toSimple(explode: true, allowEmpty: true), 'string');
          });

          test('simple roundtrip - explode true', () {
            final simple = oneOf.toSimple(explode: true, allowEmpty: true);
            final reconstructed = ThreeLevelOneOf.fromSimple(
              simple,
              explode: true,
            );
            expect(reconstructed, oneOf);
          });

          test('toSimple - explode false', () {
            expect(oneOf.toSimple(explode: false, allowEmpty: true), 'string');
          });

          test('simple roundtrip - explode false', () {
            final simple = oneOf.toSimple(explode: false, allowEmpty: true);
            final reconstructed = ThreeLevelOneOf.fromSimple(
              simple,
              explode: false,
            );
            expect(reconstructed, oneOf);
          });

          test('toMatrix - explode false', () {
            expect(
              oneOf.toMatrix('asdf', explode: false, allowEmpty: true),
              ';asdf=string',
            );
          });

          test('toMatrix - explode true', () {
            expect(
              oneOf.toMatrix('asdf', explode: true, allowEmpty: true),
              ';asdf=string',
            );
          });

          test('toLabel - explode true', () {
            expect(oneOf.toLabel(explode: true, allowEmpty: true), '.string');
          });

          test('toLabel - explode false', () {
            expect(oneOf.toLabel(explode: false, allowEmpty: true), '.string');
          });

          test('currentEncodingShape', () {
            expect(oneOf.currentEncodingShape, EncodingShape.simple);
          });
        });

        group('integer', () {
          late ThreeLevelOneOf oneOf;

          setUp(() {
            oneOf = ThreeLevelOneOfOneOf(
              ThreeLevelOneOfModelOneOf(ThreeLevelOneOfOneOfModelInt(1)),
            );
          });

          test('toJson', () {
            expect(oneOf.toJson(), 1);
          });

          test('json roundtrip', () {
            final json = oneOf.toJson();
            final reconstructed = ThreeLevelOneOf.fromJson(json);
            // Ambiguous oneOf: integer (nested) and number (direct) both match numeric values.
            // The decoder checks for num type first and returns ThreeLevelOneOfNumber.
            expect(reconstructed, anyOf(oneOf, ThreeLevelOneOfNumber(1)));
          });

          test('toForm - explode true', () {
            expect(oneOf.toForm(explode: true, allowEmpty: true), '1');
          });

          test('form roundtrip - explode true', () {
            final form = oneOf.toForm(explode: true, allowEmpty: true);
            final reconstructed = ThreeLevelOneOf.fromForm(form, explode: true);
            // Ambiguous oneOf: integer (nested) and number (direct) both match numeric values.
            // The decoder tries to decode as double first and succeeds, returning ThreeLevelOneOfNumber.
            expect(reconstructed, anyOf(oneOf, ThreeLevelOneOfNumber(1)));
          });

          test('toForm - explode false', () {
            expect(oneOf.toForm(explode: false, allowEmpty: true), '1');
          });

          test('form roundtrip - explode false', () {
            final form = oneOf.toForm(explode: false, allowEmpty: true);
            final reconstructed = ThreeLevelOneOf.fromForm(
              form,
              explode: false,
            );
            // Ambiguous oneOf: integer (nested) and number (direct) both match numeric values.
            // The decoder tries to decode as double first and succeeds, returning ThreeLevelOneOfNumber.
            expect(reconstructed, anyOf(oneOf, ThreeLevelOneOfNumber(1)));
          });

          test('toSimple - explode true', () {
            expect(oneOf.toSimple(explode: true, allowEmpty: true), '1');
          });

          test('simple roundtrip - explode true', () {
            final simple = oneOf.toSimple(explode: true, allowEmpty: true);
            final reconstructed = ThreeLevelOneOf.fromSimple(
              simple,
              explode: true,
            );
            // Ambiguous oneOf: integer (nested) and number (direct) both match numeric values.
            // The decoder tries to decode as double first and succeeds, returning ThreeLevelOneOfNumber.
            expect(reconstructed, anyOf(oneOf, ThreeLevelOneOfNumber(1)));
          });

          test('toSimple - explode false', () {
            expect(oneOf.toSimple(explode: false, allowEmpty: true), '1');
          });

          test('simple roundtrip - explode false', () {
            final simple = oneOf.toSimple(explode: false, allowEmpty: true);
            final reconstructed = ThreeLevelOneOf.fromSimple(
              simple,
              explode: false,
            );
            // Ambiguous oneOf: integer (nested) and number (direct) both match numeric values.
            // The decoder tries to decode as double first and succeeds, returning ThreeLevelOneOfNumber.
            expect(reconstructed, anyOf(oneOf, ThreeLevelOneOfNumber(1)));
          });

          test('toMatrix - explode false', () {
            expect(
              oneOf.toMatrix('asdf', explode: false, allowEmpty: true),
              ';asdf=1',
            );
          });

          test('toMatrix - explode true', () {
            expect(
              oneOf.toMatrix('asdf', explode: true, allowEmpty: true),
              ';asdf=1',
            );
          });

          test('toLabel - explode true', () {
            expect(oneOf.toLabel(explode: true, allowEmpty: true), '.1');
          });

          test('toLabel - explode false', () {
            expect(oneOf.toLabel(explode: false, allowEmpty: true), '.1');
          });

          test('currentEncodingShape', () {
            expect(oneOf.currentEncodingShape, EncodingShape.simple);
          });
        });
      });

      group('boolean', () {
        group('boolean', () {
          late ThreeLevelOneOf oneOf;

          setUp(() {
            oneOf = ThreeLevelOneOfOneOf(ThreeLevelOneOfModelBool(true));
          });

          test('toJson', () {
            expect(oneOf.toJson(), true);
          });

          test('json roundtrip', () {
            final json = oneOf.toJson();
            final reconstructed = ThreeLevelOneOf.fromJson(json);
            expect(reconstructed, oneOf);
          });

          test('toForm - explode true', () {
            expect(oneOf.toForm(explode: true, allowEmpty: true), 'true');
          });

          test('form roundtrip - explode true', () {
            final form = oneOf.toForm(explode: true, allowEmpty: true);
            final reconstructed = ThreeLevelOneOf.fromForm(form, explode: true);
            expect(reconstructed, oneOf);
          });

          test('toForm - explode false', () {
            expect(oneOf.toForm(explode: false, allowEmpty: true), 'true');
          });

          test('form roundtrip - explode false', () {
            final form = oneOf.toForm(explode: false, allowEmpty: true);
            final reconstructed = ThreeLevelOneOf.fromForm(
              form,
              explode: false,
            );
            expect(reconstructed, oneOf);
          });

          test('toSimple - explode true', () {
            expect(oneOf.toSimple(explode: true, allowEmpty: true), 'true');
          });

          test('simple roundtrip - explode true', () {
            final simple = oneOf.toSimple(explode: true, allowEmpty: true);
            final reconstructed = ThreeLevelOneOf.fromSimple(
              simple,
              explode: true,
            );
            expect(reconstructed, oneOf);
          });

          test('toSimple - explode false', () {
            expect(oneOf.toSimple(explode: false, allowEmpty: true), 'true');
          });

          test('simple roundtrip - explode false', () {
            final simple = oneOf.toSimple(explode: false, allowEmpty: true);
            final reconstructed = ThreeLevelOneOf.fromSimple(
              simple,
              explode: false,
            );
            expect(reconstructed, oneOf);
          });

          test('toMatrix - explode false', () {
            expect(
              oneOf.toMatrix('asdf', explode: false, allowEmpty: true),
              ';asdf=true',
            );
          });

          test('toMatrix - explode true', () {
            expect(
              oneOf.toMatrix('asdf', explode: true, allowEmpty: true),
              ';asdf=true',
            );
          });

          test('toLabel - explode true', () {
            expect(oneOf.toLabel(explode: true, allowEmpty: true), '.true');
          });

          test('toLabel - explode false', () {
            expect(oneOf.toLabel(explode: false, allowEmpty: true), '.true');
          });

          test('currentEncodingShape', () {
            expect(oneOf.currentEncodingShape, EncodingShape.simple);
          });
        });
      });
    });

    group('number', () {
      group('number', () {
        late ThreeLevelOneOf oneOf;

        setUp(() {
          oneOf = ThreeLevelOneOfNumber(-991);
        });

        test('toJson', () {
          expect(oneOf.toJson(), -991);
        });

        test('json roundtrip', () {
          final json = oneOf.toJson();
          final reconstructed = ThreeLevelOneOf.fromJson(json);
          expect(reconstructed, oneOf);
        });

        test('toForm - explode true', () {
          expect(oneOf.toForm(explode: true, allowEmpty: true), '-991');
        });

        test('form roundtrip - explode true', () {
          final form = oneOf.toForm(explode: true, allowEmpty: true);
          final reconstructed = ThreeLevelOneOf.fromForm(form, explode: true);
          expect(reconstructed, oneOf);
        });

        test('toForm - explode false', () {
          expect(oneOf.toForm(explode: false, allowEmpty: true), '-991');
        });

        test('form roundtrip - explode false', () {
          final form = oneOf.toForm(explode: false, allowEmpty: true);
          final reconstructed = ThreeLevelOneOf.fromForm(form, explode: false);
          expect(reconstructed, oneOf);
        });

        test('toSimple - explode true', () {
          expect(oneOf.toSimple(explode: true, allowEmpty: true), '-991');
        });

        test('simple roundtrip - explode true', () {
          final simple = oneOf.toSimple(explode: true, allowEmpty: true);
          final reconstructed = ThreeLevelOneOf.fromSimple(
            simple,
            explode: true,
          );
          expect(reconstructed, oneOf);
        });

        test('toSimple - explode false', () {
          expect(oneOf.toSimple(explode: false, allowEmpty: true), '-991');
        });

        test('simple roundtrip - explode false', () {
          final simple = oneOf.toSimple(explode: false, allowEmpty: true);
          final reconstructed = ThreeLevelOneOf.fromSimple(
            simple,
            explode: false,
          );
          expect(reconstructed, oneOf);
        });

        test('toMatrix - explode false', () {
          expect(
            oneOf.toMatrix('asdf', explode: false, allowEmpty: true),
            ';asdf=-991',
          );
        });

        test('toMatrix - explode true', () {
          expect(
            oneOf.toMatrix('asdf', explode: true, allowEmpty: true),
            ';asdf=-991',
          );
        });

        test('toLabel - explode true', () {
          expect(oneOf.toLabel(explode: true, allowEmpty: true), '.-991');
        });

        test('toLabel - explode false', () {
          expect(oneOf.toLabel(explode: false, allowEmpty: true), '.-991');
        });

        test('currentEncodingShape', () {
          expect(oneOf.currentEncodingShape, EncodingShape.simple);
        });
      });
    });
  });

  group('ThreeLevelMixedOneOfAllOfAnyOf', () {
    group('allOf', () {
      group('anyOf with string and int', () {
        late ThreeLevelMixedOneOfAllOfAnyOf oneOf;

        setUp(() {
          final allOfModel = ThreeLevelMixedOneOfAllOfAnyOfAllOfModel(
            threeLevelMixedOneOfAllOfAnyOfAllOfAnyOfModel:
                ThreeLevelMixedOneOfAllOfAnyOfAllOfAnyOfModel(
                  string: 'string',
                  int: 123,
                ),
            threeLevelMixedOneOfAllOfAnyOfAllOfModel2:
                ThreeLevelMixedOneOfAllOfAnyOfAllOfModel2(flag: true),
          );
          oneOf = ThreeLevelMixedOneOfAllOfAnyOfAllOf(allOfModel);
        });

        test('toJson throws EncodingException', () {
          expect(oneOf.toJson, throwsA(isA<EncodingException>()));
        });

        test('toForm throws EncodingException', () {
          expect(
            () => oneOf.toForm(explode: true, allowEmpty: true),
            throwsA(isA<EncodingException>()),
          );
        });

        test('toSimple throws EncodingException', () {
          expect(
            () => oneOf.toSimple(explode: true, allowEmpty: true),
            throwsA(isA<EncodingException>()),
          );
        });

        test('toMatrix throws EncodingException', () {
          expect(
            () => oneOf.toMatrix('asdf', explode: false, allowEmpty: true),
            throwsA(isA<EncodingException>()),
          );
        });

        test('toLabel - explode true throws EncodingException', () {
          expect(
            () => oneOf.toLabel(explode: true, allowEmpty: true),
            throwsA(isA<EncodingException>()),
          );
        });

        test('toLabel - explode false throws EncodingException', () {
          expect(
            () => oneOf.toLabel(explode: false, allowEmpty: true),
            throwsA(isA<EncodingException>()),
          );
        });

        test('currentEncodingShape', () {
          expect(oneOf.currentEncodingShape, EncodingShape.mixed);
        });
      });

      group('anyOf with int only', () {
        late ThreeLevelMixedOneOfAllOfAnyOf oneOf;

        setUp(() {
          final allOfModel = ThreeLevelMixedOneOfAllOfAnyOfAllOfModel(
            threeLevelMixedOneOfAllOfAnyOfAllOfAnyOfModel:
                ThreeLevelMixedOneOfAllOfAnyOfAllOfAnyOfModel(
                  string: null,
                  int: 456,
                ),
            threeLevelMixedOneOfAllOfAnyOfAllOfModel2:
                ThreeLevelMixedOneOfAllOfAnyOfAllOfModel2(flag: false),
          );
          oneOf = ThreeLevelMixedOneOfAllOfAnyOfAllOf(allOfModel);
        });

        test('toJson throws EncodingException', () {
          expect(oneOf.toJson, throwsA(isA<EncodingException>()));
        });

        test('toForm throws EncodingException', () {
          expect(
            () => oneOf.toForm(explode: true, allowEmpty: true),
            throwsA(isA<EncodingException>()),
          );
        });

        test('toSimple throws EncodingException', () {
          expect(
            () => oneOf.toSimple(explode: true, allowEmpty: true),
            throwsA(isA<EncodingException>()),
          );
        });

        test('toMatrix throws EncodingException', () {
          expect(
            () => oneOf.toMatrix('asdf', explode: false, allowEmpty: true),
            throwsA(isA<EncodingException>()),
          );
        });

        test('toLabel - explode true throws EncodingException', () {
          expect(
            () => oneOf.toLabel(explode: true, allowEmpty: true),
            throwsA(isA<EncodingException>()),
          );
        });

        test('toLabel - explode false throws EncodingException', () {
          expect(
            () => oneOf.toLabel(explode: false, allowEmpty: true),
            throwsA(isA<EncodingException>()),
          );
        });

        test('currentEncodingShape', () {
          expect(oneOf.currentEncodingShape, EncodingShape.mixed);
        });
      });
    });

    group('Class1', () {
      group('class1', () {
        late ThreeLevelMixedOneOfAllOfAnyOf oneOf;

        setUp(() {
          oneOf = ThreeLevelMixedOneOfAllOfAnyOfClass1(Class1(name: 'Mark'));
        });

        test('toJson', () {
          expect(oneOf.toJson(), {'name': 'Mark'});
        });

        test('json roundtrip', () {
          final json = oneOf.toJson();
          final reconstructed = ThreeLevelMixedOneOfAllOfAnyOf.fromJson(json);
          expect(reconstructed, oneOf);
        });

        test('toForm - explode true', () {
          expect(oneOf.toForm(explode: true, allowEmpty: true), 'name=Mark');
        });

        test('form roundtrip - explode true', () {
          final form = oneOf.toForm(explode: true, allowEmpty: true);
          final reconstructed = ThreeLevelMixedOneOfAllOfAnyOf.fromForm(
            form,
            explode: true,
          );
          expect(reconstructed, oneOf);
        });

        test('toForm - explode false', () {
          expect(oneOf.toForm(explode: false, allowEmpty: true), 'name,Mark');
        });

        test('form roundtrip - explode false', () {
          final form = oneOf.toForm(explode: false, allowEmpty: true);
          final reconstructed = ThreeLevelMixedOneOfAllOfAnyOf.fromForm(
            form,
            explode: false,
          );
          expect(reconstructed, oneOf);
        });

        test('toSimple - explode true', () {
          expect(oneOf.toSimple(explode: true, allowEmpty: true), 'name=Mark');
        });

        test('simple roundtrip - explode true', () {
          final simple = oneOf.toSimple(explode: true, allowEmpty: true);
          final reconstructed = ThreeLevelMixedOneOfAllOfAnyOf.fromSimple(
            simple,
            explode: true,
          );
          expect(reconstructed, oneOf);
        });

        test('toSimple - explode false', () {
          expect(oneOf.toSimple(explode: false, allowEmpty: true), 'name,Mark');
        });

        test('simple roundtrip - explode false', () {
          final simple = oneOf.toSimple(explode: false, allowEmpty: true);
          final reconstructed = ThreeLevelMixedOneOfAllOfAnyOf.fromSimple(
            simple,
            explode: false,
          );
          expect(reconstructed, oneOf);
        });

        test('toMatrix - explode false', () {
          expect(
            oneOf.toMatrix('asdf', explode: false, allowEmpty: true),
            ';asdf=name,Mark',
          );
        });

        test('toMatrix - explode true', () {
          expect(
            oneOf.toMatrix('asdf', explode: true, allowEmpty: true),
            ';name=Mark',
          );
        });

        test('toLabel - explode true', () {
          expect(oneOf.toLabel(explode: true, allowEmpty: true), '.name=Mark');
        });

        test('toLabel - explode false', () {
          expect(oneOf.toLabel(explode: false, allowEmpty: true), '.name,Mark');
        });

        test('currentEncodingShape', () {
          expect(oneOf.currentEncodingShape, EncodingShape.complex);
        });
      });
    });
  });

  group('ThreeLevelWithRefs', () {
    group('TwoLevelOneOf', () {
      group('string', () {
        late ThreeLevelWithRefs oneOf;

        setUp(() {
          oneOf = ThreeLevelWithRefsTwoLevelOneOf(
            TwoLevelOneOfOneOf(TwoLevelOneOfModelString('string')),
          );
        });

        test('toJson', () {
          expect(oneOf.toJson(), 'string');
        });

        test('json roundtrip', () {
          final json = oneOf.toJson();
          final reconstructed = ThreeLevelWithRefs.fromJson(json);
          // Ambiguous oneOf: string appears both in TwoLevelOneOf (nested) and as direct variant.
          // For JSON, the String type check happens first, returning ThreeLevelWithRefsString.
          expect(
            reconstructed,
            anyOf(oneOf, ThreeLevelWithRefsString('string')),
          );
        });

        test('toForm - explode true', () {
          expect(oneOf.toForm(explode: true, allowEmpty: true), 'string');
        });

        test('form roundtrip - explode true', () {
          final form = oneOf.toForm(explode: true, allowEmpty: true);
          final reconstructed = ThreeLevelWithRefs.fromForm(
            form,
            explode: true,
          );
          expect(reconstructed, oneOf);
        });

        test('toForm - explode false', () {
          expect(oneOf.toForm(explode: false, allowEmpty: true), 'string');
        });

        test('form roundtrip - explode false', () {
          final form = oneOf.toForm(explode: false, allowEmpty: true);
          final reconstructed = ThreeLevelWithRefs.fromForm(
            form,
            explode: false,
          );
          expect(reconstructed, oneOf);
        });

        test('toSimple - explode true', () {
          expect(oneOf.toSimple(explode: true, allowEmpty: true), 'string');
        });

        test('simple roundtrip - explode true', () {
          final simple = oneOf.toSimple(explode: true, allowEmpty: true);
          final reconstructed = ThreeLevelWithRefs.fromSimple(
            simple,
            explode: true,
          );
          expect(reconstructed, oneOf);
        });

        test('toSimple - explode false', () {
          expect(oneOf.toSimple(explode: false, allowEmpty: true), 'string');
        });

        test('simple roundtrip - explode false', () {
          final simple = oneOf.toSimple(explode: false, allowEmpty: true);
          final reconstructed = ThreeLevelWithRefs.fromSimple(
            simple,
            explode: false,
          );
          expect(reconstructed, oneOf);
        });

        test('toMatrix - explode false', () {
          expect(
            oneOf.toMatrix('asdf', explode: false, allowEmpty: true),
            ';asdf=string',
          );
        });

        test('toMatrix - explode true', () {
          expect(
            oneOf.toMatrix('asdf', explode: true, allowEmpty: true),
            ';asdf=string',
          );
        });

        test('toLabel - explode true', () {
          expect(oneOf.toLabel(explode: true, allowEmpty: true), '.string');
        });

        test('toLabel - explode false', () {
          expect(oneOf.toLabel(explode: false, allowEmpty: true), '.string');
        });

        test('currentEncodingShape', () {
          expect(oneOf.currentEncodingShape, EncodingShape.simple);
        });
      });

      group('integer', () {
        late ThreeLevelWithRefs oneOf;

        setUp(() {
          oneOf = ThreeLevelWithRefsTwoLevelOneOf(
            TwoLevelOneOfOneOf(TwoLevelOneOfModelInt(1)),
          );
        });

        test('toJson', () {
          expect(oneOf.toJson(), 1);
        });

        test('json roundtrip', () {
          final json = oneOf.toJson();
          final reconstructed = ThreeLevelWithRefs.fromJson(json);
          expect(reconstructed, oneOf);
        });

        test('toForm - explode true', () {
          expect(oneOf.toForm(explode: true, allowEmpty: true), '1');
        });

        test('form roundtrip - explode true', () {
          final form = oneOf.toForm(explode: true, allowEmpty: true);
          final reconstructed = ThreeLevelWithRefs.fromForm(
            form,
            explode: true,
          );
          expect(reconstructed, oneOf);
        });

        test('toForm - explode false', () {
          expect(oneOf.toForm(explode: false, allowEmpty: true), '1');
        });

        test('form roundtrip - explode false', () {
          final form = oneOf.toForm(explode: false, allowEmpty: true);
          final reconstructed = ThreeLevelWithRefs.fromForm(
            form,
            explode: false,
          );
          expect(reconstructed, oneOf);
        });

        test('toSimple - explode true', () {
          expect(oneOf.toSimple(explode: true, allowEmpty: true), '1');
        });

        test('simple roundtrip - explode true', () {
          final simple = oneOf.toSimple(explode: true, allowEmpty: true);
          final reconstructed = ThreeLevelWithRefs.fromSimple(
            simple,
            explode: true,
          );
          expect(reconstructed, oneOf);
        });

        test('toSimple - explode false', () {
          expect(oneOf.toSimple(explode: false, allowEmpty: true), '1');
        });

        test('simple roundtrip - explode false', () {
          final simple = oneOf.toSimple(explode: false, allowEmpty: true);
          final reconstructed = ThreeLevelWithRefs.fromSimple(
            simple,
            explode: false,
          );
          expect(reconstructed, oneOf);
        });

        test('toMatrix - explode false', () {
          expect(
            oneOf.toMatrix('asdf', explode: false, allowEmpty: true),
            ';asdf=1',
          );
        });

        test('toMatrix - explode true', () {
          expect(
            oneOf.toMatrix('asdf', explode: true, allowEmpty: true),
            ';asdf=1',
          );
        });

        test('toLabel - explode true', () {
          expect(oneOf.toLabel(explode: true, allowEmpty: true), '.1');
        });

        test('toLabel - explode false', () {
          expect(oneOf.toLabel(explode: false, allowEmpty: true), '.1');
        });

        test('currentEncodingShape', () {
          expect(oneOf.currentEncodingShape, EncodingShape.simple);
        });
      });
    });

    group('string', () {
      group('string', () {
        late ThreeLevelWithRefs oneOf;

        setUp(() {
          oneOf = ThreeLevelWithRefsString('string');
        });

        test('toJson', () {
          expect(oneOf.toJson(), 'string');
        });

        test('json roundtrip', () {
          final json = oneOf.toJson();
          final reconstructed = ThreeLevelWithRefs.fromJson(json);
          expect(reconstructed, oneOf);
        });

        test('toForm - explode true', () {
          expect(oneOf.toForm(explode: true, allowEmpty: true), 'string');
        });

        test('form roundtrip - explode true', () {
          final form = oneOf.toForm(explode: true, allowEmpty: true);
          final reconstructed = ThreeLevelWithRefs.fromForm(
            form,
            explode: true,
          );
          // Ambiguous oneOf: string appears both in TwoLevelOneOf (nested) and as direct variant.
          // For Form, TwoLevelOneOf is tried first and succeeds, returning ThreeLevelWithRefsTwoLevelOneOf.
          expect(
            reconstructed,
            anyOf(
              oneOf,
              ThreeLevelWithRefsTwoLevelOneOf(
                TwoLevelOneOfOneOf(TwoLevelOneOfModelString('string')),
              ),
            ),
          );
        });

        test('toForm - explode false', () {
          expect(oneOf.toForm(explode: false, allowEmpty: true), 'string');
        });

        test('form roundtrip - explode false', () {
          final form = oneOf.toForm(explode: false, allowEmpty: true);
          final reconstructed = ThreeLevelWithRefs.fromForm(
            form,
            explode: false,
          );
          // Ambiguous oneOf: string appears both in TwoLevelOneOf (nested) and as direct variant.
          // For Form, TwoLevelOneOf is tried first and succeeds, returning ThreeLevelWithRefsTwoLevelOneOf.
          expect(
            reconstructed,
            anyOf(
              oneOf,
              ThreeLevelWithRefsTwoLevelOneOf(
                TwoLevelOneOfOneOf(TwoLevelOneOfModelString('string')),
              ),
            ),
          );
        });

        test('toSimple - explode true', () {
          expect(oneOf.toSimple(explode: true, allowEmpty: true), 'string');
        });

        test('simple roundtrip - explode true', () {
          final simple = oneOf.toSimple(explode: true, allowEmpty: true);
          final reconstructed = ThreeLevelWithRefs.fromSimple(
            simple,
            explode: true,
          );
          // Ambiguous oneOf: string appears both in TwoLevelOneOf (nested) and as direct variant.
          // For Simple, TwoLevelOneOf is tried first and succeeds, returning ThreeLevelWithRefsTwoLevelOneOf.
          expect(
            reconstructed,
            anyOf(
              oneOf,
              ThreeLevelWithRefsTwoLevelOneOf(
                TwoLevelOneOfOneOf(TwoLevelOneOfModelString('string')),
              ),
            ),
          );
        });

        test('toSimple - explode false', () {
          expect(oneOf.toSimple(explode: false, allowEmpty: true), 'string');
        });

        test('simple roundtrip - explode false', () {
          final simple = oneOf.toSimple(explode: false, allowEmpty: true);
          final reconstructed = ThreeLevelWithRefs.fromSimple(
            simple,
            explode: false,
          );
          // Ambiguous oneOf: string appears both in TwoLevelOneOf (nested) and as direct variant.
          // For Simple, TwoLevelOneOf is tried first and succeeds, returning ThreeLevelWithRefsTwoLevelOneOf.
          expect(
            reconstructed,
            anyOf(
              oneOf,
              ThreeLevelWithRefsTwoLevelOneOf(
                TwoLevelOneOfOneOf(TwoLevelOneOfModelString('string')),
              ),
            ),
          );
        });

        test('toMatrix - explode false', () {
          expect(
            oneOf.toMatrix('asdf', explode: false, allowEmpty: true),
            ';asdf=string',
          );
        });

        test('toMatrix - explode true', () {
          expect(
            oneOf.toMatrix('asdf', explode: true, allowEmpty: true),
            ';asdf=string',
          );
        });

        test('toLabel - explode true', () {
          expect(oneOf.toLabel(explode: true, allowEmpty: true), '.string');
        });

        test('toLabel - explode false', () {
          expect(oneOf.toLabel(explode: false, allowEmpty: true), '.string');
        });

        test('currentEncodingShape', () {
          expect(oneOf.currentEncodingShape, EncodingShape.simple);
        });
      });
    });
  });

  group('ComplexNestedMix2', () {
    group('allOf', () {
      late ComplexNestedMix2 oneOf;

      setUp(() {
        oneOf = ComplexNestedMix2AllOf(
          ComplexNestedMix2AllOfModel(
            class1: Class1(name: 'Mark'),
            complexNestedMix2AllOfModel2: ComplexNestedMix2AllOfModel2(
              extra: 123,
            ),
          ),
        );
      });

      test('toJson', () {
        expect(oneOf.toJson(), {'name': 'Mark', 'extra': 123});
      });

      test('json roundtrip', () {
        final json = oneOf.toJson();
        final reconstructed = ComplexNestedMix2.fromJson(json);
        expect(reconstructed, oneOf);
      });

      test('toForm - explode true', () {
        expect(
          oneOf.toForm(explode: true, allowEmpty: true),
          'name=Mark&extra=123',
        );
      });

      test('form roundtrip - explode true', () {
        final form = oneOf.toForm(explode: true, allowEmpty: true);
        final reconstructed = ComplexNestedMix2.fromForm(form, explode: true);
        expect(reconstructed, oneOf);
      });

      test('toForm - explode false', () {
        expect(
          oneOf.toForm(explode: false, allowEmpty: true),
          'name,Mark,extra,123',
        );
      });

      test('form roundtrip - explode false', () {
        final form = oneOf.toForm(explode: false, allowEmpty: true);
        final reconstructed = ComplexNestedMix2.fromForm(form, explode: false);
        expect(reconstructed, oneOf);
      });

      test('toSimple - explode true', () {
        expect(
          oneOf.toSimple(explode: true, allowEmpty: true),
          'name=Mark,extra=123',
        );
      });

      test('simple roundtrip - explode true', () {
        final simple = oneOf.toSimple(explode: true, allowEmpty: true);
        final reconstructed = ComplexNestedMix2.fromSimple(
          simple,
          explode: true,
        );
        expect(reconstructed, oneOf);
      });

      test('toSimple - explode false', () {
        expect(
          oneOf.toSimple(explode: false, allowEmpty: true),
          'name,Mark,extra,123',
        );
      });

      test('simple roundtrip - explode false', () {
        final simple = oneOf.toSimple(explode: false, allowEmpty: true);
        final reconstructed = ComplexNestedMix2.fromSimple(
          simple,
          explode: false,
        );
        expect(reconstructed, oneOf);
      });

      test('toMatrix - explode false', () {
        expect(
          oneOf.toMatrix('asdf', explode: false, allowEmpty: true),
          ';asdf=name,Mark,extra,123',
        );
      });

      test('toMatrix - explode true', () {
        expect(
          oneOf.toMatrix('asdf', explode: true, allowEmpty: true),
          ';name=Mark;extra=123',
        );
      });

      test('toLabel - explode true', () {
        expect(
          oneOf.toLabel(explode: true, allowEmpty: true),
          '.name=Mark.extra=123',
        );
      });

      test('toLabel - explode false', () {
        expect(
          oneOf.toLabel(explode: false, allowEmpty: true),
          '.name,Mark,extra,123',
        );
      });

      test('currentEncodingShape', () {
        expect(oneOf.currentEncodingShape, EncodingShape.complex);
      });
    });

    group('Enum1', () {
      late ComplexNestedMix2 oneOf;

      setUp(() {
        oneOf = ComplexNestedMix2Enum1(Enum1.value2);
      });

      test('toJson', () {
        expect(oneOf.toJson(), 'value2');
      });

      test('json roundtrip', () {
        final json = oneOf.toJson();
        final reconstructed = ComplexNestedMix2.fromJson(json);
        expect(reconstructed, oneOf);
      });

      test('toForm - explode true', () {
        expect(oneOf.toForm(explode: true, allowEmpty: true), 'value2');
      });

      test('form roundtrip - explode true', () {
        final form = oneOf.toForm(explode: true, allowEmpty: true);
        final reconstructed = ComplexNestedMix2.fromForm(form, explode: true);
        expect(reconstructed, oneOf);
      });

      test('toForm - explode false', () {
        expect(oneOf.toForm(explode: false, allowEmpty: true), 'value2');
      });

      test('form roundtrip - explode false', () {
        final form = oneOf.toForm(explode: false, allowEmpty: true);
        final reconstructed = ComplexNestedMix2.fromForm(form, explode: false);
        expect(reconstructed, oneOf);
      });

      test('toSimple - explode true', () {
        expect(oneOf.toSimple(explode: true, allowEmpty: true), 'value2');
      });

      test('simple roundtrip - explode true', () {
        final simple = oneOf.toSimple(explode: true, allowEmpty: true);
        final reconstructed = ComplexNestedMix2.fromSimple(
          simple,
          explode: true,
        );
        expect(reconstructed, oneOf);
      });

      test('toSimple - explode false', () {
        expect(oneOf.toSimple(explode: false, allowEmpty: true), 'value2');
      });

      test('simple roundtrip - explode false', () {
        final simple = oneOf.toSimple(explode: false, allowEmpty: true);
        final reconstructed = ComplexNestedMix2.fromSimple(
          simple,
          explode: false,
        );
        expect(reconstructed, oneOf);
      });

      test('toMatrix - explode false', () {
        expect(
          oneOf.toMatrix('asdf', explode: false, allowEmpty: true),
          ';asdf=value2',
        );
      });

      test('toMatrix - explode true', () {
        expect(
          oneOf.toMatrix('asdf', explode: true, allowEmpty: true),
          ';asdf=value2',
        );
      });

      test('toLabel - explode true', () {
        expect(oneOf.toLabel(explode: true, allowEmpty: true), '.value2');
      });

      test('toLabel - explode false', () {
        expect(oneOf.toLabel(explode: false, allowEmpty: true), '.value2');
      });

      test('currentEncodingShape', () {
        expect(oneOf.currentEncodingShape, EncodingShape.simple);
      });
    });
  });
}
