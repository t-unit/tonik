import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/model/class_generator.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';

void main() {
  group('ClassGenerator toDeepObject generation', () {
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

    test('generates toDeepObject method with correct signature', () {
      final model = ClassModel(
        isDeprecated: false,
        name: 'SimpleModel',
        properties: [
          Property(
            name: 'name',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
          Property(
            name: 'count',
            model: IntegerModel(context: context),
            isRequired: false,
            isNullable: true,
            isDeprecated: false,
          ),
        ],
        context: context,
      );

      final result = generator.generateClass(model);

      final toDeepObjectMethod = result.methods.firstWhere(
        (m) => m.name == 'toDeepObject',
      );
      expect(
        toDeepObjectMethod.returns?.accept(emitter).toString(),
        'List<ParameterEntry>',
      );
      expect(toDeepObjectMethod.requiredParameters.length, 1);
      expect(toDeepObjectMethod.requiredParameters.first.name, 'paramName');
      expect(
        toDeepObjectMethod.requiredParameters.first.type
            ?.accept(emitter)
            .toString(),
        'String',
      );
      expect(toDeepObjectMethod.optionalParameters.length, 2);
      expect(toDeepObjectMethod.optionalParameters.first.name, 'explode');
      expect(toDeepObjectMethod.optionalParameters.first.required, isTrue);
      expect(toDeepObjectMethod.optionalParameters.first.named, isTrue);
      expect(
        toDeepObjectMethod.optionalParameters.first.type
            ?.accept(emitter)
            .toString(),
        'bool',
      );
      expect(toDeepObjectMethod.optionalParameters.last.name, 'allowEmpty');
      expect(toDeepObjectMethod.optionalParameters.last.required, isTrue);
      expect(toDeepObjectMethod.optionalParameters.last.named, isTrue);
      expect(
        toDeepObjectMethod.optionalParameters.last.type
            ?.accept(emitter)
            .toString(),
        'bool',
      );
    });

    test('generates toDeepObject method for empty model', () {
      final model = ClassModel(
        isDeprecated: false,
        name: 'EmptyModel',
        properties: const [],
        context: context,
      );

      final result = generator.generateClass(model);
      final toDeepObjectMethod = result.methods.firstWhere(
        (m) => m.name == 'toDeepObject',
      );
      expect(
        toDeepObjectMethod.returns?.accept(emitter).toString(),
        'List<ParameterEntry>',
      );
      expect(toDeepObjectMethod.requiredParameters.length, 1);
      expect(toDeepObjectMethod.requiredParameters.first.name, 'paramName');
      expect(toDeepObjectMethod.optionalParameters.length, 2);
      expect(toDeepObjectMethod.optionalParameters.first.name, 'explode');
      expect(toDeepObjectMethod.optionalParameters.last.name, 'allowEmpty');

      const expectedToDeepObjectMethod = '''
        List<ParameterEntry> toDeepObject(String paramName, {required bool explode, required bool allowEmpty, }) {
          return parameterProperties(allowEmpty: allowEmpty, allowLists: false, ).toDeepObject(paramName, explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true, );
        }
      ''';

      final generatedCode = result.accept(emitter).toString();
      expect(
        collapseWhitespace(generatedCode),
        contains(collapseWhitespace(expectedToDeepObjectMethod)),
      );
    });

    test(
      'toDeepObject method generates proper method body for single '
      'property model',
      () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'TestModel',
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
        );

        final result = generator.generateClass(model);

        final toDeepObjectMethod = result.methods.firstWhere(
          (m) => m.name == 'toDeepObject',
        );
        expect(toDeepObjectMethod.name, 'toDeepObject');
        expect(
          toDeepObjectMethod.returns?.accept(emitter).toString(),
          'List<ParameterEntry>',
        );
        expect(
          toDeepObjectMethod.lambda,
          isNot(isTrue),
        );

        const expectedToDeepObjectMethod = '''
        List<ParameterEntry> toDeepObject(String paramName, {required bool explode, required bool allowEmpty, }) {
          return parameterProperties(allowEmpty: allowEmpty, allowLists: false, ).toDeepObject(paramName, explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true, );
        }
      ''';

        final generatedCode = result.accept(emitter).toString();
        expect(
          collapseWhitespace(generatedCode),
          contains(collapseWhitespace(expectedToDeepObjectMethod)),
        );
      },
    );

    test(
      'toDeepObject method generates proper method body for multiple '
      'properties model',
      () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'ComplexModel',
          properties: [
            Property(
              name: 'firstName',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
            Property(
              name: 'age',
              model: IntegerModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
            Property(
              name: 'email',
              model: StringModel(context: context),
              isRequired: false,
              isNullable: true,
              isDeprecated: false,
            ),
          ],
          context: context,
        );

        final result = generator.generateClass(model);

        const expectedToDeepObjectMethod = '''
        List<ParameterEntry> toDeepObject(String paramName, {required bool explode, required bool allowEmpty, }) {
          return parameterProperties(allowEmpty: allowEmpty, allowLists: false, ).toDeepObject(paramName, explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true, );
        }
      ''';

        final generatedCode = result.accept(emitter).toString();
        expect(
          collapseWhitespace(generatedCode),
          contains(collapseWhitespace(expectedToDeepObjectMethod)),
        );
      },
    );

    test(
      'toDeepObject method passes allowLists=false to parameterProperties',
      () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'ModelWithList',
          properties: [
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
          ],
          context: context,
        );

        final result = generator.generateClass(model);

        const expectedToDeepObjectMethod = '''
        List<ParameterEntry> toDeepObject(String paramName, {required bool explode, required bool allowEmpty, }) {
          return parameterProperties(allowEmpty: allowEmpty, allowLists: false, ).toDeepObject(paramName, explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true, );
        }
      ''';

        final generatedCode = result.accept(emitter).toString();
        expect(
          collapseWhitespace(generatedCode),
          contains(collapseWhitespace(expectedToDeepObjectMethod)),
        );
      },
    );

    test(
      'toDeepObject method works with nullable required properties',
      () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'NullableModel',
          properties: [
            Property(
              name: 'optionalName',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: true,
              isDeprecated: false,
            ),
          ],
          context: context,
        );

        final result = generator.generateClass(model);

        const expectedToDeepObjectMethod = '''
        List<ParameterEntry> toDeepObject(String paramName, {required bool explode, required bool allowEmpty, }) {
          return parameterProperties(allowEmpty: allowEmpty, allowLists: false, ).toDeepObject(paramName, explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true, );
        }
      ''';

        final generatedCode = result.accept(emitter).toString();
        expect(
          collapseWhitespace(generatedCode),
          contains(collapseWhitespace(expectedToDeepObjectMethod)),
        );
      },
    );

    test(
      'toDeepObject method works with optional properties',
      () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'OptionalModel',
          properties: [
            Property(
              name: 'optionalField',
              model: IntegerModel(context: context),
              isRequired: false,
              isNullable: true,
              isDeprecated: false,
            ),
          ],
          context: context,
        );

        final result = generator.generateClass(model);

        const expectedToDeepObjectMethod = '''
        List<ParameterEntry> toDeepObject(String paramName, {required bool explode, required bool allowEmpty, }) {
          return parameterProperties(allowEmpty: allowEmpty, allowLists: false, ).toDeepObject(paramName, explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true, );
        }
      ''';

        final generatedCode = result.accept(emitter).toString();
        expect(
          collapseWhitespace(generatedCode),
          contains(collapseWhitespace(expectedToDeepObjectMethod)),
        );
      },
    );

    test(
      'toDeepObject method works with mixed simple and complex types',
      () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'MixedModel',
          properties: [
            Property(
              name: 'name',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
            Property(
              name: 'nested',
              model: ClassModel(
                isDeprecated: false,
                name: 'NestedClass',
                properties: [
                  Property(
                    name: 'value',
                    model: IntegerModel(context: context),
                    isRequired: true,
                    isNullable: false,
                    isDeprecated: false,
                  ),
                ],
                context: context,
              ),
              isRequired: false,
              isNullable: true,
              isDeprecated: false,
            ),
          ],
          context: context,
        );

        final result = generator.generateClass(model);

        const expectedToDeepObjectMethod = '''
        List<ParameterEntry> toDeepObject(String paramName, {required bool explode, required bool allowEmpty, }) {
          return parameterProperties(allowEmpty: allowEmpty, allowLists: false, ).toDeepObject(paramName, explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true, );
        }
      ''';

        final generatedCode = result.accept(emitter).toString();
        expect(
          collapseWhitespace(generatedCode),
          contains(collapseWhitespace(expectedToDeepObjectMethod)),
        );
      },
    );

    test(
      'toDeepObject method passes alreadyEncoded=true',
      () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'EncodedModel',
          properties: [
            Property(
              name: 'data',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          context: context,
        );

        final result = generator.generateClass(model);

        const expectedToDeepObjectMethod = '''
        List<ParameterEntry> toDeepObject(String paramName, {required bool explode, required bool allowEmpty, }) {
          return parameterProperties(allowEmpty: allowEmpty, allowLists: false, ).toDeepObject(paramName, explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true, );
        }
      ''';

        final generatedCode = result.accept(emitter).toString();
        expect(
          collapseWhitespace(generatedCode),
          contains(collapseWhitespace(expectedToDeepObjectMethod)),
        );
      },
    );
  });
}
