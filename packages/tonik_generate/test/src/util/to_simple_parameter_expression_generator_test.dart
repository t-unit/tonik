import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/to_simple_parameter_expression_generator.dart';

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
        name: 'Status',
        values: const {'active', 'inactive'},
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
        name: 'Status',
        values: const {'active', 'inactive'},
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
        name: 'Choice',
        models: {
          (discriminatorValue: 'i', model: IntegerModel(context: context)),
          (discriminatorValue: 's', model: StringModel(context: context)),
        },
        discriminator: null,
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
  });
}
