import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_generate/src/util/spec_literal_string.dart';

void main() {
  final formatter = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  );

  String render(Code code) {
    final method = Method(
      (b) => b
        ..name = 'value'
        ..lambda = true
        ..body = code,
    );
    return collapseWhitespace(
      formatter.format('${method.accept(DartEmitter())};'),
    );
  }

  String expected(String source) =>
      collapseWhitespace(formatter.format(source));

  group('specLiteralString', () {
    test('uses raw single quotes for a plain value', () {
      expect(
        render(specLiteralString('hello').code),
        expected("value() => r'hello';"),
      );
    });

    test('preserves a dollar sign in a raw string', () {
      expect(
        render(specLiteralString(r'price$5').code),
        expected(r"value() => r'price$5';"),
      );
    });

    test('uses raw double quotes for a value with a single quote', () {
      expect(
        render(specLiteralString(r"it's $5").code),
        expected(r'''value() => r"it's $5";'''),
      );
    });

    test('uses raw triple quotes for both quotes on one line', () {
      expect(
        render(specLiteralString('it\'s "here" ok').code),
        expected('value() => r"""it\'s "here" ok""";'),
      );
    });

    test('escapes both quotes when the value ends in a double quote', () {
      expect(
        render(specLiteralString('it\'s "here"').code),
        expected(r'''value() => 'it\'s "here"';'''),
      );
    });

    test('preserves an empty value', () {
      expect(render(specLiteralString('').code), expected("value() => r'';"));
    });

    test('escapes a lone newline', () {
      expect(
        render(specLiteralString('\n').code),
        expected(r"value() => '\n';"),
      );
    });

    test('preserves spaces before a leading newline', () {
      expect(
        render(specLiteralString('  \nabc').code),
        expected(r"value() => '  \nabc';"),
      );
    });

    test('preserves a tab before a leading newline', () {
      expect(
        render(specLiteralString('\t\nabc').code),
        expected("value() => '\t\\nabc';"),
      );
    });

    test('preserves multiple leading newlines', () {
      expect(
        render(specLiteralString('\n\nabc').code),
        expected(r"value() => '\n\nabc';"),
      );
    });

    test('escapes newlines with dollars, backslashes, and quotes', () {
      expect(
        render(specLiteralString('\n\$5\\it\'s "here"\r\n').code),
        expected(r'''value() => '\n\$5\\it\'s "here"\r\n';'''),
      );
    });
  });

  group('specLiteralStringCode', () {
    test('uses raw single quotes for a plain value', () {
      expect(
        render(Code(specLiteralStringCode('hello'))),
        expected("value() => r'hello';"),
      );
    });

    test('uses raw double quotes for a value with a single quote', () {
      expect(
        render(Code(specLiteralStringCode("it's"))),
        expected('value() => r"it\'s";'),
      );
    });

    test('uses raw triple quotes for both quotes on one line', () {
      expect(
        render(Code(specLiteralStringCode('it\'s "here" ok'))),
        expected('value() => r"""it\'s "here" ok""";'),
      );
    });

    test('escapes both quotes when the value ends in a double quote', () {
      expect(
        render(Code(specLiteralStringCode('it\'s "here"'))),
        expected(r'''value() => 'it\'s "here"';'''),
      );
    });

    test('escapes triple quotes, backslashes, and dollars', () {
      expect(
        render(Code(specLiteralStringCode('it\'s"""te\\\$st'))),
        expected(r'''value() => 'it\'s"""te\\\$st';'''),
      );
    });

    test('escapes a lone newline', () {
      expect(
        render(Code(specLiteralStringCode('\n'))),
        expected(r"value() => '\n';"),
      );
    });

    test('preserves spaces before a leading newline', () {
      expect(
        render(Code(specLiteralStringCode('  \nabc'))),
        expected(r"value() => '  \nabc';"),
      );
    });

    test('preserves a tab before a leading newline', () {
      expect(
        render(Code(specLiteralStringCode('\t\nabc'))),
        expected("value() => '\t\\nabc';"),
      );
    });

    test('preserves multiple leading newlines', () {
      expect(
        render(Code(specLiteralStringCode('\n\nabc'))),
        expected(r"value() => '\n\nabc';"),
      );
    });

    test('escapes a newline between nonempty lines', () {
      expect(
        render(Code(specLiteralStringCode('hello\nworld'))),
        expected(r"value() => 'hello\nworld';"),
      );
    });

    test('escapes a carriage return', () {
      expect(
        render(Code(specLiteralStringCode('hello\rworld'))),
        expected(r"value() => 'hello\rworld';"),
      );
    });

    test('escapes a carriage return and newline', () {
      expect(
        render(Code(specLiteralStringCode('hello\r\nworld'))),
        expected(r"value() => 'hello\r\nworld';"),
      );
    });

    test('escapes newlines with dollars, backslashes, and quotes', () {
      expect(
        render(Code(specLiteralStringCode('\n\$5\\it\'s "here"\r\n'))),
        expected(r'''value() => '\n\$5\\it\'s "here"\r\n';'''),
      );
    });
  });
}
