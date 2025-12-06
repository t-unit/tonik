import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/model/all_of_generator.dart';
import 'package:tonik_generate/src/model/any_of_generator.dart';
import 'package:tonik_generate/src/model/class_generator.dart';
import 'package:tonik_generate/src/model/enum_generator.dart';
import 'package:tonik_generate/src/model/one_of_generator.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';

void main() {
  late NameGenerator nameGenerator;
  late NameManager nameManager;
  late Context context;
  late DartEmitter emitter;

  setUp(() {
    nameGenerator = NameGenerator();
    nameManager = NameManager(generator: nameGenerator);
    context = Context.initial();
    emitter = DartEmitter(useNullSafetySyntax: true);
  });

  group('ClassGenerator deprecation', () {
    late ClassGenerator generator;

    setUp(() {
      generator = ClassGenerator(
        nameManager: nameManager,
        package: 'package:example',
      );
    });

    test('adds @Deprecated annotation when model is deprecated', () {
      final model = ClassModel(
        isDeprecated: true,
        description: null,
        name: 'LegacyUser',
        properties: const [],
        context: context,
      );

      final result = generator.generateClass(model);

      final deprecatedAnnotation = result.annotations.firstWhere(
        (a) => a.accept(emitter).toString().contains('Deprecated'),
        orElse: () => throw StateError('No @Deprecated annotation found'),
      );

      expect(
        deprecatedAnnotation.accept(emitter).toString(),
        contains('Deprecated'),
      );
    });

    test(
      'does not add @Deprecated annotation when model is not deprecated',
      () {
        final model = ClassModel(
          isDeprecated: false,
          description: null,
          name: 'User',
          properties: const [],
          context: context,
        );

        final result = generator.generateClass(model);

        final hasDeprecatedAnnotation = result.annotations.any(
          (a) => a.accept(emitter).toString().contains('Deprecated'),
        );

        expect(hasDeprecatedAnnotation, isFalse);
      },
    );
  });

  group('EnumGenerator deprecation', () {
    late EnumGenerator generator;

    setUp(() {
      generator = EnumGenerator(nameManager: nameManager);
    });

    test('adds @Deprecated annotation when enum model is deprecated', () {
      final model = EnumModel<String>(
        isDeprecated: true,
        description: null,
        name: 'LegacyStatus',
        values: const {'active', 'inactive'},
        isNullable: false,
        context: context,
      );

      final result = generator.generateEnum(model, 'LegacyStatus');

      final deprecatedAnnotation = result.enumValue.annotations.firstWhere(
        (a) => a.accept(emitter).toString().contains('Deprecated'),
        orElse: () => throw StateError('No @Deprecated annotation found'),
      );

      expect(
        deprecatedAnnotation.accept(emitter).toString(),
        contains('Deprecated'),
      );
    });

    test(
      'does not add @Deprecated annotation when enum model is not deprecated',
      () {
        final model = EnumModel<String>(
          isDeprecated: false,
          description: null,
          name: 'Status',
          values: const {'active', 'inactive'},
          isNullable: false,
          context: context,
        );

        final result = generator.generateEnum(model, 'Status');

        final hasDeprecatedAnnotation = result.enumValue.annotations.any(
          (a) => a.accept(emitter).toString().contains('Deprecated'),
        );

        expect(hasDeprecatedAnnotation, isFalse);
      },
    );
  });

  group('OneOfGenerator deprecation', () {
    late OneOfGenerator generator;

    setUp(() {
      generator = OneOfGenerator(
        nameManager: nameManager,
        package: 'package:example',
      );
    });

    test('adds @Deprecated annotation when oneOf model is deprecated', () {
      final model = OneOfModel(
        isDeprecated: true,
        name: 'LegacyResult',
        models: {
          (discriminatorValue: null, model: StringModel(context: context)),
          (discriminatorValue: null, model: IntegerModel(context: context)),
        },
        discriminator: null,
        context: context,
        description: null,
      );

      final result = generator.generateClasses(model);
      final baseClass = result.firstWhere((c) => c.name == 'LegacyResult');

      final deprecatedAnnotation = baseClass.annotations.firstWhere(
        (a) => a.accept(emitter).toString().contains('Deprecated'),
        orElse: () => throw StateError('No @Deprecated annotation found'),
      );

      expect(
        deprecatedAnnotation.accept(emitter).toString(),
        contains('Deprecated'),
      );
    });

    test(
      'does not add @Deprecated annotation when oneOf model is not deprecated',
      () {
        final model = OneOfModel(
          isDeprecated: false,
          name: 'Result',
          models: {
            (discriminatorValue: null, model: StringModel(context: context)),
            (discriminatorValue: null, model: IntegerModel(context: context)),
          },
          discriminator: null,
          context: context,
          description: null,
        );

        final result = generator.generateClasses(model);
        final baseClass = result.firstWhere((c) => c.name == 'Result');

        final hasDeprecatedAnnotation = baseClass.annotations.any(
          (a) => a.accept(emitter).toString().contains('Deprecated'),
        );

        expect(hasDeprecatedAnnotation, isFalse);
      },
    );
  });

  group('AnyOfGenerator deprecation', () {
    late AnyOfGenerator generator;

    setUp(() {
      generator = AnyOfGenerator(
        nameManager: nameManager,
        package: 'package:example',
      );
    });

    test('adds @Deprecated annotation when anyOf model is deprecated', () {
      final model = AnyOfModel(
        isDeprecated: true,
        name: 'LegacyMixed',
        models: {
          (discriminatorValue: null, model: StringModel(context: context)),
          (discriminatorValue: null, model: IntegerModel(context: context)),
        },
        discriminator: null,
        context: context,
        description: null,
      );

      final result = generator.generateClass(model);

      final deprecatedAnnotation = result.annotations.firstWhere(
        (a) => a.accept(emitter).toString().contains('Deprecated'),
        orElse: () => throw StateError('No @Deprecated annotation found'),
      );

      expect(
        deprecatedAnnotation.accept(emitter).toString(),
        contains('Deprecated'),
      );
    });

    test(
      'does not add @Deprecated annotation when anyOf model is not deprecated',
      () {
        final model = AnyOfModel(
          isDeprecated: false,
          name: 'Mixed',
          models: {
            (discriminatorValue: null, model: StringModel(context: context)),
            (discriminatorValue: null, model: IntegerModel(context: context)),
          },
          discriminator: null,
          context: context,
          description: null,
        );

        final result = generator.generateClass(model);

        final hasDeprecatedAnnotation = result.annotations.any(
          (a) => a.accept(emitter).toString().contains('Deprecated'),
        );

        expect(hasDeprecatedAnnotation, isFalse);
      },
    );
  });

  group('AllOfGenerator deprecation', () {
    late AllOfGenerator generator;

    setUp(() {
      generator = AllOfGenerator(
        nameManager: nameManager,
        package: 'package:example',
      );
    });

    test('adds @Deprecated annotation when allOf model is deprecated', () {
      final model = AllOfModel(
        isDeprecated: true,
        name: 'LegacyCombined',
        models: {StringModel(context: context)},
        context: context,
        description: null,
      );

      final result = generator.generateClass(model);

      final deprecatedAnnotation = result.annotations.firstWhere(
        (a) => a.accept(emitter).toString().contains('Deprecated'),
        orElse: () => throw StateError('No @Deprecated annotation found'),
      );

      expect(
        deprecatedAnnotation.accept(emitter).toString(),
        contains('Deprecated'),
      );
    });

    test(
      'does not add @Deprecated annotation when allOf model is not deprecated',
      () {
        final model = AllOfModel(
          isDeprecated: false,
          name: 'Combined',
          models: {StringModel(context: context)},
          context: context,
          description: null,
        );

        final result = generator.generateClass(model);

        final hasDeprecatedAnnotation = result.annotations.any(
          (a) => a.accept(emitter).toString().contains('Deprecated'),
        );

        expect(hasDeprecatedAnnotation, isFalse);
      },
    );
  });

  group('ClassGenerator property deprecation', () {
    late ClassGenerator generator;

    setUp(() {
      generator = ClassGenerator(
        nameManager: nameManager,
        package: 'package:example',
      );
    });

    test(
      'adds @Deprecated annotation to field when property is deprecated',
      () {
        final model = ClassModel(
          isDeprecated: false,
          description: null,
          name: 'User',
          properties: [
            Property(
              name: 'oldField',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: true,
              description: 'This field is deprecated',
            ),
            Property(
              name: 'newField',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              description: 'This field is current',
            ),
          ],
          context: context,
        );

        final result = generator.generateClass(model);

        // Find the deprecated field
        final deprecatedField = result.fields.firstWhere(
          (f) => f.name == 'oldField',
        );
        final hasDeprecatedAnnotation = deprecatedField.annotations.any(
          (a) => a.accept(emitter).toString().contains('Deprecated'),
        );

        expect(hasDeprecatedAnnotation, isTrue);
      },
    );

    test(
      'does not add @Deprecated annotation to field when property '
      'is not deprecated',
      () {
        final model = ClassModel(
          isDeprecated: false,
          description: null,
          name: 'User',
          properties: [
            Property(
              name: 'currentField',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              description: 'This field is current',
            ),
          ],
          context: context,
        );

        final result = generator.generateClass(model);

        final field = result.fields.firstWhere((f) => f.name == 'currentField');
        final hasDeprecatedAnnotation = field.annotations.any(
          (a) => a.accept(emitter).toString().contains('Deprecated'),
        );

        expect(hasDeprecatedAnnotation, isFalse);
      },
    );
  });
}
