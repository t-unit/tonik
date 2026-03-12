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
      'emits raw triple-quoted string for value with both quotes',
      () {
        expect(
          emit(specLiteralString('it\'s "here"')),
          'r"""it\'s "here""""',
        );
      },
    );

    test('emits raw single-quoted string for empty value', () {
      expect(emit(specLiteralString('')), "r''");
    });
  });
}
