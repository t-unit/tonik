import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/default_value_materialiser.dart';

void main() {
  late Context context;
  final formatter = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  );

  String renderExpression(Expression expression) {
    final method = Method(
      (b) => b
        ..name = '_render'
        ..lambda = true
        ..body = expression.code,
    );
    final source = '${method.accept(DartEmitter())};';
    return formatter.format(source);
  }

  String formatBody(String body) =>
      formatter.format('_render() => $body;');

  setUp(() {
    context = Context.initial();
  });

  group('materialiseConstDefault — primitives', () {
    test('StringModel + String literal materialises as a raw literal', () {
      final result = materialiseConstDefault(
        jsonValue: 'anon',
        targetModel: StringModel(context: context),
      );

      expect(result, isNotNull);
      expect(
        collapseWhitespace(renderExpression(result!)),
        collapseWhitespace(formatBody("r'anon'")),
      );
    });

    test(r'StringModel + String containing $ is escaped as raw string', () {
      final result = materialiseConstDefault(
        jsonValue: r'Hello $world',
        targetModel: StringModel(context: context),
      );

      expect(result, isNotNull);
      expect(
        collapseWhitespace(renderExpression(result!)),
        collapseWhitespace(formatBody(r"r'Hello $world'")),
      );
    });

    test('IntegerModel + int materialises as literalNum', () {
      final result = materialiseConstDefault(
        jsonValue: 0,
        targetModel: IntegerModel(context: context),
      );

      expect(result, isNotNull);
      expect(
        collapseWhitespace(renderExpression(result!)),
        collapseWhitespace(formatBody('0')),
      );
    });

    test('DoubleModel + num materialises as double literal', () {
      final result = materialiseConstDefault(
        jsonValue: 1.5,
        targetModel: DoubleModel(context: context),
      );

      expect(result, isNotNull);
      expect(
        collapseWhitespace(renderExpression(result!)),
        collapseWhitespace(formatBody('1.5')),
      );
    });

    test('DoubleModel + int promotes via toDouble()', () {
      final result = materialiseConstDefault(
        jsonValue: 2,
        targetModel: DoubleModel(context: context),
      );

      expect(result, isNotNull);
      expect(
        collapseWhitespace(renderExpression(result!)),
        collapseWhitespace(formatBody('2.0')),
      );
    });

    test('NumberModel + int materialises as literalNum', () {
      final result = materialiseConstDefault(
        jsonValue: 3,
        targetModel: NumberModel(context: context),
      );

      expect(result, isNotNull);
      expect(
        collapseWhitespace(renderExpression(result!)),
        collapseWhitespace(formatBody('3')),
      );
    });

    test('BooleanModel + bool materialises as literalBool', () {
      final result = materialiseConstDefault(
        jsonValue: true,
        targetModel: BooleanModel(context: context),
      );

      expect(result, isNotNull);
      expect(
        collapseWhitespace(renderExpression(result!)),
        collapseWhitespace(formatBody('true')),
      );
    });
  });

  group('materialiseConstDefault — type mismatches', () {
    test('StringModel + int returns null', () {
      final result = materialiseConstDefault(
        jsonValue: 42,
        targetModel: StringModel(context: context),
      );

      expect(result, isNull);
    });

    test('IntegerModel + String returns null', () {
      final result = materialiseConstDefault(
        jsonValue: 'no',
        targetModel: IntegerModel(context: context),
      );

      expect(result, isNull);
    });

    test('IntegerModel + double returns null', () {
      final result = materialiseConstDefault(
        jsonValue: 1.5,
        targetModel: IntegerModel(context: context),
      );

      expect(result, isNull);
    });

    test('BooleanModel + String returns null', () {
      final result = materialiseConstDefault(
        jsonValue: 'true',
        targetModel: BooleanModel(context: context),
      );

      expect(result, isNull);
    });
  });

  group('materialiseConstDefault — null jsonValue returns null', () {
    test('null + non-nullable primitive returns null', () {
      final result = materialiseConstDefault(
        jsonValue: null,
        targetModel: StringModel(context: context),
      );

      expect(result, isNull);
    });

    test('null + alias-wrapped nullable primitive returns null', () {
      final alias = AliasModel(
        name: 'NullableString',
        model: StringModel(context: context),
        context: context,
        examples: const [],
        defaultValue: null,
        isNullable: true,
      );

      final result = materialiseConstDefault(
        jsonValue: null,
        targetModel: alias,
      );

      expect(result, isNull);
    });
  });

  group('materialiseConstDefault — alias resolution', () {
    test('AliasModel wrapping a primitive routes to the primitive branch', () {
      final alias = AliasModel(
        name: 'Tagged',
        model: StringModel(context: context),
        context: context,
        examples: const [],
        defaultValue: null,
      );

      final result = materialiseConstDefault(
        jsonValue: 'hi',
        targetModel: alias,
      );

      expect(result, isNotNull);
      expect(
        collapseWhitespace(renderExpression(result!)),
        collapseWhitespace(formatBody("r'hi'")),
      );
    });

    test('AliasModel chain ending in IntegerModel resolves correctly', () {
      final inner = AliasModel(
        name: 'InnerAlias',
        model: IntegerModel(context: context),
        context: context,
        examples: const [],
        defaultValue: null,
      );
      final outer = AliasModel(
        name: 'OuterAlias',
        model: inner,
        context: context,
        examples: const [],
        defaultValue: null,
      );

      final result = materialiseConstDefault(
        jsonValue: 7,
        targetModel: outer,
      );

      expect(result, isNotNull);
      expect(
        collapseWhitespace(renderExpression(result!)),
        collapseWhitespace(formatBody('7')),
      );
    });
  });

  group('materialiseConstDefault — non-primitive targets return null', () {
    test('ClassModel returns null', () {
      final result = materialiseConstDefault(
        jsonValue: <String, Object?>{},
        targetModel: ClassModel(
          name: 'Address',
          isDeprecated: false,
          properties: const [],
          context: context,
          examples: const [],
        ),
      );

      expect(result, isNull);
    });

    test('DateTimeModel returns null', () {
      final result = materialiseConstDefault(
        jsonValue: '2024-01-01T00:00:00Z',
        targetModel: DateTimeModel(context: context),
      );

      expect(result, isNull);
    });

    test('AnyModel returns null', () {
      final result = materialiseConstDefault(
        jsonValue: 'anything',
        targetModel: AnyModel(context: context),
      );

      expect(result, isNull);
    });
  });
}
