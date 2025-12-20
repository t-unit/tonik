import 'package:test/test.dart';
import 'package:tonik_util/src/encoding/binary_extensions.dart';

void main() {
  group('BinaryToStringEncoder', () {
    test('decodes List<int> to UTF-8 string', () {
      const bytes = [72, 101, 108, 108, 111]; // "Hello"
      expect(bytes.decodeToString(), 'Hello');
    });

    test('decodes List<int> with special UTF-8 characters', () {
      const bytes = [72, 195, 171, 108, 108, 195, 182]; // "Hëllö"
      expect(bytes.decodeToString(), 'Hëllö');
    });

    test('decodes empty List<int>', () {
      const bytes = <int>[];
      expect(bytes.decodeToString(), '');
    });

    test('handles malformed UTF-8 gracefully', () {
      // Invalid UTF-8 sequence (0xFF is not valid UTF-8)
      const bytes = [72, 0xFF, 108, 108, 111]; // "H�llo"
      final result = bytes.decodeToString();
      // allowMalformed: true replaces invalid bytes with replacement character
      expect(result, isNotEmpty);
      expect(result.length, greaterThan(0));
    });

    test('decodes UTF-8 with emoji', () {
      const bytes = [240, 159, 152, 128]; // "😀"
      expect(bytes.decodeToString(), '😀');
    });

    test('decodes newlines and special characters', () {
      const bytes = [
        72,
        101,
        108,
        108,
        111,
        10,
        87,
        111,
        114,
        108,
        100,
      ]; // "Hello\nWorld"
      expect(bytes.decodeToString(), 'Hello\nWorld');
    });
  });
}
