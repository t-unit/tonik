// Test file uses many map literals passed to fromJson/constructors.
// ignore_for_file: prefer_const_literals_to_create_immutables

import 'package:additional_properties_api/additional_properties_api.dart';
import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  // -------------------------------------------------------------------
  // 1. Pure maps (typedefs)
  // -------------------------------------------------------------------

  group('StringMap (pure map typedef)', () {
    test('is a typedef for Map<String, String>', () {
      const map = <String, String>{'a': 'hello', 'b': 'world'};
      expect(map, isA<StringMap>());
      expect(map['a'], 'hello');
    });
  });

  group('IntegerMap (pure map typedef)', () {
    test('is a typedef for Map<String, int>', () {
      const map = <String, int>{'count': 1, 'total': 42};
      expect(map, isA<IntegerMap>());
      expect(map['count'], 1);
    });
  });

  group('UntypedMap (pure map typedef)', () {
    test('is a typedef for Map<String, Object?>', () {
      const map = <String, Object?>{'key': 'value', 'num': 42, 'nil': null};
      expect(map, isA<UntypedMap>());
    });
  });

  group('ObjectValueMap (pure map typedef)', () {
    test('is a typedef for Map<String, Address>', () {
      final map = <String, Address>{
        'home': const Address(street: '123 Main', city: 'Springfield'),
      };
      expect(map, isA<ObjectValueMap>());
    });
  });

  group('NestedMap (pure map typedef)', () {
    test('is a typedef for Map<String, Map<String, String>>', () {
      const map = <String, Map<String, String>>{
        'section': {'key': 'value'},
      };
      expect(map, isA<NestedMap>());
    });
  });

  group('NumberMap (pure map typedef)', () {
    test('is a typedef for Map<String, num>', () {
      const map = <String, num>{'score': 9.5, 'count': 3};
      expect(map, isA<NumberMap>());
      expect(map['score'], 9.5);
    });
  });

  group('BooleanMap (pure map typedef)', () {
    test('is a typedef for Map<String, bool>', () {
      const map = <String, bool>{'active': true, 'deleted': false};
      expect(map, isA<BooleanMap>());
      expect(map['active'], isTrue);
    });
  });

  group('ArrayValueMap (pure map typedef)', () {
    test('is a typedef for Map<String, List<String>>', () {
      const map = <String, List<String>>{
        'tags': ['a', 'b'],
        'roles': ['admin'],
      };
      expect(map, isA<ArrayValueMap>());
      expect(map['tags'], ['a', 'b']);
    });
  });

  group('EnumValueMap (pure map typedef)', () {
    test('is a typedef for Map<String, EnumValueMapModel>', () {
      const map = <String, EnumValueMapModel>{
        'priority': EnumValueMapModel.high,
        'severity': EnumValueMapModel.low,
      };
      expect(map, isA<EnumValueMap>());
      expect(map['priority'], EnumValueMapModel.high);
    });

    test('enum values are correct', () {
      expect(EnumValueMapModel.values, hasLength(3));
      expect(
        EnumValueMapModel.values.map((e) => e.rawValue),
        containsAll(['low', 'medium', 'high']),
      );
    });
  });

  // -------------------------------------------------------------------
  // 2. additionalProperties: false (no-op)
  // -------------------------------------------------------------------

  group('StrictObject (additionalProperties: false)', () {
    test('has no map field', () {
      const obj = StrictObject(id: 1, name: 'test');
      expect(obj.id, 1);
      expect(obj.name, 'test');
      // No additionalProperties field exists — verified by compilation.
    });

    test('json roundtrip', () {
      const obj = StrictObject(id: 1, name: 'test');
      final json = obj.toJson();
      final decoded = StrictObject.fromJson(json);
      expect(decoded, obj);
    });
  });

  // -------------------------------------------------------------------
  // 3. Mixed: named properties + additionalProperties: true
  // -------------------------------------------------------------------

  group('MixedUntyped', () {
    test('constructor with additional properties', () {
      const obj = MixedUntyped(
        id: 1,
        name: 'test',
        additionalProperties: <String, Object?>{'extra': 'value', 'count': 42},
      );
      expect(obj.id, 1);
      expect(obj.name, 'test');
      expect(obj.additionalProperties, {'extra': 'value', 'count': 42});
    });

    test('defaults to empty map', () {
      const obj = MixedUntyped(id: 1, name: 'test');
      expect(obj.additionalProperties, isEmpty);
    });

    test('toJson spreads additional properties', () {
      const obj = MixedUntyped(
        id: 1,
        name: 'test',
        additionalProperties: {'extra': 'value'},
      );
      expect(obj.toJson(), {
        'id': 1,
        'name': 'test',
        'extra': 'value',
      });
    });

    test('fromJson collects unknown keys', () {
      final obj = MixedUntyped.fromJson({
        'id': 1,
        'name': 'test',
        'extra': 'value',
        'count': 42,
      });
      expect(obj.id, 1);
      expect(obj.name, 'test');
      expect(obj.additionalProperties, {'extra': 'value', 'count': 42});
    });

    test('json roundtrip preserves additional properties', () {
      const obj = MixedUntyped(
        id: 1,
        name: 'test',
        additionalProperties: {'extra': 'hello'},
      );
      final json = obj.toJson();
      final decoded = MixedUntyped.fromJson(json);
      expect(decoded, obj);
    });

    test('json roundtrip with no additional properties', () {
      const obj = MixedUntyped(id: 1, name: 'test');
      final json = obj.toJson();
      final decoded = MixedUntyped.fromJson(json);
      expect(decoded, obj);
    });

    test('equality considers additional properties', () {
      const a = MixedUntyped(
        id: 1,
        name: 'test',
        additionalProperties: {'k': 'v'},
      );
      const b = MixedUntyped(
        id: 1,
        name: 'test',
        additionalProperties: {'k': 'v'},
      );
      const c = MixedUntyped(
        id: 1,
        name: 'test',
        additionalProperties: {'k': 'other'},
      );
      expect(a, b);
      expect(a, isNot(c));
    });

    test('hashCode considers additional properties', () {
      const a = MixedUntyped(
        id: 1,
        name: 'test',
        additionalProperties: {'k': 'v'},
      );
      const b = MixedUntyped(
        id: 1,
        name: 'test',
        additionalProperties: {'k': 'v'},
      );
      expect(a.hashCode, b.hashCode);
    });

    test('copyWith preserves additional properties', () {
      const obj = MixedUntyped(
        id: 1,
        name: 'test',
        additionalProperties: {'k': 'v'},
      );
      final copy = obj.copyWith(name: 'updated');
      expect(copy.name, 'updated');
      expect(copy.additionalProperties, {'k': 'v'});
    });

    test('copyWith can replace additional properties', () {
      const obj = MixedUntyped(
        id: 1,
        name: 'test',
        additionalProperties: {'k': 'v'},
      );
      final copy = obj.copyWith(
        additionalProperties: {'new': 'value'},
      );
      expect(copy.additionalProperties, {'new': 'value'});
    });
  });

  // -------------------------------------------------------------------
  // 4. Mixed: named properties + typed additionalProperties
  // -------------------------------------------------------------------

  group('MixedTypedString', () {
    test('toJson spreads typed string AP', () {
      const obj = MixedTypedString(
        id: 1,
        label: 'test',
        additionalProperties: {'tag': 'important'},
      );
      expect(obj.toJson(), {
        'id': 1,
        'label': 'test',
        'tag': 'important',
      });
    });

    test('fromJson decodes typed string AP', () {
      final obj = MixedTypedString.fromJson({
        'id': 1,
        'label': 'test',
        'tag': 'important',
        'category': 'docs',
      });
      expect(
        obj.additionalProperties,
        {'tag': 'important', 'category': 'docs'},
      );
    });

    test('json roundtrip', () {
      const obj = MixedTypedString(
        id: 1,
        additionalProperties: {'x': 'y'},
      );
      final json = obj.toJson();
      final decoded = MixedTypedString.fromJson(json);
      expect(decoded, obj);
    });

    test('fromSimple captures string AP', () {
      final obj = MixedTypedString.fromSimple(
        'id=1,label=hi,extra=val',
        explode: true,
      );
      expect(obj.id, 1);
      expect(obj.label, 'hi');
      expect(obj.additionalProperties, {'extra': 'val'});
    });

    test('fromForm captures string AP', () {
      final obj = MixedTypedString.fromForm(
        'id=1&label=hi&extra=val',
        explode: true,
      );
      expect(obj.id, 1);
      expect(obj.label, 'hi');
      expect(obj.additionalProperties, {'extra': 'val'});
    });
  });

  // -------------------------------------------------------------------
  // 5. Mixed: named properties + complex ($ref) additionalProperties
  // -------------------------------------------------------------------

  group('MixedTypedObject', () {
    test('toJson encodes complex AP values via toJson', () {
      const obj = MixedTypedObject(
        primaryAddress: Address(street: '1 Main', city: 'NYC'),
        additionalProperties: {
          'work': Address(street: '2 Office', city: 'LA'),
        },
      );
      final json = obj.toJson()! as Map<String, Object?>;
      expect(json['primaryAddress'], {
        'street': '1 Main',
        'city': 'NYC',
      });
      expect(json['work'], {
        'street': '2 Office',
        'city': 'LA',
      });
    });

    test('fromJson decodes complex AP values', () {
      final obj = MixedTypedObject.fromJson({
        'primaryAddress': {'street': '1 Main', 'city': 'NYC'},
        'work': {'street': '2 Office', 'city': 'LA'},
      });
      expect(
        obj.additionalProperties['work'],
        const Address(street: '2 Office', city: 'LA'),
      );
    });

    test('json roundtrip', () {
      const obj = MixedTypedObject(
        primaryAddress: Address(street: '1 Main', city: 'NYC'),
        additionalProperties: {
          'work': Address(street: '2 Office', city: 'LA'),
        },
      );
      final json = obj.toJson();
      final decoded = MixedTypedObject.fromJson(json);
      expect(decoded, obj);
    });
  });

  // -------------------------------------------------------------------
  // 6. Field name collision
  // -------------------------------------------------------------------

  group('CollisionModel', () {
    test('property named additionalProperties coexists with AP map', () {
      const obj = CollisionModel(
        additionalProperties: 'prop-value',
        name: 'test',
        additionalProperties2: {'extra': 42},
      );
      // The named property
      expect(obj.additionalProperties, 'prop-value');
      // The generated AP map field
      expect(obj.additionalProperties2, {'extra': 42});
    });

    test('toJson includes both', () {
      const obj = CollisionModel(
        additionalProperties: 'prop-value',
        additionalProperties2: {'score': 99},
      );
      expect(obj.toJson(), {
        'additionalProperties': 'prop-value',
        'score': 99,
      });
    });

    test('fromJson separates named vs additional', () {
      final obj = CollisionModel.fromJson({
        'additionalProperties': 'prop-value',
        'name': 'test',
        'score': 99,
      });
      expect(obj.additionalProperties, 'prop-value');
      expect(obj.name, 'test');
      expect(obj.additionalProperties2, {'score': 99});
    });

    test('json roundtrip', () {
      const obj = CollisionModel(
        additionalProperties: 'prop-value',
        additionalProperties2: {'score': 99},
      );
      final json = obj.toJson();
      final decoded = CollisionModel.fromJson(json);
      expect(decoded, obj);
    });
  });

  // -------------------------------------------------------------------
  // 7. AllOf with additionalProperties
  // -------------------------------------------------------------------

  group('ExtendedPerson (allOf + AP)', () {
    test('fromJson collects additional keys beyond all members', () {
      final obj = ExtendedPerson.fromJson({
        'firstName': 'John',
        'lastName': 'Doe',
        'email': 'john@example.com',
        'nickname': 'JD',
      });
      expect(
        obj.additionalProperties,
        {'nickname': 'JD'},
      );
    });

    test('toJson includes additional properties', () {
      final obj = ExtendedPerson.fromJson({
        'firstName': 'John',
        'lastName': 'Doe',
        'email': 'john@example.com',
        'nickname': 'JD',
      });
      final json = obj.toJson()! as Map<String, Object?>;
      expect(json['nickname'], 'JD');
      expect(json['firstName'], 'John');
    });
  });

  // -------------------------------------------------------------------
  // 8. Nested: property whose type has AP
  // -------------------------------------------------------------------

  group('Config (nested AP types)', () {
    test('json roundtrip with nested AP types', () {
      const config = Config(
        settings: MixedUntyped(
          id: 1,
          name: 'app',
          additionalProperties: {'debug': 'true'},
        ),
        metadata: {'version': '1.0', 'env': 'prod'},
      );
      final json = config.toJson();
      final decoded = Config.fromJson(json);
      expect(decoded, config);
    });
  });

  // -------------------------------------------------------------------
  // 9. Runtime errors: invalid encodings
  // -------------------------------------------------------------------

  group('MixedComplexAp - runtime encoding errors', () {
    test('toJson works (JSON encoding always valid)', () {
      const obj = MixedComplexAp(
        id: 1,
        additionalProperties: {
          'home': Address(street: '1 Main', city: 'NYC'),
        },
      );
      expect(obj.toJson, returnsNormally);
    });

    test('parameterProperties throws when AP is non-empty', () {
      const obj = MixedComplexAp(
        id: 1,
        additionalProperties: {
          'home': Address(street: '1 Main', city: 'NYC'),
        },
      );
      expect(
        () => obj.parameterProperties(),
        throwsA(isA<EncodingException>()),
      );
    });

    test('parameterProperties succeeds when AP is empty', () {
      const obj = MixedComplexAp(id: 1);
      expect(() => obj.parameterProperties(), returnsNormally);
    });

    test('toSimple throws when AP is non-empty', () {
      const obj = MixedComplexAp(
        id: 1,
        additionalProperties: {
          'home': Address(street: '1 Main', city: 'NYC'),
        },
      );
      expect(
        () => obj.toSimple(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
    });

    test('toForm throws when AP is non-empty', () {
      const obj = MixedComplexAp(
        id: 1,
        additionalProperties: {
          'home': Address(street: '1 Main', city: 'NYC'),
        },
      );
      expect(
        () => obj.toForm(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
    });

    test('toLabel throws when AP is non-empty', () {
      const obj = MixedComplexAp(
        id: 1,
        additionalProperties: {
          'home': Address(street: '1 Main', city: 'NYC'),
        },
      );
      expect(
        () => obj.toLabel(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
    });

    test('toMatrix throws when AP is non-empty', () {
      const obj = MixedComplexAp(
        id: 1,
        additionalProperties: {
          'home': Address(street: '1 Main', city: 'NYC'),
        },
      );
      expect(
        () => obj.toMatrix('p', explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
    });
  });

  group('ClassWithMapProperty - runtime encoding errors', () {
    test('toJson works', () {
      const obj = ClassWithMapProperty(
        id: 1,
        metadata: {'key': 'value'},
      );
      expect(obj.toJson, returnsNormally);
    });

    test('parameterProperties throws (complex property)', () {
      const obj = ClassWithMapProperty(
        id: 1,
        metadata: {'key': 'value'},
      );
      expect(
        () => obj.parameterProperties(),
        throwsA(isA<EncodingException>()),
      );
    });

    test('toSimple throws (complex property)', () {
      const obj = ClassWithMapProperty(
        id: 1,
        metadata: {'key': 'value'},
      );
      expect(
        () => obj.toSimple(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
    });

    test('toForm throws (complex property)', () {
      const obj = ClassWithMapProperty(
        id: 1,
        metadata: {'key': 'value'},
      );
      expect(
        () => obj.toForm(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
    });
  });

  // -------------------------------------------------------------------
  // 10. MixedNullableValues: nullable AP value type
  // -------------------------------------------------------------------

  group('MixedNullableValues (nullable string AP values)', () {
    test('fromJson decodes null AP values without throwing', () {
      // The schema declares additionalProperties:
      //   {type: string, nullable: true}
      // so fromJson must accept null values in AP entries and not throw.
      // This test guards against regressions where the generated code
      // used a non-nullable string decoder and threw InvalidTypeException.
      final obj = MixedNullableValues.fromJson({
        'name': 'test',
        'extra': null,
        'tag': 'ok',
      });
      expect(obj.name, 'test');
      expect(obj.additionalProperties['extra'], isNull);
      expect(obj.additionalProperties['tag'], 'ok');
    });

    test('fromJson with only null AP values', () {
      // All AP values are null — must not throw.
      final obj = MixedNullableValues.fromJson({
        'name': 'test',
        'a': null,
        'b': null,
      });
      expect(obj.additionalProperties['a'], isNull);
      expect(obj.additionalProperties['b'], isNull);
    });

    test('fromJson with no AP entries', () {
      final obj = MixedNullableValues.fromJson({
        'name': 'test',
      });
      expect(obj.additionalProperties, isEmpty);
    });
  });
}
