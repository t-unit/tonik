import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/property_value_expression_generator.dart';

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

  void expectListEmission(
    Model contentModel,
    String expectedBody, {
    required bool isContentNullable,
    bool useImmutableCollections = false,
  }) {
    final result = buildRawStringListExpression(
      refer('myValue'),
      contentModel,
      isContentNullable: isContentNullable,
      useImmutableCollections: useImmutableCollections,
    );
    final expected = format('test() { final result = $expectedBody; }');
    expect(
      collapseWhitespace(formatExpression(result)),
      collapseWhitespace(expected),
    );
  }

  group('buildRawStringListExpression', () {
    test('non-nullable String content returns the list unchanged', () {
      expectListEmission(
        StringModel(context: context),
        'myValue',
        isContentNullable: false,
      );
    });

    test('nullable String content maps null elements to empty string', () {
      expectListEmission(
        StringModel(context: context),
        "myValue.map((e) => e ?? '').toList()",
        isContentNullable: true,
      );
    });

    test('scalar content maps each element to its raw string', () {
      expectListEmission(
        IntegerModel(context: context),
        'myValue.map((e) => e.toString()).toList()',
        isContentNullable: false,
      );
    });

    test('immutable collections unlock the list before mapping', () {
      expectListEmission(
        IntegerModel(context: context),
        'myValue.unlock.map((e) => e.toString()).toList()',
        isContentNullable: false,
        useImmutableCollections: true,
      );
    });

    test('content-nullable scalar guards null elements to empty string', () {
      expectListEmission(
        IntegerModel(context: context),
        "myValue.map((e) => e == null ? '' : e.toString()).toList()",
        isContentNullable: true,
      );
    });

    test('alias-wrapped content resolves to the aliased scalar mapping', () {
      expectListEmission(
        AliasModel(
          name: 'Count',
          model: IntegerModel(context: context),
          context: context,
          examples: const [],
          defaultValue: null,
        ),
        'myValue.map((e) => e.toString()).toList()',
        isContentNullable: false,
      );
    });

    test('composite content maps each element to its raw string', () {
      expectListEmission(
        OneOfModel(
          isDeprecated: false,
          name: 'StringOrInt',
          models: {
            (discriminatorValue: null, model: StringModel(context: context)),
            (discriminatorValue: null, model: IntegerModel(context: context)),
          },
          context: context,
          examples: const [],
        ),
        'myValue.map((e) => '
        'encodeAnyValueToString(e.toJson(), allowEmpty: allowEmpty)).toList()',
        isContentNullable: false,
      );
    });

    test('content-nullable composite guards null elements to empty string', () {
      expectListEmission(
        OneOfModel(
          isDeprecated: false,
          name: 'StringOrInt',
          models: {
            (discriminatorValue: null, model: StringModel(context: context)),
            (discriminatorValue: null, model: IntegerModel(context: context)),
          },
          context: context,
          examples: const [],
        ),
        "myValue.map((e) => e == null ? '' : "
        'encodeAnyValueToString(e.toJson(), allowEmpty: allowEmpty)).toList()',
        isContentNullable: true,
      );
    });

    test('unsupported content throws an encoding exception', () {
      expectListEmission(
        ClassModel(
          isDeprecated: false,
          name: 'Nested',
          properties: const [],
          context: context,
          examples: const [],
        ),
        "throw EncodingException('Unsupported list content type for URI "
        "encoding.')",
        isContentNullable: false,
      );
    });
  });
}
