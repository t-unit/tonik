import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/to_form_parameter_expression_generator.dart';

void main() {
  late Context context;
  late DartEmitter emitter;

  final format =
      DartFormatter(
        languageVersion: DartFormatter.latestLanguageVersion,
      ).format;

  setUp(() {
    context = Context.initial();
    emitter = DartEmitter(useNullSafetySyntax: true);
  });

  group('buildFormParameterExpression', () {
    test('generates toForm call for StringModel', () {
      final model = StringModel(context: context);
      final expression = buildFormParameterExpression(
        refer('value'),
        model,
        explode: refer('explode'),
        allowEmpty: refer('allowEmpty'),
      );

      final generated = format('final result = ${expression.accept(emitter)};');
      const expected = '''
        final result = value.toForm(explode: explode, allowEmpty: allowEmpty);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });

    test('generates toForm call for IntegerModel', () {
      final model = IntegerModel(context: context);
      final expression = buildFormParameterExpression(
        refer('value'),
        model,
        explode: refer('explode'),
        allowEmpty: refer('allowEmpty'),
      );

      final generated = format('final result = ${expression.accept(emitter)};');
      const expected = '''
        final result = value.toForm(explode: explode, allowEmpty: allowEmpty);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });

    test('generates toForm call for BooleanModel', () {
      final model = BooleanModel(context: context);
      final expression = buildFormParameterExpression(
        refer('value'),
        model,
        explode: refer('explode'),
        allowEmpty: refer('allowEmpty'),
      );

      final generated = format('final result = ${expression.accept(emitter)};');
      const expected = '''
        final result = value.toForm(explode: explode, allowEmpty: allowEmpty);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });

    test('generates toForm call for DateTimeModel', () {
      final model = DateTimeModel(context: context);
      final expression = buildFormParameterExpression(
        refer('value'),
        model,
        explode: refer('explode'),
        allowEmpty: refer('allowEmpty'),
      );

      final generated = format('final result = ${expression.accept(emitter)};');
      const expected = '''
        final result = value.toForm(explode: explode, allowEmpty: allowEmpty);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });

    test('generates toForm call for EnumModel', () {
      final model = EnumModel(
        isDeprecated: false,
        name: 'Status',
        values: const {'active', 'inactive'},
        isNullable: false,
        context: context,
        description: null,
      );
      final expression = buildFormParameterExpression(
        refer('value'),
        model,
        explode: refer('explode'),
        allowEmpty: refer('allowEmpty'),
      );

      final generated = format('final result = ${expression.accept(emitter)};');
      const expected = '''
        final result = value.toForm(explode: explode, allowEmpty: allowEmpty);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });

    test('generates toForm call for ClassModel', () {
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
            description: null,
          ),
        ],
        context: context,
        description: null,
      );
      final expression = buildFormParameterExpression(
        refer('value'),
        model,
        explode: refer('explode'),
        allowEmpty: refer('allowEmpty'),
      );

      final generated = format('final result = ${expression.accept(emitter)};');
      const expected = '''
        final result = value.toForm(explode: explode, allowEmpty: allowEmpty);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });

    test('generates toForm call for List<String>', () {
      final model = ListModel(
        content: StringModel(context: context),
        context: context,
      );
      final expression = buildFormParameterExpression(
        refer('value'),
        model,
        explode: refer('explode'),
        allowEmpty: refer('allowEmpty'),
      );

      final generated = format('final result = ${expression.accept(emitter)};');
      const expected = '''
        final result = value.toForm(explode: explode, allowEmpty: allowEmpty);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });

    test('generates map and toForm call for List<int>', () {
      final model = ListModel(
        content: IntegerModel(context: context),
        context: context,
      );
      final expression = buildFormParameterExpression(
        refer('value'),
        model,
        explode: refer('explode'),
        allowEmpty: refer('allowEmpty'),
      );

      final generated = format('final result = ${expression.accept(emitter)};');
      const expected = '''
        final result = value.map((e) => e.toForm(explode: explode, allowEmpty: allowEmpty)).toList().toForm(explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });

    test('generates map and toForm call for List<Enum>', () {
      final enumModel = EnumModel(
        isDeprecated: false,
        name: 'Status',
        values: const {'active', 'inactive'},
        isNullable: false,
        context: context,
        description: null,
      );
      final model = ListModel(
        content: enumModel,
        context: context,
      );
      final expression = buildFormParameterExpression(
        refer('value'),
        model,
        explode: refer('explode'),
        allowEmpty: refer('allowEmpty'),
      );

      final generated = format('final result = ${expression.accept(emitter)};');
      const expected = '''
        final result = value.map((e) => e.toForm(explode: explode, allowEmpty: allowEmpty)).toList().toForm(explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });

    test('generates toForm call for List<Class>', () {
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
            description: null,
          ),
        ],
        context: context,
        description: null,
      );
      final model = ListModel(
        content: classModel,
        context: context,
      );
      final expression = buildFormParameterExpression(
        refer('value'),
        model,
        explode: refer('explode'),
        allowEmpty: refer('allowEmpty'),
      );

      final generated = format('final result = ${expression.accept(emitter)};');
      const expected = '''
        final result = value.toForm(explode: explode, allowEmpty: allowEmpty);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });

    test('generates toForm call for List<List<String>>', () {
      final innerList = ListModel(
        content: StringModel(context: context),
        context: context,
      );
      final model = ListModel(
        content: innerList,
        context: context,
      );
      final expression = buildFormParameterExpression(
        refer('value'),
        model,
        explode: refer('explode'),
        allowEmpty: refer('allowEmpty'),
      );

      final generated = format('final result = ${expression.accept(emitter)};');
      const expected = '''
        final result = value.toForm(explode: explode, allowEmpty: allowEmpty);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });

    test('generates toForm call for OneOfModel', () {
      final model = OneOfModel(
        isDeprecated: false,
        name: 'Choice',
        models: {
          (discriminatorValue: 'i', model: IntegerModel(context: context)),
          (discriminatorValue: 's', model: StringModel(context: context)),
        },
        discriminator: null,
        context: context,
        description: null,
      );
      final expression = buildFormParameterExpression(
        refer('value'),
        model,
        explode: refer('explode'),
        allowEmpty: refer('allowEmpty'),
      );

      final generated = format('final result = ${expression.accept(emitter)};');
      const expected = '''
        final result = value.toForm(explode: explode, allowEmpty: allowEmpty);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });

    test('generates toForm call for AliasModel wrapping StringModel', () {
      final model = AliasModel(
        name: 'MyString',
        model: StringModel(context: context),
        context: context,
      );
      final expression = buildFormParameterExpression(
        refer('value'),
        model,
        explode: refer('explode'),
        allowEmpty: refer('allowEmpty'),
      );

      final generated = format('final result = ${expression.accept(emitter)};');
      const expected = '''
        final result = value.toForm(explode: explode, allowEmpty: allowEmpty);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });

    test('generates map and toForm call for List<OneOf>', () {
      final oneOfModel = OneOfModel(
        isDeprecated: false,
        name: 'Choice',
        models: {
          (discriminatorValue: 'i', model: IntegerModel(context: context)),
          (discriminatorValue: 's', model: StringModel(context: context)),
        },
        discriminator: null,
        context: context,
        description: null,
      );
      final model = ListModel(
        content: oneOfModel,
        context: context,
      );
      final expression = buildFormParameterExpression(
        refer('value'),
        model,
        explode: refer('explode'),
        allowEmpty: refer('allowEmpty'),
      );

      final generated = format('final result = ${expression.accept(emitter)};');
      const expected = '''
        final result = value.map((e) => e.toForm(explode: explode, allowEmpty: allowEmpty)).toList().toForm(explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });
  });
}
