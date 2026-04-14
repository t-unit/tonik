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
    nameManager = NameManager(
      generator: nameGenerator,
      stableModelSorter: StableModelSorter(),
    );
    generator = AnyOfGenerator(
      nameManager: nameManager,
      package: 'example',
      stableModelSorter: StableModelSorter(),
    );
    context = Context.initial();
    emitter = DartEmitter(useNullSafetySyntax: true);
  });

  group('fromSimple', () {
    test(
      'generates fromSimple factory that wraps each property decode in try/catch and assigns null on failure',
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

        final format = DartFormatter(
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
                r'Invalid simple value for Flexible: all variants failed to decode',
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
          isDeprecated: false,
          name: 'ClassA',
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

        final classB = ClassModel(
          isDeprecated: false,
          name: 'ClassB',
          properties: [
            Property(
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
          isDeprecated: false,
          name: 'MixedAnyOf',
          models: {
            (discriminatorValue: null, model: listA),
            (discriminatorValue: null, model: listB),
            (discriminatorValue: null, model: StringModel(context: context)),
          },
          context: context,
        );

        final klass = generator.generateClass(model);

        final format = DartFormatter(
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
            r'Invalid simple value for MixedAnyOf: all variants failed to decode',
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
        name: 'PayloadSimple',
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

      const expectedMethod = r'''
        String toSimple({required bool explode, required bool allowEmpty}) {
          final _$mapValues = <Map<String, String>>[];
          String? _$discriminatorValue;

          if (a != null) {
            final _$aSimple = a!.parameterProperties(allowEmpty: allowEmpty);
            _$mapValues.add(_$aSimple);
              _$discriminatorValue ??= r'a';
          }
          if (b != null) {
            final _$bSimple = b!.parameterProperties(allowEmpty: allowEmpty);
            _$mapValues.add(_$bSimple);
              _$discriminatorValue ??= r'b';
          }

          final _$map = <String, String>{};
          for (final _$m in _$mapValues) { _$map.addAll(_$m); }
          final _$discValue = _$discriminatorValue;
          if (_$discValue != null) {
            _$map.putIfAbsent(r'disc', () => _$discValue);
          }
          return _$map.toSimple(
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
          name: 'PayloadSimpleNoDisc',
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

        const expectedMethod = r'''
          String toSimple({required bool explode, required bool allowEmpty}) {
            final _$mapValues = <Map<String, String>>[];

            if (a != null) {
              final _$aSimple = a!.parameterProperties(allowEmpty: allowEmpty);
              _$mapValues.add(_$aSimple);
            }
            if (b != null) {
              final _$bSimple = b!.parameterProperties(allowEmpty: allowEmpty);
              _$mapValues.add(_$bSimple);
            }

            final _$map = <String, String>{};
            for (final _$m in _$mapValues) { _$map.addAll(_$m); }
            return _$map.toSimple(
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
        isDeprecated: false,
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
      final format = DartFormatter(
        languageVersion: DartFormatter.latestLanguageVersion,
      ).format;
      final generated = format(klass.accept(emitter).toString());

      const expectedMethod = r'''
        String toSimple({required bool explode, required bool allowEmpty}) {
          final _$values = <String>{};
          if (bool != null) {
            final _$boolSimple = bool!.toSimple( explode: explode, allowEmpty: allowEmpty, );
            _$values.add(_$boolSimple);
          }
          if (int != null) {
            final _$intSimple = int!.toSimple(
              explode: explode,
              allowEmpty: allowEmpty,
            );
            _$values.add(_$intSimple);
          }
          if (string != null) {
            final _$stringSimple = string!.toSimple( explode: explode, allowEmpty: allowEmpty, );
            _$values.add(_$stringSimple);
          }

          if (_$values.isEmpty) return '';

          if (_$values.length > 1) {
            throw EncodingException(
              r'Ambiguous anyOf simple encoding for OnlyPrimitivesSimple: multiple values provided, anyOf requires exactly one value',
            );
          }
          return _$values.first;
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
          name: 'MixedSimple',
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

        const expectedMethod = r'''
        String toSimple({required bool explode, required bool allowEmpty}) {
          final _$values = <String>{};
          final _$mapValues = <Map<String, String>>[];
          String? _$discriminatorValue;

          if (string != null) {
            final _$stringSimple = string!.toSimple(
              explode: explode,
              allowEmpty: allowEmpty,
            );
            _$values.add(_$stringSimple);
          }
          if (user != null) {
            final _$userSimple = user!.parameterProperties(allowEmpty: allowEmpty);
            _$mapValues.add(_$userSimple);
            _$discriminatorValue ??= r'user';
          }

          if (_$values.isEmpty && _$mapValues.isEmpty) return '';
          if (_$mapValues.isNotEmpty && _$values.isNotEmpty) {
            throw EncodingException(
              r'Ambiguous anyOf simple encoding for MixedSimple: mixing simple and complex values',
            );
          }
          if (_$values.isNotEmpty) {
            if (_$values.length > 1) {
              throw EncodingException(
                r'Ambiguous anyOf simple encoding for MixedSimple: multiple values provided, anyOf requires exactly one value',
              );
            }
            return _$values.first;
          } else {
            final _$map = <String, String>{};
            for (final _$m in _$mapValues) {
              _$map.addAll(_$m);
            }
            final _$discValue = _$discriminatorValue;
            if (_$discValue != null) {
              _$map.putIfAbsent(r'disc', () => _$discValue);
            }
            return _$map.toSimple(
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

  group('BinaryModel field encoding', () {
    test('throws EncodingException for BinaryModel field in toSimple', () {
      final fmt = DartFormatter(
        languageVersion: DartFormatter.latestLanguageVersion,
      ).format;
      final model = AnyOfModel(
        isDeprecated: false,
        name: 'WithBinary',
        models: {
          (discriminatorValue: null, model: BinaryModel(context: context)),
          (discriminatorValue: null, model: StringModel(context: context)),
        },
        context: context,
      );

      final klass = generator.generateClass(model);
      final generated = fmt(klass.accept(emitter).toString());

      expect(
        generated,
        contains(
          "throw EncodingException('Binary data cannot be simple-encoded')",
        ),
      );
    });
  });
}
