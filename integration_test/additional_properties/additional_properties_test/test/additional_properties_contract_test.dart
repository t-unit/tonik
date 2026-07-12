// Behavioral contract for additionalProperties handling across JSON and
// flat (simple/form/label/matrix/deepObject) encodings. Expected wire
// values are literal; they are never derived through tonik encoders.
// ignore_for_file: prefer_const_literals_to_create_immutables

import 'package:additional_properties_api/additional_properties_api.dart';
import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  // -------------------------------------------------------------------
  // Bare type: object property (free-form object)
  // -------------------------------------------------------------------

  group('FreeformHolder (bare type: object property)', () {
    test('fromJson/toJson round-trips arbitrary freeform content', () {
      final holder = FreeformHolder.fromJson({
        'id': 'abc',
        'freeform': {
          'a': 1,
          'b': 'hello',
          'nested': {'x': true},
        },
      });

      expect(holder.toJson(), {
        'id': 'abc',
        'freeform': {
          'a': 1,
          'b': 'hello',
          'nested': {'x': true},
        },
      });
    });
  });

  // -------------------------------------------------------------------
  // Enum-valued additionalProperties: simple/form decode and encode
  // -------------------------------------------------------------------

  group('MixedEnumAp (enum-valued AP)', () {
    test('fromSimple decodes enum-valued additional properties', () {
      final obj = MixedEnumAp.fromSimple(
        'name=server-a,web=active,db=pending',
        explode: true,
      );

      expect(obj.name, 'server-a');
      expect(obj.additionalProperties, {
        'web': Status.active,
        'db': Status.pending,
      });
    });

    test('fromForm decodes enum-valued additional properties', () {
      final obj = MixedEnumAp.fromForm(
        'name=server-a&web=active&db=pending',
        explode: true,
      );

      expect(obj.name, 'server-a');
      expect(obj.additionalProperties, {
        'web': Status.active,
        'db': Status.pending,
      });
    });

    test('toSimple encodes enum-valued additional properties', () {
      const obj = MixedEnumAp(
        name: 'server-a',
        additionalProperties: {'web': Status.active, 'db': Status.pending},
      );

      expect(
        obj.toSimple(explode: true, allowEmpty: true),
        'name=server-a,web=active,db=pending',
      );
    });

    test('toJson encodes enum-valued additional properties as raw values', () {
      const obj = MixedEnumAp(
        name: 'server-a',
        additionalProperties: {'web': Status.active},
      );

      expect(obj.toJson(), {'name': 'server-a', 'web': 'active'});
    });
  });

  // -------------------------------------------------------------------
  // Unrestricted AP values in flat encodings
  // -------------------------------------------------------------------

  group('MixedUntyped flat encoding of unrestricted AP values', () {
    test('toSimple encodes string, int, and bool AP values as scalars', () {
      const obj = MixedUntyped(
        id: 1,
        name: 'n',
        additionalProperties: {'s': 'hi', 'i': 7, 'b': true},
      );

      expect(
        obj.toSimple(explode: true, allowEmpty: true),
        'id=1,name=n,s=hi,i=7,b=true',
      );
    });

    test('toForm encodes DateTime AP values in ISO 8601', () {
      final obj = MixedUntyped(
        id: 1,
        name: 'n',
        additionalProperties: {'ts': DateTime.utc(2024, 1, 15, 10, 30)},
      );

      expect(obj.toForm('body', explode: true, allowEmpty: true), [
        (name: 'id', value: '1'),
        (name: 'name', value: 'n'),
        (name: 'ts', value: '2024-01-15T10%3A30%3A00.000Z'),
      ]);
    });

    test('parameterProperties throws EncodingException for map AP values', () {
      const obj = MixedUntyped(
        id: 1,
        name: 'n',
        additionalProperties: {
          'meta': {'level': 1},
        },
      );

      expect(
        () => obj.parameterProperties(),
        throwsA(isA<EncodingException>()),
      );
    });

    test('toForm throws EncodingException for list AP values', () {
      const obj = MixedUntyped(
        id: 1,
        name: 'n',
        additionalProperties: {
          'tags': ['x', 'y'],
        },
      );

      expect(
        () => obj.toForm('body', explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
    });

    test('toSimple throws EncodingException for custom object AP values', () {
      const obj = MixedUntyped(
        id: 1,
        name: 'n',
        additionalProperties: {'obj': Object()},
      );

      expect(
        () => obj.toSimple(explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
    });

    test('toForm omits null AP entries', () {
      const obj = MixedUntyped(
        id: 1,
        name: 'n',
        additionalProperties: {'note': null},
      );

      expect(obj.toForm('body', explode: true, allowEmpty: true), [
        (name: 'id', value: '1'),
        (name: 'name', value: 'n'),
      ]);
    });

    test('toSimple omits null AP entries', () {
      const obj = MixedUntyped(
        id: 1,
        name: 'n',
        additionalProperties: {'note': null},
      );

      expect(obj.toSimple(explode: true, allowEmpty: true), 'id=1,name=n');
    });

    test('toForm keeps empty-string AP values as key=', () {
      const obj = MixedUntyped(
        id: 1,
        name: 'n',
        additionalProperties: {'note': ''},
      );

      expect(obj.toForm('body', explode: true, allowEmpty: true), [
        (name: 'id', value: '1'),
        (name: 'name', value: 'n'),
        (name: 'note', value: ''),
      ]);
    });
  });

  // -------------------------------------------------------------------
  // Typed nullable AP values in flat encodings
  // -------------------------------------------------------------------

  group('MixedNullableValues flat encoding', () {
    test('toForm omits null typed AP entries', () {
      const obj = MixedNullableValues(
        name: 'n',
        additionalProperties: {'gone': null, 'kept': 'v'},
      );

      expect(obj.toForm('body', explode: true, allowEmpty: true), [
        (name: 'name', value: 'n'),
        (name: 'kept', value: 'v'),
      ]);
    });
  });

  // -------------------------------------------------------------------
  // Unrestricted AP values in JSON
  // -------------------------------------------------------------------

  group('MixedUntyped JSON encoding of unrestricted AP values', () {
    test('toJson keeps nested JSON maps and lists', () {
      const obj = MixedUntyped(
        id: 1,
        name: 'n',
        additionalProperties: {
          'meta': {
            'level': 1,
            'flags': [true, false],
          },
        },
      );

      expect(obj.toJson(), {
        'id': 1,
        'name': 'n',
        'meta': {
          'level': 1,
          'flags': [true, false],
        },
      });
    });

    test('toJson encodes DateTime AP values as ISO 8601 strings', () {
      final obj = MixedUntyped(
        id: 1,
        name: 'n',
        additionalProperties: {'ts': DateTime.utc(2024, 1, 15, 10, 30)},
      );

      expect(obj.toJson(), {
        'id': 1,
        'name': 'n',
        'ts': '2024-01-15T10:30:00.000Z',
      });
    });

    test('toJson encodes DateTime values nested in list AP values', () {
      final obj = MixedUntyped(
        id: 1,
        name: 'n',
        additionalProperties: {
          'stamps': [DateTime.utc(2024, 1, 15, 10, 30)],
        },
      );

      expect(obj.toJson(), {
        'id': 1,
        'name': 'n',
        'stamps': ['2024-01-15T10:30:00.000Z'],
      });
    });

    test('toJson throws EncodingException for non-string map keys in AP '
        'values', () {
      const obj = MixedUntyped(
        id: 1,
        name: 'n',
        additionalProperties: {
          'm': {1: 'a'},
        },
      );

      expect(() => obj.toJson(), throwsA(isA<EncodingException>()));
    });

    test('toJson throws EncodingException for custom object AP values', () {
      const obj = MixedUntyped(
        id: 1,
        name: 'n',
        additionalProperties: {'obj': Object()},
      );

      expect(obj.toJson, throwsA(isA<EncodingException>()));
    });
  });

  // -------------------------------------------------------------------
  // Any-valued collections in JSON
  // -------------------------------------------------------------------

  group('AnyCollectionHolder (Any-valued map property)', () {
    test('toJson converts DateTime values inside the Any map', () {
      final obj = AnyCollectionHolder(
        lookup: {'ts': DateTime.utc(2024, 1, 15, 10, 30)},
      );

      expect(obj.toJson(), {
        'lookup': {'ts': '2024-01-15T10:30:00.000Z'},
      });
    });

    test('toJson keeps plain JSON content inside the Any map', () {
      const obj = AnyCollectionHolder(
        lookup: {
          'k': 'v',
          'nested': {
            'flags': [true],
          },
        },
      );

      expect(obj.toJson(), {
        'lookup': {
          'k': 'v',
          'nested': {
            'flags': [true],
          },
        },
      });
    });

    test('toJson throws EncodingException for unsupported values inside '
        'the Any map', () {
      const obj = AnyCollectionHolder(lookup: {'bad': Object()});

      expect(obj.toJson, throwsA(isA<EncodingException>()));
    });

    test('json round-trip preserves Any map content', () {
      final decoded = AnyCollectionHolder.fromJson({
        'lookup': {
          'k': 'v',
          'nested': {'flag': true},
        },
      });

      expect(decoded.toJson(), {
        'lookup': {
          'k': 'v',
          'nested': {'flag': true},
        },
      });
    });
  });

  // -------------------------------------------------------------------
  // Typed AP wire parity with declared properties
  // -------------------------------------------------------------------

  group('MixedTypedString typed AP wire parity', () {
    test('toForm encodes an AP value identically to a declared property', () {
      const obj = MixedTypedString(
        id: 1,
        label: 'a b',
        additionalProperties: {'note': 'a b'},
      );

      expect(obj.toForm('body', explode: true, allowEmpty: true), [
        (name: 'id', value: '1'),
        (name: 'label', value: 'a%20b'),
        (name: 'note', value: 'a%20b'),
      ]);
    });

    test('toLabel includes AP entries', () {
      const obj = MixedTypedString(
        id: 1,
        label: 'hi',
        additionalProperties: {'extra': 'val'},
      );

      expect(
        obj.toLabel(explode: true, allowEmpty: true),
        '.id=1.label=hi.extra=val',
      );
    });

    test('toMatrix includes AP entries', () {
      const obj = MixedTypedString(
        id: 1,
        label: 'hi',
        additionalProperties: {'extra': 'val'},
      );

      expect(
        obj.toMatrix('filter', explode: true, allowEmpty: true),
        ';id=1;label=hi;extra=val',
      );
    });

    test('toDeepObject emits scalar AP entries as param[key]=value', () {
      const obj = MixedTypedString(
        id: 1,
        label: 'hi',
        additionalProperties: {'extra': 'val'},
      );

      expect(obj.toDeepObject('filter', explode: true, allowEmpty: true), [
        (name: 'filter[id]', value: '1'),
        (name: 'filter[label]', value: 'hi'),
        (name: 'filter[extra]', value: 'val'),
      ]);
    });
  });

  group('MixedUntyped deepObject encoding', () {
    test('toDeepObject throws EncodingException for map AP values', () {
      const obj = MixedUntyped(
        id: 1,
        name: 'n',
        additionalProperties: {
          'meta': {'level': 1},
        },
      );

      expect(
        () => obj.toDeepObject('filter', explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
    });
  });

  // -------------------------------------------------------------------
  // Declared/AP wire key collisions
  // -------------------------------------------------------------------

  group('declared/AP key collisions', () {
    test('toJson throws when an AP key collides with a declared wire key', () {
      const obj = MixedTypedString(
        id: 1,
        label: 'declared',
        additionalProperties: {'label': 'shadow'},
      );

      expect(() => obj.toJson(), throwsA(isA<EncodingException>()));
    });

    test('toForm throws when an AP key collides with a declared wire key', () {
      const obj = MixedTypedString(
        id: 1,
        label: 'declared',
        additionalProperties: {'label': 'shadow'},
      );

      expect(
        () => obj.toForm('body', explode: true, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
    });
  });

  // -------------------------------------------------------------------
  // Active AP with no request-readable declared properties
  // -------------------------------------------------------------------

  group('AuditedSettings (read-only declared property with active AP)', () {
    test('toForm emits AP entries', () {
      const obj = AuditedSettings(additionalProperties: {'theme': 'dark'});

      expect(obj.toForm('body', explode: true, allowEmpty: true), [
        (name: 'theme', value: 'dark'),
      ]);
    });

    test('toSimple emits AP entries', () {
      const obj = AuditedSettings(additionalProperties: {'theme': 'dark'});

      expect(obj.toSimple(explode: true, allowEmpty: true), 'theme=dark');
    });

    test('fromSimple captures AP entries', () {
      final obj = AuditedSettings.fromSimple('theme=dark', explode: true);

      expect(obj.additionalProperties, {'theme': 'dark'});
    });
  });

  // -------------------------------------------------------------------
  // allOf additionalProperties
  // -------------------------------------------------------------------

  group('ExtendedPerson (allOf with string-valued AP)', () {
    test('fromSimple captures string AP beyond all member keys', () {
      final obj = ExtendedPerson.fromSimple(
        'firstName=Ada,lastName=L,email=a@b.c,nick=JD',
        explode: true,
      );

      expect(obj.additionalProperties, {'nick': 'JD'});
    });
  });

  group('ExtendedScores (allOf with integer-valued AP)', () {
    test('fromSimple decodes integer AP beyond all member keys', () {
      final obj = ExtendedScores.fromSimple(
        'firstName=Ada,lastName=L,grade=A,math=90',
        explode: true,
      );

      expect(obj.additionalProperties, {'math': 90});
    });

    test('toSimple encodes integer AP entries', () {
      const obj = ExtendedScores(
        person: Person(firstName: 'Ada', lastName: 'L'),
        extendedScoresModel: ExtendedScoresModel(grade: 'A'),
        additionalProperties: {'math': 90},
      );

      expect(
        obj.toSimple(explode: true, allowEmpty: true),
        'firstName=Ada,lastName=L,grade=A,math=90',
      );
    });
  });
}
