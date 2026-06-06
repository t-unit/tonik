import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/util/default_value_materialiser.dart';

void main() {
  late Context context;
  late NameManager nameManager;
  const package = 'example';
  final formatter = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  );

  String renderExpression(Expression expression) {
    final method = Method(
      (b) => b
        ..name = '_render'
        ..lambda = true
        ..body = expression.code,
    );
    final source = '${method.accept(DartEmitter())};';
    return formatter.format(source);
  }

  String formatBody(String body) =>
      formatter.format('_render() => $body;');

  setUp(() {
    context = Context.initial();
    nameManager = NameManager(
      generator: NameGenerator(),
      stableModelSorter: StableModelSorter(),
    );
  });

  group('materialiseConstDefault — primitives', () {
    test('StringModel + String literal materialises as a raw literal', () {
      final result = materialiseConstDefault(
        jsonValue: 'anon',
        targetModel: StringModel(context: context),
        nameManager: nameManager,
        package: package,
      );

      expect(result, isNotNull);
      expect(
        collapseWhitespace(renderExpression(result!)),
        collapseWhitespace(formatBody("r'anon'")),
      );
    });

    test(r'StringModel + String containing $ is escaped as raw string', () {
      final result = materialiseConstDefault(
        jsonValue: r'Hello $world',
        targetModel: StringModel(context: context),
        nameManager: nameManager,
        package: package,
      );

      expect(result, isNotNull);
      expect(
        collapseWhitespace(renderExpression(result!)),
        collapseWhitespace(formatBody(r"r'Hello $world'")),
      );
    });

    test('IntegerModel + int materialises as literalNum', () {
      final result = materialiseConstDefault(
        jsonValue: 0,
        targetModel: IntegerModel(context: context),
        nameManager: nameManager,
        package: package,
      );

      expect(result, isNotNull);
      expect(
        collapseWhitespace(renderExpression(result!)),
        collapseWhitespace(formatBody('0')),
      );
    });

    test('DoubleModel + num materialises as double literal', () {
      final result = materialiseConstDefault(
        jsonValue: 1.5,
        targetModel: DoubleModel(context: context),
        nameManager: nameManager,
        package: package,
      );

      expect(result, isNotNull);
      expect(
        collapseWhitespace(renderExpression(result!)),
        collapseWhitespace(formatBody('1.5')),
      );
    });

    test('DoubleModel + int promotes via toDouble()', () {
      final result = materialiseConstDefault(
        jsonValue: 2,
        targetModel: DoubleModel(context: context),
        nameManager: nameManager,
        package: package,
      );

      expect(result, isNotNull);
      expect(
        collapseWhitespace(renderExpression(result!)),
        collapseWhitespace(formatBody('2.0')),
      );
    });

    test('NumberModel + int materialises as literalNum', () {
      final result = materialiseConstDefault(
        jsonValue: 3,
        targetModel: NumberModel(context: context),
        nameManager: nameManager,
        package: package,
      );

      expect(result, isNotNull);
      expect(
        collapseWhitespace(renderExpression(result!)),
        collapseWhitespace(formatBody('3')),
      );
    });

    test('BooleanModel + bool materialises as literalBool', () {
      final result = materialiseConstDefault(
        jsonValue: true,
        targetModel: BooleanModel(context: context),
        nameManager: nameManager,
        package: package,
      );

      expect(result, isNotNull);
      expect(
        collapseWhitespace(renderExpression(result!)),
        collapseWhitespace(formatBody('true')),
      );
    });
  });

  group('materialiseConstDefault — type mismatches', () {
    test('StringModel + int returns null', () {
      final result = materialiseConstDefault(
        jsonValue: 42,
        targetModel: StringModel(context: context),
        nameManager: nameManager,
        package: package,
      );

      expect(result, isNull);
    });

    test('IntegerModel + String returns null', () {
      final result = materialiseConstDefault(
        jsonValue: 'no',
        targetModel: IntegerModel(context: context),
        nameManager: nameManager,
        package: package,
      );

      expect(result, isNull);
    });

    test('IntegerModel + double returns null', () {
      final result = materialiseConstDefault(
        jsonValue: 1.5,
        targetModel: IntegerModel(context: context),
        nameManager: nameManager,
        package: package,
      );

      expect(result, isNull);
    });

    test('BooleanModel + String returns null', () {
      final result = materialiseConstDefault(
        jsonValue: 'true',
        targetModel: BooleanModel(context: context),
        nameManager: nameManager,
        package: package,
      );

      expect(result, isNull);
    });
  });

  group('materialiseConstDefault — null jsonValue returns null', () {
    test('null + non-nullable primitive returns null', () {
      final result = materialiseConstDefault(
        jsonValue: null,
        targetModel: StringModel(context: context),
        nameManager: nameManager,
        package: package,
      );

      expect(result, isNull);
    });

    test('null + alias-wrapped nullable primitive returns null', () {
      final alias = AliasModel(
        name: 'NullableString',
        model: StringModel(context: context),
        context: context,
        examples: const [],
        defaultValue: null,
        isNullable: true,
      );

      final result = materialiseConstDefault(
        jsonValue: null,
        targetModel: alias,
        nameManager: nameManager,
        package: package,
      );

      expect(result, isNull);
    });
  });

  group('materialiseConstDefault — alias resolution', () {
    test('AliasModel wrapping a primitive routes to the primitive branch', () {
      final alias = AliasModel(
        name: 'Tagged',
        model: StringModel(context: context),
        context: context,
        examples: const [],
        defaultValue: null,
      );

      final result = materialiseConstDefault(
        jsonValue: 'hi',
        targetModel: alias,
        nameManager: nameManager,
        package: package,
      );

      expect(result, isNotNull);
      expect(
        collapseWhitespace(renderExpression(result!)),
        collapseWhitespace(formatBody("r'hi'")),
      );
    });

    test('AliasModel chain ending in IntegerModel resolves correctly', () {
      final inner = AliasModel(
        name: 'InnerAlias',
        model: IntegerModel(context: context),
        context: context,
        examples: const [],
        defaultValue: null,
      );
      final outer = AliasModel(
        name: 'OuterAlias',
        model: inner,
        context: context,
        examples: const [],
        defaultValue: null,
      );

      final result = materialiseConstDefault(
        jsonValue: 7,
        targetModel: outer,
        nameManager: nameManager,
        package: package,
      );

      expect(result, isNotNull);
      expect(
        collapseWhitespace(renderExpression(result!)),
        collapseWhitespace(formatBody('7')),
      );
    });
  });

  group('materialiseConstDefault — non-primitive targets return null', () {
    test('ClassModel returns null', () {
      final result = materialiseConstDefault(
        jsonValue: <String, Object?>{},
        targetModel: ClassModel(
          name: 'Address',
          isDeprecated: false,
          properties: const [],
          context: context,
          examples: const [],
        ),
        nameManager: nameManager,
        package: package,
      );

      expect(result, isNull);
    });

    test('DateTimeModel returns null', () {
      final result = materialiseConstDefault(
        jsonValue: '2024-01-01T00:00:00Z',
        targetModel: DateTimeModel(context: context),
        nameManager: nameManager,
        package: package,
      );

      expect(result, isNull);
    });

    test('AnyModel returns null', () {
      final result = materialiseConstDefault(
        jsonValue: 'anything',
        targetModel: AnyModel(context: context),
        nameManager: nameManager,
        package: package,
      );

      expect(result, isNull);
    });
  });

  group('materialiseConstDefault — enums', () {
    EnumModel<String> stringEnum({
      String? name = 'Status',
      List<EnumEntry<String>>? values,
      EnumEntry<String>? fallbackValue,
    }) {
      final entries = values ??
          [
            const EnumEntry<String>(value: 'active'),
            const EnumEntry<String>(value: 'inactive'),
          ];
      return EnumModel<String>(
        name: name,
        values: entries.toSet(),
        isNullable: false,
        context: context,
        isDeprecated: false,
        examples: const [],
        fallbackValue: fallbackValue,
      );
    }

    EnumModel<int> intEnum({
      String? name = 'Tier',
      List<EnumEntry<int>>? values,
      EnumEntry<int>? fallbackValue,
    }) {
      final entries = values ??
          [
            const EnumEntry<int>(value: 1),
            const EnumEntry<int>(value: 2),
            const EnumEntry<int>(value: 3),
          ];
      return EnumModel<int>(
        name: name,
        values: entries.toSet(),
        isNullable: false,
        context: context,
        isDeprecated: false,
        examples: const [],
        fallbackValue: fallbackValue,
      );
    }

    test('String enum value match emits MyEnum.variant reference', () {
      final result = materialiseConstDefault(
        jsonValue: 'active',
        targetModel: stringEnum(),
        nameManager: nameManager,
        package: package,
      );

      expect(result, isNotNull);
      expect(
        collapseWhitespace(renderExpression(result!)),
        collapseWhitespace(formatBody('Status.active')),
      );
    });

    test('int enum value match emits MyEnum.variant reference', () {
      final result = materialiseConstDefault(
        jsonValue: 2,
        targetModel: intEnum(),
        nameManager: nameManager,
        package: package,
      );

      expect(result, isNotNull);
      expect(
        collapseWhitespace(renderExpression(result!)),
        collapseWhitespace(formatBody('Tier.two')),
      );
    });

    test('type mismatch (int default on String enum) returns null', () {
      final result = materialiseConstDefault(
        jsonValue: 42,
        targetModel: stringEnum(),
        nameManager: nameManager,
        package: package,
      );

      expect(result, isNull);
    });

    test('value not in enum values returns null', () {
      final result = materialiseConstDefault(
        jsonValue: 'archived',
        targetModel: stringEnum(),
        nameManager: nameManager,
        package: package,
      );

      expect(result, isNull);
    });

    test(
      'value matches fallbackValue but is NOT in values — returns null '
      '(fallback never auto-selected)',
      () {
        final result = materialiseConstDefault(
          jsonValue: 'unknown',
          targetModel: stringEnum(
            fallbackValue: const EnumEntry<String>(value: 'unknown'),
          ),
          nameManager: nameManager,
          package: package,
        );

        expect(result, isNull);
      },
    );

    test('nameOverride on matched entry controls the variant name', () {
      final result = materialiseConstDefault(
        jsonValue: 'active',
        targetModel: stringEnum(
          values: const [
            EnumEntry<String>(value: 'active', nameOverride: 'Activated'),
            EnumEntry<String>(value: 'inactive', nameOverride: 'Deactivated'),
          ],
        ),
        nameManager: nameManager,
        package: package,
      );

      expect(result, isNotNull);
      expect(
        collapseWhitespace(renderExpression(result!)),
        collapseWhitespace(formatBody('Status.activated')),
      );
    });

    test(
      'matched variant name is stable when fallbackValue nameOverride '
      'collides with an entry nameOverride',
      () {
        final result = materialiseConstDefault(
          jsonValue: 'active',
          targetModel: stringEnum(
            values: const [
              EnumEntry<String>(value: 'active', nameOverride: 'Activated'),
              EnumEntry<String>(value: 'inactive'),
            ],
            fallbackValue: const EnumEntry<String>(
              value: 'unknown',
              nameOverride: 'Activated',
            ),
          ),
          nameManager: nameManager,
          package: package,
        );

        expect(result, isNotNull);
        expect(
          collapseWhitespace(renderExpression(result!)),
          collapseWhitespace(formatBody('Status.activated')),
        );
      },
    );

    test('alias chain to EnumModel routes via targetModel.resolved', () {
      final enumModel = stringEnum();
      final inner = AliasModel(
        name: 'StatusAlias',
        model: enumModel,
        context: context,
        examples: const [],
        defaultValue: null,
      );
      final outer = AliasModel(
        name: 'StatusOuter',
        model: inner,
        context: context,
        examples: const [],
        defaultValue: null,
      );

      final result = materialiseConstDefault(
        jsonValue: 'inactive',
        targetModel: outer,
        nameManager: nameManager,
        package: package,
      );

      expect(result, isNotNull);
      expect(
        collapseWhitespace(renderExpression(result!)),
        collapseWhitespace(formatBody('Status.inactive')),
      );
    });

    test(
      'value present in both values AND fallbackValue resolves to the '
      'values entry (matched index is the values entry)',
      () {
        final result = materialiseConstDefault(
          jsonValue: 'inactive',
          targetModel: stringEnum(
            fallbackValue: const EnumEntry<String>(value: 'inactive'),
          ),
          nameManager: nameManager,
          package: package,
        );

        expect(result, isNotNull);
        expect(
          collapseWhitespace(renderExpression(result!)),
          collapseWhitespace(formatBody('Status.inactive')),
        );
      },
    );

    test(
      'nullable enum with a value in the enum returns null because const '
      'variant access through the nullable typedef is not yet wired up',
      () {
        final nullableStatus = EnumModel<String>(
          name: 'Status',
          values: {
            const EnumEntry<String>(value: 'active'),
            const EnumEntry<String>(value: 'inactive'),
          },
          isNullable: true,
          context: context,
          isDeprecated: false,
          examples: const [],
        );

        final result = materialiseConstDefault(
          jsonValue: 'active',
          targetModel: nullableStatus,
          nameManager: nameManager,
          package: package,
        );

        expect(result, isNull);
      },
    );
  });
}
