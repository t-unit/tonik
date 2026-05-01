import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_generate/src/util/encoding_policy.dart';

void main() {
  late DartEmitter emitter;

  final format = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  ).format;

  setUp(() {
    emitter = DartEmitter(useNullSafetySyntax: true);
  });

  String formatExpression(Expression expr) =>
      format('final result = ${expr.accept(emitter)};');

  String formatStatement(String body) => format('final result = $body;');

  group('encodeAnyToJsonExpression', () {
    test('emits encodeAnyToJson(receiver)', () {
      final actual = formatExpression(
        encodeAnyToJsonExpression(refer('value')),
      );
      final expected = formatStatement('encodeAnyToJson(value)');

      expect(
        collapseWhitespace(actual),
        collapseWhitespace(expected),
      );
    });
  });

  group('encodeAnyToSimpleExpression', () {
    test('emits encodeAnyToSimple with named arguments', () {
      final actual = formatExpression(
        encodeAnyToSimpleExpression(
          refer('value'),
          explode: literalBool(true),
          allowEmpty: literalBool(false),
        ),
      );
      final expected = formatStatement(
        'encodeAnyToSimple(value, explode: true, allowEmpty: false)',
      );

      expect(
        collapseWhitespace(actual),
        collapseWhitespace(expected),
      );
    });
  });

  group('encodeAnyToFormExpression', () {
    test('omits useQueryComponent when caller does not supply it', () {
      final actual = formatExpression(
        encodeAnyToFormExpression(
          refer('value'),
          explode: literalBool(true),
          allowEmpty: literalBool(true),
        ),
      );
      final expected = formatStatement(
        'encodeAnyToForm(value, explode: true, allowEmpty: true)',
      );

      expect(
        collapseWhitespace(actual),
        collapseWhitespace(expected),
      );
    });

    test('threads useQueryComponent: true into encodeAnyToForm', () {
      final actual = formatExpression(
        encodeAnyToFormExpression(
          refer('value'),
          explode: literalBool(true),
          allowEmpty: literalBool(true),
          useQueryComponent: literalBool(true),
        ),
      );
      final expected = formatStatement(
        'encodeAnyToForm(value, explode: true, allowEmpty: true, '
        'useQueryComponent: true)',
      );

      expect(
        collapseWhitespace(actual),
        collapseWhitespace(expected),
      );
    });

    test('threads useQueryComponent: false into encodeAnyToForm', () {
      final actual = formatExpression(
        encodeAnyToFormExpression(
          refer('value'),
          explode: literalBool(false),
          allowEmpty: literalBool(false),
          useQueryComponent: literalBool(false),
        ),
      );
      final expected = formatStatement(
        'encodeAnyToForm(value, explode: false, allowEmpty: false, '
        'useQueryComponent: false)',
      );

      expect(
        collapseWhitespace(actual),
        collapseWhitespace(expected),
      );
    });
  });

  group('encodeAnyToMatrixExpression', () {
    test('emits encodeAnyToMatrix with paramName and named args', () {
      final actual = formatExpression(
        encodeAnyToMatrixExpression(
          refer('value'),
          paramName: refer('paramName'),
          explode: refer('explode'),
          allowEmpty: refer('allowEmpty'),
        ),
      );
      final expected = formatStatement(
        'encodeAnyToMatrix(value, paramName, explode: explode, '
        'allowEmpty: allowEmpty)',
      );

      expect(
        collapseWhitespace(actual),
        collapseWhitespace(expected),
      );
    });
  });

  group('encodeAnyToLabelExpression', () {
    test('emits encodeAnyToLabel with named arguments', () {
      final actual = formatExpression(
        encodeAnyToLabelExpression(
          refer('value'),
          explode: refer('explode'),
          allowEmpty: refer('allowEmpty'),
        ),
      );
      final expected = formatStatement(
        'encodeAnyToLabel(value, explode: explode, allowEmpty: allowEmpty)',
      );

      expect(
        collapseWhitespace(actual),
        collapseWhitespace(expected),
      );
    });
  });
}
