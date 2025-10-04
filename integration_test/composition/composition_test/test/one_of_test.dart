import 'package:composition_api/composition_api.dart';
import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  group('OneOfPrimitive', () {
    test('string', () {
      final oneOf = OneOfPrimitiveOneOfPrimitiveModel('string');
      expect(oneOf.toJson(), 'string');
      expect(oneOf.toForm(explode: true, allowEmpty: true), 'string');
      expect(oneOf.toSimple(explode: true, allowEmpty: true), 'string');

      expect(oneOf.currentEncodingShape, EncodingShape.simple);
    });

    test('integer', () {
      final oneOf = OneOfPrimitiveOneOfPrimitiveModel2(1);
      expect(oneOf.toJson(), 1);
      expect(oneOf.toForm(explode: true, allowEmpty: true), '1');
      expect(oneOf.toSimple(explode: true, allowEmpty: true), '1');

      expect(oneOf.currentEncodingShape, EncodingShape.simple);
    });
  });

  group('OneOfComplex', () {
    test('class1', () {
      final oneOf = OneOfComplexClass1(Class1(name: 'Kate'));
      expect(oneOf.toJson(), {'name': 'Kate'});
      expect(oneOf.toForm(explode: true, allowEmpty: true), 'name=Kate');
      expect(oneOf.toSimple(explode: true, allowEmpty: true), 'name=Kate');
      expect(oneOf.toSimple(explode: false, allowEmpty: true), 'name,Kate');

      expect(oneOf.currentEncodingShape, EncodingShape.complex);
    });

    test('class2', () {
      final oneOf = OneOfComplexClass2(Class2(number: 1));
      expect(oneOf.toJson(), {'number': 1});
      expect(oneOf.toForm(explode: true, allowEmpty: true), 'number=1');
      expect(oneOf.toSimple(explode: true, allowEmpty: true), 'number=1');
      expect(oneOf.toSimple(explode: false, allowEmpty: true), 'number,1');

      expect(oneOf.currentEncodingShape, EncodingShape.complex);
    });
  });

  group('OneOfEnum', () {
    test('enum1', () {
      final oneOf = OneOfEnumEnum1(Enum1.value1);
      expect(oneOf.toJson(), 'value1');
      expect(oneOf.toForm(explode: true, allowEmpty: true), 'value1');
      expect(oneOf.toSimple(explode: true, allowEmpty: true), 'value1');

      expect(oneOf.currentEncodingShape, EncodingShape.simple);
    });

    test('enum2', () {
      final oneOf = OneOfEnumEnum2(Enum2.one);
      expect(oneOf.toJson(), 1);
      expect(oneOf.toForm(explode: true, allowEmpty: true), '1');
      expect(oneOf.toSimple(explode: false, allowEmpty: false), '1');

      expect(oneOf.currentEncodingShape, EncodingShape.simple);
    });
  });

  group('OneOfMixed', () {
    test('string', () {
      final oneOf = OneOfMixedOneOfMixedModel('my value');
      expect(oneOf.toJson(), 'my value');
      expect(oneOf.toForm(explode: true, allowEmpty: true), 'my+value');
      expect(oneOf.toSimple(explode: true, allowEmpty: true), 'my%20value');

      expect(oneOf.currentEncodingShape, EncodingShape.simple);
    });

    test('class1', () {
      final oneOf = OneOfMixedClass1(Class1(name: 'Kate'));
      expect(oneOf.toJson(), {'name': 'Kate'});
      expect(oneOf.toForm(explode: true, allowEmpty: true), 'name=Kate');
      expect(oneOf.toSimple(explode: true, allowEmpty: true), 'name=Kate');
      expect(oneOf.toSimple(explode: false, allowEmpty: true), 'name,Kate');

      expect(oneOf.currentEncodingShape, EncodingShape.complex);
    });

    test('enum1', () {
      final oneOf = OneOfMixedEnum1(Enum1.value2);
      expect(oneOf.toJson(), 'value2');
      expect(oneOf.toForm(explode: true, allowEmpty: true), 'value2');
      expect(oneOf.toSimple(explode: true, allowEmpty: true), 'value2');

      expect(oneOf.currentEncodingShape, EncodingShape.simple);
    });
  });

  group('NestedOneOfInOneOf', () {
    group('oneOfPrimitive', () {
      test('string', () {
        final oneOf = NestedOneOfInOneOfOneOfPrimitive(
          OneOfPrimitiveOneOfPrimitiveModel('string'),
        );
        expect(oneOf.toJson(), 'string');
        expect(oneOf.toForm(explode: true, allowEmpty: true), 'string');
        expect(oneOf.toSimple(explode: true, allowEmpty: true), 'string');

        expect(oneOf.currentEncodingShape, EncodingShape.simple);
      });

      test('integer', () {
        final oneOf = NestedOneOfInOneOfOneOfPrimitive(
          OneOfPrimitiveOneOfPrimitiveModel2(1),
        );
        expect(oneOf.toJson(), 1);
        expect(oneOf.toForm(explode: true, allowEmpty: true), '1');
        expect(oneOf.toSimple(explode: true, allowEmpty: true), '1');

        expect(oneOf.currentEncodingShape, EncodingShape.simple);
      });
    });

    group('oneOfComplex', () {
      test('class1', () {
        final oneOf = NestedOneOfInOneOfOneOfComplex(
          OneOfComplexClass1(Class1(name: 'Mark')),
        );
        expect(oneOf.toJson(), {'name': 'Mark'});
        expect(oneOf.toForm(explode: true, allowEmpty: true), 'name=Mark');
        expect(oneOf.toSimple(explode: true, allowEmpty: true), 'name=Mark');
        expect(oneOf.toSimple(explode: false, allowEmpty: true), 'name,Mark');

        expect(oneOf.currentEncodingShape, EncodingShape.complex);
      });

      test('class2', () {
        final oneOf = NestedOneOfInOneOfOneOfComplex(
          OneOfComplexClass2(Class2(number: 2)),
        );
        expect(oneOf.toJson(), {'number': 2});
        expect(oneOf.toForm(explode: true, allowEmpty: true), 'number=2');
        expect(oneOf.toSimple(explode: true, allowEmpty: true), 'number=2');
        expect(oneOf.toSimple(explode: false, allowEmpty: true), 'number,2');

        expect(oneOf.currentEncodingShape, EncodingShape.complex);
      });
    });
  });

  group('NestedAllOfInOneOf', () {
    group('allOfComplex', () {
      test('Class1', () {
        final oneOf = NestedAllOfInOneOfAllOfComplex(
          AllOfComplex(
            class1: Class1(name: 'Mark'),
            class2: Class2(number: 2),
          ),
        );
        expect(oneOf.toJson(), {'name': 'Mark', 'number': 2});
        expect(
          oneOf.toForm(explode: true, allowEmpty: true),
          'name=Mark&number=2',
        );
        expect(
          oneOf.toSimple(explode: true, allowEmpty: true),
          'name=Mark,number=2',
        );
        expect(
          oneOf.toSimple(explode: false, allowEmpty: true),
          'name,Mark,number,2',
        );

        expect(oneOf.currentEncodingShape, EncodingShape.complex);
      });

      test('Class1 and Class2', () {
        final oneOf = NestedAllOfInOneOfAllOfComplex(
          AllOfComplex(
            class1: Class1(name: 'Mark'),
            class2: Class2(number: 2),
          ),
        );
        expect(oneOf.toJson(), {'name': 'Mark', 'number': 2});
        expect(
          oneOf.toForm(explode: true, allowEmpty: true),
          'name=Mark&number=2',
        );
        expect(
          oneOf.toSimple(explode: true, allowEmpty: true),
          'name=Mark,number=2',
        );
        expect(
          oneOf.toSimple(explode: false, allowEmpty: true),
          'name,Mark,number,2',
        );

        expect(oneOf.currentEncodingShape, EncodingShape.complex);
      });
    });

    group('string', () {
      test('string', () {
        final oneOf = NestedAllOfInOneOfNestedAllOfInOneOfModel('Peter');
        expect(oneOf.toJson(), 'Peter');
        expect(oneOf.toForm(explode: true, allowEmpty: true), 'Peter');
        expect(oneOf.toSimple(explode: true, allowEmpty: true), 'Peter');

        expect(oneOf.currentEncodingShape, EncodingShape.simple);
      });
    });
  });

  group('NestedAnyOfInOneOf', () {
    group('AnyOfMixed', () {
      test('integer', () {
        final oneOf = NestedAnyOfInOneOfAnyOfMixed(AnyOfMixed(int: 1));
        expect(oneOf.toJson(), 1);
        expect(oneOf.toForm(explode: true, allowEmpty: true), '1');
        expect(oneOf.toSimple(explode: true, allowEmpty: true), '1');

        expect(oneOf.currentEncodingShape, EncodingShape.simple);
      });

      test('class2', () {
        final oneOf = NestedAnyOfInOneOfAnyOfMixed(
          AnyOfMixed(class2: Class2(number: 2)),
        );
        expect(oneOf.toJson(), {'number': 2});
        expect(oneOf.toForm(explode: true, allowEmpty: true), 'number=2');
        expect(oneOf.toSimple(explode: true, allowEmpty: true), 'number=2');
        expect(oneOf.toSimple(explode: false, allowEmpty: true), 'number,2');

        expect(oneOf.currentEncodingShape, EncodingShape.complex);
      });

      test('enum2', () {
        final oneOf = NestedAnyOfInOneOfAnyOfMixed(
          AnyOfMixed(enum2: Enum2.two),
        );
        expect(oneOf.toJson(), 2);
        expect(oneOf.toForm(explode: true, allowEmpty: true), '2');
        expect(oneOf.toSimple(explode: true, allowEmpty: true), '2');

        expect(oneOf.currentEncodingShape, EncodingShape.simple);
      });

      test('integer, class2, enum2', () {
        final oneOf = NestedAnyOfInOneOfAnyOfMixed(
          AnyOfMixed(int: 1, class2: Class2(number: 2), enum2: Enum2.two),
        );
        expect(oneOf.toJson, throwsA(isA<EncodingException>()));
        expect(
          () => oneOf.toForm(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
        expect(
          () => oneOf.toSimple(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
        expect(
          () => oneOf.toSimple(explode: false, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );

        expect(oneOf.currentEncodingShape, EncodingShape.mixed);
      });
    });

    group('boolean', () {
      test('boolean', () {
        final oneOf = NestedAnyOfInOneOfNestedAnyOfInOneOfModel(false);
        expect(oneOf.toJson(), false);
        expect(oneOf.toForm(explode: true, allowEmpty: true), 'false');
        expect(oneOf.toSimple(explode: true, allowEmpty: true), 'false');

        expect(oneOf.currentEncodingShape, EncodingShape.simple);
      });
    });
  });

  group('DeepNestedOneOf', () {
    group('NestedOneOfInOneOf', () {
      group('OneOfPrimitive', () {
        test('string', () {
          final oneOf = DeepNestedOneOfNestedOneOfInOneOf(
            NestedOneOfInOneOfOneOfPrimitive(
              OneOfPrimitiveOneOfPrimitiveModel('string'),
            ),
          );
          expect(oneOf.toJson(), 'string');
          expect(oneOf.toForm(explode: true, allowEmpty: true), 'string');
          expect(oneOf.toSimple(explode: true, allowEmpty: true), 'string');

          expect(oneOf.currentEncodingShape, EncodingShape.simple);
        });

        test('integer', () {
          final oneOf = DeepNestedOneOfNestedOneOfInOneOf(
            NestedOneOfInOneOfOneOfPrimitive(
              OneOfPrimitiveOneOfPrimitiveModel2(1),
            ),
          );
          expect(oneOf.toJson(), 1);
          expect(oneOf.toForm(explode: true, allowEmpty: true), '1');
          expect(oneOf.toSimple(explode: true, allowEmpty: true), '1');

          expect(oneOf.currentEncodingShape, EncodingShape.simple);
        });
      });

      group('OneOfComplex', () {
        test('Class1', () {
          final oneOf = DeepNestedOneOfNestedOneOfInOneOf(
            NestedOneOfInOneOfOneOfComplex(
              OneOfComplexClass1(Class1(name: 'Mark')),
            ),
          );
          expect(oneOf.toJson(), {'name': 'Mark'});
          expect(oneOf.toForm(explode: true, allowEmpty: true), 'name=Mark');
          expect(oneOf.toSimple(explode: true, allowEmpty: true), 'name=Mark');

          expect(oneOf.currentEncodingShape, EncodingShape.complex);
        });

        test('Class2', () {
          final oneOf = DeepNestedOneOfNestedOneOfInOneOf(
            NestedOneOfInOneOfOneOfComplex(
              OneOfComplexClass2(Class2(number: 2)),
            ),
          );
          expect(oneOf.toJson(), {'number': 2});
          expect(oneOf.toForm(explode: true, allowEmpty: true), 'number=2');
          expect(oneOf.toSimple(explode: true, allowEmpty: true), 'number=2');
          expect(oneOf.toSimple(explode: false, allowEmpty: true), 'number,2');

          expect(oneOf.currentEncodingShape, EncodingShape.complex);
        });
      });
    });

    group('Class1', () {
      test('Class1', () {
        final oneOf = DeepNestedOneOfClass1(Class1(name: 'Mark'));
        expect(oneOf.toJson(), {'name': 'Mark'});
        expect(oneOf.toForm(explode: true, allowEmpty: true), 'name=Mark');
        expect(oneOf.toSimple(explode: true, allowEmpty: true), 'name=Mark');

        expect(oneOf.currentEncodingShape, EncodingShape.complex);
      });
    });
  });

  group('TowLevelOneOf', () {
    group('oneOf', () {
      test('string', () {
        final oneOf = TwoLevelOneOfTwoLevelOneOfModel(
          TwoLevelOneOfModelTwoLevelOneOfOneOf('Mark'),
        );
        expect(oneOf.toJson(), 'Mark');
        expect(oneOf.toForm(explode: true, allowEmpty: true), 'Mark');
        expect(oneOf.toSimple(explode: true, allowEmpty: true), 'Mark');

        expect(oneOf.currentEncodingShape, EncodingShape.simple);
      });

      test('integer', () {
        final oneOf = TwoLevelOneOfTwoLevelOneOfModel(
          TwoLevelOneOfModelTwoLevelOneOfOneOfModel(1),
        );
        expect(oneOf.toJson(), 1);
        expect(oneOf.toForm(explode: true, allowEmpty: true), '1');
        expect(oneOf.toSimple(explode: true, allowEmpty: true), '1');

        expect(oneOf.currentEncodingShape, EncodingShape.simple);
      });
    });

    group('boolean', () {
      test('boolean', () {
        final oneOf = TwoLevelOneOfTwoLevelOneOfModel2(false);
        expect(oneOf.toJson(), false);
        expect(oneOf.toForm(explode: true, allowEmpty: true), 'false');
        expect(oneOf.toSimple(explode: true, allowEmpty: true), 'false');

        expect(oneOf.currentEncodingShape, EncodingShape.simple);
      });
    });
  });

  group('TwoLevelMixedOneOfAllOf', () {
    group('allOf', () {
      test('allOf', () {
        final oneOf = TwoLevelMixedOneOfAllOfTwoLevelMixedOneOfAllOfModel(
          TwoLevelMixedOneOfAllOfModel(
            class1: Class1(name: 'Mark'),
            twoLevelMixedOneOfAllOfAllOf: TwoLevelMixedOneOfAllOfAllOf(
              timestamp: 400,
            ),
          ),
        );
        expect(oneOf.toJson(), {'name': 'Mark', 'timestamp': 400});
        expect(
          oneOf.toForm(explode: true, allowEmpty: true),
          'name=Mark&timestamp=400',
        );
        expect(
          oneOf.toSimple(explode: true, allowEmpty: true),
          'name=Mark,timestamp=400',
        );
        expect(
          oneOf.toSimple(explode: false, allowEmpty: true),
          'name,Mark,timestamp,400',
        );

        expect(oneOf.currentEncodingShape, EncodingShape.complex);
      });
    });

    test('string', () {
      final oneOf = TwoLevelMixedOneOfAllOfTwoLevelMixedOneOfAllOfModel2(
        'Mark',
      );
      expect(oneOf.toJson(), 'Mark');
      expect(oneOf.toForm(explode: true, allowEmpty: true), 'Mark');
      expect(oneOf.toSimple(explode: true, allowEmpty: true), 'Mark');
      expect(oneOf.toSimple(explode: false, allowEmpty: true), 'Mark');

      expect(oneOf.currentEncodingShape, EncodingShape.simple);
    });
  });

  group('ThreeLevelOneOf', () {
    group('oneOf', () {
      group('oneOf', () {
        test('string', () {
          final oneOf = ThreeLevelOneOfThreeLevelOneOfModel(
            ThreeLevelOneOfModelThreeLevelOneOfOneOf(
              ThreeLevelOneOfOneOfThreeLevelOneOfOneOfOneOf('string'),
            ),
          );
          expect(oneOf.toJson(), 'string');
          expect(oneOf.toForm(explode: true, allowEmpty: true), 'string');
          expect(oneOf.toSimple(explode: true, allowEmpty: true), 'string');

          expect(oneOf.currentEncodingShape, EncodingShape.simple);
        });

        test('integer', () {
          final oneOf = ThreeLevelOneOfThreeLevelOneOfModel(
            ThreeLevelOneOfModelThreeLevelOneOfOneOf(
              ThreeLevelOneOfOneOfThreeLevelOneOfOneOfOneOfModel(1),
            ),
          );
          expect(oneOf.toJson(), 1);
          expect(oneOf.toForm(explode: true, allowEmpty: true), '1');
          expect(oneOf.toSimple(explode: true, allowEmpty: true), '1');

          expect(oneOf.currentEncodingShape, EncodingShape.simple);
        });
      });

      group('boolean', () {
        test('boolean', () {
          final oneOf = ThreeLevelOneOfThreeLevelOneOfModel(
            ThreeLevelOneOfModelThreeLevelOneOfOneOfModel(true),
          );
          expect(oneOf.toJson(), true);
          expect(oneOf.toForm(explode: true, allowEmpty: true), 'true');
          expect(oneOf.toSimple(explode: true, allowEmpty: true), 'true');

          expect(oneOf.currentEncodingShape, EncodingShape.simple);
        });
      });
    });

    group('number', () {
      test('number', () {
        final oneOf = ThreeLevelOneOfThreeLevelOneOfModel2(-991);
        expect(oneOf.toJson(), -991);
        expect(oneOf.toForm(explode: true, allowEmpty: true), '-991');
        expect(oneOf.toSimple(explode: true, allowEmpty: true), '-991');

        expect(oneOf.currentEncodingShape, EncodingShape.simple);
      });
    });
  });

  group('ThreeLevelMixedOneOfAllOfAnyOf', () {
    group('allOf', () {
      test('anyfo string', () {
        final oneOf =
            ThreeLevelMixedOneOfAllOfAnyOfThreeLevelMixedOneOfAllOfAnyOfModel(
              ThreeLevelMixedOneOfAllOfAnyOfModel(
                threeLevelMixedOneOfAllOfAnyOfAllOf:
                    ThreeLevelMixedOneOfAllOfAnyOfAllOf(string: 'string'),
                threeLevelMixedOneOfAllOfAnyOfAllOfModel:
                    ThreeLevelMixedOneOfAllOfAnyOfAllOfModel(flag: false),
              ),
            );

        expect(oneOf.toJson, throwsA(isA<EncodingException>()));
        expect(
          () => oneOf.toForm(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
        expect(
          () => oneOf.toSimple(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );

        expect(oneOf.currentEncodingShape, EncodingShape.mixed);
      });

      test('anyof integer', () {
        final oneOf =
            ThreeLevelMixedOneOfAllOfAnyOfThreeLevelMixedOneOfAllOfAnyOfModel(
              ThreeLevelMixedOneOfAllOfAnyOfModel(
                threeLevelMixedOneOfAllOfAnyOfAllOf:
                    ThreeLevelMixedOneOfAllOfAnyOfAllOf(int: 123),
                threeLevelMixedOneOfAllOfAnyOfAllOfModel:
                    ThreeLevelMixedOneOfAllOfAnyOfAllOfModel(flag: false),
              ),
            );
        expect(oneOf.toJson, throwsA(isA<EncodingException>()));
        expect(
          () => oneOf.toForm(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
        expect(
          () => oneOf.toSimple(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );

        expect(oneOf.currentEncodingShape, EncodingShape.mixed);
      });
    });

    group('Class1', () {
      test('Class1', () {
        final oneOf = ThreeLevelMixedOneOfAllOfAnyOfClass1(
          Class1(name: 'Mark'),
        );
        expect(oneOf.toJson(), {'name': 'Mark'});
        expect(oneOf.toForm(explode: true, allowEmpty: true), 'name=Mark');
        expect(oneOf.toSimple(explode: true, allowEmpty: true), 'name=Mark');
      });
    });
  });

  group('ThreeLevelWithRefs', () {
    group('TwoLevelOneOf', () {
      test('string', () {
        final oneOf = ThreeLevelWithRefsTwoLevelOneOf(
          TwoLevelOneOfTwoLevelOneOfModel(
            TwoLevelOneOfModelTwoLevelOneOfOneOf('string'),
          ),
        );
        expect(oneOf.toJson(), 'string');
        expect(oneOf.toForm(explode: true, allowEmpty: true), 'string');
        expect(oneOf.toSimple(explode: true, allowEmpty: true), 'string');

        expect(oneOf.currentEncodingShape, EncodingShape.simple);
      });

      test('integer', () {
        final oneOf = ThreeLevelWithRefsTwoLevelOneOf(
          TwoLevelOneOfTwoLevelOneOfModel(
            TwoLevelOneOfModelTwoLevelOneOfOneOfModel(1),
          ),
        );
        expect(oneOf.toJson(), 1);
        expect(oneOf.toForm(explode: true, allowEmpty: true), '1');
        expect(oneOf.toSimple(explode: true, allowEmpty: true), '1');

        expect(oneOf.currentEncodingShape, EncodingShape.simple);
      });
    });

    group('TwoLevelAllOf', () {});

    group('string', () {
      test('string', () {
        final oneOf = ThreeLevelWithRefsThreeLevelWithRefsModel('string');
        expect(oneOf.toJson(), 'string');
        expect(oneOf.toForm(explode: true, allowEmpty: true), 'string');
        expect(oneOf.toSimple(explode: true, allowEmpty: true), 'string');

        expect(oneOf.currentEncodingShape, EncodingShape.simple);
      });
    });
  });

  group('ComplexNestedMix2', () {
    test('allOf', () {
      final oneOf = ComplexNestedMix2ComplexNestedMix2Model(
        ComplexNestedMix2Model(
          class1: Class1(name: 'Mark'),
          complexNestedMix2AllOf: ComplexNestedMix2AllOf(
            extra: 123,
          ),
        ),
      );
      expect(oneOf.toJson(), {'name': 'Mark', 'extra': 123});
      expect(oneOf.toForm(explode: true, allowEmpty: true), 'name=Mark&extra=123');
      expect(oneOf.toSimple(explode: true, allowEmpty: true), 'name=Mark,extra=123');
      expect(oneOf.toSimple(explode: false, allowEmpty: true), 'name,Mark,extra,123');

      expect(oneOf.currentEncodingShape, EncodingShape.complex);
    });

    test('Enum1', () {
      final oneOf = ComplexNestedMix2Enum1(Enum1.value2);
      expect(oneOf.toJson(), 'value2');
      expect(oneOf.toForm(explode: true, allowEmpty: true), 'value2');
      expect(oneOf.toSimple(explode: true, allowEmpty: true), 'value2');

      expect(oneOf.currentEncodingShape, EncodingShape.simple);
    });
  });
}
