import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
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

    String emitStatements(List<Code> statements) {
      final method = Method(
        (b) => b
          ..name = 'test'
          ..returns = refer('void')
          ..lambda = false
          ..body = Block.of(statements),
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
      );
    }

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
