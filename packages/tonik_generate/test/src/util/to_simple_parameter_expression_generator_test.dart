import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/core_prefixed_allocator.dart';
import 'package:tonik_generate/src/util/to_simple_parameter_expression_generator.dart';

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

  group('buildSimpleParameterExpression', () {
    test('generates toSimple call for StringModel', () {
      final model = StringModel(context: context);
      final expression = buildSimpleParameterExpression(
        refer('value'),
        model,
        explode: refer('explode'),
        allowEmpty: refer('allowEmpty'),
      );

      final generated = format('final result = ${expression.accept(emitter)};');
      const expected = '''
        final result = value.toSimple(explode: explode, allowEmpty: allowEmpty);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });

    test('generates toSimple call for IntegerModel', () {
      final model = IntegerModel(context: context);
      final expression = buildSimpleParameterExpression(
        refer('value'),
        model,
        explode: refer('explode'),
        allowEmpty: refer('allowEmpty'),
      );

      final generated = format('final result = ${expression.accept(emitter)};');
      const expected = '''
        final result = value.toSimple(explode: explode, allowEmpty: allowEmpty);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });

    test('generates toSimple call for BooleanModel', () {
      final model = BooleanModel(context: context);
      final expression = buildSimpleParameterExpression(
        refer('value'),
        model,
        explode: refer('explode'),
        allowEmpty: refer('allowEmpty'),
      );

      final generated = format('final result = ${expression.accept(emitter)};');
      const expected = '''
        final result = value.toSimple(explode: explode, allowEmpty: allowEmpty);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });

    test('generates toSimple call for DateTimeModel', () {
      final model = DateTimeModel(context: context);
      final expression = buildSimpleParameterExpression(
        refer('value'),
        model,
        explode: refer('explode'),
        allowEmpty: refer('allowEmpty'),
      );

      final generated = format('final result = ${expression.accept(emitter)};');
      const expected = '''
        final result = value.toSimple(explode: explode, allowEmpty: allowEmpty);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });

    test('generates toSimple call for EnumModel', () {
      final model = EnumModel(
        isDeprecated: false,
        name: 'Status',
        values: {
          const EnumEntry(value: 'active'),
          const EnumEntry(value: 'inactive'),
        },
        isNullable: false,
        context: context,
      );
      final expression = buildSimpleParameterExpression(
        refer('value'),
        model,
        explode: refer('explode'),
        allowEmpty: refer('allowEmpty'),
      );

      final generated = format('final result = ${expression.accept(emitter)};');
      const expected = '''
        final result = value.toSimple(explode: explode, allowEmpty: allowEmpty);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });

    test('generates toSimple call for ClassModel', () {
      final model = ClassModel(
        isDeprecated: false,
        name: 'User',
        properties: [
          Property(
            name: 'id',
            model: IntegerModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ],
        context: context,
      );
      final expression = buildSimpleParameterExpression(
        refer('value'),
        model,
        explode: refer('explode'),
        allowEmpty: refer('allowEmpty'),
      );

      final generated = format('final result = ${expression.accept(emitter)};');
      const expected = '''
        final result = value.toSimple(explode: explode, allowEmpty: allowEmpty);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });

    test('generates toSimple call for List<String>', () {
      final model = ListModel(
        content: StringModel(context: context),
        context: context,
      );
      final expression = buildSimpleParameterExpression(
        refer('value'),
        model,
        explode: refer('explode'),
        allowEmpty: refer('allowEmpty'),
      );

      final generated = format('final result = ${expression.accept(emitter)};');
      const expected = '''
        final result = value.toSimple(explode: explode, allowEmpty: allowEmpty);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });

    test('generates map and toSimple call for List<int>', () {
      final model = ListModel(
        content: IntegerModel(context: context),
        context: context,
      );
      final expression = buildSimpleParameterExpression(
        refer('value'),
        model,
        explode: refer('explode'),
        allowEmpty: refer('allowEmpty'),
      );

      final generated = format('final result = ${expression.accept(emitter)};');
      const expected = '''
        final result = value.map((e) => e.toSimple(explode: explode, allowEmpty: allowEmpty)).toList().toSimple(explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });

    test('generates map and toSimple call for List<Enum>', () {
      final enumModel = EnumModel(
        isDeprecated: false,
        name: 'Status',
        values: {
          const EnumEntry(value: 'active'),
          const EnumEntry(value: 'inactive'),
        },
        isNullable: false,
        context: context,
      );
      final model = ListModel(
        content: enumModel,
        context: context,
      );
      final expression = buildSimpleParameterExpression(
        refer('value'),
        model,
        explode: refer('explode'),
        allowEmpty: refer('allowEmpty'),
      );

      final generated = format('final result = ${expression.accept(emitter)};');
      const expected = '''
        final result = value.map((e) => e.toSimple(explode: explode, allowEmpty: allowEmpty)).toList().toSimple(explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });

    test('generates toSimple call for List<Class>', () {
      final classModel = ClassModel(
        isDeprecated: false,
        name: 'User',
        properties: [
          Property(
            name: 'id',
            model: IntegerModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ],
        context: context,
      );
      final model = ListModel(
        content: classModel,
        context: context,
      );
      final expression = buildSimpleParameterExpression(
        refer('value'),
        model,
        explode: refer('explode'),
        allowEmpty: refer('allowEmpty'),
      );

      final generated = format('final result = ${expression.accept(emitter)};');
      const expected = '''
        final result = value.toSimple(explode: explode, allowEmpty: allowEmpty);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });

    test('generates toSimple call for List<List<String>>', () {
      final innerList = ListModel(
        content: StringModel(context: context),
        context: context,
      );
      final model = ListModel(
        content: innerList,
        context: context,
      );
      final expression = buildSimpleParameterExpression(
        refer('value'),
        model,
        explode: refer('explode'),
        allowEmpty: refer('allowEmpty'),
      );

      final generated = format('final result = ${expression.accept(emitter)};');
      const expected = '''
        final result = value.toSimple(explode: explode, allowEmpty: allowEmpty);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });

    test('generates toSimple call for OneOfModel', () {
      final model = OneOfModel(
        isDeprecated: false,
        name: 'Choice',
        models: {
          (discriminatorValue: 'i', model: IntegerModel(context: context)),
          (discriminatorValue: 's', model: StringModel(context: context)),
        },
        context: context,
      );
      final expression = buildSimpleParameterExpression(
        refer('value'),
        model,
        explode: refer('explode'),
        allowEmpty: refer('allowEmpty'),
      );

      final generated = format('final result = ${expression.accept(emitter)};');
      const expected = '''
        final result = value.toSimple(explode: explode, allowEmpty: allowEmpty);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });

    test('generates toSimple call for AliasModel wrapping StringModel', () {
      final model = AliasModel(
        name: 'MyString',
        model: StringModel(context: context),
        context: context,
      );
      final expression = buildSimpleParameterExpression(
        refer('value'),
        model,
        explode: refer('explode'),
        allowEmpty: refer('allowEmpty'),
      );

      final generated = format('final result = ${expression.accept(emitter)};');
      const expected = '''
        final result = value.toSimple(explode: explode, allowEmpty: allowEmpty);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });

    test('generates map and toSimple call for List<OneOf>', () {
      final oneOfModel = OneOfModel(
        isDeprecated: false,
        name: 'Choice',
        models: {
          (discriminatorValue: 'i', model: IntegerModel(context: context)),
          (discriminatorValue: 's', model: StringModel(context: context)),
        },
        context: context,
      );
      final model = ListModel(
        content: oneOfModel,
        context: context,
      );
      final expression = buildSimpleParameterExpression(
        refer('value'),
        model,
        explode: refer('explode'),
        allowEmpty: refer('allowEmpty'),
      );

      final generated = format('final result = ${expression.accept(emitter)};');
      const expected = '''
        final result = value.map((e) => encodeAnyToUri(e, allowEmpty: allowEmpty)).toList().toSimple(explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });

    test('generates encodeAnyToSimple call for AnyModel', () {
      final model = AnyModel(context: context);
      final expression = buildSimpleParameterExpression(
        refer('value'),
        model,
        explode: refer('explode'),
        allowEmpty: refer('allowEmpty'),
      );

      final generated = format('final result = ${expression.accept(emitter)};');
      const expected = '''
        final result = encodeAnyToSimple(value, explode: explode, allowEmpty: allowEmpty);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });

    test('generates runtime throw for NeverModel', () {
      final model = NeverModel(context: context);
      final expression = buildSimpleParameterExpression(
        refer('value'),
        model,
        explode: refer('explode'),
        allowEmpty: refer('allowEmpty'),
      );

      expect(
        expression.accept(scopedEmitter).toString(),
        '''throw  _i1.EncodingException('Unsupported model type for simple encoding.')''',
      );
    });

    test('generates runtime throw for List with NeverModel content', () {
      final model = ListModel(
        content: NeverModel(context: context),
        context: context,
      );
      final expression = buildSimpleParameterExpression(
        refer('value'),
        model,
        explode: refer('explode'),
        allowEmpty: refer('allowEmpty'),
      );

      expect(
        expression.accept(scopedEmitter).toString(),
        '''throw  _i1.EncodingException('Unsupported list content type for simple encoding.')''',
      );
    });
  });

  group('nullable receiver support', () {
    test('generates null-safe toSimple for StringModel when isNullable', () {
      final model = StringModel(context: context);
      final expression = buildSimpleParameterExpression(
        refer('value'),
        model,
        explode: refer('explode'),
        allowEmpty: refer('allowEmpty'),
        isNullable: true,
      );

      final generated = format(
        'final result = ${expression.accept(emitter)};',
      );
      const expected = '''
        final result =
            value?.toSimple(explode: explode, allowEmpty: allowEmpty);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });

    test('generates null-safe toSimple for ClassModel when isNullable', () {
      final model = ClassModel(
        name: 'MyClass',
        properties: [],
        isDeprecated: false,
        context: context,
      );
      final expression = buildSimpleParameterExpression(
        refer('value'),
        model,
        explode: refer('explode'),
        allowEmpty: refer('allowEmpty'),
        isNullable: true,
      );

      final generated = format(
        'final result = ${expression.accept(emitter)};',
      );
      const expected = '''
        final result =
            value?.toSimple(explode: explode, allowEmpty: allowEmpty);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });

    test('generates null-safe toSimple for ListModel when isNullable', () {
      final model = ListModel(
        content: StringModel(context: context),
        context: context,
      );
      final expression = buildSimpleParameterExpression(
        refer('value'),
        model,
        explode: refer('explode'),
        allowEmpty: refer('allowEmpty'),
        isNullable: true,
      );

      final generated = format(
        'final result = ${expression.accept(emitter)};',
      );
      const expected = '''
        final result =
            value?.toSimple(explode: explode, allowEmpty: allowEmpty);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });

    test(
      'generates null-safe map for ListModel with IntegerModel content '
      'when isNullable',
      () {
        final model = ListModel(
          content: IntegerModel(context: context),
          context: context,
        );
        final expression = buildSimpleParameterExpression(
          refer('value'),
          model,
          explode: refer('explode'),
          allowEmpty: refer('allowEmpty'),
          isNullable: true,
        );

        final method = Method(
          (b) => b
            ..name = 'test'
            ..body = declareFinal('result').assign(expression).statement,
        );

        final generated = format(method.accept(emitter).toString());
        const expected = '''
          test() {
            final result = value
                ?.map(
                  (e) =>
                      e.toSimple(explode: explode, allowEmpty: allowEmpty),
                )
                .toList()
                .toSimple(
                  explode: explode,
                  allowEmpty: allowEmpty,
                  alreadyEncoded: true,
                );
          }
        ''';

        expect(
          collapseWhitespace(generated),
          collapseWhitespace(format(expected)),
        );
      },
    );

    test('uses null-safe access for AliasModel when isNullable', () {
      final model = AliasModel(
        name: 'MyAlias',
        model: StringModel(context: context),
        context: context,
        isNullable: true,
      );
      final expression = buildSimpleParameterExpression(
        refer('value'),
        model,
        explode: refer('explode'),
        allowEmpty: refer('allowEmpty'),
        isNullable: true,
      );

      final generated = format(
        'final result = ${expression.accept(emitter)};',
      );
      const expected = '''
        final result =
            value?.toSimple(explode: explode, allowEmpty: allowEmpty);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });

    test('does not use null-safe when isNullable is false', () {
      final model = StringModel(context: context);
      final expression = buildSimpleParameterExpression(
        refer('value'),
        model,
        explode: refer('explode'),
        allowEmpty: refer('allowEmpty'),
      );

      final generated = format(
        'final result = ${expression.accept(emitter)};',
      );
      const expected = '''
        final result =
            value.toSimple(explode: explode, allowEmpty: allowEmpty);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });
  });
}
