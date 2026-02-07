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

  group('fromJson', () {
    test(
      'generates fromJson factory that wraps each property decode in try/catch and assigns null on failure',
      () {
        final complex = ClassModel(
          isDeprecated: false,
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
          isDeprecated: false,
          name: 'Flexible',
          models: {
            (discriminatorValue: null, model: StringModel(context: context)),
            (discriminatorValue: null, model: IntegerModel(context: context)),
            (discriminatorValue: null, model: complex),
          },
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

        final format = DartFormatter(
          languageVersion: DartFormatter.latestLanguageVersion,
        ).format;
        final generated = format(klass.accept(emitter).toString());

        const expectedMethod = '''
        factory Flexible.fromJson(Object? json) {
          User? user;
          try {
            user = User.fromJson(json);
          } on Object catch (_) {
            user = null;
          }

          int? int;
          try {
            int = json.decodeJsonInt(context: r'Flexible');
          } on Object catch (_) {
            int = null;
          }

          String? string;
          try {
            string = json.decodeJsonString(context: r'Flexible');
          } on Object catch (_) {
            string = null;
          }

          if (user == null && int == null && string == null) {
            throw JsonDecodingException(
              r'Invalid JSON for Flexible: all variants failed to decode',
            );
          }
          return Flexible(user: user, int: int, string: string);
        }
      ''';

        expect(
          collapseWhitespace(generated),
          contains(collapseWhitespace(expectedMethod)),
        );
      },
    );
  });

  test(
    'generates toJson method with merge-or-equal algorithm for complex models',
    () {
      final modelA = ClassModel(
        isDeprecated: false,
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
        isDeprecated: false,
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
        isDeprecated: false,
        name: 'Payload',
        models: {
          (discriminatorValue: 'a', model: modelA),
          (discriminatorValue: 'b', model: modelB),
        },
        discriminator: 'disc',
        context: context,
      );

      final klass = generator.generateClass(model);

      final format = DartFormatter(
        languageVersion: DartFormatter.latestLanguageVersion,
      ).format;
      final generated = format(klass.accept(emitter).toString());

      const expectedMethod = '''
      Object? toJson() {
        final values = <Object?>{};
        final mapValues = <Map<String, Object?>>[];
        String? discriminatorValue;

        if (a != null) {
          final Object? aJson = a!.toJson();
          if (aJson is Map<String, Object?>) {
            mapValues.add(aJson);
              discriminatorValue ??= r'a';
          } else {
            values.add(aJson);
          }
        }
        if (b != null) {
          final Object? bJson = b!.toJson();
          if (bJson is Map<String, Object?>) {
            mapValues.add(bJson);
              discriminatorValue ??= r'b';
          } else {
            values.add(bJson);
          }
        }

        if (values.isEmpty && mapValues.isEmpty) return null;

        if (values.isNotEmpty && mapValues.isNotEmpty) {
          throw EncodingException(
            r'Mixed encoding not supported for Payload: cannot encode both simple and complex values',
          );
        }

        if (values.isNotEmpty) {
          if (values.length > 1) {
            throw EncodingException(
              r'Ambiguous anyOf encoding for Payload: multiple values provided, anyOf requires exactly one value',
            );
          }
          return values.first;
        }

        if (mapValues.isNotEmpty) {
          final map = <String, Object?>{};
          for (final m in mapValues) {
            map.addAll(m);
          }
          final discValue = discriminatorValue;
          if (discValue != null) {
            map.putIfAbsent('disc', () => discValue);
          }
          return map;
        }

        return null;
      }
    ''';

      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedMethod)),
      );
    },
  );

  test(
    'generates toJson method without discriminator when none configured',
    () {
      final modelA = ClassModel(
        isDeprecated: false,
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
        isDeprecated: false,
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
        isDeprecated: false,
        name: 'PayloadNoDisc',
        models: {
          (discriminatorValue: null, model: modelA),
          (discriminatorValue: 'b', model: modelB),
        },
        context: context,
      );

      final klass = generator.generateClass(model);

      final format = DartFormatter(
        languageVersion: DartFormatter.latestLanguageVersion,
      ).format;
      final generated = format(klass.accept(emitter).toString());

      const expectedMethod = '''
      Object? toJson() {
        final values = <Object?>{};
        final mapValues = <Map<String, Object?>>[];

        if (a != null) {
          final Object? aJson = a!.toJson();
          if (aJson is Map<String, Object?>) {
            mapValues.add(aJson);
          } else {
            values.add(aJson);
          }
        }
        if (b != null) {
          final Object? bJson = b!.toJson();
          if (bJson is Map<String, Object?>) {
            mapValues.add(bJson);
          } else {
            values.add(bJson);
          }
        }

        if (values.isEmpty && mapValues.isEmpty) return null;

        if (values.isNotEmpty && mapValues.isNotEmpty) {
          throw EncodingException(
            r'Mixed encoding not supported for PayloadNoDisc: cannot encode both simple and complex values',
          );
        }

        if (values.isNotEmpty) {
          if (values.length > 1) {
            throw EncodingException(
              r'Ambiguous anyOf encoding for PayloadNoDisc: multiple values provided, anyOf requires exactly one value',
            );
          }
          return values.first;
        }

        if (mapValues.isNotEmpty) {
          final map = <String, Object?>{};
          for (final m in mapValues) {
            map.addAll(m);
          }
          return map;
        }

        return null;
      }
    ''';

      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedMethod)),
      );
    },
  );

  test('generates toJson method for primitive-only anyOf models', () {
    final model = AnyOfModel(
      isDeprecated: false,
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

    final format = DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    ).format;
    final generated = format(klass.accept(emitter).toString());

    const expectedMethod = '''
      Object? toJson() {
        final values = <Object?>{};
        final mapValues = <Map<String, Object?>>[];
        String? discriminatorValue;

        if (bool != null) {
          final Object? boolJson = bool!;
          if (boolJson is Map<String, Object?>) {
            mapValues.add(boolJson);
          } else {
            values.add(boolJson);
          }
        }
        if (int != null) {
          final Object? intJson = int!;
          if (intJson is Map<String, Object?>) {
            mapValues.add(intJson);
          } else {
            values.add(intJson);
          }
        }
        if (string != null) {
          final Object? stringJson = string!;
          if (stringJson is Map<String, Object?>) {
            mapValues.add(stringJson);
          } else {
            values.add(stringJson);
          }
        }

        if (values.isEmpty && mapValues.isEmpty) return null;

        if (values.isNotEmpty && mapValues.isNotEmpty) {
          throw EncodingException(
            r'Mixed encoding not supported for OnlyPrimitives: cannot encode both simple and complex values',
          );
        }

        if (values.isNotEmpty) {
          if (values.length > 1) {
            throw EncodingException(
              r'Ambiguous anyOf encoding for OnlyPrimitives: multiple values provided, anyOf requires exactly one value',
            );
          }
          return values.first;
        }

        if (mapValues.isNotEmpty) {
          final map = <String, Object?>{};
          for (final m in mapValues) {
            map.addAll(m);
          }
          final discValue = discriminatorValue;
          if (discValue != null) {
            map.putIfAbsent('type', () => discValue);
          }
          return map;
        }

        return null;
      }
    ''';

    expect(
      collapseWhitespace(generated),
      contains(collapseWhitespace(expectedMethod)),
    );
  });

  test(
    'generates toJson method for mixed class and primitive anyOf models',
    () {
      final user = ClassModel(
        isDeprecated: false,
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
        isDeprecated: false,
        name: 'Mixed',
        models: {
          (discriminatorValue: 'user', model: user),
          (discriminatorValue: 'str', model: StringModel(context: context)),
        },
        discriminator: 'disc',
        context: context,
      );

      final klass = generator.generateClass(model);

      final format = DartFormatter(
        languageVersion: DartFormatter.latestLanguageVersion,
      ).format;
      final generated = format(klass.accept(emitter).toString());

      const expectedMethod = '''
      Object? toJson() {
        final values = <Object?>{};
        final mapValues = <Map<String, Object?>>[];
        String? discriminatorValue;

        if (string != null) {
          final Object? stringJson = string!;
          if (stringJson is Map<String, Object?>) {
            mapValues.add(stringJson);
              discriminatorValue ??= r'str';
          } else {
            values.add(stringJson);
          }
        }
        if (user != null) {
          final Object? userJson = user!.toJson();
          if (userJson is Map<String, Object?>) {
            mapValues.add(userJson);
              discriminatorValue ??= r'user';
          } else {
            values.add(userJson);
          }
        }

        if (values.isEmpty && mapValues.isEmpty) return null;

        if (values.isNotEmpty && mapValues.isNotEmpty) {
          throw EncodingException(
            r'Mixed encoding not supported for Mixed: cannot encode both simple and complex values',
          );
        }

        if (values.isNotEmpty) {
          if (values.length > 1) {
            throw EncodingException(
              r'Ambiguous anyOf encoding for Mixed: multiple values provided, anyOf requires exactly one value',
            );
          }
          return values.first;
        }

        if (mapValues.isNotEmpty) {
          final map = <String, Object?>{};
          for (final m in mapValues) {
            map.addAll(m);
          }
          final discValue = discriminatorValue;
          if (discValue != null) {
            map.putIfAbsent('disc', () => discValue);
          }
          return map;
        }

        return null;
      }
    ''';

      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedMethod)),
      );
    },
  );
}
