import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/core_prefixed_allocator.dart';
import 'package:tonik_generate/src/util/form_entries_expression_builder.dart';
import 'package:tonik_generate/src/util/uri_encode_expression_generator.dart';

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
    bool allowReserved = false,
  }) {
    final result = buildFormEntriesValueExpression(
      refer('value'),
      model,
      paramName: literalString('p'),
      explode: literalBool(explode),
      allowEmpty: literalBool(true),
      useQueryComponent: useQueryComponent ? literalBool(true) : null,
      allowReserved: allowReserved,
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

    test('scalar adds allowReserved when set', () {
      final result = build(
        StringModel(context: context),
        allowReserved: true,
      );

      final expected = format('''
        test() {
          value.toForm('p', explode: true, allowEmpty: true, allowReserved: true);
        }
      ''');

      expect(collapseWhitespace(bodyOf(result)), collapseWhitespace(expected));
    });

    test('Base64Model adds allowReserved on the base64 string when set', () {
      final result = build(
        Base64Model(context: context),
        allowReserved: true,
      );

      final expected = format('''
        test() {
          value.toBase64String().toForm(
            'p',
            explode: true,
            allowEmpty: true,
            allowReserved: true,
          );
        }
      ''');

      expect(collapseWhitespace(bodyOf(result)), collapseWhitespace(expected));
    });

    test('AliasModel threads allowReserved to its target', () {
      final result = build(
        AliasModel(
          name: 'Filter',
          model: StringModel(context: context),
          context: context,
          examples: const [],
          defaultValue: null,
        ),
        allowReserved: true,
      );

      final expected = format('''
        test() {
          value.toForm('p', explode: true, allowEmpty: true, allowReserved: true);
        }
      ''');

      expect(collapseWhitespace(bodyOf(result)), collapseWhitespace(expected));
    });

    test('enum form param omits allowReserved even when set', () {
      final result = build(
        EnumModel<String>(
          name: 'Color',
          values: {
            const EnumEntry<String>(value: 'red'),
            const EnumEntry<String>(value: 'green'),
          },
          isNullable: false,
          isDeprecated: false,
          examples: const [],
          context: context,
        ),
        allowReserved: true,
      );

      final expected = format('''
        test() {
          value.toForm('p', explode: true, allowEmpty: true);
        }
      ''');

      expect(collapseWhitespace(bodyOf(result)), collapseWhitespace(expected));
    });

    test('object form param omits allowReserved even when set', () {
      final result = build(
        ClassModel(
          name: 'Form',
          isDeprecated: false,
          properties: const [],
          context: context,
          examples: const [],
        ),
        allowReserved: true,
      );

      final expected = format('''
        test() {
          value.toForm('p', explode: true, allowEmpty: true);
        }
      ''');

      expect(collapseWhitespace(bodyOf(result)), collapseWhitespace(expected));
    });

    test('composite form param omits allowReserved even when set', () {
      final result = build(
        OneOfModel(
          models: const {},
          isDeprecated: false,
          examples: const [],
          context: context,
        ),
        allowReserved: true,
      );

      final expected = format('''
        test() {
          value.toForm('p', explode: true, allowEmpty: true);
        }
      ''');

      expect(collapseWhitespace(bodyOf(result)), collapseWhitespace(expected));
    });

    test('list element uriEncode adds allowReserved when set', () {
      final result = build(
        ListModel(
          content: IntegerModel(context: context),
          context: context,
          examples: const [],
        ),
        allowReserved: true,
      );

      final expected = format('''
        test() {
          value
              .map((e) => e.uriEncode(allowEmpty: true, allowReserved: true))
              .toList()
              .toForm('p', explode: true, allowEmpty: true, alreadyEncoded: true);
        }
      ''');

      expect(collapseWhitespace(bodyOf(result)), collapseWhitespace(expected));
    });

    test('enum list element omits allowReserved even when set', () {
      final result = build(
        ListModel(
          content: EnumModel<String>(
            name: 'Color',
            values: {
              const EnumEntry<String>(value: 'red'),
              const EnumEntry<String>(value: 'green'),
            },
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            context: context,
          ),
          context: context,
          examples: const [],
        ),
        allowReserved: true,
      );

      final expected = format('''
        test() {
          value
              .map((e) => e.uriEncode(allowEmpty: true))
              .toList()
              .toForm('p', explode: true, allowEmpty: true, alreadyEncoded: true);
        }
      ''');

      expect(collapseWhitespace(bodyOf(result)), collapseWhitespace(expected));
    });

    test('free-form list element omits allowReserved even when set', () {
      final result = build(
        ListModel(
          content: AnyModel(context: context),
          context: context,
          examples: const [],
        ),
        allowReserved: true,
      );

      final expected = format('''
        test() {
          value
              .map((e) => _i1.encodeAnyToUri(e, allowEmpty: true))
              .toList()
              .toForm('p', explode: true, allowEmpty: true, alreadyEncoded: true);
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

    test('MapModel with string values threads allowReserved when set', () {
      final model = MapModel(
        valueModel: StringModel(context: context),
        context: context,
        examples: const [],
      );

      final result = build(model, allowReserved: true);

      final expected = format('''
        test() {
          value.toForm('p', explode: true, allowEmpty: true, allowReserved: true);
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

    test('ListModel with non-nullable string content threads allowReserved '
        'on the fast path when set', () {
      final model = ListModel(
        content: StringModel(context: context),
        context: context,
        examples: const [],
      );

      final result = build(model, allowReserved: true);

      final expected = format('''
        test() {
          value.toForm('p', explode: true, allowEmpty: true, allowReserved: true);
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

    test('ListModel with Base64 content threads allowReserved on the fast '
        'path when set', () {
      final model = ListModel(
        content: Base64Model(context: context),
        context: context,
        examples: const [],
      );

      final result = build(model, allowReserved: true);

      final expected = format('''
        test() {
          value
              .map((e) => e.toBase64String())
              .toList()
              .toForm(
                'p',
                explode: true,
                allowEmpty: true,
                allowReserved: true,
              );
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

  group('isUriEncodableElement drift guard', () {
    bool encodesToSingleValue(Model model) {
      final expression = buildUriEncodeExpression(
        refer('e'),
        model,
        allowEmpty: literalBool(true),
      ).expression;
      final body = collapseWhitespace(bodyOf(expression));
      return !body.contains('EncodingException') && !body.contains('.map(');
    }

    // Enumerates every concrete Model subtype so the two switch statements
    // cannot drift apart.
    List<Model> allConcreteModels() => <Model>[
      StringModel(context: context),
      BooleanModel(context: context),
      DateTimeModel(context: context),
      DecimalModel(context: context),
      UriModel(context: context),
      DateModel(context: context),
      IntegerModel(context: context),
      DoubleModel(context: context),
      NumberModel(context: context),
      Base64Model(context: context),
      BinaryModel(context: context),
      AnyModel(context: context),
      NeverModel(context: context),
      EnumModel<String>(
        values: const {},
        isNullable: false,
        context: context,
        isDeprecated: false,
        examples: const [],
      ),
      AnyOfModel(
        models: const {},
        context: context,
        isDeprecated: false,
        examples: const [],
      ),
      OneOfModel(
        models: const {},
        context: context,
        isDeprecated: false,
        examples: const [],
      ),
      AllOfModel(
        models: const {},
        context: context,
        isDeprecated: false,
        examples: const [],
      ),
      MapModel(
        valueModel: StringModel(context: context),
        context: context,
        examples: const [],
      ),
      ListModel(
        content: StringModel(context: context),
        context: context,
        examples: const [],
      ),
      ClassModel(
        name: 'Form',
        isDeprecated: false,
        properties: const [],
        context: context,
        examples: const [],
      ),
      AliasModel(
        name: 'AliasString',
        model: StringModel(context: context),
        context: context,
        examples: const [],
        defaultValue: null,
      ),
    ];

    test(
      'every element classified encodable uri-encodes to a single value',
      () {
        for (final model in allConcreteModels()) {
          if (!isUriEncodableElement(model)) continue;
          expect(
            encodesToSingleValue(model),
            isTrue,
            reason:
                '${model.runtimeType} is element-encodable but does not '
                'uri-encode to a single value',
          );
        }
      },
    );

    test(
      'every scalar arm of buildUriEncodeExpression is element-encodable',
      () {
        // Collections and BinaryModel single-value encode but are deliberately
        // not element-encodable.
        const nonElementTypes = [MapModel, ListModel, BinaryModel];
        for (final model in allConcreteModels()) {
          if (nonElementTypes.contains(model.runtimeType)) continue;
          if (!encodesToSingleValue(model)) continue;
          expect(
            isUriEncodableElement(model),
            isTrue,
            reason:
                '${model.runtimeType} uri-encodes to a single value but is '
                'not classified as element-encodable',
          );
        }
      },
    );

    test('AliasModel inherits the classification of its target', () {
      final encodable = AliasModel(
        name: 'AliasString',
        model: StringModel(context: context),
        context: context,
        examples: const [],
        defaultValue: null,
      );
      final nonEncodable = AliasModel(
        name: 'AliasMap',
        model: MapModel(
          valueModel: StringModel(context: context),
          context: context,
          examples: const [],
        ),
        context: context,
        examples: const [],
        defaultValue: null,
      );

      expect(isUriEncodableElement(encodable), isTrue);
      expect(isUriEncodableElement(nonEncodable), isFalse);
    });

    test('complex elements are not element-encodable', () {
      final complex = <Model>[
        MapModel(
          valueModel: StringModel(context: context),
          context: context,
          examples: const [],
        ),
        ListModel(
          content: StringModel(context: context),
          context: context,
          examples: const [],
        ),
        ClassModel(
          name: 'Form',
          isDeprecated: false,
          properties: const [],
          context: context,
          examples: const [],
        ),
        NeverModel(context: context),
      ];

      for (final model in complex) {
        expect(isUriEncodableElement(model), isFalse);
      }
    });

    test('BinaryModel is single-value uri-encodable but rejected as a '
        'form element', () {
      final model = BinaryModel(context: context);

      expect(encodesToSingleValue(model), isTrue);
      expect(isUriEncodableElement(model), isFalse);
    });
  });
}
