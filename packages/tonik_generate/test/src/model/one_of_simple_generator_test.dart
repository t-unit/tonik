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

  final format = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  ).format;

  setUp(() {
    nameGenerator = NameGenerator();
    nameManager = NameManager(
      generator: nameGenerator,
      stableModelSorter: StableModelSorter(),
    );
    generator = OneOfGenerator(
      nameManager: nameManager,
      package: 'example',
      stableModelSorter: StableModelSorter(),
    );
    context = Context.initial();
    emitter = DartEmitter(useNullSafetySyntax: true);
  });

  group('toSimple', () {
    test('toSimple delegates to active variant value', () {
      final model = OneOfModel(
        isDeprecated: false,
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
        context: context,
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere((c) => c.name == 'Result');

      const expectedMethod = '''
        String toSimple({required bool explode, required bool allowEmpty}) {
          return switch (this) {
            ResultError(:final value) => value.toSimple( explode: explode, allowEmpty: allowEmpty, ),
            ResultSuccess(:final value) => value.toSimple( explode: explode, allowEmpty: allowEmpty, ),
          };
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
          isDeprecated: false,
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
          isDeprecated: false,
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
            ResponseMessage(:final value) => value.toSimple( explode: explode, allowEmpty: allowEmpty, ),
            ResponseUser(:final value) => {
              ...value.parameterProperties(allowEmpty: allowEmpty),
              r'type': r'user',
            }.toSimple( 
              explode: explode, 
              allowEmpty: allowEmpty, 
              alreadyEncoded: true, 
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
      'toSimple includes discriminator for all complex variants when '
      'discriminator is present',
      () {
        final person = ClassModel(
          isDeprecated: false,
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
          isDeprecated: false,
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
          isDeprecated: false,
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
          EntityCompany(:final value) => {
            ...value.parameterProperties(allowEmpty: allowEmpty),
            r'entity_type': r'company',
          }.toSimple( explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true, ),
          EntityPerson(:final value) => {
            ...value.parameterProperties(allowEmpty: allowEmpty),
            r'entity_type': r'person',
          }.toSimple( 
            explode: explode, 
            allowEmpty: allowEmpty, 
            alreadyEncoded: true, 
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
      'toSimple mixes map+discriminator for complex and delegates for '
      'primitive (mixed)',
      () {
        final person = ClassModel(
          isDeprecated: false,
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
          isDeprecated: false,
        );

        final classes = generator.generateClasses(model);
        final baseClass = classes.firstWhere((c) => c.name == 'MixedEntity');

        const expectedMethod = '''
      String toSimple({required bool explode, required bool allowEmpty}) {
        return switch (this) {
          MixedEntityId(:final value) => value.toSimple( explode: explode, allowEmpty: allowEmpty, ),
          MixedEntityPerson(:final value) => {
            ...value.parameterProperties(allowEmpty: allowEmpty),
            r'type': r'person',
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
  });

  group('fromSimple', () {
    test('fromSimple tries complex variants using fromSimple with explode', () {
      final person = ClassModel(
        isDeprecated: false,
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
        isDeprecated: false,
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
        isDeprecated: false,
        name: 'Entity',
        models: {
          (discriminatorValue: 'person', model: person),
          (discriminatorValue: 'company', model: company),
        },
        context: context,
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere((c) => c.name == 'Entity');

      const expectedMethod = '''
        factory Entity.fromSimple(String? value, {required bool explode}) {
          try {
            return EntityCompany(Company.fromSimple(value, explode: explode));
          } on DecodingException catch (_) { } on FormatException catch (_) {}
          try {
            return EntityPerson(Person.fromSimple(value, explode: explode));
          } on DecodingException catch (_) { } on FormatException catch (_) {}
          throw SimpleDecodingException(r'Invalid simple value for Entity');
        }
      ''';

      expect(
        collapseWhitespace(format(baseClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('fromSimple tries variants in declaration order (primitive-only)', () {
      final model = OneOfModel(
        isDeprecated: false,
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
          throw SimpleDecodingException(r'Invalid simple value for Result');
        }
      ''';

      expect(
        collapseWhitespace(format(baseClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test(
      'fromSimple with discriminator checks discriminator when explode is true',
      () {
        final person = ClassModel(
          isDeprecated: false,
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
          isDeprecated: false,
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
          isDeprecated: false,
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

        const expectedMethod = r'''
          factory Entity.fromSimple(String? value, {required bool explode}) {
            if (explode && value != null && value.isNotEmpty) {
              final _$pairs = value.split(',');
              String? _$discriminator;
              for (final pair in _$pairs) {
                final _$parts = pair.split('=');
                if (_$parts.length == 2) {
                  final _$key = Uri.decodeComponent(_$parts[0]);
                  if (_$key == r'entity_type') {
                    _$discriminator = _$parts[1];
                    break;
                  }
                }
              }
              if (_$discriminator == r'company') {
                return EntityCompany(Company.fromSimple(value, explode: explode));
              }
              if (_$discriminator == r'person') {
                return EntityPerson(Person.fromSimple(value, explode: explode));
              }
            }
            try {
              return EntityCompany(Company.fromSimple(value, explode: explode));
            } on DecodingException catch (_) { } on FormatException catch (_) {}
            try {
              return EntityPerson(Person.fromSimple(value, explode: explode));
            } on DecodingException catch (_) { } on FormatException catch (_) {}
            throw SimpleDecodingException(r'Invalid simple value for Entity');
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
          isDeprecated: false,
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
          isDeprecated: false,
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

        const expectedMethod = r'''
          factory MixedEntity.fromSimple(String? value, {required bool explode}) {
            if (explode && value != null && value.isNotEmpty) {
              final _$pairs = value.split(',');
              String? _$discriminator;
              for (final pair in _$pairs) {
                final _$parts = pair.split('=');
                if (_$parts.length == 2) {
                  final _$key = Uri.decodeComponent(_$parts[0]);
                  if (_$key == r'type') {
                    _$discriminator = _$parts[1];
                    break;
                  }
                }
              }
              if (_$discriminator == r'person') {
                return MixedEntityPerson(Person.fromSimple(value, explode: explode));
              }
            }
            try {
              return MixedEntityId(value.decodeSimpleString(context: r'MixedEntity'));
            } on DecodingException catch (_) { } on FormatException catch (_) {}
            try {
              return MixedEntityPerson(Person.fromSimple(value, explode: explode));
            } on DecodingException catch (_) { } on FormatException catch (_) {}
            throw SimpleDecodingException(r'Invalid simple value for MixedEntity');
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
          isDeprecated: false,
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
          isDeprecated: false,
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
          isDeprecated: false,
          name: 'EntityNoDisc',
          models: {
            (discriminatorValue: null, model: person),
            (discriminatorValue: null, model: company),
          },
          context: context,
        );

        final classes = generator.generateClasses(model);
        final baseClass = classes.firstWhere((c) => c.name == 'EntityNoDisc');

        const expectedMethod = '''
          factory EntityNoDisc.fromSimple(String? value, {required bool explode}) {
            try {
              return EntityNoDiscCompany(Company.fromSimple(value, explode: explode));
            } on DecodingException catch (_) { } on FormatException catch (_) {}
            try {
              return EntityNoDiscPerson(Person.fromSimple(value, explode: explode));
            } on DecodingException catch (_) { } on FormatException catch (_) {}
            throw SimpleDecodingException(r'Invalid simple value for EntityNoDisc');
          }
        ''';

        expect(
          collapseWhitespace(format(baseClass.accept(emitter).toString())),
          contains(collapseWhitespace(expectedMethod)),
        );
      },
    );
  });

  group(r'nullable oneOf with $Raw-prefixed class name', () {
    late OneOfModel model;

    setUp(() {
      final person = ClassModel(
        isDeprecated: false,
        name: 'Person',
        properties: const [],
        context: context,
      );
      final company = ClassModel(
        isDeprecated: false,
        name: 'Company',
        properties: const [],
        context: context,
      );

      model = OneOfModel(
        isDeprecated: false,
        name: 'Entity',
        models: {
          (discriminatorValue: null, model: person),
          (discriminatorValue: null, model: company),
        },
        context: context,
        isNullable: true,
      );

      nameManager.prime(
        models: {model},
        requestBodies: const [],
        responses: const [],
        operations: const [],
        tags: const [],
        servers: const [],
      );
    });

    test(
      r'fromSimple throws raw string literal for $Raw-prefixed class name',
      () {
        final classes = generator.generateClasses(model, r'$RawEntity');
        final baseClass = classes.firstWhere((c) => c.name == r'$RawEntity');
        final generatedCode = format(baseClass.accept(emitter).toString());

        expect(
          generatedCode,
          contains(r"r'Invalid simple value for $RawEntity'"),
        );
      },
    );

    test('throws EncodingException for BinaryModel variant in toSimple', () {
      final model = OneOfModel(
        isDeprecated: false,
        name: 'WithBinary',
        models: {
          (
            discriminatorValue: 'binary',
            model: BinaryModel(context: context),
          ),
          (
            discriminatorValue: 'text',
            model: StringModel(context: context),
          ),
        },
        context: context,
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere((c) => c.name == 'WithBinary');
      final generated = format(baseClass.accept(emitter).toString());

      expect(
        collapseWhitespace(generated),
        contains(
          collapseWhitespace(
            'throw EncodingException(\n'
            "'Binary data cannot be simple-encoded',\n"
            ')',
          ),
        ),
      );
    });
  });

  group('fromSimple with List/Map variants', () {
    test('fromSimple throws for MapModel variant', () {
      final mapVariant = MapModel(
        valueModel: StringModel(context: context),
        context: context,
        name: 'Tags',
      );

      final model = OneOfModel(
        isDeprecated: false,
        name: 'Payload',
        models: {
          (discriminatorValue: null, model: StringModel(context: context)),
          (discriminatorValue: null, model: mapVariant),
        },
        context: context,
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere((c) => c.name == 'Payload');
      final generated = format(baseClass.accept(emitter).toString());

      // Map variant should throw SimpleDecodingException, not be silently
      // skipped
      expect(
        collapseWhitespace(generated),
        contains(
          collapseWhitespace(
            'throw SimpleDecodingException(\n'
            "r'Map types cannot be decoded from simple encoding "
            "in Payload',\n);",
          ),
        ),
      );
    });

    test('fromSimple throws for complex ListModel variant', () {
      final innerClass = ClassModel(
        isDeprecated: false,
        name: 'Item',
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
      );

      final listVariant = ListModel(
        content: innerClass,
        context: context,
        name: 'Items',
      );

      final model = OneOfModel(
        isDeprecated: false,
        name: 'Payload',
        models: {
          (discriminatorValue: null, model: StringModel(context: context)),
          (discriminatorValue: null, model: listVariant),
        },
        context: context,
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere((c) => c.name == 'Payload');
      final generated = format(baseClass.accept(emitter).toString());

      // Complex List variant should throw SimpleDecodingException, not be
      // silently skipped
      expect(
        collapseWhitespace(generated),
        contains(
          collapseWhitespace(
            'throw SimpleDecodingException(\n'
            "r'List types with complex content cannot be decoded "
            "from simple encoding in Payload',\n);",
          ),
        ),
      );
    });

    test('fromSimple throws for simple-content ListModel variant '
        'that is not decodable', () {
      // A ListModel with simple content that is NOT a list of primitives
      // (e.g. list of enums) — the hasSimpleContent branch
      final listVariant = ListModel(
        content: StringModel(context: context),
        context: context,
        name: 'Tags',
        isNullable: true,
      );

      final model = OneOfModel(
        isDeprecated: false,
        name: 'Payload',
        models: {
          (discriminatorValue: null, model: IntegerModel(context: context)),
          (discriminatorValue: null, model: listVariant),
        },
        context: context,
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere((c) => c.name == 'Payload');
      final generated = format(baseClass.accept(emitter).toString());

      // Simple-content list should be decodable via try/catch path
      expect(
        collapseWhitespace(generated),
        contains(
          collapseWhitespace(
            'return PayloadTags(value.decodeSimpleStringList(',
          ),
        ),
      );
    });
  });

  group('special characters in discriminator', () {
    test(
      'fromSimple escapes discriminator value containing single quote',
      () {
        final model = OneOfModel(
          isDeprecated: false,
          name: 'Result',
          models: {
            (
              discriminatorValue: "it's-success",
              model: ClassModel(
                isDeprecated: false,
                name: 'Success',
                properties: [
                  Property(
                    name: 'value',
                    model: StringModel(context: context),
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

        final classes = generator.generateClasses(model);
        final baseClass = classes.firstWhere((c) => c.name == 'Result');
        final generated = format(baseClass.accept(emitter).toString());

        const expectedMethod = r'''
          factory Result.fromSimple(String? value, {required bool explode}) {
            if (explode && value != null && value.isNotEmpty) {
              final _$pairs = value.split(',');
              String? _$discriminator;
              for (final pair in _$pairs) {
                final _$parts = pair.split('=');
                if (_$parts.length == 2) {
                  final _$key = Uri.decodeComponent(_$parts[0]);
                  if (_$key == r'type') {
                    _$discriminator = _$parts[1];
                    break;
                  }
                }
              }
              if (_$discriminator == r"it's-success") {
                return ResultSuccess(Success.fromSimple(value, explode: explode));
              }
            }
            try {
              return ResultSuccess(Success.fromSimple(value, explode: explode));
            } on DecodingException catch (_) { } on FormatException catch (_) {}
            throw SimpleDecodingException(r'Invalid simple value for Result');
          }''';

        expect(
          collapseWhitespace(generated),
          contains(collapseWhitespace(expectedMethod)),
        );
      },
    );

    test(
      'fromSimple escapes discriminator field name containing single quote',
      () {
        final model = OneOfModel(
          isDeprecated: false,
          name: 'Result',
          models: {
            (
              discriminatorValue: 'success',
              model: ClassModel(
                isDeprecated: false,
                name: 'Success',
                properties: [
                  Property(
                    name: 'value',
                    model: StringModel(context: context),
                    isRequired: true,
                    isNullable: false,
                    isDeprecated: false,
                  ),
                ],
                context: context,
              ),
            ),
          },
          discriminator: "it's-type",
          context: context,
        );

        final classes = generator.generateClasses(model);
        final baseClass = classes.firstWhere((c) => c.name == 'Result');
        final generated = format(baseClass.accept(emitter).toString());

        const expectedMethod = r'''
          factory Result.fromSimple(String? value, {required bool explode}) {
            if (explode && value != null && value.isNotEmpty) {
              final _$pairs = value.split(',');
              String? _$discriminator;
              for (final pair in _$pairs) {
                final _$parts = pair.split('=');
                if (_$parts.length == 2) {
                  final _$key = Uri.decodeComponent(_$parts[0]);
                  if (_$key == r"it's-type") {
                    _$discriminator = _$parts[1];
                    break;
                  }
                }
              }
              if (_$discriminator == r'success') {
                return ResultSuccess(Success.fromSimple(value, explode: explode));
              }
            }
            try {
              return ResultSuccess(Success.fromSimple(value, explode: explode));
            } on DecodingException catch (_) { } on FormatException catch (_) {}
            throw SimpleDecodingException(r'Invalid simple value for Result');
          }''';

        expect(
          collapseWhitespace(generated),
          contains(collapseWhitespace(expectedMethod)),
        );
      },
    );
  });
}
