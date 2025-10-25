import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/model/any_of_generator.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';

void main() {
  late AnyOfGenerator generator;
  late NameManager nameManager;
  late NameGenerator nameGenerator;
  late Context context;
  late DartEmitter emitter;

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
        name: 'FlexibleModel',
        models: {
          (discriminatorValue: 'id', model: IntegerModel(context: context)),
          (discriminatorValue: 'name', model: StringModel(context: context)),
          (
            discriminatorValue: 'details',
            model: ClassModel(
              name: 'Details',
              properties: const [],
              context: context,
            ),
          ),
        },
        discriminator: null,
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

    test(
      'generates AnyOf class when discriminatorValue is absent for all entries',
      () {
        final model = AnyOfModel(
          name: 'AnonymousChoices',
          models: {
            (
              discriminatorValue: null,
              model: ClassModel(
                name: 'User',
                properties: const [],
                context: context,
              ),
            ),
            (discriminatorValue: null, model: StringModel(context: context)),
            (discriminatorValue: null, model: IntegerModel(context: context)),
          },
          discriminator: null,
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
          name: 'Status',
          values: const {'active', 'inactive'},
          isNullable: false,
          context: context,
        );

        final model = AnyOfModel(
          name: 'VariousTypes',
          models: {
            (discriminatorValue: null, model: enumModel),
            (discriminatorValue: null, model: DateModel(context: context)),
            (discriminatorValue: null, model: DateTimeModel(context: context)),
            (discriminatorValue: null, model: BooleanModel(context: context)),
            (discriminatorValue: null, model: DecimalModel(context: context)),
          },
          discriminator: null,
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
        name: 'ValueChoice',
        models: {
          (discriminatorValue: null, model: StringModel(context: context)),
          (discriminatorValue: null, model: IntegerModel(context: context)),
        },
        discriminator: null,
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

      final format =
          DartFormatter(
            languageVersion: DartFormatter.latestLanguageVersion,
          ).format;
      final generated = format(klass.accept(emitter).toString());

      const expectedEquals = '''
        @override
        bool operator ==(Object other) {
          if (identical(this, other)) return true;
          return other is ValueChoice &&
            other.string == string &&
            other.int == int;
        }
      ''';

      const expectedHash = '''
        @override
        int get hashCode {
          return Object.hashAll([string, int]);
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
      'generates copyWith method with nullable parameters and field defaults',
      () {
        final model = AnyOfModel(
          name: 'ValueChoice',
          models: {
            (discriminatorValue: null, model: StringModel(context: context)),
            (discriminatorValue: null, model: IntegerModel(context: context)),
          },
          discriminator: null,
          context: context,
        );

        final klass = generator.generateClass(model);

        final copyWith = klass.methods.firstWhere((m) => m.name == 'copyWith');
        expect(copyWith.returns?.accept(emitter).toString(), 'ValueChoice');
        expect(
          copyWith.optionalParameters.map((p) => p.name).toList(),
          containsAll(['string', 'int']),
        );
        expect(
          copyWith.optionalParameters
              .firstWhere((p) => p.name == 'string')
              .type
              ?.accept(emitter)
              .toString(),
          'String?',
        );
        expect(
          copyWith.optionalParameters
              .firstWhere((p) => p.name == 'int')
              .type
              ?.accept(emitter)
              .toString(),
          'int?',
        );

        final format =
            DartFormatter(
              languageVersion: DartFormatter.latestLanguageVersion,
            ).format;
        final generated = format(klass.accept(emitter).toString());

        const expectedCopyWithBody = '''
        ValueChoice copyWith({String? string, int? int}) {
          return ValueChoice(string: string ?? this.string, int: int ?? this.int);
        }
      ''';

        expect(
          collapseWhitespace(generated),
          contains(collapseWhitespace(expectedCopyWithBody)),
        );
      },
    );
  });

  group('currentEncodingShape with multiple fields of same shape', () {
    final format =
        DartFormatter(
          languageVersion: DartFormatter.latestLanguageVersion,
        ).format;

    test('anyOf with multiple primitives returns simple shape', () {
      final model = AnyOfModel(
        name: 'StringOrInt',
        models: {
          (discriminatorValue: null, model: StringModel(context: context)),
          (discriminatorValue: null, model: IntegerModel(context: context)),
        },
        discriminator: null,
        context: context,
      );

      final klass = generator.generateClass(model);
      final generated = format(klass.accept(emitter).toString());

      const expectedGetter = '''
        EncodingShape get currentEncodingShape {
          final shapes = <EncodingShape>{};
          if (string != null) {
            shapes.add(EncodingShape.simple);
          }
          if (int != null) {
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
        name: 'UserProfile',
        properties: const [],
        context: context,
      );
      final classB = ClassModel(
        name: 'AdminProfile',
        properties: const [],
        context: context,
      );

      final model = AnyOfModel(
        name: 'Profile',
        models: {
          (discriminatorValue: null, model: classA),
          (discriminatorValue: null, model: classB),
        },
        discriminator: null,
        context: context,
      );

      final klass = generator.generateClass(model);
      final generated = format(klass.accept(emitter).toString());

      const expectedGetter = '''
        EncodingShape get currentEncodingShape {
          final shapes = <EncodingShape>{};
          if (userProfile != null) {
            shapes.add(userProfile!.currentEncodingShape);
          }
          if (adminProfile != null) {
            shapes.add(adminProfile!.currentEncodingShape);
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
        name: 'FlexibleData',
        models: {
          (discriminatorValue: null, model: StringModel(context: context)),
          (discriminatorValue: null, model: classModel),
        },
        discriminator: null,
        context: context,
      );

      final klass = generator.generateClass(model);
      final generated = format(klass.accept(emitter).toString());

      const expectedGetter = '''
        EncodingShape get currentEncodingShape {
          final shapes = <EncodingShape>{};
          if (string != null) {
            shapes.add(EncodingShape.simple);
          }
          if (data != null) {
            shapes.add(data!.currentEncodingShape);
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

        final format =
            DartFormatter(
              languageVersion: DartFormatter.latestLanguageVersion,
            ).format;
        final generated = format(toSimpleMethod.accept(emitter).toString());

        const expectedMethod = '''
String toSimple({required bool explode, required bool allowEmpty}) {
  final mapValues = <Map<String, String>>[];
  String? discriminatorValue;
  if (person != null) {
    final personSimple = person!.parameterProperties(allowEmpty: allowEmpty);
    mapValues.add(personSimple);
    discriminatorValue ??= r'person';
  }
  if (company != null) {
    final companySimple = company!.parameterProperties(allowEmpty: allowEmpty);
    mapValues.add(companySimple);
    discriminatorValue ??= r'company';
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

        expect(generated.trim(), equals(expectedMethod.trim()));
      },
    );

    test(
      'anyOf with discriminator includes discriminator in toForm for complex',
      () {
        final personModel = ClassModel(
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

        final format =
            DartFormatter(
              languageVersion: DartFormatter.latestLanguageVersion,
            ).format;
        final generated = format(toFormMethod.accept(emitter).toString());

        const expectedMethod = '''
String toForm({required bool explode, required bool allowEmpty}) {
  final mapValues = <Map<String, String>>[];
  String? discriminatorValue;
  if (person != null) {
    final personForm = person!.parameterProperties(allowEmpty: allowEmpty);
    mapValues.add(personForm);
    discriminatorValue ??= r'person';
  }
  if (company != null) {
    final companyForm = company!.parameterProperties(allowEmpty: allowEmpty);
    mapValues.add(companyForm);
    discriminatorValue ??= r'company';
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

        expect(generated.trim(), equals(expectedMethod.trim()));
      },
    );

    test(
      'anyOf with discriminator does NOT include discriminator for simple only',
      () {
        final model = AnyOfModel(
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

        final format =
            DartFormatter(
              languageVersion: DartFormatter.latestLanguageVersion,
            ).format;
        final generated = format(toSimpleMethod.accept(emitter).toString());

        const expectedMethod = '''
String toSimple({required bool explode, required bool allowEmpty}) {
  final values = <String>{};
  if (string != null) {
    final stringSimple = string!.toSimple(
      explode: explode,
      allowEmpty: allowEmpty,
    );
    values.add(stringSimple);
  }
  if (int != null) {
    final intSimple = int!.toSimple(explode: explode, allowEmpty: allowEmpty);
    values.add(intSimple);
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

        expect(generated.trim(), equals(expectedMethod.trim()));
      },
    );

    test(
      'anyOf with discriminator handles mixed simple and complex correctly',
      () {
        final classModel = ClassModel(
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

        final format =
            DartFormatter(
              languageVersion: DartFormatter.latestLanguageVersion,
            ).format;
        final generated = format(toSimpleMethod.accept(emitter).toString());

        const expectedMethod = '''
String toSimple({required bool explode, required bool allowEmpty}) {
  final values = <String>{};
  final mapValues = <Map<String, String>>[];
  String? discriminatorValue;
  if (string != null) {
    final stringSimple = string!.toSimple(
      explode: explode,
      allowEmpty: allowEmpty,
    );
    values.add(stringSimple);
  }
  if (data != null) {
    final dataSimple = data!.parameterProperties(allowEmpty: allowEmpty);
    mapValues.add(dataSimple);
    discriminatorValue ??= r'data';
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

        expect(generated.trim(), equals(expectedMethod.trim()));
      },
    );
  });

  group('parameterProperties', () {
    test('method exists with correct signature for anyOf', () {
      final model = AnyOfModel(
        name: 'FlexibleChoice',
        models: {
          (
            discriminatorValue: 'user',
            model: ClassModel(
              name: 'User',
              properties: const [],
              context: context,
            ),
          ),
          (
            discriminatorValue: 'admin',
            model: ClassModel(
              name: 'Admin',
              properties: const [],
              context: context,
            ),
          ),
        },
        discriminator: null,
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
      expect(method.optionalParameters.length, 1);
      expect(method.optionalParameters.first.name, 'allowEmpty');
      expect(method.optionalParameters.first.named, isTrue);
      expect(method.optionalParameters.first.required, isFalse);
      expect(
        method.optionalParameters.first.defaultTo?.accept(emitter).toString(),
        'true',
      );
    });

    test('generates complete method for single complex variant', () {
      final userModel = ClassModel(
        name: 'User',
        properties: const [],
        context: context,
      );

      final model = AnyOfModel(
        name: 'FlexibleChoice',
        models: {
          (discriminatorValue: 'user', model: userModel),
        },
        discriminator: null,
        context: context,
      );

      final klass = generator.generateClass(model);
      final method = klass.methods.firstWhere(
        (m) => m.name == 'parameterProperties',
      );

      final format =
          DartFormatter(
            languageVersion: DartFormatter.latestLanguageVersion,
          ).format;
      final generated = format(method.accept(emitter).toString());

      const expectedMethod = r'''
Map<String, String> parameterProperties({bool allowEmpty = true}) {
  final _$mapValues = <Map<String, String>>[];
  if (user != null) {
    _$mapValues.add(user!.parameterProperties(allowEmpty: allowEmpty));
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
        name: 'User',
        properties: const [],
        context: context,
      );

      final admin = ClassModel(
        name: 'Admin',
        properties: const [],
        context: context,
      );

      final model = AnyOfModel(
        name: 'MultiChoice',
        models: {
          (discriminatorValue: 'user', model: user),
          (discriminatorValue: 'admin', model: admin),
        },
        discriminator: null,
        context: context,
      );

      final klass = generator.generateClass(model);
      final method = klass.methods.firstWhere(
        (m) => m.name == 'parameterProperties',
      );

      final format =
          DartFormatter(
            languageVersion: DartFormatter.latestLanguageVersion,
          ).format;
      final generated = format(method.accept(emitter).toString());

      const expectedMethod = r'''
Map<String, String> parameterProperties({bool allowEmpty = true}) {
  final _$mapValues = <Map<String, String>>[];
  if (user != null) {
    _$mapValues.add(user!.parameterProperties(allowEmpty: allowEmpty));
  }
  if (admin != null) {
    _$mapValues.add(admin!.parameterProperties(allowEmpty: allowEmpty));
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

      final format =
          DartFormatter(
            languageVersion: DartFormatter.latestLanguageVersion,
          ).format;
      final generated = format(method.accept(emitter).toString());

      const expectedMethod = r'''
Map<String, String> parameterProperties({bool allowEmpty = true}) {
  final _$mapValues = <Map<String, String>>[];
  String? _$discriminatorValue;
  if (data != null) {
    _$mapValues.add(data!.parameterProperties(allowEmpty: allowEmpty));
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
        name: 'InnerChoice',
        models: {
          (discriminatorValue: 'string', model: StringModel(context: context)),
          (
            discriminatorValue: 'data',
            model: ClassModel(
              name: 'Data',
              properties: const [],
              context: context,
            ),
          ),
        },
        discriminator: null,
        context: context,
      );

      final model = AnyOfModel(
        name: 'MixedChoice',
        models: {
          (discriminatorValue: 'inner', model: anyOfModel),
        },
        discriminator: null,
        context: context,
      );

      final klass = generator.generateClass(model);
      final method = klass.methods.firstWhere(
        (m) => m.name == 'parameterProperties',
      );

      final format =
          DartFormatter(
            languageVersion: DartFormatter.latestLanguageVersion,
          ).format;
      final generated = format(method.accept(emitter).toString());

      const expectedMethod = r'''
Map<String, String> parameterProperties({bool allowEmpty = true}) {
  final _$mapValues = <Map<String, String>>[];
  if (innerChoice != null) {
    switch (innerChoice!.currentEncodingShape) {
      case EncodingShape.simple:
        throw EncodingException(
          'Cannot encode simple type to map in parameterProperties',
        );
      case EncodingShape.complex:
        _$mapValues.add(
          innerChoice!.parameterProperties(allowEmpty: allowEmpty),
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
          name: 'InnerChoice',
          models: {
            (
              discriminatorValue: 'string',
              model: StringModel(context: context),
            ),
            (
              discriminatorValue: 'data',
              model: ClassModel(
                name: 'Data',
                properties: const [],
                context: context,
              ),
            ),
          },
          discriminator: null,
          context: context,
        );

        final model = AnyOfModel(
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

        final format =
            DartFormatter(
              languageVersion: DartFormatter.latestLanguageVersion,
            ).format;
        final generated = format(method.accept(emitter).toString());

        const expectedMethod = r'''
Map<String, String> parameterProperties({bool allowEmpty = true}) {
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
          innerChoice!.parameterProperties(allowEmpty: allowEmpty),
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
      'generates complete method for anyOf with dynamic encoding shape and '
      'complex class',
      () {
        final anyOfModel = AnyOfModel(
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
          discriminator: null,
          context: context,
        );

        final classModel = ClassModel(
          name: 'ComplexData',
          properties: const [],
          context: context,
        );

        final model = AnyOfModel(
          name: 'MixedChoice',
          models: {
            (discriminatorValue: 'inner', model: anyOfModel),
            (discriminatorValue: 'complex', model: classModel),
          },
          discriminator: null,
          context: context,
        );

        final klass = generator.generateClass(model);
        final method = klass.methods.firstWhere(
          (m) => m.name == 'parameterProperties',
        );

        final format =
            DartFormatter(
              languageVersion: DartFormatter.latestLanguageVersion,
            ).format;
        final generated = format(method.accept(emitter).toString());

        const expectedMethod = r'''
Map<String, String> parameterProperties({bool allowEmpty = true}) {
  final _$mapValues = <Map<String, String>>[];
  if (innerChoice != null) {
    switch (innerChoice!.currentEncodingShape) {
      case EncodingShape.simple:
        throw EncodingException(
          'Cannot encode simple type to map in parameterProperties',
        );
      case EncodingShape.complex:
        _$mapValues.add(
          innerChoice!.parameterProperties(allowEmpty: allowEmpty),
        );
        break;
      case EncodingShape.mixed:
        throw EncodingException(
          'Cannot encode field with mixed encoding shape',
        );
    }
  }
  if (complexData != null) {
    _$mapValues.add(complexData!.parameterProperties(allowEmpty: allowEmpty));
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
          name: 'ComplexData',
          properties: const [],
          context: context,
        );

        final model = AnyOfModel(
          name: 'MixedTopLevel',
          models: {
            (
              discriminatorValue: 'string',
              model: StringModel(context: context),
            ),
            (discriminatorValue: 'complex', model: classModel),
          },
          discriminator: null,
          context: context,
        );

        final klass = generator.generateClass(model);
        final method = klass.methods.firstWhere(
          (m) => m.name == 'parameterProperties',
        );

        final format =
            DartFormatter(
              languageVersion: DartFormatter.latestLanguageVersion,
            ).format;
        final generated = format(method.accept(emitter).toString());

        const expectedMethod = r'''
Map<String, String> parameterProperties({bool allowEmpty = true}) {
  final _$mapValues = <Map<String, String>>[];
  if (complexData != null) {
    _$mapValues.add(complexData!.parameterProperties(allowEmpty: allowEmpty));
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
        name: 'SimpleChoice',
        models: {
          (discriminatorValue: 'string', model: StringModel(context: context)),
          (discriminatorValue: 'number', model: IntegerModel(context: context)),
        },
        discriminator: null,
        context: context,
      );

      final klass = generator.generateClass(model);
      final method = klass.methods.firstWhere(
        (m) => m.name == 'parameterProperties',
      );

      final format =
          DartFormatter(
            languageVersion: DartFormatter.latestLanguageVersion,
          ).format;
      final generated = format(method.accept(emitter).toString());

      const expectedMethod = '''
Map<String, String> parameterProperties({bool allowEmpty = true}) {
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
  });
}
