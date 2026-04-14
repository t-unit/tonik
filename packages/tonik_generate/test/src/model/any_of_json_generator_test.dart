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

      const expectedMethod = r'''
      Object? toJson() {
        final _$values = <Object?>{};
        final _$mapValues = <Map<String, Object?>>[];
        String? _$discriminatorValue;

        if (a != null) {
          final Object? _$aJson = a!.toJson();
          if (_$aJson is Map<String, Object?>) {
            _$mapValues.add(_$aJson);
              _$discriminatorValue ??= r'a';
          } else {
            _$values.add(_$aJson);
          }
        }
        if (b != null) {
          final Object? _$bJson = b!.toJson();
          if (_$bJson is Map<String, Object?>) {
            _$mapValues.add(_$bJson);
              _$discriminatorValue ??= r'b';
          } else {
            _$values.add(_$bJson);
          }
        }

        if (_$values.isEmpty && _$mapValues.isEmpty) return null;

        if (_$values.isNotEmpty && _$mapValues.isNotEmpty) {
          throw EncodingException(
            r'Mixed encoding not supported for Payload: cannot encode both simple and complex values',
          );
        }

        if (_$values.isNotEmpty) {
          if (_$values.length > 1) {
            throw EncodingException(
              r'Ambiguous anyOf encoding for Payload: multiple values provided, anyOf requires exactly one value',
            );
          }
          return _$values.first;
        }

        if (_$mapValues.isNotEmpty) {
          final _$map = <String, Object?>{};
          for (final _$m in _$mapValues) {
            _$map.addAll(_$m);
          }
          final _$discValue = _$discriminatorValue;
          if (_$discValue != null) {
            _$map.putIfAbsent(r'disc', () => _$discValue);
          }
          return _$map;
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

      const expectedMethod = r'''
      Object? toJson() {
        final _$values = <Object?>{};
        final _$mapValues = <Map<String, Object?>>[];

        if (a != null) {
          final Object? _$aJson = a!.toJson();
          if (_$aJson is Map<String, Object?>) {
            _$mapValues.add(_$aJson);
          } else {
            _$values.add(_$aJson);
          }
        }
        if (b != null) {
          final Object? _$bJson = b!.toJson();
          if (_$bJson is Map<String, Object?>) {
            _$mapValues.add(_$bJson);
          } else {
            _$values.add(_$bJson);
          }
        }

        if (_$values.isEmpty && _$mapValues.isEmpty) return null;

        if (_$values.isNotEmpty && _$mapValues.isNotEmpty) {
          throw EncodingException(
            r'Mixed encoding not supported for PayloadNoDisc: cannot encode both simple and complex values',
          );
        }

        if (_$values.isNotEmpty) {
          if (_$values.length > 1) {
            throw EncodingException(
              r'Ambiguous anyOf encoding for PayloadNoDisc: multiple values provided, anyOf requires exactly one value',
            );
          }
          return _$values.first;
        }

        if (_$mapValues.isNotEmpty) {
          final _$map = <String, Object?>{};
          for (final _$m in _$mapValues) {
            _$map.addAll(_$m);
          }
          return _$map;
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

    const expectedMethod = r'''
      Object? toJson() {
        final _$values = <Object?>{};
        final _$mapValues = <Map<String, Object?>>[];
        String? _$discriminatorValue;

        if (bool != null) {
          final Object? _$boolJson = bool!;
          if (_$boolJson is Map<String, Object?>) {
            _$mapValues.add(_$boolJson);
          } else {
            _$values.add(_$boolJson);
          }
        }
        if (int != null) {
          final Object? _$intJson = int!;
          if (_$intJson is Map<String, Object?>) {
            _$mapValues.add(_$intJson);
          } else {
            _$values.add(_$intJson);
          }
        }
        if (string != null) {
          final Object? _$stringJson = string!;
          if (_$stringJson is Map<String, Object?>) {
            _$mapValues.add(_$stringJson);
          } else {
            _$values.add(_$stringJson);
          }
        }

        if (_$values.isEmpty && _$mapValues.isEmpty) return null;

        if (_$values.isNotEmpty && _$mapValues.isNotEmpty) {
          throw EncodingException(
            r'Mixed encoding not supported for OnlyPrimitives: cannot encode both simple and complex values',
          );
        }

        if (_$values.isNotEmpty) {
          if (_$values.length > 1) {
            throw EncodingException(
              r'Ambiguous anyOf encoding for OnlyPrimitives: multiple values provided, anyOf requires exactly one value',
            );
          }
          return _$values.first;
        }

        if (_$mapValues.isNotEmpty) {
          final _$map = <String, Object?>{};
          for (final _$m in _$mapValues) {
            _$map.addAll(_$m);
          }
          final _$discValue = _$discriminatorValue;
          if (_$discValue != null) {
            _$map.putIfAbsent(r'type', () => _$discValue);
          }
          return _$map;
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

      const expectedMethod = r'''
      Object? toJson() {
        final _$values = <Object?>{};
        final _$mapValues = <Map<String, Object?>>[];
        String? _$discriminatorValue;

        if (string != null) {
          final Object? _$stringJson = string!;
          if (_$stringJson is Map<String, Object?>) {
            _$mapValues.add(_$stringJson);
              _$discriminatorValue ??= r'str';
          } else {
            _$values.add(_$stringJson);
          }
        }
        if (user != null) {
          final Object? _$userJson = user!.toJson();
          if (_$userJson is Map<String, Object?>) {
            _$mapValues.add(_$userJson);
              _$discriminatorValue ??= r'user';
          } else {
            _$values.add(_$userJson);
          }
        }

        if (_$values.isEmpty && _$mapValues.isEmpty) return null;

        if (_$values.isNotEmpty && _$mapValues.isNotEmpty) {
          throw EncodingException(
            r'Mixed encoding not supported for Mixed: cannot encode both simple and complex values',
          );
        }

        if (_$values.isNotEmpty) {
          if (_$values.length > 1) {
            throw EncodingException(
              r'Ambiguous anyOf encoding for Mixed: multiple values provided, anyOf requires exactly one value',
            );
          }
          return _$values.first;
        }

        if (_$mapValues.isNotEmpty) {
          final _$map = <String, Object?>{};
          for (final _$m in _$mapValues) {
            _$map.addAll(_$m);
          }
          final _$discValue = _$discriminatorValue;
          if (_$discValue != null) {
            _$map.putIfAbsent(r'disc', () => _$discValue);
          }
          return _$map;
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
