import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/to_form_query_parameter_expression_generator.dart';

void main() {
  group('buildToFormQueryParameterCode', () {
    late Context context;
    late DartEmitter emitter;

    final format = DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    ).format;

    setUp(() {
      context = Context.initial();
      emitter = DartEmitter(useNullSafetySyntax: true);
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
      test('generates encoding exception for MapModel', () {
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

        final method = Method(
          (b) => b
            ..name = 'test'
            ..body = Block.of(codes),
        );
        final generated = format(method.accept(emitter).toString());

        expect(
          collapseWhitespace(generated),
          contains(
            collapseWhitespace(
              "throw EncodingException('Map types cannot be"
              " form query encoded.')",
            ),
          ),
        );
      });
    });
  });
}
