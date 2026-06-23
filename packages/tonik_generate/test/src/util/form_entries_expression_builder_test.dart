import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/core_prefixed_allocator.dart';
import 'package:tonik_generate/src/util/form_entries_expression_builder.dart';

void main() {
  late Context context;
  late DartEmitter emitter;

  final format = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  ).format;

  setUp(() {
    context = Context.initial();
    emitter = DartEmitter(
      useNullSafetySyntax: true,
      allocator: CorePrefixedAllocator(),
    );
  });

  String bodyOf(Expression expression) {
    final method = Method(
      (b) => b
        ..name = 'test'
        ..body = expression.statement,
    );
    return format(method.accept(emitter).toString());
  }

  Expression build(
    Model model, {
    bool explode = true,
    bool useQueryComponent = false,
  }) {
    final result = buildFormEntriesValueExpression(
      refer('value'),
      model,
      paramName: literalString('p'),
      explode: literalBool(explode),
      allowEmpty: literalBool(true),
      useQueryComponent: useQueryComponent,
    );
    expect(result, isNotNull);
    return result!;
  }

  group('buildFormEntriesValueExpression', () {
    test('scalar threads paramName, explode and allowEmpty to toForm', () {
      final result = build(StringModel(context: context));

      final expected = format('''
        test() {
          value.toForm('p', explode: true, allowEmpty: true);
        }
      ''');

      expect(collapseWhitespace(bodyOf(result)), collapseWhitespace(expected));
    });

    test('scalar adds useQueryComponent when requested', () {
      final result = build(
        StringModel(context: context),
        useQueryComponent: true,
      );

      final expected = format('''
        test() {
          value.toForm('p', explode: true, allowEmpty: true, useQueryComponent: true);
        }
      ''');

      expect(collapseWhitespace(bodyOf(result)), collapseWhitespace(expected));
    });

    test('ClassModel with explode true delegates to toForm', () {
      final model = ClassModel(
        name: 'Form',
        isDeprecated: false,
        properties: const [],
        context: context,
        examples: const [],
      );

      final result = build(model);

      final expected = format('''
        test() {
          value.toForm('p', explode: true, allowEmpty: true);
        }
      ''');

      expect(collapseWhitespace(bodyOf(result)), collapseWhitespace(expected));
    });

    test('ClassModel with explode false delegates to toForm', () {
      final model = ClassModel(
        name: 'Form',
        isDeprecated: false,
        properties: const [],
        context: context,
        examples: const [],
      );

      final result = build(model, explode: false);

      final expected = format('''
        test() {
          value.toForm('p', explode: false, allowEmpty: true);
        }
      ''');

      expect(collapseWhitespace(bodyOf(result)), collapseWhitespace(expected));
    });

    test('Base64Model maps through toBase64String before toForm', () {
      final result = build(Base64Model(context: context));

      final expected = format('''
        test() {
          value.toBase64String().toForm('p', explode: true, allowEmpty: true);
        }
      ''');

      expect(collapseWhitespace(bodyOf(result)), collapseWhitespace(expected));
    });

    test('MapModel with string values encodes the receiver directly', () {
      final model = MapModel(
        valueModel: StringModel(context: context),
        context: context,
        examples: const [],
      );

      final result = build(model);

      final expected = format('''
        test() {
          value.toForm('p', explode: true, allowEmpty: true);
        }
      ''');

      expect(collapseWhitespace(bodyOf(result)), collapseWhitespace(expected));
    });

    test('MapModel with int values converts values with toString', () {
      final model = MapModel(
        valueModel: IntegerModel(context: context),
        context: context,
        examples: const [],
      );

      final result = build(model);

      final expected = format('''
        test() {
          value
              .map((k, v) => _i1.MapEntry(k, v.toString()))
              .toForm('p', explode: true, allowEmpty: true);
        }
      ''');

      expect(collapseWhitespace(bodyOf(result)), collapseWhitespace(expected));
    });

    test('MapModel with complex value type returns null', () {
      final model = MapModel(
        valueModel: ListModel(
          content: StringModel(context: context),
          context: context,
          examples: const [],
        ),
        context: context,
        examples: const [],
      );

      final result = buildFormEntriesValueExpression(
        refer('value'),
        model,
        paramName: literalString('p'),
        explode: literalBool(true),
        allowEmpty: literalBool(true),
      );

      expect(result, isNull);
    });

    test('ListModel with simple string content encodes the receiver', () {
      final model = ListModel(
        content: StringModel(context: context),
        context: context,
        examples: const [],
      );

      final result = build(model);

      final expected = format('''
        test() {
          value.toForm('p', explode: true, allowEmpty: true);
        }
      ''');

      expect(collapseWhitespace(bodyOf(result)), collapseWhitespace(expected));
    });

    test('ListModel with AnyModel content uri-encodes each element', () {
      final model = ListModel(
        content: AnyModel(context: context),
        context: context,
        examples: const [],
      );

      final result = build(model, useQueryComponent: true);

      final expected = format('''
        test() {
          value
              .map(
                (e) => _i1.encodeAnyToUri(
                  e,
                  allowEmpty: true,
                  useQueryComponent: true,
                ),
              )
              .toList()
              .toForm(
                'p',
                explode: true,
                allowEmpty: true,
                useQueryComponent: true,
                alreadyEncoded: true,
              );
        }
      ''');

      expect(collapseWhitespace(bodyOf(result)), collapseWhitespace(expected));
    });

    test('ListModel with nullable content guards each element', () {
      final model = ListModel(
        content: AliasModel(
          name: 'NullableString',
          model: StringModel(context: context),
          isNullable: true,
          context: context,
          examples: const [],
          defaultValue: null,
        ),
        context: context,
        examples: const [],
      );

      final result = build(model);

      final expected = format('''
        test() {
          value
              .map((e) => e == null ? '' : e.uriEncode(allowEmpty: true))
              .toList()
              .toForm('p', explode: true, allowEmpty: true, alreadyEncoded: true);
        }
      ''');

      expect(collapseWhitespace(bodyOf(result)), collapseWhitespace(expected));
    });

    test('ListModel with Base64 content maps each through toBase64String', () {
      final model = ListModel(
        content: Base64Model(context: context),
        context: context,
        examples: const [],
      );

      final result = build(model);

      final expected = format('''
        test() {
          value
              .map((e) => e.toBase64String())
              .toList()
              .toForm('p', explode: true, allowEmpty: true);
        }
      ''');

      expect(collapseWhitespace(bodyOf(result)), collapseWhitespace(expected));
    });

    test('AnyModel returns null so callers render a single string entry', () {
      final result = buildFormEntriesValueExpression(
        refer('value'),
        AnyModel(context: context),
        paramName: literalString('p'),
        explode: literalBool(true),
        allowEmpty: literalBool(true),
      );

      expect(result, isNull);
    });

    test('NeverModel returns null', () {
      final result = buildFormEntriesValueExpression(
        refer('value'),
        NeverModel(context: context),
        paramName: literalString('p'),
        explode: literalBool(true),
        allowEmpty: literalBool(true),
      );

      expect(result, isNull);
    });

    test('BinaryModel returns null', () {
      final result = buildFormEntriesValueExpression(
        refer('value'),
        BinaryModel(context: context),
        paramName: literalString('p'),
        explode: literalBool(true),
        allowEmpty: literalBool(true),
      );

      expect(result, isNull);
    });
  });
}
