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
          description: null,
          name: 'User',
          properties: [
            Property(
              description: null,
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
          description: null,
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
            User? user;
            try {
              user = User.fromSimple(value, explode: explode);
            } on Object catch (_) {
              user = null;
            }

            int? int;
            try {
              int = value.decodeSimpleInt(context: r'Flexible');
            } on Object catch (_) {
              int = null;
            }

            String? string;
            try {
              string = value.decodeSimpleString(context: r'Flexible');
            } on Object catch (_) {
              string = null;
            }

            if (user == null && int == null && string == null) {
              throw SimpleDecodingException(
                'Invalid simple value for Flexible: all variants failed to decode',
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

    test(
      'anyOf with complex lists and simple type tries decodable variants',
      () {
        final classA = ClassModel(
          description: null,
          name: 'ClassA',
          properties: [
            Property(
              description: null,
              name: 'name',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          context: context,
        );

        final classB = ClassModel(
          description: null,
          name: 'ClassB',
          properties: [
            Property(
              description: null,
              name: 'value',
              model: IntegerModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          context: context,
        );

        final listA = ListModel(
          content: classA,
          context: context,
        );

        final listB = ListModel(
          content: classB,
          context: context,
        );

        final model = AnyOfModel(
          description: null,
          name: 'MixedAnyOf',
          models: {
            (discriminatorValue: null, model: listA),
            (discriminatorValue: null, model: listB),
            (discriminatorValue: null, model: StringModel(context: context)),
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
      factory MixedAnyOf.fromSimple(String? value, {required bool explode}) {
        String? string;
        try {
          string = value.decodeSimpleString(context: r'MixedAnyOf');
        } on Object catch (_) {
          string = null;
        }

        if (string == null) {
          throw SimpleDecodingException(
            'Invalid simple value for MixedAnyOf: all variants failed to decode',
          );
        }
        return MixedAnyOf(list: null, list2: null, string: string);
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
    test('generates toSimple method with merge-or-equal algorithm', () {
      final modelA = ClassModel(
        description: null,
        name: 'A',
        properties: [
          Property(
            description: null,
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
        description: null,
        name: 'B',
        properties: [
          Property(
            description: null,
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
        description: null,
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
          final mapValues = <Map<String, String>>[];
          String? discriminatorValue;

          if (a != null) {
            final aSimple = a!.parameterProperties(allowEmpty: allowEmpty);
            mapValues.add(aSimple);
              discriminatorValue ??= r'a';
          }
          if (b != null) {
            final bSimple = b!.parameterProperties(allowEmpty: allowEmpty);
            mapValues.add(bSimple);
              discriminatorValue ??= r'b';
          }

          final map = <String, String>{};
          for (final m in mapValues) { map.addAll(m); }
          if (discriminatorValue != null) { 
            map.putIfAbsent('disc', () => discriminatorValue);
          }
          return map.toSimple(
            explode: explode, 
            allowEmpty: allowEmpty, 
            alreadyEncoded: true,
          );
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
          description: null,
          name: 'A',
          properties: [
            Property(
              description: null,
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
          description: null,
          name: 'B',
          properties: [
            Property(
              description: null,
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
          description: null,
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
            final mapValues = <Map<String, String>>[];

            if (a != null) {
              final aSimple = a!.parameterProperties(allowEmpty: allowEmpty);
              mapValues.add(aSimple);
            }
            if (b != null) {
              final bSimple = b!.parameterProperties(allowEmpty: allowEmpty);
              mapValues.add(bSimple);
            }

            final map = <String, String>{};
            for (final m in mapValues) { map.addAll(m); }
            return map.toSimple(
              explode: explode, 
              allowEmpty: allowEmpty, 
              alreadyEncoded: true,
            );
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
        description: null,
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
          final values = <String>{};
          if (bool != null) {
            final boolSimple = bool!.toSimple( explode: explode, allowEmpty: allowEmpty, );
            values.add(boolSimple);
          }
          if (int != null) {
            final intSimple = int!.toSimple(explode: explode, allowEmpty: allowEmpty);
            values.add(intSimple);
          }
          if (string != null) {
            final stringSimple = string!.toSimple( explode: explode, allowEmpty: allowEmpty, );
            values.add(stringSimple);
          }

          if (values.isEmpty) return '';

          if (values.length > 1) {
            throw EncodingException(
              'Ambiguous anyOf simple encoding for OnlyPrimitivesSimple: multiple values provided, anyOf requires exactly one value',
            );
          }
          return values.first;
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
          description: null,
          name: 'User',
          properties: [
            Property(
              description: null,
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
          description: null,
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
          if (user != null) {
            final userSimple = user!.parameterProperties(allowEmpty: allowEmpty);
            mapValues.add(userSimple);
            discriminatorValue ??= r'user';
          }

          if (values.isEmpty && mapValues.isEmpty) return '';
          if (mapValues.isNotEmpty && values.isNotEmpty) {
            throw EncodingException(
              'Ambiguous anyOf simple encoding for MixedSimple: mixing simple and complex values',
            );
          }
          if (values.isNotEmpty) {
            if (values.length > 1) {
              throw EncodingException(
                'Ambiguous anyOf simple encoding for MixedSimple: multiple values provided, anyOf requires exactly one value',
              );
            }
            return values.first;
          } else {
            final map = <String, String>{};
            for (final m in mapValues) { 
              map.addAll(m); 
            }
            if (discriminatorValue != null) { 
              map.putIfAbsent('disc', () => discriminatorValue);
            }
            return map.toSimple(
              explode: explode, 
              allowEmpty: allowEmpty, 
              alreadyEncoded: true,
            );
          }
        }
      ''';

        expect(
          collapseWhitespace(generated),
          contains(collapseWhitespace(expectedMethod)),
        );
      },
    );
  });
}
