import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/core_prefixed_allocator.dart';
import 'package:tonik_generate/src/util/to_form_query_parameter_expression_generator.dart';

void main() {
  group('buildToFormQueryParameterCode', () {
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

    QueryParameterObject createParameter({
      required String name,
      required String rawName,
      required Model model,
      required bool explode,
      required bool allowEmpty,
    }) {
      return QueryParameterObject(
        name: name,
        rawName: rawName,
        description: null,
        model: model,
        isRequired: true,
        isDeprecated: false,
        encoding: QueryParameterEncoding.form,
        explode: explode,
        allowEmptyValue: allowEmpty,
        allowReserved: false,
        context: context,
      );
    }

    String emitCodes(List<Code> codes) {
      final method = Method(
        (b) => b
          ..name = 'test'
          ..body = Block.of(codes),
      );
      return format(method.accept(scopedEmitter).toString());
    }

    group('rawName with special characters', () {
      test('generates valid code when rawName contains single quote', () {
        final parameter = createParameter(
          name: 'filterParam',
          rawName: "filter's",
          model: StringModel(context: context),
          explode: false,
          allowEmpty: true,
        );

        final codes = buildToFormQueryParameterCode(
          'filterParam',
          parameter,
        );

        final method = Method(
          (b) => b
            ..name = 'test'
            ..body = Block.of(codes),
        );

        // Should not throw when formatting (valid Dart syntax)
        final generated = format(method.accept(emitter).toString());
        expect(generated, contains("filter's"));
      });

      test('generates valid code when rawName contains double quote', () {
        final parameter = createParameter(
          name: 'filterParam',
          rawName: 'filter"s',
          model: StringModel(context: context),
          explode: false,
          allowEmpty: true,
        );

        final codes = buildToFormQueryParameterCode(
          'filterParam',
          parameter,
        );

        final method = Method(
          (b) => b
            ..name = 'test'
            ..body = Block.of(codes),
        );

        final generated = format(method.accept(emitter).toString());
        expect(generated, contains('filter"s'));
      });
    });

    group('MapModel', () {
      test('generates toParameterMap().toForm() for MapModel', () {
        final parameter = createParameter(
          name: 'mapParam',
          rawName: 'mapParam',
          model: MapModel(
            valueModel: StringModel(context: context),
            context: context,
          ),
          explode: false,
          allowEmpty: true,
        );

        final codes = buildToFormQueryParameterCode(
          'mapParam',
          parameter,
        );

        final generated = emitCodes(codes);

        expect(
          collapseWhitespace(generated),
          contains(
            collapseWhitespace(
              'mapParam.toParameterMap().toForm('
              'explode: false, allowEmpty: true)',
            ),
          ),
        );
      });
    });

    group('Base64Model', () {
      test('generates toBase64String().toForm() for Base64Model', () {
        final parameter = createParameter(
          name: 'base64Param',
          rawName: 'base64Param',
          model: Base64Model(context: context),
          explode: false,
          allowEmpty: true,
        );

        final codes = buildToFormQueryParameterCode(
          'base64Param',
          parameter,
        );

        final generated = emitCodes(codes);

        expect(
          collapseWhitespace(generated),
          contains(
            collapseWhitespace(
              'base64Param.toBase64String().toForm(',
            ),
          ),
        );
        expect(
          collapseWhitespace(generated),
          contains(
            collapseWhitespace('explode: false, allowEmpty: true'),
          ),
        );
      });
    });

    group('unsupported model types generate runtime throws', () {

      test('BinaryModel generates encoding exception', () {
        final parameter = createParameter(
          name: 'binaryParam',
          rawName: 'binaryParam',
          model: BinaryModel(context: context),
          explode: false,
          allowEmpty: true,
        );

        final codes = buildToFormQueryParameterCode(
          'binaryParam',
          parameter,
        );

        final generated = emitCodes(codes);

        expect(
          collapseWhitespace(generated),
          contains(
            collapseWhitespace(
              '''throw _i1.EncodingException('Binary data cannot be form-encoded.')''',
            ),
          ),
        );
      });

      test('NeverModel generates encoding exception', () {
        final parameter = createParameter(
          name: 'neverParam',
          rawName: 'neverParam',
          model: NeverModel(context: context),
          explode: false,
          allowEmpty: true,
        );

        final codes = buildToFormQueryParameterCode(
          'neverParam',
          parameter,
        );

        final generated = emitCodes(codes);

        expect(
          collapseWhitespace(generated),
          contains(
            collapseWhitespace(
              '''throw _i1.EncodingException( 'Cannot encode NeverModel - this type does not permit any value.', );''',
            ),
          ),
        );
      });

      test(
        'List with BinaryModel content generates encoding exception',
        () {
          final parameter = createParameter(
            name: 'binaryListParam',
            rawName: 'binaryListParam',
            model: ListModel(
              content: BinaryModel(context: context),
              context: context,
            ),
            explode: false,
            allowEmpty: true,
          );

          final codes = buildToFormQueryParameterCode(
            'binaryListParam',
            parameter,
          );

          final generated = emitCodes(codes);

          expect(
            collapseWhitespace(generated),
            contains(
              collapseWhitespace(
                '''throw _i1.EncodingException('Binary data cannot be form-encoded.')''',
              ),
            ),
          );
        },
      );

      test(
        'List with MapModel content generates map with '
        'toParameterMap().toForm()',
        () {
          final parameter = createParameter(
            name: 'mapListParam',
            rawName: 'mapListParam',
            model: ListModel(
              content: MapModel(
                valueModel: IntegerModel(context: context),
                context: context,
              ),
              context: context,
            ),
            explode: false,
            allowEmpty: true,
          );

          final codes = buildToFormQueryParameterCode(
            'mapListParam',
            parameter,
          );

          final generated = emitCodes(codes);

          expect(
            collapseWhitespace(generated),
            contains(
              collapseWhitespace(
                // Adjacent strings are concatenated to form a single
                // expected value for comparison.
                // ignore: missing_whitespace_between_adjacent_strings
                '.map((e) => e.toParameterMap().toForm('
                'explode: false, allowEmpty: true))',
              ),
            ),
          );
          expect(
            collapseWhitespace(generated),
            contains(
              collapseWhitespace('.toList()'),
            ),
          );
        },
      );

      test(
        'List with Base64Model content generates map with '
        'toBase64String().toForm()',
        () {
          final parameter = createParameter(
            name: 'base64ListParam',
            rawName: 'base64ListParam',
            model: ListModel(
              content: Base64Model(context: context),
              context: context,
            ),
            explode: false,
            allowEmpty: true,
          );

          final codes = buildToFormQueryParameterCode(
            'base64ListParam',
            parameter,
          );

          final generated = emitCodes(codes);

          expect(
            collapseWhitespace(generated),
            contains(
              collapseWhitespace(
                // Adjacent strings are concatenated to form a single
                // expected value for comparison.
                // ignore: missing_whitespace_between_adjacent_strings
                '.map((e) => e.toBase64String().toForm('
                'explode: false, allowEmpty: true))',
              ),
            ),
          );
          expect(
            collapseWhitespace(generated),
            contains(
              collapseWhitespace('.toList()'),
            ),
          );
        },
      );

      test(
        'List with NeverModel content generates encoding exception',
        () {
          final parameter = createParameter(
            name: 'neverListParam',
            rawName: 'neverListParam',
            model: ListModel(
              content: NeverModel(context: context),
              context: context,
            ),
            explode: false,
            allowEmpty: true,
          );

          final codes = buildToFormQueryParameterCode(
            'neverListParam',
            parameter,
          );

          final generated = emitCodes(codes);

          expect(
            collapseWhitespace(generated),
            contains(
              collapseWhitespace(
                '''throw _i1.EncodingException( 'Cannot encode List<NeverModel> - this type does not permit any value.', );''',
              ),
            ),
          );
        },
      );

      test(
        'AliasModel wrapping BinaryModel generates encoding exception',
        () {
          final parameter = createParameter(
            name: 'aliasParam',
            rawName: 'aliasParam',
            model: AliasModel(
              name: 'MyAlias',
              model: BinaryModel(context: context),
              context: context,
            ),
            explode: false,
            allowEmpty: true,
          );

          final codes = buildToFormQueryParameterCode(
            'aliasParam',
            parameter,
          );

          final generated = emitCodes(codes);

          expect(
            collapseWhitespace(generated),
            contains(
              collapseWhitespace(
                '''throw _i1.EncodingException( 'Unsupported model type for form query encoding.', );''',
              ),
            ),
          );
        },
      );

      test(
        'AliasModel wrapping ListModel with BinaryModel content '
        'generates encoding exception',
        () {
          final parameter = createParameter(
            name: 'aliasListParam',
            rawName: 'aliasListParam',
            model: AliasModel(
              name: 'MyAlias',
              model: ListModel(
                content: BinaryModel(context: context),
                context: context,
              ),
              context: context,
            ),
            explode: false,
            allowEmpty: true,
          );

          final codes = buildToFormQueryParameterCode(
            'aliasListParam',
            parameter,
          );

          final generated = emitCodes(codes);

          expect(
            collapseWhitespace(generated),
            contains(
              collapseWhitespace(
                '''throw _i1.EncodingException( 'Unsupported model type for form query encoding.', );''',
              ),
            ),
          );
        },
      );
    });

    group('nullable list content', () {
      test(
        'generates e?.toForm for exploded list '
        'with nullable content model',
        () {
          final parameter = createParameter(
            name: 'queryType',
            rawName: 'queryType',
            model: ListModel(
              content: AliasModel(
                name: 'NullableType',
                model: EnumModel<String>(
                  name: 'MyEnum',
                  values: {const EnumEntry(value: 'a')},
                  isNullable: false,
                  isDeprecated: false,
                  context: context,
                ),
                context: context,
                isNullable: true,
              ),
              context: context,
            ),
            explode: true,
            allowEmpty: false,
          );

          final codes = buildToFormQueryParameterCode(
            'queryType',
            parameter,
            explode: true,
            allowEmpty: false,
          );

          final generated = emitCodes(codes);

          const expectedBody = r'''
            test() {
              _$entries.addAll(
                queryType.map(
                  (e) => (
                    name: r'queryType',
                    value: e?.toForm(explode: true, allowEmpty: false) ?? '',
                  ),
                ),
              );
            }
          ''';

          expect(
            collapseWhitespace(generated),
            collapseWhitespace(expectedBody),
          );
        },
      );

      test(
        'generates e.toForm for exploded list '
        'with non-nullable content model',
        () {
          final parameter = createParameter(
            name: 'values',
            rawName: 'values',
            model: ListModel(
              content: IntegerModel(context: context),
              context: context,
            ),
            explode: true,
            allowEmpty: false,
          );

          final codes = buildToFormQueryParameterCode(
            'values',
            parameter,
            explode: true,
            allowEmpty: false,
          );

          final generated = emitCodes(codes);

          const expectedBody = r'''
            test() {
              _$entries.addAll(
                values.map(
                  (e) => (name: r'values',
                    value: e.toForm(explode: true, allowEmpty: false)),
                ),
              );
            }
          ''';

          expect(
            collapseWhitespace(generated),
            collapseWhitespace(expectedBody),
          );
        },
      );
    });

    group('non-exploded list with nullable alias content', () {
      test(
        'generates nullable map expression for list with nullable alias '
        'wrapping IntegerModel',
        () {
          final parameter = createParameter(
            name: 'ids',
            rawName: 'ids',
            model: ListModel(
              content: AliasModel(
                name: 'NullableInt',
                model: IntegerModel(context: context),
                context: context,
                isNullable: true,
              ),
              context: context,
            ),
            explode: false,
            allowEmpty: true,
          );

          final codes = buildToFormQueryParameterCode(
            'ids',
            parameter,
          );

          final generated = emitCodes(codes);

          const expectedBody = r'''
            test() {
              _$entries.add((
                name: r'ids',
                value: ids
                    .map((e) => e?.toForm(explode: false, allowEmpty: true))
                    .toList()
                    .toForm(explode: false, allowEmpty: true),
              ));
            }
          ''';

          expect(
            collapseWhitespace(generated),
            collapseWhitespace(expectedBody),
          );
        },
      );
    });
  });
}
