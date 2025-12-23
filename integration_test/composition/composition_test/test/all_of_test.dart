import 'package:composition_api/composition_api.dart';
import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  group('AllOfPrimitive', () {
    late AllOfPrimitive allOf;

    setUp(() {
      allOf = const AllOfPrimitive(
        allOfPrimitiveModel: AllOfPrimitiveModel(count: 1),
        allOfPrimitiveModel2: AllOfPrimitiveModel2(id: '1'),
      );
    });

    test('toJson', () {
      expect(allOf.toJson(), {'id': '1', 'count': 1});
    });

    test('json roundtrip', () {
      final json = allOf.toJson();
      final reconstructed = AllOfPrimitive.fromJson(json);
      expect(reconstructed, allOf);
    });

    test('toForm - explode true', () {
      expect(allOf.toForm(explode: true, allowEmpty: true), 'count=1&id=1');
    });

    test('form roundtrip - explode true', () {
      final form = allOf.toForm(explode: true, allowEmpty: true);
      final reconstructed = AllOfPrimitive.fromForm(form, explode: true);
      expect(reconstructed, allOf);
    });

    test('toForm - explode false', () {
      expect(allOf.toForm(explode: false, allowEmpty: true), 'count,1,id,1');
    });

    test('form roundtrip - explode false', () {
      final form = allOf.toForm(explode: false, allowEmpty: true);
      final reconstructed = AllOfPrimitive.fromForm(form, explode: false);
      expect(reconstructed, allOf);
    });

    test('toSimple - explode true', () {
      expect(allOf.toSimple(explode: true, allowEmpty: true), 'count=1,id=1');
    });

    test('simple roundtrip - explode true', () {
      final simple = allOf.toSimple(explode: true, allowEmpty: true);
      final reconstructed = AllOfPrimitive.fromSimple(simple, explode: true);
      expect(reconstructed, allOf);
    });

    test('toSimple - explode false', () {
      expect(allOf.toSimple(explode: false, allowEmpty: true), 'count,1,id,1');
    });

    test('simple roundtrip - explode false', () {
      final simple = allOf.toSimple(explode: false, allowEmpty: true);
      final reconstructed = AllOfPrimitive.fromSimple(simple, explode: false);
      expect(reconstructed, allOf);
    });

    test('toMatrix - explode false', () {
      expect(
        allOf.toMatrix('allOf', explode: false, allowEmpty: true),
        ';allOf=count,1,id,1',
      );
    });

    test('toMatrix - explode true', () {
      expect(
        allOf.toMatrix('allOf', explode: true, allowEmpty: true),
        ';count=1;id=1',
      );
    });

    test('toLabel - explode true', () {
      expect(allOf.toLabel(explode: true, allowEmpty: true), '.count=1.id=1');
    });

    test('toLabel - explode false', () {
      expect(allOf.toLabel(explode: false, allowEmpty: true), '.count,1,id,1');
    });

    test('currentEncodingShape', () {
      expect(allOf.currentEncodingShape, EncodingShape.complex);
    });
  });

  group('AllOfPrimitive with URL special characters', () {
    late AllOfPrimitive allOf;

    setUp(() {
      allOf = const AllOfPrimitive(
        allOfPrimitiveModel: AllOfPrimitiveModel(count: 1),
        allOfPrimitiveModel2: AllOfPrimitiveModel2(id: 'foo%bar&baz=qux'),
      );
    });

    test('toJson', () {
      expect(allOf.toJson(), {'id': 'foo%bar&baz=qux', 'count': 1});
    });

    test('json roundtrip', () {
      final json = allOf.toJson();
      final reconstructed = AllOfPrimitive.fromJson(json);
      expect(reconstructed, allOf);
    });

    test('toForm - explode true', () {
      expect(
        allOf.toForm(explode: true, allowEmpty: true),
        'count=1&id=foo%25bar%26baz%3Dqux',
      );
    });

    test('form roundtrip - explode true', () {
      final form = allOf.toForm(explode: true, allowEmpty: true);
      final reconstructed = AllOfPrimitive.fromForm(form, explode: true);
      expect(reconstructed, allOf);
    });

    test('toForm - explode false', () {
      expect(
        allOf.toForm(explode: false, allowEmpty: true),
        'count,1,id,foo%25bar%26baz%3Dqux',
      );
    });

    test('form roundtrip - explode false', () {
      final form = allOf.toForm(explode: false, allowEmpty: true);
      final reconstructed = AllOfPrimitive.fromForm(form, explode: false);
      expect(reconstructed, allOf);
    });

    test('toSimple - explode true', () {
      expect(
        allOf.toSimple(explode: true, allowEmpty: true),
        'count=1,id=foo%25bar%26baz%3Dqux',
      );
    });

    test('simple roundtrip - explode true', () {
      final simple = allOf.toSimple(explode: true, allowEmpty: true);
      final reconstructed = AllOfPrimitive.fromSimple(simple, explode: true);
      expect(reconstructed, allOf);
    });

    test('toSimple - explode false', () {
      expect(
        allOf.toSimple(explode: false, allowEmpty: true),
        'count,1,id,foo%25bar%26baz%3Dqux',
      );
    });

    test('simple roundtrip - explode false', () {
      final simple = allOf.toSimple(explode: false, allowEmpty: true);
      final reconstructed = AllOfPrimitive.fromSimple(simple, explode: false);
      expect(reconstructed, allOf);
    });

    test('toMatrix - explode false', () {
      expect(
        allOf.toMatrix('allOf', explode: false, allowEmpty: true),
        ';allOf=count,1,id,foo%25bar%26baz%3Dqux',
      );
    });

    test('toMatrix - explode true', () {
      expect(
        allOf.toMatrix('allOf', explode: true, allowEmpty: true),
        ';count=1;id=foo%25bar%26baz%3Dqux',
      );
    });

    test('toLabel - explode true', () {
      expect(
        allOf.toLabel(explode: true, allowEmpty: true),
        '.count=1.id=foo%25bar%26baz%3Dqux',
      );
    });

    test('toLabel - explode false', () {
      expect(
        allOf.toLabel(explode: false, allowEmpty: true),
        '.count,1,id,foo%25bar%26baz%3Dqux',
      );
    });

    test('currentEncodingShape', () {
      expect(allOf.currentEncodingShape, EncodingShape.complex);
    });
  });

  group('AllOfComplex', () {
    late AllOfComplex allOf;

    setUp(() {
      allOf = const AllOfComplex(
        class1: Class1(name: '1'),
        class2: Class2(number: 1),
      );
    });

    test('toJson', () {
      expect(allOf.toJson(), {'name': '1', 'number': 1});
    });

    test('json roundtrip', () {
      final json = allOf.toJson();
      final reconstructed = AllOfComplex.fromJson(json);
      expect(reconstructed, allOf);
    });

    test('toForm - explode true', () {
      expect(allOf.toForm(explode: true, allowEmpty: true), 'name=1&number=1');
    });

    test('form roundtrip - explode true', () {
      final form = allOf.toForm(explode: true, allowEmpty: true);
      final reconstructed = AllOfComplex.fromForm(form, explode: true);
      expect(reconstructed, allOf);
    });

    test('toForm - explode false', () {
      expect(allOf.toForm(explode: false, allowEmpty: true), 'name,1,number,1');
    });

    test('form roundtrip - explode false', () {
      final form = allOf.toForm(explode: false, allowEmpty: true);
      final reconstructed = AllOfComplex.fromForm(form, explode: false);
      expect(reconstructed, allOf);
    });

    test('toSimple - explode true', () {
      expect(
        allOf.toSimple(explode: true, allowEmpty: true),
        'name=1,number=1',
      );
    });

    test('simple roundtrip - explode true', () {
      final simple = allOf.toSimple(explode: true, allowEmpty: true);
      final reconstructed = AllOfComplex.fromSimple(simple, explode: true);
      expect(reconstructed, allOf);
    });

    test('toSimple - explode false', () {
      expect(
        allOf.toSimple(explode: false, allowEmpty: true),
        'name,1,number,1',
      );
    });

    test('simple roundtrip - explode false', () {
      final simple = allOf.toSimple(explode: false, allowEmpty: true);
      final reconstructed = AllOfComplex.fromSimple(simple, explode: false);
      expect(reconstructed, allOf);
    });

    test('toMatrix - explode false', () {
      expect(
        allOf.toMatrix('x', explode: false, allowEmpty: true),
        ';x=name,1,number,1',
      );
    });

    test('toMatrix - explode true', () {
      expect(
        allOf.toMatrix('x', explode: true, allowEmpty: true),
        ';name=1;number=1',
      );
    });

    test('toLabel - explode true', () {
      expect(
        allOf.toLabel(explode: true, allowEmpty: true),
        '.name=1.number=1',
      );
    });

    test('toLabel - explode false', () {
      expect(
        allOf.toLabel(explode: false, allowEmpty: true),
        '.name,1,number,1',
      );
    });

    test('currentEncodingShape', () {
      expect(allOf.currentEncodingShape, EncodingShape.complex);
    });
  });

  group('AllOfComplex with URL special characters', () {
    late AllOfComplex allOf;

    setUp(() {
      allOf = const AllOfComplex(
        class1: Class1(name: '50% off! Buy now & save'),
        class2: Class2(number: 99),
      );
    });

    test('toJson', () {
      expect(allOf.toJson(), {'name': '50% off! Buy now & save', 'number': 99});
    });

    test('json roundtrip', () {
      final json = allOf.toJson();
      final reconstructed = AllOfComplex.fromJson(json);
      expect(reconstructed, allOf);
    });

    test('toForm - explode true', () {
      expect(
        allOf.toForm(explode: true, allowEmpty: true),
        'name=50%25%20off!%20Buy%20now%20%26%20save&number=99',
      );
    });

    test('form roundtrip - explode true', () {
      final form = allOf.toForm(explode: true, allowEmpty: true);
      final reconstructed = AllOfComplex.fromForm(form, explode: true);
      expect(reconstructed, allOf);
    });

    test('toForm - explode false', () {
      expect(
        allOf.toForm(explode: false, allowEmpty: true),
        'name,50%25%20off!%20Buy%20now%20%26%20save,number,99',
      );
    });

    test('form roundtrip - explode false', () {
      final form = allOf.toForm(explode: false, allowEmpty: true);
      final reconstructed = AllOfComplex.fromForm(form, explode: false);
      expect(reconstructed, allOf);
    });

    test('toSimple - explode true', () {
      expect(
        allOf.toSimple(explode: true, allowEmpty: true),
        'name=50%25%20off!%20Buy%20now%20%26%20save,number=99',
      );
    });

    test('simple roundtrip - explode true', () {
      final simple = allOf.toSimple(explode: true, allowEmpty: true);
      final reconstructed = AllOfComplex.fromSimple(simple, explode: true);
      expect(reconstructed, allOf);
    });

    test('toSimple - explode false', () {
      expect(
        allOf.toSimple(explode: false, allowEmpty: true),
        'name,50%25%20off!%20Buy%20now%20%26%20save,number,99',
      );
    });

    test('simple roundtrip - explode false', () {
      final simple = allOf.toSimple(explode: false, allowEmpty: true);
      final reconstructed = AllOfComplex.fromSimple(simple, explode: false);
      expect(reconstructed, allOf);
    });

    test('toMatrix - explode false', () {
      expect(
        allOf.toMatrix('x', explode: false, allowEmpty: true),
        ';x=name,50%25%20off!%20Buy%20now%20%26%20save,number,99',
      );
    });

    test('toMatrix - explode true', () {
      expect(
        allOf.toMatrix('x', explode: true, allowEmpty: true),
        ';name=50%25%20off!%20Buy%20now%20%26%20save;number=99',
      );
    });

    test('toLabel - explode true', () {
      expect(
        allOf.toLabel(explode: true, allowEmpty: true),
        '.name=50%25%20off!%20Buy%20now%20%26%20save.number=99',
      );
    });

    test('toLabel - explode false', () {
      expect(
        allOf.toLabel(explode: false, allowEmpty: true),
        '.name,50%25%20off!%20Buy%20now%20%26%20save,number,99',
      );
    });

    test('currentEncodingShape', () {
      expect(allOf.currentEncodingShape, EncodingShape.complex);
    });
  });

  group('AllOfEnum', () {
    late AllOfEnum allOf;

    setUp(() {
      allOf = const AllOfEnum(
        allOfEnumModel2: AllOfEnumModel2(status: Enum1.value1),
        allOfEnumModel: AllOfEnumModel(priority: Enum2.one),
      );
    });

    test('toJson', () {
      expect(allOf.toJson(), {'status': 'value1', 'priority': 1});
    });

    test('json roundtrip', () {
      final json = allOf.toJson();
      final reconstructed = AllOfEnum.fromJson(json);
      expect(reconstructed, allOf);
    });

    test('toForm - explode true', () {
      expect(
        allOf.toForm(explode: true, allowEmpty: true),
        'priority=1&status=value1',
      );
    });

    test('form roundtrip - explode true', () {
      final form = allOf.toForm(explode: true, allowEmpty: true);
      final reconstructed = AllOfEnum.fromForm(form, explode: true);
      expect(reconstructed, allOf);
    });

    test('toForm - explode false', () {
      expect(
        allOf.toForm(explode: false, allowEmpty: true),
        'priority,1,status,value1',
      );
    });

    test('form roundtrip - explode false', () {
      final form = allOf.toForm(explode: false, allowEmpty: true);
      final reconstructed = AllOfEnum.fromForm(form, explode: false);
      expect(reconstructed, allOf);
    });

    test('toSimple - explode true', () {
      expect(
        allOf.toSimple(explode: true, allowEmpty: true),
        'priority=1,status=value1',
      );
    });

    test('simple roundtrip - explode true', () {
      final simple = allOf.toSimple(explode: true, allowEmpty: true);
      final reconstructed = AllOfEnum.fromSimple(simple, explode: true);
      expect(reconstructed, allOf);
    });

    test('toSimple - explode false', () {
      expect(
        allOf.toSimple(explode: false, allowEmpty: true),
        'priority,1,status,value1',
      );
    });

    test('simple roundtrip - explode false', () {
      final simple = allOf.toSimple(explode: false, allowEmpty: true);
      final reconstructed = AllOfEnum.fromSimple(simple, explode: false);
      expect(reconstructed, allOf);
    });

    test('toMatrix - explode false', () {
      expect(
        allOf.toMatrix('1234', explode: false, allowEmpty: true),
        ';1234=priority,1,status,value1',
      );
    });

    test('toMatrix - explode true', () {
      expect(
        allOf.toMatrix('1234', explode: true, allowEmpty: true),
        ';priority=1;status=value1',
      );
    });

    test('toLabel - explode true', () {
      expect(
        allOf.toLabel(explode: true, allowEmpty: true),
        '.priority=1.status=value1',
      );
    });

    test('toLabel - explode false', () {
      expect(
        allOf.toLabel(explode: false, allowEmpty: true),
        '.priority,1,status,value1',
      );
    });

    test('currentEncodingShape', () {
      expect(allOf.currentEncodingShape, EncodingShape.complex);
    });
  });

  group('AllOfMixed', () {
    late AllOfMixed allOf;

    setUp(() {
      allOf = const AllOfMixed(
        string: 'hello, world!',
        class1: Class1(name: '1'),
      );
    });

    test('toJson throws EncodingException', () {
      expect(allOf.toJson, throwsA(isA<EncodingException>()));
    });

    test('toForm throws EncodingException', () {
      expect(
        () => allOf.toForm(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
    });

    test('toSimple throws EncodingException', () {
      expect(
        () => allOf.toSimple(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
    });

    test('toMatrix throws EncodingException', () {
      expect(
        () => allOf.toMatrix('paramName', explode: false, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
    });

    test('toLabel - explode true throws EncodingException', () {
      expect(
        () => allOf.toLabel(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
    });

    test('toLabel - explode false throws EncodingException', () {
      expect(
        () => allOf.toLabel(explode: false, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
    });

    test('currentEncodingShape', () {
      expect(allOf.currentEncodingShape, EncodingShape.mixed);
    });
  });

  group('NestedAllOfInAllOf', () {
    late NestedAllOfInAllOf allOf;

    setUp(() {
      allOf = const NestedAllOfInAllOf(
        allOfComplex: AllOfComplex(
          class1: Class1(name: 'Albert'),
          class2: Class2(number: 1),
        ),
        nestedAllOfInAllOfModel: NestedAllOfInAllOfModel(extra: 'extra'),
      );
    });

    test('toJson', () {
      expect(allOf.toJson(), {'name': 'Albert', 'number': 1, 'extra': 'extra'});
    });

    test('json roundtrip', () {
      final json = allOf.toJson();
      final reconstructed = NestedAllOfInAllOf.fromJson(json);
      expect(reconstructed, allOf);
    });

    test('toForm - explode true', () {
      expect(
        allOf.toForm(explode: true, allowEmpty: true),
        'name=Albert&number=1&extra=extra',
      );
    });

    test('form roundtrip - explode true', () {
      final form = allOf.toForm(explode: true, allowEmpty: true);
      final reconstructed = NestedAllOfInAllOf.fromForm(form, explode: true);
      expect(reconstructed, allOf);
    });

    test('toForm - explode false', () {
      expect(
        allOf.toForm(explode: false, allowEmpty: true),
        'name,Albert,number,1,extra,extra',
      );
    });

    test('form roundtrip - explode false', () {
      final form = allOf.toForm(explode: false, allowEmpty: true);
      final reconstructed = NestedAllOfInAllOf.fromForm(form, explode: false);
      expect(reconstructed, allOf);
    });

    test('toSimple - explode true', () {
      expect(
        allOf.toSimple(explode: true, allowEmpty: true),
        'name=Albert,number=1,extra=extra',
      );
    });

    test('simple roundtrip - explode true', () {
      final simple = allOf.toSimple(explode: true, allowEmpty: true);
      final reconstructed = NestedAllOfInAllOf.fromSimple(
        simple,
        explode: true,
      );
      expect(reconstructed, allOf);
    });

    test('toSimple - explode false', () {
      expect(
        allOf.toSimple(explode: false, allowEmpty: true),
        'name,Albert,number,1,extra,extra',
      );
    });

    test('simple roundtrip - explode false', () {
      final simple = allOf.toSimple(explode: false, allowEmpty: true);
      final reconstructed = NestedAllOfInAllOf.fromSimple(
        simple,
        explode: false,
      );
      expect(reconstructed, allOf);
    });

    test('toMatrix - explode false', () {
      expect(
        allOf.toMatrix('x', explode: false, allowEmpty: true),
        ';x=name,Albert,number,1,extra,extra',
      );
    });

    test('toMatrix - explode true', () {
      expect(
        allOf.toMatrix('x', explode: true, allowEmpty: true),
        ';name=Albert;number=1;extra=extra',
      );
    });

    test('toLabel - explode true', () {
      expect(
        allOf.toLabel(explode: true, allowEmpty: true),
        '.name=Albert.number=1.extra=extra',
      );
    });

    test('toLabel - explode false', () {
      expect(
        allOf.toLabel(explode: false, allowEmpty: true),
        '.name,Albert,number,1,extra,extra',
      );
    });

    test('currentEncodingShape', () {
      expect(allOf.currentEncodingShape, EncodingShape.complex);
    });
  });

  group('NestedOneOfInAllOf', () {
    group('string', () {
      late NestedOneOfInAllOf allOf;

      setUp(() {
        allOf = const NestedOneOfInAllOf(
          oneOfPrimitive: OneOfPrimitiveString('hello, world!'),
          nestedOneOfInAllOfModel: NestedOneOfInAllOfModel(metadata: 'extra'),
        );
      });

      test('toJson throws EncodingException', () {
        expect(allOf.toJson, throwsA(isA<EncodingException>()));
      });

      test('toForm throws EncodingException', () {
        expect(
          () => allOf.toForm(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toSimple throws EncodingException', () {
        expect(
          () => allOf.toSimple(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toMatrix throws EncodingException', () {
        expect(
          () => allOf.toMatrix('name', explode: false, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toLabel - explode true throws EncodingException', () {
        expect(
          () => allOf.toLabel(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toLabel - explode false throws EncodingException', () {
        expect(
          () => allOf.toLabel(explode: false, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('currentEncodingShape', () {
        expect(allOf.currentEncodingShape, EncodingShape.mixed);
      });
    });

    group('integer', () {
      late NestedOneOfInAllOf allOf;

      setUp(() {
        allOf = const NestedOneOfInAllOf(
          oneOfPrimitive: OneOfPrimitiveInt(-848),
          nestedOneOfInAllOfModel: NestedOneOfInAllOfModel(metadata: 'extra'),
        );
      });

      test('toJson throws EncodingException', () {
        expect(allOf.toJson, throwsA(isA<EncodingException>()));
      });

      test('toForm throws EncodingException', () {
        expect(
          () => allOf.toForm(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toSimple throws EncodingException', () {
        expect(
          () => allOf.toSimple(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toMatrix throws EncodingException', () {
        expect(
          () => allOf.toMatrix('int', explode: false, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('currentEncodingShape', () {
        expect(allOf.currentEncodingShape, EncodingShape.mixed);
      });
    });
  });

  group('TwoLevelAllOf', () {
    late TwoLevelAllOf allOf;

    setUp(() {
      allOf = const TwoLevelAllOf(
        twoLevelAllOfAllOfModel: TwoLevelAllOfAllOfModel(
          twoLevelAllOfAllOfModel3: TwoLevelAllOfAllOfModel3(name: 'Albert'),
          twoLevelAllOfAllOfModel2: TwoLevelAllOfAllOfModel2(id: '123'),
        ),
        twoLevelAllOfModel: TwoLevelAllOfModel(active: true),
      );
    });

    test('toJson', () {
      expect(allOf.toJson(), {'id': '123', 'name': 'Albert', 'active': true});
    });

    test('json roundtrip', () {
      final json = allOf.toJson();
      final reconstructed = TwoLevelAllOf.fromJson(json);
      expect(reconstructed, allOf);
    });

    test('toForm - explode true', () {
      expect(
        allOf.toForm(explode: true, allowEmpty: true),
        'active=true&id=123&name=Albert',
      );
    });

    test('form roundtrip - explode true', () {
      final form = allOf.toForm(explode: true, allowEmpty: true);
      final reconstructed = TwoLevelAllOf.fromForm(form, explode: true);
      expect(reconstructed, allOf);
    });

    test('toForm - explode false', () {
      expect(
        allOf.toForm(explode: false, allowEmpty: true),
        'active,true,id,123,name,Albert',
      );
    });

    test('form roundtrip - explode false', () {
      final form = allOf.toForm(explode: false, allowEmpty: true);
      final reconstructed = TwoLevelAllOf.fromForm(form, explode: false);
      expect(reconstructed, allOf);
    });

    test('toSimple - explode true', () {
      expect(
        allOf.toSimple(explode: true, allowEmpty: true),
        'active=true,id=123,name=Albert',
      );
    });

    test('simple roundtrip - explode true', () {
      final simple = allOf.toSimple(explode: true, allowEmpty: true);
      final reconstructed = TwoLevelAllOf.fromSimple(simple, explode: true);
      expect(reconstructed, allOf);
    });

    test('toSimple - explode false', () {
      expect(
        allOf.toSimple(explode: false, allowEmpty: true),
        'active,true,id,123,name,Albert',
      );
    });

    test('simple roundtrip - explode false', () {
      final simple = allOf.toSimple(explode: false, allowEmpty: true);
      final reconstructed = TwoLevelAllOf.fromSimple(simple, explode: false);
      expect(reconstructed, allOf);
    });

    test('toMatrix - explode false', () {
      expect(
        allOf.toMatrix('x', explode: false, allowEmpty: true),
        ';x=active,true,id,123,name,Albert',
      );
    });

    test('toMatrix - explode true', () {
      expect(
        allOf.toMatrix('x', explode: true, allowEmpty: true),
        ';active=true;id=123;name=Albert',
      );
    });

    test('toLabel - explode true', () {
      expect(
        allOf.toLabel(explode: true, allowEmpty: true),
        '.active=true.id=123.name=Albert',
      );
    });

    test('toLabel - explode false', () {
      expect(
        allOf.toLabel(explode: false, allowEmpty: true),
        '.active,true,id,123,name,Albert',
      );
    });

    test('currentEncodingShape', () {
      expect(allOf.currentEncodingShape, EncodingShape.complex);
    });
  });

  group('ThreeLevelAllOf', () {
    late ThreeLevelAllOf allOf;

    setUp(() {
      allOf = const ThreeLevelAllOf(
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
    });

    test('toJson', () {
      expect(allOf.toJson(), {
        'id': '123',
        'name': 'Albert',
        'email': 'albert@example.com',
        'verified': true,
      });
    });

    test('json roundtrip', () {
      final json = allOf.toJson();
      final reconstructed = ThreeLevelAllOf.fromJson(json);
      expect(reconstructed, allOf);
    });

    test('toForm - explode true', () {
      expect(
        allOf.toForm(explode: true, allowEmpty: true),
        'verified=true&email=albert%40example.com&id=123&name=Albert',
      );
    });

    test('form roundtrip - explode true', () {
      final form = allOf.toForm(explode: true, allowEmpty: true);
      final reconstructed = ThreeLevelAllOf.fromForm(form, explode: true);
      expect(reconstructed, allOf);
    });

    test('toForm - explode false', () {
      expect(
        allOf.toForm(explode: false, allowEmpty: true),
        'verified,true,email,albert%40example.com,id,123,name,Albert',
      );
    });

    test('form roundtrip - explode false', () {
      final form = allOf.toForm(explode: false, allowEmpty: true);
      final reconstructed = ThreeLevelAllOf.fromForm(form, explode: false);
      expect(reconstructed, allOf);
    });

    test('toSimple - explode true', () {
      expect(
        allOf.toSimple(explode: true, allowEmpty: true),
        'verified=true,email=albert%40example.com,id=123,name=Albert',
      );
    });

    test('simple roundtrip - explode true', () {
      final simple = allOf.toSimple(explode: true, allowEmpty: true);
      final reconstructed = ThreeLevelAllOf.fromSimple(simple, explode: true);
      expect(reconstructed, allOf);
    });

    test('toSimple - explode false', () {
      expect(
        allOf.toSimple(explode: false, allowEmpty: true),
        'verified,true,email,albert%40example.com,id,123,name,Albert',
      );
    });

    test('simple roundtrip - explode false', () {
      final simple = allOf.toSimple(explode: false, allowEmpty: true);
      final reconstructed = ThreeLevelAllOf.fromSimple(simple, explode: false);
      expect(reconstructed, allOf);
    });

    test('toMatrix - explode false', () {
      expect(
        allOf.toMatrix('x', explode: false, allowEmpty: true),
        ';x=verified,true,email,albert%40example.com,id,123,name,Albert',
      );
    });

    test('toMatrix - explode true', () {
      expect(
        allOf.toMatrix('x', explode: true, allowEmpty: true),
        ';verified=true;email=albert%40example.com;id=123;name=Albert',
      );
    });

    test('toLabel - explode true', () {
      expect(
        allOf.toLabel(explode: true, allowEmpty: true),
        '.verified=true.email=albert%40example.com.id=123.name=Albert',
      );
    });

    test('toLabel - explode false', () {
      expect(
        allOf.toLabel(explode: false, allowEmpty: true),
        '.verified,true,email,albert%40example.com,id,123,name,Albert',
      );
    });

    test('currentEncodingShape', () {
      expect(allOf.currentEncodingShape, EncodingShape.complex);
    });
  });

  group('TwoLevelMixedAllOfAnyOf', () {
    group('integer', () {
      late TwoLevelMixedAllOfAnyOf allOf;

      setUp(() {
        allOf = const TwoLevelMixedAllOfAnyOf(
          twoLevelMixedAllOfAnyOfModel: TwoLevelMixedAllOfAnyOfModel(int: 1),
          twoLevelMixedAllOfAnyOfModel2: TwoLevelMixedAllOfAnyOfModel2(
            metadata: 'extra',
          ),
        );
      });

      test('toJson throws EncodingException', () {
        expect(allOf.toJson, throwsA(isA<EncodingException>()));
      });

      test('toForm throws EncodingException', () {
        expect(
          () => allOf.toForm(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toSimple throws EncodingException', () {
        expect(
          () => allOf.toSimple(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toMatrix throws EncodingException', () {
        expect(
          () => allOf.toMatrix('int', explode: false, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toLabel - explode true throws EncodingException', () {
        expect(
          () => allOf.toLabel(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toLabel - explode false throws EncodingException', () {
        expect(
          () => allOf.toLabel(explode: false, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('currentEncodingShape', () {
        expect(allOf.currentEncodingShape, EncodingShape.mixed);
      });
    });

    group('string', () {
      late TwoLevelMixedAllOfAnyOf allOf;

      setUp(() {
        allOf = const TwoLevelMixedAllOfAnyOf(
          twoLevelMixedAllOfAnyOfModel: TwoLevelMixedAllOfAnyOfModel(
            string: 'extra',
          ),
          twoLevelMixedAllOfAnyOfModel2: TwoLevelMixedAllOfAnyOfModel2(
            metadata: 'extra',
          ),
        );
      });

      test('toJson throws EncodingException', () {
        expect(allOf.toJson, throwsA(isA<EncodingException>()));
      });

      test('toForm throws EncodingException', () {
        expect(
          () => allOf.toForm(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toSimple throws EncodingException', () {
        expect(
          () => allOf.toSimple(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toMatrix throws EncodingException', () {
        expect(
          () => allOf.toMatrix('string', explode: false, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });
    });

    group('integer and string', () {
      late TwoLevelMixedAllOfAnyOf allOf;

      setUp(() {
        allOf = const TwoLevelMixedAllOfAnyOf(
          twoLevelMixedAllOfAnyOfModel: TwoLevelMixedAllOfAnyOfModel(
            int: 1,
            string: 'extra',
          ),
          twoLevelMixedAllOfAnyOfModel2: TwoLevelMixedAllOfAnyOfModel2(
            metadata: 'extra',
          ),
        );
      });

      test('toJson throws EncodingException', () {
        expect(allOf.toJson, throwsA(isA<EncodingException>()));
      });

      test('toForm throws EncodingException', () {
        expect(
          () => allOf.toForm(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toSimple throws EncodingException', () {
        expect(
          () => allOf.toSimple(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toMatrix throws EncodingException', () {
        expect(
          () => allOf.toMatrix('int', explode: false, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('currentEncodingShape', () {
        expect(allOf.currentEncodingShape, EncodingShape.mixed);
      });
    });
  });

  group('ThreeLevelMixedAllOfOneOfAnyOf', () {
    group('enum1', () {
      late ThreeLevelMixedAllOfOneOfAnyOf allOf;

      setUp(() {
        allOf = const ThreeLevelMixedAllOfOneOfAnyOf(
          threeLevelMixedAllOfOneOfAnyOfOneOfModel:
              ThreeLevelMixedAllOfOneOfAnyOfOneOfModelAnyOf(
                ThreeLevelMixedAllOfOneOfAnyOfOneOfAnyOfModel(
                  enum1: Enum1.value1,
                ),
              ),
          threeLevelMixedAllOfOneOfAnyOfModel:
              ThreeLevelMixedAllOfOneOfAnyOfModel(metadata: 'asdf'),
        );
      });

      test('toJson throws EncodingException', () {
        expect(allOf.toJson, throwsA(isA<EncodingException>()));
      });

      test('toForm throws EncodingException', () {
        expect(
          () => allOf.toForm(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toSimple throws EncodingException', () {
        expect(
          () => allOf.toSimple(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toMatrix throws EncodingException', () {
        expect(
          () => allOf.toMatrix('enum1', explode: false, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toLabel - explode true throws EncodingException', () {
        expect(
          () => allOf.toLabel(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toLabel - explode false throws EncodingException', () {
        expect(
          () => allOf.toLabel(explode: false, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('currentEncodingShape', () {
        expect(allOf.currentEncodingShape, EncodingShape.mixed);
      });
    });

    group('class1', () {
      late ThreeLevelMixedAllOfOneOfAnyOf allOf;

      setUp(() {
        allOf = const ThreeLevelMixedAllOfOneOfAnyOf(
          threeLevelMixedAllOfOneOfAnyOfOneOfModel:
              ThreeLevelMixedAllOfOneOfAnyOfOneOfModelAnyOf(
                ThreeLevelMixedAllOfOneOfAnyOfOneOfAnyOfModel(
                  class1: Class1(name: 'qwerty'),
                ),
              ),
          threeLevelMixedAllOfOneOfAnyOfModel:
              ThreeLevelMixedAllOfOneOfAnyOfModel(metadata: 'asdf'),
        );
      });

      test('toJson', () {
        expect(allOf.toJson(), {'name': 'qwerty', 'metadata': 'asdf'});
      });

      test('toForm', () {
        expect(
          allOf.toForm(explode: true, allowEmpty: true),
          'metadata=asdf&name=qwerty',
        );
      });

      test('toSimple - explode true', () {
        expect(
          allOf.toSimple(explode: true, allowEmpty: true),
          'metadata=asdf,name=qwerty',
        );
      });

      test('toSimple - explode false', () {
        expect(
          allOf.toSimple(explode: false, allowEmpty: true),
          'metadata,asdf,name,qwerty',
        );
      });

      test('toMatrix - explode false', () {
        expect(
          allOf.toMatrix('x', explode: false, allowEmpty: true),
          ';x=metadata,asdf,name,qwerty',
        );
      });

      test('toMatrix - explode true', () {
        expect(
          allOf.toMatrix('x', explode: true, allowEmpty: true),
          ';metadata=asdf;name=qwerty',
        );
      });

      test('currentEncodingShape', () {
        expect(allOf.currentEncodingShape, EncodingShape.complex);
      });
    });

    group('string', () {
      late ThreeLevelMixedAllOfOneOfAnyOf allOf;

      setUp(() {
        allOf = const ThreeLevelMixedAllOfOneOfAnyOf(
          threeLevelMixedAllOfOneOfAnyOfOneOfModel:
              ThreeLevelMixedAllOfOneOfAnyOfOneOfModelString('qwerty'),
          threeLevelMixedAllOfOneOfAnyOfModel:
              ThreeLevelMixedAllOfOneOfAnyOfModel(metadata: 'asdf'),
        );
      });

      test('toJson throws EncodingException', () {
        expect(allOf.toJson, throwsA(isA<EncodingException>()));
      });

      test('toForm throws EncodingException', () {
        expect(
          () => allOf.toForm(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toSimple throws EncodingException', () {
        expect(
          () => allOf.toSimple(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toMatrix throws EncodingException', () {
        expect(
          () => allOf.toMatrix('string', explode: false, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('currentEncodingShape', () {
        expect(allOf.currentEncodingShape, EncodingShape.mixed);
      });
    });
  });

  group('ThreeLevelMixedRefs', () {
    group('with Class1', () {
      late ThreeLevelMixedRefs allOf;

      setUp(() {
        allOf = const ThreeLevelMixedRefs(
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
      });

      test('toJson throws EncodingException', () {
        expect(allOf.toJson, throwsA(isA<EncodingException>()));
      });

      test('toForm throws EncodingException', () {
        expect(
          () => allOf.toForm(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toSimple throws EncodingException', () {
        expect(
          () => allOf.toSimple(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toMatrix throws EncodingException', () {
        expect(
          () => allOf.toMatrix('x', explode: false, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toLabel - explode true throws EncodingException', () {
        expect(
          () => allOf.toLabel(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toLabel - explode false throws EncodingException', () {
        expect(
          () => allOf.toLabel(explode: false, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('currentEncodingShape', () {
        expect(allOf.currentEncodingShape, EncodingShape.mixed);
      });
    });

    group('with integer', () {
      late ThreeLevelMixedRefs allOf;

      setUp(() {
        allOf = const ThreeLevelMixedRefs(
          twoLevelMixedAllOfAnyOf: TwoLevelMixedAllOfAnyOf(
            twoLevelMixedAllOfAnyOfModel: TwoLevelMixedAllOfAnyOfModel(int: 42),
            twoLevelMixedAllOfAnyOfModel2: TwoLevelMixedAllOfAnyOfModel2(
              metadata: 'extra',
            ),
          ),
          threeLevelMixedRefsAnyOfModel: ThreeLevelMixedRefsAnyOfModel(
            int: 123,
          ),
        );
      });

      test('toJson throws EncodingException', () {
        expect(allOf.toJson, throwsA(isA<EncodingException>()));
      });

      test('toForm throws EncodingException', () {
        expect(
          () => allOf.toForm(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toSimple throws EncodingException', () {
        expect(
          () => allOf.toSimple(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toMatrix throws EncodingException', () {
        expect(
          () => allOf.toMatrix('int', explode: false, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('currentEncodingShape', () {
        expect(allOf.currentEncodingShape, EncodingShape.mixed);
      });
    });
  });

  group('ComplexNestedMix', () {
    group('with Class1', () {
      late ComplexNestedMix allOf;

      setUp(() {
        allOf = const ComplexNestedMix(
          complexNestedMixModel: ComplexNestedMixModel($base: 'test'),
          complexNestedMixOneOfModel: ComplexNestedMixOneOfModelClass1(
            Class1(name: 'Albert'),
          ),
        );
      });

      test('toJson', () {
        expect(allOf.toJson(), {'base': 'test', 'name': 'Albert'});
      });

      test('json roundtrip', () {
        final json = allOf.toJson();
        final reconstructed = ComplexNestedMix.fromJson(json);
        expect(reconstructed, allOf);
      });

      test('toForm - explode true', () {
        expect(
          allOf.toForm(explode: true, allowEmpty: true),
          'base=test&name=Albert',
        );
      });

      test('form roundtrip - explode true', () {
        final form = allOf.toForm(explode: true, allowEmpty: true);
        final reconstructed = ComplexNestedMix.fromForm(form, explode: true);
        expect(reconstructed, allOf);
      });

      test('toForm - explode false', () {
        expect(
          allOf.toForm(explode: false, allowEmpty: true),
          'base,test,name,Albert',
        );
      });

      test('form roundtrip - explode false', () {
        final form = allOf.toForm(explode: false, allowEmpty: true);
        final reconstructed = ComplexNestedMix.fromForm(form, explode: false);
        expect(reconstructed, allOf);
      });

      test('toSimple - explode true', () {
        expect(
          allOf.toSimple(explode: true, allowEmpty: true),
          'base=test,name=Albert',
        );
      });

      test('simple roundtrip - explode true', () {
        final simple = allOf.toSimple(explode: true, allowEmpty: true);
        final reconstructed = ComplexNestedMix.fromSimple(
          simple,
          explode: true,
        );
        expect(reconstructed, allOf);
      });

      test('toSimple - explode false', () {
        expect(
          allOf.toSimple(explode: false, allowEmpty: true),
          'base,test,name,Albert',
        );
      });

      test('simple roundtrip - explode false', () {
        final simple = allOf.toSimple(explode: false, allowEmpty: true);
        final reconstructed = ComplexNestedMix.fromSimple(
          simple,
          explode: false,
        );
        expect(reconstructed, allOf);
      });

      test('toMatrix - explode false', () {
        expect(
          allOf.toMatrix('complexNestedMix', explode: false, allowEmpty: true),
          ';complexNestedMix=base,test,name,Albert',
        );
      });

      test('toMatrix - explode true', () {
        expect(
          allOf.toMatrix('complexNestedMix', explode: true, allowEmpty: true),
          ';base=test;name=Albert',
        );
      });

      test('toLabel - explode true', () {
        expect(
          allOf.toLabel(explode: true, allowEmpty: true),
          '.base=test.name=Albert',
        );
      });

      test('toLabel - explode false', () {
        expect(
          allOf.toLabel(explode: false, allowEmpty: true),
          '.base,test,name,Albert',
        );
      });

      test('currentEncodingShape', () {
        expect(allOf.currentEncodingShape, EncodingShape.complex);
      });
    });

    group('with Class2', () {
      late ComplexNestedMix allOf;

      setUp(() {
        allOf = const ComplexNestedMix(
          complexNestedMixModel: ComplexNestedMixModel($base: 'test'),
          complexNestedMixOneOfModel: ComplexNestedMixOneOfModelClass2(
            Class2(number: 42),
          ),
        );
      });

      test('toJson', () {
        expect(allOf.toJson(), {'base': 'test', 'number': 42});
      });

      test('toForm', () {
        expect(
          allOf.toForm(explode: true, allowEmpty: true),
          'base=test&number=42',
        );
      });

      test('toSimple - explode true', () {
        expect(
          allOf.toSimple(explode: true, allowEmpty: true),
          'base=test,number=42',
        );
      });

      test('toSimple - explode false', () {
        expect(
          allOf.toSimple(explode: false, allowEmpty: true),
          'base,test,number,42',
        );
      });

      test('toMatrix - explode false', () {
        expect(
          allOf.toMatrix('asdf', explode: false, allowEmpty: true),
          ';asdf=base,test,number,42',
        );
      });

      test('toMatrix - explode true', () {
        expect(
          allOf.toMatrix('asdf', explode: true, allowEmpty: true),
          ';base=test;number=42',
        );
      });

      test('currentEncodingShape', () {
        expect(allOf.currentEncodingShape, EncodingShape.complex);
      });
    });
  });

  group('MultiLevelNesting', () {
    group('with string level1', () {
      late MultiLevelNesting allOf;

      setUp(() {
        allOf = const MultiLevelNesting(
          multiLevelNestingModel2: MultiLevelNestingModel2(level2: 42),
          multiLevelNestingModel: MultiLevelNestingModel(
            level1: MultiLevelNestingLevel1OneOfModelString('test'),
          ),
        );
      });

      test('toJson', () {
        expect(allOf.toJson(), {'level1': 'test', 'level2': 42});
      });

      test('json roundtrip', () {
        final json = allOf.toJson();
        final reconstructed = MultiLevelNesting.fromJson(json);
        expect(reconstructed, allOf);
      });

      test('toForm - explode true', () {
        expect(
          allOf.toForm(explode: true, allowEmpty: true),
          'level1=test&level2=42',
        );
      });

      test('form roundtrip - explode true', () {
        final form = allOf.toForm(explode: true, allowEmpty: true);
        final reconstructed = MultiLevelNesting.fromForm(form, explode: true);
        expect(reconstructed, allOf);
      });

      test('toForm - explode false', () {
        expect(
          allOf.toForm(explode: false, allowEmpty: true),
          'level1,test,level2,42',
        );
      });

      test('form roundtrip - explode false', () {
        final form = allOf.toForm(explode: false, allowEmpty: true);
        final reconstructed = MultiLevelNesting.fromForm(form, explode: false);
        expect(reconstructed, allOf);
      });

      test('toSimple - explode true', () {
        expect(
          allOf.toSimple(explode: true, allowEmpty: true),
          'level1=test,level2=42',
        );
      });

      test('simple roundtrip - explode true', () {
        final simple = allOf.toSimple(explode: true, allowEmpty: true);
        final reconstructed = MultiLevelNesting.fromSimple(
          simple,
          explode: true,
        );
        expect(reconstructed, allOf);
      });

      test('toSimple - explode false', () {
        expect(
          allOf.toSimple(explode: false, allowEmpty: true),
          'level1,test,level2,42',
        );
      });

      test('simple roundtrip - explode false', () {
        final simple = allOf.toSimple(explode: false, allowEmpty: true);
        final reconstructed = MultiLevelNesting.fromSimple(
          simple,
          explode: false,
        );
        expect(reconstructed, allOf);
      });

      test('toMatrix - explode false', () {
        expect(
          allOf.toMatrix('level1', explode: false, allowEmpty: true),
          ';level1=level1,test,level2,42',
        );
      });

      test('toMatrix - explode true', () {
        expect(
          allOf.toMatrix('level1', explode: true, allowEmpty: true),
          ';level1=test;level2=42',
        );
      });

      test('toLabel - explode true', () {
        expect(
          allOf.toLabel(explode: true, allowEmpty: true),
          '.level1=test.level2=42',
        );
      });

      test('toLabel - explode false', () {
        expect(
          allOf.toLabel(explode: false, allowEmpty: true),
          '.level1,test,level2,42',
        );
      });

      test('currentEncodingShape', () {
        expect(allOf.currentEncodingShape, EncodingShape.complex);
      });
    });

    group('with Class1 level1', () {
      late MultiLevelNesting allOf;

      setUp(() {
        allOf = const MultiLevelNesting(
          multiLevelNestingModel2: MultiLevelNestingModel2(level2: 42),
          multiLevelNestingModel: MultiLevelNestingModel(
            level1: MultiLevelNestingLevel1OneOfModelAnyOf(
              MultiLevelNestingLevel1OneOfAnyOfModel(
                class1: Class1(name: 'Albert'),
              ),
            ),
          ),
        );
      });

      test('toJson', () {
        expect(allOf.toJson(), {
          'level1': {'name': 'Albert'},
          'level2': 42,
        });
      });

      test('toForm throws EncodingException', () {
        expect(
          () => allOf.toForm(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toSimple throws EncodingException', () {
        expect(
          () => allOf.toSimple(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toMatrix throws EncodingException', () {
        expect(
          () => allOf.toMatrix('level1', explode: false, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('currentEncodingShape', () {
        expect(allOf.currentEncodingShape, EncodingShape.complex);
      });
    });

    group('with Class2 level1', () {
      late MultiLevelNesting allOf;

      setUp(() {
        allOf = const MultiLevelNesting(
          multiLevelNestingModel2: MultiLevelNestingModel2(level2: 42),
          multiLevelNestingModel: MultiLevelNestingModel(
            level1: MultiLevelNestingLevel1OneOfModelAnyOf(
              MultiLevelNestingLevel1OneOfAnyOfModel(
                class2: Class2(number: 123),
              ),
            ),
          ),
        );
      });

      test('toJson', () {
        expect(allOf.toJson(), {
          'level1': {'number': 123},
          'level2': 42,
        });
      });

      test('toForm throws EncodingException', () {
        expect(
          () => allOf.toForm(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toSimple throws EncodingException', () {
        expect(
          () => allOf.toSimple(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toMatrix throws EncodingException', () {
        expect(
          () => allOf.toMatrix('level1', explode: false, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('currentEncodingShape', () {
        expect(allOf.currentEncodingShape, EncodingShape.complex);
      });
    });
  });

  group('AllOfWithSimpleList', () {
    late AllOfWithSimpleList allOf;

    setUp(() {
      allOf = const AllOfWithSimpleList(
        allOfWithSimpleListModel: AllOfWithSimpleListModel(ids: [1, 2, 3]),
        allOfWithSimpleListModel2: AllOfWithSimpleListModel2(
          tags: ['tag1', 'tag2', 'tag3'],
        ),
      );
    });

    test('toJson', () {
      expect(allOf.toJson(), {
        'ids': [1, 2, 3],
        'tags': ['tag1', 'tag2', 'tag3'],
      });
    });

    test('json roundtrip', () {
      final json = allOf.toJson();
      final reconstructed = AllOfWithSimpleList.fromJson(json);
      expect(reconstructed, allOf);
    });

    test('toForm - explode true', () {
      expect(
        allOf.toForm(explode: true, allowEmpty: true),
        'ids=1,2,3&tags=tag1,tag2,tag3',
      );
    });

    test('form roundtrip - explode true', () {
      final form = allOf.toForm(explode: true, allowEmpty: true);
      final reconstructed = AllOfWithSimpleList.fromForm(form, explode: true);
      expect(reconstructed, allOf);
    });

    test('toForm - explode false', () {
      expect(
        allOf.toForm(explode: false, allowEmpty: true),
        'ids,1,2,3,tags,tag1,tag2,tag3',
      );
    });

    test('form roundtrip - explode false', () {
      final form = allOf.toForm(explode: false, allowEmpty: true);
      expect(
        () => AllOfWithSimpleList.fromForm(form, explode: false),
        throwsA(isA<DecodingException>()),
        reason:
            'allOf with list properties and explode=false creates '
            'ambiguous boundaries: cannot determine where one list ends and '
            'the next property begins without knowing all keys from all '
            'composed schemas',
      );
    });

    test('toSimple - explode true', () {
      expect(
        allOf.toSimple(explode: true, allowEmpty: true),
        'ids=1,2,3,tags=tag1,tag2,tag3',
      );
    });

    test('simple roundtrip - explode true', () {
      final simple = allOf.toSimple(explode: true, allowEmpty: true);
      final reconstructed = AllOfWithSimpleList.fromSimple(
        simple,
        explode: true,
      );
      expect(reconstructed, allOf);
    });

    test('toSimple - explode false', () {
      expect(
        allOf.toSimple(explode: false, allowEmpty: true),
        'ids,1,2,3,tags,tag1,tag2,tag3',
      );
    });

    test('simple roundtrip - explode false', () {
      final simple = allOf.toSimple(explode: false, allowEmpty: true);
      expect(
        () => AllOfWithSimpleList.fromSimple(simple, explode: false),
        throwsA(isA<InvalidTypeException>()),
        reason:
            'allOf with list properties and explode=false creates '
            'ambiguous boundaries: cannot determine where one list ends and '
            'the next property begins without knowing all keys from all '
            'composed schemas',
      );
    });

    test('toMatrix - explode false', () {
      expect(
        allOf.toMatrix('x', explode: false, allowEmpty: true),
        ';x=ids,1,2,3,tags,tag1,tag2,tag3',
      );
    });

    test('toMatrix - explode true', () {
      expect(
        allOf.toMatrix('x', explode: true, allowEmpty: true),
        ';ids=1,2,3;tags=tag1,tag2,tag3',
      );
    });

    test('toLabel - explode true', () {
      expect(
        allOf.toLabel(explode: true, allowEmpty: true),
        '.ids=1,2,3.tags=tag1,tag2,tag3',
      );
    });

    test('toLabel - explode false', () {
      expect(
        allOf.toLabel(explode: false, allowEmpty: true),
        '.ids,1,2,3,tags,tag1,tag2,tag3',
      );
    });

    test('currentEncodingShape', () {
      expect(allOf.currentEncodingShape, EncodingShape.complex);
    });
  });

  group('AllOfWithMixedLists', () {
    late AllOfWithMixedLists allOf;

    setUp(() {
      allOf = const AllOfWithMixedLists(
        allOfWithMixedListsModel2: AllOfWithMixedListsModel2(
          users: [Class1(name: 'Albert')],
        ),
        allOfWithMixedListsModel: AllOfWithMixedListsModel(
          tags: ['tag1', 'tag2', 'tag3'],
        ),
      );
    });

    test('toJson', () {
      expect(allOf.toJson(), {
        'tags': ['tag1', 'tag2', 'tag3'],
        'users': [
          {'name': 'Albert'},
        ],
      });
    });

    test('json roundtrip', () {
      final json = allOf.toJson();
      final reconstructed = AllOfWithMixedLists.fromJson(json);
      expect(reconstructed, allOf);
    });

    test('toForm throws EncodingException', () {
      expect(
        () => allOf.toForm(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
    });

    test('toSimple throws EncodingException', () {
      expect(
        () => allOf.toSimple(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
    });

    test('toMatrix throws EncodingException', () {
      expect(
        () => allOf.toMatrix('x', explode: false, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
    });

    test('toLabel - explode true throws EncodingException', () {
      expect(
        () => allOf.toLabel(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
    });

    test('toLabel - explode false throws EncodingException', () {
      expect(
        () => allOf.toLabel(explode: false, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
    });

    test('currentEncodingShape', () {
      expect(allOf.currentEncodingShape, EncodingShape.complex);
    });
  });

  group('AllOfWithEnumList', () {
    late AllOfWithEnumList allOf;

    setUp(() {
      allOf = const AllOfWithEnumList(
        allOfWithEnumListModel: AllOfWithEnumListModel(
          priorities: [Enum2.one, Enum2.two],
        ),
        allOfWithEnumListModel2: AllOfWithEnumListModel2(
          statuses: [Enum1.value1],
        ),
      );
    });

    test('toJson', () {
      expect(allOf.toJson(), {
        'statuses': ['value1'],
        'priorities': [1, 2],
      });
    });

    test('json roundtrip', () {
      final json = allOf.toJson();
      final reconstructed = AllOfWithEnumList.fromJson(json);
      expect(reconstructed, allOf);
    });

    test('toForm - explode true', () {
      expect(
        allOf.toForm(explode: true, allowEmpty: true),
        'priorities=1,2&statuses=value1',
      );
    });

    test('form roundtrip - explode true', () {
      final form = allOf.toForm(explode: true, allowEmpty: true);
      final reconstructed = AllOfWithEnumList.fromForm(form, explode: true);
      expect(reconstructed, allOf);
    });

    test('toForm - explode false', () {
      expect(
        allOf.toForm(explode: false, allowEmpty: true),
        'priorities,1,2,statuses,value1',
      );
    });

    test('form roundtrip - explode false', () {
      final form = allOf.toForm(explode: false, allowEmpty: true);
      expect(
        () => AllOfWithEnumList.fromForm(form, explode: false),
        throwsA(isA<DecodingException>()),
        reason:
            'allOf with list properties and explode=false creates '
            'ambiguous boundaries: cannot determine where one list ends and '
            'the next property begins without knowing all keys from all '
            'composed schemas',
      );
    });

    test('toSimple - explode true', () {
      expect(
        allOf.toSimple(explode: true, allowEmpty: true),
        'priorities=1,2,statuses=value1',
      );
    });

    test('simple roundtrip - explode true', () {
      final simple = allOf.toSimple(explode: true, allowEmpty: true);
      final reconstructed = AllOfWithEnumList.fromSimple(simple, explode: true);
      expect(reconstructed, allOf);
    });

    test('toSimple - explode false', () {
      expect(
        allOf.toSimple(explode: false, allowEmpty: true),
        'priorities,1,2,statuses,value1',
      );
    });

    test('simple roundtrip - explode false', () {
      final simple = allOf.toSimple(explode: false, allowEmpty: true);
      expect(
        () => AllOfWithEnumList.fromSimple(simple, explode: false),
        throwsA(isA<InvalidTypeException>()),
        reason:
            'allOf with list properties and explode=false creates '
            'ambiguous boundaries: cannot determine where one list ends and '
            'the next property begins without knowing all keys from all '
            'composed schemas',
      );
    });

    test('toMatrix - explode false', () {
      expect(
        allOf.toMatrix('y', explode: false, allowEmpty: true),
        ';y=priorities,1,2,statuses,value1',
      );
    });

    test('toMatrix - explode true', () {
      expect(
        allOf.toMatrix('y', explode: true, allowEmpty: true),
        ';priorities=1,2;statuses=value1',
      );
    });

    test('toLabel - explode true', () {
      expect(
        allOf.toLabel(explode: true, allowEmpty: true),
        '.priorities=1,2.statuses=value1',
      );
    });

    test('toLabel - explode false', () {
      expect(
        allOf.toLabel(explode: false, allowEmpty: true),
        '.priorities,1,2,statuses,value1',
      );
    });

    test('currentEncodingShape', () {
      expect(allOf.currentEncodingShape, EncodingShape.complex);
    });
  });

  group('NestedListInAllOf', () {
    late NestedListInAllOf allOf;

    setUp(() {
      allOf = const NestedListInAllOf(
        nestedListInAllOfModel: NestedListInAllOfModel(
          matrix: [
            [1, 2, 3],
            [4, 5, 6],
          ],
        ),
        nestedListInAllOfModel2: NestedListInAllOfModel2(name: 'test'),
      );
    });

    test('toJson', () {
      expect(allOf.toJson(), {
        'matrix': [
          [1, 2, 3],
          [4, 5, 6],
        ],
        'name': 'test',
      });
    });

    test('json roundtrip', () {
      final json = allOf.toJson();
      final reconstructed = NestedListInAllOf.fromJson(json);
      expect(reconstructed, allOf);
    });

    test('toForm throws EncodingException', () {
      expect(
        () => allOf.toForm(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
    });

    test('toSimple throws EncodingException', () {
      expect(
        () => allOf.toSimple(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
    });

    test('toMatrix throws EncodingException', () {
      expect(
        () => allOf.toMatrix('x', explode: false, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
    });

    test('toLabel - explode true throws EncodingException', () {
      expect(
        () => allOf.toLabel(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
    });

    test('toLabel - explode false throws EncodingException', () {
      expect(
        () => allOf.toLabel(explode: false, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
    });

    test('currentEncodingShape', () {
      expect(allOf.currentEncodingShape, EncodingShape.complex);
    });
  });

  group('ComplexListComposition', () {
    group('enum list', () {
      late ComplexListComposition allOf;

      setUp(() {
        allOf = const ComplexListComposition(
          complexListCompositionModel: ComplexListCompositionModel(
            simpleList: ['test', 'test2'],
          ),
          complexListCompositionAnyOfModel: ComplexListCompositionAnyOfModel(
            complexListCompositionAnyOfModel3:
                ComplexListCompositionAnyOfModel3(
                  enumList: [Enum1.value1, Enum1.value2],
                ),
          ),
        );
      });

      test('toJson', () {
        expect(allOf.toJson(), {
          'simpleList': ['test', 'test2'],
          'enumList': ['value1', 'value2'],
        });
      });

      test('json roundtrip', () {
        final json = allOf.toJson();
        final reconstructed = ComplexListComposition.fromJson(json);
        expect(reconstructed, allOf);
      });

      test('toForm - explode true', () {
        expect(
          allOf.toForm(explode: true, allowEmpty: true),
          'enumList=value1,value2&simpleList=test,test2',
        );
      });

      test('form roundtrip - explode true', () {
        final form = allOf.toForm(explode: true, allowEmpty: true);
        final reconstructed = ComplexListComposition.fromForm(
          form,
          explode: true,
        );
        expect(reconstructed, allOf);
      });

      test('toForm - explode false', () {
        expect(
          allOf.toForm(explode: false, allowEmpty: true),
          'enumList,value1,value2,simpleList,test,test2',
        );
      });

      test('form roundtrip - explode false', () {
        final form = allOf.toForm(explode: false, allowEmpty: true);
        expect(
          () => ComplexListComposition.fromForm(form, explode: false),
          throwsA(isA<DecodingException>()),
          reason:
              'allOf with list properties and explode=false creates '
              'ambiguous boundaries: cannot determine where one list ends and '
              'the next property begins without knowing all keys from all '
              'composed schemas',
        );
      });

      test('toSimple - explode true', () {
        expect(
          allOf.toSimple(explode: true, allowEmpty: true),
          'enumList=value1,value2,simpleList=test,test2',
        );
      });

      test('simple roundtrip - explode true', () {
        final simple = allOf.toSimple(explode: true, allowEmpty: true);
        expect(
          () => ComplexListComposition.fromSimple(simple, explode: false),
          throwsA(isA<DecodingException>()),
          reason:
              'allOf with list properties and explode=false creates '
              'ambiguous boundaries: cannot determine where one list ends and '
              'the next property begins',
        );
      });

      test('toSimple - explode false', () {
        expect(
          allOf.toSimple(explode: false, allowEmpty: true),
          'enumList,value1,value2,simpleList,test,test2',
        );
      });

      test('simple roundtrip - explode false', () {
        final simple = allOf.toSimple(explode: false, allowEmpty: true);
        expect(
          () => ComplexListComposition.fromSimple(simple, explode: false),
          throwsA(isA<DecodingException>()),
          reason:
              'allOf with list properties and explode=false creates '
              'ambiguous boundaries: cannot determine where one list ends and '
              'the next property begins',
        );
      });

      test('toMatrix - explode false', () {
        expect(
          allOf.toMatrix('x', explode: false, allowEmpty: true),
          ';x=enumList,value1,value2,simpleList,test,test2',
        );
      });

      test('toMatrix - explode true', () {
        expect(
          allOf.toMatrix('x', explode: true, allowEmpty: true),
          ';enumList=value1,value2;simpleList=test,test2',
        );
      });

      test('toLabel - explode true', () {
        expect(
          allOf.toLabel(explode: true, allowEmpty: true),
          '.enumList=value1,value2.simpleList=test,test2',
        );
      });

      test('toLabel - explode false', () {
        expect(
          allOf.toLabel(explode: false, allowEmpty: true),
          '.enumList,value1,value2,simpleList,test,test2',
        );
      });

      test('currentEncodingShape', () {
        expect(allOf.currentEncodingShape, EncodingShape.complex);
      });
    });

    group('complex list', () {
      late ComplexListComposition allOf;

      setUp(() {
        allOf = const ComplexListComposition(
          complexListCompositionModel: ComplexListCompositionModel(
            simpleList: ['test', 'test2'],
          ),
          complexListCompositionAnyOfModel: ComplexListCompositionAnyOfModel(
            complexListCompositionAnyOfModel2:
                ComplexListCompositionAnyOfModel2(
                  complexList: [
                    Class1(name: 'Albert'),
                    Class1(name: 'Bob'),
                  ],
                ),
          ),
        );
      });

      test('toJson', () {
        expect(allOf.toJson(), {
          'simpleList': ['test', 'test2'],
          'complexList': [
            {'name': 'Albert'},
            {'name': 'Bob'},
          ],
        });
      });

      test('json roundtrip', () {
        final json = allOf.toJson();
        final reconstructed = ComplexListComposition.fromJson(json);
        expect(reconstructed, allOf);
      });

      test('toForm throws EncodingException', () {
        expect(
          () => allOf.toForm(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toSimple throws EncodingException', () {
        expect(
          () => allOf.toSimple(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toMatrix throws EncodingException', () {
        expect(
          () => allOf.toMatrix('x', explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('currentEncodingShape', () {
        expect(allOf.currentEncodingShape, EncodingShape.complex);
      });
    });

    group('both lists', () {
      late ComplexListComposition allOf;

      setUp(() {
        allOf = const ComplexListComposition(
          complexListCompositionModel: ComplexListCompositionModel(
            simpleList: ['test', 'test2'],
          ),
          complexListCompositionAnyOfModel: ComplexListCompositionAnyOfModel(
            complexListCompositionAnyOfModel3:
                ComplexListCompositionAnyOfModel3(
                  enumList: [Enum1.value1, Enum1.value2],
                ),
            complexListCompositionAnyOfModel2:
                ComplexListCompositionAnyOfModel2(
                  complexList: [
                    Class1(name: 'Albert'),
                    Class1(name: 'Bob'),
                  ],
                ),
          ),
        );
      });

      test('toJson', () {
        expect(allOf.toJson(), {
          'simpleList': ['test', 'test2'],
          'complexList': [
            {'name': 'Albert'},
            {'name': 'Bob'},
          ],
          'enumList': ['value1', 'value2'],
        });
      });

      test('json roundtrip', () {
        final json = allOf.toJson();
        final reconstructed = ComplexListComposition.fromJson(json);
        expect(reconstructed, allOf);
      });

      test('toForm throws EncodingException', () {
        expect(
          () => allOf.toForm(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toSimple throws EncodingException', () {
        expect(
          () => allOf.toSimple(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toMatrix throws EncodingException', () {
        expect(
          () => allOf.toMatrix('x', explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('currentEncodingShape', () {
        expect(allOf.currentEncodingShape, EncodingShape.complex);
      });
    });
  });

  group('AllOfWithListOfComposites', () {
    late AllOfWithListOfComposites allOf;

    setUp(() {
      allOf = const AllOfWithListOfComposites(
        allOfWithListOfCompositesModel2: AllOfWithListOfCompositesModel2(
          items: [
            AllOfWithListOfCompositesItemsArrayOneOfModelClass1(
              Class1(name: 'Albert'),
            ),
            AllOfWithListOfCompositesItemsArrayOneOfModelClass2(
              Class2(number: 123),
            ),
          ],
        ),
        allOfWithListOfCompositesModel: AllOfWithListOfCompositesModel(
          count: 948894984,
        ),
      );
    });

    test('toJson', () {
      expect(allOf.toJson(), {
        'items': [
          {'name': 'Albert'},
          {'number': 123},
        ],
        'count': 948894984,
      });
    });

    test('json roundtrip', () {
      final json = allOf.toJson();
      final reconstructed = AllOfWithListOfComposites.fromJson(json);
      expect(reconstructed, allOf);
    });

    test('toForm throws EncodingException', () {
      expect(
        () => allOf.toForm(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
    });

    test('toSimple - explode true throws EncodingException', () {
      expect(
        () => allOf.toSimple(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
    });

    test('toSimple - explode false throws EncodingException', () {
      expect(
        () => allOf.toSimple(explode: false, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
    });

    test('toMatrix - explode false throws EncodingException', () {
      expect(
        () => allOf.toMatrix('x', explode: false, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
    });

    test('toMatrix - explode true throws EncodingException', () {
      expect(
        () => allOf.toMatrix('x', explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
    });

    test('toLabel - explode true throws EncodingException', () {
      expect(
        () => allOf.toLabel(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
    });

    test('toLabel - explode false throws EncodingException', () {
      expect(
        () => allOf.toLabel(explode: false, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
    });

    test('currentEncodingShape', () {
      expect(allOf.currentEncodingShape, EncodingShape.complex);
    });
  });

  group('AllOfDoubleList', () {
    late AllOfDoubleList allOf;

    setUp(() {
      allOf = AllOfDoubleList(
        list2: [
          DateTime.utc(2021).toTimeZonedIso8601String(),
          DateTime.utc(2021, 1, 2).toTimeZonedIso8601String(),
        ],
        list: [DateTime.utc(2021), DateTime.utc(2021, 1, 2)],
      );
    });

    test('toJson', () {
      expect(allOf.toJson(), [
        '2021-01-01T00:00:00.000Z',
        '2021-01-02T00:00:00.000Z',
      ]);
    });

    test('json roundtrip', () {
      final json = allOf.toJson();
      final reconstructed = AllOfDoubleList.fromJson(json);
      expect(reconstructed, allOf);
    });

    test('toForm - explode true', () {
      expect(
        allOf.toForm(explode: true, allowEmpty: true),
        '2021-01-01T00%3A00%3A00.000Z,2021-01-02T00%3A00%3A00.000Z',
      );
    });

    test('form roundtrip - explode true', () {
      final form = allOf.toForm(explode: true, allowEmpty: true);
      final reconstructed = AllOfDoubleList.fromForm(form, explode: true);
      expect(reconstructed, allOf);
    });

    test('toForm - explode false', () {
      expect(
        allOf.toForm(explode: false, allowEmpty: true),
        '2021-01-01T00%3A00%3A00.000Z,2021-01-02T00%3A00%3A00.000Z',
      );
    });

    test('form roundtrip - explode false', () {
      final form = allOf.toForm(explode: false, allowEmpty: true);
      final reconstructed = AllOfDoubleList.fromForm(form, explode: false);
      expect(reconstructed, allOf);
    });

    test('toSimple - explode true', () {
      expect(
        allOf.toSimple(explode: true, allowEmpty: true),
        '2021-01-01T00%3A00%3A00.000Z,2021-01-02T00%3A00%3A00.000Z',
      );
    });

    test('simple roundtrip - explode true', () {
      final simple = allOf.toSimple(explode: true, allowEmpty: true);
      final reconstructed = AllOfDoubleList.fromSimple(simple, explode: true);
      expect(reconstructed, allOf);
    });

    test('toSimple - explode false', () {
      expect(
        allOf.toSimple(explode: false, allowEmpty: true),
        '2021-01-01T00%3A00%3A00.000Z,2021-01-02T00%3A00%3A00.000Z',
      );
    });

    test('simple roundtrip - explode false', () {
      final simple = allOf.toSimple(explode: false, allowEmpty: true);
      final reconstructed = AllOfDoubleList.fromSimple(simple, explode: false);
      expect(reconstructed, allOf);
    });

    test('toMatrix - explode false', () {
      expect(
        allOf.toMatrix('x', explode: false, allowEmpty: true),
        ';x=2021-01-01T00%3A00%3A00.000Z,2021-01-02T00%3A00%3A00.000Z',
      );
    });

    test('toMatrix - explode true', () {
      expect(
        allOf.toMatrix('list', explode: true, allowEmpty: true),
        ';list=2021-01-01T00%3A00%3A00.000Z;list=2021-01-02T00%3A00%3A00.000Z',
      );
    });

    test('toLabel - explode true', () {
      expect(
        allOf.toLabel(explode: true, allowEmpty: true),
        '.2021-01-01T00%3A00%3A00.000Z.2021-01-02T00%3A00%3A00.000Z',
      );
    });

    test('toLabel - explode false', () {
      expect(
        allOf.toLabel(explode: false, allowEmpty: true),
        '.2021-01-01T00%3A00%3A00.000Z,2021-01-02T00%3A00%3A00.000Z',
      );
    });

    test('currentEncodingShape', () {
      expect(allOf.currentEncodingShape, EncodingShape.complex);
    });
  });

  group('AllOfOneOfDoubleList', () {
    group('string', () {
      late AllOfOneOfDoubleList allOf;

      setUp(() {
        allOf = AllOfOneOfDoubleList(
          list: [DateTime.utc(2021), DateTime.utc(2021, 1, 2)],
          list2: [
            AllOfOneOfDoubleListArrayOneOfModelString(
              DateTime.utc(2021).toTimeZonedIso8601String(),
            ),
            AllOfOneOfDoubleListArrayOneOfModelString(
              DateTime.utc(2021, 1, 2).toTimeZonedIso8601String(),
            ),
          ],
        );
      });

      test('toJson', () {
        expect(allOf.toJson(), [
          '2021-01-01T00:00:00.000Z',
          '2021-01-02T00:00:00.000Z',
        ]);
      });

      test('json roundtrip', () {
        final json = allOf.toJson();
        final reconstructed = AllOfOneOfDoubleList.fromJson(json);
        expect(reconstructed, allOf);
      });

      test('toForm - explode true', () {
        expect(
          allOf.toForm(explode: true, allowEmpty: true),
          '2021-01-01T00%3A00%3A00.000Z,2021-01-02T00%3A00%3A00.000Z',
        );
      });

      test('form roundtrip - explode true', () {
        final form = allOf.toForm(explode: true, allowEmpty: true);
        final reconstructed = AllOfOneOfDoubleList.fromForm(
          form,
          explode: true,
        );
        expect(reconstructed, allOf);
      });

      test('toForm - explode false', () {
        expect(
          allOf.toForm(explode: false, allowEmpty: true),
          '2021-01-01T00%3A00%3A00.000Z,2021-01-02T00%3A00%3A00.000Z',
        );
      });

      test('form roundtrip - explode false', () {
        final form = allOf.toForm(explode: false, allowEmpty: true);
        final reconstructed = AllOfOneOfDoubleList.fromForm(
          form,
          explode: false,
        );
        expect(reconstructed, allOf);
      });

      test('toSimple - explode true', () {
        expect(
          allOf.toSimple(explode: true, allowEmpty: true),
          '2021-01-01T00%3A00%3A00.000Z,2021-01-02T00%3A00%3A00.000Z',
        );
      });

      test('simple roundtrip - explode true', () {
        final simple = allOf.toSimple(explode: true, allowEmpty: true);
        final reconstructed = AllOfOneOfDoubleList.fromSimple(
          simple,
          explode: true,
        );
        expect(reconstructed, allOf);
      });

      test('toSimple - explode false', () {
        expect(
          allOf.toSimple(explode: false, allowEmpty: true),
          '2021-01-01T00%3A00%3A00.000Z,2021-01-02T00%3A00%3A00.000Z',
        );
      });

      test('simple roundtrip - explode false', () {
        final simple = allOf.toSimple(explode: false, allowEmpty: true);
        final reconstructed = AllOfOneOfDoubleList.fromSimple(
          simple,
          explode: false,
        );
        expect(reconstructed, allOf);
      });

      test('toMatrix - explode false', () {
        expect(
          allOf.toMatrix('x', explode: false, allowEmpty: true),
          ';x=2021-01-01T00%3A00%3A00.000Z,2021-01-02T00%3A00%3A00.000Z',
        );
      });

      test('toMatrix - explode true', () {
        expect(
          allOf.toMatrix('list', explode: true, allowEmpty: true),
          ''';list=2021-01-01T00%3A00%3A00.000Z;list=2021-01-02T00%3A00%3A00.000Z''',
        );
      });

      test('toLabel - explode true', () {
        expect(
          allOf.toLabel(explode: true, allowEmpty: true),
          '.2021-01-01T00%3A00%3A00.000Z.2021-01-02T00%3A00%3A00.000Z',
        );
      });

      test('toLabel - explode false', () {
        expect(
          allOf.toLabel(explode: false, allowEmpty: true),
          '.2021-01-01T00%3A00%3A00.000Z,2021-01-02T00%3A00%3A00.000Z',
        );
      });

      test('currentEncodingShape', () {
        expect(allOf.currentEncodingShape, EncodingShape.complex);
      });
    });

    group('integer', () {
      late AllOfOneOfDoubleList allOf;

      setUp(() {
        allOf = AllOfOneOfDoubleList(
          list: [DateTime.utc(2021), DateTime.utc(2021, 1, 2)],
          list2: const [
            AllOfOneOfDoubleListArrayOneOfModelInt(1),
            AllOfOneOfDoubleListArrayOneOfModelInt(2),
          ],
        );
      });

      test('toJson throws EncodingException', () {
        expect(allOf.toJson, throwsA(isA<EncodingException>()));
      });

      test('toForm throws EncodingException', () {
        expect(
          () => allOf.toForm(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toSimple throws EncodingException', () {
        expect(
          () => allOf.toSimple(explode: false, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toMatrix throws EncodingException', () {
        expect(
          () => allOf.toMatrix('y', explode: false, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('toLabel throws EncodingException', () {
        expect(
          () => allOf.toLabel(explode: true, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('currentEncodingShape', () {
        expect(allOf.currentEncodingShape, EncodingShape.complex);
      });
    });
  });

  group('AllOfDirectPrimitive', () {
    late AllOfDirectPrimitive allOf;

    setUp(() {
      allOf = const AllOfDirectPrimitive(num: 1, int: 1);
    });

    test('toJson', () {
      expect(allOf.toJson(), 1);
    });

    test('json roundtrip', () {
      final json = allOf.toJson();
      final reconstructed = AllOfDirectPrimitive.fromJson(json);
      expect(reconstructed, allOf);
    });

    test('toForm - explode true', () {
      expect(allOf.toForm(explode: true, allowEmpty: true), '1');
    });

    test('form roundtrip - explode true', () {
      final form = allOf.toForm(explode: true, allowEmpty: true);
      final reconstructed = AllOfDirectPrimitive.fromForm(form, explode: true);
      expect(reconstructed, allOf);
    });

    test('toForm - explode false', () {
      expect(allOf.toForm(explode: false, allowEmpty: true), '1');
    });

    test('form roundtrip - explode false', () {
      final form = allOf.toForm(explode: false, allowEmpty: true);
      final reconstructed = AllOfDirectPrimitive.fromForm(form, explode: false);
      expect(reconstructed, allOf);
    });

    test('toSimple - explode true', () {
      expect(allOf.toSimple(explode: true, allowEmpty: true), '1');
    });

    test('simple roundtrip - explode true', () {
      final simple = allOf.toSimple(explode: true, allowEmpty: true);
      final reconstructed = AllOfDirectPrimitive.fromSimple(
        simple,
        explode: true,
      );
      expect(reconstructed, allOf);
    });

    test('toSimple - explode false', () {
      expect(allOf.toSimple(explode: false, allowEmpty: true), '1');
    });

    test('simple roundtrip - explode false', () {
      final simple = allOf.toSimple(explode: false, allowEmpty: true);
      final reconstructed = AllOfDirectPrimitive.fromSimple(
        simple,
        explode: false,
      );
      expect(reconstructed, allOf);
    });

    test('toMatrix - explode false', () {
      expect(allOf.toMatrix('x', explode: false, allowEmpty: true), ';x=1');
    });

    test('toMatrix - explode true', () {
      expect(allOf.toMatrix('x', explode: true, allowEmpty: true), ';x=1');
    });

    test('toLabel - explode true', () {
      expect(allOf.toLabel(explode: true, allowEmpty: true), '.1');
    });

    test('toLabel - explode false', () {
      expect(allOf.toLabel(explode: false, allowEmpty: true), '.1');
    });

    test('currentEncodingShape', () {
      expect(allOf.currentEncodingShape, EncodingShape.simple);
    });
  });
}
