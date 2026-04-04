import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';
import 'package:tonik_generate/src/util/spec_literal_string.dart';

void main() {
  group('specLiteralString', () {
    late DartEmitter emitter;

    setUp(() {
      emitter = DartEmitter(useNullSafetySyntax: true);
    });

    String emit(Expression expr) => expr.accept(emitter).toString();

    test('emits raw single-quoted string for plain value', () {
      expect(emit(specLiteralString('hello')), "r'hello'");
    });

    test('emits raw single-quoted string for value with dollar sign', () {
      expect(emit(specLiteralString(r'price$5')), r"r'price$5'");
    });

    test('emits raw double-quoted string for value with single quote', () {
      expect(emit(specLiteralString("it's")), 'r"it\'s"');
    });

    test(
      'emits raw double-quoted string for value with single quote and dollar',
      () {
        expect(emit(specLiteralString(r"it's $5")), r'''r"it's $5"''');
      },
    );

    test(
      'emits raw triple-quoted string for value with both quotes '
      'not ending in double quote',
      () {
        expect(
          emit(specLiteralString('it\'s "here" ok')),
          'r"""it\'s "here" ok"""',
        );
      },
    );

    test(
      'falls back to escaped string when value with both quotes '
      'ends in double quote',
      () {
        // r"""...""" is invalid Dart when content ends with "
        // so we must use escaped single-quoted string
        expect(
          emit(specLiteralString('it\'s "here"')),
          "'it\\'s \"here\"'",
        );
      },
    );

    test('emits raw single-quoted string for empty value', () {
      expect(emit(specLiteralString('')), "r''");
    });
  });

  group('specLiteralStringCode', () {
    test('path 1: no quotes uses raw single-quoted string', () {
      expect(specLiteralStringCode('hello'), "r'hello'");
    });

    test('path 2: single quote uses raw double-quoted string', () {
      expect(specLiteralStringCode("it's"), 'r"it\'s"');
    });

    test(
      'path 3: both quotes uses raw triple-double-quoted string',
      () {
        expect(
          specLiteralStringCode('it\'s "here" ok'),
          'r"""it\'s "here" ok"""',
        );
      },
    );

    test(
      'path 3 skipped: both quotes but ends with double quote falls '
      'through to path 4',
      () {
        // Ending with " would produce r"""..."""" which is invalid Dart
        final result = specLiteralStringCode('it\'s "here"');
        expect(result, isNot(startsWith('r"""')));
        expect(result, "'it\\'s \"here\"'");
      },
    );

    test(
      'path 4: triple-double-quotes uses escaped single-quoted string',
      () {
        // Build a string containing ', ", and """
        const value =
            "it's"
            '"""'
            'test';
        final result = specLiteralStringCode(value);
        expect(result, isNot(startsWith('r')));
        expect(result, startsWith("'"));
        expect(result, endsWith("'"));
        expect(result, contains(r"\'"));
      },
    );

    test('escapes backslash in fallback path', () {
      // Build a string with ', ", and """ plus backslash
      const value =
          "it's"
          '"""'
          r'te\st';
      final result = specLiteralStringCode(value);
      expect(result, contains(r'\\'));
    });

    test('escapes dollar sign in fallback path', () {
      // Build a string with ', ", and """ plus dollar
      const value =
          "it's"
          '"""'
          r'te$st';
      final result = specLiteralStringCode(value);
      expect(result, contains(r'\$'));
    });

    group('newline handling', () {
      test(r'value with \n uses raw triple-quoted string', () {
        final result = specLiteralStringCode('hello\nworld');
        expect(result, startsWith('r"""'));
        expect(result, endsWith('"""'));
        expect(result, 'r"""hello\nworld"""');
      });

      test(r'value with \r uses raw triple-quoted string', () {
        final result = specLiteralStringCode('hello\rworld');
        expect(result, startsWith('r"""'));
        expect(result, endsWith('"""'));
        expect(result, 'r"""hello\rworld"""');
      });

      test(r'value with \r\n uses raw triple-quoted string', () {
        final result = specLiteralStringCode('hello\r\nworld');
        expect(result, startsWith('r"""'));
        expect(result, endsWith('"""'));
        expect(result, 'r"""hello\r\nworld"""');
      });

      test(
        r'value with \n and single quotes uses raw triple-quoted string',
        () {
          final result = specLiteralStringCode("it's\nnew");
          expect(result, startsWith('r"""'));
          expect(result, endsWith('"""'));
          expect(result, 'r"""it\'s\nnew"""');
        },
      );

      test(
        r'value with \n and double quotes uses raw triple-quoted string',
        () {
          final result = specLiteralStringCode('say "hi"\nthere');
          expect(result, startsWith('r"""'));
          expect(result, endsWith('"""'));
          expect(result, 'r"""say "hi"\nthere"""');
        },
      );

      test(
        r'value with \n and both quotes uses raw triple-quoted string',
        () {
          final result = specLiteralStringCode('it\'s "here"\nok');
          expect(result, startsWith('r"""'));
          expect(result, endsWith('"""'));
          expect(result, 'r"""it\'s "here"\nok"""');
        },
      );

      test(
        r'value with \n and triple-double-quotes falls back to escaped '
        'single-quoted string with escaped newline',
        () {
          // Contains ', ", """, and \n — must use escaped fallback
          const value = "it's\"\"\"\ntest";
          final result = specLiteralStringCode(value);
          expect(result, isNot(startsWith('r')));
          expect(result, startsWith("'"));
          expect(result, endsWith("'"));
          // \n must be escaped as literal \n in the output
          expect(result, contains(r'\n'));
          // single quote must be escaped
          expect(result, contains(r"\'"));
        },
      );

      test(
        r'value with \r in fallback path is escaped as literal \r',
        () {
          // Contains ', ", """, and \r — must use escaped fallback
          const value = "it's\"\"\"\rtest";
          final result = specLiteralStringCode(value);
          expect(result, isNot(startsWith('r')));
          expect(result, contains(r'\r'));
        },
      );

      test(
        r'value with \n ending in double quote uses escaped '
        'single-quoted string',
        () {
          // Has both quotes, ends in ", and has \n
          final result = specLiteralStringCode('it\'s "here"\n"end"');
          expect(result, isNot(startsWith('r')));
          expect(result, startsWith("'"));
          expect(result, endsWith("'"));
          expect(result, contains(r'\n'));
        },
      );
    });
  });

  group('escapeForSingleQuotedDartString', () {
    test(r'escapes \n to literal \n', () {
      expect(escapeForSingleQuotedDartString('hello\nworld'), r'hello\nworld');
    });

    test(r'escapes \r to literal \r', () {
      expect(escapeForSingleQuotedDartString('hello\rworld'), r'hello\rworld');
    });

    test(
      r'escapes combined \n, \r, single quote, dollar, and backslash',
      () {
        const input = "a\\b'c\$d\ne\rf";
        final result = escapeForSingleQuotedDartString(input);
        // Backslash must be escaped first to avoid double-escaping.
        // Then single quote, dollar, \n, and \r.
        expect(result, r"a\\b\'c\$d\ne\rf");
      },
    );
  });
}
