import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';
import 'package:tonic_core/tonic_core.dart';
import 'package:tonic_generate/src/model/enum_generator.dart';
import 'package:tonic_generate/src/util/name_generator.dart';
import 'package:tonic_generate/src/util/name_manager.dart';
import 'package:tonic_generate/src/util/property_name_normalizer.dart';

void main() {
  late EnumGenerator generator;
  late NameGenerator nameGenerator;

  setUp(() {
    nameGenerator = NameGenerator();
    generator = EnumGenerator(
      nameManger: NameManger(generator: nameGenerator),
      propertyNameNormalizer: PropertyNameNormalizer(),
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

      final enumClass = generator.generateEnum(model);

      expect(enumClass.name, 'Color');
      expect(enumClass.values.length, 3);
      expect(enumClass.values[0].name, 'red');
      expect(enumClass.values[1].name, 'green');
      expect(enumClass.values[2].name, 'blue');

      // Verify JSON value annotations
      for (final value in enumClass.values) {
        final annotation = value.annotations.first;
        final code = annotation.code.accept(DartEmitter()).toString();
        expect(code, contains('@JsonValue'));
        expect(code, contains("'${value.name}'"));
      }
    });

    test('generates enum with integer values', () {
      final model = EnumModel<int>(
        name: 'Status',
        values: const {100, 200, 404},
        isNullable: false,
        context: Context.initial().push('test'),
      );

      final enumClass = generator.generateEnum(model);

      expect(enumClass.name, 'Status');
      expect(enumClass.values.length, 3);
      expect(enumClass.values[0].name, 'oneHundred');
      expect(enumClass.values[1].name, 'twoHundred');
      expect(enumClass.values[2].name, 'fourHundredFour');

      // Verify JSON value annotations
      for (final value in enumClass.values) {
        final annotation = value.annotations.first;
        final code = annotation.code.accept(DartEmitter()).toString();
        expect(code, contains('@JsonValue'));

        if (value.name == 'oneHundred') {
          expect(code, contains('100'));
        } else if (value.name == 'twoHundred') {
          expect(code, contains('200'));
        } else {
          expect(code, contains('404'));
        }
      }
    });

    test('handles underscore-only values', () {
      final model = EnumModel<String>(
        name: 'Placeholder',
        values: const {'_', '__', '___'},
        isNullable: false,
        context: Context.initial().push('test'),
      );

      final enumClass = generator.generateEnum(model);

      expect(enumClass.name, 'Placeholder');
      expect(enumClass.values.length, 3);
      expect(enumClass.values[0].name, 'value');
      expect(enumClass.values[1].name, 'value2');
      expect(enumClass.values[2].name, 'value3');

      // Verify JSON value annotations
      expect(
        enumClass.values[0].annotations.first.code
            .accept(DartEmitter())
            .toString(),
        contains("'_'"),
      );
      expect(
        enumClass.values[1].annotations.first.code
            .accept(DartEmitter())
            .toString(),
        contains("'__'"),
      );
      expect(
        enumClass.values[2].annotations.first.code
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
            'EnumGenerator only supports String and int values. Got type: double',
          ),
        ),
      );
    });
  });
}
