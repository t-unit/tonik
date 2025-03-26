import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';
import 'package:tonic_core/tonic_core.dart';
import 'package:tonic_generate/src/model/enum_generator.dart';
import 'package:tonic_generate/src/util/name_generator.dart';
import 'package:tonic_generate/src/util/name_manager.dart';

void main() {
  late EnumGenerator generator;
  late NameGenerator nameGenerator;

  setUp(() {
    nameGenerator = NameGenerator();
    generator = EnumGenerator(
      nameManger: NameManger(generator: nameGenerator),
      package: 'test_package',
    );
  });

  group('EnumGenerator', () {
    test('generates enum with string values', () {
      final model = EnumModel<String>(
        name: 'Color',
        values: const {'red', 'green', 'blue'},
        isNullable: false,
        context: Context.initial().push('test'),
      );

      final result = generator.generate(model);

      expect(result.filename, 'color.dart');
      expect(result.code, contains('enum Color'));
      expect(result.code, isNot(contains('typedef')));
    });

    test('generates enum with string values value', () {
      final model = EnumModel<String>(
        name: 'Color',
        values: const {'red', 'green', 'blue'},
        isNullable: false,
        context: Context.initial().push('test'),
      );

      final generated = generator.generateEnum(model, 'Color');

      expect(generated.enumValue.name, 'Color');
      expect(generated.typedefValue, isNull);
      expect(generated.enumValue.values, hasLength(3));
      expect(generated.enumValue.values[0].name, 'red');
      expect(generated.enumValue.values[1].name, 'green');
      expect(generated.enumValue.values[2].name, 'blue');

      // Verify JSON value annotations
      for (final value in generated.enumValue.values) {
        final annotation = value.annotations.first;
        final code = annotation.code.accept(DartEmitter()).toString();
        expect(code, contains('@JsonValue'));
        expect(code, contains("'${value.name}'"));
      }
    });

    test('generates nullable enum code', () {
      final model = EnumModel<String>(
        name: 'Status',
        values: const {'active', 'inactive'},
        isNullable: true,
        context: Context.initial(),
      );

      final result = generator.generate(model);

      expect(result.code, contains('enum RawStatus'));
      expect(result.code, contains('typedef Status = RawStatus?'));
      expect(result.filename, 'status.dart');
    });

    test('generates nullable enum value', () {
      final model = EnumModel<String>(
        name: 'Status',
        values: const {'active', 'inactive'},
        isNullable: true,
        context: Context.initial(),
      );

      final generated = generator.generateEnum(model, 'Status');

      expect(generated.enumValue.name, 'RawStatus');
      expect(generated.typedefValue, isNotNull);
      expect(generated.typedefValue!.name, 'Status');
      expect(
        generated.typedefValue!.definition.accept(DartEmitter()).toString(),
        'RawStatus?',
      );
      expect(generated.enumValue.values, hasLength(2));
      expect(generated.enumValue.values[0].name, 'active');
      expect(generated.enumValue.values[1].name, 'inactive');
    });

    test('generates non-nullable enum code', () {
      final model = EnumModel<String>(
        name: 'Color',
        values: const {'red', 'green', 'blue'},
        isNullable: false,
        context: Context.initial(),
      );

      final result = generator.generate(model);

      expect(result.code, contains('enum Color'));
      expect(result.code, isNot(contains('typedef')));
      expect(result.filename, 'color.dart');
    });

    test('generates non-nullable enum value', () {
      final model = EnumModel<String>(
        name: 'Color',
        values: const {'red', 'green', 'blue'},
        isNullable: false,
        context: Context.initial(),
      );

      final generated = generator.generateEnum(model, 'Color');

      expect(generated.enumValue.name, 'Color');
      expect(generated.enumValue.values, hasLength(3));
      expect(generated.enumValue.values.first.name, 'red');
      expect(generated.typedefValue, isNull);
    });

    test('generates enum with string values code', () {
      final model = EnumModel<String>(
        name: 'Color',
        values: const {'red', 'green', 'blue'},
        isNullable: false,
        context: Context.initial().push('test'),
      );

      final result = generator.generate(model);

      expect(result.filename, 'color.dart');
      expect(result.code, contains('enum Color'));
      expect(result.code, isNot(contains('typedef')));
    });

    test('generates enum with integer values code', () {
      final model = EnumModel<int>(
        name: 'Status',
        values: const {1, 2, 3},
        isNullable: false,
        context: Context.initial().push('test'),
      );

      final result = generator.generate(model);

      expect(result.filename, 'status.dart');
      expect(result.code, contains('enum Status'));
      expect(result.code, isNot(contains('typedef')));
    });

    test('generates enum with integer values value', () {
      final model = EnumModel<int>(
        name: 'Status',
        values: const {1, 2, 3},
        isNullable: false,
        context: Context.initial().push('test'),
      );

      final generated = generator.generateEnum(model, 'Status');

      expect(generated.enumValue.name, 'Status');
      expect(generated.typedefValue, isNull);
      expect(generated.enumValue.values, hasLength(3));
      expect(generated.enumValue.values[0].name, 'one');
      expect(generated.enumValue.values[1].name, 'two');
      expect(generated.enumValue.values[2].name, 'three');

      // Verify JSON value annotations
      for (var i = 0; i < generated.enumValue.values.length; i++) {
        final value = generated.enumValue.values[i];
        final annotation = value.annotations.first;
        final code = annotation.code.accept(DartEmitter()).toString();
        expect(code, contains('@JsonValue'));
        expect(code, contains('${i + 1}'));
      }
    });

    test('handles underscore-only values', () {
      final model = EnumModel<String>(
        name: 'Placeholder',
        values: const {'_', '__', '___'},
        isNullable: false,
        context: Context.initial().push('test'),
      );

      final generated = generator.generateEnum(model, 'Placeholder');

      expect(generated.enumValue.name, 'Placeholder');
      expect(generated.typedefValue, isNull);
      expect(generated.enumValue.values, hasLength(3));
      expect(generated.enumValue.values[0].name, 'value');
      expect(generated.enumValue.values[1].name, 'value2');
      expect(generated.enumValue.values[2].name, 'value3');

      // Verify JSON value annotations
      expect(
        generated.enumValue.values[0].annotations.first.code
            .accept(DartEmitter())
            .toString(),
        contains("'_'"),
      );
      expect(
        generated.enumValue.values[1].annotations.first.code
            .accept(DartEmitter())
            .toString(),
        contains("'__'"),
      );
      expect(
        generated.enumValue.values[2].annotations.first.code
            .accept(DartEmitter())
            .toString(),
        contains("'___'"),
      );
    });

    test('generates file with correct name and content', () {
      final model = EnumModel<int>(
        name: 'Status',
        values: const {100, 200, 404},
        isNullable: false,
        context: Context.initial().push('test'),
      );

      final result = generator.generate(model);

      expect(result.filename, 'status.dart');
      expect(result.code, contains('@_i1.JsonEnum'));
      expect(result.code, contains('enum Status'));
      expect(result.code, contains("part 'status.g.dart'"));
      expect(result.code, isNot(contains('typedef')));
      expect(result.code, contains('@JsonValue(100)'));
      expect(result.code, contains('@JsonValue(200)'));
      expect(result.code, contains('@JsonValue(404)'));
    });

    test('throws error for unsupported types', () {
      final model = EnumModel<double>(
        name: 'Rate',
        values: {0.5, 1.5, 2.5},
        isNullable: false,
        context: Context.initial().push('test'),
      );

      expect(
        () => generator.generate(model),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'EnumGenerator only supports String and int values. '
                'Got type: double',
          ),
        ),
      );
    });

    test('throws for unsupported enum value type', () {
      final model = EnumModel<double>(
        name: 'Status',
        values: {1.0, 2.0},
        isNullable: false,
        context: Context.initial().push('test'),
      );

      expect(
        () => generator.generateEnum(model, 'Status'),
        throwsArgumentError,
      );
    });

    group('_normalizeEnumValueName', () {
      test('handles string values', () {
        final model = EnumModel<String>(
          name: 'Status',
          values: const {'active', 'inactive'},
          isNullable: false,
          context: Context.initial().push('test'),
        );

        final generated = generator.generateEnum(model, 'Status');
        expect(generated.enumValue.values[0].name, 'active');
        expect(generated.enumValue.values[1].name, 'inactive');
      });

      test('handles integer values', () {
        final model = EnumModel<int>(
          name: 'Status',
          values: const {1, 2, 3},
          isNullable: false,
          context: Context.initial().push('test'),
        );

        final generated = generator.generateEnum(model, 'Status');
        expect(generated.enumValue.values[0].name, 'one');
        expect(generated.enumValue.values[1].name, 'two');
        expect(generated.enumValue.values[2].name, 'three');
      });
    });
  });
}
