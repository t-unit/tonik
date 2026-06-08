import 'package:defaulted_collections_api/defaulted_collections_api.dart';
import 'package:test/test.dart';

void main() {
  group('Filters — collection const defaults', () {
    test('constructor with no args yields all defaults', () {
      const value = Filters();
      expect(value.tags, const <String>['new', 'featured']);
      expect(value.counts, const <String, int>{'x': 1, 'y': 2});
      expect(
        value.raw,
        const <String, Object?>{
          'any': 'value',
          'nested': <Object?>[1, 2, 3],
        },
      );
    });

    test('public static const exposes default value', () {
      expect(Filters.tagsDefault, const <String>['new', 'featured']);
      expect(Filters.countsDefault, const <String, int>{'x': 1, 'y': 2});
      expect(
        Filters.rawDefault,
        const <String, Object?>{
          'any': 'value',
          'nested': <Object?>[1, 2, 3],
        },
      );
    });

    test('defaults are identical-by-reference across instances', () {
      const a = Filters();
      const b = Filters();
      expect(identical(a.tags, b.tags), isTrue);
      expect(identical(a.counts, b.counts), isTrue);
      expect(identical(a.raw, b.raw), isTrue);
    });

    test('static const default is identical to constructor-default field', () {
      const value = Filters();
      expect(identical(value.tags, Filters.tagsDefault), isTrue);
      expect(identical(value.counts, Filters.countsDefault), isTrue);
      expect(identical(value.raw, Filters.rawDefault), isTrue);
    });

    test('fromJson with empty map yields all defaults', () {
      final value = Filters.fromJson(const <String, Object?>{});
      expect(value.tags, const <String>['new', 'featured']);
      expect(value.counts, const <String, int>{'x': 1, 'y': 2});
      expect(
        value.raw,
        const <String, Object?>{
          'any': 'value',
          'nested': <Object?>[1, 2, 3],
        },
      );
    });

    test('fromJson preserves const identity of defaults on missing keys', () {
      final value = Filters.fromJson(const <String, Object?>{});
      expect(identical(value.tags, Filters.tagsDefault), isTrue);
      expect(identical(value.counts, Filters.countsDefault), isTrue);
      expect(identical(value.raw, Filters.rawDefault), isTrue);
    });

    test('fromJson supplied keys override defaults', () {
      final value = Filters.fromJson(const <String, Object?>{
        'tags': <Object?>['custom'],
        'counts': <String, Object?>{'z': 9},
        'raw': <String, Object?>{'kind': 'override'},
      });
      expect(value.tags, const <String>['custom']);
      expect(value.counts, const <String, int>{'z': 9});
      expect(value.raw, const <String, Object?>{'kind': 'override'});
    });

    test('missing key falls through to default; supplied key uses value', () {
      final value = Filters.fromJson(const <String, Object?>{
        'tags': <Object?>['alpha', 'beta'],
      });
      expect(value.tags, const <String>['alpha', 'beta']);
      expect(value.counts, const <String, int>{'x': 1, 'y': 2});
      expect(
        value.raw,
        const <String, Object?>{
          'any': 'value',
          'nested': <Object?>[1, 2, 3],
        },
      );
    });

    test('round-trip: fromJson(toJson(...)) yields an equal instance', () {
      const original = Filters();
      final encoded = original.toJson()! as Map<String, Object?>;
      final decoded = Filters.fromJson(encoded);
      expect(decoded, original);
    });

    test('round-trip with custom values', () {
      const original = Filters(
        tags: <String>['alpha', 'beta'],
        counts: <String, int>{'a': 10},
        raw: <String, Object?>{'kind': 'custom'},
      );
      final encoded = original.toJson()! as Map<String, Object?>;
      final decoded = Filters.fromJson(encoded);
      expect(decoded, original);
    });
  });
}
