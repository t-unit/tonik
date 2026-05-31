import 'package:defaulted_primitives_api/defaulted_primitives_api.dart';
import 'package:test/test.dart';

void main() {
  group('DefaultedPrimitives — Strategy A const defaults', () {
    test('constructor with no args yields all defaults', () {
      const value = DefaultedPrimitives();
      expect(value.name, 'anon');
      expect(value.count, 0);
      expect(value.rate, 1.5);
      expect(value.active, isTrue);
      expect(value.nickname, isNull);
      expect(value.title, 'Mx.');
    });

    test('public static const exposes default value', () {
      expect(DefaultedPrimitives.nameDefault, 'anon');
      expect(DefaultedPrimitives.countDefault, 0);
      expect(DefaultedPrimitives.rateDefault, 1.5);
      expect(DefaultedPrimitives.activeDefault, isTrue);
      expect(DefaultedPrimitives.titleDefault, 'Mx.');
    });

    test('fromJson with empty map yields all defaults', () {
      final value = DefaultedPrimitives.fromJson(const <String, Object?>{});
      expect(value.name, 'anon');
      expect(value.count, 0);
      expect(value.rate, 1.5);
      expect(value.active, isTrue);
      expect(value.nickname, isNull);
      expect(value.title, 'Mx.');
    });

    test('fromJson supplied keys override defaults', () {
      final value = DefaultedPrimitives.fromJson(const <String, Object?>{
        'name': 'alice',
        'count': 7,
        'rate': 9.25,
        'active': false,
      });
      expect(value.name, 'alice');
      expect(value.count, 7);
      expect(value.rate, 9.25);
      expect(value.active, isFalse);
    });

    test(
      'D15: explicit null on a nullable defaulted field decodes to null, '
      'NOT the default',
      () {
        final value = DefaultedPrimitives.fromJson(const <String, Object?>{
          'title': null,
        });
        expect(value.title, isNull);
      },
    );

    test('missing key on nullable defaulted field falls through to default',
        () {
      final value = DefaultedPrimitives.fromJson(const <String, Object?>{
        'name': 'alice',
      });
      expect(value.title, 'Mx.');
    });

    test(
      'D14: nickname (nullable + default: null) carries no default — '
      'explicit null decodes to null',
      () {
        final value = DefaultedPrimitives.fromJson(const <String, Object?>{
          'nickname': null,
        });
        expect(value.nickname, isNull);
      },
    );

    test(
      'D14: nickname (nullable + default: null) carries no default — '
      'missing key decodes to null (nullable field has no fallback)',
      () {
        final value = DefaultedPrimitives.fromJson(const <String, Object?>{});
        expect(value.nickname, isNull);
      },
    );

    test('missing key falls through to default', () {
      final value = DefaultedPrimitives.fromJson(const <String, Object?>{
        'name': 'alice',
      });
      expect(value.name, 'alice');
      expect(value.count, 0);
      expect(value.rate, 1.5);
      expect(value.active, isTrue);
      expect(value.nickname, isNull);
      expect(value.title, 'Mx.');
    });

    test('round-trip: fromJson(toJson(...)) yields an equal instance', () {
      const original = DefaultedPrimitives();
      final encoded = original.toJson()! as Map<String, Object?>;
      final decoded = DefaultedPrimitives.fromJson(encoded);
      expect(decoded, original);
    });

    test('round-trip with custom values', () {
      const original = DefaultedPrimitives(
        name: 'alice',
        count: 5,
        rate: 2.5,
        active: false,
        nickname: 'al',
        title: 'Dr.',
      );
      final encoded = original.toJson()! as Map<String, Object?>;
      final decoded = DefaultedPrimitives.fromJson(encoded);
      expect(decoded, original);
    });
  });
}
