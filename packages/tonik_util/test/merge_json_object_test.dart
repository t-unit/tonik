import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  test('merges nested objects without changing either source map', () {
    const first = <String, Object?>{
      'details': {
        'name': {'given': 'Ada'},
      },
    };
    const second = <String, Object?>{
      'details': {
        'name': {'family': 'Lovelace'},
      },
    };
    final result = <String, Object?>{};
    mergeJsonObject(result, first);
    mergeJsonObject(result, second);

    expect(result, {
      'details': {
        'name': {'given': 'Ada', 'family': 'Lovelace'},
      },
    });
    expect(first, {
      'details': {
        'name': {'given': 'Ada'},
      },
    });
    expect(second, {
      'details': {
        'name': {'family': 'Lovelace'},
      },
    });
  });

  test('later scalar, null, and array values replace earlier values', () {
    final result = <String, Object?>{
      'name': 'Ada',
      'age': 36,
      'tags': ['first'],
    };
    mergeJsonObject(result, {
      'name': 'Grace',
      'age': null,
      'tags': ['second'],
    });
    expect(result, {
      'name': 'Grace',
      'age': null,
      'tags': ['second'],
    });
  });
}
