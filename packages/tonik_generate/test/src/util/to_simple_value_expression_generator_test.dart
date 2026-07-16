import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/built_expression.dart';
import 'package:tonik_generate/src/util/core_prefixed_allocator.dart';
import 'package:tonik_generate/src/util/to_simple_value_expression_generator.dart';

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

  String emit(BuiltExpression built) =>
      built.expression.accept(emitter).toString();

  String methodBody(BuiltExpression built) {
    final method = Method(
      (b) => b
        ..name = 'test'
        ..body = declareFinal('result').assign(built.expression).statement,
    );
    return format(method.accept(emitter).toString());
  }

  group('buildToSimplePathParameterExpression', () {
    test('for String parameter', () {
      final parameter = PathParameterObject(
        name: 'userId',
        rawName: 'userId',
        description: 'User ID parameter',
        model: StringModel(context: context),
        encoding: PathParameterEncoding.simple,
        explode: false,
        allowEmptyValue: false,
        isRequired: true,
        isDeprecated: false,
        context: context,
        examples: const [],
        defaultValue: null,
      );
      expect(
        emit(buildToSimplePathParameterExpression('userId', parameter)),
        'userId.toSimple(explode: false, allowEmpty: true, )',
      );
    });

    test('for Integer parameter with custom params', () {
      final parameter = PathParameterObject(
        name: 'id',
        rawName: 'id',
        description: 'ID parameter',
        model: IntegerModel(context: context),
        encoding: PathParameterEncoding.simple,
        explode: false,
        allowEmptyValue: false,
        isRequired: true,
        isDeprecated: false,
        context: context,
        examples: const [],
        defaultValue: null,
      );
      expect(
        emit(
          buildToSimplePathParameterExpression(
            'id',
            parameter,
            explode: true,
            allowEmpty: false,
          ),
        ),
        'id.toSimple(explode: true, allowEmpty: false, )',
      );
    });

    test('for DateTime parameter', () {
      final parameter = PathParameterObject(
        name: 'timestamp',
        rawName: 'timestamp',
        description: 'Timestamp parameter',
        model: DateTimeModel(context: context),
        encoding: PathParameterEncoding.simple,
        explode: false,
        allowEmptyValue: false,
        isRequired: true,
        isDeprecated: false,
        context: context,
        examples: const [],
        defaultValue: null,
      );
      expect(
        emit(buildToSimplePathParameterExpression('timestamp', parameter)),
        'timestamp.toSimple(explode: false, allowEmpty: true, )',
      );
    });

    test('for integer list parameter omits literal arg', () {
      final parameter = PathParameterObject(
        name: 'ids',
        rawName: 'ids',
        description: 'IDs parameter',
        model: ListModel(
          content: IntegerModel(context: context),
          context: context,
          examples: const [],
        ),
        encoding: PathParameterEncoding.simple,
        explode: false,
        allowEmptyValue: false,
        isRequired: true,
        isDeprecated: false,
        context: context,
        examples: const [],
        defaultValue: null,
      );
      expect(
        collapseWhitespace(
          methodBody(buildToSimplePathParameterExpression('ids', parameter)),
        ),
        collapseWhitespace(
          format('''
            test() {
              final result = ids
                  .map((e) => e.uriEncode(allowEmpty: true))
                  .toList()
                  .toSimple(explode: false, allowEmpty: true, alreadyEncoded: true);
            }
          '''),
        ),
      );
    });

    test('for NeverModel parameter throws EncodingException', () {
      final parameter = PathParameterObject(
        name: 'neverParam',
        rawName: 'neverParam',
        description: 'Never parameter',
        model: NeverModel(context: context, isNullable: false),
        encoding: PathParameterEncoding.simple,
        explode: false,
        allowEmptyValue: false,
        isRequired: true,
        isDeprecated: false,
        context: context,
        examples: const [],
        defaultValue: null,
      );
      expect(
        emit(buildToSimplePathParameterExpression('neverParam', parameter)),
        '''throw  EncodingException('Cannot encode NeverModel - this type does not permit any value.')''',
      );
    });
  });

  group('buildToSimpleHeaderParameterExpression', () {
    RequestHeaderObject header(Model model) => RequestHeaderObject(
      name: 'value',
      rawName: 'X-Value',
      description: 'header',
      model: model,
      encoding: HeaderParameterEncoding.simple,
      explode: false,
      allowEmptyValue: false,
      isRequired: true,
      isDeprecated: false,
      context: context,
      examples: const [],
      defaultValue: null,
    );

    for (final model in <Model>[
      StringModel(context: Context.initial()),
      IntegerModel(context: Context.initial()),
      DoubleModel(context: Context.initial()),
      NumberModel(context: Context.initial()),
      BooleanModel(context: Context.initial()),
      DateTimeModel(context: Context.initial()),
      DecimalModel(context: Context.initial()),
      UriModel(context: Context.initial()),
      DateModel(context: Context.initial()),
    ]) {
      test('primitive ${model.runtimeType} header emits literal: true', () {
        final built = buildToSimpleHeaderParameterExpression(
          'value',
          header(model),
        );
        expect(
          collapseWhitespace(methodBody(built)),
          collapseWhitespace(
            format('''
              test() {
                final result = value.toSimple(
                  explode: false,
                  allowEmpty: true,
                  literal: true,
                );
              }
            '''),
          ),
        );
      });
    }

    test('base64 header emits literal toSimple on base64 string', () {
      final built = buildToSimpleHeaderParameterExpression(
        'value',
        header(Base64Model(context: context)),
      );
      expect(
        collapseWhitespace(methodBody(built)),
        collapseWhitespace(
          format('''
            test() {
              final result = value.toBase64String().toSimple(
                explode: false,
                allowEmpty: true,
                literal: true,
              );
            }
          '''),
        ),
      );
    });

    test('string list header emits literal toSimple on the list', () {
      final built = buildToSimpleHeaderParameterExpression(
        'value',
        header(
          ListModel(
            content: StringModel(context: context),
            context: context,
            examples: const [],
          ),
        ),
      );
      expect(
        collapseWhitespace(methodBody(built)),
        collapseWhitespace(
          format('''
            test() {
              final result = value.toSimple(
                explode: false,
                allowEmpty: true,
                literal: true,
              );
            }
          '''),
        ),
      );
    });

    test(
      'integer list header emits literal on element encode and final toSimple',
      () {
        final built = buildToSimpleHeaderParameterExpression(
          'value',
          header(
            ListModel(
              content: IntegerModel(context: context),
              context: context,
              examples: const [],
            ),
          ),
        );
        expect(
          collapseWhitespace(methodBody(built)),
          collapseWhitespace(
            format('''
              test() {
                final result = value
                    .map((e) => e.uriEncode(allowEmpty: true, literal: true))
                    .toList()
                    .toSimple(
                      explode: false,
                      allowEmpty: true,
                      literal: true,
                      alreadyEncoded: true,
                    );
              }
            '''),
          ),
        );
      },
    );

    test('dateTime list header emits literal on element and list', () {
      final built = buildToSimpleHeaderParameterExpression(
        'value',
        header(
          ListModel(
            content: DateTimeModel(context: context),
            context: context,
            examples: const [],
          ),
        ),
      );
      expect(
        collapseWhitespace(methodBody(built)),
        collapseWhitespace(
          format('''
            test() {
              final result = value
                  .map(
                    (e) => e.toSimple(
                      explode: false,
                      allowEmpty: true,
                      literal: true,
                    ),
                  )
                  .toList()
                  .toSimple(explode: false, allowEmpty: true, literal: true);
            }
          '''),
        ),
      );
    });

    test('enum header emits literal toSimple', () {
      final model = EnumModel<String>(
        name: 'Status',
        values: {const EnumEntry(value: 'active')},
        isNullable: false,
        isDeprecated: false,
        context: context,
        examples: const [],
      );
      final built = buildToSimpleHeaderParameterExpression(
        'value',
        header(model),
      );
      expect(
        collapseWhitespace(methodBody(built)),
        collapseWhitespace(
          format('''
            test() {
              final result = value.toSimple(
                explode: false,
                allowEmpty: true,
                literal: true,
              );
            }
          '''),
        ),
      );
    });

    test('class header emits literal toSimple', () {
      final model = ClassModel(
        name: 'Point',
        properties: const [],
        context: context,
        isDeprecated: false,
        examples: const [],
      );
      final built = buildToSimpleHeaderParameterExpression(
        'value',
        header(model),
      );
      expect(
        collapseWhitespace(methodBody(built)),
        collapseWhitespace(
          format('''
            test() {
              final result = value.toSimple(
                explode: false,
                allowEmpty: true,
                literal: true,
              );
            }
          '''),
        ),
      );
    });

    test('alias header threads literal into the resolved model', () {
      final model = AliasModel(
        name: 'MyString',
        model: StringModel(context: context),
        context: context,
        examples: const [],
        defaultValue: null,
      );
      final built = buildToSimpleHeaderParameterExpression(
        'value',
        header(model),
      );
      expect(
        collapseWhitespace(methodBody(built)),
        collapseWhitespace(
          format('''
            test() {
              final result = value.toSimple(
                explode: false,
                allowEmpty: true,
                literal: true,
              );
            }
          '''),
        ),
      );
    });

    test('map header emits literal toSimple', () {
      final model = MapModel(
        valueModel: StringModel(context: context),
        context: context,
        examples: const [],
      );
      final built = buildToSimpleHeaderParameterExpression(
        'value',
        header(model),
      );
      expect(
        collapseWhitespace(methodBody(built)),
        collapseWhitespace(
          format('''
            test() {
              final result = value
                  .map((k, v) => MapEntry(k, PropertyValue.scalar(v)))
                  .toSimple(
                    explode: false,
                    allowEmpty: true,
                    literal: true,
                  );
            }
          '''),
        ),
      );
    });

    test('AnyModel header emits encodeAnyToSimple with literal: true', () {
      final built = buildToSimpleHeaderParameterExpression(
        'value',
        header(AnyModel(context: context)),
      );
      expect(
        collapseWhitespace(methodBody(built)),
        collapseWhitespace(
          format('''
            test() {
              final result = encodeAnyToSimple(
                value,
                explode: false,
                allowEmpty: true,
                literal: true,
              );
            }
          '''),
        ),
      );
    });

    test('enum list header emits literal on element and list', () {
      final model = EnumModel<String>(
        name: 'Status',
        values: {const EnumEntry(value: 'active')},
        isNullable: false,
        isDeprecated: false,
        context: context,
        examples: const [],
      );
      final built = buildToSimpleHeaderParameterExpression(
        'value',
        header(
          ListModel(content: model, context: context, examples: const []),
        ),
      );
      expect(
        collapseWhitespace(methodBody(built)),
        collapseWhitespace(
          format('''
            test() {
              final result = value
                  .map(
                    (e) => e.toSimple(
                      explode: false,
                      allowEmpty: true,
                      literal: true,
                    ),
                  )
                  .toList()
                  .toSimple(explode: false, allowEmpty: true, literal: true);
            }
          '''),
        ),
      );
    });

    test('for NeverModel header throws EncodingException', () {
      expect(
        emit(
          buildToSimpleHeaderParameterExpression(
            'neverHeader',
            header(NeverModel(context: context, isNullable: false)),
          ),
        ),
        '''throw  EncodingException('Cannot encode NeverModel - this type does not permit any value.')''',
      );
    });
  });

  group('buildSimpleValueExpression', () {
    test('serializes string model', () {
      final model = StringModel(context: context);
      expect(
        emit(
          buildSimpleValueExpression(
            refer('myParam'),
            model,
            explode: false,
            allowEmpty: true,
          ),
        ),
        'myParam.toSimple(explode: false, allowEmpty: true, )',
      );
    });

    test('serializes integer model', () {
      final model = IntegerModel(context: context);
      expect(
        emit(
          buildSimpleValueExpression(
            refer('count'),
            model,
            explode: false,
            allowEmpty: true,
          ),
        ),
        'count.toSimple(explode: false, allowEmpty: true, )',
      );
    });

    test('serializes boolean model', () {
      final model = BooleanModel(context: context);
      expect(
        emit(
          buildSimpleValueExpression(
            refer('flag'),
            model,
            explode: true,
            allowEmpty: false,
          ),
        ),
        'flag.toSimple(explode: true, allowEmpty: false, )',
      );
    });

    test('serializes enum model', () {
      final model = EnumModel<String>(
        name: 'Status',
        values: {
          const EnumEntry(value: 'active'),
          const EnumEntry(value: 'inactive'),
        },
        isNullable: false,
        isDeprecated: false,
        context: context,
        examples: const [],
      );
      expect(
        emit(
          buildSimpleValueExpression(
            refer('status'),
            model,
            explode: false,
            allowEmpty: true,
          ),
        ),
        'status.toSimple(explode: false, allowEmpty: true, )',
      );
    });

    test('serializes dateTime model', () {
      final model = DateTimeModel(context: context);
      expect(
        emit(
          buildSimpleValueExpression(
            refer('timestamp'),
            model,
            explode: false,
            allowEmpty: true,
          ),
        ),
        'timestamp.toSimple(explode: false, allowEmpty: true, )',
      );
    });

    test('serializes never model as exception', () {
      final model = NeverModel(context: context, isNullable: false);
      expect(
        emit(
          buildSimpleValueExpression(
            refer('neverParam'),
            model,
            explode: false,
            allowEmpty: true,
          ),
        ),
        '''throw  EncodingException('Cannot encode NeverModel - this type does not permit any value.')''',
      );
    });

    test('respects isNullable flag', () {
      final model = StringModel(context: context);
      expect(
        emit(
          buildSimpleValueExpression(
            refer('myParam'),
            model,
            explode: false,
            allowEmpty: true,
            isNullable: true,
          ),
        ),
        'myParam?.toSimple(explode: false, allowEmpty: true, )',
      );
    });

    test('serializes list of strings', () {
      final model = ListModel(
        content: StringModel(context: context),
        context: context,
        examples: const [],
      );
      expect(
        emit(
          buildSimpleValueExpression(
            refer('tags'),
            model,
            explode: false,
            allowEmpty: true,
          ),
        ),
        'tags.toSimple(explode: false, allowEmpty: true, )',
      );
    });

    test('serializes alias model by resolving underlying type', () {
      final underlying = IntegerModel(context: context);
      final model = AliasModel(
        name: 'MyInt',
        model: underlying,
        context: context,
        examples: const [],
        defaultValue: null,
      );
      expect(
        emit(
          buildSimpleValueExpression(
            refer('myInt'),
            model,
            explode: false,
            allowEmpty: true,
          ),
        ),
        'myInt.toSimple(explode: false, allowEmpty: true, )',
      );
    });

    group('unsupported model types generate runtime throws', () {
      test('nested ListModel generates runtime throw', () {
        final model = ListModel(
          content: ListModel(
            content: StringModel(context: context),
            context: context,
            examples: const [],
          ),
          context: context,
          examples: const [],
        );
        expect(
          buildSimpleValueExpression(
            refer('value'),
            model,
            explode: false,
            allowEmpty: true,
          ).accept(scopedEmitter).toString(),
          '''throw  _i1.EncodingException('Nested lists are not supported for simple encoding.')''',
        );
      });

      test('generates runtime throw for BinaryModel', () {
        expect(
          buildSimpleValueExpression(
            refer('value'),
            BinaryModel(context: context),
            explode: false,
            allowEmpty: true,
          ).accept(scopedEmitter).toString(),
          '''throw  _i1.EncodingException('Unsupported model type for simple encoding.')''',
        );
      });
    });

    group('AnyModel', () {
      test(
        'generates encodeAnyToSimple call with literal explode/allowEmpty',
        () {
          final model = AnyModel(context: context);
          final expression = buildSimpleValueExpression(
            refer('value'),
            model,
            explode: true,
            allowEmpty: false,
          );

          final generated = format(
            'final result = ${expression.accept(emitter)};',
          );
          const expected = '''
          final result = encodeAnyToSimple(value, explode: true, allowEmpty: false);
        ''';

          expect(
            collapseWhitespace(generated),
            collapseWhitespace(format(expected)),
          );
        },
      );

      test('passes through explode/allowEmpty unchanged when nullable', () {
        final model = AnyModel(context: context);
        final expression = buildSimpleValueExpression(
          refer('value'),
          model,
          explode: false,
          allowEmpty: true,
          isNullable: true,
        );

        final generated = format(
          'final result = ${expression.accept(emitter)};',
        );
        const expected = '''
          final result = encodeAnyToSimple(value, explode: false, allowEmpty: true);
        ''';

        expect(
          collapseWhitespace(generated),
          collapseWhitespace(format(expected)),
        );
      });
    });

    group('MapModel', () {
      test('generates toSimple for MapModel with StringModel values', () {
        final model = MapModel(
          valueModel: StringModel(context: context),
          context: context,
          examples: const [],
        );
        final expression = buildSimpleValueExpression(
          refer('value'),
          model,
          explode: false,
          allowEmpty: true,
        );

        final generated = methodBody(expression);
        const expected = '''
          test() {
            final result = value
                .map((k, v) => MapEntry(k, PropertyValue.scalar(v)))
                .toSimple(explode: false, allowEmpty: true);
          }
        ''';

        expect(
          collapseWhitespace(generated),
          collapseWhitespace(format(expected)),
        );
      });

      test(
        'generates map and toSimple for MapModel with IntegerModel values',
        () {
          final model = MapModel(
            valueModel: IntegerModel(context: context),
            context: context,
            examples: const [],
          );
          final expression = buildSimpleValueExpression(
            refer('value'),
            model,
            explode: false,
            allowEmpty: true,
          );

          final method = Method(
            (b) => b
              ..name = 'test'
              ..body = declareFinal(
                'result',
              ).assign(expression.expression).statement,
          );

          final generated = format(method.accept(emitter).toString());
          final expected = format('''
            test() {
              final result = value
                  .map(
                    (k, v) => MapEntry(k, PropertyValue.scalar(v.toString())),
                  )
                  .toSimple(explode: false, allowEmpty: true);
            }
          ''');

          expect(
            collapseWhitespace(generated),
            collapseWhitespace(expected),
          );
        },
      );

      test(
        'generates map and toSimple for MapModel with DateTimeModel values',
        () {
          final model = MapModel(
            valueModel: DateTimeModel(context: context),
            context: context,
            examples: const [],
          );
          final expression = buildSimpleValueExpression(
            refer('value'),
            model,
            explode: false,
            allowEmpty: true,
          );

          final method = Method(
            (b) => b
              ..name = 'test'
              ..body = declareFinal(
                'result',
              ).assign(expression.expression).statement,
          );

          final generated = format(method.accept(emitter).toString());
          final expected = format('''
            test() {
              final result = value
                  .map(
                    (k, v) => MapEntry(
                      k,
                      PropertyValue.scalar(v.toTimeZonedIso8601String()),
                    ),
                  )
                  .toSimple(explode: false, allowEmpty: true);
            }
          ''');

          expect(
            collapseWhitespace(generated),
            collapseWhitespace(expected),
          );
        },
      );

      test(
        'generates map and toSimple for MapModel with EnumModel values',
        () {
          final model = MapModel(
            valueModel: EnumModel<String>(
              isDeprecated: false,
              name: 'Status',
              values: {
                const EnumEntry(value: 'active'),
              },
              isNullable: false,
              context: context,
              examples: const [],
            ),
            context: context,
            examples: const [],
          );
          final expression = buildSimpleValueExpression(
            refer('value'),
            model,
            explode: false,
            allowEmpty: true,
          );

          final method = Method(
            (b) => b
              ..name = 'test'
              ..body = declareFinal(
                'result',
              ).assign(expression.expression).statement,
          );

          final generated = format(method.accept(emitter).toString());
          final expected = format('''
            test() {
              final result = value
                  .map(
                    (k, v) => MapEntry(k, PropertyValue.scalar(v.toJson())),
                  )
                  .toSimple(explode: false, allowEmpty: true);
            }
          ''');

          expect(
            collapseWhitespace(generated),
            collapseWhitespace(expected),
          );
        },
      );

      test(
        'generates runtime throw for MapModel with ClassModel values',
        () {
          final model = MapModel(
            valueModel: ClassModel(
              isDeprecated: false,
              name: 'User',
              properties: [],
              context: context,
              examples: const [],
            ),
            context: context,
            examples: const [],
          );
          final expression = buildSimpleValueExpression(
            refer('value'),
            model,
            explode: false,
            allowEmpty: true,
          );

          final method = Method(
            (b) => b
              ..name = 'test'
              ..body = declareFinal(
                'result',
              ).assign(expression.expression).statement,
          );

          final generated = format(method.accept(scopedEmitter).toString());
          final expected = format('''
            test() {
              final result = throw _i1.EncodingException(
                'Map with complex value types cannot be simple-encoded.',
              );
            }
          ''');

          expect(
            collapseWhitespace(generated),
            collapseWhitespace(expected),
          );
        },
      );

      test(
        'generates null-safe toSimple for nullable MapModel '
        'with StringModel values',
        () {
          final model = MapModel(
            valueModel: StringModel(context: context),
            context: context,
            examples: const [],
          );
          final expression = buildSimpleValueExpression(
            refer('value'),
            model,
            explode: false,
            allowEmpty: true,
            isNullable: true,
          );

          final generated = methodBody(expression);
          const expected = '''
            test() {
              final result = value == null
                  ? null
                  : value
                      .map((k, v) => MapEntry(k, PropertyValue.scalar(v)))
                      ?.toSimple(explode: false, allowEmpty: true);
            }
          ''';

          expect(
            collapseWhitespace(generated),
            collapseWhitespace(format(expected)),
          );
        },
      );
    });

    group('Base64Model', () {
      test('generates toBase64String and toSimple for Base64Model', () {
        final model = Base64Model(context: context);
        final expression = buildSimpleValueExpression(
          refer('value'),
          model,
          explode: false,
          allowEmpty: true,
        );

        final method = Method(
          (b) => b
            ..name = 'test'
            ..body = declareFinal(
              'result',
            ).assign(expression.expression).statement,
        );

        final generated = format(method.accept(emitter).toString());
        final expected = format('''
          test() {
            final result = value
                .toBase64String()
                .toSimple(explode: false, allowEmpty: true);
          }
        ''');

        expect(
          collapseWhitespace(generated),
          collapseWhitespace(expected),
        );
      });

      test(
        'generates null-safe toBase64String for nullable Base64Model',
        () {
          final model = Base64Model(context: context);
          final expression = buildSimpleValueExpression(
            refer('value'),
            model,
            explode: false,
            allowEmpty: true,
            isNullable: true,
          );

          final method = Method(
            (b) => b
              ..name = 'test'
              ..body = declareFinal(
                'result',
              ).assign(expression.expression).statement,
          );

          final generated = format(method.accept(emitter).toString());
          final expected = format('''
            test() {
              final result = value
                  ?.toBase64String()
                  .toSimple(explode: false, allowEmpty: true);
            }
          ''');

          expect(
            collapseWhitespace(generated),
            collapseWhitespace(expected),
          );
        },
      );
    });

    group('List<Base64Model>', () {
      test(
        'generates toBase64String list content for List<Base64Model>',
        () {
          final model = ListModel(
            content: Base64Model(context: context),
            context: context,
            examples: const [],
          );
          final expression = buildSimpleValueExpression(
            refer('value'),
            model,
            explode: false,
            allowEmpty: true,
          );

          final method = Method(
            (b) => b
              ..name = 'test'
              ..body = declareFinal(
                'result',
              ).assign(expression.expression).statement,
          );

          final generated = format(method.accept(emitter).toString());
          final expected = format('''
            test() {
              final result = value
                  .map((e) => e.toBase64String())
                  .toList()
                  .toSimple(
                    explode: false,
                    allowEmpty: true,
                    alreadyEncoded: true,
                  );
            }
          ''');

          expect(
            collapseWhitespace(generated),
            collapseWhitespace(expected),
          );
        },
      );

      test(
        'generates null-safe map for nullable List<Base64Model>',
        () {
          final model = ListModel(
            content: Base64Model(context: context),
            context: context,
            examples: const [],
          );
          final expression = buildSimpleValueExpression(
            refer('value'),
            model,
            explode: false,
            allowEmpty: true,
            isNullable: true,
          );

          final method = Method(
            (b) => b
              ..name = 'test'
              ..body = declareFinal(
                'result',
              ).assign(expression.expression).statement,
          );

          final generated = format(method.accept(emitter).toString());
          final expected = format('''
            test() {
              final result = value
                  ?.map((e) => e.toBase64String())
                  .toList()
                  .toSimple(
                    explode: false,
                    allowEmpty: true,
                    alreadyEncoded: true,
                  );
            }
          ''');

          expect(
            collapseWhitespace(generated),
            collapseWhitespace(expected),
          );
        },
      );

      test('null-guards each element for List<Base64Model?>', () {
        final model = ListModel(
          content: Base64Model(context: context),
          isContentNullable: true,
          context: context,
          examples: const [],
        );
        final expression = buildSimpleValueExpression(
          refer('value'),
          model,
          explode: false,
          allowEmpty: true,
        );

        final method = Method(
          (b) => b
            ..name = 'test'
            ..body = declareFinal(
              'result',
            ).assign(expression.expression).statement,
        );

        final generated = format(method.accept(emitter).toString());
        final expected = format('''
          test() {
            final result = value
                .map((e) => e?.toBase64String() ?? '')
                .toList()
                .toSimple(
                  explode: false,
                  allowEmpty: true,
                  alreadyEncoded: true,
                );
          }
        ''');

        expect(
          collapseWhitespace(generated),
          collapseWhitespace(expected),
        );
      });
    });

    group('List<MapModel>', () {
      test(
        'generates list-of-map encoding for List<Map<String, String>>',
        () {
          final model = ListModel(
            content: MapModel(
              valueModel: StringModel(context: context),
              context: context,
              examples: const [],
            ),
            context: context,
            examples: const [],
          );
          final expression = buildSimpleValueExpression(
            refer('value'),
            model,
            explode: false,
            allowEmpty: true,
          );

          final method = Method(
            (b) => b
              ..name = 'test'
              ..body = declareFinal(
                'result',
              ).assign(expression.expression).statement,
          );

          final generated = format(method.accept(emitter).toString());
          final expected = format('''
            test() {
              final result = value
                  .map(
                    (e) => e
                        .map((k, v) => MapEntry(k, PropertyValue.scalar(v)))
                        .toSimple(explode: false, allowEmpty: true),
                  )
                  .toList()
                  .toSimple(
                    explode: false,
                    allowEmpty: true,
                    alreadyEncoded: true,
                  );
            }
          ''');

          expect(
            collapseWhitespace(generated),
            collapseWhitespace(expected),
          );
        },
      );

      test(
        'generates list-of-map encoding for List<Map<String, int>>',
        () {
          final model = ListModel(
            content: MapModel(
              valueModel: IntegerModel(context: context),
              context: context,
              examples: const [],
            ),
            context: context,
            examples: const [],
          );
          final expression = buildSimpleValueExpression(
            refer('value'),
            model,
            explode: false,
            allowEmpty: true,
          );

          final method = Method(
            (b) => b
              ..name = 'test'
              ..body = declareFinal(
                'result',
              ).assign(expression.expression).statement,
          );

          final generated = format(method.accept(emitter).toString());
          final expected = format('''
            test() {
              final result = value
                  .map(
                    (e) => e
                        .map(
                          (k, v) =>
                              MapEntry(k, PropertyValue.scalar(v.toString())),
                        )
                        .toSimple(explode: false, allowEmpty: true),
                  )
                  .toList()
                  .toSimple(
                    explode: false,
                    allowEmpty: true,
                    alreadyEncoded: true,
                  );
            }
          ''');

          expect(
            collapseWhitespace(generated),
            collapseWhitespace(expected),
          );
        },
      );

      test(
        'generates runtime throw for List<Map<String, ClassModel>>',
        () {
          final model = ListModel(
            content: MapModel(
              valueModel: ClassModel(
                isDeprecated: false,
                name: 'User',
                properties: [],
                context: context,
                examples: const [],
              ),
              context: context,
              examples: const [],
            ),
            context: context,
            examples: const [],
          );
          final expression = buildSimpleValueExpression(
            refer('value'),
            model,
            explode: false,
            allowEmpty: true,
          );

          final method = Method(
            (b) => b
              ..name = 'test'
              ..body = declareFinal(
                'result',
              ).assign(expression.expression).statement,
          );

          final generated = format(method.accept(scopedEmitter).toString());
          final expected = format('''
            test() {
              final result = throw _i1.EncodingException(
                'List of maps with complex value types cannot be simple-encoded.',
              );
            }
          ''');

          expect(
            collapseWhitespace(generated),
            collapseWhitespace(expected),
          );
        },
      );

      test(
        'header List<Map<String, int>> threads literal into element and list '
        'toSimple',
        () {
          final built = buildToSimpleHeaderParameterExpression(
            'value',
            RequestHeaderObject(
              name: 'value',
              rawName: 'X-Value',
              description: 'header',
              model: ListModel(
                content: MapModel(
                  valueModel: IntegerModel(context: context),
                  context: context,
                  examples: const [],
                ),
                context: context,
                examples: const [],
              ),
              encoding: HeaderParameterEncoding.simple,
              explode: false,
              allowEmptyValue: false,
              isRequired: true,
              isDeprecated: false,
              context: context,
              examples: const [],
              defaultValue: null,
            ),
          );

          expect(
            collapseWhitespace(methodBody(built)),
            collapseWhitespace(
              format('''
                test() {
                  final result = value
                      .map(
                        (e) => e
                            .map(
                              (k, v) => MapEntry(
                                k,
                                PropertyValue.scalar(v.toString()),
                              ),
                            )
                            .toSimple(
                              explode: false,
                              allowEmpty: true,
                              literal: true,
                            ),
                      )
                      .toList()
                      .toSimple(
                        explode: false,
                        allowEmpty: true,
                        alreadyEncoded: true,
                        literal: true,
                      );
                }
              '''),
            ),
          );
        },
      );
    });

    group('nullable list content', () {
      test('null-guards each element for List<String?>', () {
        final model = ListModel(
          content: StringModel(context: context),
          isContentNullable: true,
          context: context,
          examples: const [],
        );

        final expression = buildSimpleValueExpression(
          refer('value'),
          model,
          explode: false,
          allowEmpty: true,
        );

        final method = Method(
          (b) => b
            ..name = 'test'
            ..body = declareFinal(
              'result',
            ).assign(expression.expression).statement,
        );

        final generated = format(method.accept(emitter).toString());
        final expected = format('''
          test() {
            final result = value
                .map((e) => e ?? '')
                .toList()
                .toSimple(explode: false, allowEmpty: true);
          }
        ''');

        expect(
          collapseWhitespace(generated),
          collapseWhitespace(expected),
        );
      });

      test('null-guards each element for List<int?>', () {
        final model = ListModel(
          content: IntegerModel(context: context),
          isContentNullable: true,
          context: context,
          examples: const [],
        );

        final expression = buildSimpleValueExpression(
          refer('value'),
          model,
          explode: false,
          allowEmpty: true,
        );

        final method = Method(
          (b) => b
            ..name = 'test'
            ..body = declareFinal(
              'result',
            ).assign(expression.expression).statement,
        );

        final generated = format(method.accept(emitter).toString());
        final expected = format('''
          test() {
            final result = value
                .map((e) => e == null ? '' : e.uriEncode(allowEmpty: true))
                .toList()
                .toSimple(explode: false, allowEmpty: true, alreadyEncoded: true);
          }
        ''');

        expect(
          collapseWhitespace(generated),
          collapseWhitespace(expected),
        );
      });
    });
  });

  group('buildToSimplePathParameterExpression with nullable model', () {
    test(
      'uses null assertion for effectively nullable AliasModel '
      'since path params are required',
      () {
        final parameter = PathParameterObject(
          name: 'loaDocumentId',
          rawName: 'loa_document_id',
          description: 'LOA document ID',
          model: AliasModel(
            name: 'LoaDocumentIdentifier',
            model: StringModel(context: context),
            context: context,
            isNullable: true,
            examples: const [],
            defaultValue: null,
          ),
          encoding: PathParameterEncoding.simple,
          explode: false,
          allowEmptyValue: false,
          isRequired: true,
          isDeprecated: false,
          context: context,
          examples: const [],
          defaultValue: null,
        );
        expect(
          emit(
            buildToSimplePathParameterExpression('loaDocumentId', parameter),
          ),
          'loaDocumentId!.toSimple(explode: false, allowEmpty: true, )',
        );
      },
    );

    test('uses non-null call for non-nullable model', () {
      final parameter = PathParameterObject(
        name: 'userId',
        rawName: 'userId',
        description: 'User ID',
        model: StringModel(context: context),
        encoding: PathParameterEncoding.simple,
        explode: false,
        allowEmptyValue: false,
        isRequired: true,
        isDeprecated: false,
        context: context,
        examples: const [],
        defaultValue: null,
      );
      expect(
        emit(
          buildToSimplePathParameterExpression('userId', parameter),
        ),
        'userId.toSimple(explode: false, allowEmpty: true, )',
      );
    });
  });

  group('buildToSimpleHeaderParameterExpression with nullable model', () {
    test('uses null-safe call for effectively nullable AliasModel', () {
      final parameter = RequestHeaderObject(
        name: 'x-custom-header',
        rawName: 'x-custom-header',
        description: 'Custom header',
        model: AliasModel(
          name: 'HeaderAlias',
          model: StringModel(context: context),
          context: context,
          isNullable: true,
          examples: const [],
          defaultValue: null,
        ),
        encoding: HeaderParameterEncoding.simple,
        explode: false,
        allowEmptyValue: false,
        isRequired: true,
        isDeprecated: false,
        context: context,
        examples: const [],
        defaultValue: null,
      );
      expect(
        emit(
          buildToSimpleHeaderParameterExpression('xCustomHeader', parameter),
        ),
        'xCustomHeader?.toSimple(explode: false, allowEmpty: true, '
        'literal: true, )',
      );
    });

    test(
      'uses non-null call for effectively nullable AliasModel '
      'when isNullChecked is true',
      () {
        final parameter = RequestHeaderObject(
          name: 'x-custom-header',
          rawName: 'x-custom-header',
          description: 'Custom header',
          model: AliasModel(
            name: 'HeaderAlias',
            model: StringModel(context: context),
            context: context,
            isNullable: true,
            examples: const [],
            defaultValue: null,
          ),
          encoding: HeaderParameterEncoding.simple,
          explode: false,
          allowEmptyValue: false,
          isRequired: false,
          isDeprecated: false,
          context: context,
          examples: const [],
          defaultValue: null,
        );
        expect(
          emit(
            buildToSimpleHeaderParameterExpression(
              'xCustomHeader',
              parameter,
              isNullChecked: true,
            ),
          ),
          'xCustomHeader.toSimple(explode: false, allowEmpty: true, '
          'literal: true, )',
        );
      },
    );

    test(
      'uses non-null call for nullable ClassModel '
      'when isNullChecked is true',
      () {
        final parameter = RequestHeaderObject(
          name: 'x-nullable-object',
          rawName: 'X-Nullable-Object',
          description: 'Nullable object header',
          model: ClassModel(
            name: 'NullableObj',
            properties: const [],
            context: context,
            isNullable: true,
            isDeprecated: false,
            examples: const [],
          ),
          encoding: HeaderParameterEncoding.simple,
          explode: false,
          allowEmptyValue: false,
          isRequired: false,
          isDeprecated: false,
          context: context,
          examples: const [],
          defaultValue: null,
        );
        expect(
          emit(
            buildToSimpleHeaderParameterExpression(
              'xNullableObject',
              parameter,
              isNullChecked: true,
            ),
          ),
          'xNullableObject.toSimple(explode: false, allowEmpty: true, '
          'literal: true, )',
        );
      },
    );

    test(
      'uses null-safe call for nullable model when isNullChecked is false',
      () {
        final parameter = RequestHeaderObject(
          name: 'x-nullable-header',
          rawName: 'X-Nullable-Header',
          description: 'Nullable header',
          model: ClassModel(
            name: 'NullableObj',
            properties: const [],
            context: context,
            isNullable: true,
            isDeprecated: false,
            examples: const [],
          ),
          encoding: HeaderParameterEncoding.simple,
          explode: false,
          allowEmptyValue: false,
          isRequired: true,
          isDeprecated: false,
          context: context,
          examples: const [],
          defaultValue: null,
        );
        expect(
          emit(
            buildToSimpleHeaderParameterExpression(
              'xNullableHeader',
              parameter,
            ),
          ),
          'xNullableHeader?.toSimple(explode: false, allowEmpty: true, '
          'literal: true, )',
        );
      },
    );
  });

  group('dual-context: same model literal in header, URI-encoded in path', () {
    test('ClassModel header emits literal while path stays byte-identical', () {
      final model = ClassModel(
        name: 'Point',
        properties: const [],
        context: context,
        isDeprecated: false,
        examples: const [],
      );
      final headerBuilt = buildToSimpleHeaderParameterExpression(
        'value',
        RequestHeaderObject(
          name: 'value',
          rawName: 'X-Value',
          description: 'header',
          model: model,
          encoding: HeaderParameterEncoding.simple,
          explode: false,
          allowEmptyValue: false,
          isRequired: true,
          isDeprecated: false,
          context: context,
          examples: const [],
          defaultValue: null,
        ),
      );
      final pathBuilt = buildToSimplePathParameterExpression(
        'value',
        PathParameterObject(
          name: 'value',
          rawName: 'value',
          description: 'path',
          model: model,
          encoding: PathParameterEncoding.simple,
          explode: false,
          allowEmptyValue: false,
          isRequired: true,
          isDeprecated: false,
          context: context,
          examples: const [],
          defaultValue: null,
        ),
      );
      expect(
        collapseWhitespace(methodBody(headerBuilt)),
        collapseWhitespace(
          format(
            'test() { final result = value.toSimple(explode: false, '
            'allowEmpty: true, literal: true); }',
          ),
        ),
      );
      expect(
        collapseWhitespace(methodBody(pathBuilt)),
        collapseWhitespace(
          format(
            'test() { final result = '
            'value.toSimple(explode: false, allowEmpty: true); }',
          ),
        ),
      );
    });
  });

  group('simpleEncodingThrowReason', () {
    void expectSupported(Model model, {required String label}) {
      expect(
        simpleEncodingThrowReason(model),
        isNull,
        reason: '$label should be supported (no throw)',
      );
    }

    void expectThrowReason(
      Model model, {
      required String label,
      required String containsText,
    }) {
      final reason = simpleEncodingThrowReason(model);
      expect(
        reason,
        isNotNull,
        reason: '$label should produce a throw reason',
      );
      expect(
        reason!.contains(containsText),
        isTrue,
        reason: '$label reason "$reason" should contain "$containsText"',
      );
    }

    test('supported leaf models return null', () {
      expectSupported(StringModel(context: context), label: 'StringModel');
      expectSupported(IntegerModel(context: context), label: 'IntegerModel');
      expectSupported(DoubleModel(context: context), label: 'DoubleModel');
      expectSupported(NumberModel(context: context), label: 'NumberModel');
      expectSupported(BooleanModel(context: context), label: 'BooleanModel');
      expectSupported(DateTimeModel(context: context), label: 'DateTimeModel');
      expectSupported(DateModel(context: context), label: 'DateModel');
      expectSupported(DecimalModel(context: context), label: 'DecimalModel');
      expectSupported(UriModel(context: context), label: 'UriModel');
      expectSupported(Base64Model(context: context), label: 'Base64Model');
      expectSupported(AnyModel(context: context), label: 'AnyModel');
      expectSupported(
        EnumModel<String>(
          isDeprecated: false,
          name: 'StatusE',
          values: {const EnumEntry(value: 'a')},
          isNullable: false,
          context: context,
          examples: const [],
        ),
        label: 'EnumModel<String>',
      );
      expectSupported(
        ClassModel(
          isDeprecated: false,
          name: 'User',
          properties: const [],
          context: context,
          examples: const [],
        ),
        label: 'ClassModel',
      );
      expectSupported(
        AllOfModel(
          isDeprecated: false,
          name: 'AllOfX',
          models: {StringModel(context: context)},
          context: context,
          examples: const [],
        ),
        label: 'AllOfModel',
      );
      expectSupported(
        OneOfModel(
          isDeprecated: false,
          name: 'OneOfX',
          models: {
            (discriminatorValue: null, model: StringModel(context: context)),
          },
          context: context,
          examples: const [],
        ),
        label: 'OneOfModel',
      );
      expectSupported(
        AnyOfModel(
          isDeprecated: false,
          name: 'AnyOfX',
          models: {
            (discriminatorValue: null, model: StringModel(context: context)),
          },
          context: context,
          examples: const [],
        ),
        label: 'AnyOfModel',
      );
    });

    test('AliasModel chains delegate to underlying type', () {
      expectSupported(
        AliasModel(
          name: 'A1',
          model: StringModel(context: context),
          context: context,
          examples: const [],
          defaultValue: null,
        ),
        label: 'AliasModel(StringModel)',
      );
      expectSupported(
        AliasModel(
          name: 'A2',
          model: AliasModel(
            name: 'A1',
            model: StringModel(context: context),
            context: context,
            examples: const [],
            defaultValue: null,
          ),
          context: context,
          examples: const [],
          defaultValue: null,
        ),
        label: 'AliasModel(AliasModel(StringModel))',
      );
    });

    test('NeverModel returns never-typed reason', () {
      expectThrowReason(
        NeverModel(context: context, isNullable: false),
        label: 'NeverModel',
        containsText: 'never-typed',
      );
    });

    test('BinaryModel returns binary reason', () {
      expectThrowReason(
        BinaryModel(context: context),
        label: 'BinaryModel',
        containsText: 'binary',
      );
    });

    test('ListModel<NeverModel> returns unsupported elements reason', () {
      expectThrowReason(
        ListModel(
          content: NeverModel(context: context, isNullable: false),
          context: context,
          examples: const [],
        ),
        label: 'ListModel<NeverModel>',
        containsText: 'lists with unsupported element types',
      );
    });

    test('ListModel<BinaryModel> returns unsupported elements reason', () {
      expectThrowReason(
        ListModel(
          content: BinaryModel(context: context),
          context: context,
          examples: const [],
        ),
        label: 'ListModel<BinaryModel>',
        containsText: 'lists with unsupported element types',
      );
    });

    test('ListModel<ListModel<String>> returns unsupported elements reason '
        '(nested list)', () {
      expectThrowReason(
        ListModel(
          content: ListModel(
            content: StringModel(context: context),
            context: context,
            examples: const [],
          ),
          context: context,
          examples: const [],
        ),
        label: 'ListModel<ListModel<String>>',
        containsText: 'lists with unsupported element types',
      );
    });

    test('MapModel with complex value returns map complex reason', () {
      expectThrowReason(
        MapModel(
          valueModel: ClassModel(
            isDeprecated: false,
            name: 'User',
            properties: const [],
            context: context,
            examples: const [],
          ),
          context: context,
          examples: const [],
        ),
        label: 'MapModel(ClassModel)',
        containsText: 'map with complex value types',
      );
    });

    test('AliasModel(NeverModel) returns never-typed reason '
        '(unwrap depth 1)', () {
      expectThrowReason(
        AliasModel(
          name: 'NA',
          model: NeverModel(context: context, isNullable: false),
          context: context,
          examples: const [],
          defaultValue: null,
        ),
        label: 'AliasModel(NeverModel)',
        containsText: 'never-typed',
      );
    });

    test('AliasModel(AliasModel(NeverModel)) returns never-typed reason '
        '(unwrap depth 2)', () {
      expectThrowReason(
        AliasModel(
          name: 'NA2',
          model: AliasModel(
            name: 'NA1',
            model: NeverModel(context: context, isNullable: false),
            context: context,
            examples: const [],
            defaultValue: null,
          ),
          context: context,
          examples: const [],
          defaultValue: null,
        ),
        label: 'AliasModel(AliasModel(NeverModel))',
        containsText: 'never-typed',
      );
    });

    test('AliasModel(MapModel(ClassModel)) returns map complex reason', () {
      expectThrowReason(
        AliasModel(
          name: 'AM',
          model: MapModel(
            valueModel: ClassModel(
              isDeprecated: false,
              name: 'User',
              properties: const [],
              context: context,
              examples: const [],
            ),
            context: context,
            examples: const [],
          ),
          context: context,
          examples: const [],
          defaultValue: null,
        ),
        label: 'AliasModel(MapModel(ClassModel))',
        containsText: 'map with complex value types',
      );
    });

    test('MapModel with simple value returns null', () {
      expectSupported(
        MapModel(
          valueModel: StringModel(context: context),
          context: context,
          examples: const [],
        ),
        label: 'MapModel<String>',
      );
      expectSupported(
        MapModel(
          valueModel: IntegerModel(context: context),
          context: context,
          examples: const [],
        ),
        label: 'MapModel<Integer>',
      );
    });

    test('ListModel<AnyModel> returns unsupported elements reason', () {
      // List<AnyModel> compiles to List<Object?>, which has no toSimple
      // extension in tonik_util. The pre-flight guard must throw.
      expectThrowReason(
        ListModel(
          content: AnyModel(context: context),
          context: context,
          examples: const [],
        ),
        label: 'ListModel<AnyModel>',
        containsText: 'lists with unsupported element types',
      );
    });

    test('ListModel with complex map content returns unsupported reason', () {
      expectThrowReason(
        ListModel(
          content: MapModel(
            valueModel: ClassModel(
              isDeprecated: false,
              name: 'User',
              properties: const [],
              context: context,
              examples: const [],
            ),
            context: context,
            examples: const [],
          ),
          context: context,
          examples: const [],
        ),
        label: 'ListModel<MapModel<ClassModel>>',
        containsText: 'lists with unsupported element types',
      );
    });

    test('ListModel<AliasModel(NeverModel)> unwraps and returns reason', () {
      expectThrowReason(
        ListModel(
          content: AliasModel(
            name: 'NA',
            model: NeverModel(context: context, isNullable: false),
            context: context,
            examples: const [],
            defaultValue: null,
          ),
          context: context,
          examples: const [],
        ),
        label: 'ListModel<AliasModel(NeverModel)>',
        containsText: 'lists with unsupported element types',
      );
    });

    test('ListModel content arms backed by runtime support return null', () {
      // These exercise every "supported" arm of _listContentThrowReason so it
      // stays in lock-step with _handleListExpression's runtime support.
      expectSupported(
        ListModel(
          content: ClassModel(
            isDeprecated: false,
            name: 'User',
            properties: const [],
            context: context,
            examples: const [],
          ),
          context: context,
          examples: const [],
        ),
        label: 'ListModel<ClassModel>',
      );
      expectSupported(
        ListModel(
          content: EnumModel<String>(
            isDeprecated: false,
            name: 'StatusE',
            values: {const EnumEntry(value: 'a')},
            isNullable: false,
            context: context,
            examples: const [],
          ),
          context: context,
          examples: const [],
        ),
        label: 'ListModel<EnumModel<String>>',
      );
      expectSupported(
        ListModel(
          content: AllOfModel(
            isDeprecated: false,
            name: 'AllOfX',
            models: {StringModel(context: context)},
            context: context,
            examples: const [],
          ),
          context: context,
          examples: const [],
        ),
        label: 'ListModel<AllOfModel>',
      );
      expectSupported(
        ListModel(
          content: OneOfModel(
            isDeprecated: false,
            name: 'OneOfX',
            models: {
              (discriminatorValue: null, model: StringModel(context: context)),
            },
            context: context,
            examples: const [],
          ),
          context: context,
          examples: const [],
        ),
        label: 'ListModel<OneOfModel>',
      );
      expectSupported(
        ListModel(
          content: AnyOfModel(
            isDeprecated: false,
            name: 'AnyOfX',
            models: {
              (discriminatorValue: null, model: StringModel(context: context)),
            },
            context: context,
            examples: const [],
          ),
          context: context,
          examples: const [],
        ),
        label: 'ListModel<AnyOfModel>',
      );
      expectSupported(
        ListModel(
          content: DateTimeModel(context: context),
          context: context,
          examples: const [],
        ),
        label: 'ListModel<DateTimeModel>',
      );
      expectSupported(
        ListModel(
          content: DateModel(context: context),
          context: context,
          examples: const [],
        ),
        label: 'ListModel<DateModel>',
      );
      expectSupported(
        ListModel(
          content: DecimalModel(context: context),
          context: context,
          examples: const [],
        ),
        label: 'ListModel<DecimalModel>',
      );
      expectSupported(
        ListModel(
          content: UriModel(context: context),
          context: context,
          examples: const [],
        ),
        label: 'ListModel<UriModel>',
      );
      expectSupported(
        ListModel(
          content: Base64Model(context: context),
          context: context,
          examples: const [],
        ),
        label: 'ListModel<Base64Model>',
      );
      expectSupported(
        ListModel(
          content: IntegerModel(context: context),
          context: context,
          examples: const [],
        ),
        label: 'ListModel<IntegerModel>',
      );
      expectSupported(
        ListModel(
          content: DoubleModel(context: context),
          context: context,
          examples: const [],
        ),
        label: 'ListModel<DoubleModel>',
      );
      expectSupported(
        ListModel(
          content: NumberModel(context: context),
          context: context,
          examples: const [],
        ),
        label: 'ListModel<NumberModel>',
      );
      expectSupported(
        ListModel(
          content: BooleanModel(context: context),
          context: context,
          examples: const [],
        ),
        label: 'ListModel<BooleanModel>',
      );
      expectSupported(
        ListModel(
          content: StringModel(context: context),
          context: context,
          examples: const [],
        ),
        label: 'ListModel<StringModel>',
      );
      expectSupported(
        ListModel(
          content: MapModel(
            valueModel: StringModel(context: context),
            context: context,
            examples: const [],
          ),
          context: context,
          examples: const [],
        ),
        label: 'ListModel<MapModel<String>>',
      );
    });
  });
}
