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

  group('isMapValueTypeSimplyEncodable', () {
    test('StringModel is encodable', () {
      expect(
        isMapValueTypeSimplyEncodable(StringModel(context: context)),
        isTrue,
      );
    });

    test('IntegerModel is encodable', () {
      expect(
        isMapValueTypeSimplyEncodable(IntegerModel(context: context)),
        isTrue,
      );
    });

    test('DoubleModel is encodable', () {
      expect(
        isMapValueTypeSimplyEncodable(DoubleModel(context: context)),
        isTrue,
      );
    });

    test('NumberModel is encodable', () {
      expect(
        isMapValueTypeSimplyEncodable(NumberModel(context: context)),
        isTrue,
      );
    });

    test('BooleanModel is encodable', () {
      expect(
        isMapValueTypeSimplyEncodable(BooleanModel(context: context)),
        isTrue,
      );
    });

    test('DecimalModel is encodable', () {
      expect(
        isMapValueTypeSimplyEncodable(DecimalModel(context: context)),
        isTrue,
      );
    });

    test('UriModel is encodable', () {
      expect(
        isMapValueTypeSimplyEncodable(UriModel(context: context)),
        isTrue,
      );
    });

    test('DateModel is encodable', () {
      expect(
        isMapValueTypeSimplyEncodable(DateModel(context: context)),
        isTrue,
      );
    });

    test('DateTimeModel is encodable', () {
      expect(
        isMapValueTypeSimplyEncodable(DateTimeModel(context: context)),
        isTrue,
      );
    });

    test('EnumModel<String> is encodable', () {
      final model = EnumModel<String>(
        isDeprecated: false,
        name: 'Status',
        values: {
          const EnumEntry(value: 'a'),
          const EnumEntry(value: 'b'),
        },
        isNullable: false,
        context: context,
      );
      expect(isMapValueTypeSimplyEncodable(model), isTrue);
    });

    test('EnumModel<int> is encodable', () {
      final model = EnumModel<int>(
        isDeprecated: false,
        name: 'Priority',
        values: {
          const EnumEntry(value: 1),
          const EnumEntry(value: 2),
        },
        isNullable: false,
        context: context,
      );
      expect(isMapValueTypeSimplyEncodable(model), isTrue);
    });

    test('Base64Model is encodable', () {
      expect(
        isMapValueTypeSimplyEncodable(Base64Model(context: context)),
        isTrue,
      );
    });

    test('AnyModel is encodable', () {
      expect(
        isMapValueTypeSimplyEncodable(AnyModel(context: context)),
        isTrue,
      );
    });

    test('AliasModel wrapping StringModel is encodable', () {
      final model = AliasModel(
        name: 'MyString',
        model: StringModel(context: context),
        context: context,
      );
      expect(isMapValueTypeSimplyEncodable(model), isTrue);
    });

    test('AliasModel wrapping IntegerModel is encodable', () {
      final model = AliasModel(
        name: 'MyInt',
        model: IntegerModel(context: context),
        context: context,
      );
      expect(isMapValueTypeSimplyEncodable(model), isTrue);
    });

    test('AliasModel wrapping ClassModel is not encodable', () {
      final model = AliasModel(
        name: 'MyClass',
        model: ClassModel(
          isDeprecated: false,
          name: 'User',
          properties: const [],
          context: context,
        ),
        context: context,
      );
      expect(isMapValueTypeSimplyEncodable(model), isFalse);
    });

    test('AliasModel wrapping ListModel is not encodable', () {
      final model = AliasModel(
        name: 'MyList',
        model: ListModel(
          content: StringModel(context: context),
          context: context,
        ),
        context: context,
      );
      expect(isMapValueTypeSimplyEncodable(model), isFalse);
    });

    test('AliasModel wrapping AliasModel wrapping ClassModel is not '
        'encodable', () {
      final model = AliasModel(
        name: 'Outer',
        model: AliasModel(
          name: 'Inner',
          model: ClassModel(
            isDeprecated: false,
            name: 'User',
            properties: const [],
            context: context,
          ),
          context: context,
        ),
        context: context,
      );
      expect(isMapValueTypeSimplyEncodable(model), isFalse);
    });

    test('ClassModel is not encodable', () {
      final model = ClassModel(
        isDeprecated: false,
        name: 'User',
        properties: const [],
        context: context,
      );
      expect(isMapValueTypeSimplyEncodable(model), isFalse);
    });

    test('ListModel is not encodable', () {
      final model = ListModel(
        content: StringModel(context: context),
        context: context,
      );
      expect(isMapValueTypeSimplyEncodable(model), isFalse);
    });

    test('nested MapModel is not encodable', () {
      final model = MapModel(
        valueModel: StringModel(context: context),
        context: context,
      );
      expect(isMapValueTypeSimplyEncodable(model), isFalse);
    });

    test('BinaryModel is not encodable', () {
      expect(
        isMapValueTypeSimplyEncodable(BinaryModel(context: context)),
        isFalse,
      );
    });

    test('NeverModel is not encodable', () {
      expect(
        isMapValueTypeSimplyEncodable(NeverModel(context: context)),
        isFalse,
      );
    });

    test('OneOfModel of all-simple members is not encodable', () {
      final model = OneOfModel(
        isDeprecated: false,
        name: 'StringOrInt',
        models: {
          (discriminatorValue: null, model: StringModel(context: context)),
          (discriminatorValue: null, model: IntegerModel(context: context)),
        },
        context: context,
      );
      expect(isMapValueTypeSimplyEncodable(model), isFalse);
    });

    test('OneOfModel of mixed members is not encodable', () {
      final model = OneOfModel(
        isDeprecated: false,
        name: 'StringOrClass',
        models: {
          (discriminatorValue: null, model: StringModel(context: context)),
          (
            discriminatorValue: null,
            model: ClassModel(
              isDeprecated: false,
              name: 'User',
              properties: const [],
              context: context,
            ),
          ),
        },
        context: context,
      );
      expect(isMapValueTypeSimplyEncodable(model), isFalse);
    });

    test('AllOfModel of all-simple members is not encodable', () {
      final model = AllOfModel(
        isDeprecated: false,
        name: 'StringOnly',
        models: {StringModel(context: context)},
        context: context,
      );
      expect(isMapValueTypeSimplyEncodable(model), isFalse);
    });

    test('AnyOfModel of all-simple members is not encodable', () {
      final model = AnyOfModel(
        isDeprecated: false,
        name: 'StringOrIntOrBool',
        models: {
          (discriminatorValue: null, model: StringModel(context: context)),
          (discriminatorValue: null, model: IntegerModel(context: context)),
          (discriminatorValue: null, model: BooleanModel(context: context)),
        },
        context: context,
      );
      expect(isMapValueTypeSimplyEncodable(model), isFalse);
    });
  });

  group('predicate / builder parity', () {
    /// Drift guard: predicate and builder must agree on every model.
    /// Anything else re-introduces the path-suffix throw bug.
    void expectParity(Model valueModel, {required String label}) {
      final mapModel = MapModel(valueModel: valueModel, context: context);
      final built = buildMapToStringMapExpression(
        refer('x'),
        mapModel,
        isNullable: false,
      );
      final predicate = isMapValueTypeSimplyEncodable(valueModel);
      if (built != null) {
        expect(
          predicate,
          isTrue,
          reason:
              '$label: builder produced an expression but predicate said '
              'unsupported',
        );
      } else {
        expect(
          predicate,
          isFalse,
          reason:
              '$label: predicate says supported but builder returned null',
        );
      }
    }

    test('all supported and unsupported models agree', () {
      expectParity(StringModel(context: context), label: 'StringModel');
      expectParity(IntegerModel(context: context), label: 'IntegerModel');
      expectParity(DoubleModel(context: context), label: 'DoubleModel');
      expectParity(NumberModel(context: context), label: 'NumberModel');
      expectParity(BooleanModel(context: context), label: 'BooleanModel');
      expectParity(DecimalModel(context: context), label: 'DecimalModel');
      expectParity(UriModel(context: context), label: 'UriModel');
      expectParity(DateModel(context: context), label: 'DateModel');
      expectParity(DateTimeModel(context: context), label: 'DateTimeModel');
      expectParity(Base64Model(context: context), label: 'Base64Model');
      expectParity(AnyModel(context: context), label: 'AnyModel');
      expectParity(NeverModel(context: context), label: 'NeverModel');
      expectParity(BinaryModel(context: context), label: 'BinaryModel');

      expectParity(
        EnumModel<String>(
          isDeprecated: false,
          name: 'StatusE',
          values: {const EnumEntry(value: 'a')},
          isNullable: false,
          context: context,
        ),
        label: 'EnumModel<String>',
      );
      expectParity(
        EnumModel<int>(
          isDeprecated: false,
          name: 'PriorityE',
          values: {const EnumEntry(value: 1)},
          isNullable: false,
          context: context,
        ),
        label: 'EnumModel<int>',
      );

      expectParity(
        AliasModel(
          name: 'AliasOfString',
          model: StringModel(context: context),
          context: context,
        ),
        label: 'AliasModel(StringModel)',
      );
      expectParity(
        AliasModel(
          name: 'AliasOfClass',
          model: ClassModel(
            isDeprecated: false,
            name: 'User',
            properties: const [],
            context: context,
          ),
          context: context,
        ),
        label: 'AliasModel(ClassModel)',
      );

      expectParity(
        ClassModel(
          isDeprecated: false,
          name: 'User2',
          properties: const [],
          context: context,
        ),
        label: 'ClassModel',
      );
      expectParity(
        ListModel(content: StringModel(context: context), context: context),
        label: 'ListModel',
      );
      expectParity(
        MapModel(valueModel: StringModel(context: context), context: context),
        label: 'nested MapModel',
      );
      expectParity(
        OneOfModel(
          isDeprecated: false,
          name: 'OneOfAllSimple',
          models: {
            (discriminatorValue: null, model: StringModel(context: context)),
            (discriminatorValue: null, model: IntegerModel(context: context)),
          },
          context: context,
        ),
        label: 'OneOfModel(all-simple)',
      );
      expectParity(
        AllOfModel(
          isDeprecated: false,
          name: 'AllOfAllSimple',
          models: {StringModel(context: context)},
          context: context,
        ),
        label: 'AllOfModel(all-simple)',
      );
      expectParity(
        AnyOfModel(
          isDeprecated: false,
          name: 'AnyOfAllSimple',
          models: {
            (discriminatorValue: null, model: StringModel(context: context)),
            (discriminatorValue: null, model: BooleanModel(context: context)),
          },
          context: context,
        ),
        label: 'AnyOfModel(all-simple)',
      );
    });
  });
}
