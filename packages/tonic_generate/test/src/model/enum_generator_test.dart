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
      nameManager: NameManager(generator: nameGenerator),
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

      final code = generated.enumValue.accept(DartEmitter()).toString();
      expect(code, contains("red('red')"));
      expect(code, contains("green('green')"));
      expect(code, contains("blue('blue')"));
      expect(code, contains('const Color(this.rawValue);'));
      expect(code, contains('final String rawValue;'));

      final enumAnnotation = generated.enumValue.annotations.first;
      final annotationCode =
          enumAnnotation.code.accept(DartEmitter()).toString();
      expect(annotationCode, contains("JsonEnum(valueField: 'rawValue')"));
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

      final code = generated.enumValue.accept(DartEmitter()).toString();
      expect(code, contains('one(1)'));
      expect(code, contains('two(2)'));
      expect(code, contains('three(3)'));
      expect(code, contains('const Status(this.rawValue);'));
      expect(code, contains('final int rawValue;'));

      final enumAnnotation = generated.enumValue.annotations.first;
      final annotationCode =
          enumAnnotation.code.accept(DartEmitter()).toString();
      expect(annotationCode, equals("JsonEnum(valueField: 'rawValue')"));
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

      final code = generated.enumValue.accept(DartEmitter()).toString();
      expect(code, contains("value('_')"));
      expect(code, contains("value2('__')"));
      expect(code, contains("value3('___')"));
      expect(code, contains('const Placeholder(this.rawValue);'));
      expect(code, contains('final String rawValue;'));
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
      expect(result.code, contains("@_i1.JsonEnum(valueField: 'rawValue')"));
      expect(result.code, contains('enum Status'));
      expect(result.code, contains("part 'status.g.dart'"));
      expect(result.code, isNot(contains('typedef')));
      expect(result.code, contains('oneHundred(100)'));
      expect(result.code, contains('twoHundred(200)'));
      expect(result.code, contains('fourHundredFour(404)'));
      expect(result.code, contains('const Status(this.rawValue);'));
      expect(result.code, contains('final int rawValue;'));
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

    group('json serialization', () {
      test('generates toJson method', () {
        final model = EnumModel<String>(
          name: 'Color',
          values: const {'red', 'green', 'blue'},
          isNullable: false,
          context: Context.initial().push('test'),
        );

        final generated = generator.generateEnum(model, 'Color');
        final toJson = generated.enumValue.methods.firstWhere(
          (m) => m.name == 'toJson',
        );

        final body = toJson.body?.accept(DartEmitter()).toString() ?? '';
        expect(body, 'rawValue');
        expect(toJson.returns?.accept(DartEmitter()).toString(), 'String');
      });

      test('generates fromJson factory for string enums', () {
        final model = EnumModel<String>(
          name: 'Color',
          values: const {'red', 'green', 'blue'},
          isNullable: false,
          context: Context.initial().push('test'),
        );

        final generated = generator.generateEnum(model, 'Color');
        final fromJson = generated.enumValue.constructors.firstWhere(
          (c) => c.name == 'fromJson',
        );

        expect(fromJson.factory, isTrue);
        expect(
          fromJson.requiredParameters.single.type
              ?.accept(DartEmitter())
              .toString(),
          'dynamic',
        );

        final body = fromJson.body?.accept(DartEmitter()).toString() ?? '';
        const expectedBody = r'''
          if (value is! String) {
            throw FormatException('Expected String for Color, got ${value.runtimeType}');
          }
          return values.firstWhere(
            (e) => e.rawValue == value,
            orElse: () => throw FormatException('No matching Color for value: $value'));
        ''';
        expect(body.normalizeCode(), expectedBody.normalizeCode());
      });

      test('generates fromJson factory for integer enums', () {
        final model = EnumModel<int>(
          name: 'Status',
          values: const {200, 404, 500},
          isNullable: false,
          context: Context.initial().push('test'),
        );

        final generated = generator.generateEnum(model, 'Status');
        final fromJson = generated.enumValue.constructors.firstWhere(
          (c) => c.name == 'fromJson',
        );

        expect(fromJson.factory, isTrue);
        expect(
          fromJson.requiredParameters.single.type
              ?.accept(DartEmitter())
              .toString(),
          'dynamic',
        );

        final body = fromJson.body?.accept(DartEmitter()).toString() ?? '';
        const expectedBody = r'''
          if (value is! int) {
            throw FormatException('Expected int for Status, got ${value.runtimeType}');
          }
          return values.firstWhere(
            (e) => e.rawValue == value,
            orElse: () => throw FormatException('No matching Status for value: $value'));
        ''';
        expect(body.normalizeCode(), expectedBody.normalizeCode());
      });

      test('generates fromJson factory for nullable enums', () {
        final model = EnumModel<String>(
          name: 'Status',
          values: const {'active', 'inactive'},
          isNullable: true,
          context: Context.initial(),
        );

        final generated = generator.generateEnum(model, 'Status');
        final fromJson = generated.enumValue.constructors.firstWhere(
          (c) => c.name == 'fromJson',
        );

        expect(fromJson.factory, isTrue);
        expect(
          fromJson.requiredParameters.single.type
              ?.accept(DartEmitter())
              .toString(),
          'dynamic',
        );

        final body = fromJson.body?.accept(DartEmitter()).toString() ?? '';
        const expectedBody = r'''
          if (value is! String) {
            throw FormatException('Expected String for Status, got ${value.runtimeType}');
          }
          return values.firstWhere(
            (e) => e.rawValue == value,
            orElse: () => throw FormatException('No matching Status for value: $value'));
        ''';
        expect(body.normalizeCode(), expectedBody.normalizeCode());
      });
    });
  });
}

extension on String {
  String normalizeCode() => replaceAll(RegExp(r'\s+'), ' ').trim();
}
