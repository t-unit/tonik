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

  group('jsonEncodingPolicy', () {
    test('encodeAny calls encodeAnyToJson with the receiver', () {
      final policy = jsonEncodingPolicy();

      final actual = formatExpression(policy.encodeAny(refer('value')));
      final expected = formatStatement('encodeAnyToJson(value)');

      expect(
        collapseWhitespace(actual),
        collapseWhitespace(expected),
      );
    });
  });

  group('simpleEncodingPolicy', () {
    test('encodeAny calls encodeAnyToSimple with named arguments', () {
      final policy = simpleEncodingPolicy(
        explode: refer('explode'),
        allowEmpty: refer('allowEmpty'),
      );

      final actual = formatExpression(policy.encodeAny(refer('value')));
      final expected = formatStatement(
        'encodeAnyToSimple(value, explode: explode, allowEmpty: allowEmpty)',
      );

      expect(
        collapseWhitespace(actual),
        collapseWhitespace(expected),
      );
    });

    test('encodeAny accepts boolean literals for explode and allowEmpty', () {
      final policy = simpleEncodingPolicy(
        explode: literalBool(true),
        allowEmpty: literalBool(false),
      );

      final actual = formatExpression(policy.encodeAny(refer('value')));
      final expected = formatStatement(
        'encodeAnyToSimple(value, explode: true, allowEmpty: false)',
      );

      expect(
        collapseWhitespace(actual),
        collapseWhitespace(expected),
      );
    });
  });

  group('formEncodingPolicy', () {
    test('encodeAny calls encodeAnyToForm with named arguments', () {
      final policy = formEncodingPolicy(
        explode: refer('explode'),
        allowEmpty: refer('allowEmpty'),
      );

      final actual = formatExpression(policy.encodeAny(refer('value')));
      final expected = formatStatement(
        'encodeAnyToForm(value, explode: explode, allowEmpty: allowEmpty)',
      );

      expect(
        collapseWhitespace(actual),
        collapseWhitespace(expected),
      );
    });

    test('encodeAny accepts boolean literals for explode and allowEmpty', () {
      final policy = formEncodingPolicy(
        explode: literalBool(false),
        allowEmpty: literalBool(true),
      );

      final actual = formatExpression(policy.encodeAny(refer('value')));
      final expected = formatStatement(
        'encodeAnyToForm(value, explode: false, allowEmpty: true)',
      );

      expect(
        collapseWhitespace(actual),
        collapseWhitespace(expected),
      );
    });

    test('encodeAny threads useQueryComponent into encodeAnyToForm', () {
      final policy = formEncodingPolicy(
        explode: literalBool(true),
        allowEmpty: literalBool(true),
        useQueryComponent: literalBool(true),
      );

      final actual = formatExpression(policy.encodeAny(refer('value')));
      final expected = formatStatement(
        'encodeAnyToForm(value, explode: true, allowEmpty: true, '
        'useQueryComponent: true)',
      );

      expect(
        collapseWhitespace(actual),
        collapseWhitespace(expected),
      );
    });

    test('encodeAny omits useQueryComponent when caller does not supply it',
        () {
      final policy = formEncodingPolicy(
        explode: literalBool(true),
        allowEmpty: literalBool(true),
      );

      final actual = formatExpression(policy.encodeAny(refer('value')));
      final expected = formatStatement(
        'encodeAnyToForm(value, explode: true, allowEmpty: true)',
      );

      expect(
        collapseWhitespace(actual),
        collapseWhitespace(expected),
      );
    });
  });

  group('matrixEncodingPolicy', () {
    test('encodeAny calls encodeAnyToMatrix with paramName and named args',
        () {
      final policy = matrixEncodingPolicy(
        paramName: refer('paramName'),
        explode: refer('explode'),
        allowEmpty: refer('allowEmpty'),
      );

      final actual = formatExpression(policy.encodeAny(refer('value')));
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

  group('labelEncodingPolicy', () {
    test('encodeAny calls encodeAnyToLabel with named arguments', () {
      final policy = labelEncodingPolicy(
        explode: refer('explode'),
        allowEmpty: refer('allowEmpty'),
      );

      final actual = formatExpression(policy.encodeAny(refer('value')));
      final expected = formatStatement(
        'encodeAnyToLabel(value, explode: explode, allowEmpty: allowEmpty)',
      );

      expect(
        collapseWhitespace(actual),
        collapseWhitespace(expected),
      );
    });
  });

  group('neverThrow', () {
    // Each factory returns its own EncodingPolicy, but they all share the
    // same `neverThrow` closure. One parameterised assertion covers every
    // factory; if a future refactor splits the closures the loop still
    // surfaces a regression at the diverging factory.
    final factories = <String, EncodingPolicy Function()>{
      'jsonEncodingPolicy': jsonEncodingPolicy,
      'simpleEncodingPolicy': () => simpleEncodingPolicy(
            explode: refer('explode'),
            allowEmpty: refer('allowEmpty'),
          ),
      'formEncodingPolicy': () => formEncodingPolicy(
            explode: refer('explode'),
            allowEmpty: refer('allowEmpty'),
          ),
      'matrixEncodingPolicy': () => matrixEncodingPolicy(
            paramName: refer('paramName'),
            explode: refer('explode'),
            allowEmpty: refer('allowEmpty'),
          ),
      'labelEncodingPolicy': () => labelEncodingPolicy(
            explode: refer('explode'),
            allowEmpty: refer('allowEmpty'),
          ),
    };

    final expectedThrow = formatStatement(
      "throw EncodingException('Cannot encode NeverModel - this type "
      "does not permit any value.')",
    );

    for (final entry in factories.entries) {
      test('${entry.key} neverThrow emits the standard NeverModel throw', () {
        final policy = entry.value();

        final actual = formatExpression(policy.neverThrow());

        expect(
          collapseWhitespace(actual),
          collapseWhitespace(expectedThrow),
        );
      });
    }
  });
}
