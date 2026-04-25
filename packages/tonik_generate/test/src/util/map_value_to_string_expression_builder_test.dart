import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/map_value_to_string_expression_builder.dart';

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

  /// Helper: wraps an expression in a method for formatting.
  String formatExpression(Expression expr) {
    final method = Method(
      (b) => b
        ..name = 'test'
        ..body = declareFinal('result').assign(expr).statement,
    );
    return format(method.accept(emitter).toString());
  }

  group('buildMapToStringMapExpression', () {
    group('StringModel values', () {
      test('returns receiver unchanged', () {
        final model = MapModel(
          valueModel: StringModel(context: context),
          context: context,
        );

        final result = buildMapToStringMapExpression(
          refer('myMap'),
          model,
          isNullable: false,
        );

        expect(result, isNotNull);
        expect(result!.accept(emitter).toString(), 'myMap');
      });
    });

    group('IntegerModel values', () {
      test('emits .map with v.toString()', () {
        final model = MapModel(
          valueModel: IntegerModel(context: context),
          context: context,
        );

        final result = buildMapToStringMapExpression(
          refer('myMap'),
          model,
          isNullable: false,
        );

        expect(result, isNotNull);
        final generated = formatExpression(result!);
        final expected = format('''
          test() {
            final result = myMap.map((k, v) => MapEntry(k, v.toString()));
          }
        ''');
        expect(collapseWhitespace(generated), collapseWhitespace(expected));
      });
    });

    group('DoubleModel values', () {
      test('emits .map with v.toString()', () {
        final model = MapModel(
          valueModel: DoubleModel(context: context),
          context: context,
        );

        final result = buildMapToStringMapExpression(
          refer('myMap'),
          model,
          isNullable: false,
        );

        expect(result, isNotNull);
        final generated = formatExpression(result!);
        final expected = format('''
          test() {
            final result = myMap.map((k, v) => MapEntry(k, v.toString()));
          }
        ''');
        expect(collapseWhitespace(generated), collapseWhitespace(expected));
      });
    });

    group('NumberModel values', () {
      test('emits .map with v.toString()', () {
        final model = MapModel(
          valueModel: NumberModel(context: context),
          context: context,
        );

        final result = buildMapToStringMapExpression(
          refer('myMap'),
          model,
          isNullable: false,
        );

        expect(result, isNotNull);
        final generated = formatExpression(result!);
        final expected = format('''
          test() {
            final result = myMap.map((k, v) => MapEntry(k, v.toString()));
          }
        ''');
        expect(collapseWhitespace(generated), collapseWhitespace(expected));
      });
    });

    group('BooleanModel values', () {
      test('emits .map with v.toString()', () {
        final model = MapModel(
          valueModel: BooleanModel(context: context),
          context: context,
        );

        final result = buildMapToStringMapExpression(
          refer('myMap'),
          model,
          isNullable: false,
        );

        expect(result, isNotNull);
        final generated = formatExpression(result!);
        final expected = format('''
          test() {
            final result = myMap.map((k, v) => MapEntry(k, v.toString()));
          }
        ''');
        expect(collapseWhitespace(generated), collapseWhitespace(expected));
      });
    });

    group('DateTimeModel values', () {
      test('emits .map with v.toTimeZonedIso8601String()', () {
        final model = MapModel(
          valueModel: DateTimeModel(context: context),
          context: context,
        );

        final result = buildMapToStringMapExpression(
          refer('myMap'),
          model,
          isNullable: false,
        );

        expect(result, isNotNull);
        final generated = formatExpression(result!);
        final expected = format('''
          test() {
            final result = myMap.map(
              (k, v) => MapEntry(k, v.toTimeZonedIso8601String()),
            );
          }
        ''');
        expect(collapseWhitespace(generated), collapseWhitespace(expected));
      });
    });

    group('DateModel values', () {
      test('emits .map with v.toString()', () {
        final model = MapModel(
          valueModel: DateModel(context: context),
          context: context,
        );

        final result = buildMapToStringMapExpression(
          refer('myMap'),
          model,
          isNullable: false,
        );

        expect(result, isNotNull);
        final generated = formatExpression(result!);
        final expected = format('''
          test() {
            final result = myMap.map((k, v) => MapEntry(k, v.toString()));
          }
        ''');
        expect(collapseWhitespace(generated), collapseWhitespace(expected));
      });
    });

    group('DecimalModel values', () {
      test('emits .map with v.toString()', () {
        final model = MapModel(
          valueModel: DecimalModel(context: context),
          context: context,
        );

        final result = buildMapToStringMapExpression(
          refer('myMap'),
          model,
          isNullable: false,
        );

        expect(result, isNotNull);
        final generated = formatExpression(result!);
        final expected = format('''
          test() {
            final result = myMap.map((k, v) => MapEntry(k, v.toString()));
          }
        ''');
        expect(collapseWhitespace(generated), collapseWhitespace(expected));
      });
    });

    group('UriModel values', () {
      test('emits .map with v.toString()', () {
        final model = MapModel(
          valueModel: UriModel(context: context),
          context: context,
        );

        final result = buildMapToStringMapExpression(
          refer('myMap'),
          model,
          isNullable: false,
        );

        expect(result, isNotNull);
        final generated = formatExpression(result!);
        final expected = format('''
          test() {
            final result = myMap.map((k, v) => MapEntry(k, v.toString()));
          }
        ''');
        expect(collapseWhitespace(generated), collapseWhitespace(expected));
      });
    });

    group('EnumModel<String> values', () {
      test('emits .map with v.toJson()', () {
        final model = MapModel(
          valueModel: EnumModel<String>(
            isDeprecated: false,
            name: 'Status',
            values: {
              const EnumEntry(value: 'active'),
              const EnumEntry(value: 'inactive'),
            },
            isNullable: false,
            context: context,
          ),
          context: context,
        );

        final result = buildMapToStringMapExpression(
          refer('myMap'),
          model,
          isNullable: false,
        );

        expect(result, isNotNull);
        final generated = formatExpression(result!);
        final expected = format('''
          test() {
            final result = myMap.map((k, v) => MapEntry(k, v.toJson()));
          }
        ''');
        expect(collapseWhitespace(generated), collapseWhitespace(expected));
      });
    });

    group('EnumModel<int> values (non-string)', () {
      test('emits .map with v.toJson().toString()', () {
        final model = MapModel(
          valueModel: EnumModel<int>(
            isDeprecated: false,
            name: 'Priority',
            values: {
              const EnumEntry(value: 1),
              const EnumEntry(value: 2),
            },
            isNullable: false,
            context: context,
          ),
          context: context,
        );

        final result = buildMapToStringMapExpression(
          refer('myMap'),
          model,
          isNullable: false,
        );

        expect(result, isNotNull);
        final generated = formatExpression(result!);
        final expected = format('''
          test() {
            final result = myMap.map(
              (k, v) => MapEntry(k, v.toJson().toString()),
            );
          }
        ''');
        expect(collapseWhitespace(generated), collapseWhitespace(expected));
      });
    });

    group('Base64Model values', () {
      test('emits .map with v.toBase64String()', () {
        final model = MapModel(
          valueModel: Base64Model(context: context),
          context: context,
        );

        final result = buildMapToStringMapExpression(
          refer('myMap'),
          model,
          isNullable: false,
        );

        expect(result, isNotNull);
        final generated = formatExpression(result!);
        final expected = format('''
          test() {
            final result = myMap.map(
              (k, v) => MapEntry(k, v.toBase64String()),
            );
          }
        ''');
        expect(collapseWhitespace(generated), collapseWhitespace(expected));
      });
    });

    group('AnyModel values', () {
      test('emits .map with encodeAnyValueToString(v)', () {
        final model = MapModel(
          valueModel: AnyModel(context: context),
          context: context,
        );

        final result = buildMapToStringMapExpression(
          refer('myMap'),
          model,
          isNullable: false,
        );

        expect(result, isNotNull);
        final generated = formatExpression(result!);
        final expected = format('''
          test() {
            final result = myMap.map(
              (k, v) => MapEntry(
                k, encodeAnyValueToString(v, allowEmpty: false),
              ),
            );
          }
        ''');
        expect(collapseWhitespace(generated), collapseWhitespace(expected));
      });
    });

    group('AliasModel values', () {
      test('unwraps alias to StringModel and returns identity', () {
        final model = MapModel(
          valueModel: AliasModel(
            name: 'MyString',
            model: StringModel(context: context),
            context: context,
          ),
          context: context,
        );

        final result = buildMapToStringMapExpression(
          refer('myMap'),
          model,
          isNullable: false,
        );

        expect(result, isNotNull);
        expect(result!.accept(emitter).toString(), 'myMap');
      });

      test('unwraps alias to IntegerModel and emits .map', () {
        final model = MapModel(
          valueModel: AliasModel(
            name: 'MyInt',
            model: IntegerModel(context: context),
            context: context,
          ),
          context: context,
        );

        final result = buildMapToStringMapExpression(
          refer('myMap'),
          model,
          isNullable: false,
        );

        expect(result, isNotNull);
        final generated = formatExpression(result!);
        final expected = format('''
          test() {
            final result = myMap.map((k, v) => MapEntry(k, v.toString()));
          }
        ''');
        expect(collapseWhitespace(generated), collapseWhitespace(expected));
      });
    });

    group('unsupported types return null', () {
      test('ClassModel returns null', () {
        final model = MapModel(
          valueModel: ClassModel(
            isDeprecated: false,
            name: 'User',
            properties: [],
            context: context,
          ),
          context: context,
        );

        final result = buildMapToStringMapExpression(
          refer('myMap'),
          model,
          isNullable: false,
        );

        expect(result, isNull);
      });

      test('ListModel returns null', () {
        final model = MapModel(
          valueModel: ListModel(
            content: StringModel(context: context),
            context: context,
          ),
          context: context,
        );

        final result = buildMapToStringMapExpression(
          refer('myMap'),
          model,
          isNullable: false,
        );

        expect(result, isNull);
      });

      test('nested MapModel returns null', () {
        final model = MapModel(
          valueModel: MapModel(
            valueModel: StringModel(context: context),
            context: context,
          ),
          context: context,
        );

        final result = buildMapToStringMapExpression(
          refer('myMap'),
          model,
          isNullable: false,
        );

        expect(result, isNull);
      });

      test('BinaryModel returns null', () {
        final model = MapModel(
          valueModel: BinaryModel(context: context),
          context: context,
        );

        final result = buildMapToStringMapExpression(
          refer('myMap'),
          model,
          isNullable: false,
        );

        expect(result, isNull);
      });

      test('NeverModel returns null', () {
        final model = MapModel(
          valueModel: NeverModel(context: context),
          context: context,
        );

        final result = buildMapToStringMapExpression(
          refer('myMap'),
          model,
          isNullable: false,
        );

        expect(result, isNull);
      });
    });

    group('nullable map (isNullable=true)', () {
      test('emits null-safe .map for IntegerModel values', () {
        final model = MapModel(
          valueModel: IntegerModel(context: context),
          context: context,
          isNullable: true,
        );

        final result = buildMapToStringMapExpression(
          refer('myMap'),
          model,
          isNullable: true,
        );

        expect(result, isNotNull);
        final generated = formatExpression(result!);
        final expected = format('''
          test() {
            final result = myMap?.map((k, v) => MapEntry(k, v.toString()));
          }
        ''');
        expect(collapseWhitespace(generated), collapseWhitespace(expected));
      });
    });

    group('nullable value type', () {
      test('emits null check for nullable IntegerModel values', () {
        final model = MapModel(
          valueModel: AliasModel(
            name: 'NullableInt',
            model: IntegerModel(context: context),
            context: context,
            isNullable: true,
          ),
          context: context,
        );

        final result = buildMapToStringMapExpression(
          refer('myMap'),
          model,
          isNullable: false,
        );

        expect(result, isNotNull);
        final generated = formatExpression(result!);
        final expected = format('''
          test() {
            final result = myMap.map(
              (k, v) => MapEntry(k, v == null ? '' : v.toString()),
            );
          }
        ''');
        expect(collapseWhitespace(generated), collapseWhitespace(expected));
      });

      test('emits null check for nullable DateTimeModel values', () {
        final model = MapModel(
          valueModel: AliasModel(
            name: 'NullableDateTime',
            model: DateTimeModel(context: context),
            context: context,
            isNullable: true,
          ),
          context: context,
        );

        final result = buildMapToStringMapExpression(
          refer('myMap'),
          model,
          isNullable: false,
        );

        expect(result, isNotNull);
        final generated = formatExpression(result!);
        final expected = format('''
          test() {
            final result = myMap.map(
              (k, v) => MapEntry(
                k, v == null ? '' : v.toTimeZonedIso8601String(),
              ),
            );
          }
        ''');
        expect(collapseWhitespace(generated), collapseWhitespace(expected));
      });
    });
  });
}
