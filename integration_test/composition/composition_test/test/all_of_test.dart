import 'package:composition_api/composition_api.dart';
import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  group('AllOfPrimitive', () {
    test('AllOfPrimitive', () {
      final allOf = AllOfPrimitive(
        allOfPrimitiveModel: AllOfPrimitiveModel(count: 1),
        allOfPrimitiveModel2: AllOfPrimitiveModel2(id: '1'),
      );

      expect(allOf.toJson(), {'id': '1', 'count': 1});
      expect(allOf.toForm(explode: true, allowEmpty: true), 'id=1&count=1');
      expect(allOf.toSimple(explode: true, allowEmpty: true), 'id=1,count=1');
      expect(allOf.toSimple(explode: false, allowEmpty: true), 'id,1,count,1');

      expect(allOf.currentEncodingShape, EncodingShape.complex);
    });
  });

  group('AllOfComplex', () {
    test('AllOfComplex', () {
      final allOf = AllOfComplex(
        class1: Class1(name: '1'),
        class2: Class2(number: 1),
      );
      expect(allOf.toJson(), {'name': '1', 'number': 1});
      expect(allOf.toForm(explode: true, allowEmpty: true), 'name=1&number=1');
      expect(
        allOf.toSimple(explode: true, allowEmpty: true),
        'name=1,number=1',
      );
      expect(
        allOf.toSimple(explode: false, allowEmpty: true),
        'name,1,number,1',
      );

      expect(allOf.currentEncodingShape, EncodingShape.complex);
    });
  });

  group('AllOfEnum', () {
    test('AllOfEnum', () {
      final allOf = AllOfEnum(
        allOfEnumModel: AllOfEnumModel(status: Enum1.value1),
        allOfEnumModel2: AllOfEnumModel2(priority: Enum2.one),
      );
      expect(allOf.toJson(), {'status': 'value1', 'priority': 1});
      expect(
        allOf.toForm(explode: true, allowEmpty: true),
        'status=value1&priority=1',
      );
      expect(
        allOf.toSimple(explode: true, allowEmpty: true),
        'status=value1,priority=1',
      );

      expect(allOf.currentEncodingShape, EncodingShape.complex);
    });
  });

  group('AllOfMixed', () {
    test('AllOfMixed', () {
      final allOf = AllOfMixed(
        string: 'hello, world!',
        class1: Class1(name: '1'),
      );
      expect(allOf.toJson, throwsA(isA<EncodingException>()));
      expect(
        () => allOf.toForm(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
      expect(
        () => allOf.toSimple(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
    });
  });

  group('NestedAllOfInAllOf', () {
    test('NestedAllOfInAllOf', () {
      final allOf = NestedAllOfInAllOf(
        allOfComplex: AllOfComplex(
          class1: Class1(name: 'Albert'),
          class2: Class2(number: 1),
        ),
        nestedAllOfInAllOfModel: NestedAllOfInAllOfModel(extra: 'extra'),
      );

      expect(allOf.toJson(), {'name': 'Albert', 'number': 1, 'extra': 'extra'});
      expect(
        allOf.toForm(explode: true, allowEmpty: true),
        'name=Albert&number=1&extra=extra',
      );
      expect(
        allOf.toSimple(explode: true, allowEmpty: true),
        'name=Albert,number=1,extra=extra',
      );
      expect(
        allOf.toSimple(explode: false, allowEmpty: true),
        'name,Albert,number,1,extra,extra',
      );

      expect(allOf.currentEncodingShape, EncodingShape.complex);
    });
  });

  group('NestedOneOfInAllOf', () {
    test('string', () {
      final allOf = NestedOneOfInAllOf(
        oneOfPrimitive: OneOfPrimitiveString('hello, world!'),
        nestedOneOfInAllOfModel: NestedOneOfInAllOfModel(metadata: 'extra'),
      );

      expect(allOf.toJson, throwsA(isA<EncodingException>()));
      expect(
        () => allOf.toForm(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
      expect(
        () => allOf.toSimple(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );

      expect(allOf.currentEncodingShape, EncodingShape.mixed);
    });

    test('integer', () {
      final allOf = NestedOneOfInAllOf(
        oneOfPrimitive: OneOfPrimitiveInt(-848),
        nestedOneOfInAllOfModel: NestedOneOfInAllOfModel(metadata: 'extra'),
      );

      expect(allOf.toJson, throwsA(isA<EncodingException>()));
      expect(
        () => allOf.toForm(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
      expect(
        () => allOf.toSimple(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );

      expect(allOf.currentEncodingShape, EncodingShape.mixed);
    });
  });

  group('TwoLevelAllOf', () {
    test('TwoLevelAllOf', () {
      final allOf = TwoLevelAllOf(
        twoLevelAllOfAllOfModel: TwoLevelAllOfAllOfModel(
          twoLevelAllOfAllOfModel3: TwoLevelAllOfAllOfModel3(id: '123'),
          twoLevelAllOfAllOfModel2: TwoLevelAllOfAllOfModel2(name: 'Albert'),
        ),
        twoLevelAllOfModel: TwoLevelAllOfModel(active: true),
      );

      expect(allOf.toJson(), {'id': '123', 'name': 'Albert', 'active': true});
      expect(
        allOf.toForm(explode: true, allowEmpty: true),
        'id=123&name=Albert&active=true',
      );
      expect(
        allOf.toSimple(explode: true, allowEmpty: true),
        'id=123,name=Albert,active=true',
      );
      expect(
        allOf.toSimple(explode: false, allowEmpty: true),
        'id,123,name,Albert,active,true',
      );

      expect(allOf.currentEncodingShape, EncodingShape.complex);
    });
  });

  group('ThreeLevelAllOf', () {
    test('ThreeLevelAllOf', () {
      final allOf = ThreeLevelAllOf(
        threeLevelAllOfAllOfModel: ThreeLevelAllOfAllOfModel(
          threeLevelAllOfAllOfAllOfModel: ThreeLevelAllOfAllOfAllOfModel(
            threeLevelAllOfAllOfAllOfModel3: ThreeLevelAllOfAllOfAllOfModel3(
              id: '123',
            ),
            threeLevelAllOfAllOfAllOfModel2: ThreeLevelAllOfAllOfAllOfModel2(
              name: 'Albert',
            ),
          ),
          threeLevelAllOfAllOfModel2: ThreeLevelAllOfAllOfModel2(
            email: 'albert@example.com',
          ),
        ),
        threeLevelAllOfModel: ThreeLevelAllOfModel(verified: true),
      );

      expect(allOf.toJson(), {
        'id': '123',
        'name': 'Albert',
        'email': 'albert@example.com',
        'verified': true,
      });
      expect(
        allOf.toForm(explode: true, allowEmpty: true),
        'id=123&name=Albert&email=albert%40example.com&verified=true',
      );
      expect(
        allOf.toSimple(explode: true, allowEmpty: true),
        'id=123,name=Albert,email=albert%40example.com,verified=true',
      );
      expect(
        allOf.toSimple(explode: false, allowEmpty: true),
        'id,123,name,Albert,email,albert%40example.com,verified,true',
      );

      expect(allOf.currentEncodingShape, EncodingShape.complex);
    });
  });

  group('TwoLevelMixedAllOfAnyOf', () {
    test('ingeger', () {
      final allOf = TwoLevelMixedAllOfAnyOf(
        twoLevelMixedAllOfAnyOfModel: TwoLevelMixedAllOfAnyOfModel(int: 1),
        twoLevelMixedAllOfAnyOfModel2: TwoLevelMixedAllOfAnyOfModel2(
          metadata: 'extra',
        ),
      );

      expect(allOf.toJson, throwsA(isA<EncodingException>()));
      expect(
        () => allOf.toForm(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
      expect(
        () => allOf.toSimple(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );

      expect(allOf.currentEncodingShape, EncodingShape.mixed);
    });

    test('string', () {
      final allOf = TwoLevelMixedAllOfAnyOf(
        twoLevelMixedAllOfAnyOfModel: TwoLevelMixedAllOfAnyOfModel(
          string: 'extra',
        ),
        twoLevelMixedAllOfAnyOfModel2: TwoLevelMixedAllOfAnyOfModel2(
          metadata: 'extra',
        ),
      );

      expect(allOf.toJson, throwsA(isA<EncodingException>()));
      expect(
        () => allOf.toForm(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
      expect(
        () => allOf.toSimple(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
    });

    test('integeger and string', () {
      final allOf = TwoLevelMixedAllOfAnyOf(
        twoLevelMixedAllOfAnyOfModel: TwoLevelMixedAllOfAnyOfModel(
          int: 1,
          string: 'extra',
        ),
        twoLevelMixedAllOfAnyOfModel2: TwoLevelMixedAllOfAnyOfModel2(
          metadata: 'extra',
        ),
      );

      expect(allOf.toJson, throwsA(isA<EncodingException>()));
      expect(
        () => allOf.toForm(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
      expect(
        () => allOf.toSimple(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );

      expect(allOf.currentEncodingShape, EncodingShape.mixed);
    });
  });

  group('ThreeLevelMixedAllOfOneOfAnyOf', () {
    test('enum1', () {
      final allOf = ThreeLevelMixedAllOfOneOfAnyOf(
        threeLevelMixedAllOfOneOfAnyOfOneOfModel:
            ThreeLevelMixedAllOfOneOfAnyOfOneOfModelAnyOf(
              ThreeLevelMixedAllOfOneOfAnyOfOneOfAnyOfModel(
                enum1: Enum1.value1,
              ),
            ),
        threeLevelMixedAllOfOneOfAnyOfModel:
            ThreeLevelMixedAllOfOneOfAnyOfModel(metadata: 'asdf'),
      );

      expect(allOf.toJson, throwsA(isA<EncodingException>()));
      expect(
        () => allOf.toForm(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
      expect(
        () => allOf.toSimple(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );

      expect(allOf.currentEncodingShape, EncodingShape.mixed);
    });

    test('class1', () {
      final allOf = ThreeLevelMixedAllOfOneOfAnyOf(
        threeLevelMixedAllOfOneOfAnyOfOneOfModel:
            ThreeLevelMixedAllOfOneOfAnyOfOneOfModelAnyOf(
              ThreeLevelMixedAllOfOneOfAnyOfOneOfAnyOfModel(
                class1: Class1(name: 'qwerty'),
              ),
            ),
        threeLevelMixedAllOfOneOfAnyOfModel:
            ThreeLevelMixedAllOfOneOfAnyOfModel(metadata: 'asdf'),
      );

      expect(allOf.toJson(), {'name': 'qwerty', 'metadata': 'asdf'});
      expect(
        allOf.toForm(explode: true, allowEmpty: true),
        'name=qwerty&metadata=asdf',
      );
      expect(
        allOf.toSimple(explode: true, allowEmpty: true),
        'name=qwerty,metadata=asdf',
      );
      expect(
        allOf.toSimple(explode: false, allowEmpty: true),
        'name,qwerty,metadata,asdf',
      );

      expect(allOf.currentEncodingShape, EncodingShape.complex);
    });

    test('string', () {
      final allOf = ThreeLevelMixedAllOfOneOfAnyOf(
        threeLevelMixedAllOfOneOfAnyOfOneOfModel:
            ThreeLevelMixedAllOfOneOfAnyOfOneOfModelString('qwerty'),
        threeLevelMixedAllOfOneOfAnyOfModel:
            ThreeLevelMixedAllOfOneOfAnyOfModel(metadata: 'asdf'),
      );

      expect(allOf.toJson, throwsA(isA<EncodingException>()));
      expect(
        () => allOf.toForm(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
      expect(
        () => allOf.toSimple(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );

      expect(allOf.currentEncodingShape, EncodingShape.mixed);
    });
  });

  group('ThreeLevelMixedRefs', () {
    test('with Class1', () {
      final allOf = ThreeLevelMixedRefs(
        twoLevelMixedAllOfAnyOf: TwoLevelMixedAllOfAnyOf(
          twoLevelMixedAllOfAnyOfModel: TwoLevelMixedAllOfAnyOfModel(
            string: 'test',
          ),
          twoLevelMixedAllOfAnyOfModel2: TwoLevelMixedAllOfAnyOfModel2(
            metadata: 'extra',
          ),
        ),
        threeLevelMixedRefsAnyOfModel: ThreeLevelMixedRefsAnyOfModel(
          class1: Class1(name: 'Albert'),
        ),
      );

      expect(allOf.toJson, throwsA(isA<EncodingException>()));
      expect(
        () => allOf.toForm(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
      expect(
        () => allOf.toSimple(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );

      expect(allOf.currentEncodingShape, EncodingShape.mixed);
    });

    test('with integer', () {
      final allOf = ThreeLevelMixedRefs(
        twoLevelMixedAllOfAnyOf: TwoLevelMixedAllOfAnyOf(
          twoLevelMixedAllOfAnyOfModel: TwoLevelMixedAllOfAnyOfModel(int: 42),
          twoLevelMixedAllOfAnyOfModel2: TwoLevelMixedAllOfAnyOfModel2(
            metadata: 'extra',
          ),
        ),
        threeLevelMixedRefsAnyOfModel: ThreeLevelMixedRefsAnyOfModel(int: 123),
      );

      expect(allOf.toJson, throwsA(isA<EncodingException>()));
      expect(
        () => allOf.toForm(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
      expect(
        () => allOf.toSimple(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );

      expect(allOf.currentEncodingShape, EncodingShape.mixed);
    });
  });

  group('ComplexNestedMix', () {
    test('with Class1', () {
      final allOf = ComplexNestedMix(
        complexNestedMixModel: ComplexNestedMixModel($base: 'test'),
        complexNestedMixOneOfModel: ComplexNestedMixOneOfModelClass1(
          Class1(name: 'Albert'),
        ),
      );

      expect(allOf.toJson(), {'base': 'test', 'name': 'Albert'});
      expect(
        allOf.toForm(explode: true, allowEmpty: true),
        'base=test&name=Albert',
      );
      expect(
        allOf.toSimple(explode: true, allowEmpty: true),
        'base=test,name=Albert',
      );
      expect(
        allOf.toSimple(explode: false, allowEmpty: true),
        'base,test,name,Albert',
      );

      expect(allOf.currentEncodingShape, EncodingShape.complex);
    });

    test('with Class2', () {
      final allOf = ComplexNestedMix(
        complexNestedMixModel: ComplexNestedMixModel($base: 'test'),
        complexNestedMixOneOfModel: ComplexNestedMixOneOfModelClass2(
          Class2(number: 42),
        ),
      );

      expect(allOf.toJson(), {'base': 'test', 'number': 42});
      expect(
        allOf.toForm(explode: true, allowEmpty: true),
        'base=test&number=42',
      );
      expect(
        allOf.toSimple(explode: true, allowEmpty: true),
        'base=test,number=42',
      );
      expect(
        allOf.toSimple(explode: false, allowEmpty: true),
        'base,test,number,42',
      );

      expect(allOf.currentEncodingShape, EncodingShape.complex);
    });
  });

  group('MultiLevelNesting', () {
    test('with string level1', () {
      final allOf = MultiLevelNesting(
        multiLevelNestingModel: MultiLevelNestingModel(
          level1: MultiLevelNestingLevel1OneOfModelString('test'),
        ),
        multiLevelNestingModel2: MultiLevelNestingModel2(level2: 42),
      );

      expect(allOf.toJson(), {'level1': 'test', 'level2': 42});
      expect(allOf.toForm(explode: true, allowEmpty: true), 'level2=42');
      expect(allOf.toSimple(explode: true, allowEmpty: true), 'level2=42');
      expect(allOf.toSimple(explode: false, allowEmpty: true), 'level2,42');

      expect(allOf.currentEncodingShape, EncodingShape.complex);
    });

    test('with Class1 level1', () {
      final allOf = MultiLevelNesting(
        multiLevelNestingModel: MultiLevelNestingModel(
          level1: MultiLevelNestingLevel1OneOfModelAnyOf(
            MultiLevelNestingLevel1OneOfAnyOfModel(
              class1: Class1(name: 'Albert'),
            ),
          ),
        ),
        multiLevelNestingModel2: MultiLevelNestingModel2(level2: 42),
      );

      expect(allOf.toJson(), {
        'level1': {'name': 'Albert'},
        'level2': 42,
      });
      expect(
        () => allOf.toForm(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
      expect(
        () => allOf.toSimple(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );

      expect(allOf.currentEncodingShape, EncodingShape.complex);
    });

    test('with Class2 level1', () {
      final allOf = MultiLevelNesting(
        multiLevelNestingModel: MultiLevelNestingModel(
          level1: MultiLevelNestingLevel1OneOfModelAnyOf(
            MultiLevelNestingLevel1OneOfAnyOfModel(class2: Class2(number: 123)),
          ),
        ),
        multiLevelNestingModel2: MultiLevelNestingModel2(level2: 42),
      );

      expect(allOf.toJson(), {
        'level1': {'number': 123},
        'level2': 42,
      });
      expect(
        () => allOf.toForm(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
      expect(
        () => allOf.toSimple(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );

      expect(allOf.currentEncodingShape, EncodingShape.complex);
    });
  });
}
