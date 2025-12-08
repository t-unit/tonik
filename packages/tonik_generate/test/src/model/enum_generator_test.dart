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
    );
  });

  group('EnumGenerator', () {
    test('generates currentEncodingShape getter', () {
      final model = EnumModel<String>(
        isDeprecated: false,
        name: 'Color',
        values: {
          const EnumEntry(value: 'red'),
          const EnumEntry(value: 'green'),
          const EnumEntry(value: 'blue'),
        },
        isNullable: false,
        context: Context.initial().push('test'),
      );

      final generated = generator.generateEnum(model, 'Color');
      final emitter = DartEmitter(useNullSafetySyntax: true);

      final getter = generated.enumValue.methods.firstWhere(
        (m) => m.name == 'currentEncodingShape',
      );

      expect(getter.type, MethodType.getter);
      expect(
        getter.returns?.accept(emitter).toString(),
        'EncodingShape',
      );
      expect(getter.lambda, isTrue);
      expect(
        getter.body?.accept(emitter).toString(),
        'EncodingShape.simple',
      );
    });

    test('generates enum with string values', () {
      final model = EnumModel<String>(
        isDeprecated: false,
        name: 'Color',
        values: {
          const EnumEntry(value: 'red'),
          const EnumEntry(value: 'green'),
          const EnumEntry(value: 'blue'),
        },
        isNullable: false,
        context: Context.initial().push('test'),
      );

      final result = generator.generate(model);
      final generated = generator.generateEnum(model, 'Color');

      expect(result.filename, 'color.dart');
      expect(result.code, contains('enum Color'));
      expect(result.code, isNot(contains('typedef')));

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
        isDeprecated: false,
        name: 'Status',
        values: {
          const EnumEntry(value: 'active'),
          const EnumEntry(value: 'inactive'),
        },
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
        isDeprecated: false,
        name: 'Status',
        values: {
          const EnumEntry(value: 'active'),
          const EnumEntry(value: 'inactive'),
        },
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

    test('generates non-nullable enum', () {
      final model = EnumModel<String>(
        isDeprecated: false,
        name: 'Color',
        values: {
          const EnumEntry(value: 'red'),
          const EnumEntry(value: 'green'),
          const EnumEntry(value: 'blue'),
        },
        isNullable: false,
        context: Context.initial(),
      );

      final result = generator.generate(model);
      final generated = generator.generateEnum(model, 'Color');

      expect(result.code, contains('enum Color'));
      expect(result.code, isNot(contains('typedef')));
      expect(result.filename, 'color.dart');

      expect(generated.enumValue.name, 'Color');
      expect(generated.enumValue.values, hasLength(3));
      expect(generated.enumValue.values.first.name, 'red');
      expect(generated.typedefValue, isNull);
    });

    test('generates enum with integer values', () {
      final model = EnumModel<int>(
        isDeprecated: false,
        name: 'Status',
        values: {
          const EnumEntry(value: 1),
          const EnumEntry(value: 2),
          const EnumEntry(value: 3),
        },
        isNullable: false,
        context: Context.initial().push('test'),
      );

      final result = generator.generate(model);
      final generated = generator.generateEnum(model, 'Status');

      expect(result.filename, 'status.dart');
      expect(result.code, contains('enum Status'));
      expect(result.code, isNot(contains('typedef')));

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

    test(
      'generates enum with underscore-only values using normalized names',
      () {
        final model = EnumModel<String>(
          isDeprecated: false,
          name: 'Placeholder',
          values: {
            const EnumEntry(value: '_'),
            const EnumEntry(value: '__'),
            const EnumEntry(value: '___'),
          },
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
      },
    );

    test(
      'generates enum file with correct name and content for integer values',
      () {
        final model = EnumModel<int>(
          isDeprecated: false,
          name: 'Status',
          values: {
            const EnumEntry(value: 100),
            const EnumEntry(value: 200),
            const EnumEntry(value: 404),
          },
          isNullable: false,
          context: Context.initial().push('test'),
        );

        final result = generator.generate(model);

        expect(result.filename, 'status.dart');
        expect(result.code, contains('enum Status'));
        expect(result.code, isNot(contains('typedef')));
      },
    );

    test('throws error for unsupported enum value types like double', () {
      final model = EnumModel<double>(
        isDeprecated: false,
        name: 'Rate',
        values: {
          const EnumEntry(value: 0.5),
          const EnumEntry(value: 1.5),
          const EnumEntry(value: 2.5),
        },
        isNullable: false,
        context: Context.initial().push('test'),
      );

      expect(() => generator.generate(model), throwsA(isA<ArgumentError>()));
    });

    test(
      'throws ArgumentError for unsupported enum value type in generateEnum',
      () {
        final model = EnumModel<double>(
          isDeprecated: false,
          name: 'Status',
          values: {
            const EnumEntry(value: 1),
            const EnumEntry(value: 2),
          },
          isNullable: false,
          context: Context.initial().push('test'),
        );

        expect(
          () => generator.generateEnum(model, 'Status'),
          throwsArgumentError,
        );
      },
    );

    group('doc comments', () {
      test('generates enum with doc comment from description', () {
        final model = EnumModel<String>(
          isDeprecated: false,
          description: 'The color options available',
          name: 'Color',
          values: {
            const EnumEntry(value: 'red'),
            const EnumEntry(value: 'green'),
            const EnumEntry(value: 'blue'),
          },
          isNullable: false,
          context: Context.initial(),
        );

        final generated = generator.generateEnum(model, 'Color');

        expect(generated.enumValue.docs, ['/// The color options available']);
      });

      test('generates enum with multiline doc comment', () {
        final model = EnumModel<String>(
          isDeprecated: false,
          description: 'The status of an order.\nCan change over time.',
          name: 'Status',
          values: {
            const EnumEntry(value: 'pending'),
            const EnumEntry(value: 'complete'),
          },
          isNullable: false,
          context: Context.initial(),
        );

        final generated = generator.generateEnum(model, 'Status');

        expect(generated.enumValue.docs, [
          '/// The status of an order.',
          '/// Can change over time.',
        ]);
      });

      test('generates enum without doc comment when description is null', () {
        final model = EnumModel<String>(
          isDeprecated: false,
          name: 'Color',
          values: {
            const EnumEntry(value: 'red'),
            const EnumEntry(value: 'green'),
            const EnumEntry(value: 'blue'),
          },
          isNullable: false,
          context: Context.initial(),
        );

        final generated = generator.generateEnum(model, 'Color');

        expect(generated.enumValue.docs, isEmpty);
      });

      test('generates enum without doc comment when description is empty', () {
        final model = EnumModel<String>(
          isDeprecated: false,
          description: '',
          name: 'Color',
          values: {
            const EnumEntry(value: 'red'),
            const EnumEntry(value: 'green'),
            const EnumEntry(value: 'blue'),
          },
          isNullable: false,
          context: Context.initial(),
        );

        final generated = generator.generateEnum(model, 'Color');

        expect(generated.enumValue.docs, isEmpty);
      });
    });

    group('enum value name normalization', () {
      test('handles string values', () {
        final model = EnumModel<String>(
          isDeprecated: false,
          name: 'Status',
          values: {
            const EnumEntry(value: 'active'),
            const EnumEntry(value: 'inactive'),
          },
          isNullable: false,
          context: Context.initial().push('test'),
        );

        final generated = generator.generateEnum(model, 'Status');
        expect(generated.enumValue.values[0].name, 'active');
        expect(generated.enumValue.values[1].name, 'inactive');
      });

      test('handles integer values', () {
        final model = EnumModel<int>(
          isDeprecated: false,
          name: 'Status',
          values: {
            const EnumEntry(value: 1),
            const EnumEntry(value: 2),
            const EnumEntry(value: 3),
          },
          isNullable: false,
          context: Context.initial().push('test'),
        );

        final generated = generator.generateEnum(model, 'Status');
        expect(generated.enumValue.values[0].name, 'one');
        expect(generated.enumValue.values[1].name, 'two');
        expect(generated.enumValue.values[2].name, 'three');
      });
    });

    group('JSON serialization', () {
      test('generates toJson method', () {
        final model = EnumModel<String>(
          isDeprecated: false,
          name: 'Color',
          values: {
            const EnumEntry(value: 'red'),
            const EnumEntry(value: 'green'),
            const EnumEntry(value: 'blue'),
          },
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
          isDeprecated: false,
          name: 'Color',
          values: {
            const EnumEntry(value: 'red'),
            const EnumEntry(value: 'green'),
            const EnumEntry(value: 'blue'),
          },
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
          isDeprecated: false,
          name: 'Status',
          values: {
            const EnumEntry(value: 200),
            const EnumEntry(value: 404),
            const EnumEntry(value: 500),
          },
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
          isDeprecated: false,
          name: 'Status',
          values: {
            const EnumEntry(value: 'active'),
            const EnumEntry(value: 'inactive'),
          },
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

    group('fromSimple factory constructor', () {
      test('generates fromSimple constructor for string enum', () {
        final model = EnumModel<String>(
          isDeprecated: false,
          name: 'Color',
          values: {
            const EnumEntry(value: 'red'),
            const EnumEntry(value: 'green'),
            const EnumEntry(value: 'blue'),
          },
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
        expect(fromSimple.optionalParameters, hasLength(2));

        final explodeParam = fromSimple.optionalParameters.firstWhere(
          (p) => p.name == 'explode',
        );
        expect(explodeParam.type?.accept(DartEmitter()).toString(), 'bool');
        expect(explodeParam.named, isTrue);
        expect(explodeParam.required, isTrue);

        final contextParam = fromSimple.optionalParameters.firstWhere(
          (p) => p.name == 'context',
        );
        expect(contextParam.type?.accept(DartEmitter()).toString(), 'String?');
        expect(contextParam.named, isTrue);
        expect(contextParam.required, isFalse);

        final body = fromSimple.body?.accept(DartEmitter()).toString() ?? '';
        const expectedBody = '''
          return Color.fromJson(value.decodeSimpleString(context: context));
        ''';
        expect(collapseWhitespace(body), collapseWhitespace(expectedBody));
      });

      test('generates fromSimple constructor for int enum', () {
        final model = EnumModel<int>(
          isDeprecated: false,
          name: 'Status',
          values: {
            const EnumEntry(value: 1),
            const EnumEntry(value: 2),
            const EnumEntry(value: 3),
          },
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
        expect(fromSimple.optionalParameters, hasLength(2));

        final explodeParam = fromSimple.optionalParameters.firstWhere(
          (p) => p.name == 'explode',
        );
        expect(explodeParam.type?.accept(DartEmitter()).toString(), 'bool');
        expect(explodeParam.named, isTrue);
        expect(explodeParam.required, isTrue);

        final contextParam = fromSimple.optionalParameters.firstWhere(
          (p) => p.name == 'context',
        );
        expect(contextParam.type?.accept(DartEmitter()).toString(), 'String?');
        expect(contextParam.named, isTrue);
        expect(contextParam.required, isFalse);

        final body = fromSimple.body?.accept(DartEmitter()).toString() ?? '';
        const expectedBody = '''
          return Status.fromJson(value.decodeSimpleInt(context: context));
        ''';
        expect(collapseWhitespace(body), collapseWhitespace(expectedBody));
      });

      test('generates fromSimple constructor for nullable string enum', () {
        final model = EnumModel<String>(
          isDeprecated: false,
          name: 'Status',
          values: {
            const EnumEntry(value: 'active'),
            const EnumEntry(value: 'inactive'),
          },
          isNullable: true,
          context: Context.initial(),
        );

        final generated = generator.generateEnum(model, 'Status');
        final fromSimple = generated.enumValue.constructors.firstWhere(
          (c) => c.name == 'fromSimple',
        );

        final body = fromSimple.body?.accept(DartEmitter()).toString() ?? '';
        const expectedBody = '''
          return RawStatus.fromJson(value.decodeSimpleString(context: context));
        ''';
        expect(collapseWhitespace(body), collapseWhitespace(expectedBody));
      });

      test('generates fromSimple constructor for nullable int enum', () {
        final model = EnumModel<int>(
          isDeprecated: false,
          name: 'Status',
          values: {
            const EnumEntry(value: 1),
            const EnumEntry(value: 2),
            const EnumEntry(value: 3),
          },
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
          return RawStatus.fromJson(value.decodeSimpleInt(context: context));
        ''';
        expect(collapseWhitespace(body), collapseWhitespace(expectedBody));
      });
    });

    group('toSimple method generation', () {
      test('generates toSimple method for string enum', () {
        final model = EnumModel<String>(
          isDeprecated: false,
          name: 'Color',
          values: {
            const EnumEntry(value: 'red'),
            const EnumEntry(value: 'green'),
            const EnumEntry(value: 'blue'),
          },
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
          isDeprecated: false,
          name: 'Status',
          values: {
            const EnumEntry(value: 1),
            const EnumEntry(value: 2),
            const EnumEntry(value: 3),
          },
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
          isDeprecated: false,
          name: 'Status',
          values: {
            const EnumEntry(value: 'active'),
            const EnumEntry(value: 'inactive'),
          },
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
          isDeprecated: false,
          name: 'Status',
          values: {
            const EnumEntry(value: 100),
            const EnumEntry(value: 200),
            const EnumEntry(value: 300),
          },
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
          isDeprecated: false,
          name: 'Color',
          values: {
            const EnumEntry(value: 'red'),
            const EnumEntry(value: 'green'),
            const EnumEntry(value: 'blue'),
          },
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
          isDeprecated: false,
          name: 'Status',
          values: {
            const EnumEntry(value: 1),
            const EnumEntry(value: 2),
            const EnumEntry(value: 3),
          },
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

    group('fromForm factory constructor', () {
      test('generates fromForm constructor for string enum', () {
        final model = EnumModel<String>(
          isDeprecated: false,
          name: 'Color',
          values: {
            const EnumEntry(value: 'red'),
            const EnumEntry(value: 'green'),
            const EnumEntry(value: 'blue'),
          },
          isNullable: false,
          context: Context.initial(),
        );

        final generated = generator.generateEnum(model, 'Color');
        final fromForm = generated.enumValue.constructors.firstWhere(
          (c) => c.name == 'fromForm',
        );

        expect(fromForm.factory, isTrue);
        expect(
          fromForm.requiredParameters.single.type
              ?.accept(DartEmitter())
              .toString(),
          'String?',
        );
        expect(fromForm.requiredParameters.single.name, 'value');
        expect(fromForm.optionalParameters, hasLength(2));

        final explodeParam = fromForm.optionalParameters.firstWhere(
          (p) => p.name == 'explode',
        );
        expect(explodeParam.type?.accept(DartEmitter()).toString(), 'bool');
        expect(explodeParam.named, isTrue);
        expect(explodeParam.required, isTrue);

        final contextParam = fromForm.optionalParameters.firstWhere(
          (p) => p.name == 'context',
        );
        expect(contextParam.type?.accept(DartEmitter()).toString(), 'String?');
        expect(contextParam.named, isTrue);
        expect(contextParam.required, isFalse);

        final body = fromForm.body?.accept(DartEmitter()).toString() ?? '';
        const expectedBody = '''
          return Color.fromJson(value.decodeFormString(context: context));
        ''';
        expect(collapseWhitespace(body), collapseWhitespace(expectedBody));
      });

      test('generates fromForm constructor for int enum', () {
        final model = EnumModel<int>(
          isDeprecated: false,
          name: 'Status',
          values: {
            const EnumEntry(value: 1),
            const EnumEntry(value: 2),
            const EnumEntry(value: 3),
          },
          isNullable: false,
          context: Context.initial(),
        );

        final generated = generator.generateEnum(model, 'Status');
        final fromForm = generated.enumValue.constructors.firstWhere(
          (c) => c.name == 'fromForm',
        );

        expect(fromForm.factory, isTrue);
        expect(
          fromForm.requiredParameters.single.type
              ?.accept(DartEmitter())
              .toString(),
          'String?',
        );
        expect(fromForm.requiredParameters.single.name, 'value');
        expect(fromForm.optionalParameters, hasLength(2));

        final explodeParam = fromForm.optionalParameters.firstWhere(
          (p) => p.name == 'explode',
        );
        expect(explodeParam.type?.accept(DartEmitter()).toString(), 'bool');
        expect(explodeParam.named, isTrue);
        expect(explodeParam.required, isTrue);

        final contextParam = fromForm.optionalParameters.firstWhere(
          (p) => p.name == 'context',
        );
        expect(contextParam.type?.accept(DartEmitter()).toString(), 'String?');
        expect(contextParam.named, isTrue);
        expect(contextParam.required, isFalse);

        final body = fromForm.body?.accept(DartEmitter()).toString() ?? '';
        const expectedBody = '''
          return Status.fromJson(value.decodeFormInt(context: context));
        ''';
        expect(collapseWhitespace(body), collapseWhitespace(expectedBody));
      });

      test('generates fromForm constructor for nullable string enum', () {
        final model = EnumModel<String>(
          isDeprecated: false,
          name: 'Status',
          values: {
            const EnumEntry(value: 'active'),
            const EnumEntry(value: 'inactive'),
          },
          isNullable: true,
          context: Context.initial(),
        );

        final generated = generator.generateEnum(model, 'Status');
        final fromForm = generated.enumValue.constructors.firstWhere(
          (c) => c.name == 'fromForm',
        );

        final body = fromForm.body?.accept(DartEmitter()).toString() ?? '';
        const expectedBody = '''
          return RawStatus.fromJson(value.decodeFormString(context: context));
        ''';
        expect(collapseWhitespace(body), collapseWhitespace(expectedBody));
      });

      test('generates fromForm constructor for nullable int enum', () {
        final model = EnumModel<int>(
          isDeprecated: false,
          name: 'Status',
          values: {
            const EnumEntry(value: 1),
            const EnumEntry(value: 2),
            const EnumEntry(value: 3),
          },
          isNullable: true,
          context: Context.initial(),
        );

        final generated = generator.generateEnum(model, 'Status');
        final fromForm = generated.enumValue.constructors.firstWhere(
          (c) => c.name == 'fromForm',
        );

        expect(fromForm.factory, isTrue);
        expect(
          fromForm.requiredParameters.single.type
              ?.accept(DartEmitter())
              .toString(),
          'String?',
        );
        expect(fromForm.requiredParameters.single.name, 'value');

        final body = fromForm.body?.accept(DartEmitter()).toString() ?? '';
        const expectedBody = '''
          return RawStatus.fromJson(value.decodeFormInt(context: context));
        ''';
        expect(collapseWhitespace(body), collapseWhitespace(expectedBody));
      });
    });

    group('toForm method generation', () {
      test('generates toForm method for string enum', () {
        final model = EnumModel<String>(
          isDeprecated: false,
          name: 'Color',
          values: {
            const EnumEntry(value: 'red'),
            const EnumEntry(value: 'green'),
            const EnumEntry(value: 'blue'),
          },
          isNullable: false,
          context: Context.initial(),
        );

        final generated = generator.generateEnum(model, 'Color');
        final toForm = generated.enumValue.methods.firstWhere(
          (m) => m.name == 'toForm',
        );

        expect(toForm.returns?.accept(DartEmitter()).toString(), 'String');
        expect(toForm.optionalParameters, hasLength(2));

        final explodeParam = toForm.optionalParameters.firstWhere(
          (p) => p.name == 'explode',
        );
        expect(explodeParam.type?.accept(DartEmitter()).toString(), 'bool');
        expect(explodeParam.named, isTrue);
        expect(explodeParam.required, isTrue);

        final allowEmptyParam = toForm.optionalParameters.firstWhere(
          (p) => p.name == 'allowEmpty',
        );
        expect(allowEmptyParam.type?.accept(DartEmitter()).toString(), 'bool');
        expect(allowEmptyParam.named, isTrue);
        expect(allowEmptyParam.required, isTrue);

        final body = toForm.body?.accept(DartEmitter()).toString() ?? '';
        expect(
          body,
          'rawValue.toForm(explode: explode, allowEmpty: allowEmpty)',
        );
        expect(toForm.lambda, isTrue);
      });

      test('generates toForm method for int enum', () {
        final model = EnumModel<int>(
          isDeprecated: false,
          name: 'Status',
          values: {
            const EnumEntry(value: 1),
            const EnumEntry(value: 2),
            const EnumEntry(value: 3),
          },
          isNullable: false,
          context: Context.initial(),
        );

        final generated = generator.generateEnum(model, 'Status');
        final toForm = generated.enumValue.methods.firstWhere(
          (m) => m.name == 'toForm',
        );

        expect(toForm.returns?.accept(DartEmitter()).toString(), 'String');
        expect(toForm.optionalParameters, hasLength(2));

        final body = toForm.body?.accept(DartEmitter()).toString() ?? '';
        expect(
          body,
          'rawValue.toForm(explode: explode, allowEmpty: allowEmpty)',
        );
        expect(toForm.lambda, isTrue);
      });

      test('generates toForm method for nullable string enum', () {
        final model = EnumModel<String>(
          isDeprecated: false,
          name: 'Status',
          values: {
            const EnumEntry(value: 'active'),
            const EnumEntry(value: 'inactive'),
          },
          isNullable: true,
          context: Context.initial(),
        );

        final generated = generator.generateEnum(model, 'Status');
        final toForm = generated.enumValue.methods.firstWhere(
          (m) => m.name == 'toForm',
        );

        expect(toForm.returns?.accept(DartEmitter()).toString(), 'String');
        expect(toForm.optionalParameters, hasLength(2));

        final body = toForm.body?.accept(DartEmitter()).toString() ?? '';
        expect(
          body,
          'rawValue.toForm(explode: explode, allowEmpty: allowEmpty)',
        );
        expect(toForm.lambda, isTrue);
      });

      test('generates toForm method for nullable int enum', () {
        final model = EnumModel<int>(
          isDeprecated: false,
          name: 'Status',
          values: {
            const EnumEntry(value: 100),
            const EnumEntry(value: 200),
            const EnumEntry(value: 300),
          },
          isNullable: true,
          context: Context.initial(),
        );

        final generated = generator.generateEnum(model, 'Status');
        final toForm = generated.enumValue.methods.firstWhere(
          (m) => m.name == 'toForm',
        );

        expect(toForm.returns?.accept(DartEmitter()).toString(), 'String');
        expect(toForm.optionalParameters, hasLength(2));

        final body = toForm.body?.accept(DartEmitter()).toString() ?? '';
        expect(
          body,
          'rawValue.toForm(explode: explode, allowEmpty: allowEmpty)',
        );
        expect(toForm.lambda, isTrue);
      });

      test('generates toForm in complete enum code for string enum', () {
        final model = EnumModel<String>(
          isDeprecated: false,
          name: 'Color',
          values: {
            const EnumEntry(value: 'red'),
            const EnumEntry(value: 'green'),
            const EnumEntry(value: 'blue'),
          },
          isNullable: false,
          context: Context.initial(),
        );

        final result = generator.generate(model);

        const expectedToFormMethod = '''
          _i2.String toForm({ required _i2.bool explode, required _i2.bool allowEmpty, }) => rawValue.toForm(explode: explode, allowEmpty: allowEmpty);
        ''';
        expect(
          collapseWhitespace(result.code),
          contains(collapseWhitespace(expectedToFormMethod)),
        );
      });

      test('generates toForm in complete enum code for int enum', () {
        final model = EnumModel<int>(
          isDeprecated: false,
          name: 'Status',
          values: {
            const EnumEntry(value: 1),
            const EnumEntry(value: 2),
            const EnumEntry(value: 3),
          },
          isNullable: false,
          context: Context.initial(),
        );

        final result = generator.generate(model);

        const expectedToFormMethod = '''
          _i2.String toForm({ required _i2.bool explode, required _i2.bool allowEmpty, }) => rawValue.toForm(explode: explode, allowEmpty: allowEmpty);
        ''';
        expect(
          collapseWhitespace(result.code),
          contains(collapseWhitespace(expectedToFormMethod)),
        );
      });
    });

    group('toLabel method generation', () {
      test('generates toLabel method for string enum', () {
        final model = EnumModel<String>(
          isDeprecated: false,
          name: 'Color',
          values: {
            const EnumEntry(value: 'red'),
            const EnumEntry(value: 'green'),
            const EnumEntry(value: 'blue'),
          },
          isNullable: false,
          context: Context.initial(),
        );

        final generated = generator.generateEnum(model, 'Color');
        final toLabel = generated.enumValue.methods.firstWhere(
          (m) => m.name == 'toLabel',
        );

        expect(toLabel.returns?.accept(DartEmitter()).toString(), 'String');
        expect(toLabel.optionalParameters, hasLength(2));

        final explodeParam = toLabel.optionalParameters.firstWhere(
          (p) => p.name == 'explode',
        );
        expect(explodeParam.type?.accept(DartEmitter()).toString(), 'bool');
        expect(explodeParam.named, isTrue);
        expect(explodeParam.required, isTrue);

        final allowEmptyParam = toLabel.optionalParameters.firstWhere(
          (p) => p.name == 'allowEmpty',
        );
        expect(allowEmptyParam.type?.accept(DartEmitter()).toString(), 'bool');
        expect(allowEmptyParam.named, isTrue);
        expect(allowEmptyParam.required, isTrue);

        final body = toLabel.body?.accept(DartEmitter()).toString() ?? '';
        expect(
          body,
          'rawValue.toLabel(explode: explode, allowEmpty: allowEmpty)',
        );
      });

      test('generates toLabel method for int enum', () {
        final model = EnumModel<int>(
          isDeprecated: false,
          name: 'Status',
          values: {
            const EnumEntry(value: 1),
            const EnumEntry(value: 2),
            const EnumEntry(value: 3),
          },
          isNullable: false,
          context: Context.initial(),
        );

        final generated = generator.generateEnum(model, 'Status');
        final toLabel = generated.enumValue.methods.firstWhere(
          (m) => m.name == 'toLabel',
        );

        expect(toLabel.returns?.accept(DartEmitter()).toString(), 'String');
        expect(toLabel.optionalParameters, hasLength(2));

        final body = toLabel.body?.accept(DartEmitter()).toString() ?? '';
        expect(
          body,
          'rawValue.toLabel(explode: explode, allowEmpty: allowEmpty)',
        );
      });

      test('generates toLabel method for nullable enum', () {
        final model = EnumModel<String>(
          isDeprecated: false,
          name: 'Priority',
          values: {
            const EnumEntry(value: 'low'),
            const EnumEntry(value: 'medium'),
            const EnumEntry(value: 'high'),
          },
          isNullable: true,
          context: Context.initial(),
        );

        final generated = generator.generateEnum(model, 'Priority');
        final toLabel = generated.enumValue.methods.firstWhere(
          (m) => m.name == 'toLabel',
        );

        expect(toLabel.returns?.accept(DartEmitter()).toString(), 'String');
        expect(toLabel.optionalParameters, hasLength(2));

        final body = toLabel.body?.accept(DartEmitter()).toString() ?? '';
        expect(
          body,
          'rawValue.toLabel(explode: explode, allowEmpty: allowEmpty)',
        );
      });

      test('toLabel method is included in generated code for string enum', () {
        final model = EnumModel<String>(
          isDeprecated: false,
          name: 'Color',
          values: {
            const EnumEntry(value: 'red'),
            const EnumEntry(value: 'green'),
            const EnumEntry(value: 'blue'),
          },
          isNullable: false,
          context: Context.initial(),
        );

        final result = generator.generate(model);

        const expectedToLabelMethod = '''
          _i2.String toLabel({ required _i2.bool explode, required _i2.bool allowEmpty, }) => rawValue.toLabel(explode: explode, allowEmpty: allowEmpty);
        ''';
        expect(
          collapseWhitespace(result.code),
          contains(collapseWhitespace(expectedToLabelMethod)),
        );
      });

      test('toLabel method is included in generated code for int enum', () {
        final model = EnumModel<int>(
          isDeprecated: false,
          name: 'Status',
          values: {
            const EnumEntry(value: 1),
            const EnumEntry(value: 2),
            const EnumEntry(value: 3),
          },
          isNullable: false,
          context: Context.initial(),
        );

        final result = generator.generate(model);

        const expectedToLabelMethod = '''
          _i2.String toLabel({ required _i2.bool explode, required _i2.bool allowEmpty, }) => rawValue.toLabel(explode: explode, allowEmpty: allowEmpty);
        ''';
        expect(
          collapseWhitespace(result.code),
          contains(collapseWhitespace(expectedToLabelMethod)),
        );
      });

      test(
        'toLabel method is included in generated code for nullable enum',
        () {
          final model = EnumModel<String>(
            isDeprecated: false,
            name: 'Priority',
            values: {
              const EnumEntry(value: 'low'),
              const EnumEntry(value: 'medium'),
              const EnumEntry(value: 'high'),
            },
            isNullable: true,
            context: Context.initial(),
          );

          final result = generator.generate(model);

          const expectedToLabelMethod = '''
          _i2.String toLabel({ required _i2.bool explode, required _i2.bool allowEmpty, }) => rawValue.toLabel(explode: explode, allowEmpty: allowEmpty);
        ''';
          expect(
            collapseWhitespace(result.code),
            contains(collapseWhitespace(expectedToLabelMethod)),
          );
        },
      );
    });

    group('toMatrix method generation', () {
      test('generates toMatrix method for string enum', () {
        final model = EnumModel<String>(
          isDeprecated: false,
          name: 'Color',
          values: {
            const EnumEntry(value: 'red'),
            const EnumEntry(value: 'green'),
            const EnumEntry(value: 'blue'),
          },
          isNullable: false,
          context: Context.initial(),
        );

        final generated = generator.generateEnum(model, 'Color');
        final toMatrix = generated.enumValue.methods.firstWhere(
          (m) => m.name == 'toMatrix',
        );

        expect(toMatrix.returns?.accept(DartEmitter()).toString(), 'String');
        expect(toMatrix.requiredParameters, hasLength(1));
        expect(toMatrix.requiredParameters.first.name, 'paramName');
        expect(
          toMatrix.requiredParameters.first.type
              ?.accept(DartEmitter())
              .toString(),
          'String',
        );
        expect(toMatrix.optionalParameters, hasLength(2));

        final explodeParam = toMatrix.optionalParameters.firstWhere(
          (p) => p.name == 'explode',
        );
        expect(explodeParam.type?.accept(DartEmitter()).toString(), 'bool');
        expect(explodeParam.named, isTrue);
        expect(explodeParam.required, isTrue);

        final allowEmptyParam = toMatrix.optionalParameters.firstWhere(
          (p) => p.name == 'allowEmpty',
        );
        expect(allowEmptyParam.type?.accept(DartEmitter()).toString(), 'bool');
        expect(allowEmptyParam.named, isTrue);
        expect(allowEmptyParam.required, isTrue);

        final body = toMatrix.body?.accept(DartEmitter()).toString() ?? '';
        expect(
          body,
          'rawValue.toMatrix(paramName, explode: explode, '
          'allowEmpty: allowEmpty)',
        );
        expect(toMatrix.lambda, isTrue);
      });

      test('generates toMatrix method for int enum', () {
        final model = EnumModel<int>(
          isDeprecated: false,
          name: 'Status',
          values: {
            const EnumEntry(value: 1),
            const EnumEntry(value: 2),
            const EnumEntry(value: 3),
          },
          isNullable: false,
          context: Context.initial(),
        );

        final generated = generator.generateEnum(model, 'Status');
        final toMatrix = generated.enumValue.methods.firstWhere(
          (m) => m.name == 'toMatrix',
        );

        expect(toMatrix.returns?.accept(DartEmitter()).toString(), 'String');
        expect(toMatrix.requiredParameters, hasLength(1));
        expect(toMatrix.requiredParameters.first.name, 'paramName');
        expect(
          toMatrix.requiredParameters.first.type
              ?.accept(DartEmitter())
              .toString(),
          'String',
        );
        expect(toMatrix.optionalParameters, hasLength(2));

        final body = toMatrix.body?.accept(DartEmitter()).toString() ?? '';
        expect(
          body,
          'rawValue.toMatrix(paramName, explode: explode, '
          'allowEmpty: allowEmpty)',
        );
        expect(toMatrix.lambda, isTrue);
      });

      test('generates toMatrix method for nullable string enum', () {
        final model = EnumModel<String>(
          isDeprecated: false,
          name: 'Status',
          values: {
            const EnumEntry(value: 'active'),
            const EnumEntry(value: 'inactive'),
          },
          isNullable: true,
          context: Context.initial(),
        );

        final generated = generator.generateEnum(model, 'Status');
        final toMatrix = generated.enumValue.methods.firstWhere(
          (m) => m.name == 'toMatrix',
        );

        expect(toMatrix.returns?.accept(DartEmitter()).toString(), 'String');
        expect(toMatrix.requiredParameters, hasLength(1));
        expect(toMatrix.requiredParameters.first.name, 'paramName');
        expect(
          toMatrix.requiredParameters.first.type
              ?.accept(DartEmitter())
              .toString(),
          'String',
        );
        expect(toMatrix.optionalParameters, hasLength(2));

        final body = toMatrix.body?.accept(DartEmitter()).toString() ?? '';
        expect(
          body,
          'rawValue.toMatrix(paramName, explode: explode, '
          'allowEmpty: allowEmpty)',
        );
        expect(toMatrix.lambda, isTrue);
      });

      test('generates toMatrix method for nullable int enum', () {
        final model = EnumModel<int>(
          isDeprecated: false,
          name: 'Status',
          values: {
            const EnumEntry(value: 100),
            const EnumEntry(value: 200),
            const EnumEntry(value: 300),
          },
          isNullable: true,
          context: Context.initial(),
        );

        final generated = generator.generateEnum(model, 'Status');
        final toMatrix = generated.enumValue.methods.firstWhere(
          (m) => m.name == 'toMatrix',
        );

        expect(toMatrix.returns?.accept(DartEmitter()).toString(), 'String');
        expect(toMatrix.requiredParameters, hasLength(1));
        expect(toMatrix.requiredParameters.first.name, 'paramName');
        expect(
          toMatrix.requiredParameters.first.type
              ?.accept(DartEmitter())
              .toString(),
          'String',
        );
        expect(toMatrix.optionalParameters, hasLength(2));

        final body = toMatrix.body?.accept(DartEmitter()).toString() ?? '';
        expect(
          body,
          'rawValue.toMatrix(paramName, explode: explode, '
          'allowEmpty: allowEmpty)',
        );
        expect(toMatrix.lambda, isTrue);
      });

      test('toMatrix method is included in generated code for string enum', () {
        final model = EnumModel<String>(
          isDeprecated: false,
          name: 'Color',
          values: {
            const EnumEntry(value: 'red'),
            const EnumEntry(value: 'green'),
            const EnumEntry(value: 'blue'),
          },
          isNullable: false,
          context: Context.initial(),
        );

        final result = generator.generate(model);

        const expectedToMatrixMethod = '''
          _i2.String toMatrix( _i2.String paramName, { required _i2.bool explode, required _i2.bool allowEmpty, }) => rawValue.toMatrix(paramName, explode: explode, allowEmpty: allowEmpty);
        ''';
        expect(
          collapseWhitespace(result.code),
          contains(collapseWhitespace(expectedToMatrixMethod)),
        );
      });

      test('toMatrix method is included in generated code for int enum', () {
        final model = EnumModel<int>(
          isDeprecated: false,
          name: 'Status',
          values: {
            const EnumEntry(value: 1),
            const EnumEntry(value: 2),
            const EnumEntry(value: 3),
          },
          isNullable: false,
          context: Context.initial(),
        );

        final result = generator.generate(model);

        const expectedToMatrixMethod = '''
          _i2.String toMatrix( _i2.String paramName, { required _i2.bool explode, required _i2.bool allowEmpty, }) => rawValue.toMatrix(paramName, explode: explode, allowEmpty: allowEmpty);
        ''';
        expect(
          collapseWhitespace(result.code),
          contains(collapseWhitespace(expectedToMatrixMethod)),
        );
      });

      test(
        'toMatrix method is included in generated code for nullable enum',
        () {
          final model = EnumModel<String>(
            isDeprecated: false,
            name: 'Priority',
            values: {
              const EnumEntry(value: 'low'),
              const EnumEntry(value: 'medium'),
              const EnumEntry(value: 'high'),
            },
            isNullable: true,
            context: Context.initial(),
          );

          final result = generator.generate(model);

          const expectedToMatrixMethod = '''
          _i2.String toMatrix( _i2.String paramName, { required _i2.bool explode, required _i2.bool allowEmpty, }) => rawValue.toMatrix(paramName, explode: explode, allowEmpty: allowEmpty);
        ''';
          expect(
            collapseWhitespace(result.code),
            contains(collapseWhitespace(expectedToMatrixMethod)),
          );
        },
      );
    });

    group('uriEncode method generation', () {
      test('generates uriEncode method for string enum', () {
        final model = EnumModel<String>(
          isDeprecated: false,
          name: 'Color',
          values: {
            const EnumEntry(value: 'red'),
            const EnumEntry(value: 'green'),
            const EnumEntry(value: 'blue'),
          },
          isNullable: false,
          context: Context.initial(),
        );

        final generated = generator.generateEnum(model, 'Color');
        final uriEncode = generated.enumValue.methods.firstWhere(
          (m) => m.name == 'uriEncode',
        );

        expect(uriEncode.returns?.accept(DartEmitter()).toString(), 'String');
        expect(uriEncode.optionalParameters, hasLength(1));

        final allowEmptyParam = uriEncode.optionalParameters.firstWhere(
          (p) => p.name == 'allowEmpty',
        );
        expect(allowEmptyParam.type?.accept(DartEmitter()).toString(), 'bool');
        expect(allowEmptyParam.named, isTrue);
        expect(allowEmptyParam.required, isTrue);

        final body = uriEncode.body?.accept(DartEmitter()).toString() ?? '';
        expect(
          body,
          'rawValue.uriEncode(allowEmpty: allowEmpty)',
        );
        expect(uriEncode.lambda, isTrue);
      });

      test('generates uriEncode method for int enum', () {
        final model = EnumModel<int>(
          isDeprecated: false,
          name: 'Status',
          values: {
            const EnumEntry(value: 1),
            const EnumEntry(value: 2),
            const EnumEntry(value: 3),
          },
          isNullable: false,
          context: Context.initial(),
        );

        final generated = generator.generateEnum(model, 'Status');
        final uriEncode = generated.enumValue.methods.firstWhere(
          (m) => m.name == 'uriEncode',
        );

        expect(uriEncode.returns?.accept(DartEmitter()).toString(), 'String');
        expect(uriEncode.optionalParameters, hasLength(1));

        final body = uriEncode.body?.accept(DartEmitter()).toString() ?? '';
        expect(
          body,
          'rawValue.uriEncode(allowEmpty: allowEmpty)',
        );
        expect(uriEncode.lambda, isTrue);
      });

      test('generates uriEncode method for nullable string enum', () {
        final model = EnumModel<String>(
          isDeprecated: false,
          name: 'Status',
          values: {
            const EnumEntry(value: 'active'),
            const EnumEntry(value: 'inactive'),
          },
          isNullable: true,
          context: Context.initial(),
        );

        final generated = generator.generateEnum(model, 'Status');
        final uriEncode = generated.enumValue.methods.firstWhere(
          (m) => m.name == 'uriEncode',
        );

        expect(uriEncode.returns?.accept(DartEmitter()).toString(), 'String');
        expect(uriEncode.optionalParameters, hasLength(1));

        final body = uriEncode.body?.accept(DartEmitter()).toString() ?? '';
        expect(
          body,
          'rawValue.uriEncode(allowEmpty: allowEmpty)',
        );
        expect(uriEncode.lambda, isTrue);
      });

      test(
        'uriEncode method is included in generated code for string enum',
        () {
          final model = EnumModel<String>(
            isDeprecated: false,
            name: 'Color',
            values: {
              const EnumEntry(value: 'red'),
              const EnumEntry(value: 'green'),
              const EnumEntry(value: 'blue'),
            },
            isNullable: false,
            context: Context.initial(),
          );

          final result = generator.generate(model);

          const expectedUriEncodeMethod = '''
          _i2.String uriEncode({required _i2.bool allowEmpty}) => rawValue.uriEncode(allowEmpty: allowEmpty);
        ''';
          expect(
            collapseWhitespace(result.code),
            contains(collapseWhitespace(expectedUriEncodeMethod)),
          );
        },
      );

      test('uriEncode method is included in generated code for int enum', () {
        final model = EnumModel<int>(
          isDeprecated: false,
          name: 'Status',
          values: {
            const EnumEntry(value: 1),
            const EnumEntry(value: 2),
            const EnumEntry(value: 3),
          },
          isNullable: false,
          context: Context.initial(),
        );

        final result = generator.generate(model);

        const expectedUriEncodeMethod = '''
          _i2.String uriEncode({required _i2.bool allowEmpty}) => rawValue.uriEncode(allowEmpty: allowEmpty);
        ''';
        expect(
          collapseWhitespace(result.code),
          contains(collapseWhitespace(expectedUriEncodeMethod)),
        );
      });

      test(
        'uriEncode method is included in generated code for nullable enum',
        () {
          final model = EnumModel<String>(
            isDeprecated: false,
            name: 'Priority',
            values: {
              const EnumEntry(value: 'low'),
              const EnumEntry(value: 'medium'),
              const EnumEntry(value: 'high'),
            },
            isNullable: true,
            context: Context.initial(),
          );

          final result = generator.generate(model);

          const expectedUriEncodeMethod = '''
          _i2.String uriEncode({required _i2.bool allowEmpty}) => rawValue.uriEncode(allowEmpty: allowEmpty);
        ''';
          expect(
            collapseWhitespace(result.code),
            contains(collapseWhitespace(expectedUriEncodeMethod)),
          );
        },
      );
    });
  });
}
