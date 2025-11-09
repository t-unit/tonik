import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/model/all_of_generator.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';

void main() {
  late AllOfGenerator generator;
  late NameManager nameManager;
  late NameGenerator nameGenerator;
  late Context context;
  late DartEmitter emitter;

  final format =
      DartFormatter(
        languageVersion: DartFormatter.latestLanguageVersion,
      ).format;

  setUp(() {
    nameGenerator = NameGenerator();
    nameManager = NameManager(generator: nameGenerator);
    generator = AllOfGenerator(
      nameManager: nameManager,
      package: 'package:example',
    );
    context = Context.initial();
    emitter = DartEmitter(useNullSafetySyntax: true);
  });

  group('parameterProperties', () {
    test('method exists with correct signature for allOf', () {
      final model = AllOfModel(
        name: 'Combined',
        models: {
          StringModel(context: context),
        },
        context: context,
      );

      final combinedClass = generator.generateClass(model);
      final method = combinedClass.methods.firstWhere(
        (m) => m.name == 'parameterProperties',
        orElse: () => throw StateError('parameterProperties method not found'),
      );

      expect(method.name, 'parameterProperties');
      expect(
        method.returns?.accept(emitter).toString().replaceAll(' ', ''),
        'Map<String,String>',
      );
      expect(method.optionalParameters.length, 1);
      expect(method.optionalParameters.first.name, 'allowEmpty');
      expect(method.optionalParameters.first.named, isTrue);
      expect(method.optionalParameters.first.required, isFalse);
      expect(
        method.optionalParameters.first.defaultTo?.accept(emitter).toString(),
        'true',
      );
    });

    test('throws error for allOf containing only primitive types', () {
      final model = AllOfModel(
        name: 'Combined',
        models: {
          StringModel(context: context),
        },
        context: context,
      );

      final combinedClass = generator.generateClass(model);
      final classCode = format(combinedClass.accept(emitter).toString());

      const expectedMethod = '''
Map<String, String> parameterProperties({bool allowEmpty = true}) {
  throw EncodingException(
    'parameterProperties not supported for Combined: contains primitive types',
  );
}
''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('encodes allOf with only complex types by merging properties', () {
      final model = AllOfModel(
        name: 'ComplexOnly',
        models: {
          ClassModel(
            name: 'Base',
            properties: const [],
            context: context,
          ),
        },
        context: context,
      );

      final combinedClass = generator.generateClass(model);
      final classCode = format(combinedClass.accept(emitter).toString());

      const expectedMethod = r'''
Map<String, String> parameterProperties({bool allowEmpty = true}) {
  final mergedProperties = <String, String>{};
  mergedProperties.addAll($base.parameterProperties(allowEmpty: allowEmpty));
  return mergedProperties;
}
''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('throws error for allOf with simple and complex types mixed', () {
      final model = AllOfModel(
        name: 'Mixed',
        models: {
          StringModel(context: context),
          ClassModel(
            name: 'Base',
            properties: const [],
            context: context,
          ),
        },
        context: context,
      );

      final combinedClass = generator.generateClass(model);
      final classCode = format(combinedClass.accept(emitter).toString());

      const expectedMethod = '''
Map<String, String> parameterProperties({bool allowEmpty = true}) {
  throw EncodingException(
    'parameterProperties not supported for Mixed: contains primitive types',
  );
}
''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('merges properties for allOf with multiple complex models', () {
      final model = AllOfModel(
        name: 'CombinedModels',
        models: {
          ClassModel(
            name: 'FirstModel',
            properties: const [],
            context: context,
          ),
          ClassModel(
            name: 'SecondModel',
            properties: const [],
            context: context,
          ),
        },
        context: context,
      );

      final combinedClass = generator.generateClass(model);
      final classCode = format(combinedClass.accept(emitter).toString());

      const expectedMethod = '''
Map<String, String> parameterProperties({bool allowEmpty = true}) {
  final mergedProperties = <String, String>{};
  mergedProperties.addAll(
    firstModel.parameterProperties(allowEmpty: allowEmpty),
  );
  mergedProperties.addAll(
    secondModel.parameterProperties(allowEmpty: allowEmpty),
  );
  return mergedProperties;
}
''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test(
      'runtime check for allOf with complex class and mixed encoding anyOf',
      () {
        final anyOfModel = AnyOfModel(
          name: 'StringOrComplex',
          models: {
            (discriminatorValue: null, model: StringModel(context: context)),
            (
              discriminatorValue: null,
              model: ClassModel(
                name: 'ComplexData',
                properties: [
                  Property(
                    name: 'id',
                    model: IntegerModel(context: context),
                    isRequired: true,
                    isNullable: false,
                    isDeprecated: false,
                  ),
                ],
                context: context,
              ),
            ),
          },
          discriminator: null,
          context: context,
        );

        final model = AllOfModel(
          name: 'MixedEncodingAllOf',
          models: {
            ClassModel(
              name: 'SimpleModel',
              properties: [
                Property(
                  name: 'name',
                  model: StringModel(context: context),
                  isRequired: true,
                  isNullable: false,
                  isDeprecated: false,
                ),
              ],
              context: context,
            ),
            anyOfModel,
          },
          context: context,
        );

        final combinedClass = generator.generateClass(model);
        final classCode = format(combinedClass.accept(emitter).toString());

        const expectedMethod = '''
Map<String, String> parameterProperties({bool allowEmpty = true}) {
  final mergedProperties = <String, String>{};
  mergedProperties.addAll(
    stringOrComplex.parameterProperties(allowEmpty: allowEmpty),
  );
  mergedProperties.addAll(
    simpleModel.parameterProperties(allowEmpty: allowEmpty),
  );
  return mergedProperties;
}
''';

        expect(
          collapseWhitespace(classCode),
          contains(collapseWhitespace(expectedMethod)),
        );
      },
    );

    test('returns empty map for empty allOf', () {
      final model = AllOfModel(
        name: 'Empty',
        models: const {},
        context: context,
      );

      final combinedClass = generator.generateClass(model);
      final classCode = format(combinedClass.accept(emitter).toString());

      const expectedMethod = '''
Map<String, String> parameterProperties({bool allowEmpty = true}) {
  return <String, String>{};
}
''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });
  });
}
