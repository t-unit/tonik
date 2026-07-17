import 'package:test/test.dart';
import 'package:tonik_generate/src/naming/file_name.dart';

void main() {
  group('fileNameForClass', () {
    test('converts a PascalCase class name to a snake_case file name', () {
      expect(fileNameForClass('FooBar'), 'foo_bar.dart');
    });

    test('maps a dollar-prefixed class name to the same file name as its '
        'plain form', () {
      expect(fileNameForClass(r'$User'), 'user.dart');
      expect(fileNameForClass('User'), 'user.dart');
    });

    test('keeps the leading underscore for digit-leading class names', () {
      expect(fileNameForClass(r'$20100401Test'), '_20100401_test.dart');
    });

    test('falls back to the raw snake_case form when stripping would empty '
        'the name', () {
      expect(fileNameForClass(r'$'), '_.dart');
    });
  });
}
