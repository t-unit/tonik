import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/model/enum_generator.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';

void main() {
  late EnumGenerator generator;
  late NameGenerator nameGenerator;
  late NameManager nameManager;

  setUp(() {
    nameGenerator = NameGenerator();
    nameManager = NameManager(generator: nameGenerator);
    generator = EnumGenerator(nameManager: nameManager);
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

      expect(generated.enumValue.name, 'Color');
      expect(generated.typedefValue, isNull);
      expect(generated.enumValue.values, hasLength(3));
      expect(generated.enumValue.values[0].name, 'red');
      expect(generated.enumValue.values[1].name, 'green');
      expect(generated.enumValue.values[2].name, 'blue');

      // Check enum values have correct arguments with actual values
      expect(generated.enumValue.values[0].arguments, hasLength(1));
      expect(
        generated.enumValue.values[0].arguments[0]
            .accept(DartEmitter())
            .toString(),
        "r'red'",
      );
      expect(generated.enumValue.values[1].arguments, hasLength(1));
      expect(
        generated.enumValue.values[1].arguments[0]
            .accept(DartEmitter())
            .toString(),
        "r'green'",
      );
      expect(generated.enumValue.values[2].arguments, hasLength(1));
      expect(
        generated.enumValue.values[2].arguments[0]
            .accept(DartEmitter())
            .toString(),
        "r'blue'",
      );

      // Check rawValue field
      final rawValueField = generated.enumValue.fields.firstWhere(
        (f) => f.name == 'rawValue',
      );
      expect(rawValueField.modifier, FieldModifier.final$);
      expect(
        rawValueField.type?.accept(DartEmitter()).toString(),
        'String',
      );

      // Check constructor exists
      final mainConstructor = generated.enumValue.constructors.firstWhere(
        (c) => c.name == null,
      );
      expect(mainConstructor.constant, isTrue);
      expect(mainConstructor.requiredParameters, hasLength(1));
      expect(mainConstructor.requiredParameters[0].name, 'rawValue');
      expect(mainConstructor.requiredParameters[0].toThis, isTrue);
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
      final publicEnumName = nameManager.modelName(model);
      final generated = generator.generateEnum(model, publicEnumName);

      expect(result.filename, 'status.dart');

      // For nullable enums, check that a typedef was created
      expect(generated.typedefValue, isNotNull);

      // The typedef should use the public name
      expect(generated.typedefValue!.name, publicEnumName);

      // The actual enum has a $Raw prefix
      expect(generated.enumValue.name.startsWith(r'$Raw'), isTrue);

      // The typedef definition should point to the nullable rawEnum
      expect(
        generated.typedefValue!.definition.accept(DartEmitter()).toString(),
        '${generated.enumValue.name}?',
      );
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

      expect(generated.enumValue.name, r'$RawStatus');
      expect(generated.typedefValue, isNotNull);
      expect(generated.typedefValue!.name, 'Status');
      expect(
        generated.typedefValue!.definition.accept(DartEmitter()).toString(),
        r'$RawStatus?',
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

      expect(result.filename, 'color.dart');

      // Non-nullable enums use the name directly
      expect(generated.enumValue.name, 'Color');

      // No typedef for non-nullable enums
      expect(generated.typedefValue, isNull);

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

      expect(generated.enumValue.name, 'Status');
      expect(generated.typedefValue, isNull);
      expect(generated.enumValue.values, hasLength(3));
      expect(generated.enumValue.values[0].name, 'one');
      expect(generated.enumValue.values[1].name, 'two');
      expect(generated.enumValue.values[2].name, 'three');

      // Check enum values have correct arguments with actual values
      expect(generated.enumValue.values[0].arguments, hasLength(1));
      expect(
        generated.enumValue.values[0].arguments[0]
            .accept(DartEmitter())
            .toString(),
        '1',
      );
      expect(generated.enumValue.values[1].arguments, hasLength(1));
      expect(
        generated.enumValue.values[1].arguments[0]
            .accept(DartEmitter())
            .toString(),
        '2',
      );
      expect(generated.enumValue.values[2].arguments, hasLength(1));
      expect(
        generated.enumValue.values[2].arguments[0]
            .accept(DartEmitter())
            .toString(),
        '3',
      );

      // Check rawValue field
      final rawValueField = generated.enumValue.fields.firstWhere(
        (f) => f.name == 'rawValue',
      );
      expect(rawValueField.modifier, FieldModifier.final$);
      expect(
        rawValueField.type?.accept(DartEmitter()).toString(),
        'int',
      );

      // Check constructor exists and structure
      final mainConstructor = generated.enumValue.constructors.firstWhere(
        (c) => c.name == null,
      );
      expect(mainConstructor.constant, isTrue);
      expect(mainConstructor.requiredParameters, hasLength(1));
      expect(mainConstructor.requiredParameters[0].name, 'rawValue');
      expect(mainConstructor.requiredParameters[0].toThis, isTrue);
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

        // Check enum values have correct arguments with actual values
        expect(generated.enumValue.values[0].arguments, hasLength(1));
        expect(
          generated.enumValue.values[0].arguments[0]
              .accept(DartEmitter())
              .toString(),
          "r'_'",
        );
        expect(generated.enumValue.values[1].arguments, hasLength(1));
        expect(
          generated.enumValue.values[1].arguments[0]
              .accept(DartEmitter())
              .toString(),
          "r'__'",
        );
        expect(generated.enumValue.values[2].arguments, hasLength(1));
        expect(
          generated.enumValue.values[2].arguments[0]
              .accept(DartEmitter())
              .toString(),
          "r'___'",
        );

        // Check rawValue field
        final rawValueField = generated.enumValue.fields.firstWhere(
          (f) => f.name == 'rawValue',
        );
        expect(rawValueField.modifier, FieldModifier.final$);
        expect(
          rawValueField.type?.accept(DartEmitter()).toString(),
          'String',
        );

        // Check constructor exists
        final mainConstructor = generated.enumValue.constructors.firstWhere(
          (c) => c.name == null,
        );
        expect(mainConstructor.constant, isTrue);
        expect(mainConstructor.requiredParameters, hasLength(1));
        expect(mainConstructor.requiredParameters[0].name, 'rawValue');
        expect(mainConstructor.requiredParameters[0].toThis, isTrue);
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
        final generated = generator.generateEnum(model, 'Status');

        expect(result.filename, 'status.dart');

        // Non-nullable enums use the name directly
        expect(generated.enumValue.name, 'Status');

        // No typedef for non-nullable enums
        expect(generated.typedefValue, isNull);
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
            throw JsonDecodingException('Expected String for Color, got ${value.runtimeType}');
          }
          return values.firstWhere((e) => e.rawValue == value,
            orElse: () => throw JsonDecodingException('No matching Color for value: $value'), );
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
            throw JsonDecodingException('Expected int for Status, got ${value.runtimeType}');
          }
          return values.firstWhere((e) => e.rawValue == value,
            orElse: () => throw JsonDecodingException('No matching Status for value: $value'), );
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
            throw JsonDecodingException('Expected String for Status, got ${value.runtimeType}');
          }
          return values.firstWhere((e) => e.rawValue == value,
            orElse: () => throw JsonDecodingException('No matching Status for value: $value'), );
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
        const expectedBody = r'''
          return $RawStatus.fromJson(value.decodeSimpleString(context: context));
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
        const expectedBody = r'''
          return $RawStatus.fromJson(value.decodeSimpleInt(context: context));
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
        const expectedBody = r'''
          return $RawStatus.fromJson(value.decodeFormString(context: context));
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
        const expectedBody = r'''
          return $RawStatus.fromJson(value.decodeFormInt(context: context));
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
        expect(toForm.optionalParameters, hasLength(3));

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

        final useQueryComponentParam = toForm.optionalParameters.firstWhere(
          (p) => p.name == 'useQueryComponent',
        );
        expect(
          useQueryComponentParam.type?.accept(DartEmitter()).toString(),
          'bool',
        );
        expect(useQueryComponentParam.named, isTrue);
        expect(useQueryComponentParam.required, isFalse);
        expect(
          useQueryComponentParam.defaultTo?.accept(DartEmitter()).toString(),
          'false',
        );

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
        expect(toForm.optionalParameters, hasLength(3));

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
        expect(toForm.optionalParameters, hasLength(3));

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
        expect(toForm.optionalParameters, hasLength(3));

        final body = toForm.body?.accept(DartEmitter()).toString() ?? '';
        expect(
          body,
          'rawValue.toForm(explode: explode, allowEmpty: allowEmpty)',
        );
        expect(toForm.lambda, isTrue);
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
        expect(uriEncode.optionalParameters, hasLength(2));

        final allowEmptyParam = uriEncode.optionalParameters.firstWhere(
          (p) => p.name == 'allowEmpty',
        );
        expect(allowEmptyParam.type?.accept(DartEmitter()).toString(), 'bool');
        expect(allowEmptyParam.named, isTrue);
        expect(allowEmptyParam.required, isTrue);

        final useQueryComponentParam = uriEncode.optionalParameters.firstWhere(
          (p) => p.name == 'useQueryComponent',
        );
        expect(
          useQueryComponentParam.type?.accept(DartEmitter()).toString(),
          'bool',
        );
        expect(useQueryComponentParam.named, isTrue);
        expect(useQueryComponentParam.required, isFalse);
        expect(
          useQueryComponentParam.defaultTo?.accept(DartEmitter()).toString(),
          'false',
        );

        final body = uriEncode.body?.accept(DartEmitter()).toString() ?? '';
        expect(
          body,
          'rawValue.uriEncode(allowEmpty: allowEmpty, '
          'useQueryComponent: useQueryComponent)',
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
        expect(uriEncode.optionalParameters, hasLength(2));

        final useQueryComponentParam = uriEncode.optionalParameters.firstWhere(
          (p) => p.name == 'useQueryComponent',
        );
        expect(
          useQueryComponentParam.type?.accept(DartEmitter()).toString(),
          'bool',
        );
        expect(useQueryComponentParam.named, isTrue);
        expect(useQueryComponentParam.required, isFalse);
        expect(
          useQueryComponentParam.defaultTo?.accept(DartEmitter()).toString(),
          'false',
        );

        final body = uriEncode.body?.accept(DartEmitter()).toString() ?? '';
        expect(
          body,
          'rawValue.uriEncode(allowEmpty: allowEmpty, '
          'useQueryComponent: useQueryComponent)',
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
        expect(uriEncode.optionalParameters, hasLength(2));

        final useQueryComponentParam = uriEncode.optionalParameters.firstWhere(
          (p) => p.name == 'useQueryComponent',
        );
        expect(
          useQueryComponentParam.type?.accept(DartEmitter()).toString(),
          'bool',
        );
        expect(useQueryComponentParam.named, isTrue);
        expect(useQueryComponentParam.required, isFalse);
        expect(
          useQueryComponentParam.defaultTo?.accept(DartEmitter()).toString(),
          'false',
        );

        final body = uriEncode.body?.accept(DartEmitter()).toString() ?? '';
        expect(
          body,
          'rawValue.uriEncode(allowEmpty: allowEmpty, '
          'useQueryComponent: useQueryComponent)',
        );
        expect(uriEncode.lambda, isTrue);
      });
    });

    group('fallback/unknown case', () {
      test('includes fallback enum value when fallbackValue is set', () {
        final model = EnumModel<String>(
          isDeprecated: false,
          name: 'Status',
          values: {
            const EnumEntry(value: 'active'),
            const EnumEntry(value: 'inactive'),
          },
          isNullable: false,
          context: Context.initial().push('test'),
          fallbackValue: const EnumEntry(
            value: 'unknown',
            nameOverride: 'unknown',
          ),
        );

        final generated = generator.generateEnum(model, 'Status');

        expect(generated.enumValue.values, hasLength(3));
        expect(generated.enumValue.values[0].name, 'active');
        expect(generated.enumValue.values[1].name, 'inactive');
        expect(generated.enumValue.values[2].name, 'unknown');

        final unknownValue = generated.enumValue.values[2];
        expect(unknownValue.arguments, hasLength(1));
        expect(
          unknownValue.arguments.first.accept(DartEmitter()).toString(),
          "r'unknown'",
        );
      });

      test('fromJson returns fallback case for unknown string values', () {
        final model = EnumModel<String>(
          isDeprecated: false,
          name: 'Status',
          values: {
            const EnumEntry(value: 'active'),
            const EnumEntry(value: 'inactive'),
          },
          isNullable: false,
          context: Context.initial().push('test'),
          fallbackValue: const EnumEntry(
            value: 'unknown',
            nameOverride: 'unknown',
          ),
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
            throw JsonDecodingException('Expected String for Status, got ${value.runtimeType}');
          }
          return values.firstWhere((e) => e.rawValue == value,
            orElse: () => Status.unknown,
          );
        ''';
        expect(collapseWhitespace(body), collapseWhitespace(expectedBody));
      });

      test('fromJson returns fallback case for unknown int values', () {
        final model = EnumModel<int>(
          isDeprecated: false,
          name: 'Code',
          values: {
            const EnumEntry(value: 0),
            const EnumEntry(value: 1),
          },
          isNullable: false,
          context: Context.initial().push('test'),
          fallbackValue: const EnumEntry(
            value: -1,
            nameOverride: 'unknown',
          ),
        );

        final generated = generator.generateEnum(model, 'Code');
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
            throw JsonDecodingException('Expected int for Code, got ${value.runtimeType}');
          }
          return values.firstWhere((e) => e.rawValue == value,
            orElse: () => Code.unknown,
          );
        ''';
        expect(collapseWhitespace(body), collapseWhitespace(expectedBody));
      });

      test('toJson throws when encoding fallback case', () {
        final model = EnumModel<String>(
          isDeprecated: false,
          name: 'Status',
          values: {const EnumEntry(value: 'active')},
          isNullable: false,
          context: Context.initial().push('test'),
          fallbackValue: const EnumEntry(
            value: 'unknown',
            nameOverride: 'unknown',
          ),
        );

        final generated = generator.generateEnum(model, 'Status');
        final toJson = generated.enumValue.methods.firstWhere(
          (m) => m.name == 'toJson',
        );

        expect(toJson.returns?.accept(DartEmitter()).toString(), 'String');
        expect(toJson.lambda, isFalse);

        final body = toJson.body?.accept(DartEmitter()).toString() ?? '';
        const expectedBody = '''
          if (this == Status.unknown) {
            throw EncodingException(r'Cannot encode unknown enum value');
          }
          return rawValue;
        ''';
        expect(collapseWhitespace(body), collapseWhitespace(expectedBody));
      });

      test('toSimple throws when encoding fallback case', () {
        final model = EnumModel<String>(
          isDeprecated: false,
          name: 'Status',
          values: {const EnumEntry(value: 'active')},
          isNullable: false,
          context: Context.initial().push('test'),
          fallbackValue: const EnumEntry(
            value: 'unknown',
            nameOverride: 'unknown',
          ),
        );

        final generated = generator.generateEnum(model, 'Status');
        final toSimple = generated.enumValue.methods.firstWhere(
          (m) => m.name == 'toSimple',
        );

        expect(toSimple.returns?.accept(DartEmitter()).toString(), 'String');
        expect(toSimple.lambda, isFalse);
        expect(toSimple.optionalParameters, hasLength(2));

        final body = toSimple.body?.accept(DartEmitter()).toString() ?? '';
        const expectedBody = '''
          if (this == Status.unknown) {
            throw EncodingException(r'Cannot encode unknown enum value');
          }
          return rawValue.toSimple(explode: explode, allowEmpty: allowEmpty);
        ''';
        expect(collapseWhitespace(body), collapseWhitespace(expectedBody));
      });

      test('toForm throws when encoding fallback case', () {
        final model = EnumModel<String>(
          isDeprecated: false,
          name: 'Status',
          values: {const EnumEntry(value: 'active')},
          isNullable: false,
          context: Context.initial().push('test'),
          fallbackValue: const EnumEntry(
            value: 'unknown',
            nameOverride: 'unknown',
          ),
        );

        final generated = generator.generateEnum(model, 'Status');
        final toForm = generated.enumValue.methods.firstWhere(
          (m) => m.name == 'toForm',
        );

        expect(toForm.returns?.accept(DartEmitter()).toString(), 'String');
        expect(toForm.lambda, isFalse);
        expect(toForm.optionalParameters, hasLength(3));

        final body = toForm.body?.accept(DartEmitter()).toString() ?? '';
        const expectedBody = '''
          if (this == Status.unknown) {
            throw EncodingException(r'Cannot encode unknown enum value');
          }
          return rawValue.toForm(explode: explode, allowEmpty: allowEmpty);
        ''';
        expect(collapseWhitespace(body), collapseWhitespace(expectedBody));
      });

      test('uses custom fallback name from nameOverride', () {
        final model = EnumModel<String>(
          isDeprecated: false,
          name: 'Status',
          values: {const EnumEntry(value: 'active')},
          isNullable: false,
          context: Context.initial().push('test'),
          fallbackValue: const EnumEntry(
            value: 'fallback',
            nameOverride: 'fallback',
          ),
        );

        final generated = generator.generateEnum(model, 'Status');

        expect(generated.enumValue.values.last.name, 'fallback');

        final fallbackValue = generated.enumValue.values.last;
        expect(fallbackValue.arguments, hasLength(1));
        expect(
          fallbackValue.arguments.first.accept(DartEmitter()).toString(),
          "r'fallback'",
        );
      });

      test('does not include fallback when fallbackValue is null', () {
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

        expect(generated.enumValue.values, hasLength(2));
        expect(generated.enumValue.values[0].name, 'active');
        expect(generated.enumValue.values[1].name, 'inactive');
      });

      test('toLabel throws when encoding fallback case', () {
        final model = EnumModel<String>(
          isDeprecated: false,
          name: 'Status',
          values: {const EnumEntry(value: 'active')},
          isNullable: false,
          context: Context.initial().push('test'),
          fallbackValue: const EnumEntry(
            value: 'unknown',
            nameOverride: 'unknown',
          ),
        );

        final generated = generator.generateEnum(model, 'Status');
        final toLabel = generated.enumValue.methods.firstWhere(
          (m) => m.name == 'toLabel',
        );

        expect(toLabel.returns?.accept(DartEmitter()).toString(), 'String');
        expect(toLabel.lambda, isFalse);
        expect(toLabel.optionalParameters, hasLength(2));

        final body = toLabel.body?.accept(DartEmitter()).toString() ?? '';
        const expectedBody = '''
          if (this == Status.unknown) {
            throw EncodingException(r'Cannot encode unknown enum value');
          }
          return rawValue.toLabel(explode: explode, allowEmpty: allowEmpty);
        ''';
        expect(collapseWhitespace(body), collapseWhitespace(expectedBody));
      });

      test('uriEncode throws when encoding fallback case', () {
        final model = EnumModel<String>(
          isDeprecated: false,
          name: 'Status',
          values: {const EnumEntry(value: 'active')},
          isNullable: false,
          context: Context.initial().push('test'),
          fallbackValue: const EnumEntry(
            value: 'unknown',
            nameOverride: 'unknown',
          ),
        );

        final generated = generator.generateEnum(model, 'Status');
        final uriEncode = generated.enumValue.methods.firstWhere(
          (m) => m.name == 'uriEncode',
        );

        expect(uriEncode.returns?.accept(DartEmitter()).toString(), 'String');
        expect(uriEncode.lambda, isFalse);
        expect(uriEncode.optionalParameters, hasLength(2));

        final allowEmptyParam = uriEncode.optionalParameters.firstWhere(
          (p) => p.name == 'allowEmpty',
        );
        expect(allowEmptyParam.type?.accept(DartEmitter()).toString(), 'bool');
        expect(allowEmptyParam.named, isTrue);
        expect(allowEmptyParam.required, isTrue);

        final useQueryComponentParam = uriEncode.optionalParameters.firstWhere(
          (p) => p.name == 'useQueryComponent',
        );
        expect(
          useQueryComponentParam.type?.accept(DartEmitter()).toString(),
          'bool',
        );
        expect(useQueryComponentParam.named, isTrue);
        expect(useQueryComponentParam.required, isFalse);
        expect(
          useQueryComponentParam.defaultTo?.accept(DartEmitter()).toString(),
          'false',
        );

        final body = uriEncode.body?.accept(DartEmitter()).toString() ?? '';
        const expectedBody = '''
          if (this == Status.unknown) {
            throw EncodingException(r'Cannot encode unknown enum value');
          }
          return rawValue.uriEncode(allowEmpty: allowEmpty, useQueryComponent: useQueryComponent);
        ''';
        expect(collapseWhitespace(body), collapseWhitespace(expectedBody));
      });

      test('toMatrix throws when encoding fallback case', () {
        final model = EnumModel<String>(
          isDeprecated: false,
          name: 'Status',
          values: {const EnumEntry(value: 'active')},
          isNullable: false,
          context: Context.initial().push('test'),
          fallbackValue: const EnumEntry(
            value: 'unknown',
            nameOverride: 'unknown',
          ),
        );

        final generated = generator.generateEnum(model, 'Status');
        final toMatrix = generated.enumValue.methods.firstWhere(
          (m) => m.name == 'toMatrix',
        );

        expect(toMatrix.returns?.accept(DartEmitter()).toString(), 'String');
        expect(toMatrix.lambda, isFalse);
        expect(toMatrix.requiredParameters, hasLength(1));
        expect(toMatrix.optionalParameters, hasLength(2));

        final body = toMatrix.body?.accept(DartEmitter()).toString() ?? '';
        const expectedBody = '''
          if (this == Status.unknown) {
            throw EncodingException(r'Cannot encode unknown enum value');
          }
          return rawValue.toMatrix(paramName, explode: explode, allowEmpty: allowEmpty);
        ''';
        expect(collapseWhitespace(body), collapseWhitespace(expectedBody));
      });

      test('fromJson throws when no fallback and value does not match', () {
        final model = EnumModel<String>(
          isDeprecated: false,
          name: 'Status',
          values: {
            const EnumEntry(value: 'active'),
          },
          isNullable: false,
          context: Context.initial().push('test'),
        );

        final generated = generator.generateEnum(model, 'Status');
        final fromJson = generated.enumValue.constructors.firstWhere(
          (c) => c.name == 'fromJson',
        );

        final body = fromJson.body?.accept(DartEmitter()).toString() ?? '';
        const expectedBody = r'''
          if (value is! String) {
            throw JsonDecodingException('Expected String for Status, got ${value.runtimeType}');
          }
          return values.firstWhere((e) => e.rawValue == value,
            orElse: () => throw JsonDecodingException('No matching Status for value: $value'),
          );
        ''';
        expect(collapseWhitespace(body), collapseWhitespace(expectedBody));
      });

      test('handles fallback with nullable enum', () {
        final model = EnumModel<String>(
          isDeprecated: false,
          name: 'Status',
          values: {const EnumEntry(value: 'active')},
          isNullable: true,
          context: Context.initial().push('test'),
          fallbackValue: const EnumEntry(
            value: 'unknown',
            nameOverride: 'unknown',
          ),
        );

        final generated = generator.generateEnum(model, 'Status');

        expect(generated.enumValue.name, r'$RawStatus');
        expect(generated.typedefValue, isNotNull);
        expect(generated.enumValue.values, hasLength(2));
        expect(generated.enumValue.values.last.name, 'unknown');
      });

      test(
        'includes both regular values and fallback when no collision',
        () {
          final model = EnumModel<String>(
            isDeprecated: false,
            name: 'Status',
            values: {
              const EnumEntry(value: 'active'),
              const EnumEntry(value: 'inactive'),
            },
            isNullable: false,
            context: Context.initial().push('test'),
            fallbackValue: const EnumEntry(
              value: 'fallback',
              nameOverride: 'fallback',
            ),
          );

          final generated = generator.generateEnum(model, 'Status');

          expect(generated.enumValue.values, hasLength(3));
          expect(generated.enumValue.values[0].name, 'active');
          expect(generated.enumValue.values[1].name, 'inactive');
          expect(generated.enumValue.values[2].name, 'fallback');

          expect(
            generated.enumValue.values[1].arguments.first
                .accept(DartEmitter())
                .toString(),
            "r'inactive'",
          );
          expect(
            generated.enumValue.values[2].arguments.first
                .accept(DartEmitter())
                .toString(),
            "r'fallback'",
          );
        },
      );

      test(
        'handles collision when regular value name matches fallback name',
        () {
          final model = EnumModel<String>(
            isDeprecated: false,
            name: 'Status',
            values: {
              const EnumEntry(value: 'active'),
              const EnumEntry(value: 'unknown'),
            },
            isNullable: false,
            context: Context.initial().push('test'),
            fallbackValue: const EnumEntry(
              value: 'unknown',
              nameOverride: 'unknown',
            ),
          );

          final generated = generator.generateEnum(model, 'Status');

          expect(generated.enumValue.values, hasLength(3));
          expect(generated.enumValue.values[0].name, 'active');
          expect(generated.enumValue.values[1].name, 'unknown');
          expect(generated.enumValue.values[2].name, 'unknown2');

          expect(
            generated.enumValue.values[1].arguments.first
                .accept(DartEmitter())
                .toString(),
            "r'unknown'",
          );
          expect(
            generated.enumValue.values[2].arguments.first
                .accept(DartEmitter())
                .toString(),
            "r'unknown'",
          );
        },
      );

      test(
        'fromJson returns correct value when regular value matches '
        'fallback rawValue',
        () {
          final model = EnumModel<String>(
            isDeprecated: false,
            name: 'Status',
            values: {
              const EnumEntry(value: 'active'),
              const EnumEntry(value: 'unknown'),
            },
            isNullable: false,
            context: Context.initial().push('test'),
            fallbackValue: const EnumEntry(
              value: 'fallback',
              nameOverride: 'fallback',
            ),
          );

          final generated = generator.generateEnum(model, 'Status');
          final fromJson = generated.enumValue.constructors.firstWhere(
            (c) => c.name == 'fromJson',
          );

          final body = fromJson.body?.accept(DartEmitter()).toString() ?? '';
          const expectedBody = r'''
            if (value is! String) {
              throw JsonDecodingException('Expected String for Status, got ${value.runtimeType}');
            }
            return values.firstWhere((e) => e.rawValue == value,
              orElse: () => Status.fallback,
            );
          ''';
          expect(collapseWhitespace(body), collapseWhitespace(expectedBody));
        },
      );

      test(
        'fromJson prefers regular enum value over fallback when values match',
        () {
          final model = EnumModel<String>(
            isDeprecated: false,
            name: 'Status',
            values: {
              const EnumEntry(value: 'active'),
              const EnumEntry(value: 'unknown'),
            },
            isNullable: false,
            context: Context.initial().push('test'),
            fallbackValue: const EnumEntry(
              value: 'unknown',
              nameOverride: 'fallbackUnknown',
            ),
          );

          final generated = generator.generateEnum(model, 'Status');

          expect(generated.enumValue.values, hasLength(3));
          expect(generated.enumValue.values[0].name, 'active');
          expect(generated.enumValue.values[1].name, 'unknown');
          expect(generated.enumValue.values[2].name, 'fallbackUnknown');

          expect(
            generated.enumValue.values[1].arguments.first
                .accept(DartEmitter())
                .toString(),
            "r'unknown'",
          );
          expect(
            generated.enumValue.values[2].arguments.first
                .accept(DartEmitter())
                .toString(),
            "r'unknown'",
          );

          final fromJson = generated.enumValue.constructors.firstWhere(
            (c) => c.name == 'fromJson',
          );

          final body = fromJson.body?.accept(DartEmitter()).toString() ?? '';
          const expectedBody = r'''
            if (value is! String) {
              throw JsonDecodingException('Expected String for Status, got ${value.runtimeType}');
            }
            return values.firstWhere((e) => e.rawValue == value,
              orElse: () => Status.fallbackUnknown,
            );
          ''';
          expect(collapseWhitespace(body), collapseWhitespace(expectedBody));
        },
      );

      test(
        'encoding methods throw for fallback even when name collides',
        () {
          final model = EnumModel<String>(
            isDeprecated: false,
            name: 'Status',
            values: {
              const EnumEntry(value: 'active'),
              const EnumEntry(value: 'unknown'),
            },
            isNullable: false,
            context: Context.initial().push('test'),
            fallbackValue: const EnumEntry(
              value: 'unknown',
              nameOverride: 'unknown',
            ),
          );

          final generated = generator.generateEnum(model, 'Status');
          final toJson = generated.enumValue.methods.firstWhere(
            (m) => m.name == 'toJson',
          );

          final body = toJson.body?.accept(DartEmitter()).toString() ?? '';
          const expectedBody = '''
            if (this == Status.unknown2) {
              throw EncodingException(r'Cannot encode unknown enum value');
            }
            return rawValue;
          ''';
          expect(collapseWhitespace(body), collapseWhitespace(expectedBody));
        },
      );

      test('handles fallback name with reserved keyword (enum)', () {
        final model = EnumModel<String>(
          isDeprecated: false,
          name: 'Type',
          values: {
            const EnumEntry(value: 'class'),
            const EnumEntry(value: 'struct'),
          },
          isNullable: false,
          context: Context.initial().push('test'),
          fallbackValue: const EnumEntry(
            value: 'enum',
            nameOverride: 'enum',
          ),
        );

        final generated = generator.generateEnum(model, 'Type');

        expect(generated.enumValue.values, hasLength(3));
        expect(generated.enumValue.values[2].name, r'$enum');

        expect(
          generated.enumValue.values[2].arguments.first
              .accept(DartEmitter())
              .toString(),
          "r'enum'",
        );
      });

      test(r'handles fallback name with special characters ($unknown)', () {
        final model = EnumModel<String>(
          isDeprecated: false,
          name: 'Status',
          values: {
            const EnumEntry(value: 'active'),
          },
          isNullable: false,
          context: Context.initial().push('test'),
          fallbackValue: const EnumEntry(
            value: r'$unknown',
            nameOverride: r'$unknown',
          ),
        );

        final generated = generator.generateEnum(model, 'Status');

        expect(generated.enumValue.values, hasLength(2));
        expect(generated.enumValue.values[1].name, r'$unknown');

        expect(
          generated.enumValue.values[1].arguments.first
              .accept(DartEmitter())
              .toString(),
          r"r'$unknown'",
        );
      });

      test('handles fallback name with leading digits (123unknown)', () {
        final model = EnumModel<String>(
          isDeprecated: false,
          name: 'Status',
          values: {
            const EnumEntry(value: 'active'),
          },
          isNullable: false,
          context: Context.initial().push('test'),
          fallbackValue: const EnumEntry(
            value: '123unknown',
            nameOverride: '123unknown',
          ),
        );

        final generated = generator.generateEnum(model, 'Status');

        expect(generated.enumValue.values, hasLength(2));
        expect(generated.enumValue.values[1].name, 'unknown123');

        expect(
          generated.enumValue.values[1].arguments.first
              .accept(DartEmitter())
              .toString(),
          "r'123unknown'",
        );
      });

      test('handles fallback name with hyphens (un-known)', () {
        final model = EnumModel<String>(
          isDeprecated: false,
          name: 'Status',
          values: {
            const EnumEntry(value: 'active'),
          },
          isNullable: false,
          context: Context.initial().push('test'),
          fallbackValue: const EnumEntry(
            value: 'un-known',
            nameOverride: 'un-known',
          ),
        );

        final generated = generator.generateEnum(model, 'Status');

        expect(generated.enumValue.values, hasLength(2));
        expect(generated.enumValue.values[1].name, 'unKnown');

        expect(
          generated.enumValue.values[1].arguments.first
              .accept(DartEmitter())
              .toString(),
          "r'un-known'",
        );
      });

      test('handles fallback name with spaces (un known)', () {
        final model = EnumModel<String>(
          isDeprecated: false,
          name: 'Status',
          values: {
            const EnumEntry(value: 'active'),
          },
          isNullable: false,
          context: Context.initial().push('test'),
          fallbackValue: const EnumEntry(
            value: 'un known',
            nameOverride: 'un known',
          ),
        );

        final generated = generator.generateEnum(model, 'Status');

        expect(generated.enumValue.values, hasLength(2));
        expect(generated.enumValue.values[1].name, 'unKnown');

        expect(
          generated.enumValue.values[1].arguments.first
              .accept(DartEmitter())
              .toString(),
          "r'un known'",
        );
      });

      test('handles fallback name with dots (un.known)', () {
        final model = EnumModel<String>(
          isDeprecated: false,
          name: 'Status',
          values: {
            const EnumEntry(value: 'active'),
          },
          isNullable: false,
          context: Context.initial().push('test'),
          fallbackValue: const EnumEntry(
            value: 'un.known',
            nameOverride: 'un.known',
          ),
        );

        final generated = generator.generateEnum(model, 'Status');

        expect(generated.enumValue.values, hasLength(2));
        expect(generated.enumValue.values[1].name, 'unknown');

        expect(
          generated.enumValue.values[1].arguments.first
              .accept(DartEmitter())
              .toString(),
          "r'un.known'",
        );
      });

      test('handles empty string as fallback value', () {
        final model = EnumModel<String>(
          isDeprecated: false,
          name: 'Status',
          values: {
            const EnumEntry(value: 'active'),
          },
          isNullable: false,
          context: Context.initial().push('test'),
          fallbackValue: const EnumEntry(
            value: '',
            nameOverride: 'empty',
          ),
        );

        final generated = generator.generateEnum(model, 'Status');

        expect(generated.enumValue.values, hasLength(2));
        expect(generated.enumValue.values[1].name, 'empty');

        expect(
          generated.enumValue.values[1].arguments.first
              .accept(DartEmitter())
              .toString(),
          "r''",
        );
      });

      test(
        'encoding methods use normalized fallback name in comparison',
        () {
          final model = EnumModel<String>(
            isDeprecated: false,
            name: 'Status',
            values: {
              const EnumEntry(value: 'active'),
            },
            isNullable: false,
            context: Context.initial().push('test'),
            fallbackValue: const EnumEntry(
              value: 'un-known',
              nameOverride: 'un-known',
            ),
          );

          final generated = generator.generateEnum(model, 'Status');
          final toJson = generated.enumValue.methods.firstWhere(
            (m) => m.name == 'toJson',
          );

          final body = toJson.body?.accept(DartEmitter()).toString() ?? '';
          const expectedBody = '''
            if (this == Status.unKnown) {
              throw EncodingException(r'Cannot encode unknown enum value');
            }
            return rawValue;
          ''';
          expect(collapseWhitespace(body), collapseWhitespace(expectedBody));
        },
      );
    });

    test(
      'generates enum implementing encoding interfaces '
      'except DeepObjectEncodable',
      () {
        final model = EnumModel<String>(
          isDeprecated: false,
          name: 'Color',
          values: {
            const EnumEntry(value: 'red'),
            const EnumEntry(value: 'green'),
          },
          isNullable: false,
          context: Context.initial().push('test'),
        );

        final generated = generator.generateEnum(model, 'Color');

        final implementedInterfaces = generated.enumValue.implements
            .map((i) => i.accept(DartEmitter()).toString())
            .toList();

        expect(implementedInterfaces, hasLength(5));
        expect(implementedInterfaces, contains('MatrixEncodable'));
        expect(implementedInterfaces, contains('LabelEncodable'));
        expect(implementedInterfaces, contains('SimpleEncodable'));
        expect(implementedInterfaces, contains('FormEncodable'));
        expect(implementedInterfaces, contains('JsonEncodable'));
        expect(implementedInterfaces, isNot(contains('DeepObjectEncodable')));
        expect(implementedInterfaces, isNot(contains('ParameterEncodable')));
      },
    );

    test('encoding methods have @override annotation', () {
      final model = EnumModel<String>(
        isDeprecated: false,
        name: 'Color',
        values: {
          const EnumEntry(value: 'red'),
          const EnumEntry(value: 'green'),
        },
        isNullable: false,
        context: Context.initial().push('test'),
      );

      final generated = generator.generateEnum(model, 'Color');

      final encodingMethods = [
        'toJson',
        'toSimple',
        'toForm',
        'toLabel',
        'toMatrix',
      ];
      for (final methodName in encodingMethods) {
        final method = generated.enumValue.methods.firstWhere(
          (m) => m.name == methodName,
          orElse: () => throw StateError('Method $methodName not found'),
        );
        expect(
          method.annotations,
          hasLength(1),
          reason: '$methodName should have @override annotation',
        );
        expect(
          method.annotations.first.accept(DartEmitter()).toString(),
          'override',
          reason: '$methodName should have @override annotation',
        );
      }
    });
  });
}
