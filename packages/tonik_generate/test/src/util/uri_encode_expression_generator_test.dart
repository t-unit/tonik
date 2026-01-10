import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/uri_encode_expression_generator.dart';

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

  group('buildUriEncodeExpression', () {
    test('generates uriEncode call for StringModel', () {
      final model = StringModel(context: context);
      final expression = buildUriEncodeExpression(
        refer('value'),
        model,
        allowEmpty: refer('allowEmpty'),
      );

      final generated = format('final result = ${expression.accept(emitter)};');
      const expected = '''
        final result = value.uriEncode(allowEmpty: allowEmpty);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });

    test('generates uriEncode call for IntegerModel', () {
      final model = IntegerModel(context: context);
      final expression = buildUriEncodeExpression(
        refer('value'),
        model,
        allowEmpty: refer('allowEmpty'),
      );

      final generated = format('final result = ${expression.accept(emitter)};');
      const expected = '''
        final result = value.uriEncode(allowEmpty: allowEmpty);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });

    test('generates uriEncode call for BooleanModel', () {
      final model = BooleanModel(context: context);
      final expression = buildUriEncodeExpression(
        refer('value'),
        model,
        allowEmpty: refer('allowEmpty'),
      );

      final generated = format('final result = ${expression.accept(emitter)};');
      const expected = '''
        final result = value.uriEncode(allowEmpty: allowEmpty);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });

    test('generates uriEncode call for DateTimeModel', () {
      final model = DateTimeModel(context: context);
      final expression = buildUriEncodeExpression(
        refer('value'),
        model,
        allowEmpty: refer('allowEmpty'),
      );

      final generated = format('final result = ${expression.accept(emitter)};');
      const expected = '''
        final result = value.uriEncode(allowEmpty: allowEmpty);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });

    test('generates uriEncode call for DecimalModel', () {
      final model = DecimalModel(context: context);
      final expression = buildUriEncodeExpression(
        refer('value'),
        model,
        allowEmpty: refer('allowEmpty'),
      );

      final generated = format('final result = ${expression.accept(emitter)};');
      const expected = '''
        final result = value.uriEncode(allowEmpty: allowEmpty);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });

    test('generates uriEncode call for EnumModel', () {
      final model = EnumModel<String>(
        name: 'TestEnum',
        values: {
          const EnumEntry(value: 'value1'),
          const EnumEntry(value: 'value2'),
        },
        isNullable: false,
        context: context,
        isDeprecated: false,
      );
      final expression = buildUriEncodeExpression(
        refer('value'),
        model,
        allowEmpty: refer('allowEmpty'),
      );

      final generated = format('final result = ${expression.accept(emitter)};');
      const expected = '''
        final result = value.uriEncode(allowEmpty: allowEmpty);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });

    test('generates uriEncode call with useQueryComponent', () {
      final model = StringModel(context: context);
      final expression = buildUriEncodeExpression(
        refer('value'),
        model,
        allowEmpty: refer('allowEmpty'),
        useQueryComponent: refer('useQueryComponent'),
      );

      final generated = format('final result = ${expression.accept(emitter)};');
      const expected = '''
        final result = value.uriEncode(
          allowEmpty: allowEmpty,
          useQueryComponent: useQueryComponent,
        );
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });

    test('generates encodeAnyToUri call for AnyModel', () {
      final model = AnyModel(context: context);
      final expression = buildUriEncodeExpression(
        refer('value'),
        model,
        allowEmpty: refer('allowEmpty'),
      );

      final generated = format('final result = ${expression.accept(emitter)};');
      const expected = '''
        final result = encodeAnyToUri(value, allowEmpty: allowEmpty);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });

    test(
      'generates encodeAnyToUri call for AnyModel with useQueryComponent',
      () {
        final model = AnyModel(context: context);
        final expression = buildUriEncodeExpression(
          refer('value'),
          model,
          allowEmpty: refer('allowEmpty'),
          useQueryComponent: refer('useQueryComponent'),
        );

        final generated = format(
          'final result = ${expression.accept(emitter)};',
        );
        const expected = '''
        final result = encodeAnyToUri(
          value,
          allowEmpty: allowEmpty,
          useQueryComponent: useQueryComponent,
        );
      ''';

        expect(
          collapseWhitespace(generated),
          collapseWhitespace(format(expected)),
        );
      },
    );

    test('resolves AliasModel and generates correct expression', () {
      final aliasModel = AliasModel(
        name: 'StringAlias',
        model: StringModel(context: context),
        context: context,
      );
      final expression = buildUriEncodeExpression(
        refer('value'),
        aliasModel,
        allowEmpty: refer('allowEmpty'),
      );

      final generated = format('final result = ${expression.accept(emitter)};');
      const expected = '''
        final result = value.uriEncode(allowEmpty: allowEmpty);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });

    test('throws UnimplementedError for ClassModel', () {
      final model = ClassModel(
        name: 'TestClass',
        properties: [],
        context: context,
        isDeprecated: false,
      );

      expect(
        () => buildUriEncodeExpression(
          refer('value'),
          model,
          allowEmpty: refer('allowEmpty'),
        ),
        throwsA(isA<UnimplementedError>()),
      );
    });
  });

  group('buildUriEncodeExpression for ListModel', () {
    test('generates uriEncode call for List<String>', () {
      final model = ListModel(
        content: StringModel(context: context),
        context: context,
      );
      final expression = buildUriEncodeExpression(
        refer('value'),
        model,
        allowEmpty: refer('allowEmpty'),
      );

      final generated = format('final result = ${expression.accept(emitter)};');
      const expected = '''
        final result = value.uriEncode(allowEmpty: allowEmpty);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });

    test('generates map expression for List<int>', () {
      final model = ListModel(
        content: IntegerModel(context: context),
        context: context,
      );
      final expression = buildUriEncodeExpression(
        refer('value'),
        model,
        allowEmpty: refer('allowEmpty'),
      );

      final generated = format('final result = ${expression.accept(emitter)};');
      const expected = '''
        final result = value
            .map((e) => e.uriEncode(allowEmpty: allowEmpty))
            .toList()
            .uriEncode(allowEmpty: allowEmpty);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });

    test('generates map expression for List<bool>', () {
      final model = ListModel(
        content: BooleanModel(context: context),
        context: context,
      );
      final expression = buildUriEncodeExpression(
        refer('value'),
        model,
        allowEmpty: refer('allowEmpty'),
      );

      final generated = format('final result = ${expression.accept(emitter)};');
      const expected = '''
        final result = value
            .map((e) => e.uriEncode(allowEmpty: allowEmpty))
            .toList()
            .uriEncode(allowEmpty: allowEmpty);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });

    test('generates map expression for List<DateTime>', () {
      final model = ListModel(
        content: DateTimeModel(context: context),
        context: context,
      );
      final expression = buildUriEncodeExpression(
        refer('value'),
        model,
        allowEmpty: refer('allowEmpty'),
      );

      final generated = format('final result = ${expression.accept(emitter)};');
      const expected = '''
        final result = value
            .map((e) => e.uriEncode(allowEmpty: allowEmpty))
            .toList()
            .uriEncode(allowEmpty: allowEmpty);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });

    test('generates map expression for List<Enum>', () {
      final enumModel = EnumModel<String>(
        name: 'TestEnum',
        values: {
          const EnumEntry(value: 'value1'),
          const EnumEntry(value: 'value2'),
        },
        isNullable: false,
        context: context,
        isDeprecated: false,
      );
      final model = ListModel(
        content: enumModel,
        context: context,
      );
      final expression = buildUriEncodeExpression(
        refer('value'),
        model,
        allowEmpty: refer('allowEmpty'),
      );

      final generated = format('final result = ${expression.accept(emitter)};');
      const expected = '''
        final result = value
            .map((e) => e.uriEncode(allowEmpty: allowEmpty))
            .toList()
            .uriEncode(allowEmpty: allowEmpty);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });

    test('generates map expression for List<AnyModel>', () {
      final model = ListModel(
        content: AnyModel(context: context),
        context: context,
      );
      final expression = buildUriEncodeExpression(
        refer('value'),
        model,
        allowEmpty: refer('allowEmpty'),
      );

      final generated = format('final result = ${expression.accept(emitter)};');
      const expected = '''
        final result = value
            .map((e) => encodeAnyToUri(e, allowEmpty: allowEmpty))
            .toList()
            .uriEncode(allowEmpty: allowEmpty);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });

    test(
      'generates map expression for List<AnyModel> with useQueryComponent',
      () {
        final model = ListModel(
          content: AnyModel(context: context),
          context: context,
        );
        final expression = buildUriEncodeExpression(
          refer('value'),
          model,
          allowEmpty: refer('allowEmpty'),
          useQueryComponent: refer('useQueryComponent'),
        );

        final generated = format(
          'final result = ${expression.accept(emitter)};',
        );
        const expected = '''
        final result = value
            .map((e) => encodeAnyToUri(
                  e,
                  allowEmpty: allowEmpty,
                  useQueryComponent: useQueryComponent,
                ))
            .toList()
            .uriEncode(
              allowEmpty: allowEmpty,
              useQueryComponent: useQueryComponent,
            );
      ''';

        expect(
          collapseWhitespace(generated),
          collapseWhitespace(format(expected)),
        );
      },
    );

    test('resolves AliasModel content and generates correct expression', () {
      final aliasModel = AliasModel(
        name: 'IntAlias',
        model: IntegerModel(context: context),
        context: context,
      );
      final model = ListModel(
        content: aliasModel,
        context: context,
      );
      final expression = buildUriEncodeExpression(
        refer('value'),
        model,
        allowEmpty: refer('allowEmpty'),
      );

      final generated = format('final result = ${expression.accept(emitter)};');
      const expected = '''
        final result = value
            .map((e) => e.uriEncode(allowEmpty: allowEmpty))
            .toList()
            .uriEncode(allowEmpty: allowEmpty);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });

    test('throws UnimplementedError for List<ClassModel>', () {
      final model = ListModel(
        content: ClassModel(
          name: 'TestClass',
          properties: [],
          context: context,
          isDeprecated: false,
        ),
        context: context,
      );

      expect(
        () => buildUriEncodeExpression(
          refer('value'),
          model,
          allowEmpty: refer('allowEmpty'),
        ),
        throwsA(isA<UnimplementedError>()),
      );
    });
  });
}
