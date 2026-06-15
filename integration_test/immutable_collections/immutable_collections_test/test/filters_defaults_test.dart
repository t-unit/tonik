import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:immutable_collections_api/immutable_collections_api.dart';
import 'package:test/test.dart';

void main() {
  group('Filters — collection const defaults under immutableCollections', () {
    test('defaults are IList / IMap typed', () {
      const value = Filters();
      expect(value.tags, isA<IList<String>>());
      expect(value.counts, isA<IMap<String, int>>());
      expect(value.raw, isA<IMap<String, Object?>>());
    });

    test('defaults carry the expected values', () {
      const value = Filters();
      expect(value.tags!.unlock, <String>['new', 'featured']);
      expect(value.counts!.unlock, <String, int>{'x': 1, 'y': 2});
      expect(
        value.raw!.unlock,
        <String, Object?>{
          'any': 'value',
          'nested': <Object?>[1, 2, 3],
        },
      );
    });

    test('public static const exposes default value', () {
      expect(Filters.tagsDefault, isA<IList<String>>());
      expect(Filters.countsDefault, isA<IMap<String, int>>());
      expect(Filters.rawDefault, isA<IMap<String, Object?>>());
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

    test('fromJson with empty map yields the defaults', () {
      final value = Filters.fromJson(const <String, Object?>{});
      expect(value.tags!.unlock, <String>['new', 'featured']);
      expect(value.counts!.unlock, <String, int>{'x': 1, 'y': 2});
      expect(
        value.raw!.unlock,
        <String, Object?>{
          'any': 'value',
          'nested': <Object?>[1, 2, 3],
        },
      );
    });

    test('fromJson supplied keys override defaults', () {
      final value = Filters.fromJson(const <String, Object?>{
        'tags': <Object?>['custom'],
        'counts': <String, Object?>{'z': 9},
      });
      expect(value.tags!.unlock, <String>['custom']);
      expect(value.counts!.unlock, <String, int>{'z': 9});
    });

    test('round-trip: fromJson(toJson(...)) yields an equal instance', () {
      const original = Filters();
      final encoded = original.toJson()! as Map<String, Object?>;
      final decoded = Filters.fromJson(encoded);
      expect(decoded, original);
    });
  });

  group(
    'BucketHolder — ClassModel default with additionalProperties under '
    'immutableCollections',
    () {
      test(
        'the static-getter default decodes the named property and populates '
        'the typed IMap<String,int> AP field correctly',
        () {
          final bucket = BucketHolder.bucketDefault;
          expect(bucket.label, 'primary');
          expect(bucket.additionalProperties, isA<IMap<String, int>>());
          expect(
            bucket.additionalProperties.unlock,
            <String, int>{'x': 1, 'y': 2},
          );
        },
      );

      test('fromJson with missing key falls through to the bucket default', () {
        final value = BucketHolder.fromJson(const <String, Object?>{});
        expect(value.bucket!.label, 'primary');
        expect(
          value.bucket!.additionalProperties.unlock,
          <String, int>{'x': 1, 'y': 2},
        );
      });

      test('AP field type is IMap<String,int>, not Map<String,int>', () {
        const value = BucketWithExtras();
        expect(value.additionalProperties, isA<IMap<String, int>>());
      });
    },
  );
}
