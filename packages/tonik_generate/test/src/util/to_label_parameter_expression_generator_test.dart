import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/to_label_parameter_expression_generator.dart';

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

  group('buildLabelParameterExpression', () {
    test('generates toLabel call for StringModel', () {
      final model = StringModel(context: context);
      final expression = buildLabelParameterExpression(
        refer('value'),
        model,
        explode: refer('explode'),
        allowEmpty: refer('allowEmpty'),
      );

      final generated = format('final result = ${expression.accept(emitter)};');
      const expected = '''
        final result = value.toLabel(explode: explode, allowEmpty: allowEmpty);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });

    test('generates toLabel call for IntegerModel', () {
      final model = IntegerModel(context: context);
      final expression = buildLabelParameterExpression(
        refer('value'),
        model,
        explode: refer('explode'),
        allowEmpty: refer('allowEmpty'),
      );

      final generated = format('final result = ${expression.accept(emitter)};');
      const expected = '''
        final result = value.toLabel(explode: explode, allowEmpty: allowEmpty);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });

    test('generates toLabel call for BooleanModel', () {
      final model = BooleanModel(context: context);
      final expression = buildLabelParameterExpression(
        refer('value'),
        model,
        explode: refer('explode'),
        allowEmpty: refer('allowEmpty'),
      );

      final generated = format('final result = ${expression.accept(emitter)};');
      const expected = '''
        final result = value.toLabel(explode: explode, allowEmpty: allowEmpty);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });

    test('generates toLabel call for DateTimeModel', () {
      final model = DateTimeModel(context: context);
      final expression = buildLabelParameterExpression(
        refer('value'),
        model,
        explode: refer('explode'),
        allowEmpty: refer('allowEmpty'),
      );

      final generated = format('final result = ${expression.accept(emitter)};');
      const expected = '''
        final result = value.toLabel(explode: explode, allowEmpty: allowEmpty);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });

    test('generates toLabel call for EnumModel', () {
      final model = EnumModel(
        name: 'Status',
        values: const {'active', 'inactive'},
        isNullable: false,
        context: context,
      );
      final expression = buildLabelParameterExpression(
        refer('value'),
        model,
        explode: refer('explode'),
        allowEmpty: refer('allowEmpty'),
      );

      final generated = format('final result = ${expression.accept(emitter)};');
      const expected = '''
        final result = value.toLabel(explode: explode, allowEmpty: allowEmpty);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });

    test('generates toLabel call for ClassModel', () {
      final model = ClassModel(
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
      final expression = buildLabelParameterExpression(
        refer('value'),
        model,
        explode: refer('explode'),
        allowEmpty: refer('allowEmpty'),
      );

      final generated = format('final result = ${expression.accept(emitter)};');
      const expected = '''
        final result = value.toLabel(explode: explode, allowEmpty: allowEmpty);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });

    test('generates toLabel call for List<String>', () {
      final model = ListModel(
        content: StringModel(context: context),
        context: context,
      );
      final expression = buildLabelParameterExpression(
        refer('value'),
        model,
        explode: refer('explode'),
        allowEmpty: refer('allowEmpty'),
      );

      final generated = format('final result = ${expression.accept(emitter)};');
      const expected = '''
        final result = value.toLabel(explode: explode, allowEmpty: allowEmpty);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });

    test('generates map and toLabel call for List<int>', () {
      final model = ListModel(
        content: IntegerModel(context: context),
        context: context,
      );
      final expression = buildLabelParameterExpression(
        refer('value'),
        model,
        explode: refer('explode'),
        allowEmpty: refer('allowEmpty'),
      );

      final generated = format('final result = ${expression.accept(emitter)};');
      const expected = '''
        final result = value.map((e) => e.uriEncode(allowEmpty: allowEmpty)).toList().toLabel(explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });

    test('generates map and toLabel call for List<Enum>', () {
      final enumModel = EnumModel(
        name: 'Status',
        values: const {'active', 'inactive'},
        isNullable: false,
        context: context,
      );
      final model = ListModel(
        content: enumModel,
        context: context,
      );
      final expression = buildLabelParameterExpression(
        refer('value'),
        model,
        explode: refer('explode'),
        allowEmpty: refer('allowEmpty'),
      );

      final generated = format('final result = ${expression.accept(emitter)};');
      const expected = '''
        final result = value.map((e) => e.uriEncode(allowEmpty: allowEmpty)).toList().toLabel(explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });

    test('generates toLabel call for List<Class>', () {
      final classModel = ClassModel(
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
      final expression = buildLabelParameterExpression(
        refer('value'),
        model,
        explode: refer('explode'),
        allowEmpty: refer('allowEmpty'),
      );

      final generated = format('final result = ${expression.accept(emitter)};');
      const expected = '''
        final result = value.toLabel(explode: explode, allowEmpty: allowEmpty);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });

    test('generates toLabel call for List<List<String>>', () {
      final innerList = ListModel(
        content: StringModel(context: context),
        context: context,
      );
      final model = ListModel(
        content: innerList,
        context: context,
      );
      final expression = buildLabelParameterExpression(
        refer('value'),
        model,
        explode: refer('explode'),
        allowEmpty: refer('allowEmpty'),
      );

      final generated = format('final result = ${expression.accept(emitter)};');
      const expected = '''
        final result = value.toLabel(explode: explode, allowEmpty: allowEmpty);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });

    test('generates toLabel call for OneOfModel', () {
      final model = OneOfModel(
        name: 'Choice',
        models: {
          (discriminatorValue: 'i', model: IntegerModel(context: context)),
          (discriminatorValue: 's', model: StringModel(context: context)),
        },
        discriminator: null,
        context: context,
      );
      final expression = buildLabelParameterExpression(
        refer('value'),
        model,
        explode: refer('explode'),
        allowEmpty: refer('allowEmpty'),
      );

      final generated = format('final result = ${expression.accept(emitter)};');
      const expected = '''
        final result = value.toLabel(explode: explode, allowEmpty: allowEmpty);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });

    test('generates toLabel call for AliasModel wrapping StringModel', () {
      final model = AliasModel(
        name: 'MyString',
        model: StringModel(context: context),
        context: context,
      );
      final expression = buildLabelParameterExpression(
        refer('value'),
        model,
        explode: refer('explode'),
        allowEmpty: refer('allowEmpty'),
      );

      final generated = format('final result = ${expression.accept(emitter)};');
      const expected = '''
        final result = value.toLabel(explode: explode, allowEmpty: allowEmpty);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });

    test('generates map and toLabel call for List<OneOf>', () {
      final oneOfModel = OneOfModel(
        name: 'Choice',
        models: {
          (discriminatorValue: 'i', model: IntegerModel(context: context)),
          (discriminatorValue: 's', model: StringModel(context: context)),
        },
        discriminator: null,
        context: context,
      );
      final model = ListModel(
        content: oneOfModel,
        context: context,
      );
      final expression = buildLabelParameterExpression(
        refer('value'),
        model,
        explode: refer('explode'),
        allowEmpty: refer('allowEmpty'),
      );

      final generated = format('final result = ${expression.accept(emitter)};');
      const expected = '''
        final result = value.map((e) => e.uriEncode(allowEmpty: allowEmpty)).toList().toLabel(explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });
  });
}
