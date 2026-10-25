import 'package:immutable_collections_api/immutable_collections_api.dart';
import 'package:test/test.dart';

void main() {
  test(
    'immutable mode retains value equality for raw free-form collections',
    () {
      final firstJson = <String, Object?>{
        'data': {
          'items': [1, 2],
        },
        'aliasedData': [3, 4],
      };
      final secondJson = <String, Object?>{
        'data': {
          'items': [1, 2],
        },
        'aliasedData': [3, 4],
      };
      final first = FreeformHolder.fromJson(firstJson);
      final second = FreeformHolder.fromJson(secondJson);

      expect(identical(first.data, second.data), isFalse);
      expect(identical(first.aliasedData, second.aliasedData), isFalse);
      expect(first, second);
      expect(first.hashCode, second.hashCode);
    },
  );

  test('immutable mode oneOf free-form members compare maps by value', () {
    final firstJson = <String, Object?>{
      'items': [1, 2],
    };
    final secondJson = <String, Object?>{
      'items': [1, 2],
    };
    final first = OneOfFreeformValue.fromJson(firstJson);
    final second = OneOfFreeformValue.fromJson(secondJson);

    expect(identical(firstJson, secondJson), isFalse);
    expect(first.toJson(), {
      'items': [1, 2],
    });
    expect(first, second);
    expect(first.hashCode, second.hashCode);
  });

  test('immutable mode anyOf free-form members compare lists by value', () {
    final firstJson = <Object?>[
      1,
      {'name': 'same'},
    ];
    final secondJson = <Object?>[
      1,
      {'name': 'same'},
    ];
    final first = AnyOfFreeformValue.fromJson(firstJson);
    final second = AnyOfFreeformValue.fromJson(secondJson);

    expect(identical(firstJson, secondJson), isFalse);
    expect(first.toJson(), [
      1,
      {'name': 'same'},
    ]);
    expect(first, second);
    expect(first.hashCode, second.hashCode);
  });

  test('immutable mode allOf free-form properties compare by value', () {
    final firstJson = <String, Object?>{
      'label': 'same',
      'data': {
        'items': [1, 2],
      },
    };
    final secondJson = <String, Object?>{
      'label': 'same',
      'data': {
        'items': [1, 2],
      },
    };
    final differentJson = <String, Object?>{
      'label': 'same',
      'data': {
        'items': [1, 3],
      },
    };
    final first = AllOfFreeformValue.fromJson(firstJson);
    final second = AllOfFreeformValue.fromJson(secondJson);
    final different = AllOfFreeformValue.fromJson(differentJson);

    expect(identical(firstJson['data'], secondJson['data']), isFalse);
    expect(first.toJson(), {
      'label': 'same',
      'data': {
        'items': [1, 2],
      },
    });
    expect(first, second);
    expect(first.hashCode, second.hashCode);
    expect(first, isNot(different));
  });
}
