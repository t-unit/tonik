import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/util/flat_value_codec_plan.dart';

void main() {
  late Context context;
  late DartEmitter emitter;
  late NameManager nameManager;

  final format = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  ).format;

  setUp(() {
    context = Context.initial();
    emitter = DartEmitter(useNullSafetySyntax: true);
    nameManager = NameManager(
      generator: NameGenerator(),
      stableModelSorter: StableModelSorter(),
    );
  });

  String emit(Expression expression) => expression.accept(emitter).toString();

  String methodBody(Expression expression) => format(
    Method(
      (b) => b
        ..name = 'test'
        ..body = declareFinal('result').assign(expression).statement,
    ).accept(emitter).toString(),
  );

  FlatEncodePlan encodePlan(Model model) =>
      buildFlatEncodePlan(refer('v'), model, context: 'ctx');

  FlatDecodePlan decodePlan(
    Model model, {
    FlatWireFormat format = FlatWireFormat.simple,
    bool isRequired = true,
  }) => buildFlatDecodePlan(
    refer('v'),
    model,
    format: format,
    isRequired: isRequired,
    nameManager: nameManager,
    explode: refer('explode'),
  );

  group('buildFlatEncodePlan scalar models', () {
    test('String encodes as the raw value', () {
      final plan = encodePlan(StringModel(context: context));

      expect(
        emit((plan as FlatScalarEncodePlan).value),
        'v',
      );
    });

    test('Integer, Number, Double, Boolean, Decimal, Uri, and Date encode '
        'via toString', () {
      final models = [
        IntegerModel(context: context),
        NumberModel(context: context),
        DoubleModel(context: context),
        BooleanModel(context: context),
        DecimalModel(context: context),
        UriModel(context: context),
        DateModel(context: context),
      ];

      for (final model in models) {
        final plan = encodePlan(model);
        expect(
          emit((plan as FlatScalarEncodePlan).value),
          'v.toString()',
          reason: model.runtimeType.toString(),
        );
      }
    });

    test('DateTime encodes via toTimeZonedIso8601String', () {
      final plan = encodePlan(DateTimeModel(context: context));

      expect(
        emit((plan as FlatScalarEncodePlan).value),
        'v.toTimeZonedIso8601String()',
      );
    });

    test('string enum encodes via toJson', () {
      final plan = encodePlan(
        EnumModel<String>(
          values: {const EnumEntry(value: 'a')},
          isNullable: false,
          context: context,
          isDeprecated: false,
          examples: const [],
        ),
      );

      expect(
        emit((plan as FlatScalarEncodePlan).value),
        'v.toJson()',
      );
    });

    test('integer enum encodes via toJson toString', () {
      final plan = encodePlan(
        EnumModel<int>(
          values: {const EnumEntry(value: 1)},
          isNullable: false,
          context: context,
          isDeprecated: false,
          examples: const [],
        ),
      );

      expect(
        emit((plan as FlatScalarEncodePlan).value),
        'v.toJson().toString()',
      );
    });

    test('Base64 encodes via toBase64String', () {
      final plan = encodePlan(Base64Model(context: context));

      expect(
        emit((plan as FlatScalarEncodePlan).value),
        'v.toBase64String()',
      );
    });

    test('Any encodes through the unknown-flat-scalar runtime boundary', () {
      final plan = encodePlan(AnyModel(context: context));

      expect(
        collapseWhitespace(
          methodBody((plan as FlatScalarEncodePlan).value),
        ),
        collapseWhitespace(
          format('''
            test() {
              final result = encodeUnknownFlatScalar(
                v,
                context: r'ctx',
              );
            }
          '''),
        ),
      );
    });

    test('Any uses a safe spec literal for an adversarial context', () {
      final plan = buildFlatEncodePlan(
        refer('v'),
        AnyModel(context: context),
        context: r'''parameter "quo'te" \ $value''',
      );

      expect(
        collapseWhitespace(
          methodBody((plan as FlatScalarEncodePlan).value),
        ),
        collapseWhitespace(
          format(r'''
            test() {
              final result = encodeUnknownFlatScalar(
                v,
                context: r"""parameter "quo'te" \ $value""",
              );
            }
          '''),
        ),
      );
    });

    test('alias delegates to the aliased model', () {
      final plan = encodePlan(
        AliasModel(
          name: 'Count',
          model: IntegerModel(context: context),
          context: context,
          examples: const [],
          defaultValue: null,
        ),
      );

      expect(
        emit((plan as FlatScalarEncodePlan).value),
        'v.toString()',
      );
    });

    test('nullable alias delegates to the aliased model', () {
      final plan = encodePlan(
        AliasModel(
          name: 'Count',
          model: IntegerModel(context: context),
          isNullable: true,
          context: context,
          examples: const [],
          defaultValue: null,
        ),
      );

      expect(
        emit((plan as FlatScalarEncodePlan).value),
        'v.toString()',
      );
    });
  });

  group('buildFlatEncodePlan arrays', () {
    test('string list passes through preserving element boundaries', () {
      final plan = encodePlan(
        ListModel(
          content: StringModel(context: context),
          context: context,
          examples: const [],
        ),
      );

      expect(
        emit((plan as FlatArrayEncodePlan).values),
        'v',
      );
    });

    test('integer list maps elements to raw strings', () {
      final plan = encodePlan(
        ListModel(
          content: IntegerModel(context: context),
          context: context,
          examples: const [],
        ),
      );

      expect(
        emit((plan as FlatArrayEncodePlan).values),
        'v.map((e) => e.toString()).toList()',
      );
    });

    test('nullable string content maps null elements to empty strings', () {
      final plan = encodePlan(
        ListModel(
          content: StringModel(context: context),
          isContentNullable: true,
          context: context,
          examples: const [],
        ),
      );

      expect(
        emit((plan as FlatArrayEncodePlan).values),
        "v.map((e) => e ?? '').toList()",
      );
    });

    test('enum list maps elements through toJson', () {
      final plan = encodePlan(
        ListModel(
          content: EnumModel<String>(
            values: {const EnumEntry(value: 'a')},
            isNullable: false,
            context: context,
            isDeprecated: false,
            examples: const [],
          ),
          context: context,
          examples: const [],
        ),
      );

      expect(
        emit((plan as FlatArrayEncodePlan).values),
        'v.map((e) => e.toJson()).toList()',
      );
    });

    test('Any list maps elements through the unknown-flat-scalar '
        'boundary', () {
      final plan = encodePlan(
        ListModel(
          content: AnyModel(context: context),
          context: context,
          examples: const [],
        ),
      );

      expect(
        collapseWhitespace(
          methodBody((plan as FlatArrayEncodePlan).values),
        ),
        collapseWhitespace(
          format('''
            test() {
              final result = v
                  .map(
                    (e) => encodeUnknownFlatScalar(
                      e,
                      context: r'ctx',
                    ),
                  )
                  .toList();
            }
          '''),
        ),
      );
    });

    test('nested lists are unsupported', () {
      final plan = encodePlan(
        ListModel(
          content: ListModel(
            content: StringModel(context: context),
            context: context,
            examples: const [],
          ),
          context: context,
          examples: const [],
        ),
      );

      expect(plan, isA<UnsupportedFlatEncodePlan>());
    });

    test('lists of classes are unsupported', () {
      final plan = encodePlan(
        ListModel(
          content: ClassModel(
            properties: const [],
            context: context,
            isDeprecated: false,
            examples: const [],
          ),
          context: context,
          examples: const [],
        ),
      );

      expect(plan, isA<UnsupportedFlatEncodePlan>());
    });
  });

  group('buildFlatEncodePlan unsupported models', () {
    test('maps, classes, and compositions share the canonical reason', () {
      final models = <Model>[
        MapModel(
          valueModel: StringModel(context: context),
          context: context,
          examples: const [],
        ),
        ClassModel(
          properties: const [],
          context: context,
          isDeprecated: false,
          examples: const [],
        ),
        AllOfModel(
          models: {StringModel(context: context)},
          context: context,
          isDeprecated: false,
          examples: const [],
        ),
        OneOfModel(
          models: const {},
          context: context,
          isDeprecated: false,
          examples: const [],
        ),
        AnyOfModel(
          models: const {},
          context: context,
          isDeprecated: false,
          examples: const [],
        ),
      ];

      for (final model in models) {
        final plan = encodePlan(model);
        expect(
          (plan as UnsupportedFlatEncodePlan).reason,
          '${model.runtimeType} values have no flat representation',
          reason: model.runtimeType.toString(),
        );
      }
    });

    test('binary values are unsupported', () {
      final plan = encodePlan(BinaryModel(context: context));

      expect(plan, isA<UnsupportedFlatEncodePlan>());
    });

    test('never values are unsupported', () {
      final plan = encodePlan(NeverModel(context: context, isNullable: false));

      expect(plan, isA<UnsupportedFlatEncodePlan>());
    });
  });

  group('buildFlatDecodePlan', () {
    test('required string decodes from simple', () {
      final plan = decodePlan(StringModel(context: context));

      expect(
        emit((plan as FlatScalarDecodePlan).value),
        'v.decodeSimpleString()',
      );
    });

    test('optional string decodes with the nullable simple decoder', () {
      final plan = decodePlan(
        StringModel(context: context),
        isRequired: false,
      );

      expect(
        emit((plan as FlatScalarDecodePlan).value),
        'v.decodeSimpleNullableString()',
      );
    });

    test('required int decodes from form', () {
      final plan = decodePlan(
        IntegerModel(context: context),
        format: FlatWireFormat.form,
      );

      expect(
        emit((plan as FlatScalarDecodePlan).value),
        'v.decodeFormInt()',
      );
    });

    test('enum decodes through its fromSimple factory', () {
      final model = EnumModel<String>(
        name: 'Status',
        values: {const EnumEntry(value: 'active')},
        isNullable: false,
        context: context,
        isDeprecated: false,
        examples: const [],
      );
      final plan = decodePlan(model);

      expect(
        emit((plan as FlatScalarDecodePlan).value),
        'Status.fromSimple(v, explode: explode, )',
      );
    });

    test('Any decoding retains the raw string', () {
      final plan = decodePlan(AnyModel(context: context));

      expect(
        emit((plan as FlatScalarDecodePlan).value),
        'v',
      );
    });

    test('alias delegates to the aliased model', () {
      final plan = decodePlan(
        AliasModel(
          name: 'Count',
          model: IntegerModel(context: context),
          context: context,
          examples: const [],
          defaultValue: null,
        ),
      );

      expect(
        emit((plan as FlatScalarDecodePlan).value),
        'v.decodeSimpleInt()',
      );
    });

    test('lists are unsupported because unknown-key element boundaries '
        'cannot be recovered', () {
      final plan = decodePlan(
        ListModel(
          content: IntegerModel(context: context),
          context: context,
          examples: const [],
        ),
      );

      expect(
        (plan as UnsupportedFlatDecodePlan).reason,
        'List values cannot be decoded from a flat value',
      );
    });

    test('maps are unsupported', () {
      final plan = decodePlan(
        MapModel(
          valueModel: StringModel(context: context),
          context: context,
          examples: const [],
        ),
      );

      expect(
        (plan as UnsupportedFlatDecodePlan).reason,
        'Map values cannot be decoded from a flat value',
      );
    });

    test('classes and compositions are unsupported in one flat slot', () {
      final models = <Model>[
        ClassModel(
          properties: const [],
          context: context,
          isDeprecated: false,
          examples: const [],
        ),
        AllOfModel(
          models: {StringModel(context: context)},
          context: context,
          isDeprecated: false,
          examples: const [],
        ),
      ];

      for (final model in models) {
        final plan = decodePlan(model);
        expect(
          (plan as UnsupportedFlatDecodePlan).reason,
          '${model.runtimeType} values cannot be decoded from a flat value',
          reason: model.runtimeType.toString(),
        );
      }
    });

    test('never is unsupported', () {
      final plan = decodePlan(NeverModel(context: context, isNullable: false));

      expect(plan, isA<UnsupportedFlatDecodePlan>());
    });

    test('alias of a map is unsupported', () {
      final plan = decodePlan(
        AliasModel(
          name: 'Lookup',
          model: MapModel(
            valueModel: StringModel(context: context),
            context: context,
            examples: const [],
          ),
          context: context,
          examples: const [],
          defaultValue: null,
        ),
      );

      expect(plan, isA<UnsupportedFlatDecodePlan>());
    });
  });
}
