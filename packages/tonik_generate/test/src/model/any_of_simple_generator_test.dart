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

  group('fromSimple', () {
    test(
      'generates fromSimple factory that wraps each property decode in try/catch and assigns null on failure',
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

  group('toSimple', () {
    test(
      'generates toSimple method with merge-or-equal algorithm',
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
        name: 'PayloadSimple',
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
        String toSimple({required bool explode, required bool allowEmpty}) {
          final values = <String>[];
          final mapValues = <Map<String, String>>[];
          String? discriminatorValue;

          if (a != null) {
            final aSimple = a!.simpleProperties(allowEmpty: allowEmpty);
            mapValues.add(aSimple);
            discriminatorValue ??= 'a';
            values.add(aSimple.toSimple(explode: explode, allowEmpty: allowEmpty));
          }
          if (b != null) {
            final bSimple = b!.simpleProperties(allowEmpty: allowEmpty);
            mapValues.add(bSimple);
            discriminatorValue ??= 'b';
            values.add(bSimple.toSimple(explode: explode, allowEmpty: allowEmpty));
          }

          if (values.isEmpty) return '';
          if (mapValues.isNotEmpty && mapValues.length != values.length) {
            throw EncodingException(
              'Ambiguous anyOf simple encoding for PayloadSimple: mixing simple and complex values',
            );
          }
          if (mapValues.length == values.length) {
            final map = <String, String>{};
            for (final m in mapValues) {
              map.addAll(m);
            }
            if (discriminatorValue != null) {
              map.putIfAbsent('disc', () => discriminatorValue);
            }
            return map.toSimple(explode: explode, allowEmpty: allowEmpty);
          }

          final first = values.first;
          for (final v in values) {
            if (v != first) {
              throw EncodingException(
                'Ambiguous anyOf simple encoding for PayloadSimple: inconsistent simple representations',
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
      'generates toSimple method without discriminator when none configured',
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
          name: 'PayloadSimpleNoDisc',
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
          String toSimple({required bool explode, required bool allowEmpty}) {
            final values = <String>[];
            final mapValues = <Map<String, String>>[];

            if (a != null) {
              final aSimple = a!.simpleProperties(allowEmpty: allowEmpty);
              mapValues.add(aSimple);
              values.add(aSimple.toSimple(explode: explode, allowEmpty: allowEmpty));
            }
            if (b != null) {
              final bSimple = b!.simpleProperties(allowEmpty: allowEmpty);
              mapValues.add(bSimple);
              values.add(bSimple.toSimple(explode: explode, allowEmpty: allowEmpty));
            }

            if (values.isEmpty) return '';
            if (mapValues.isNotEmpty && mapValues.length != values.length) {
              throw EncodingException(
                'Ambiguous anyOf simple encoding for PayloadSimpleNoDisc: mixing simple and complex values',
              );
            }

            if (mapValues.length == values.length) {
              final map = <String, String>{};
              for (final m in mapValues) {
                map.addAll(m);
              }
              return map.toSimple(explode: explode, allowEmpty: allowEmpty);
            }

            final first = values.first;
            for (final v in values) {
              if (v != first) {
                throw EncodingException(
                  'Ambiguous anyOf simple encoding for PayloadSimpleNoDisc: inconsistent simple representations',
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

    test('generates toSimple method for primitive-only anyOf models', () {
      final model = AnyOfModel(
        name: 'OnlyPrimitivesSimple',
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
        String toSimple({required bool explode, required bool allowEmpty}) {
          final values = <String>[];
          final mapValues = <Map<String, String>>[];
          String? discriminatorValue;

          if (string != null) {
            final stringSimple = string!.toSimple( explode: explode, allowEmpty: allowEmpty, );
            values.add(stringSimple);
          }
          if (int != null) {
            final intSimple = int!.toSimple(explode: explode, allowEmpty: allowEmpty);
            values.add(intSimple);
          }
          if (bool != null) {
            final boolSimple = bool!.toSimple( explode: explode, allowEmpty: allowEmpty, );
            values.add(boolSimple);
          }

          if (values.isEmpty) return '';
          if (mapValues.isNotEmpty && mapValues.length != values.length) {
            throw EncodingException(
              'Ambiguous anyOf simple encoding for OnlyPrimitivesSimple: mixing simple and complex values',
            );
          }

          if (mapValues.length == values.length) {
            final map = <String, String>{};
            for (final m in mapValues) {
              map.addAll(m);
            }
            if (discriminatorValue != null) {
              map.putIfAbsent('type', () => discriminatorValue);
            }
            return map.toSimple(explode: explode, allowEmpty: allowEmpty);
          }

          final first = values.first;
          for (final v in values) {
            if (v != first) {
              throw EncodingException(
                'Ambiguous anyOf simple encoding for OnlyPrimitivesSimple: inconsistent simple representations',
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
      'throws exception when mixed class and primitive anyOf are both set',
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
        name: 'MixedSimple',
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
        String toSimple({required bool explode, required bool allowEmpty}) {
          final values = <String>[];
          final mapValues = <Map<String, String>>[];
          String? discriminatorValue;

          if (user != null) {
            final userSimple = user!.simpleProperties(allowEmpty: allowEmpty);
            mapValues.add(userSimple);
            discriminatorValue ??= 'user';
            values.add(userSimple.toSimple(explode: explode, allowEmpty: allowEmpty));
          }
          if (string != null) {
            final stringSimple = string!.toSimple( 
              explode: explode, 
              allowEmpty: allowEmpty, 
            );
            values.add(stringSimple);
          }

          if (values.isEmpty) return '';

          if (mapValues.isNotEmpty && mapValues.length != values.length) {
            throw EncodingException(
              'Ambiguous anyOf simple encoding for MixedSimple: mixing simple and complex values',
            );
          }

          if (mapValues.length == values.length) {
            final map = <String, String>{};
            for (final m in mapValues) {
              map.addAll(m);
            }
            if (discriminatorValue != null) {
              map.putIfAbsent('disc', () => discriminatorValue);
            }
            return map.toSimple(explode: explode, allowEmpty: allowEmpty);
          }

          final first = values.first;
          for (final v in values) {
            if (v != first) {
              throw EncodingException(
                'Ambiguous anyOf simple encoding for MixedSimple: inconsistent simple representations',
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
  });

  group('simpleProperties', () {
    test('throws exception for primitive-only anyOf in simpleProperties', () {
      final model = AnyOfModel(
        name: 'OnlyPrimitivesSimple',
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
        Map<String, String> simpleProperties({required bool allowEmpty}) {
          throw EncodingException(
            'simpleProperties not supported for OnlyPrimitivesSimple: contains primitive values',
          );
        }
      ''';

      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test(
      'merges simpleProperties for multiple complex variants',
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
          name: 'PayloadSimple',
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
        Map<String, String> simpleProperties({required bool allowEmpty}) {
          final maps = <Map<String, String>>[];
          if (a != null) {
            final Map<String, String> aSimple = a!.simpleProperties( 
              allowEmpty: allowEmpty, 
            );
            maps.add(aSimple);
          }
          if (b != null) {
            final Map<String, String> bSimple = b!.simpleProperties( 
              allowEmpty: allowEmpty, 
            );
            maps.add(bSimple);
          }
          if (maps.isEmpty) return <String, String>{};
          final map = <String, String>{};
          for (final m in maps) {
            map.addAll(m);
          }
          return map;
        }
      ''';

        expect(
          collapseWhitespace(generated),
          contains(collapseWhitespace(expectedMethod)),
        );
      },
    );

    test(
      'throws exception when mixed complex and primitive values are set',
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
        name: 'MixedSimple',
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
        Map<String, String> simpleProperties({required bool allowEmpty}) {
          final maps = <Map<String, String>>[];
          if (user != null) {
            final Map<String, String> userSimple = user!.simpleProperties( 
              allowEmpty: allowEmpty, 
            );
            maps.add(userSimple);
          }
          if (string != null) {
            throw EncodingException(
              'simpleProperties not supported for MixedSimple: mixing simple and complex values',
            );
          }
          if (maps.isEmpty) return <String, String>{};
          final map = <String, String>{};
          for (final m in maps) {
            map.addAll(m);
          }
          return map;
        }
      ''';

      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedMethod)),
      );
    });
  });
}
