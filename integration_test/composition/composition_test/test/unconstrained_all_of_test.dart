import 'package:composition_api/composition_api.dart';
import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  test('all-Any intersections roundtrip null, arrays and constrained maps', () {
    final value = UnconstrainedAllOfHolder.fromJson(const {
      'any': null,
      'open': [null, 7],
      'strings': {'x': 'ok'},
      'closed': <String, Object?>{},
    });

    expect(value.toJson(), {
      'any': null,
      'open': [null, 7],
      'strings': {'x': 'ok'},
      'closed': <String, Object?>{},
    });
  });

  test(
    'all-Any intersection retains typed additionalProperties validation',
    () {
      expect(
        () => UnconstrainedAllOfHolder.fromJson(const {
          'any': null,
          'open': null,
          'strings': {'x': 42},
          'closed': <String, Object?>{},
        }),
        throwsA(isA<InvalidTypeException>()),
      );
    },
  );

  test('all-Any intersection retains forbidden additionalProperties', () {
    expect(
      () => UnconstrainedAllOfHolder.fromJson(const {
        'any': null,
        'open': null,
        'strings': <String, Object?>{},
        'closed': {'extra': 'forbidden'},
      }),
      throwsA(isA<JsonDecodingException>()),
    );
  });

  test('recursive additionalProperties roundtrip nested objects', () {
    final value = RecursiveEmptyIntersection.fromJson(const {
      'child': {'leaf': <String, Object?>{}},
    });

    expect(value.toJson(), {
      'child': {'leaf': <String, Object?>{}},
    });
  });
}
