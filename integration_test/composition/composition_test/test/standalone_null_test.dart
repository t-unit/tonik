import 'package:composition_api/composition_api.dart';
import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  group('StandaloneNullHolder', () {
    test('fromJson decodes null values to null', () {
      final holder = StandaloneNullHolder.fromJson(const {
        'viaRef': null,
        'inline': null,
        'nullList': [null, null],
        'nullMap': {'first': null},
      });

      expect(holder.viaRef, isNull);
      expect(holder.inline, isNull);
      expect(holder.nullList, [null, null]);
      expect(holder.nullMap, {'first': null});
    });

    test('json roundtrip preserves null values', () {
      final holder = StandaloneNullHolder.fromJson(const {
        'viaRef': null,
        'inline': null,
        'nullList': [null],
        'nullMap': {'first': null},
      });

      expect(holder.toJson(), {
        'viaRef': null,
        'inline': null,
        'nullList': [null],
        'nullMap': {'first': null},
      });
    });

    test('fromJson throws for empty object via ref', () {
      expect(
        () => StandaloneNullHolder.fromJson(const {
          'viaRef': <String, Object?>{},
          'inline': null,
          'nullList': <Object?>[],
          'nullMap': <String, Object?>{},
        }),
        throwsA(isA<JsonDecodingException>()),
      );
    });

    test('fromJson throws for non-empty object via ref', () {
      expect(
        () => StandaloneNullHolder.fromJson(const {
          'viaRef': {'a': 1},
          'inline': null,
          'nullList': <Object?>[],
          'nullMap': <String, Object?>{},
        }),
        throwsA(isA<JsonDecodingException>()),
      );
    });

    test('fromJson throws for non-null inline value', () {
      expect(
        () => StandaloneNullHolder.fromJson(const {
          'viaRef': null,
          'inline': 'value',
          'nullList': <Object?>[],
          'nullMap': <String, Object?>{},
        }),
        throwsA(isA<JsonDecodingException>()),
      );
    });

    test('fromJson throws for non-null list element', () {
      expect(
        () => StandaloneNullHolder.fromJson(const {
          'viaRef': null,
          'inline': null,
          'nullList': [1],
          'nullMap': <String, Object?>{},
        }),
        throwsA(isA<JsonDecodingException>()),
      );
    });

    test('fromJson throws for non-null map value', () {
      expect(
        () => StandaloneNullHolder.fromJson(const {
          'viaRef': null,
          'inline': null,
          'nullList': <Object?>[],
          'nullMap': {'first': 1},
        }),
        throwsA(isA<JsonDecodingException>()),
      );
    });
  });
}
