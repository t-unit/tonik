import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/raw_string_expression_generator.dart';

void main() {
  late Context context;
  late DartEmitter emitter;

  final format = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  ).format;

  setUp(() {
    context = Context.initial();
    emitter = DartEmitter(useNullSafetySyntax: true);
  });

  String formatExpression(Expression expr) {
    final method = Method(
      (b) => b
        ..name = 'test'
        ..body = declareFinal('result').assign(expr).statement,
    );
    return format(method.accept(emitter).toString());
  }

  void expectEmission(Model model, String expectedBody) {
    final result = buildRawStringExpression(refer('myValue'), model);
    final expected = format('test() { final result = $expectedBody; }');
    expect(
      collapseWhitespace(formatExpression(result)),
      collapseWhitespace(expected),
    );
  }

  group('buildRawStringExpression', () {
    test('StringModel emits the receiver unchanged', () {
      expectEmission(StringModel(context: context), 'myValue');
    });

    test('IntegerModel emits myValue.toString()', () {
      expectEmission(IntegerModel(context: context), 'myValue.toString()');
    });

    test('DoubleModel emits myValue.toString()', () {
      expectEmission(DoubleModel(context: context), 'myValue.toString()');
    });

    test('NumberModel emits myValue.toString()', () {
      expectEmission(NumberModel(context: context), 'myValue.toString()');
    });

    test('BooleanModel emits myValue.toString()', () {
      expectEmission(BooleanModel(context: context), 'myValue.toString()');
    });

    test('DecimalModel emits myValue.toString()', () {
      expectEmission(DecimalModel(context: context), 'myValue.toString()');
    });

    test('UriModel emits myValue.toString()', () {
      expectEmission(UriModel(context: context), 'myValue.toString()');
    });

    test('DateModel emits myValue.toString()', () {
      expectEmission(DateModel(context: context), 'myValue.toString()');
    });

    test('DateTimeModel emits myValue.toTimeZonedIso8601String()', () {
      expectEmission(
        DateTimeModel(context: context),
        'myValue.toTimeZonedIso8601String()',
      );
    });

    test('EnumModel<String> emits myValue.toJson()', () {
      expectEmission(
        EnumModel<String>(
          isDeprecated: false,
          name: 'Status',
          values: {const EnumEntry(value: 'active')},
          isNullable: false,
          context: context,
          examples: const [],
        ),
        'myValue.toJson()',
      );
    });

    test('EnumModel<int> emits myValue.toJson().toString()', () {
      expectEmission(
        EnumModel<int>(
          isDeprecated: false,
          name: 'Priority',
          values: {const EnumEntry(value: 1)},
          isNullable: false,
          context: context,
          examples: const [],
        ),
        'myValue.toJson().toString()',
      );
    });

    test('Base64Model emits myValue.toBase64String()', () {
      expectEmission(Base64Model(context: context), 'myValue.toBase64String()');
    });

    test('BinaryModel emits myValue.toBytes().decodeToString()', () {
      expectEmission(
        BinaryModel(context: context),
        'myValue.toBytes().decodeToString()',
      );
    });

    test('AliasModel recurses into the resolved DateTimeModel', () {
      expectEmission(
        AliasModel(
          name: 'MyTimestamp',
          model: DateTimeModel(context: context),
          context: context,
          examples: const [],
          defaultValue: null,
        ),
        'myValue.toTimeZonedIso8601String()',
      );
    });

    test('throws for an unsupported model', () {
      expect(
        () => buildRawStringExpression(
          refer('myValue'),
          ClassModel(
            isDeprecated: false,
            name: 'User',
            properties: const [],
            context: context,
            examples: const [],
          ),
        ),
        throwsUnsupportedError,
      );
    });
  });
}
