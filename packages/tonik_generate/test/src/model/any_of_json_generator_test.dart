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

  test(
    'generates toJson method with merge-or-equal algorithm for complex models',
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
    'generates toJson method without discriminator when none configured',
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

  test('generates toJson method for primitive-only anyOf models', () {
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

  test(
    'generates toJson method for mixed class and primitive anyOf models',
    () {
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
