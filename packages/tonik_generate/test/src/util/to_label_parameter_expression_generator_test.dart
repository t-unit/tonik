import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/core_prefixed_allocator.dart';
import 'package:tonik_generate/src/util/to_label_parameter_expression_generator.dart';

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
        isDeprecated: false,
        name: 'Status',
        values: {
          const EnumEntry(value: 'active'),
          const EnumEntry(value: 'inactive'),
        },
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
        isDeprecated: false,
        name: 'Choice',
        models: {
          (discriminatorValue: 'i', model: IntegerModel(context: context)),
          (discriminatorValue: 's', model: StringModel(context: context)),
        },
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
      final expression = buildLabelParameterExpression(
        refer('value'),
        model,
        explode: refer('explode'),
        allowEmpty: refer('allowEmpty'),
      );

      final generated = format('final result = ${expression.accept(emitter)};');
      const expected = '''
        final result = value.map((e) => encodeAnyToUri(e, allowEmpty: allowEmpty)).toList().toLabel(explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });

    test('generates encodeAnyToLabel call for AnyModel', () {
      final model = AnyModel(context: context);
      final expression = buildLabelParameterExpression(
        refer('value'),
        model,
        explode: refer('explode'),
        allowEmpty: refer('allowEmpty'),
      );

      final generated = format('final result = ${expression.accept(emitter)};');
      const expected = '''
        final result = encodeAnyToLabel(value, explode: explode, allowEmpty: allowEmpty);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });

    test('generates toParameterMap().toLabel() for MapModel', () {
      final model = MapModel(
        valueModel: IntegerModel(context: context),
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
        final result = value.toParameterMap().toLabel(explode: explode, allowEmpty: allowEmpty);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });

    test('generates toBase64String().toLabel() for Base64Model', () {
      final model = Base64Model(context: context);
      final expression = buildLabelParameterExpression(
        refer('value'),
        model,
        explode: refer('explode'),
        allowEmpty: refer('allowEmpty'),
      );

      final generated = format('final result = ${expression.accept(emitter)};');
      const expected = '''
        final result = value.toBase64String().toLabel(explode: explode, allowEmpty: allowEmpty);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });

    test('generates map and toLabel for List<MapModel>', () {
      final model = ListModel(
        content: MapModel(
          valueModel: IntegerModel(context: context),
          context: context,
        ),
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
        final result = value.map((e) => e.toParameterMap().uriEncode(allowEmpty: allowEmpty)).toList().toLabel(explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });

    test('generates map and toLabel for List<Base64Model>', () {
      final model = ListModel(
        content: Base64Model(context: context),
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
        final result = value.map((e) => e.toBase64String().uriEncode(allowEmpty: allowEmpty)).toList().toLabel(explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });

    test('generates runtime throw for BinaryModel', () {
      final model = BinaryModel(context: context);
      final expression = buildLabelParameterExpression(
        refer('value'),
        model,
        explode: refer('explode'),
        allowEmpty: refer('allowEmpty'),
      );

      expect(
        expression.accept(scopedEmitter).toString(),
        '''throw  _i1.EncodingException('Binary data cannot be label-encoded')''',
      );
    });

    test('generates runtime throw for NeverModel', () {
      final model = NeverModel(context: context);
      final expression = buildLabelParameterExpression(
        refer('value'),
        model,
        explode: refer('explode'),
        allowEmpty: refer('allowEmpty'),
      );

      expect(
        expression.accept(scopedEmitter).toString(),
        '''throw  _i1.EncodingException('Unsupported model type for label encoding.')''',
      );
    });

    test('generates runtime throw for List with NeverModel content', () {
      final model = ListModel(
        content: NeverModel(context: context),
        context: context,
      );
      final expression = buildLabelParameterExpression(
        refer('value'),
        model,
        explode: refer('explode'),
        allowEmpty: refer('allowEmpty'),
      );

      expect(
        expression.accept(scopedEmitter).toString(),
        '''throw  _i1.EncodingException('Unsupported list content type for label encoding.')''',
      );
    });
  });

  group('nullable receiver support', () {
    test('generates null-safe toLabel for StringModel when isNullable', () {
      final model = StringModel(context: context);
      final expression = buildLabelParameterExpression(
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
            value?.toLabel(explode: explode, allowEmpty: allowEmpty);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });

    test('generates null-safe toLabel for ClassModel when isNullable', () {
      final model = ClassModel(
        name: 'MyClass',
        properties: [],
        isDeprecated: false,
        context: context,
      );
      final expression = buildLabelParameterExpression(
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
            value?.toLabel(explode: explode, allowEmpty: allowEmpty);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });

    test('generates null-safe toLabel for ListModel when isNullable', () {
      final model = ListModel(
        content: StringModel(context: context),
        context: context,
      );
      final expression = buildLabelParameterExpression(
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
            value?.toLabel(explode: explode, allowEmpty: allowEmpty);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });

    test('uses null-safe access for AliasModel when isNullable', () {
      final model = AliasModel(
        name: 'MyAlias',
        model: StringModel(context: context),
        context: context,
        isNullable: true,
      );
      final expression = buildLabelParameterExpression(
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
            value?.toLabel(explode: explode, allowEmpty: allowEmpty);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });

    test('does not use null-safe when isNullable is false', () {
      final model = StringModel(context: context);
      final expression = buildLabelParameterExpression(
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
            value.toLabel(explode: explode, allowEmpty: allowEmpty);
      ''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(format(expected)),
      );
    });
  });
}
