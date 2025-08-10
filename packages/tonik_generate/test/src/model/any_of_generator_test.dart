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
    test('generates class with nullable fields for each model', () {
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
      expect(ctorParams.every((p) => p.named == true), isTrue);
      expect(ctorParams.every((p) => p.required != true), isTrue);
      expect(ctorParams.every((p) => p.toThis == true), isTrue);
    });

    test(
      'generates class when discriminatorValue is absent for all entries',
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

    test('generates class with enum, date, dateTime, bool, decimal', () {
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
      final defaultCtor = klass.constructors.firstWhere((c) => c.name == null);
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
      expect(ctor.optionalParameters.every((p) => p.named == true), isTrue);
      expect(ctor.optionalParameters.every((p) => p.required != true), isTrue);
    });
  });

  group('equals, hashCode, copyWith', () {
    test('generates equals and hashCode for simple fields', () {
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

    test('generates copyWith with nullable param types and field defaults', () {
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
    });
  });

  group('fromJson', () {
    test(
      'wraps each property decode in try/catch and assigns null on failure',
      () {
        final complex = ClassModel(
          name: 'User',
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

        final model = AnyOfModel(
          name: 'Flexible',
          models: {
            (discriminatorValue: null, model: StringModel(context: context)),
            (discriminatorValue: null, model: IntegerModel(context: context)),
            (discriminatorValue: null, model: complex),
          },
          discriminator: null,
          context: context,
        );

        final klass = generator.generateClass(model);

        final fromJson = klass.constructors.firstWhere(
          (c) => c.name == 'fromJson',
        );
        expect(fromJson.factory, isTrue);
        expect(
          fromJson.requiredParameters.first.type?.accept(emitter).toString(),
          'Object?',
        );

        final format =
            DartFormatter(
              languageVersion: DartFormatter.latestLanguageVersion,
            ).format;
        final generated = format(klass.accept(emitter).toString());

        const expectedMethod = '''
        factory Flexible.fromJson(Object? json) {
          String? string;
          try {
            string = json.decodeJsonString(context: r'Flexible');
          } on Object catch (_) {
            string = null;
          }

          int? int;
          try {
            int = json.decodeJsonInt(context: r'Flexible');
          } on Object catch (_) {
            int = null;
          }

          User? user;
          try {
            user = User.fromJson(json);
          } on Object catch (_) {
            user = null;
          }

          return Flexible(string: string, int: int, user: user);
        }
      ''';

        expect(
          collapseWhitespace(generated),
          contains(collapseWhitespace(expectedMethod)),
        );
      },
    );
  });

  group('fromSimple', () {
    test(
      'wraps each property decode in try/catch and assigns null on failure',
      () {
        final complex = ClassModel(
          name: 'User',
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

        final model = AnyOfModel(
          name: 'Flexible',
          models: {
            (discriminatorValue: null, model: StringModel(context: context)),
            (discriminatorValue: null, model: IntegerModel(context: context)),
            (discriminatorValue: null, model: complex),
          },
          discriminator: null,
          context: context,
        );

        final klass = generator.generateClass(model);

        final fromSimple = klass.constructors.firstWhere(
          (c) => c.name == 'fromSimple',
        );
        expect(fromSimple.factory, isTrue);
        expect(
          fromSimple.requiredParameters.first.type?.accept(emitter).toString(),
          'String?',
        );
        expect(fromSimple.optionalParameters, isNotEmpty);
        expect(fromSimple.optionalParameters.first.name, 'explode');
        expect(
          fromSimple.optionalParameters.first.type?.accept(emitter).toString(),
          'bool',
        );

        final format =
            DartFormatter(
              languageVersion: DartFormatter.latestLanguageVersion,
            ).format;
        final generated = format(klass.accept(emitter).toString());

        const expectedMethod = '''
          factory Flexible.fromSimple(String? value, {required bool explode}) {
            String? string;
            try {
              string = value.decodeSimpleString(context: r'Flexible');
            } on Object catch (_) {
              string = null;
            }

            int? int;
            try {
              int = value.decodeSimpleInt(context: r'Flexible');
            } on Object catch (_) {
              int = null;
            }

            User? user;
            try {
              user = User.fromSimple(value, explode: explode);
            } on Object catch (_) {
              user = null;
            }

            return Flexible(string: string, int: int, user: user);
          }
        ''';

        expect(
          collapseWhitespace(generated),
          contains(collapseWhitespace(expectedMethod)),
        );
      },
    );
  });

  test('generates full toJson body with generic merge-or-equal algorithm', () {
    final modelA = ClassModel(
      name: 'A',
      properties: [
        Property(
          name: 'id',
          model: StringModel(context: context),
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
        ),
      ],
      context: context,
    );

    final modelB = ClassModel(
      name: 'B',
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

    final model = AnyOfModel(
      name: 'Payload',
      models: {
        (discriminatorValue: 'a', model: modelA),
        (discriminatorValue: 'b', model: modelB),
      },
      discriminator: 'disc',
      context: context,
    );

    final klass = generator.generateClass(model);

    final format =
        DartFormatter(
          languageVersion: DartFormatter.latestLanguageVersion,
        ).format;
    final generated = format(klass.accept(emitter).toString());

    const expectedMethod = '''
      Object? toJson() {
        final values = <Object?>[];
        final mapValues = <Map<String, Object?>>[];
        String? discriminatorValue;

        if (a != null) {
          final Object? aJson = a!.toJson();
          if (aJson is Map<String, Object?>) {
            mapValues.add(aJson);
            discriminatorValue ??= 'a';
          }
          values.add(aJson);
        }
        if (b != null) {
          final Object? bJson = b!.toJson();
          if (bJson is Map<String, Object?>) {
            mapValues.add(bJson);
            discriminatorValue ??= 'b';
          }
          values.add(bJson);
        }

        if (values.isEmpty) return null;

        if (mapValues.length == values.length) {
          final map = <String, Object?>{};
          for (final m in mapValues) {
            map.addAll(m);
          }
          if (discriminatorValue != null) {
            map.putIfAbsent('disc', () => discriminatorValue);
          }
          return map;
        }

        const _deepEquals = DeepCollectionEquality();
        final first = values.firstOrNull;
        if (first == null) return null;
        for (final v in values) {
          if (!_deepEquals.equals(v, first)) {
            throw EncodingException(
              'Ambiguous anyOf encoding for Payload: inconsistent JSON representations',
            );
          }
        }
        return first;
      }
    ''';

    expect(
      collapseWhitespace(generated),
      contains(collapseWhitespace(expectedMethod)),
    );
  });

  test(
    'generates full toJson body without discriminator when none configured',
    () {
      final modelA = ClassModel(
        name: 'A',
        properties: [
          Property(
            name: 'id',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ],
        context: context,
      );

      final modelB = ClassModel(
        name: 'B',
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

      final model = AnyOfModel(
        name: 'PayloadNoDisc',
        models: {
          (discriminatorValue: null, model: modelA),
          (discriminatorValue: 'b', model: modelB),
        },
        discriminator: null,
        context: context,
      );

      final klass = generator.generateClass(model);

      final format =
          DartFormatter(
            languageVersion: DartFormatter.latestLanguageVersion,
          ).format;
      final generated = format(klass.accept(emitter).toString());

    const expectedMethod = '''
      Object? toJson() {
        final values = <Object?>[];
        final mapValues = <Map<String, Object?>>[];

        if (a != null) {
          final Object? aJson = a!.toJson();
          if (aJson is Map<String, Object?>) {
            mapValues.add(aJson);
          }
          values.add(aJson);
        }
        if (b != null) {
          final Object? bJson = b!.toJson();
          if (bJson is Map<String, Object?>) {
            mapValues.add(bJson);
          }
          values.add(bJson);
        }

        if (values.isEmpty) return null;

        if (mapValues.length == values.length) {
          final map = <String, Object?>{};
          for (final m in mapValues) {
            map.addAll(m);
          }
          return map;
        }

        const _deepEquals = DeepCollectionEquality();
        final first = values.firstOrNull;
        if (first == null) return null;
        for (final v in values) {
          if (!_deepEquals.equals(v, first)) {
            throw EncodingException(
              'Ambiguous anyOf encoding for PayloadNoDisc: inconsistent JSON representations',
            );
          }
        }
        return first;
      }
    ''';

      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedMethod)),
      );
    },
  );

  test('generates full toJson body for primitive-only anyOf', () {
    final model = AnyOfModel(
      name: 'OnlyPrimitives',
      models: {
        (discriminatorValue: null, model: StringModel(context: context)),
        (discriminatorValue: null, model: IntegerModel(context: context)),
        (discriminatorValue: null, model: BooleanModel(context: context)),
      },
      discriminator: 'type',
      context: context,
    );

    final klass = generator.generateClass(model);

    final format =
        DartFormatter(
          languageVersion: DartFormatter.latestLanguageVersion,
        ).format;
    final generated = format(klass.accept(emitter).toString());

    const expectedMethod = '''
      Object? toJson() {
        final values = <Object?>[];
        final mapValues = <Map<String, Object?>>[];
        String? discriminatorValue;

        if (string != null) {
          final Object? stringJson = string;
          if (stringJson is Map<String, Object?>) {
            mapValues.add(stringJson);
          }
          values.add(stringJson);
        }
        if (int != null) {
          final Object? intJson = int;
          if (intJson is Map<String, Object?>) {
            mapValues.add(intJson);
          }
          values.add(intJson);
        }
        if (bool != null) {
          final Object? boolJson = bool;
          if (boolJson is Map<String, Object?>) {
            mapValues.add(boolJson);
          }
          values.add(boolJson);
        }

        if (values.isEmpty) return null;

        if (mapValues.length == values.length) {
          final map = <String, Object?>{};
          for (final m in mapValues) {
            map.addAll(m);
          }
          if (discriminatorValue != null) {
            map.putIfAbsent('type', () => discriminatorValue);
          }
          return map;
        }

        const _deepEquals = DeepCollectionEquality();
        final first = values.firstOrNull;
        if (first == null) return null;
        for (final v in values) {
          if (!_deepEquals.equals(v, first)) {
            throw EncodingException(
              'Ambiguous anyOf encoding for OnlyPrimitives: inconsistent JSON representations',
            );
          }
        }
        return first;
      }
    ''';

    expect(
      collapseWhitespace(generated),
      contains(collapseWhitespace(expectedMethod)),
    );
  });

  test('generates full toJson body for mixed class and primitive anyOf', () {
    final user = ClassModel(
      name: 'User',
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

    final model = AnyOfModel(
      name: 'Mixed',
      models: {
        (discriminatorValue: 'user', model: user),
        (discriminatorValue: 'str', model: StringModel(context: context)),
      },
      discriminator: 'disc',
      context: context,
    );

    final klass = generator.generateClass(model);

    final format =
        DartFormatter(
          languageVersion: DartFormatter.latestLanguageVersion,
        ).format;
    final generated = format(klass.accept(emitter).toString());

    const expectedMethod = '''
      Object? toJson() {
        final values = <Object?>[];
        final mapValues = <Map<String, Object?>>[];
        String? discriminatorValue;

        if (user != null) {
          final Object? userJson = user!.toJson();
          if (userJson is Map<String, Object?>) {
            mapValues.add(userJson);
            discriminatorValue ??= 'user';
          }
          values.add(userJson);
        }
        if (string != null) {
          final Object? stringJson = string;
          if (stringJson is Map<String, Object?>) {
            mapValues.add(stringJson);
            discriminatorValue ??= 'str';
          }
          values.add(stringJson);
        }

        if (values.isEmpty) return null;

        if (mapValues.length == values.length) {
          final map = <String, Object?>{};
          for (final m in mapValues) {
            map.addAll(m);
          }
          if (discriminatorValue != null) {
            map.putIfAbsent('disc', () => discriminatorValue);
          }
          return map;
        }

        const _deepEquals = DeepCollectionEquality();
        final first = values.firstOrNull;
        if (first == null) return null;
        for (final v in values) {
          if (!_deepEquals.equals(v, first)) {
            throw EncodingException(
              'Ambiguous anyOf encoding for Mixed: inconsistent JSON representations',
            );
          }
        }
        return first;
      }
    ''';

    expect(
      collapseWhitespace(generated),
      contains(collapseWhitespace(expectedMethod)),
    );
  });
}
