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
      expect(allOf.toForm(explode: true, allowEmpty: true), 'count=1&id=1');
      expect(allOf.toSimple(explode: true, allowEmpty: true), 'count=1,id=1');
      expect(allOf.toSimple(explode: false, allowEmpty: true), 'count,1,id,1');
      expect(
        allOf.toMatrix('allOf', explode: false, allowEmpty: true),
        ';allOf=count,1,id,1',
      );
      expect(
        allOf.toMatrix('allOf', explode: true, allowEmpty: true),
        ';count=1;id=1',
      );

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
      expect(
        allOf.toMatrix('x', explode: false, allowEmpty: true),
        ';x=name,1,number,1',
      );
      expect(
        allOf.toMatrix('x', explode: true, allowEmpty: true),
        ';name=1;number=1',
      );

      expect(allOf.currentEncodingShape, EncodingShape.complex);
    });
  });

  group('AllOfEnum', () {
    test('AllOfEnum', () {
      final allOf = AllOfEnum(
        allOfEnumModel2: AllOfEnumModel2(status: Enum1.value1),
        allOfEnumModel: AllOfEnumModel(priority: Enum2.one),
      );
      expect(allOf.toJson(), {'status': 'value1', 'priority': 1});
      expect(
        allOf.toForm(explode: true, allowEmpty: true),
        'priority=1&status=value1',
      );
      expect(
        allOf.toSimple(explode: true, allowEmpty: true),
        'priority=1,status=value1',
      );
      expect(
        allOf.toMatrix('1234', explode: false, allowEmpty: true),
        ';1234=priority,1,status,value1',
      );
      expect(
        allOf.toMatrix('1234', explode: true, allowEmpty: true),
        ';priority=1;status=value1',
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
      expect(
        () => allOf.toMatrix('paramName', explode: false, allowEmpty: true),
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
      expect(
        allOf.toMatrix('x', explode: false, allowEmpty: true),
        ';x=name,Albert,number,1,extra,extra',
      );
      expect(
        allOf.toMatrix('x', explode: true, allowEmpty: true),
        ';name=Albert;number=1;extra=extra',
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
      expect(
        () => allOf.toMatrix('name', explode: false, allowEmpty: true),
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
      expect(
        () => allOf.toMatrix('int', explode: false, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );

      expect(allOf.currentEncodingShape, EncodingShape.mixed);
    });
  });

  group('TwoLevelAllOf', () {
    test('TwoLevelAllOf', () {
      final allOf = TwoLevelAllOf(
        twoLevelAllOfAllOfModel: TwoLevelAllOfAllOfModel(
          twoLevelAllOfAllOfModel3: TwoLevelAllOfAllOfModel3(name: 'Albert'),
          twoLevelAllOfAllOfModel2: TwoLevelAllOfAllOfModel2(id: '123'),
        ),
        twoLevelAllOfModel: TwoLevelAllOfModel(active: true),
      );

      expect(allOf.toJson(), {'id': '123', 'name': 'Albert', 'active': true});
      expect(
        allOf.toForm(explode: true, allowEmpty: true),
        'active=true&id=123&name=Albert',
      );
      expect(
        allOf.toSimple(explode: true, allowEmpty: true),
        'active=true,id=123,name=Albert',
      );
      expect(
        allOf.toSimple(explode: false, allowEmpty: true),
        'active,true,id,123,name,Albert',
      );
      expect(
        allOf.toMatrix('x', explode: false, allowEmpty: true),
        ';x=active,true,id,123,name,Albert',
      );
      expect(
        allOf.toMatrix('x', explode: true, allowEmpty: true),
        ';active=true;id=123;name=Albert',
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
              name: 'Albert',
            ),
            threeLevelAllOfAllOfAllOfModel2: ThreeLevelAllOfAllOfAllOfModel2(
              id: '123',
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
        'verified=true&email=albert%40example.com&id=123&name=Albert',
      );
      expect(
        allOf.toSimple(explode: true, allowEmpty: true),
        'verified=true,email=albert%40example.com,id=123,name=Albert',
      );
      expect(
        allOf.toSimple(explode: false, allowEmpty: true),
        'verified,true,email,albert%40example.com,id,123,name,Albert',
      );
      expect(
        allOf.toMatrix('x', explode: false, allowEmpty: true),
        ';x=verified,true,email,albert%40example.com,id,123,name,Albert',
      );
      expect(
        allOf.toMatrix('x', explode: true, allowEmpty: true),
        ';verified=true;email=albert%40example.com;id=123;name=Albert',
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
      expect(
        () => allOf.toMatrix('int', explode: false, allowEmpty: true),
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
      expect(
        () => allOf.toMatrix('string', explode: false, allowEmpty: true),
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
      expect(
        () => allOf.toMatrix('int', explode: false, allowEmpty: true),
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
      expect(
        () => allOf.toMatrix('enum1', explode: false, allowEmpty: true),
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
        'metadata=asdf&name=qwerty',
      );
      expect(
        allOf.toSimple(explode: true, allowEmpty: true),
        'metadata=asdf,name=qwerty',
      );
      expect(
        allOf.toSimple(explode: false, allowEmpty: true),
        'metadata,asdf,name,qwerty',
      );
      expect(
        allOf.toMatrix('x', explode: false, allowEmpty: true),
        ';x=metadata,asdf,name,qwerty',
      );
      expect(
        allOf.toMatrix('x', explode: true, allowEmpty: true),
        ';metadata=asdf;name=qwerty',
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
      expect(
        () => allOf.toMatrix('string', explode: false, allowEmpty: true),
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
      expect(
        () => allOf.toMatrix('x', explode: false, allowEmpty: true),
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
      expect(
        () => allOf.toMatrix('int', explode: false, allowEmpty: true),
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
      expect(
        allOf.toMatrix('complexNestedMix', explode: false, allowEmpty: true),
        ';complexNestedMix=base,test,name,Albert',
      );
      expect(
        allOf.toMatrix('complexNestedMix', explode: true, allowEmpty: true),
        ';base=test;name=Albert',
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
      expect(
        allOf.toMatrix('asdf', explode: false, allowEmpty: true),
        ';asdf=base,test,number,42',
      );
      expect(
        allOf.toMatrix('asdf', explode: true, allowEmpty: true),
        ';base=test;number=42',
      );

      expect(allOf.currentEncodingShape, EncodingShape.complex);
    });
  });

  group('MultiLevelNesting', () {
    test('with string level1', () {
      final allOf = MultiLevelNesting(
        multiLevelNestingModel2: MultiLevelNestingModel2(level2: 42),
        multiLevelNestingModel: MultiLevelNestingModel(
          level1: MultiLevelNestingLevel1OneOfModelString('test'),
        ),
      );

      expect(allOf.toJson(), {'level1': 'test', 'level2': 42});
      expect(
        allOf.toForm(explode: true, allowEmpty: true),
        'level1=test&level2=42',
      );
      expect(
        allOf.toSimple(explode: true, allowEmpty: true),
        'level1=test,level2=42',
      );
      expect(
        allOf.toSimple(explode: false, allowEmpty: true),
        'level1,test,level2,42',
      );
      expect(
        allOf.toMatrix('level1', explode: false, allowEmpty: true),
        ';level1=level1,test,level2,42',
      );
      expect(
        allOf.toMatrix('level1', explode: true, allowEmpty: true),
        ';level1=test;level2=42',
      );

      expect(allOf.currentEncodingShape, EncodingShape.complex);
    });

    test('with Class1 level1', () {
      final allOf = MultiLevelNesting(
        multiLevelNestingModel2: MultiLevelNestingModel2(level2: 42),
        multiLevelNestingModel: MultiLevelNestingModel(
          level1: MultiLevelNestingLevel1OneOfModelAnyOf(
            MultiLevelNestingLevel1OneOfAnyOfModel(
              class1: Class1(name: 'Albert'),
            ),
          ),
        ),
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
      expect(
        () => allOf.toMatrix('level1', explode: false, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );

      expect(allOf.currentEncodingShape, EncodingShape.complex);
    });

    test('with Class2 level1', () {
      final allOf = MultiLevelNesting(
        multiLevelNestingModel2: MultiLevelNestingModel2(level2: 42),
        multiLevelNestingModel: MultiLevelNestingModel(
          level1: MultiLevelNestingLevel1OneOfModelAnyOf(
            MultiLevelNestingLevel1OneOfAnyOfModel(class2: Class2(number: 123)),
          ),
        ),
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
      expect(
        () => allOf.toMatrix('level1', explode: false, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );

      expect(allOf.currentEncodingShape, EncodingShape.complex);
    });
  });

  group('AllOfWithSimpleList', () {
    test('AllOfWithSimpleList', () {
      final allOf = AllOfWithSimpleList(
        allOfWithSimpleListModel: AllOfWithSimpleListModel(ids: [1, 2, 3]),
        allOfWithSimpleListModel2: AllOfWithSimpleListModel2(
          tags: ['tag1', 'tag2', 'tag3'],
        ),
      );

      expect(allOf.toJson(), {
        'ids': [1, 2, 3],
        'tags': ['tag1', 'tag2', 'tag3'],
      });
      expect(
        allOf.toForm(explode: true, allowEmpty: true),
        'ids=1,2,3&tags=tag1,tag2,tag3',
      );
      expect(
        allOf.toSimple(explode: true, allowEmpty: true),
        'ids=1,2,3,tags=tag1,tag2,tag3',
      );
      expect(
        allOf.toSimple(explode: false, allowEmpty: true),
        'ids,1,2,3,tags,tag1,tag2,tag3',
      );
      expect(
        allOf.toMatrix('x', explode: false, allowEmpty: true),
        ';x=ids,1,2,3,tags,tag1,tag2,tag3',
      );
      expect(
        allOf.toMatrix('x', explode: true, allowEmpty: true),
        ';ids=1,2,3;tags=tag1,tag2,tag3',
      );

      expect(allOf.currentEncodingShape, EncodingShape.complex);
    });
  });

  group('AllOfWithMixedLists', () {
    test('AllOfWithMixedLists', () {
      final allOf = AllOfWithMixedLists(
        allOfWithMixedListsModel2: AllOfWithMixedListsModel2(
          users: [Class1(name: 'Albert')],
        ),
        allOfWithMixedListsModel: AllOfWithMixedListsModel(
          tags: ['tag1', 'tag2', 'tag3'],
        ),
      );

      expect(allOf.toJson(), {
        'tags': ['tag1', 'tag2', 'tag3'],
        'users': [
          {'name': 'Albert'},
        ],
      });
      expect(
        () => allOf.toForm(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
      expect(
        () => allOf.toSimple(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
      expect(
        () => allOf.toMatrix('x', explode: false, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );

      expect(allOf.currentEncodingShape, EncodingShape.complex);
    });
  });

  group('AllOfWithEnumList', () {
    test('AllOfWithEnumList', () {
      final allOf = AllOfWithEnumList(
        allOfWithEnumListModel: AllOfWithEnumListModel(
          priorities: [Enum2.one, Enum2.two],
        ),
        allOfWithEnumListModel2: AllOfWithEnumListModel2(
          statuses: [Enum1.value1],
        ),
      );

      expect(allOf.toJson(), {
        'statuses': ['value1'],
        'priorities': [1, 2],
      });
      expect(
        allOf.toForm(explode: true, allowEmpty: true),
        'priorities=1,2&statuses=value1',
      );
      expect(
        allOf.toSimple(explode: true, allowEmpty: true),
        'priorities=1,2,statuses=value1',
      );
      expect(
        allOf.toSimple(explode: false, allowEmpty: true),
        'priorities,1,2,statuses,value1',
      );
      expect(
        allOf.toMatrix('y', explode: false, allowEmpty: true),
        ';y=priorities,1,2,statuses,value1',
      );
      expect(
        allOf.toMatrix('y', explode: true, allowEmpty: true),
        ';priorities=1,2;statuses=value1',
      );

      expect(allOf.currentEncodingShape, EncodingShape.complex);
    });
  });

  group('NestedListInAllOf', () {
    test('NestedListInAllOf', () {
      final allOf = NestedListInAllOf(
        nestedListInAllOfModel: NestedListInAllOfModel(
          matrix: [
            [1, 2, 3],
            [4, 5, 6],
          ],
        ),
        nestedListInAllOfModel2: NestedListInAllOfModel2(name: 'test'),
      );

      expect(allOf.toJson(), {
        'matrix': [
          [1, 2, 3],
          [4, 5, 6],
        ],
        'name': 'test',
      });
      expect(
        () => allOf.toForm(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
      expect(
        () => allOf.toSimple(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
      expect(
        () => allOf.toMatrix('x', explode: false, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );

      expect(allOf.currentEncodingShape, EncodingShape.complex);
    });
  });

  group('ComplexListComposition', () {
    test('enum list', () {
      final allOf = ComplexListComposition(
        complexListCompositionModel: ComplexListCompositionModel(
          simpleList: ['test', 'test2'],
        ),
        complexListCompositionAnyOfModel: ComplexListCompositionAnyOfModel(
          complexListCompositionAnyOfModel3: ComplexListCompositionAnyOfModel3(
            enumList: [Enum1.value1, Enum1.value2],
          ),
        ),
      );

      expect(allOf.toJson(), {
        'simpleList': ['test', 'test2'],
        'enumList': ['value1', 'value2'],
      });
      expect(
        allOf.toForm(explode: true, allowEmpty: true),
        'enumList=value1,value2&simpleList=test,test2',
      );
      expect(
        allOf.toSimple(explode: true, allowEmpty: true),
        'enumList=value1,value2,simpleList=test,test2',
      );
      expect(
        allOf.toSimple(explode: false, allowEmpty: true),
        'enumList,value1,value2,simpleList,test,test2',
      );
      expect(
        allOf.toMatrix('x', explode: false, allowEmpty: true),
        ';x=enumList,value1,value2,simpleList,test,test2',
      );
      expect(
        allOf.toMatrix('x', explode: true, allowEmpty: true),
        ';enumList=value1,value2;simpleList=test,test2',
      );

      expect(allOf.currentEncodingShape, EncodingShape.complex);
    });

    test('complex list', () {
      final allOf = ComplexListComposition(
        complexListCompositionModel: ComplexListCompositionModel(
          simpleList: ['test', 'test2'],
        ),
        complexListCompositionAnyOfModel: ComplexListCompositionAnyOfModel(
          complexListCompositionAnyOfModel2: ComplexListCompositionAnyOfModel2(
            complexList: [
              Class1(name: 'Albert'),
              Class1(name: 'Bob'),
            ],
          ),
        ),
      );

      expect(allOf.toJson(), {
        'simpleList': ['test', 'test2'],
        'complexList': [{'name': 'Albert'}, {'name': 'Bob'}],
      });
      expect(
        () => allOf.toForm(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
      expect(
        () => allOf.toSimple(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
      expect(
        () => allOf.toMatrix('x', explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );

      expect(allOf.currentEncodingShape, EncodingShape.complex);
    });

    test('both lists', () {
      final allOf = ComplexListComposition(
        complexListCompositionModel: ComplexListCompositionModel(
          simpleList: ['test', 'test2'],
        ),
        complexListCompositionAnyOfModel: ComplexListCompositionAnyOfModel(
          complexListCompositionAnyOfModel3: ComplexListCompositionAnyOfModel3(enumList: [Enum1.value1, Enum1.value2]),
          complexListCompositionAnyOfModel2: ComplexListCompositionAnyOfModel2(complexList: [Class1(name: 'Albert'), Class1(name: 'Bob')]),
        ),
      );

      expect(allOf.toJson(), {
        'simpleList': ['test', 'test2'],
        'complexList': [{'name': 'Albert'}, {'name': 'Bob'}],
        'enumList': ['value1', 'value2'],
      });
      expect(
        () => allOf.toForm(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
      expect(
        () => allOf.toSimple(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
      expect(
        () => allOf.toMatrix('x', explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );

      expect(allOf.currentEncodingShape, EncodingShape.complex);
    });
  });

  group('AllOfWithListOfComposites', () {
    test('AllOfWithListOfComposites', () {
      final allOf = AllOfWithListOfComposites(
        allOfWithListOfCompositesModel2: AllOfWithListOfCompositesModel2(
          items: [AllOfWithListOfCompositesItemsArrayOneOfModelClass1(Class1(name: 'Albert')), AllOfWithListOfCompositesItemsArrayOneOfModelClass2(Class2(number: 123))],
        ), 
        allOfWithListOfCompositesModel: AllOfWithListOfCompositesModel(
          count: 948894984
        ),
      );

      expect(allOf.toJson(), {
        'items': [{'name': 'Albert'}, {'number': 123}],
        'count': 948894984,
      });
      expect(
        () =>allOf.toForm(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
      expect(
        () =>allOf.toSimple(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
      expect(
        () =>allOf.toSimple(explode: false, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
      expect(
        () =>allOf.toMatrix('x', explode: false, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
      expect(
        () =>allOf.toMatrix('x', explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );

      expect(allOf.currentEncodingShape, EncodingShape.complex);
    });
  });

  // group('AllOfDoubleList', () {
  //   test('AllOfDoubleList', () {
  //     final allOf = AllOfDoubleList(
  //       list: [DateTime(2021, 1, 1).toTimeZonedIso8601String(), DateTime(2021, 1, 2).toTimeZonedIso8601String()],
  //         list2: [DateTime(2021, 1, 1), DateTime(2021, 1, 2)],
  //     );

  //     expect(allOf.toJson(), ['2021-01-01T00:00:00.000Z', '2021-01-02T00:00:00.000Z']);
  // });

  // group('AllOfOneOfDoubleList', () {});
}
