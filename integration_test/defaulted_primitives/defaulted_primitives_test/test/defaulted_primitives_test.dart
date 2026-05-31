import 'package:defaulted_primitives_api/defaulted_primitives_api.dart';
import 'package:test/test.dart';

void main() {
  group('DefaultedPrimitives — primitive const defaults', () {
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
      'explicit null on a nullable defaulted field decodes to null, '
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
      'nickname (nullable + default: null) carries no default — '
      'explicit null decodes to null',
      () {
        final value = DefaultedPrimitives.fromJson(const <String, Object?>{
          'nickname': null,
        });
        expect(value.nickname, isNull);
      },
    );

    test(
      'nickname (nullable + default: null) carries no default — '
      'missing key decodes to null',
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

  group('DefaultedPrimitives.fromSimple', () {
    test('all keys present uses supplied values', () {
      final value = DefaultedPrimitives.fromSimple(
        'name=alice,count=7,rate=9.25,active=false,nickname=al,title=Dr.',
        explode: true,
      );
      expect(value.name, 'alice');
      expect(value.count, 7);
      expect(value.rate, 9.25);
      expect(value.active, isFalse);
      expect(value.nickname, 'al');
      expect(value.title, 'Dr.');
    });

    test('some keys absent fall through to defaults', () {
      final value = DefaultedPrimitives.fromSimple(
        'name=alice',
        explode: true,
      );
      expect(value.name, 'alice');
      expect(value.count, 0);
      expect(value.rate, 1.5);
      expect(value.active, isTrue);
      expect(value.nickname, isNull);
      expect(value.title, 'Mx.');
    });
  });

  group('DefaultedPrimitives.fromForm', () {
    test('all keys present uses supplied values', () {
      final value = DefaultedPrimitives.fromForm(
        'name=alice&count=7&rate=9.25&active=false&nickname=al&title=Dr.',
        explode: true,
      );
      expect(value.name, 'alice');
      expect(value.count, 7);
      expect(value.rate, 9.25);
      expect(value.active, isFalse);
      expect(value.nickname, 'al');
      expect(value.title, 'Dr.');
    });

    test('some keys absent fall through to defaults', () {
      final value = DefaultedPrimitives.fromForm(
        'name=alice',
        explode: true,
      );
      expect(value.name, 'alice');
      expect(value.count, 0);
      expect(value.rate, 1.5);
      expect(value.active, isTrue);
      expect(value.nickname, isNull);
      expect(value.title, 'Mx.');
    });
  });
}
