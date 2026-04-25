import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/core_prefixed_allocator.dart';
import 'package:tonik_generate/src/util/uri_encode_expression_generator.dart';

void main() {
  late Context context;
  late DartEmitter emitter;
  late DartEmitter scopedEmitter;

  final format = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  ).format;

  setUp(() {
    context = Context.initial();
    emitter = DartEmitter(useNullSafetySyntax: true);
    scopedEmitter = DartEmitter(
      useNullSafetySyntax: true,
      allocator: CorePrefixedAllocator(),
    );
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

    test('generates uriEncode call for BinaryModel', () {
      final model = BinaryModel(context: context);
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

    test('generates uriEncode call for Base64Model', () {
      final model = Base64Model(context: context);
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

    test('generates runtime throw for ClassModel', () {
      final model = ClassModel(
        name: 'TestClass',
        properties: [],
        context: context,
        isDeprecated: false,
      );

      final expression = buildUriEncodeExpression(
        refer('value'),
        model,
        allowEmpty: refer('allowEmpty'),
      );

      expect(
        expression.accept(scopedEmitter).toString(),
        '''throw  _i1.EncodingException('Unsupported model type for URI encoding.')''',
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

    test('generates map expression for List<BinaryModel>', () {
      final model = ListModel(
        content: BinaryModel(context: context),
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

    test('generates map expression for List<Base64Model>', () {
      final model = ListModel(
        content: Base64Model(context: context),
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

    test('generates runtime throw for List<ClassModel>', () {
      final model = ListModel(
        content: ClassModel(
          name: 'TestClass',
          properties: [],
          context: context,
          isDeprecated: false,
        ),
        context: context,
      );

      final expression = buildUriEncodeExpression(
        refer('value'),
        model,
        allowEmpty: refer('allowEmpty'),
      );

      expect(
        expression.accept(scopedEmitter).toString(),
        '''throw  _i1.EncodingException('Unsupported list content type for URI encoding.')''',
      );
    });
  });

  group('buildUriEncodeExpression for MapModel', () {
    test('generates uriEncode for MapModel with StringModel values', () {
      final model = MapModel(
        valueModel: StringModel(context: context),
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

    test('generates map and uriEncode for MapModel with IntegerModel values',
        () {
      final model = MapModel(
        valueModel: IntegerModel(context: context),
        context: context,
      );
      final expression = buildUriEncodeExpression(
        refer('value'),
        model,
        allowEmpty: refer('allowEmpty'),
      );

      final method = Method(
        (b) => b
          ..name = 'test'
          ..body = declareFinal('result').assign(expression).statement,
      );

      final generated = format(method.accept(emitter).toString());
      final expected = format('''
        test() {
          final result = value
              .map((k, v) => MapEntry(k, v.toString()))
              .uriEncode(allowEmpty: allowEmpty);
        }
      ''');

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(expected),
      );
    });

    test('generates runtime throw for MapModel with ClassModel values', () {
      final model = MapModel(
        valueModel: ClassModel(
          isDeprecated: false,
          name: 'TestClass',
          properties: [],
          context: context,
        ),
        context: context,
      );
      final expression = buildUriEncodeExpression(
        refer('value'),
        model,
        allowEmpty: refer('allowEmpty'),
      );

      final method = Method(
        (b) => b
          ..name = 'test'
          ..body = declareFinal('result').assign(expression).statement,
      );

      final generated = format(method.accept(scopedEmitter).toString());
      final expected = format('''
        test() {
          final result = throw _i1.EncodingException(
            'Map with complex value types cannot be URI-encoded.',
          );
        }
      ''');

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(expected),
      );
    });
  });

  group('buildUriEncodeExpression for list-of-map content', () {
    test('generates list-of-map encoding for List<Map<String, int>>', () {
      final model = ListModel(
        content: MapModel(
          valueModel: IntegerModel(context: context),
          context: context,
        ),
        context: context,
      );
      final expression = buildUriEncodeExpression(
        refer('value'),
        model,
        allowEmpty: refer('allowEmpty'),
      );

      final method = Method(
        (b) => b
          ..name = 'test'
          ..body = declareFinal('result').assign(expression).statement,
      );

      final generated = format(method.accept(emitter).toString());
      final expected = format('''
        test() {
          final result = value
              .map(
                (e) => e
                    .map((k, v) => MapEntry(k, v.toString()))
                    .uriEncode(allowEmpty: allowEmpty),
              )
              .toList()
              .uriEncode(allowEmpty: allowEmpty);
        }
      ''');

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(expected),
      );
    });

    test(
        'generates runtime throw for List<Map<String, ClassModel>> '
        '(unsupported)', () {
      final model = ListModel(
        content: MapModel(
          valueModel: ClassModel(
            isDeprecated: false,
            name: 'TestClass',
            properties: [],
            context: context,
          ),
          context: context,
        ),
        context: context,
      );
      final expression = buildUriEncodeExpression(
        refer('value'),
        model,
        allowEmpty: refer('allowEmpty'),
      );

      final method = Method(
        (b) => b
          ..name = 'test'
          ..body = declareFinal('result').assign(expression).statement,
      );

      final generated = format(method.accept(scopedEmitter).toString());
      final expected = format('''
        test() {
          final result = throw _i1.EncodingException(
            'List of maps with complex value types cannot be URI-encoded.',
          );
        }
      ''');

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(expected),
      );
    });
  });
}
