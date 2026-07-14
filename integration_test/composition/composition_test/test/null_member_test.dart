import 'package:composition_api/composition_api.dart';
import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  group('NullMemberHolder', () {
    test('fromJson decodes null members to null', () {
      final holder = NullMemberHolder.fromJson(const {
        'oneOfValue': null,
        'oneOfRefValue': null,
        'anyOfValue': null,
      });

      expect(holder.oneOfValue, isNull);
      expect(holder.oneOfRefValue, isNull);
      expect(holder.anyOfValue, isNull);
    });

    test('json roundtrip preserves null members', () {
      final holder = NullMemberHolder.fromJson(const {
        'oneOfValue': null,
        'oneOfRefValue': null,
        'anyOfValue': null,
      });

      expect(holder.toJson(), {
        'oneOfValue': null,
        'oneOfRefValue': null,
        'anyOfValue': null,
      });
    });

    test('fromJson decodes non-null members to variants', () {
      final holder = NullMemberHolder.fromJson(const {
        'oneOfValue': {'name': 'Kate'},
        'oneOfRefValue': {'name': 'Mark'},
        'anyOfValue': {'name': 'Lena'},
      });

      expect(
        holder.oneOfValue,
        const $RawOneOfWithNullClass1(Class1(name: 'Kate')),
      );
      expect(
        holder.oneOfRefValue,
        const $RawOneOfWithNullRefClass1(Class1(name: 'Mark')),
      );
      expect(
        holder.anyOfValue,
        const $RawAnyOfWithNull(class1: Class1(name: 'Lena')),
      );
    });

    test('json roundtrip preserves non-null members', () {
      final holder = NullMemberHolder.fromJson(const {
        'oneOfValue': {'name': 'Kate'},
        'oneOfRefValue': {'name': 'Mark'},
        'anyOfValue': {'name': 'Lena'},
      });

      expect(holder.toJson(), {
        'oneOfValue': {'name': 'Kate'},
        'oneOfRefValue': {'name': 'Mark'},
        'anyOfValue': {'name': 'Lena'},
      });
    });
  });

  group('OneOfWithNull', () {
    test('fromJson throws when no variant matches', () {
      expect(
        () => $RawOneOfWithNull.fromJson(const {'wings': 2}),
        throwsA(isA<JsonDecodingException>()),
      );
    });
  });

  group('OneOfWithNullRef', () {
    test('fromJson throws when no variant matches', () {
      expect(
        () => $RawOneOfWithNullRef.fromJson(const {'wings': 2}),
        throwsA(isA<JsonDecodingException>()),
      );
    });
  });

  group('AnyOfWithNull', () {
    test('fromJson throws when no variant matches', () {
      expect(
        () => $RawAnyOfWithNull.fromJson(const {'wings': 2}),
        throwsA(isA<JsonDecodingException>()),
      );
    });
  });
}
