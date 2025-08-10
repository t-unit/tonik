import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/model/enum_generator.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';

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
      expect(code, contains("red(r'red')"));
      expect(code, contains("green(r'green')"));
      expect(code, contains("blue(r'blue')"));
      expect(code, contains('const Color(this.rawValue);'));
      expect(code, contains('final String rawValue;'));
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
      expect(code, contains("value(r'_')"));
      expect(code, contains("value2(r'__')"));
      expect(code, contains("value3(r'___')"));
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
      expect(result.code, contains('enum Status'));
      expect(result.code, isNot(contains('typedef')));
    });

    test('throws error for unsupported types', () {
      final model = EnumModel<double>(
        name: 'Rate',
        values: {0.5, 1.5, 2.5},
        isNullable: false,
        context: Context.initial().push('test'),
      );

      expect(() => generator.generate(model), throwsA(isA<ArgumentError>()));
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
            orElse: () => throw FormatException('No matching Color for value: $value') );
        ''';
        expect(collapseWhitespace(body), collapseWhitespace(expectedBody));
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
            orElse: () => throw FormatException('No matching Status for value: $value') );
        ''';
        expect(collapseWhitespace(body), collapseWhitespace(expectedBody));
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
            orElse: () => throw FormatException('No matching Status for value: $value') );
        ''';
        expect(collapseWhitespace(body), collapseWhitespace(expectedBody));
      });
    });

    group('fromSimple factory', () {
      test('generates fromSimple constructor for string enum', () {
        final model = EnumModel<String>(
          name: 'Color',
          values: const {'red', 'green', 'blue'},
          isNullable: false,
          context: Context.initial(),
        );

        final generated = generator.generateEnum(model, 'Color');
        final fromSimple = generated.enumValue.constructors.firstWhere(
          (c) => c.name == 'fromSimple',
        );

        expect(fromSimple.factory, isTrue);
        expect(
          fromSimple.requiredParameters.single.type
              ?.accept(DartEmitter())
              .toString(),
          'String?',
        );
        expect(fromSimple.requiredParameters.single.name, 'value');

        final body = fromSimple.body?.accept(DartEmitter()).toString() ?? '';
        const expectedBody = '''
          return Color.fromJson(value.decodeSimpleString());
        ''';
        expect(collapseWhitespace(body), collapseWhitespace(expectedBody));
      });

      test('generates fromSimple constructor for int enum', () {
        final model = EnumModel<int>(
          name: 'Status',
          values: const {1, 2, 3},
          isNullable: false,
          context: Context.initial(),
        );

        final generated = generator.generateEnum(model, 'Status');
        final fromSimple = generated.enumValue.constructors.firstWhere(
          (c) => c.name == 'fromSimple',
        );

        expect(fromSimple.factory, isTrue);
        expect(
          fromSimple.requiredParameters.single.type
              ?.accept(DartEmitter())
              .toString(),
          'String?',
        );
        expect(fromSimple.requiredParameters.single.name, 'value');

        final body = fromSimple.body?.accept(DartEmitter()).toString() ?? '';
        const expectedBody = '''
          return Status.fromJson(value.decodeSimpleInt());
        ''';
        expect(collapseWhitespace(body), collapseWhitespace(expectedBody));
      });

      test('generates fromSimple constructor for nullable string enum', () {
        final model = EnumModel<String>(
          name: 'Status',
          values: const {'active', 'inactive'},
          isNullable: true,
          context: Context.initial(),
        );

        final generated = generator.generateEnum(model, 'Status');
        final fromSimple = generated.enumValue.constructors.firstWhere(
          (c) => c.name == 'fromSimple',
        );

        final body = fromSimple.body?.accept(DartEmitter()).toString() ?? '';
        const expectedBody = '''
          return RawStatus.fromJson(value.decodeSimpleString());
        ''';
        expect(collapseWhitespace(body), collapseWhitespace(expectedBody));
      });

      test('generates fromSimple constructor for nullable int enum', () {
        final model = EnumModel<int>(
          name: 'Status',
          values: const {1, 2, 3},
          isNullable: true,
          context: Context.initial(),
        );

        final generated = generator.generateEnum(model, 'Status');
        final fromSimple = generated.enumValue.constructors.firstWhere(
          (c) => c.name == 'fromSimple',
        );

        expect(fromSimple.factory, isTrue);
        expect(
          fromSimple.requiredParameters.single.type
              ?.accept(DartEmitter())
              .toString(),
          'String?',
        );
        expect(fromSimple.requiredParameters.single.name, 'value');

        final body = fromSimple.body?.accept(DartEmitter()).toString() ?? '';
        const expectedBody = '''
          return RawStatus.fromJson(value.decodeSimpleInt());
        ''';
        expect(collapseWhitespace(body), collapseWhitespace(expectedBody));
      });
    });

    group('toSimple method', () {
      test('generates toSimple method for string enum', () {
        final model = EnumModel<String>(
          name: 'Color',
          values: const {'red', 'green', 'blue'},
          isNullable: false,
          context: Context.initial(),
        );

        final generated = generator.generateEnum(model, 'Color');
        final toSimple = generated.enumValue.methods.firstWhere(
          (m) => m.name == 'toSimple',
        );

        expect(toSimple.returns?.accept(DartEmitter()).toString(), 'String');
        expect(toSimple.optionalParameters, hasLength(2));

        final explodeParam = toSimple.optionalParameters.firstWhere(
          (p) => p.name == 'explode',
        );
        expect(explodeParam.type?.accept(DartEmitter()).toString(), 'bool');
        expect(explodeParam.named, isTrue);
        expect(explodeParam.required, isTrue);

        final allowEmptyParam = toSimple.optionalParameters.firstWhere(
          (p) => p.name == 'allowEmpty',
        );
        expect(allowEmptyParam.type?.accept(DartEmitter()).toString(), 'bool');
        expect(allowEmptyParam.named, isTrue);
        expect(allowEmptyParam.required, isTrue);

        final body = toSimple.body?.accept(DartEmitter()).toString() ?? '';
        expect(
          body,
          'rawValue.toSimple(explode: explode, allowEmpty: allowEmpty)',
        );
        expect(toSimple.lambda, isTrue);
      });

      test('generates toSimple method for int enum', () {
        final model = EnumModel<int>(
          name: 'Status',
          values: const {1, 2, 3},
          isNullable: false,
          context: Context.initial(),
        );

        final generated = generator.generateEnum(model, 'Status');
        final toSimple = generated.enumValue.methods.firstWhere(
          (m) => m.name == 'toSimple',
        );

        expect(toSimple.returns?.accept(DartEmitter()).toString(), 'String');
        expect(toSimple.optionalParameters, hasLength(2));

        final body = toSimple.body?.accept(DartEmitter()).toString() ?? '';
        expect(
          body,
          'rawValue.toSimple(explode: explode, allowEmpty: allowEmpty)',
        );
        expect(toSimple.lambda, isTrue);
      });

      test('generates toSimple method for nullable string enum', () {
        final model = EnumModel<String>(
          name: 'Status',
          values: const {'active', 'inactive'},
          isNullable: true,
          context: Context.initial(),
        );

        final generated = generator.generateEnum(model, 'Status');
        final toSimple = generated.enumValue.methods.firstWhere(
          (m) => m.name == 'toSimple',
        );

        expect(toSimple.returns?.accept(DartEmitter()).toString(), 'String');
        expect(toSimple.optionalParameters, hasLength(2));

        final body = toSimple.body?.accept(DartEmitter()).toString() ?? '';
        expect(
          body,
          'rawValue.toSimple(explode: explode, allowEmpty: allowEmpty)',
        );
        expect(toSimple.lambda, isTrue);
      });

      test('generates toSimple method for nullable int enum', () {
        final model = EnumModel<int>(
          name: 'Status',
          values: const {100, 200, 300},
          isNullable: true,
          context: Context.initial(),
        );

        final generated = generator.generateEnum(model, 'Status');
        final toSimple = generated.enumValue.methods.firstWhere(
          (m) => m.name == 'toSimple',
        );

        expect(toSimple.returns?.accept(DartEmitter()).toString(), 'String');
        expect(toSimple.optionalParameters, hasLength(2));

        final body = toSimple.body?.accept(DartEmitter()).toString() ?? '';
        expect(
          body,
          'rawValue.toSimple(explode: explode, allowEmpty: allowEmpty)',
        );
        expect(toSimple.lambda, isTrue);
      });

      test('generates toSimple in complete enum code for string enum', () {
        final model = EnumModel<String>(
          name: 'Color',
          values: const {'red', 'green', 'blue'},
          isNullable: false,
          context: Context.initial(),
        );

        final result = generator.generate(model);

        const expectedToSimpleMethod = '''
          _i2.String toSimple({ required _i2.bool explode, required _i2.bool allowEmpty, }) => rawValue.toSimple(explode: explode, allowEmpty: allowEmpty);
        ''';
        expect(
          collapseWhitespace(result.code),
          contains(collapseWhitespace(expectedToSimpleMethod)),
        );
      });

      test('generates toSimple in complete enum code for int enum', () {
        final model = EnumModel<int>(
          name: 'Status',
          values: const {1, 2, 3},
          isNullable: false,
          context: Context.initial(),
        );

        final result = generator.generate(model);

        const expectedToSimpleMethod = '''
          _i2.String toSimple({ required _i2.bool explode, required _i2.bool allowEmpty, }) => rawValue.toSimple(explode: explode, allowEmpty: allowEmpty);
        ''';
        expect(
          collapseWhitespace(result.code),
          contains(collapseWhitespace(expectedToSimpleMethod)),
        );
      });
    });
  });
}
