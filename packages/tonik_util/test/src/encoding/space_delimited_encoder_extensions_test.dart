import 'package:test/test.dart';
import 'package:tonik_util/src/encoding/encoding_exception.dart';
import 'package:tonik_util/src/encoding/space_delimited_encoder_extensions.dart';

void main() {
  group('SpaceDelimitedStringListEncoder', () {
    group('with explode=false', () {
      test('encodes list of strings with space delimiter', () {
        final result = ['red', 'green', 'blue'].toSpaceDelimited(
          explode: false,
          allowEmpty: true,
        );
        expect(result, ['red%20green%20blue']);
      });

      test('encodes list with special characters', () {
        final result = ['item 1', 'item 2'].toSpaceDelimited(
          explode: false,
          allowEmpty: true,
        );
        expect(result, ['item%201%20item%202']);
      });

      test('encodes list with reserved characters', () {
        final result = ['a&b', 'c=d'].toSpaceDelimited(
          explode: false,
          allowEmpty: true,
        );
        expect(result, ['a%26b%20c%3Dd']);
      });

      test('encodes empty list when allowEmpty is true', () {
        final result = <String>[].toSpaceDelimited(
          explode: false,
          allowEmpty: true,
        );
        expect(result, ['']);
      });

      test(
        'throws EmptyValueException when empty list and allowEmpty is false',
        () {
          expect(
            () => <String>[].toSpaceDelimited(
              explode: false,
              allowEmpty: false,
            ),
            throwsA(isA<EmptyValueException>()),
          );
        },
      );

      test('encodes single item list', () {
        final result = ['single'].toSpaceDelimited(
          explode: false,
          allowEmpty: true,
        );
        expect(result, ['single']);
      });

      test(
        'encodes list with already encoded values when alreadyEncoded is true',
        () {
          final result = ['item+1', 'item+2'].toSpaceDelimited(
            explode: false,
            allowEmpty: true,
            alreadyEncoded: true,
          );
          expect(result, ['item+1%20item+2']);
        },
      );

      test('encodes non-ASCII characters', () {
        final result = ['café', '你好'].toSpaceDelimited(
          explode: false,
          allowEmpty: true,
        );
        expect(result, ['caf%C3%A9%20%E4%BD%A0%E5%A5%BD']);
      });

      test('encodes URL with special characters', () {
        final result = ['http://example.com', '/api/v1'].toSpaceDelimited(
          explode: false,
          allowEmpty: true,
        );
        expect(result, ['http%3A%2F%2Fexample.com%20%2Fapi%2Fv1']);
      });
    });

    group('with explode=true', () {
      test('encodes list as separate values', () {
        final result = ['red', 'green', 'blue'].toSpaceDelimited(
          explode: true,
          allowEmpty: true,
        );
        expect(result, ['red', 'green', 'blue']);
      });

      test('encodes list with special characters as separate values', () {
        final result = ['item 1', 'item 2'].toSpaceDelimited(
          explode: true,
          allowEmpty: true,
        );
        expect(result, ['item%201', 'item%202']);
      });

      test('encodes empty list when allowEmpty is true', () {
        final result = <String>[].toSpaceDelimited(
          explode: true,
          allowEmpty: true,
        );
        expect(result, ['']);
      });

      test(
        'throws EmptyValueException when empty list and allowEmpty is false',
        () {
          expect(
            () => <String>[].toSpaceDelimited(
              explode: true,
              allowEmpty: false,
            ),
            throwsA(isA<EmptyValueException>()),
          );
        },
      );

      test('encodes single item list', () {
        final result = ['single'].toSpaceDelimited(
          explode: true,
          allowEmpty: true,
        );
        expect(result, ['single']);
      });

      test(
        'encodes list with already encoded values when alreadyEncoded is true',
        () {
          final result = ['item+1', 'item+2'].toSpaceDelimited(
            explode: true,
            allowEmpty: true,
            alreadyEncoded: true,
          );
          expect(result, ['item+1', 'item+2']);
        },
      );
    });
  });

  group('SpaceDelimitedBinaryEncoder', () {
    test('encodes List<int> as single item with explode=false', () {
      const value = [72, 101, 108, 108, 111]; // "Hello"
      final result = value.toSpaceDelimited(explode: false, allowEmpty: true);
      expect(result, ['Hello']);
    });

    test('encodes List<int> as single item with explode=true', () {
      const value = [72, 101, 108, 108, 111];
      final result = value.toSpaceDelimited(explode: true, allowEmpty: true);
      expect(result, ['Hello']);
    });

    test('encodes empty List<int> when allowEmpty=true', () {
      const value = <int>[];
      final result = value.toSpaceDelimited(explode: false, allowEmpty: true);
      expect(result, ['']);
    });

    test('throws EmptyValueException when empty and allowEmpty=false', () {
      const value = <int>[];
      expect(
        () => value.toSpaceDelimited(explode: false, allowEmpty: false),
        throwsA(isA<EmptyValueException>()),
      );
    });

    test('encodes List<int> with special characters', () {
      const value = [72, 195, 171, 108, 108, 195, 182]; // "Hëllö"
      final result = value.toSpaceDelimited(explode: false, allowEmpty: true);
      expect(result, ['H%C3%ABll%C3%B6']);
    });
  });
}
