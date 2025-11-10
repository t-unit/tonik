import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/model/class_generator.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';

void main() {
  group('ClassGenerator fromForm parsing logic', () {
    late ClassGenerator generator;
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
      generator = ClassGenerator(
        nameManager: nameManager,
        package: 'package:example',
      );
      context = Context.initial();
      emitter = DartEmitter(useNullSafetySyntax: true);
    });

    test('fromForm constructor exists with correct signature', () {
      final model = ClassModel(
        name: 'TestModel',
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
      final fromFormConstructor = result.constructors.firstWhere(
        (c) => c.name == 'fromForm',
      );

      expect(fromFormConstructor.factory, isTrue);
      expect(fromFormConstructor.requiredParameters.length, 1);
      expect(fromFormConstructor.requiredParameters.first.name, 'value');
      expect(
        fromFormConstructor.requiredParameters.first.type
            ?.accept(emitter)
            .toString(),
        'String?',
      );
      expect(fromFormConstructor.optionalParameters.length, 1);
      expect(fromFormConstructor.optionalParameters.first.name, 'explode');
      expect(fromFormConstructor.optionalParameters.first.required, isTrue);
    });

    test('generates complete fromForm method with parsing logic', () {
      final model = ClassModel(
        name: 'TestModel',
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
      final generatedCode = format(result.accept(emitter).toString());

      const expectedFromFormMethod = '''
        factory TestModel.fromForm(String? value, {required bool explode}) {
          final values = value.decodeObject(
            explode: explode,
            explodeSeparator: '&',
            expectedKeys: {r'name', r'count'},
            listKeys: {},
            isFormStyle: true,
            context: r'TestModel',
          );
          return TestModel(
            name: values[r'name'].decodeFormString(context: r'TestModel.name'),
            count: values[r'count'].decodeFormNullableInt(
              context: r'TestModel.count',
            ),
          );
        }
      ''';

      expect(
        collapseWhitespace(generatedCode),
        contains(collapseWhitespace(expectedFromFormMethod)),
      );
    });

    test('generates fromForm method with all property types', () {
      final model = ClassModel(
        name: 'ComplexForm',
        properties: [
          Property(
            name: 'name',
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
      final generatedCode = format(result.accept(emitter).toString());

      const expectedFromFormMethod = '''
        factory ComplexForm.fromForm(String? value, {required bool explode}) {
          final values = value.decodeObject(
            explode: explode,
            explodeSeparator: '&',
            expectedKeys: {r'name', r'age', r'email'},
            listKeys: {},
            isFormStyle: true,
            context: r'ComplexForm',
          );
          return ComplexForm(
            name: values[r'name'].decodeFormString(context: r'ComplexForm.name'),
            age: values[r'age'].decodeFormInt(context: r'ComplexForm.age'),
            email: values[r'email'].decodeFormNullableString(
              context: r'ComplexForm.email',
            ),
          );
        }
      ''';

      expect(
        collapseWhitespace(generatedCode),
        contains(collapseWhitespace(expectedFromFormMethod)),
      );
    });

    test(
      'generates fromForm for mixed OneOf that attempts decoding',
      () {
        final oneOfModel = OneOfModel(
          name: 'DynamicValue',
          models: {
            (discriminatorValue: 'str', model: StringModel(context: context)),
            (
              discriminatorValue: 'class',
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
          discriminator: 'type',
          context: context,
        );
        final model = ClassModel(
          name: 'Wrapper',
          properties: [
            Property(
              name: 'data',
              model: oneOfModel,
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          context: context,
        );

        final result = generator.generateClass(model);
        final generatedCode = format(result.accept(emitter).toString());

        const expectedFromFormMethod = '''
          factory Wrapper.fromForm(String? value, {required bool explode}) {
            final values = value.decodeObject(
              explode: explode,
              explodeSeparator: '&',
              expectedKeys: {r'data'},
              listKeys: {},
              isFormStyle: true,
              context: r'Wrapper',
            );
            return Wrapper(
              data: DynamicValue.fromForm(values[r'data'], explode: explode),
            );
          }
        ''';

        expect(
          collapseWhitespace(generatedCode),
          contains(collapseWhitespace(expectedFromFormMethod)),
        );
      },
    );
  });
}
