import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';
import 'package:tonic_core/tonic_core.dart';
import 'package:tonic_generate/src/model/class_generator.dart';
import 'package:tonic_generate/src/util/name_generator.dart';
import 'package:tonic_generate/src/util/name_manager.dart';

void main() {
  group('ClassGenerator', () {
    late ClassGenerator generator;
    late NameManager nameManager;
    late NameGenerator nameGenerator;
    late Context context;
    late DartEmitter emitter;

    setUp(() {
      nameGenerator = NameGenerator();
      nameManager = NameManager(generator: nameGenerator);
      generator = ClassGenerator(
        nameManager: nameManager,
        package: 'package:example',
      );
      context = Context.initial();
      emitter = DartEmitter(useNullSafetySyntax: true);
    });

    test('generates class with correct name', () {
      final model = ClassModel(
        name: 'User',
        properties: const {},
        context: context,
      );

      final result = generator.generateClass(model);
      expect(result.name, 'User');
    });

    test('generates class with immutable annotation', () {
      final model = ClassModel(
        name: 'User',
        properties: const {},
        context: context,
      );

      final result = generator.generateClass(model);

      expect(result.annotations.length, 1);

      final annotation = result.annotations.first;
      expect(annotation.accept(emitter).toString(), 'immutable');
    });

    test('generates constructor with required and optional parameters', () {
      final model = ClassModel(
        name: 'User',
        properties: {
          Property(
            name: 'id',
            model: IntegerModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
          Property(
            name: 'name',
            model: StringModel(context: context),
            isRequired: false,
            isNullable: true,
            isDeprecated: false,
          ),
        },
        context: context,
      );

      final result = generator.generateClass(model);
      final constructor = result.constructors.first;

      expect(constructor.constant, isTrue);
      expect(constructor.optionalParameters, hasLength(2));

      final idParam = constructor.optionalParameters[0];
      expect(idParam.name, 'id');
      expect(idParam.named, isTrue);
      expect(idParam.required, isTrue);
      expect(idParam.toThis, isTrue);

      final nameParam = constructor.optionalParameters[1];
      expect(nameParam.name, 'name');
      expect(nameParam.named, isTrue);
      expect(nameParam.required, isFalse);
      expect(nameParam.toThis, isTrue);
    });

    test(
      'generates constructor with required fields before non-required fields',
      () {
        final model = ClassModel(
          name: 'User',
          properties: {
            Property(
              name: 'nickname',
              model: StringModel(context: context),
              isRequired: false,
              isNullable: true,
              isDeprecated: false,
            ),
            Property(
              name: 'id',
              model: IntegerModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
            Property(
              name: 'name',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
            Property(
              name: 'bio',
              model: StringModel(context: context),
              isRequired: false,
              isNullable: true,
              isDeprecated: false,
            ),
          },
          context: context,
        );

        final result = generator.generateClass(model);
        final constructor = result.constructors.first;

        // Get the required and optional parameters
        final requiredParams =
            constructor.optionalParameters
                .where((p) => p.required)
                .map((p) => p.name)
                .toList();
        final optionalParams =
            constructor.optionalParameters
                .where((p) => !p.required)
                .map((p) => p.name)
                .toList();

        // Verify all required parameters come before optional ones
        final allParams =
            constructor.optionalParameters.map((p) => p.name).toList();
        final requiredIndices = requiredParams.map(allParams.indexOf);
        final optionalIndices = optionalParams.map(allParams.indexOf);

        // Check that every required parameter index is less
        // than every optional parameter index
        for (final reqIndex in requiredIndices) {
          for (final optIndex in optionalIndices) {
            expect(reqIndex < optIndex, isTrue);
          }
        }

        // Verify the exact order: required params should be id and name,
        // optional params should be nickname and bio
        expect(requiredParams, ['id', 'name']);
        expect(optionalParams, ['nickname', 'bio']);
      },
    );

    test('generates filename in snake_case', () {
      final model = ClassModel(
        name: 'UserProfile',
        properties: const {},
        context: Context.initial(),
      );

      final result = generator.generate(model);
      expect(result.filename, 'user_profile.dart');
    });

    group('property generation', () {
      test('generates required non-nullable int property', () {
        final model = ClassModel(
          name: 'User',
          properties: {
            Property(
              name: 'id',
              model: IntegerModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          },
          context: context,
        );

        final result = generator.generateClass(model);
        final field = result.fields.first;

        expect(field.name, 'id');
        expect(field.type?.accept(emitter).toString(), 'int');
        expect(field.annotations, isEmpty);
      });

      test('generates optional nullable string property', () {
        final model = ClassModel(
          name: 'User',
          properties: {
            Property(
              name: 'name',
              model: StringModel(context: context),
              isRequired: false,
              isNullable: true,
              isDeprecated: false,
            ),
          },
          context: context,
        );

        final result = generator.generateClass(model);
        final field = result.fields.first;

        expect(field.name, 'name');
        expect(field.type?.accept(emitter).toString(), 'String?');
        expect(field.annotations, isEmpty);
      });

      test('generates decimal property', () {
        final model = ClassModel(
          name: 'User',
          properties: {
            Property(
              name: 'balance',
              model: DecimalModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          },
          context: context,
        );

        final result = generator.generateClass(model);
        final field = result.fields.first;

        expect(field.name, 'balance');
        expect(field.type?.accept(emitter).toString(), 'BigDecimal');
        expect(field.annotations, isEmpty);
      });

      test('generates list of strings property', () {
        final model = ClassModel(
          name: 'User',
          properties: {
            Property(
              name: 'tags',
              model: ListModel(
                content: StringModel(context: context),
                context: context,
              ),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          },
          context: context,
        );

        final result = generator.generateClass(model);
        final field = result.fields.first;

        expect(field.name, 'tags');
        expect(field.type?.accept(emitter).toString(), 'List<String>');
        expect(field.annotations, isEmpty);
      });

      test('generates nested class property', () {
        final model = ClassModel(
          name: 'User',
          properties: {
            Property(
              name: 'address',
              model: ClassModel(
                name: 'Address',
                properties: const {},
                context: context,
              ),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          },
          context: context,
        );

        final result = generator.generateClass(model);
        final field = result.fields.first;

        expect(field.name, 'address');
        expect(field.type?.accept(emitter).toString(), 'Address');
        expect(field.annotations, isEmpty);
      });

      test('generates deprecated property', () {
        final model = ClassModel(
          name: 'User',
          properties: {
            Property(
              name: 'username',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: true,
            ),
          },
          context: context,
        );

        final result = generator.generateClass(model);
        final field = result.fields.first;

        expect(field.name, 'username');
        expect(field.type?.accept(emitter).toString(), 'String');
        expect(field.annotations, hasLength(1));
        expect(
          field.annotations.first.code.accept(emitter).toString(),
          "Deprecated('This property is deprecated.')",
        );
      });

      test('generates optional non-nullable property', () {
        final model = ClassModel(
          name: 'User',
          properties: {
            Property(
              name: 'photoUrl',
              model: StringModel(context: context),
              isRequired: false,
              isNullable: false,
              isDeprecated: false,
            ),
          },
          context: context,
        );

        final result = generator.generateClass(model);
        final field = result.fields.first;

        expect(field.name, 'photoUrl');
        expect(field.type?.accept(emitter).toString(), 'String?');
        expect(field.annotations, isEmpty);
      });

      test('generates required nullable property', () {
        final model = ClassModel(
          name: 'User',
          properties: {
            Property(
              name: 'photoUrl',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: true,
              isDeprecated: false,
            ),
          },
          context: context,
        );

        final result = generator.generateClass(model);
        final field = result.fields.first;

        expect(field.name, 'photoUrl');
        expect(field.type?.accept(emitter).toString(), 'String?');
        expect(field.annotations, isEmpty);
      });
    });
  });
}
