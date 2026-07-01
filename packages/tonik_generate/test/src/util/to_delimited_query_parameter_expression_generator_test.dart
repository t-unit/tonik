import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/built_expression.dart';
import 'package:tonik_generate/src/util/to_delimited_query_parameter_expression_generator.dart';

void main() {
  group('buildToDelimitedQueryParameterCode', () {
    late Context context;
    late DartEmitter emitter;

    final format = DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    ).format;

    setUp(() {
      context = Context.initial();
      emitter = DartEmitter(useNullSafetySyntax: true);
    });

    String emitStatements(BuiltStatements built) {
      final method = Method(
        (b) => b
          ..name = 'test'
          ..returns = refer('void')
          ..lambda = false
          ..body = Block.of(built.statements),
      );
      return format(method.accept(emitter).toString());
    }

    QueryParameterObject createParameter({
      required String name,
      required String rawName,
      required Model model,
      required bool explode,
      required bool allowEmpty,
      bool allowReserved = false,
    }) {
      return QueryParameterObject(
        name: name,
        rawName: rawName,
        description: null,
        model: model,
        isRequired: true,
        isDeprecated: false,
        encoding: QueryParameterEncoding.spaceDelimited,
        explode: explode,
        allowEmptyValue: allowEmpty,
        allowReserved: allowReserved,
        context: context,
        examples: const [],
        defaultValue: null,
      );
    }

    group('enum and integer list items', () {
      EnumModel<String> stringEnum() => EnumModel<String>(
        isDeprecated: false,
        context: context,
        values: {
          const EnumEntry(value: 'high priority'),
          const EnumEntry(value: 'low priority'),
        },
        isNullable: false,
        examples: const [],
      );

      test('generates spaceDelimited enum list (non-explode)', () {
        final parameter = createParameter(
          name: 'priorities',
          rawName: 'priorities',
          model: ListModel(
            content: stringEnum(),
            context: context,
            examples: const [],
          ),
          explode: false,
          allowEmpty: true,
        );

        final codes = buildToDelimitedQueryParameterCode(
          'priorities',
          parameter,
          encoding: QueryParameterEncoding.spaceDelimited,
        );

        final code = emitStatements(codes);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format(r'''
              void test() {
                for (final value in priorities
                    .map((e) => e.uriEncode(allowEmpty: true))
                    .toList()
                    .toSpaceDelimited(
                      explode: false,
                      allowEmpty: true,
                      alreadyEncoded: true,
                    )) {
                  _$entries.add((name: r'priorities', value: value));
                }
              }
            '''),
          ),
        );
      });

      test('generates spaceDelimited enum list (explode)', () {
        final parameter = createParameter(
          name: 'priorities',
          rawName: 'priorities',
          model: ListModel(
            content: stringEnum(),
            context: context,
            examples: const [],
          ),
          explode: true,
          allowEmpty: true,
        );

        final codes = buildToDelimitedQueryParameterCode(
          'priorities',
          parameter,
          encoding: QueryParameterEncoding.spaceDelimited,
          explode: true,
        );

        final code = emitStatements(codes);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format(r'''
              void test() {
                for (final value in priorities
                    .map((e) => e.uriEncode(allowEmpty: true))
                    .toList()
                    .toSpaceDelimited(
                      explode: true,
                      allowEmpty: true,
                      alreadyEncoded: true,
                    )) {
                  _$entries.add((name: r'priorities', value: value));
                }
              }
            '''),
          ),
        );
      });

      test('generates spaceDelimited integer list (non-explode)', () {
        final parameter = createParameter(
          name: 'ids',
          rawName: 'ids',
          model: ListModel(
            content: IntegerModel(context: context),
            context: context,
            examples: const [],
          ),
          explode: false,
          allowEmpty: true,
        );

        final codes = buildToDelimitedQueryParameterCode(
          'ids',
          parameter,
          encoding: QueryParameterEncoding.spaceDelimited,
        );

        final code = emitStatements(codes);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format(r'''
              void test() {
                for (final value in ids
                    .map((e) => e.uriEncode(allowEmpty: true))
                    .toList()
                    .toSpaceDelimited(
                      explode: false,
                      allowEmpty: true,
                      alreadyEncoded: true,
                    )) {
                  _$entries.add((name: r'ids', value: value));
                }
              }
            '''),
          ),
        );
      });

      test('generates pipeDelimited enum list (non-explode)', () {
        final parameter = createParameter(
          name: 'priorities',
          rawName: 'priorities',
          model: ListModel(
            content: stringEnum(),
            context: context,
            examples: const [],
          ),
          explode: false,
          allowEmpty: true,
        );

        final codes = buildToDelimitedQueryParameterCode(
          'priorities',
          parameter,
          encoding: QueryParameterEncoding.pipeDelimited,
        );

        final code = emitStatements(codes);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format(r'''
              void test() {
                for (final value in priorities
                    .map((e) => e.uriEncode(allowEmpty: true))
                    .toList()
                    .toPipeDelimited(
                      explode: false,
                      allowEmpty: true,
                      alreadyEncoded: true,
                    )) {
                  _$entries.add((name: r'priorities', value: value));
                }
              }
            '''),
          ),
        );
      });

      test('generates pipeDelimited enum list (explode)', () {
        final parameter = createParameter(
          name: 'priorities',
          rawName: 'priorities',
          model: ListModel(
            content: stringEnum(),
            context: context,
            examples: const [],
          ),
          explode: true,
          allowEmpty: true,
        );

        final codes = buildToDelimitedQueryParameterCode(
          'priorities',
          parameter,
          encoding: QueryParameterEncoding.pipeDelimited,
          explode: true,
        );

        final code = emitStatements(codes);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format(r'''
              void test() {
                for (final value in priorities
                    .map((e) => e.uriEncode(allowEmpty: true))
                    .toList()
                    .toPipeDelimited(
                      explode: true,
                      allowEmpty: true,
                      alreadyEncoded: true,
                    )) {
                  _$entries.add((name: r'priorities', value: value));
                }
              }
            '''),
          ),
        );
      });

      test('generates pipeDelimited integer list (non-explode)', () {
        final parameter = createParameter(
          name: 'ids',
          rawName: 'ids',
          model: ListModel(
            content: IntegerModel(context: context),
            context: context,
            examples: const [],
          ),
          explode: false,
          allowEmpty: true,
        );

        final codes = buildToDelimitedQueryParameterCode(
          'ids',
          parameter,
          encoding: QueryParameterEncoding.pipeDelimited,
        );

        final code = emitStatements(codes);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format(r'''
              void test() {
                for (final value in ids
                    .map((e) => e.uriEncode(allowEmpty: true))
                    .toList()
                    .toPipeDelimited(
                      explode: false,
                      allowEmpty: true,
                      alreadyEncoded: true,
                    )) {
                  _$entries.add((name: r'ids', value: value));
                }
              }
            '''),
          ),
        );
      });
    });

    group('nullable list content', () {
      test('null-guards each element for List<String?>', () {
        final parameter = createParameter(
          name: 'tags',
          rawName: 'tags',
          model: ListModel(
            content: StringModel(context: context),
            isContentNullable: true,
            context: context,
            examples: const [],
          ),
          explode: false,
          allowEmpty: true,
        );

        final codes = buildToDelimitedQueryParameterCode(
          'tags',
          parameter,
          encoding: QueryParameterEncoding.spaceDelimited,
        );

        final code = emitStatements(codes);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format(r'''
              void test() {
                for (final value in tags
                    .map((e) => e == null ? '' : e.uriEncode(allowEmpty: true))
                    .toList()
                    .toSpaceDelimited(
                      explode: false,
                      allowEmpty: true,
                      alreadyEncoded: true,
                    )) {
                  _$entries.add((name: r'tags', value: value));
                }
              }
            '''),
          ),
        );
      });

      test('null-guards each element for List<int?>', () {
        final parameter = createParameter(
          name: 'ids',
          rawName: 'ids',
          model: ListModel(
            content: IntegerModel(context: context),
            isContentNullable: true,
            context: context,
            examples: const [],
          ),
          explode: false,
          allowEmpty: true,
        );

        final codes = buildToDelimitedQueryParameterCode(
          'ids',
          parameter,
          encoding: QueryParameterEncoding.pipeDelimited,
        );

        final code = emitStatements(codes);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format(r'''
              void test() {
                for (final value in ids
                    .map((e) => e == null ? '' : e.uriEncode(allowEmpty: true))
                    .toList()
                    .toPipeDelimited(
                      explode: false,
                      allowEmpty: true,
                      alreadyEncoded: true,
                    )) {
                  _$entries.add((name: r'ids', value: value));
                }
              }
            '''),
          ),
        );
      });
    });

    group('special characters in rawName', () {
      test(
        'generates valid code when rawName contains single quote '
        '(non-explode)',
        () {
          final parameter = createParameter(
            name: 'filterParam',
            rawName: "filter's",
            model: ListModel(
              content: StringModel(context: context),
              context: context,
              examples: const [],
            ),
            explode: false,
            allowEmpty: true,
          );

          final codes = buildToDelimitedQueryParameterCode(
            'filterParam',
            parameter,
            encoding: QueryParameterEncoding.spaceDelimited,
          );

          final code = emitStatements(codes);
          expect(
            collapseWhitespace(code),
            collapseWhitespace(
              format(r'''
              void test() {
                for (final value in filterParam.toSpaceDelimited(
                  explode: false,
                  allowEmpty: true,
                )) {
                  _$entries.add((name: r"filter's", value: value));
                }
              }
            '''),
            ),
          );
        },
      );

      test(
        'generates valid code when rawName contains single quote '
        '(explode)',
        () {
          final parameter = createParameter(
            name: 'filterParam',
            rawName: "filter's",
            model: ListModel(
              content: StringModel(context: context),
              context: context,
              examples: const [],
            ),
            explode: true,
            allowEmpty: true,
          );

          final codes = buildToDelimitedQueryParameterCode(
            'filterParam',
            parameter,
            encoding: QueryParameterEncoding.spaceDelimited,
            explode: true,
          );

          final code = emitStatements(codes);
          expect(
            collapseWhitespace(code),
            collapseWhitespace(
              format(r'''
              void test() {
                for (final value in filterParam.toSpaceDelimited(
                  explode: true,
                  allowEmpty: true,
                )) {
                  _$entries.add((name: r"filter's", value: value));
                }
              }
            '''),
            ),
          );
        },
      );
    });

    group('allowReserved', () {
      test('spaceDelimited string list carries allowReserved when set', () {
        final parameter = createParameter(
          name: 'tags',
          rawName: 'tags',
          model: ListModel(
            content: StringModel(context: context),
            context: context,
            examples: const [],
          ),
          explode: false,
          allowEmpty: true,
          allowReserved: true,
        );

        final codes = buildToDelimitedQueryParameterCode(
          'tags',
          parameter,
          encoding: QueryParameterEncoding.spaceDelimited,
          allowReserved: true,
        );

        final code = emitStatements(codes);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format(r'''
              void test() {
                for (final value in tags.toSpaceDelimited(
                  explode: false,
                  allowEmpty: true,
                  allowReserved: true,
                )) {
                  _$entries.add((name: r'tags', value: value));
                }
              }
            '''),
          ),
        );
      });

      test('spaceDelimited string list omits allowReserved by default', () {
        final parameter = createParameter(
          name: 'tags',
          rawName: 'tags',
          model: ListModel(
            content: StringModel(context: context),
            context: context,
            examples: const [],
          ),
          explode: false,
          allowEmpty: true,
        );

        final codes = buildToDelimitedQueryParameterCode(
          'tags',
          parameter,
          encoding: QueryParameterEncoding.spaceDelimited,
        );

        final code = emitStatements(codes);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format(r'''
              void test() {
                for (final value in tags.toSpaceDelimited(
                  explode: false,
                  allowEmpty: true,
                )) {
                  _$entries.add((name: r'tags', value: value));
                }
              }
            '''),
          ),
        );
      });

      test('pipeDelimited string list carries allowReserved when set', () {
        final parameter = createParameter(
          name: 'tags',
          rawName: 'tags',
          model: ListModel(
            content: StringModel(context: context),
            context: context,
            examples: const [],
          ),
          explode: false,
          allowEmpty: true,
          allowReserved: true,
        );

        final codes = buildToDelimitedQueryParameterCode(
          'tags',
          parameter,
          encoding: QueryParameterEncoding.pipeDelimited,
          allowReserved: true,
        );

        final code = emitStatements(codes);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format(r'''
              void test() {
                for (final value in tags.toPipeDelimited(
                  explode: false,
                  allowEmpty: true,
                  allowReserved: true,
                )) {
                  _$entries.add((name: r'tags', value: value));
                }
              }
            '''),
          ),
        );
      });

      test('pipeDelimited string list omits allowReserved by default', () {
        final parameter = createParameter(
          name: 'tags',
          rawName: 'tags',
          model: ListModel(
            content: StringModel(context: context),
            context: context,
            examples: const [],
          ),
          explode: false,
          allowEmpty: true,
        );

        final codes = buildToDelimitedQueryParameterCode(
          'tags',
          parameter,
          encoding: QueryParameterEncoding.pipeDelimited,
        );

        final code = emitStatements(codes);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format(r'''
              void test() {
                for (final value in tags.toPipeDelimited(
                  explode: false,
                  allowEmpty: true,
                )) {
                  _$entries.add((name: r'tags', value: value));
                }
              }
            '''),
          ),
        );
      });

      test('spaceDelimited scalar list carries allowReserved when set', () {
        final parameter = createParameter(
          name: 'ids',
          rawName: 'ids',
          model: ListModel(
            content: IntegerModel(context: context),
            context: context,
            examples: const [],
          ),
          explode: false,
          allowEmpty: true,
          allowReserved: true,
        );

        final codes = buildToDelimitedQueryParameterCode(
          'ids',
          parameter,
          encoding: QueryParameterEncoding.spaceDelimited,
          allowReserved: true,
        );

        final code = emitStatements(codes);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format(r'''
              void test() {
                for (final value in ids
                    .map((e) => e.uriEncode(allowEmpty: true, allowReserved: true))
                    .toList()
                    .toSpaceDelimited(
                      explode: false,
                      allowEmpty: true,
                      alreadyEncoded: true,
                    )) {
                  _$entries.add((name: r'ids', value: value));
                }
              }
            '''),
          ),
        );
      });

      test('enum list omits allowReserved even when set', () {
        final parameter = createParameter(
          name: 'priorities',
          rawName: 'priorities',
          model: ListModel(
            content: EnumModel<String>(
              isDeprecated: false,
              context: context,
              values: {
                const EnumEntry(value: 'high priority'),
                const EnumEntry(value: 'low priority'),
              },
              isNullable: false,
              examples: const [],
            ),
            context: context,
            examples: const [],
          ),
          explode: false,
          allowEmpty: true,
          allowReserved: true,
        );

        final codes = buildToDelimitedQueryParameterCode(
          'priorities',
          parameter,
          encoding: QueryParameterEncoding.spaceDelimited,
          allowReserved: true,
        );

        final code = emitStatements(codes);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format(r'''
              void test() {
                for (final value in priorities
                    .map((e) => e.uriEncode(allowEmpty: true))
                    .toList()
                    .toSpaceDelimited(
                      explode: false,
                      allowEmpty: true,
                      alreadyEncoded: true,
                    )) {
                  _$entries.add((name: r'priorities', value: value));
                }
              }
            '''),
          ),
        );
      });

      test('composition list omits allowReserved even when set', () {
        final parameter = createParameter(
          name: 'items',
          rawName: 'items',
          model: ListModel(
            content: OneOfModel(
              isDeprecated: false,
              name: 'Item',
              models: {
                (
                  discriminatorValue: null,
                  model: StringModel(context: context),
                ),
                (
                  discriminatorValue: null,
                  model: IntegerModel(context: context),
                ),
              },
              context: context,
              examples: const [],
            ),
            context: context,
            examples: const [],
          ),
          explode: false,
          allowEmpty: true,
          allowReserved: true,
        );

        final codes = buildToDelimitedQueryParameterCode(
          'items',
          parameter,
          encoding: QueryParameterEncoding.spaceDelimited,
          allowReserved: true,
        );

        final code = emitStatements(codes);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format(r'''
              void test() {
                for (final item in items) {
                  if (item.currentEncodingShape != EncodingShape.simple) {
                    throw EncodingException(
                      r'Parameter items: spaceDelimited encoding requires simple encoding shape',
                    );
                  }
                }
                for (final value in items
                    .map((item) => item.uriEncode(allowEmpty: true))
                    .toList()
                    .toSpaceDelimited(
                      explode: false,
                      allowEmpty: true,
                      alreadyEncoded: true,
                    )) {
                  _$entries.add((name: r'items', value: value));
                }
              }
            '''),
          ),
        );
      });
    });
  });
}
