import 'package:composition_api/composition_api.dart';
import 'package:test/test.dart';

void main() {
  test('free-form list properties compare and hash by value', () {
    final firstJson = <String, Object?>{
      'data': [1, 2],
    };
    final secondJson = <String, Object?>{
      'data': [1, 2],
    };
    final first = FreeformHolder.fromJson(firstJson);
    final second = FreeformHolder.fromJson(secondJson);

    expect(identical(first.data, second.data), isFalse);
    expect(first, second);
    expect(first.hashCode, second.hashCode);
  });

  test('free-form properties compare nested maps and lists by value', () {
    final firstJson = <String, Object?>{
      'data': {
        'items': [
          1,
          {'name': 'same'},
        ],
      },
    };
    final secondJson = <String, Object?>{
      'data': {
        'items': [
          1,
          {'name': 'same'},
        ],
      },
    };
    final differentJson = <String, Object?>{
      'data': {
        'items': [
          1,
          {'name': 'different'},
        ],
      },
    };
    final first = FreeformHolder.fromJson(firstJson);
    final second = FreeformHolder.fromJson(secondJson);
    final different = FreeformHolder.fromJson(differentJson);

    expect(identical(first.data, second.data), isFalse);
    expect(first, second);
    expect(first.hashCode, second.hashCode);
    expect(first, isNot(different));
  });

  test('aliased free-form properties compare by value', () {
    final firstJson = <String, Object?>{
      'aliasedData': [1, 2],
    };
    final secondJson = <String, Object?>{
      'aliasedData': [1, 2],
    };
    final first = FreeformHolder.fromJson(firstJson);
    final second = FreeformHolder.fromJson(secondJson);

    expect(identical(first.aliasedData, second.aliasedData), isFalse);
    expect(first, second);
    expect(first.hashCode, second.hashCode);
  });

  test('oneOf free-form members compare nested lists by value', () {
    final firstJson = <Object?>[
      1,
      {'name': 'same'},
    ];
    final secondJson = <Object?>[
      1,
      {'name': 'same'},
    ];
    final first = OneOfFreeformValue.fromJson(firstJson);
    final second = OneOfFreeformValue.fromJson(secondJson);

    expect(identical(firstJson, secondJson), isFalse);
    expect(first.toJson(), [
      1,
      {'name': 'same'},
    ]);
    expect(first, second);
    expect(first.hashCode, second.hashCode);
  });

  test('anyOf free-form members compare nested maps by value', () {
    final firstJson = <String, Object?>{
      'items': [1, 2],
    };
    final secondJson = <String, Object?>{
      'items': [1, 2],
    };
    final first = AnyOfFreeformValue.fromJson(firstJson);
    final second = AnyOfFreeformValue.fromJson(secondJson);

    expect(identical(firstJson, secondJson), isFalse);
    expect(first.toJson(), {
      'items': [1, 2],
    });
    expect(first, second);
    expect(first.hashCode, second.hashCode);
  });

  test('allOf free-form properties compare nested values by value', () {
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

  test('free-form scalar and null equality remains unchanged', () {
    final number = FreeformHolder.fromJson(const {'data': 7});
    final text = FreeformHolder.fromJson(const {'data': 'same'});
    final empty = FreeformHolder.fromJson(const {'data': null});

    expect(number, const FreeformHolder(data: 7));
    expect(number.hashCode, const FreeformHolder(data: 7).hashCode);
    expect(text, const FreeformHolder(data: 'same'));
    expect(text.hashCode, const FreeformHolder(data: 'same').hashCode);
    expect(empty, const FreeformHolder());
    expect(empty.hashCode, const FreeformHolder().hashCode);
    expect(number, isNot(text));
  });
}
