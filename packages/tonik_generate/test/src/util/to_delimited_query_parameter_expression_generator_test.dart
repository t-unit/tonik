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

      test(
        'spaceDelimited nullable string list threads allowReserved '
        'through the null guard',
        () {
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
                  for (final value in tags
                      .map(
                        (e) => e == null
                            ? ''
                            : e.uriEncode(allowEmpty: true, allowReserved: true),
                      )
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
        },
      );

      test(
        'pipeDelimited nullable string list threads allowReserved '
        'through the null guard',
        () {
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
                  for (final value in tags
                      .map(
                        (e) => e == null
                            ? ''
                            : e.uriEncode(allowEmpty: true, allowReserved: true),
                      )
                      .toList()
                      .toPipeDelimited(
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
        },
      );

      test('enum list threads allowReserved into each item uriEncode when set',
          () {
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
                    .map((e) => e.uriEncode(allowEmpty: true, allowReserved: true))
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

      test('composition list threads allowReserved into each item uriEncode '
          'when set', () {
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
                    .map((item) => item.uriEncode(allowEmpty: true, allowReserved: true))
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

    group('object parameters', () {
      ClassModel colorClass() => ClassModel(
        name: 'Color',
        properties: const [],
        isDeprecated: false,
        context: context,
        examples: const [],
      );

      test('pipeDelimited object (non-explode) flattens via '
          'parameterProperties', () {
        final parameter = createParameter(
          name: 'color',
          rawName: 'color',
          model: colorClass(),
          explode: false,
          allowEmpty: true,
        );

        final codes = buildToDelimitedQueryParameterCode(
          'color',
          parameter,
          encoding: QueryParameterEncoding.pipeDelimited,
        );

        final code = emitStatements(codes);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format(r'''
              void test() {
                _$entries.addAll(
                  color
                      .parameterProperties(allowEmpty: true)
                      .toPipeDelimited(r'color', allowEmpty: true),
                );
              }
            '''),
          ),
        );
      });

      test('spaceDelimited object (non-explode) flattens via '
          'parameterProperties', () {
        final parameter = createParameter(
          name: 'coord',
          rawName: 'coord',
          model: colorClass(),
          explode: false,
          allowEmpty: true,
        );

        final codes = buildToDelimitedQueryParameterCode(
          'coord',
          parameter,
          encoding: QueryParameterEncoding.spaceDelimited,
        );

        final code = emitStatements(codes);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format(r'''
              void test() {
                _$entries.addAll(
                  coord
                      .parameterProperties(allowEmpty: true)
                      .toSpaceDelimited(r'coord', allowEmpty: true),
                );
              }
            '''),
          ),
        );
      });

      test('object threads allowReserved into the flattening call', () {
        final parameter = createParameter(
          name: 'color',
          rawName: 'color',
          model: colorClass(),
          explode: false,
          allowEmpty: true,
          allowReserved: true,
        );

        final codes = buildToDelimitedQueryParameterCode(
          'color',
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
                _$entries.addAll(
                  color
                      .parameterProperties(allowEmpty: true)
                      .toPipeDelimited(
                        r'color',
                        allowEmpty: true,
                        allowReserved: true,
                      ),
                );
              }
            '''),
          ),
        );
      });

      test('explode object throws the specification-undefined exception', () {
        final parameter = createParameter(
          name: 'color',
          rawName: 'color',
          model: colorClass(),
          explode: true,
          allowEmpty: true,
        );

        final codes = buildToDelimitedQueryParameterCode(
          'color',
          parameter,
          encoding: QueryParameterEncoding.pipeDelimited,
          explode: true,
        );

        final code = emitStatements(codes);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format('''
              void test() {
                throw EncodingException(
                  r'Parameter color: pipeDelimited encoding of objects with explode: true is not defined by the specification',
                );
              }
            '''),
          ),
        );
      });
    });

    group('unsupported models', () {
      test('primitive throws the array-and-object-only exception', () {
        final parameter = createParameter(
          name: 'name',
          rawName: 'name',
          model: StringModel(context: context),
          explode: false,
          allowEmpty: true,
        );

        final codes = buildToDelimitedQueryParameterCode(
          'name',
          parameter,
          encoding: QueryParameterEncoding.spaceDelimited,
        );

        final code = emitStatements(codes);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format('''
              void test() {
                throw EncodingException(
                  r'Parameter name: spaceDelimited encoding supports only array and object types',
                );
              }
            '''),
          ),
        );
      });

      test('enum throws the array-and-object-only exception', () {
        final parameter = createParameter(
          name: 'status',
          rawName: 'status',
          model: EnumModel<String>(
            isDeprecated: false,
            context: context,
            values: {
              const EnumEntry(value: 'active'),
              const EnumEntry(value: 'inactive'),
            },
            isNullable: false,
            examples: const [],
          ),
          explode: false,
          allowEmpty: true,
        );

        final codes = buildToDelimitedQueryParameterCode(
          'status',
          parameter,
          encoding: QueryParameterEncoding.pipeDelimited,
        );

        final code = emitStatements(codes);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format('''
              void test() {
                throw EncodingException(
                  r'Parameter status: pipeDelimited encoding supports only array and object types',
                );
              }
            '''),
          ),
        );
      });
    });

    group('alias resolving to list', () {
      test('spaceDelimited alias to string list emits the list path', () {
        final parameter = createParameter(
          name: 'tags',
          rawName: 'tags',
          model: AliasModel(
            name: 'TagList',
            model: ListModel(
              content: StringModel(context: context),
              context: context,
              examples: const [],
            ),
            context: context,
            examples: const [],
            defaultValue: null,
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

      test('pipeDelimited alias to string list emits the list path', () {
        final parameter = createParameter(
          name: 'tags',
          rawName: 'tags',
          model: AliasModel(
            name: 'TagList',
            model: ListModel(
              content: StringModel(context: context),
              context: context,
              examples: const [],
            ),
            context: context,
            examples: const [],
            defaultValue: null,
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
    });

    group('map parameters', () {
      test('spaceDelimited Map<String, String> flattens via '
          'buildMapPropertyValueConversion', () {
        final parameter = createParameter(
          name: 'filter',
          rawName: 'filter',
          model: MapModel(
            valueModel: StringModel(context: context),
            context: context,
            examples: const [],
          ),
          explode: false,
          allowEmpty: true,
        );

        final codes = buildToDelimitedQueryParameterCode(
          'filter',
          parameter,
          encoding: QueryParameterEncoding.spaceDelimited,
        );

        final code = emitStatements(codes);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format(r'''
              void test() {
                _$entries.addAll(
                  filter
                      .map((k, v) => MapEntry(k, PropertyValue.scalar(v)))
                      .toSpaceDelimited(r'filter', allowEmpty: true),
                );
              }
            '''),
          ),
        );
      });

      test('pipeDelimited Map<String, int> flattens via '
          'buildMapPropertyValueConversion', () {
        final parameter = createParameter(
          name: 'counts',
          rawName: 'counts',
          model: MapModel(
            valueModel: IntegerModel(context: context),
            context: context,
            examples: const [],
          ),
          explode: false,
          allowEmpty: true,
        );

        final codes = buildToDelimitedQueryParameterCode(
          'counts',
          parameter,
          encoding: QueryParameterEncoding.pipeDelimited,
        );

        final code = emitStatements(codes);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format(r'''
              void test() {
                _$entries.addAll(
                  counts
                      .map((k, v) => MapEntry(k, PropertyValue.scalar(v.toString())))
                      .toPipeDelimited(r'counts', allowEmpty: true),
                );
              }
            '''),
          ),
        );
      });

      test('map with complex value type throws the unsupported-complex-value '
          'exception', () {
        final parameter = createParameter(
          name: 'nested',
          rawName: 'nested',
          model: MapModel(
            valueModel: ClassModel(
              name: 'Inner',
              properties: const [],
              isDeprecated: false,
              context: context,
              examples: const [],
            ),
            context: context,
            examples: const [],
          ),
          explode: false,
          allowEmpty: true,
        );

        final codes = buildToDelimitedQueryParameterCode(
          'nested',
          parameter,
          encoding: QueryParameterEncoding.pipeDelimited,
        );

        final code = emitStatements(codes);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format('''
              void test() {
                throw EncodingException(
                  r'pipeDelimited encoding is not supported for Map types with complex values. Parameter "nested" cannot be encoded.',
                );
              }
            '''),
          ),
        );
      });

      test('explode map throws the specification-undefined exception', () {
        final parameter = createParameter(
          name: 'filter',
          rawName: 'filter',
          model: MapModel(
            valueModel: StringModel(context: context),
            context: context,
            examples: const [],
          ),
          explode: true,
          allowEmpty: true,
        );

        final codes = buildToDelimitedQueryParameterCode(
          'filter',
          parameter,
          encoding: QueryParameterEncoding.pipeDelimited,
          explode: true,
        );

        final code = emitStatements(codes);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format('''
              void test() {
                throw EncodingException(
                  r'Parameter filter: pipeDelimited encoding of objects with explode: true is not defined by the specification',
                );
              }
            '''),
          ),
        );
      });
    });

    group('composite parameters', () {
      OneOfModel allSimpleOneOf() => OneOfModel(
        name: 'SimpleVariant',
        isDeprecated: false,
        models: {
          (discriminatorValue: null, model: StringModel(context: context)),
          (discriminatorValue: null, model: IntegerModel(context: context)),
        },
        context: context,
        examples: const [],
      );

      OneOfModel allComplexOneOf() => OneOfModel(
        name: 'ComplexVariant',
        isDeprecated: false,
        models: {
          (
            discriminatorValue: null,
            model: ClassModel(
              name: 'ClassA',
              properties: const [],
              isDeprecated: false,
              context: context,
              examples: const [],
            ),
          ),
          (
            discriminatorValue: null,
            model: ClassModel(
              name: 'ClassB',
              properties: const [],
              isDeprecated: false,
              context: context,
              examples: const [],
            ),
          ),
        },
        context: context,
        examples: const [],
      );

      OneOfModel mixedOneOf() => OneOfModel(
        name: 'MixedVariant',
        isDeprecated: false,
        models: {
          (discriminatorValue: null, model: StringModel(context: context)),
          (
            discriminatorValue: null,
            model: ClassModel(
              name: 'ClassA',
              properties: const [],
              isDeprecated: false,
              context: context,
              examples: const [],
            ),
          ),
        },
        context: context,
        examples: const [],
      );

      test('all-simple oneOf flattens via parameterProperties '
          '(pipeDelimited)', () {
        final parameter = createParameter(
          name: 'variant',
          rawName: 'variant',
          model: allSimpleOneOf(),
          explode: false,
          allowEmpty: true,
        );

        final codes = buildToDelimitedQueryParameterCode(
          'variant',
          parameter,
          encoding: QueryParameterEncoding.pipeDelimited,
        );

        final code = emitStatements(codes);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format(r'''
              void test() {
                _$entries.addAll(
                  variant
                      .parameterProperties(allowEmpty: true)
                      .toPipeDelimited(r'variant', allowEmpty: true),
                );
              }
            '''),
          ),
        );
      });

      test('all-complex oneOf flattens via parameterProperties '
          '(pipeDelimited)', () {
        final parameter = createParameter(
          name: 'variant',
          rawName: 'variant',
          model: allComplexOneOf(),
          explode: false,
          allowEmpty: true,
        );

        final codes = buildToDelimitedQueryParameterCode(
          'variant',
          parameter,
          encoding: QueryParameterEncoding.pipeDelimited,
        );

        final code = emitStatements(codes);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format(r'''
              void test() {
                _$entries.addAll(
                  variant
                      .parameterProperties(allowEmpty: true)
                      .toPipeDelimited(r'variant', allowEmpty: true),
                );
              }
            '''),
          ),
        );
      });

      test('mixed oneOf flattens via parameterProperties '
          '(spaceDelimited)', () {
        final parameter = createParameter(
          name: 'variant',
          rawName: 'variant',
          model: mixedOneOf(),
          explode: false,
          allowEmpty: true,
        );

        final codes = buildToDelimitedQueryParameterCode(
          'variant',
          parameter,
          encoding: QueryParameterEncoding.spaceDelimited,
        );

        final code = emitStatements(codes);
        expect(
          collapseWhitespace(code),
          collapseWhitespace(
            format(r'''
              void test() {
                _$entries.addAll(
                  variant
                      .parameterProperties(allowEmpty: true)
                      .toSpaceDelimited(r'variant', allowEmpty: true),
                );
              }
            '''),
          ),
        );
      });
    });
  });
}
