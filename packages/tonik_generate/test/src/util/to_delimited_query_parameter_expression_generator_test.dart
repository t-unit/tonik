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
        allowReserved: false,
        context: context,
        examples: const [],
        defaultValue: null,
      );
    }

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
                    .map(
                      (e) => e == null
                          ? ''
                          : e.uriEncode(allowEmpty: true, useQueryComponent: true),
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
                    .map(
                      (e) => e == null
                          ? ''
                          : e.uriEncode(allowEmpty: true, useQueryComponent: true),
                    )
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
  });
}
