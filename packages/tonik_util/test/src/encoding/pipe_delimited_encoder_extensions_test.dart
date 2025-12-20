import 'package:test/test.dart';
import 'package:tonik_util/src/encoding/encoding_exception.dart';
import 'package:tonik_util/src/encoding/pipe_delimited_encoder_extensions.dart';

void main() {
  group('PipeDelimitedStringListEncoder', () {
    group('with explode=false', () {
      test('encodes list of strings with pipe delimiter', () {
        final result = ['red', 'green', 'blue'].toPipeDelimited(
          explode: false,
          allowEmpty: true,
        );
        expect(result, ['red|green|blue']);
      });

      test('encodes list with special characters', () {
        final result = ['item 1', 'item 2'].toPipeDelimited(
          explode: false,
          allowEmpty: true,
        );
        expect(result, ['item%201|item%202']);
      });

      test('encodes list with reserved characters', () {
        final result = ['a&b', 'c=d'].toPipeDelimited(
          explode: false,
          allowEmpty: true,
        );
        expect(result, ['a%26b|c%3Dd']);
      });

      test('encodes empty list when allowEmpty is true', () {
        final result = <String>[].toPipeDelimited(
          explode: false,
          allowEmpty: true,
        );
        expect(result, ['']);
      });

      test(
        'throws EmptyValueException when empty list and allowEmpty is false',
        () {
          expect(
            () => <String>[].toPipeDelimited(
              explode: false,
              allowEmpty: false,
            ),
            throwsA(isA<EmptyValueException>()),
          );
        },
      );

      test('encodes single item list', () {
        final result = ['single'].toPipeDelimited(
          explode: false,
          allowEmpty: true,
        );
        expect(result, ['single']);
      });

      test(
        'encodes list with already encoded values when alreadyEncoded is true',
        () {
          final result = ['item+1', 'item+2'].toPipeDelimited(
            explode: false,
            allowEmpty: true,
            alreadyEncoded: true,
          );
          expect(result, ['item+1|item+2']);
        },
      );

      test('encodes non-ASCII characters', () {
        final result = ['café', '你好'].toPipeDelimited(
          explode: false,
          allowEmpty: true,
        );
        expect(result, ['caf%C3%A9|%E4%BD%A0%E5%A5%BD']);
      });
    });

    group('with explode=true', () {
      test('encodes list as separate values', () {
        final result = ['red', 'green', 'blue'].toPipeDelimited(
          explode: true,
          allowEmpty: true,
        );
        expect(result, ['red', 'green', 'blue']);
      });

      test('encodes list with special characters as separate values', () {
        final result = ['item 1', 'item 2'].toPipeDelimited(
          explode: true,
          allowEmpty: true,
        );
        expect(result, ['item%201', 'item%202']);
      });

      test('encodes empty list when allowEmpty is true', () {
        final result = <String>[].toPipeDelimited(
          explode: true,
          allowEmpty: true,
        );
        expect(result, ['']);
      });

      test(
        'throws EmptyValueException when empty list and allowEmpty is false',
        () {
          expect(
            () => <String>[].toPipeDelimited(
              explode: true,
              allowEmpty: false,
            ),
            throwsA(isA<EmptyValueException>()),
          );
        },
      );

      test('encodes single item list', () {
        final result = ['single'].toPipeDelimited(
          explode: true,
          allowEmpty: true,
        );
        expect(result, ['single']);
      });

      test(
        'encodes list with already encoded values when alreadyEncoded is true',
        () {
          final result = ['item+1', 'item+2'].toPipeDelimited(
            explode: true,
            allowEmpty: true,
            alreadyEncoded: true,
          );
          expect(result, ['item+1', 'item+2']);
        },
      );
    });
  });

  group('PipeDelimitedBinaryEncoder', () {
    test('encodes List<int> as single item with explode=false', () {
      const value = [72, 101, 108, 108, 111]; // "Hello"
      final result = value.toPipeDelimited(explode: false, allowEmpty: true);
      expect(result, ['Hello']);
    });

    test('encodes List<int> as single item with explode=true', () {
      const value = [72, 101, 108, 108, 111];
      final result = value.toPipeDelimited(explode: true, allowEmpty: true);
      expect(result, ['Hello']);
    });

    test('encodes empty List<int> when allowEmpty=true', () {
      const value = <int>[];
      final result = value.toPipeDelimited(explode: false, allowEmpty: true);
      expect(result, ['']);
    });

    test('throws EmptyValueException when empty and allowEmpty=false', () {
      const value = <int>[];
      expect(
        () => value.toPipeDelimited(explode: false, allowEmpty: false),
        throwsA(isA<EmptyValueException>()),
      );
    });

    test('encodes List<int> with special characters', () {
      const value = [72, 195, 171, 108, 108, 195, 182]; // "Hëllö"
      final result = value.toPipeDelimited(explode: false, allowEmpty: true);
      expect(result, ['H%C3%ABll%C3%B6']);
    });
  });
}
