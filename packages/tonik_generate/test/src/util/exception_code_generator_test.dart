import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';

void main() {
  group('generateInterpolatedJsonDecodingExceptionExpression', () {
    late DartEmitter emitter;

    setUp(() {
      emitter = DartEmitter(useNullSafetySyntax: true);
    });

    String emit(Expression expr) =>
        collapseWhitespace(expr.accept(emitter).toString());

    test('escapes single quote in prefix so literal stays valid', () {
      expect(
        emit(
          generateInterpolatedJsonDecodingExceptionExpression(
            "it's bad: ",
            'value',
          ),
        ),
        r"throw JsonDecodingException('it\'s bad: $value')",
      );
    });

    test('escapes backslash in prefix', () {
      expect(
        emit(
          generateInterpolatedJsonDecodingExceptionExpression(
            r'a\b: ',
            'value',
          ),
        ),
        r"throw JsonDecodingException('a\\b: $value')",
      );
    });

    test('escapes newline in prefix', () {
      expect(
        emit(
          generateInterpolatedJsonDecodingExceptionExpression(
            'a\nb: ',
            'value',
          ),
        ),
        r"throw JsonDecodingException('a\nb: $value')",
      );
    });

    test('escapes dollar sign in prefix', () {
      expect(
        emit(
          generateInterpolatedJsonDecodingExceptionExpression(
            r'cost $: ',
            'value',
          ),
        ),
        r"throw JsonDecodingException('cost \$: $value')",
      );
    });

    test('emits bare identifier interpolation with a dollar prefix', () {
      expect(
        emit(
          generateInterpolatedJsonDecodingExceptionExpression('got: ', 'value'),
        ),
        r"throw JsonDecodingException('got: $value')",
      );
    });

    test('wraps dotted interpolation expression in braces', () {
      expect(
        emit(
          generateInterpolatedJsonDecodingExceptionExpression(
            'got: ',
            'value.runtimeType',
          ),
        ),
        r"throw JsonDecodingException('got: ${value.runtimeType}')",
      );
    });
  });
}
