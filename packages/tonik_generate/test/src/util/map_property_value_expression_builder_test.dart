import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/map_property_value_expression_builder.dart';

void main() {
  late Context context;
  late DartEmitter emitter;

  final format = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  ).format;

  setUp(() {
    context = Context.initial();
    emitter = DartEmitter(useNullSafetySyntax: true);
  });

  String methodBody(Expression expression) => format(
    Method(
      (b) => b
        ..name = 'test'
        ..body = declareFinal('result').assign(expression).statement,
    ).accept(emitter).toString(),
  );

  test('integer values use the shared scalar plan', () {
    final conversion = buildMapPropertyValueConversion(
      refer('values'),
      MapModel(
        valueModel: IntegerModel(context: context),
        context: context,
        examples: const [],
      ),
      isNullable: false,
      context: 'counts',
    );

    expect(conversion, isA<SupportedMapPropertyValueConversion>());
    final expression =
        (conversion as SupportedMapPropertyValueConversion).expression;
    expect(
      collapseWhitespace(methodBody(expression)),
      collapseWhitespace(
        format('''
          test() {
            final result = values.map(
              (k, v) => MapEntry(
                k,
                PropertyValue.scalar(v.toString()),
              ),
            );
          }
        '''),
      ),
    );
  });

  test('Any values omit null entries and use a safe context literal', () {
    final conversion = buildMapPropertyValueConversion(
      refer('values'),
      MapModel(
        valueModel: AnyModel(context: context),
        context: context,
        examples: const [],
      ),
      isNullable: false,
      context: r'''parameter "quo'te" \ $value''',
    );

    expect(conversion, isA<SupportedMapPropertyValueConversion>());
    final expression =
        (conversion as SupportedMapPropertyValueConversion).expression;
    expect(
      collapseWhitespace(methodBody(expression)),
      collapseWhitespace(
        format(r'''
          test() {
            final result = Map.fromEntries(
              values.entries
                  .where((e) => e.value != null)
                  .map(
                    (e) => MapEntry(
                      e.key,
                      PropertyValue.scalar(
                        encodeUnknownFlatScalar(
                          e.value!,
                          context: r"""parameter "quo'te" \ $value""",
                        ),
                      ),
                    ),
                  ),
            );
          }
        '''),
      ),
    );
  });

  test('nullable typed values are omitted before scalar conversion', () {
    final conversion = buildMapPropertyValueConversion(
      refer('values'),
      MapModel(
        valueModel: StringModel(context: context),
        isValueNullable: true,
        context: context,
        examples: const [],
      ),
      isNullable: false,
      context: 'labels',
    );

    expect(conversion, isA<SupportedMapPropertyValueConversion>());
    final expression =
        (conversion as SupportedMapPropertyValueConversion).expression;
    expect(
      collapseWhitespace(methodBody(expression)),
      collapseWhitespace(
        format('''
          test() {
            final result = Map.fromEntries(
              values.entries
                  .where((e) => e.value != null)
                  .map(
                    (e) => MapEntry(
                      e.key,
                      PropertyValue.scalar(e.value!),
                    ),
                  ),
            );
          }
        '''),
      ),
    );
  });

  test('list values return one canonical unsupported result', () {
    final conversion = buildMapPropertyValueConversion(
      refer('values'),
      MapModel(
        valueModel: ListModel(
          content: StringModel(context: context),
          context: context,
          examples: const [],
        ),
        context: context,
        examples: const [],
      ),
      isNullable: false,
      context: 'tags',
    );

    expect(conversion, isA<UnsupportedMapPropertyValueConversion>());
    expect(
      (conversion as UnsupportedMapPropertyValueConversion).reason,
      'ListModel values have no flat map representation',
    );
  });
}
