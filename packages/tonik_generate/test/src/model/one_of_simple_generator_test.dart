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

  test(
    'toSimple includes discriminator for complex variant, delegates for '
    'primitive',
    () {
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
            ResponseUser(:final value) => {
              ...value.simpleProperties(allowEmpty: allowEmpty),
              'type': 'user',
            }.toSimple( 
              explode: explode, 
              allowEmpty: allowEmpty, 
              alreadyEncoded: true, 
            ),
            ResponseMessage(:final value) => value.toSimple( explode: explode, allowEmpty: allowEmpty, ),
          };
        }
      ''';

      expect(
        collapseWhitespace(format(baseClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedMethod)),
      );
    },
  );

  test(
    'toSimple includes discriminator for all complex variants when '
    'discriminator is present',
    () {
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
        discriminator: 'entity_type',
        context: context,
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere((c) => c.name == 'Entity');

      const expectedMethod = '''
      String toSimple({required bool explode, required bool allowEmpty}) {
        return switch (this) {
          EntityPerson(:final value) => {
            ...value.simpleProperties(allowEmpty: allowEmpty),
            'entity_type': 'person',
          }.toSimple( 
            explode: explode, 
            allowEmpty: allowEmpty, 
            alreadyEncoded: true, 
          ),
          EntityCompany(:final value) => {
            ...value.simpleProperties(allowEmpty: allowEmpty),
            'entity_type': 'company',
          }.toSimple( explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true, ),
        };
      }
    ''';

      expect(
        collapseWhitespace(format(baseClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedMethod)),
      );
    },
  );

  test(
    'toSimple mixes map+discriminator for complex and delegates for '
    'primitive (mixed)',
    () {
      final person = ClassModel(
        name: 'Person',
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
        name: 'MixedEntity',
        models: {
          (discriminatorValue: 'person', model: person),
          (discriminatorValue: 'id', model: StringModel(context: context)),
        },
        discriminator: 'type',
        context: context,
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere((c) => c.name == 'MixedEntity');

      const expectedMethod = '''
      String toSimple({required bool explode, required bool allowEmpty}) {
        return switch (this) {
          MixedEntityPerson(:final value) => {
            ...value.simpleProperties(allowEmpty: allowEmpty),
            'type': 'person',
          }.toSimple( explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true, ),
          MixedEntityId(:final value) => value.toSimple( explode: explode, allowEmpty: allowEmpty, ),
        };
      }
    ''';

      expect(
        collapseWhitespace(format(baseClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedMethod)),
      );
    },
  );

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
      discriminator: null,
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

  group('discriminator support', () {
    test('simpleProperties returns empty map for primitive variants', () {
      final model = OneOfModel(
        name: 'PrimitiveResult',
        models: {
          (discriminatorValue: 'text', model: StringModel(context: context)),
          (discriminatorValue: 'number', model: IntegerModel(context: context)),
        },
        discriminator: 'type',
        context: context,
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere((c) => c.name == 'PrimitiveResult');

      const expectedMethod = '''
        Map<String, String> simpleProperties({required bool allowEmpty}) {
        return switch (this) {
          PrimitiveResultText() => <String, String>{},
          PrimitiveResultNumber() => <String, String>{},
        };
        }
      ''';

      expect(
        collapseWhitespace(format(baseClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test(
      'simpleProperties delegates to variant for complex types without '
      'discriminator',
      () {
        final person = ClassModel(
          name: 'Person',
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
          name: 'EntityNoDisc',
          models: {
            (discriminatorValue: null, model: person),
            (discriminatorValue: null, model: company),
          },
          discriminator: null,
          context: context,
        );

        final classes = generator.generateClasses(model);
        final baseClass = classes.firstWhere((c) => c.name == 'EntityNoDisc');

        const expectedMethod = '''
          Map<String, String> simpleProperties({required bool allowEmpty}) {
            return switch (this) {
              EntityNoDiscPerson(:final value) => value.simpleProperties(
                allowEmpty: allowEmpty,
              ),
              EntityNoDiscCompany(:final value) => value.simpleProperties(
                allowEmpty: allowEmpty,
              ),
            };
          }
        ''';

        expect(
          collapseWhitespace(format(baseClass.accept(emitter).toString())),
          contains(collapseWhitespace(expectedMethod)),
        );
      },
    );

    test(
      'simpleProperties includes discriminator field for complex variants with '
      'discriminator',
      () {
        final person = ClassModel(
          name: 'Person',
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
          discriminator: 'entity_type',
          context: context,
        );

        final classes = generator.generateClasses(model);
        final baseClass = classes.firstWhere((c) => c.name == 'Entity');

        const expectedMethod = '''
          Map<String, String> simpleProperties({required bool allowEmpty}) {
            return switch (this) {
              EntityPerson(:final value) => {
                ...value.simpleProperties(allowEmpty: allowEmpty),
                'entity_type': 'person',
              },
              EntityCompany(:final value) => {
                ...value.simpleProperties(allowEmpty: allowEmpty),
                'entity_type': 'company',
              },
            };
          }
        ''';

        expect(
          collapseWhitespace(format(baseClass.accept(emitter).toString())),
          contains(collapseWhitespace(expectedMethod)),
        );
      },
    );

    test(
      'simpleProperties handles mixed primitive and complex variants with '
      'discriminator',
      () {
        final person = ClassModel(
          name: 'Person',
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
          name: 'MixedEntity',
          models: {
            (discriminatorValue: 'person', model: person),
            (discriminatorValue: 'id', model: StringModel(context: context)),
          },
          discriminator: 'type',
          context: context,
        );

        final classes = generator.generateClasses(model);
        final baseClass = classes.firstWhere((c) => c.name == 'MixedEntity');

        const expectedMethod = '''
          Map<String, String> simpleProperties({required bool allowEmpty}) {
            return switch (this) {
              MixedEntityPerson(:final value) => {
                ...value.simpleProperties(allowEmpty: allowEmpty),
                'type': 'person',
              },
              MixedEntityId() => <String, String>{},
            };
          }
        ''';

        expect(
          collapseWhitespace(format(baseClass.accept(emitter).toString())),
          contains(collapseWhitespace(expectedMethod)),
        );
      },
    );

    test(
      'fromSimple with discriminator checks discriminator when explode is true',
      () {
        final person = ClassModel(
          name: 'Person',
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
          discriminator: 'entity_type',
          context: context,
        );

        final classes = generator.generateClasses(model);
        final baseClass = classes.firstWhere((c) => c.name == 'Entity');

        const expectedMethod = '''
          factory Entity.fromSimple(String? value, {required bool explode}) {
            if (explode && value != null && value.isNotEmpty) {
              final pairs = value.split(',');
              String? discriminator;
              for (final pair in pairs) {
                final parts = pair.split('=');
                if (parts.length == 2) {
                  final key = Uri.decodeComponent(parts[0]);
                  if (key == 'entity_type') {
                    discriminator = parts[1];
                    break;
                  }
                }
              }
              if (discriminator == 'person') {
                return EntityPerson(Person.fromSimple(value, explode: explode));
              }
              if (discriminator == 'company') {
                return EntityCompany(Company.fromSimple(value, explode: explode));
              }
            }
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
      },
    );

    test(
      'fromSimple with discriminator but mixed primitive and complex variants',
      () {
        final person = ClassModel(
          name: 'Person',
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
          name: 'MixedEntity',
          models: {
            (discriminatorValue: 'person', model: person),
            (discriminatorValue: 'id', model: StringModel(context: context)),
          },
          discriminator: 'type',
          context: context,
        );

        final classes = generator.generateClasses(model);
        final baseClass = classes.firstWhere((c) => c.name == 'MixedEntity');

        const expectedMethod = '''
          factory MixedEntity.fromSimple(String? value, {required bool explode}) {
            if (explode && value != null && value.isNotEmpty) {
              final pairs = value.split(',');
              String? discriminator;
              for (final pair in pairs) {
                final parts = pair.split('=');
                if (parts.length == 2) {
                  final key = Uri.decodeComponent(parts[0]);
                  if (key == 'type') {
                    discriminator = parts[1];
                    break;
                  }
                }
              }
              if (discriminator == 'person') {
                return MixedEntityPerson(Person.fromSimple(value, explode: explode));
              }
            }
            try {
              return MixedEntityPerson(Person.fromSimple(value, explode: explode));
            } on DecodingException catch (_) { } on FormatException catch (_) {}
            try {
              return MixedEntityId(value.decodeSimpleString(context: r'MixedEntity'));
            } on DecodingException catch (_) { } on FormatException catch (_) {}
            throw SimpleDecodingException('Invalid simple value for MixedEntity');
          }
        ''';

        expect(
          collapseWhitespace(format(baseClass.accept(emitter).toString())),
          contains(collapseWhitespace(expectedMethod)),
        );
      },
    );

    test(
      'fromSimple without discriminator uses only try-catch approach',
      () {
        final person = ClassModel(
          name: 'Person',
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
          name: 'EntityNoDisc',
          models: {
            (discriminatorValue: null, model: person),
            (discriminatorValue: null, model: company),
          },
          discriminator: null,
          context: context,
        );

        final classes = generator.generateClasses(model);
        final baseClass = classes.firstWhere((c) => c.name == 'EntityNoDisc');

        const expectedMethod = '''
          factory EntityNoDisc.fromSimple(String? value, {required bool explode}) {
            try {
              return EntityNoDiscPerson(Person.fromSimple(value, explode: explode));
            } on DecodingException catch (_) { } on FormatException catch (_) {}
            try {
              return EntityNoDiscCompany(Company.fromSimple(value, explode: explode));
            } on DecodingException catch (_) { } on FormatException catch (_) {}
            throw SimpleDecodingException('Invalid simple value for EntityNoDisc');
          }
        ''';

        expect(
          collapseWhitespace(format(baseClass.accept(emitter).toString())),
          contains(collapseWhitespace(expectedMethod)),
        );
      },
    );
  });
}
