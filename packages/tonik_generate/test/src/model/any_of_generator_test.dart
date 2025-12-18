import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/model/any_of_generator.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  late AnyOfGenerator generator;
  late NameManager nameManager;
  late NameGenerator nameGenerator;
  late Context context;
  late DartEmitter emitter;

  final format = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  ).format;

  setUp(() {
    nameGenerator = NameGenerator();
    nameManager = NameManager(generator: nameGenerator);
    generator = AnyOfGenerator(
      nameManager: nameManager,
      package: 'package:example',
    );
    context = Context.initial();
    emitter = DartEmitter(useNullSafetySyntax: true);
  });

  group('AnyOfGenerator basic structure', () {
    test('generates AnyOf class with nullable fields for each model', () {
      final model = AnyOfModel(
        isDeprecated: false,
        name: 'FlexibleModel',
        models: {
          (discriminatorValue: 'id', model: IntegerModel(context: context)),
          (discriminatorValue: 'name', model: StringModel(context: context)),
          (
            discriminatorValue: 'details',
            model: ClassModel(
              isDeprecated: false,
              name: 'Details',
              properties: const [],
              context: context,
            ),
          ),
        },
        context: context,
      );

      final klass = generator.generateClass(model);

      expect(klass.name, 'FlexibleModel');

      final ctor = klass.constructors.firstWhere((c) => c.name == null);
      expect(ctor.constant, isTrue);
      expect(ctor.name, isNull);

      final fieldNames = klass.fields.map((f) => f.name).toList();
      expect(fieldNames, containsAll(['int', 'string', 'details']));

      final intField = klass.fields.firstWhere((f) => f.name == 'int');
      expect(intField.type?.accept(emitter).toString(), 'int?');
      expect(intField.modifier, FieldModifier.final$);

      final stringField = klass.fields.firstWhere((f) => f.name == 'string');
      expect(stringField.type?.accept(emitter).toString(), 'String?');
      expect(stringField.modifier, FieldModifier.final$);

      final detailsField = klass.fields.firstWhere((f) => f.name == 'details');
      expect(detailsField.type?.accept(emitter).toString(), 'Details?');
      expect(detailsField.modifier, FieldModifier.final$);

      final ctorParams = ctor.optionalParameters;
      expect(
        ctorParams.map((p) => p.name),
        containsAll(['int', 'string', 'details']),
      );
      expect(ctorParams.every((p) => p.named), isTrue);
      expect(ctorParams.every((p) => !p.required), isTrue);
      expect(ctorParams.every((p) => p.toThis), isTrue);
    });

    group('doc comments', () {
      test('generates class with doc comment from description', () {
        final model = AnyOfModel(
          isDeprecated: false,
          description: 'A flexible model that can have multiple values',
          name: 'FlexibleModel',
          models: {
            (discriminatorValue: null, model: IntegerModel(context: context)),
            (discriminatorValue: null, model: StringModel(context: context)),
          },
          context: context,
        );

        final klass = generator.generateClass(model);

        expect(
          klass.docs,
          ['/// A flexible model that can have multiple values'],
        );
      });

      test('generates class with multiline doc comment', () {
        final model = AnyOfModel(
          isDeprecated: false,
          description: 'A flexible model.\nSupports multiple types.',
          name: 'FlexibleModel',
          models: {
            (discriminatorValue: null, model: IntegerModel(context: context)),
            (discriminatorValue: null, model: StringModel(context: context)),
          },
          context: context,
        );

        final klass = generator.generateClass(model);

        expect(klass.docs, [
          '/// A flexible model.',
          '/// Supports multiple types.',
        ]);
      });

      test('generates class without doc comment when description is null', () {
        final model = AnyOfModel(
          isDeprecated: false,
          name: 'FlexibleModel',
          models: {
            (discriminatorValue: null, model: IntegerModel(context: context)),
            (discriminatorValue: null, model: StringModel(context: context)),
          },
          context: context,
        );

        final klass = generator.generateClass(model);

        expect(klass.docs, isEmpty);
      });

      test('generates class without doc comment when description is empty', () {
        final model = AnyOfModel(
          isDeprecated: false,
          description: '',
          name: 'FlexibleModel',
          models: {
            (discriminatorValue: null, model: IntegerModel(context: context)),
            (discriminatorValue: null, model: StringModel(context: context)),
          },
          context: context,
        );

        final klass = generator.generateClass(model);

        expect(klass.docs, isEmpty);
      });
    });

    test(
      'generates AnyOf class when discriminatorValue is absent for all entries',
      () {
        final model = AnyOfModel(
          isDeprecated: false,
          name: 'AnonymousChoices',
          models: {
            (
              discriminatorValue: null,
              model: ClassModel(
                isDeprecated: false,
                name: 'User',
                properties: const [],
                context: context,
              ),
            ),
            (discriminatorValue: null, model: StringModel(context: context)),
            (discriminatorValue: null, model: IntegerModel(context: context)),
          },
          context: context,
        );

        final klass = generator.generateClass(model);

        expect(klass.name, 'AnonymousChoices');
        final defaultCtor = klass.constructors.firstWhere(
          (c) => c.name == null,
        );
        expect(defaultCtor.constant, isTrue);

        final fieldNames = klass.fields.map((f) => f.name).toList();
        expect(fieldNames, containsAll(['user', 'string', 'int']));

        final userField = klass.fields.firstWhere((f) => f.name == 'user');
        expect(userField.type?.accept(emitter).toString(), 'User?');
        expect(userField.modifier, FieldModifier.final$);

        final stringField = klass.fields.firstWhere((f) => f.name == 'string');
        expect(stringField.type?.accept(emitter).toString(), 'String?');
        expect(stringField.modifier, FieldModifier.final$);

        final intField = klass.fields.firstWhere((f) => f.name == 'int');
        expect(intField.type?.accept(emitter).toString(), 'int?');
        expect(intField.modifier, FieldModifier.final$);

        final ctor = klass.constructors.first;
        final ctorParams = ctor.optionalParameters.map((p) => p.name).toList();
        expect(ctorParams, containsAll(['user', 'string', 'int']));
      },
    );

    test(
      'generates AnyOf class with enum, date, dateTime, bool, decimal fields',
      () {
        final enumModel = EnumModel<String>(
          isDeprecated: false,
          name: 'Status',
          values: {
            const EnumEntry(value: 'active'),
            const EnumEntry(value: 'inactive'),
          },
          isNullable: false,
          context: context,
        );

        final model = AnyOfModel(
          isDeprecated: false,
          name: 'VariousTypes',
          models: {
            (discriminatorValue: null, model: enumModel),
            (discriminatorValue: null, model: DateModel(context: context)),
            (discriminatorValue: null, model: DateTimeModel(context: context)),
            (discriminatorValue: null, model: BooleanModel(context: context)),
            (discriminatorValue: null, model: DecimalModel(context: context)),
          },
          context: context,
        );

        final klass = generator.generateClass(model);

        expect(klass.name, 'VariousTypes');
        final defaultCtor = klass.constructors.firstWhere(
          (c) => c.name == null,
        );
        expect(defaultCtor.constant, isTrue);

        final fieldNames = klass.fields.map((f) => f.name).toList();
        expect(
          fieldNames,
          containsAll(['status', 'date', 'dateTime', 'bool', 'bigDecimal']),
        );

        expect(
          klass.fields
              .firstWhere((f) => f.name == 'status')
              .type
              ?.accept(emitter)
              .toString(),
          'Status?',
        );
        expect(
          klass.fields
              .firstWhere((f) => f.name == 'date')
              .type
              ?.accept(emitter)
              .toString(),
          'Date?',
        );
        expect(
          klass.fields
              .firstWhere((f) => f.name == 'dateTime')
              .type
              ?.accept(emitter)
              .toString(),
          'DateTime?',
        );
        expect(
          klass.fields
              .firstWhere((f) => f.name == 'bool')
              .type
              ?.accept(emitter)
              .toString(),
          'bool?',
        );
        expect(
          klass.fields
              .firstWhere((f) => f.name == 'bigDecimal')
              .type
              ?.accept(emitter)
              .toString(),
          'BigDecimal?',
        );

        expect(
          klass.fields.every((f) => f.modifier == FieldModifier.final$),
          isTrue,
        );

        final ctor = klass.constructors.first;
        final ctorParams = ctor.optionalParameters.map((p) => p.name).toList();
        expect(
          ctorParams,
          containsAll(['status', 'date', 'dateTime', 'bool', 'bigDecimal']),
        );
        expect(ctor.optionalParameters.every((p) => p.named), isTrue);
        expect(ctor.optionalParameters.every((p) => !p.required), isTrue);
      },
    );
  });

  group('equals, hashCode, copyWith', () {
    test('generates equals and hashCode methods that compare all fields', () {
      final model = AnyOfModel(
        isDeprecated: false,
        name: 'ValueChoice',
        models: {
          (discriminatorValue: null, model: StringModel(context: context)),
          (discriminatorValue: null, model: IntegerModel(context: context)),
        },
        context: context,
      );

      final klass = generator.generateClass(model);

      // equals method
      final equalsMethod = klass.methods.firstWhere(
        (m) => m.name == 'operator ==',
      );
      expect(equalsMethod.returns?.accept(emitter).toString(), 'bool');

      // hashCode getter
      final hashGetter = klass.methods.firstWhere((m) => m.name == 'hashCode');
      expect(hashGetter.returns?.accept(emitter).toString(), 'int');
      final generated = format(klass.accept(emitter).toString());

      const expectedEquals = '''
        @override
        bool operator ==(Object other) {
          if (identical(this, other)) return true;
          return other is ValueChoice &&
            other.int == int &&
            other.string == string;
        }
      ''';

      const expectedHash = '''
        @override
        int get hashCode {
          return Object.hashAll([int, string]);
        }
      ''';

      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedEquals)),
      );
      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedHash)),
      );
    });

    test(
      'generates copyWith getter returning interface type',
      () {
        final model = AnyOfModel(
          isDeprecated: false,
          name: 'ValueChoice',
          models: {
            (discriminatorValue: null, model: StringModel(context: context)),
            (discriminatorValue: null, model: IntegerModel(context: context)),
          },
          context: context,
        );

        final klass = generator.generateClass(model);

        final copyWith = klass.methods.firstWhere((m) => m.name == 'copyWith');
        expect(copyWith.type, MethodType.getter);
        expect(
          copyWith.returns?.accept(emitter).toString(),
          r'$$ValueChoiceCopyWith<ValueChoice>',
        );
      },
    );
  });

  group('currentEncodingShape with multiple fields of same shape', () {
    final format = DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    ).format;

    test('anyOf with multiple primitives returns simple shape', () {
      final model = AnyOfModel(
        isDeprecated: false,
        name: 'StringOrInt',
        models: {
          (discriminatorValue: null, model: StringModel(context: context)),
          (discriminatorValue: null, model: IntegerModel(context: context)),
        },
        context: context,
      );

      final klass = generator.generateClass(model);
      final generated = format(klass.accept(emitter).toString());

      const expectedGetter = '''
        EncodingShape get currentEncodingShape {
          final shapes = <EncodingShape>{};
          if (int != null) {
            shapes.add(EncodingShape.simple);
          }
          if (string != null) {
            shapes.add(EncodingShape.simple);
          }
          if (shapes.isEmpty) {
            throw StateError('At least one field must be non-null in anyOf');
          }
          if (shapes.length > 1) return EncodingShape.mixed;
          return shapes.first;
        }
      ''';

      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedGetter)),
      );
    });

    test('anyOf with multiple complex types returns complex shape', () {
      final classA = ClassModel(
        isDeprecated: false,
        name: 'UserProfile',
        properties: const [],
        context: context,
      );
      final classB = ClassModel(
        isDeprecated: false,
        name: 'AdminProfile',
        properties: const [],
        context: context,
      );

      final model = AnyOfModel(
        isDeprecated: false,
        name: 'Profile',
        models: {
          (discriminatorValue: null, model: classA),
          (discriminatorValue: null, model: classB),
        },
        context: context,
      );

      final klass = generator.generateClass(model);
      final generated = format(klass.accept(emitter).toString());

      const expectedGetter = '''
        EncodingShape get currentEncodingShape {
          final shapes = <EncodingShape>{};
          if (adminProfile != null) {
            shapes.add(adminProfile!.currentEncodingShape);
          }
          if (userProfile != null) {
            shapes.add(userProfile!.currentEncodingShape);
          }
          if (shapes.isEmpty) {
            throw StateError('At least one field must be non-null in anyOf');
          }
          if (shapes.length > 1) return EncodingShape.mixed;
          return shapes.first;
        }
      ''';

      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedGetter)),
      );
    });

    test('anyOf with primitive and complex type returns mixed shape', () {
      final classModel = ClassModel(
        isDeprecated: false,
        name: 'Data',
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
      );

      final model = AnyOfModel(
        isDeprecated: false,
        name: 'FlexibleData',
        models: {
          (discriminatorValue: null, model: StringModel(context: context)),
          (discriminatorValue: null, model: classModel),
        },
        context: context,
      );

      final klass = generator.generateClass(model);
      final generated = format(klass.accept(emitter).toString());

      const expectedGetter = '''
        EncodingShape get currentEncodingShape {
          final shapes = <EncodingShape>{};
          if (data != null) {
            shapes.add(data!.currentEncodingShape);
          }
          if (string != null) {
            shapes.add(EncodingShape.simple);
          }
          if (shapes.isEmpty) {
            throw StateError('At least one field must be non-null in anyOf');
          }
          if (shapes.length > 1) return EncodingShape.mixed;
          return shapes.first;
        }
      ''';

      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedGetter)),
      );
    });
  });

  group('AnyOfGenerator discriminator handling', () {
    test(
      'anyOf with discriminator includes discriminator in toSimple for complex',
      () {
        final personModel = ClassModel(
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

        final companyModel = ClassModel(
          isDeprecated: false,
          name: 'Company',
          properties: [
            Property(
              name: 'companyName',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          context: context,
        );

        final model = AnyOfModel(
          isDeprecated: false,
          name: 'EntityChoice',
          models: {
            (
              discriminatorValue: 'person',
              model: personModel,
            ),
            (
              discriminatorValue: 'company',
              model: companyModel,
            ),
          },
          discriminator: 'type',
          context: context,
        );

        final klass = generator.generateClass(model);
        final toSimpleMethod = klass.methods.firstWhere(
          (m) => m.name == 'toSimple',
        );
        expect(toSimpleMethod.name, 'toSimple');
        expect(toSimpleMethod.returns?.accept(emitter).toString(), 'String');
        expect(toSimpleMethod.optionalParameters.length, 2);
        expect(
          toSimpleMethod.optionalParameters.any((p) => p.name == 'explode'),
          isTrue,
        );
        expect(
          toSimpleMethod.optionalParameters.any((p) => p.name == 'allowEmpty'),
          isTrue,
        );

        final format = DartFormatter(
          languageVersion: DartFormatter.latestLanguageVersion,
        ).format;
        final generated = format(toSimpleMethod.accept(emitter).toString());

        const expectedMethod = '''
String toSimple({required bool explode, required bool allowEmpty}) {
  final mapValues = <Map<String, String>>[];
  String? discriminatorValue;
  if (company != null) {
    final companySimple = company!.parameterProperties(allowEmpty: allowEmpty);
    mapValues.add(companySimple);
    discriminatorValue ??= r'company';
  }
  if (person != null) {
    final personSimple = person!.parameterProperties(allowEmpty: allowEmpty);
    mapValues.add(personSimple);
    discriminatorValue ??= r'person';
  }
  final map = <String, String>{};
  for (final m in mapValues) {
    map.addAll(m);
  }
  if (discriminatorValue != null) {
    map.putIfAbsent('type', () => discriminatorValue);
  }
  return map.toSimple(
    explode: explode,
    allowEmpty: allowEmpty,
    alreadyEncoded: true,
  );
}
      ''';

        expect(generated.trim(), expectedMethod.trim());
      },
    );

    test(
      'anyOf with discriminator includes discriminator in toForm for complex',
      () {
        final personModel = ClassModel(
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

        final companyModel = ClassModel(
          isDeprecated: false,
          name: 'Company',
          properties: [
            Property(
              name: 'companyName',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          context: context,
        );

        final model = AnyOfModel(
          isDeprecated: false,
          name: 'EntityChoice',
          models: {
            (
              discriminatorValue: 'person',
              model: personModel,
            ),
            (
              discriminatorValue: 'company',
              model: companyModel,
            ),
          },
          discriminator: 'type',
          context: context,
        );

        final klass = generator.generateClass(model);

        // Test method exists and has correct signature
        final toFormMethod = klass.methods.firstWhere(
          (m) => m.name == 'toForm',
        );
        expect(toFormMethod.name, 'toForm');
        expect(toFormMethod.returns?.accept(emitter).toString(), 'String');
        expect(toFormMethod.optionalParameters.length, 2);
        expect(
          toFormMethod.optionalParameters.any((p) => p.name == 'explode'),
          isTrue,
        );
        expect(
          toFormMethod.optionalParameters.any((p) => p.name == 'allowEmpty'),
          isTrue,
        );

        final format = DartFormatter(
          languageVersion: DartFormatter.latestLanguageVersion,
        ).format;
        final generated = format(toFormMethod.accept(emitter).toString());

        const expectedMethod = '''
String toForm({required bool explode, required bool allowEmpty}) {
  final mapValues = <Map<String, String>>[];
  String? discriminatorValue;
  if (company != null) {
    final companyForm = company!.parameterProperties(allowEmpty: allowEmpty);
    mapValues.add(companyForm);
    discriminatorValue ??= r'company';
  }
  if (person != null) {
    final personForm = person!.parameterProperties(allowEmpty: allowEmpty);
    mapValues.add(personForm);
    discriminatorValue ??= r'person';
  }
  final map = <String, String>{};
  for (final m in mapValues) {
    map.addAll(m);
  }
  if (discriminatorValue != null) {
    map.putIfAbsent('type', () => discriminatorValue);
  }
  return map.toForm(
    explode: explode,
    allowEmpty: allowEmpty,
    alreadyEncoded: true,
  );
}
      ''';

        expect(generated.trim(), expectedMethod.trim());
      },
    );

    test(
      'anyOf with discriminator does NOT include discriminator for simple only',
      () {
        final model = AnyOfModel(
          isDeprecated: false,
          name: 'SimpleChoice',
          models: {
            (
              discriminatorValue: 'string',
              model: StringModel(context: context),
            ),
            (discriminatorValue: 'int', model: IntegerModel(context: context)),
          },
          discriminator: 'type',
          context: context,
        );

        final klass = generator.generateClass(model);
        final toSimpleMethod = klass.methods.firstWhere(
          (m) => m.name == 'toSimple',
        );
        expect(toSimpleMethod.name, 'toSimple');
        expect(toSimpleMethod.returns?.accept(emitter).toString(), 'String');
        expect(toSimpleMethod.optionalParameters.length, 2);

        final format = DartFormatter(
          languageVersion: DartFormatter.latestLanguageVersion,
        ).format;
        final generated = format(toSimpleMethod.accept(emitter).toString());

        const expectedMethod = '''
String toSimple({required bool explode, required bool allowEmpty}) {
  final values = <String>{};
  if (int != null) {
    final intSimple = int!.toSimple(explode: explode, allowEmpty: allowEmpty);
    values.add(intSimple);
  }
  if (string != null) {
    final stringSimple = string!.toSimple(
      explode: explode,
      allowEmpty: allowEmpty,
    );
    values.add(stringSimple);
  }
  if (values.isEmpty) return '';
  if (values.length > 1) {
    throw EncodingException(
      'Ambiguous anyOf simple encoding for SimpleChoice: multiple values provided, anyOf requires exactly one value',
    );
  }
  return values.first;
}
      ''';

        expect(generated.trim(), expectedMethod.trim());
      },
    );

    test(
      'anyOf with discriminator handles mixed simple and complex correctly',
      () {
        final classModel = ClassModel(
          isDeprecated: false,
          name: 'Data',
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
        );

        final model = AnyOfModel(
          isDeprecated: false,
          name: 'MixedChoice',
          models: {
            (
              discriminatorValue: 'string',
              model: StringModel(context: context),
            ),
            (discriminatorValue: 'data', model: classModel),
          },
          discriminator: 'type',
          context: context,
        );

        final klass = generator.generateClass(model);
        final toSimpleMethod = klass.methods.firstWhere(
          (m) => m.name == 'toSimple',
        );
        expect(toSimpleMethod.name, 'toSimple');
        expect(toSimpleMethod.returns?.accept(emitter).toString(), 'String');

        final format = DartFormatter(
          languageVersion: DartFormatter.latestLanguageVersion,
        ).format;
        final generated = format(toSimpleMethod.accept(emitter).toString());

        const expectedMethod = '''
String toSimple({required bool explode, required bool allowEmpty}) {
  final values = <String>{};
  final mapValues = <Map<String, String>>[];
  String? discriminatorValue;
  if (data != null) {
    final dataSimple = data!.parameterProperties(allowEmpty: allowEmpty);
    mapValues.add(dataSimple);
    discriminatorValue ??= r'data';
  }
  if (string != null) {
    final stringSimple = string!.toSimple(
      explode: explode,
      allowEmpty: allowEmpty,
    );
    values.add(stringSimple);
  }
  if (values.isEmpty && mapValues.isEmpty) return '';
  if (mapValues.isNotEmpty && values.isNotEmpty) {
    throw EncodingException(
      'Ambiguous anyOf simple encoding for MixedChoice: mixing simple and complex values',
    );
  }
  if (values.isNotEmpty) {
    if (values.length > 1) {
      throw EncodingException(
        'Ambiguous anyOf simple encoding for MixedChoice: multiple values provided, anyOf requires exactly one value',
      );
    }
    return values.first;
  } else {
    final map = <String, String>{};
    for (final m in mapValues) {
      map.addAll(m);
    }
    if (discriminatorValue != null) {
      map.putIfAbsent('type', () => discriminatorValue);
    }
    return map.toSimple(
      explode: explode,
      allowEmpty: allowEmpty,
      alreadyEncoded: true,
    );
  }
}
      ''';

        expect(generated.trim(), expectedMethod.trim());
      },
    );
  });

  group('parameterProperties', () {
    test('method exists with correct signature for anyOf', () {
      final model = AnyOfModel(
        isDeprecated: false,
        name: 'FlexibleChoice',
        models: {
          (
            discriminatorValue: 'user',
            model: ClassModel(
              isDeprecated: false,
              name: 'User',
              properties: const [],
              context: context,
            ),
          ),
          (
            discriminatorValue: 'admin',
            model: ClassModel(
              isDeprecated: false,
              name: 'Admin',
              properties: const [],
              context: context,
            ),
          ),
        },
        context: context,
      );

      final klass = generator.generateClass(model);
      final method = klass.methods.firstWhere(
        (m) => m.name == 'parameterProperties',
        orElse: () => throw StateError('parameterProperties method not found'),
      );

      expect(method.name, 'parameterProperties');
      expect(
        method.returns?.accept(emitter).toString().replaceAll(' ', ''),
        'Map<String,String>',
      );
      expect(method.optionalParameters.length, 2);

      final allowEmptyParam = method.optionalParameters.firstWhere(
        (p) => p.name == 'allowEmpty',
      );
      expect(allowEmptyParam.named, isTrue);
      expect(allowEmptyParam.required, isFalse);
      expect(
        allowEmptyParam.defaultTo?.accept(emitter).toString(),
        'true',
      );

      final allowListsParam = method.optionalParameters.firstWhere(
        (p) => p.name == 'allowLists',
      );
      expect(allowListsParam.named, isTrue);
      expect(allowListsParam.required, isFalse);
    });

    test('generates complete method for single complex variant', () {
      final userModel = ClassModel(
        isDeprecated: false,
        name: 'User',
        properties: const [],
        context: context,
      );

      final model = AnyOfModel(
        isDeprecated: false,
        name: 'FlexibleChoice',
        models: {
          (discriminatorValue: 'user', model: userModel),
        },
        context: context,
      );

      final klass = generator.generateClass(model);
      final method = klass.methods.firstWhere(
        (m) => m.name == 'parameterProperties',
      );

      final generated = format(method.accept(emitter).toString());

      const expectedMethod = r'''
Map<String, String> parameterProperties({ bool allowEmpty = true, bool allowLists = true, }) {
  final _$mapValues = <Map<String, String>>[];
  if (user != null) {
    _$mapValues.add( user!.parameterProperties(allowEmpty: allowEmpty, allowLists: allowLists), );
  }
  final _$map = <String, String>{};
  for (final m in _$mapValues) {
    _$map.addAll(m);
  }
  return _$map;
}
''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(expectedMethod),
      );
    });

    test('generates complete method for multiple complex variants', () {
      final user = ClassModel(
        isDeprecated: false,
        name: 'User',
        properties: const [],
        context: context,
      );

      final admin = ClassModel(
        isDeprecated: false,
        name: 'Admin',
        properties: const [],
        context: context,
      );

      final model = AnyOfModel(
        isDeprecated: false,
        name: 'MultiChoice',
        models: {
          (discriminatorValue: 'user', model: user),
          (discriminatorValue: 'admin', model: admin),
        },
        context: context,
      );

      final klass = generator.generateClass(model);
      final method = klass.methods.firstWhere(
        (m) => m.name == 'parameterProperties',
      );

      final generated = format(method.accept(emitter).toString());

      const expectedMethod = r'''
Map<String, String> parameterProperties({ bool allowEmpty = true, bool allowLists = true, }) {
  final _$mapValues = <Map<String, String>>[];
  if (admin != null) {
    _$mapValues.add( admin!.parameterProperties( allowEmpty: allowEmpty, allowLists: allowLists, ), );
  }
  if (user != null) {
    _$mapValues.add( user!.parameterProperties(allowEmpty: allowEmpty, allowLists: allowLists), );
  }
  final _$map = <String, String>{};
  for (final m in _$mapValues) {
    _$map.addAll(m);
  }
  return _$map;
}
''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(expectedMethod),
      );
    });

    test('generates complete method with discriminator', () {
      final classModel = ClassModel(
        isDeprecated: false,
        name: 'Data',
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
      );

      final model = AnyOfModel(
        isDeprecated: false,
        name: 'DiscriminatedChoice',
        models: {
          (
            discriminatorValue: 'data',
            model: classModel,
          ),
        },
        discriminator: 'type',
        context: context,
      );

      final klass = generator.generateClass(model);
      final method = klass.methods.firstWhere(
        (m) => m.name == 'parameterProperties',
      );

      final generated = format(method.accept(emitter).toString());

      const expectedMethod = r'''
Map<String, String> parameterProperties({ bool allowEmpty = true, bool allowLists = true, }) {
  final _$mapValues = <Map<String, String>>[];
  String? _$discriminatorValue;
  if (data != null) {
    _$mapValues.add( data!.parameterProperties(allowEmpty: allowEmpty, allowLists: allowLists), );
    _$discriminatorValue ??= r'data';
  }
  final _$map = <String, String>{};
  for (final m in _$mapValues) {
    _$map.addAll(m);
  }
  if (_$discriminatorValue != null) {
    _$map.putIfAbsent('type', () => _$discriminatorValue);
  }
  return _$map;
}
''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(expectedMethod),
      );
    });

    test('generates complete method for anyOf with dynamic encoding shape', () {
      final anyOfModel = AnyOfModel(
        isDeprecated: false,
        name: 'InnerChoice',
        models: {
          (discriminatorValue: 'string', model: StringModel(context: context)),
          (
            discriminatorValue: 'data',
            model: ClassModel(
              isDeprecated: false,
              name: 'Data',
              properties: const [],
              context: context,
            ),
          ),
        },
        context: context,
      );

      final model = AnyOfModel(
        isDeprecated: false,
        name: 'MixedChoice',
        models: {
          (discriminatorValue: 'inner', model: anyOfModel),
        },
        context: context,
      );

      final klass = generator.generateClass(model);
      final method = klass.methods.firstWhere(
        (m) => m.name == 'parameterProperties',
      );

      final generated = format(method.accept(emitter).toString());

      const expectedMethod = r'''
Map<String, String> parameterProperties({ bool allowEmpty = true, bool allowLists = true, }) {
  final _$mapValues = <Map<String, String>>[];
  if (innerChoice != null) {
    switch (innerChoice!.currentEncodingShape) {
      case EncodingShape.simple:
        throw EncodingException(
          'Cannot encode simple type to map in parameterProperties',
        );
      case EncodingShape.complex:
        _$mapValues.add(
          innerChoice!.parameterProperties( allowEmpty: allowEmpty, allowLists: allowLists, ),
        );
        break;
      case EncodingShape.mixed:
        throw EncodingException(
          'Cannot encode field with mixed encoding shape',
        );
    }
  }
  final _$map = <String, String>{};
  for (final m in _$mapValues) {
    _$map.addAll(m);
  }
  return _$map;
}
''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(expectedMethod),
      );
    });

    test(
      'generates complete method for anyOf with dynamic encoding shape '
      'and discriminator',
      () {
        final anyOfModel = AnyOfModel(
          isDeprecated: false,
          name: 'InnerChoice',
          models: {
            (
              discriminatorValue: 'string',
              model: StringModel(context: context),
            ),
            (
              discriminatorValue: 'data',
              model: ClassModel(
                isDeprecated: false,
                name: 'Data',
                properties: const [],
                context: context,
              ),
            ),
          },
          context: context,
        );

        final model = AnyOfModel(
          isDeprecated: false,
          name: 'MixedChoice',
          models: {
            (discriminatorValue: 'inner', model: anyOfModel),
          },
          discriminator: 'type',
          context: context,
        );

        final klass = generator.generateClass(model);
        final method = klass.methods.firstWhere(
          (m) => m.name == 'parameterProperties',
        );

        final format = DartFormatter(
          languageVersion: DartFormatter.latestLanguageVersion,
        ).format;
        final generated = format(method.accept(emitter).toString());

        const expectedMethod = r'''
Map<String, String> parameterProperties({ bool allowEmpty = true, bool allowLists = true, }) {
  final _$mapValues = <Map<String, String>>[];
  String? _$discriminatorValue;
  if (innerChoice != null) {
    switch (innerChoice!.currentEncodingShape) {
      case EncodingShape.simple:
        throw EncodingException(
          'Cannot encode simple type to map in parameterProperties',
        );
      case EncodingShape.complex:
        _$mapValues.add(
          innerChoice!.parameterProperties( allowEmpty: allowEmpty, allowLists: allowLists, ),
        );
        _$discriminatorValue ??= r'inner';
        break;
      case EncodingShape.mixed:
        throw EncodingException(
          'Cannot encode field with mixed encoding shape',
        );
    }
  }
  final _$map = <String, String>{};
  for (final m in _$mapValues) {
    _$map.addAll(m);
  }
  if (_$discriminatorValue != null) {
    _$map.putIfAbsent('type', () => _$discriminatorValue);
  }
  return _$map;
}
''';

        expect(
          collapseWhitespace(generated),
          collapseWhitespace(expectedMethod),
        );
      },
    );

    test(
      'generates complete method for anyOf with simple composite and '
      'complex class',
      () {
        final anyOfModel = AnyOfModel(
          isDeprecated: false,
          name: 'InnerChoice',
          models: {
            (
              discriminatorValue: 'string',
              model: StringModel(context: context),
            ),
            (
              discriminatorValue: 'number',
              model: IntegerModel(context: context),
            ),
          },
          context: context,
        );

        final classModel = ClassModel(
          isDeprecated: false,
          name: 'ComplexData',
          properties: const [],
          context: context,
        );

        final model = AnyOfModel(
          isDeprecated: false,
          name: 'MixedChoice',
          models: {
            (discriminatorValue: 'inner', model: anyOfModel),
            (discriminatorValue: 'complex', model: classModel),
          },
          context: context,
        );

        final klass = generator.generateClass(model);
        final method = klass.methods.firstWhere(
          (m) => m.name == 'parameterProperties',
        );

        final format = DartFormatter(
          languageVersion: DartFormatter.latestLanguageVersion,
        ).format;
        final generated = format(method.accept(emitter).toString());

        const expectedMethod = r'''
Map<String, String> parameterProperties({ bool allowEmpty = true, bool allowLists = true, }) {
  final _$mapValues = <Map<String, String>>[];
  if (complexData != null) {
    _$mapValues.add( complexData!.parameterProperties( allowEmpty: allowEmpty, allowLists: allowLists, ), );
  }
  if (innerChoice != null) {
    throw EncodingException(
      'Cannot encode anyOf with simple type to map in parameterProperties',
    );
  }
  final _$map = <String, String>{};
  for (final m in _$mapValues) {
    _$map.addAll(m);
  }
  return _$map;
}
''';

        expect(
          collapseWhitespace(generated),
          collapseWhitespace(expectedMethod),
        );
      },
    );

    test(
      'generates complete method for anyOf with mixed simple and complex '
      'at top level',
      () {
        final classModel = ClassModel(
          isDeprecated: false,
          name: 'ComplexData',
          properties: const [],
          context: context,
        );

        final model = AnyOfModel(
          isDeprecated: false,
          name: 'MixedTopLevel',
          models: {
            (
              discriminatorValue: 'string',
              model: StringModel(context: context),
            ),
            (discriminatorValue: 'complex', model: classModel),
          },
          context: context,
        );

        final klass = generator.generateClass(model);
        final method = klass.methods.firstWhere(
          (m) => m.name == 'parameterProperties',
        );

        final format = DartFormatter(
          languageVersion: DartFormatter.latestLanguageVersion,
        ).format;
        final generated = format(method.accept(emitter).toString());

        const expectedMethod = r'''
Map<String, String> parameterProperties({ bool allowEmpty = true, bool allowLists = true, }) {
  final _$mapValues = <Map<String, String>>[];
  if (complexData != null) {
    _$mapValues.add( complexData!.parameterProperties( allowEmpty: allowEmpty, allowLists: allowLists, ), );
  }
  if (string != null) {
    throw EncodingException(
      'Cannot encode anyOf with simple type to map in parameterProperties',
    );
  }
  final _$map = <String, String>{};
  for (final m in _$mapValues) {
    _$map.addAll(m);
  }
  return _$map;
}
''';

        expect(
          collapseWhitespace(generated),
          collapseWhitespace(expectedMethod),
        );
      },
    );

    test('generates complete method for anyOf with only simple types', () {
      final model = AnyOfModel(
        isDeprecated: false,
        name: 'SimpleChoice',
        models: {
          (discriminatorValue: 'string', model: StringModel(context: context)),
          (discriminatorValue: 'number', model: IntegerModel(context: context)),
        },
        context: context,
      );

      final klass = generator.generateClass(model);
      final method = klass.methods.firstWhere(
        (m) => m.name == 'parameterProperties',
      );

      final generated = format(method.accept(emitter).toString());

      const expectedMethod = '''
Map<String, String> parameterProperties({ bool allowEmpty = true, bool allowLists = true, }) {
  throw EncodingException(
    'parameterProperties not supported for SimpleChoice: contains only simple types',
  );
}
''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(expectedMethod),
      );
    });

    test('passes allowLists to nested complex types', () {
      final user = ClassModel(
        isDeprecated: false,
        name: 'User',
        properties: const [],
        context: context,
      );
      final admin = ClassModel(
        isDeprecated: false,
        name: 'Admin',
        properties: const [],
        context: context,
      );

      final model = AnyOfModel(
        isDeprecated: false,
        name: 'FlexibleChoice',
        models: {
          (discriminatorValue: 'user', model: user),
          (discriminatorValue: 'admin', model: admin),
        },
        context: context,
      );

      final klass = generator.generateClass(model);
      final method = klass.methods.firstWhere(
        (m) => m.name == 'parameterProperties',
      );

      final generated = format(method.accept(emitter).toString());

      const expectedMethod = r'''
Map<String, String> parameterProperties({
  bool allowEmpty = true,
  bool allowLists = true,
}) {
  final _$mapValues = <Map<String, String>>[];
  if (admin != null) {
    _$mapValues.add(
      admin!.parameterProperties(
        allowEmpty: allowEmpty,
        allowLists: allowLists,
      ),
    );
  }
  if (user != null) {
    _$mapValues.add(
      user!.parameterProperties(allowEmpty: allowEmpty, allowLists: allowLists),
    );
  }
  final _$map = <String, String>{};
  for (final m in _$mapValues) {
    _$map.addAll(m);
  }
  return _$map;
}
''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(expectedMethod),
      );
    });

    test('throws when anyOf contains list model', () {
      final model = AnyOfModel(
        isDeprecated: false,
        name: 'ChoiceWithList',
        models: {
          (
            discriminatorValue: 'list',
            model: ListModel(
              content: IntegerModel(context: context),
              context: context,
            ),
          ),
        },
        context: context,
      );

      final klass = generator.generateClass(model);
      final method = klass.methods.firstWhere(
        (m) => m.name == 'parameterProperties',
      );

      final generated = format(method.accept(emitter).toString());

      const expectedMethod = r'''
Map<String, String> parameterProperties({
  bool allowEmpty = true,
  bool allowLists = true,
}) {
  final _$mapValues = <Map<String, String>>[];
  if (list != null) {
    if (!allowLists) {
      throw EncodingException('Lists are not supported in this encoding style');
    }
    throw EncodingException('Lists are not supported in parameterProperties');
  }
  final _$map = <String, String>{};
  for (final m in _$mapValues) {
    _$map.addAll(m);
  }
  return _$map;
}
''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(expectedMethod),
      );
    });

    test('passes allowLists to nested anyOf with mixed encoding', () {
      final innerAnyOf = AnyOfModel(
        isDeprecated: false,
        name: 'InnerChoice',
        models: {
          (
            discriminatorValue: 'data',
            model: ClassModel(
              isDeprecated: false,
              name: 'Data',
              properties: const [],
              context: context,
            ),
          ),
          (
            discriminatorValue: 'text',
            model: StringModel(context: context),
          ),
        },
        context: context,
      );

      final model = AnyOfModel(
        isDeprecated: false,
        name: 'OuterChoice',
        models: {
          (discriminatorValue: 'inner', model: innerAnyOf),
        },
        context: context,
      );

      final klass = generator.generateClass(model);
      final method = klass.methods.firstWhere(
        (m) => m.name == 'parameterProperties',
      );

      final generated = format(method.accept(emitter).toString());

      const expectedMethod = r'''
Map<String, String> parameterProperties({
  bool allowEmpty = true,
  bool allowLists = true,
}) {
  final _$mapValues = <Map<String, String>>[];
  if (innerChoice != null) {
    switch (innerChoice!.currentEncodingShape) {
      case EncodingShape.simple:
        throw EncodingException(
          'Cannot encode simple type to map in parameterProperties',
        );
      case EncodingShape.complex:
        _$mapValues.add(
          innerChoice!.parameterProperties(
            allowEmpty: allowEmpty,
            allowLists: allowLists,
          ),
        );
        break;
      case EncodingShape.mixed:
        throw EncodingException(
          'Cannot encode field with mixed encoding shape',
        );
    }
  }
  final _$map = <String, String>{};
  for (final m in _$mapValues) {
    _$map.addAll(m);
  }
  return _$map;
}
''';

      expect(
        collapseWhitespace(generated),
        collapseWhitespace(expectedMethod),
      );
    });
  });

  group('AnyOfGenerator with nested composite models', () {
    test('handles AllOfModel with simple encoding shape correctly', () {
      final allOfModel = AllOfModel(
        isDeprecated: false,
        name: 'SimpleAllOf',
        models: {
          StringModel(context: context),
          EnumModel<String>(
            isDeprecated: false,
            values: {
              const EnumEntry(value: 'value1'),
              const EnumEntry(value: 'value2'),
            },
            isNullable: false,
            context: context,
          ),
        },
        context: context,
      );

      final model = AnyOfModel(
        isDeprecated: false,
        name: 'TestAnyOf',
        models: {
          (discriminatorValue: 'simple', model: allOfModel),
          (discriminatorValue: 'string', model: StringModel(context: context)),
        },
        discriminator: 'type',
        context: context,
      );

      final klass = generator.generateClass(model);
      final generated = format(klass.accept(emitter).toString());

      expect(allOfModel.encodingShape, EncodingShape.simple);

      const expectedGetter = '''
        EncodingShape get currentEncodingShape {
          final shapes = <EncodingShape>{};
          if (simpleAllOf != null) {
            shapes.add(EncodingShape.simple);
          }
          if (string != null) {
            shapes.add(EncodingShape.simple);
          }
          if (shapes.isEmpty) {
            throw StateError('At least one field must be non-null in anyOf');
          }
          if (shapes.length > 1) return EncodingShape.mixed;
          return shapes.first;
        }
      ''';

      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedGetter)),
      );
    });

    test('handles AllOfModel with complex encoding shape correctly', () {
      final allOfModel = AllOfModel(
        isDeprecated: false,
        name: 'ComplexAllOf',
        models: {
          ClassModel(
            isDeprecated: false,
            name: 'Model1',
            properties: const [],
            context: context,
          ),
          ClassModel(
            isDeprecated: false,
            name: 'Model2',
            properties: const [],
            context: context,
          ),
        },
        context: context,
      );

      final model = AnyOfModel(
        isDeprecated: false,
        name: 'TestAnyOf',
        models: {
          (discriminatorValue: 'complex', model: allOfModel),
          (discriminatorValue: 'string', model: StringModel(context: context)),
        },
        discriminator: 'type',
        context: context,
      );

      final klass = generator.generateClass(model);
      final generated = format(klass.accept(emitter).toString());

      expect(allOfModel.encodingShape, EncodingShape.complex);

      const expectedGetter = '''
        EncodingShape get currentEncodingShape {
          final shapes = <EncodingShape>{};
          if (complexAllOf != null) {
            shapes.add(complexAllOf!.currentEncodingShape);
          }
          if (string != null) {
            shapes.add(EncodingShape.simple);
          }
          if (shapes.isEmpty) {
            throw StateError('At least one field must be non-null in anyOf');
          }
          if (shapes.length > 1) return EncodingShape.mixed;
          return shapes.first;
        }
      ''';

      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedGetter)),
      );
    });

    test('handles AllOfModel with mixed encoding shape correctly', () {
      final allOfModel = AllOfModel(
        isDeprecated: false,
        name: 'MixedAllOf',
        models: {
          StringModel(context: context),
          ClassModel(
            isDeprecated: false,
            name: 'Model1',
            properties: const [],
            context: context,
          ),
        },
        context: context,
      );

      final model = AnyOfModel(
        isDeprecated: false,
        name: 'TestAnyOf',
        models: {
          (discriminatorValue: 'mixed', model: allOfModel),
          (discriminatorValue: 'string', model: StringModel(context: context)),
        },
        discriminator: 'type',
        context: context,
      );

      final klass = generator.generateClass(model);
      final generated = format(klass.accept(emitter).toString());

      expect(allOfModel.encodingShape, EncodingShape.mixed);

      const expectedGetter = '''
        EncodingShape get currentEncodingShape {
          final shapes = <EncodingShape>{};
          if (mixedAllOf != null) {
            shapes.add(mixedAllOf!.currentEncodingShape);
          }
          if (string != null) {
            shapes.add(EncodingShape.simple);
          }
          if (shapes.isEmpty) {
            throw StateError('At least one field must be non-null in anyOf');
          }
          if (shapes.length > 1) return EncodingShape.mixed;
          return shapes.first;
        }
      ''';

      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedGetter)),
      );
    });

    test('handles OneOfModel with simple encoding shape correctly', () {
      final oneOfModel = OneOfModel(
        isDeprecated: false,
        name: 'SimpleOneOf',
        models: {
          (discriminatorValue: 'str', model: StringModel(context: context)),
          (discriminatorValue: 'int', model: IntegerModel(context: context)),
        },
        discriminator: 'type',
        context: context,
      );

      final model = AnyOfModel(
        isDeprecated: false,
        name: 'TestAnyOf',
        models: {
          (discriminatorValue: 'oneof', model: oneOfModel),
          (discriminatorValue: 'string', model: StringModel(context: context)),
        },
        discriminator: 'type',
        context: context,
      );

      final klass = generator.generateClass(model);
      final generated = format(klass.accept(emitter).toString());

      expect(oneOfModel.encodingShape, EncodingShape.simple);

      const expectedGetter = '''
        EncodingShape get currentEncodingShape {
          final shapes = <EncodingShape>{};
          if (simpleOneOf != null) {
            shapes.add(EncodingShape.simple);
          }
          if (string != null) {
            shapes.add(EncodingShape.simple);
          }
          if (shapes.isEmpty) {
            throw StateError('At least one field must be non-null in anyOf');
          }
          if (shapes.length > 1) return EncodingShape.mixed;
          return shapes.first;
        }
      ''';

      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedGetter)),
      );
    });

    test('handles nested AnyOfModel with complex encoding shape correctly', () {
      final nestedAnyOfModel = AnyOfModel(
        isDeprecated: false,
        name: 'NestedAnyOf',
        models: {
          (
            discriminatorValue: 'class',
            model: ClassModel(
              isDeprecated: false,
              name: 'Model1',
              properties: const [],
              context: context,
            ),
          ),
          (
            discriminatorValue: 'list',
            model: ListModel(
              content: StringModel(context: context),
              context: context,
            ),
          ),
        },
        discriminator: 'type',
        context: context,
      );

      final model = AnyOfModel(
        isDeprecated: false,
        name: 'TestAnyOf',
        models: {
          (discriminatorValue: 'nested', model: nestedAnyOfModel),
          (discriminatorValue: 'string', model: StringModel(context: context)),
        },
        discriminator: 'type',
        context: context,
      );

      final klass = generator.generateClass(model);
      final generated = format(klass.accept(emitter).toString());

      expect(nestedAnyOfModel.encodingShape, EncodingShape.complex);

      const expectedGetter = '''
        EncodingShape get currentEncodingShape {
          final shapes = <EncodingShape>{};
          if (nestedAnyOf != null) {
            shapes.add(nestedAnyOf!.currentEncodingShape);
          }
          if (string != null) {
            shapes.add(EncodingShape.simple);
          }
          if (shapes.isEmpty) {
            throw StateError('At least one field must be non-null in anyOf');
          }
          if (shapes.length > 1) return EncodingShape.mixed;
          return shapes.first;
        }
      ''';

      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedGetter)),
      );
    });
  });
}
