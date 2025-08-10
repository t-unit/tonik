import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/model/one_of_generator.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';

void main() {
  late OneOfGenerator generator;
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
    generator = OneOfGenerator(
      nameManager: nameManager,
      package: 'package:example',
    );
    context = Context.initial();
    emitter = DartEmitter(useNullSafetySyntax: true);
  });

  test('toSimple delegates to active variant value', () {
    final model = OneOfModel(
      name: 'Result',
      models: {
        (
          discriminatorValue: 'success',
          model: StringModel(context: context),
        ),
        (
          discriminatorValue: 'error',
          model: IntegerModel(context: context),
        ),
      },
      discriminator: null,
      context: context,
    );

    final classes = generator.generateClasses(model);
    final baseClass = classes.firstWhere((c) => c.name == 'Result');

    const expectedMethod = '''
        String toSimple({required bool explode, required bool allowEmpty}) {
          return switch (this) {
            ResultSuccess(:final value) => value.toSimple( explode: explode, allowEmpty: allowEmpty, ),
            ResultError(:final value) => value.toSimple( explode: explode, allowEmpty: allowEmpty, ),
          };
        }
      ''';

    expect(
      collapseWhitespace(format(baseClass.accept(emitter).toString())),
      contains(collapseWhitespace(expectedMethod)),
    );
  });

  test('fromSimple tries variants in declaration order (primitive-only)', () {
    final model = OneOfModel(
      name: 'Result',
      models: {
        (
          discriminatorValue: 'error',
          model: IntegerModel(context: context),
        ),
        (
          discriminatorValue: 'success',
          model: StringModel(context: context),
        ),
      },
      discriminator: null,
      context: context,
    );

    final classes = generator.generateClasses(model);
    final baseClass = classes.firstWhere((c) => c.name == 'Result');

    const expectedMethod = '''
        factory Result.fromSimple(String? value, {required bool explode}) {
          try {
            return ResultError(value.decodeSimpleInt(context: r'Result'));
          } on DecodingException catch (_) { } on FormatException catch (_) {}
          try {
            return ResultSuccess(value.decodeSimpleString(context: r'Result'));
          } on DecodingException catch (_) { } on FormatException catch (_) {}
          throw SimpleDecodingException('Invalid simple value for Result');
        }
      ''';

    expect(
      collapseWhitespace(format(baseClass.accept(emitter).toString())),
      contains(collapseWhitespace(expectedMethod)),
    );
  });

  test('toSimple delegates for complex variants', () {
    final userModel = ClassModel(
      name: 'User',
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

    final model = OneOfModel(
      name: 'Response',
      models: {
        (
          discriminatorValue: 'user',
          model: userModel,
        ),
        (
          discriminatorValue: 'message',
          model: StringModel(context: context),
        ),
      },
      discriminator: 'type',
      context: context,
    );

    final classes = generator.generateClasses(model);
    final baseClass = classes.firstWhere((c) => c.name == 'Response');

    const expectedMethod = '''
        String toSimple({required bool explode, required bool allowEmpty}) {
          return switch (this) {
            ResponseUser(:final value) => value.toSimple( explode: explode, allowEmpty: allowEmpty, ),
            ResponseMessage(:final value) => value.toSimple( explode: explode, allowEmpty: allowEmpty, ),
          };
        }
      ''';

    expect(
      collapseWhitespace(format(baseClass.accept(emitter).toString())),
      contains(collapseWhitespace(expectedMethod)),
    );
  });

  test('fromSimple tries complex variants using fromSimple with explode', () {
    final person = ClassModel(
      name: 'Person',
      properties: [
        Property(
          name: 'first_name',
          model: StringModel(context: context),
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
        ),
      ],
      context: context,
    );

    final company = ClassModel(
      name: 'Company',
      properties: [
        Property(
          name: 'company_name',
          model: StringModel(context: context),
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
        ),
      ],
      context: context,
    );

    final model = OneOfModel(
      name: 'Entity',
      models: {
        (discriminatorValue: 'person', model: person),
        (discriminatorValue: 'company', model: company),
      },
      discriminator: 'type',
      context: context,
    );

    final classes = generator.generateClasses(model);
    final baseClass = classes.firstWhere((c) => c.name == 'Entity');

    const expectedMethod = '''
        factory Entity.fromSimple(String? value, {required bool explode}) {
          try {
            return EntityPerson(Person.fromSimple(value, explode: explode));
          } on DecodingException catch (_) { } on FormatException catch (_) {}
          try {
            return EntityCompany(Company.fromSimple(value, explode: explode));
          } on DecodingException catch (_) { } on FormatException catch (_) {}
          throw SimpleDecodingException('Invalid simple value for Entity');
        }
      ''';

    expect(
      collapseWhitespace(format(baseClass.accept(emitter).toString())),
      contains(collapseWhitespace(expectedMethod)),
    );
  });
}
