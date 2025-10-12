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

  final format =
      DartFormatter(
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

  group('Method signatures', () {
    test('fromForm constructor has correct signature', () {
      final model = AnyOfModel(
        name: 'Test',
        models: {
          (discriminatorValue: null, model: StringModel(context: context)),
        },
        discriminator: null,
        context: context,
      );

      final klass = generator.generateClass(model);
      final fromFormConstructor = klass.constructors.firstWhere(
        (c) => c.name == 'fromForm',
      );

      expect(fromFormConstructor.factory, isTrue);
      expect(fromFormConstructor.requiredParameters.length, 1);
      expect(fromFormConstructor.requiredParameters[0].name, 'value');
      expect(
        fromFormConstructor.requiredParameters[0].type
            ?.accept(emitter)
            .toString(),
        'String?',
      );
      expect(fromFormConstructor.optionalParameters.length, 1);
      expect(fromFormConstructor.optionalParameters[0].name, 'explode');
      expect(
        fromFormConstructor.optionalParameters[0].type
            ?.accept(emitter)
            .toString(),
        'bool',
      );
      expect(fromFormConstructor.optionalParameters[0].required, isTrue);
    });

    test('toForm method has correct signature', () {
      final model = AnyOfModel(
        name: 'Test',
        models: {
          (discriminatorValue: null, model: StringModel(context: context)),
        },
        discriminator: null,
        context: context,
      );

      final klass = generator.generateClass(model);
      final toFormMethod = klass.methods.firstWhere(
        (m) => m.name == 'toForm',
      );

      expect(toFormMethod.returns?.accept(emitter).toString(), 'String');
      expect(toFormMethod.optionalParameters, hasLength(2));
      expect(
        toFormMethod.optionalParameters.map((p) => p.name),
        containsAll(['explode', 'allowEmpty']),
      );
      expect(
        toFormMethod.optionalParameters.every((p) => p.required),
        isTrue,
      );
    });

    test('formProperties method has correct signature', () {
      final model = AnyOfModel(
        name: 'Test',
        models: {
          (
            discriminatorValue: null,
            model: ClassModel(
              name: 'TestClass',
              properties: const [],
              context: context,
            ),
          ),
        },
        discriminator: null,
        context: context,
      );

      final klass = generator.generateClass(model);
      final formPropsMethod = klass.methods.firstWhere(
        (m) => m.name == 'formProperties',
      );

      expect(
        formPropsMethod.returns?.accept(emitter).toString(),
        'Map<String,String>',
      );
      expect(formPropsMethod.optionalParameters, hasLength(1));
      expect(formPropsMethod.optionalParameters.first.name, 'allowEmpty');
      expect(formPropsMethod.optionalParameters.first.required, isTrue);
    });

    test('currentEncodingShape getter has correct signature', () {
      final model = AnyOfModel(
        name: 'Test',
        models: {
          (discriminatorValue: null, model: StringModel(context: context)),
        },
        discriminator: null,
        context: context,
      );

      final klass = generator.generateClass(model);
      final getter = klass.methods.firstWhere(
        (m) => m.name == 'currentEncodingShape',
      );

      expect(getter.type, MethodType.getter);
      expect(
        getter.returns?.accept(emitter).toString(),
        'EncodingShape',
      );
    });
  });

  group('currentEncodingShape getter generation', () {
    test('primitive-only anyOf returns dynamic shape', () {
      final model = AnyOfModel(
        name: 'Flexible',
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

    test('complex-only anyOf returns dynamic shape', () {
      final classA = ClassModel(
        name: 'A',
        properties: const [],
        context: context,
      );
      final classB = ClassModel(
        name: 'B',
        properties: const [],
        context: context,
      );

      final model = AnyOfModel(
        name: 'Combined',
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
          if (a != null) {
            shapes.add(a!.currentEncodingShape);
          }
          if (b != null) {
            shapes.add(b!.currentEncodingShape);
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

    test('mixed primitive and complex anyOf returns dynamic shape', () {
      final classA = ClassModel(
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
        name: 'Flexible',
        models: {
          (discriminatorValue: null, model: StringModel(context: context)),
          (discriminatorValue: null, model: classA),
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

  group('fromForm constructor generation', () {
    test('primitive-only anyOf tries all variants independently', () {
      final model = AnyOfModel(
        name: 'Flexible',
        models: {
          (discriminatorValue: null, model: StringModel(context: context)),
          (discriminatorValue: null, model: IntegerModel(context: context)),
        },
        discriminator: null,
        context: context,
      );

      final klass = generator.generateClass(model);
      final generated = format(klass.accept(emitter).toString());

      const expectedMethod = '''
        factory Flexible.fromForm(String? value, {required bool explode}) {
          String? string;
          try {
            string = value.decodeFormString(context: r'Flexible');
          } on Object catch (_) {
            string = null;
          }

          int? int;
          try {
            int = value.decodeFormInt(context: r'Flexible');
          } on Object catch (_) {
            int = null;
          }

          return Flexible(string: string, int: int);
        }
      ''';

      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('complex-only anyOf tries all variants', () {
      final classA = ClassModel(
        name: 'A',
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

      final classB = ClassModel(
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
        name: 'Choice',
        models: {
          (discriminatorValue: null, model: classA),
          (discriminatorValue: null, model: classB),
        },
        discriminator: null,
        context: context,
      );

      final klass = generator.generateClass(model);
      final generated = format(klass.accept(emitter).toString());

      const expectedMethod = '''
        factory Choice.fromForm(String? value, {required bool explode}) {
          A? a;
          try {
            a = A.fromForm(value, explode: explode);
          } on Object catch (_) {
            a = null;
          }

          B? b;
          try {
            b = B.fromForm(value, explode: explode);
          } on Object catch (_) {
            b = null;
          }

          return Choice(a: a, b: b);
        }
      ''';

      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('mixed primitive and complex tries all', () {
      final classA = ClassModel(
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
        name: 'SearchKey',
        models: {
          (discriminatorValue: null, model: StringModel(context: context)),
          (discriminatorValue: null, model: classA),
        },
        discriminator: null,
        context: context,
      );

      final klass = generator.generateClass(model);
      final generated = format(klass.accept(emitter).toString());

      const expectedMethod = '''
        factory SearchKey.fromForm(String? value, {required bool explode}) {
          String? string;
          try {
            string = value.decodeFormString(context: r'SearchKey');
          } on Object catch (_) {
            string = null;
          }

          User? user;
          try {
            user = User.fromForm(value, explode: explode);
          } on Object catch (_) {
            user = null;
          }

          return SearchKey(string: string, user: user);
        }
      ''';

      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedMethod)),
      );
    });
  });

  group('toForm method generation', () {
    test('primitive-only anyOf encodes each field to form', () {
      final model = AnyOfModel(
        name: 'Simple',
        models: {
          (discriminatorValue: null, model: StringModel(context: context)),
          (discriminatorValue: null, model: IntegerModel(context: context)),
        },
        discriminator: null,
        context: context,
      );

      final klass = generator.generateClass(model);
      final generated = format(klass.accept(emitter).toString());

      const expectedMethod = '''
        String toForm({required bool explode, required bool allowEmpty}) {
          final values = <String>{};
          if (string != null) {
            final stringForm = string!.toForm(
              explode: explode,
              allowEmpty: allowEmpty,
            );
            values.add(stringForm);
          }
          if (int != null) {
            final intForm = int!.toForm(explode: explode, allowEmpty: allowEmpty);
            values.add(intForm);
          }
          if (values.isEmpty) return '';
          if (values.length > 1) {
            throw EncodingException(
              'Ambiguous anyOf form encoding for Simple: multiple values provided, anyOf requires exactly one value',
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

    test('complex-only anyOf merges formProperties', () {
      final classA = ClassModel(
        name: 'A',
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
        name: 'Wrapper',
        models: {
          (discriminatorValue: null, model: classA),
        },
        discriminator: null,
        context: context,
      );

      final klass = generator.generateClass(model);
      final generated = format(klass.accept(emitter).toString());

      const expectedMethod = '''
        String toForm({required bool explode, required bool allowEmpty}) {
          final mapValues = <Map<String, String>>[];
          if (a != null) {
            final aForm = a!.formProperties(allowEmpty: allowEmpty);
            mapValues.add(aForm);
          }
          final map = <String, String>{};
          for (final m in mapValues) { map.addAll(m); }
          return map.toForm(
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

    test('multiple complex fields merge with discriminator', () {
      final classA = ClassModel(
        name: 'A',
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

      final classB = ClassModel(
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
        name: 'Combined',
        models: {
          (discriminatorValue: 'a', model: classA),
          (discriminatorValue: 'b', model: classB),
        },
        discriminator: 'type',
        context: context,
      );

      final klass = generator.generateClass(model);
      final generated = format(klass.accept(emitter).toString());

      const expectedMethod = '''
        String toForm({required bool explode, required bool allowEmpty}) {
          final mapValues = <Map<String, String>>[];
          String? discriminatorValue;
          if (a != null) {
            final aForm = a!.formProperties(allowEmpty: allowEmpty);
            mapValues.add(aForm);
            discriminatorValue ??= 'a';
          }
          if (b != null) {
            final bForm = b!.formProperties(allowEmpty: allowEmpty);
            mapValues.add(bForm);
            discriminatorValue ??= 'b';
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

      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('mixed primitive and complex checks for ambiguity', () {
      final classA = ClassModel(
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
        name: 'Mixed',
        models: {
          (discriminatorValue: null, model: StringModel(context: context)),
          (discriminatorValue: null, model: classA),
        },
        discriminator: null,
        context: context,
      );

      final klass = generator.generateClass(model);
      final generated = format(klass.accept(emitter).toString());

      const expectedMethod = '''
        String toForm({required bool explode, required bool allowEmpty}) {
          final values = <String>{};
          final mapValues = <Map<String, String>>[];
          
          if (string != null) {
            final stringForm = string!.toForm(
              explode: explode,
              allowEmpty: allowEmpty,
            );
            values.add(stringForm);
          }

          if (data != null) {
            final dataForm = data!.formProperties(allowEmpty: allowEmpty);
            mapValues.add(dataForm);
          }
          
          if (values.isEmpty && mapValues.isEmpty) return '';
          if (mapValues.isNotEmpty && values.isNotEmpty) {
            throw EncodingException(
              'Ambiguous anyOf form encoding for Mixed: mixing simple and complex values',
            );
          }
          
          if (values.isNotEmpty) {
            if (values.length > 1) {
              throw EncodingException(
                'Ambiguous anyOf form encoding for Mixed: multiple values provided, anyOf requires exactly one value',
              );
            }
            return values.first;
          } else {
            final map = <String, String>{};
            for (final m in mapValues) { 
              map.addAll(m); 
            }
            return map.toForm(
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
    });
  });

  group('formProperties method generation', () {
    test('complex-only anyOf merges formProperties from all fields', () {
      final classA = ClassModel(
        name: 'A',
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

      final classB = ClassModel(
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
        name: 'Combined',
        models: {
          (discriminatorValue: null, model: classA),
          (discriminatorValue: null, model: classB),
        },
        discriminator: null,
        context: context,
      );

      final klass = generator.generateClass(model);
      final generated = format(klass.accept(emitter).toString());

      const expectedMethod = '''
        Map<String, String> formProperties({required bool allowEmpty}) {
          final maps = <Map<String, String>>[];
          if (a != null) {
          final aForm = a!.formProperties(allowEmpty: allowEmpty);
          maps.add(aForm);
          }
          if (b != null) {
          final bForm = b!.formProperties(allowEmpty: allowEmpty);
          maps.add(bForm);
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

    test('primitive-only anyOf returns empty map', () {
      final model = AnyOfModel(
        name: 'PrimitiveOnly',
        models: {
          (discriminatorValue: null, model: StringModel(context: context)),
          (discriminatorValue: null, model: IntegerModel(context: context)),
        },
        discriminator: null,
        context: context,
      );

      final klass = generator.generateClass(model);
      final generated = format(klass.accept(emitter).toString());

      const expectedMethod = '''
        Map<String, String> formProperties({required bool allowEmpty}) {
          return <String, String>{};
        }
      ''';

      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('mixed primitive and complex skips primitive fields', () {
      final classA = ClassModel(
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
        name: 'Mixed',
        models: {
          (discriminatorValue: null, model: StringModel(context: context)),
          (discriminatorValue: null, model: classA),
        },
        discriminator: null,
        context: context,
      );

      final klass = generator.generateClass(model);
      final generated = format(klass.accept(emitter).toString());

      const expectedMethod = '''
        Map<String, String> formProperties({required bool allowEmpty}) {
          final maps = <Map<String, String>>[];
          if (data != null) {
          final dataForm = data!.formProperties(allowEmpty: allowEmpty);
          maps.add(dataForm);
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

    test('complex anyOf with discriminator injects discriminator value', () {
      final classA = ClassModel(
        name: 'A',
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

      final classB = ClassModel(
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
        name: 'WithDisc',
        models: {
          (discriminatorValue: 'a', model: classA),
          (discriminatorValue: 'b', model: classB),
        },
        discriminator: 'type',
        context: context,
      );

      final klass = generator.generateClass(model);
      final generated = format(klass.accept(emitter).toString());

      const expectedMethod = '''
        Map<String, String> formProperties({required bool allowEmpty}) {
          final maps = <Map<String, String>>[];
          String? discriminatorValue;
          if (a != null) {
          final aForm = a!.formProperties(allowEmpty: allowEmpty);
          maps.add(aForm);
            discriminatorValue ??= 'a';
          }
          if (b != null) {
          final bForm = b!.formProperties(allowEmpty: allowEmpty);
          maps.add(bForm);
            discriminatorValue ??= 'b';
          }
          if (maps.isEmpty) return <String, String>{};
          final map = <String, String>{};
          for (final m in maps) {
            map.addAll(m);
          }
          if (discriminatorValue != null) {
            map.putIfAbsent('type', () => discriminatorValue);
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

  group('Edge cases', () {
    test('nested anyOf properly delegates to inner fromForm', () {
      final innerAnyOf = AnyOfModel(
        name: 'Inner',
        models: {
          (discriminatorValue: null, model: StringModel(context: context)),
          (discriminatorValue: null, model: IntegerModel(context: context)),
        },
        discriminator: null,
        context: context,
      );

      final model = AnyOfModel(
        name: 'Outer',
        models: {
          (discriminatorValue: null, model: StringModel(context: context)),
          (discriminatorValue: null, model: innerAnyOf),
        },
        discriminator: null,
        context: context,
      );

      final klass = generator.generateClass(model);
      final generated = format(klass.accept(emitter).toString());

      const expectedMethod = '''
        factory Outer.fromForm(String? value, {required bool explode}) {
          String? string;
          try {
            string = value.decodeFormString(context: r'Outer');
          } on Object catch (_) {
            string = null;
          }

          Inner? inner;
          try {
            inner = Inner.fromForm(value, explode: explode);
          } on Object catch (_) {
            inner = null;
          }

          return Outer(string: string, inner: inner);
        }
      ''';

      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedMethod)),
      );
    });
  });

  group('Runtime shape checking', () {
    group('toForm method', () {
      test('uses runtime check for nested oneOf with dynamic shape', () {
        final innerOneOf = OneOfModel(
          name: 'InnerChoice',
          models: {
            (
              discriminatorValue: 'str',
              model: StringModel(context: context),
            ),
            (
              discriminatorValue: 'obj',
              model: ClassModel(
                name: 'Inner',
                properties: [
                  Property(
                    name: 'field',
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

        final model = AnyOfModel(
          name: 'TestAnyOf',
          models: {
            (discriminatorValue: null, model: StringModel(context: context)),
            (discriminatorValue: null, model: innerOneOf),
          },
          discriminator: null,
          context: context,
        );

        final klass = generator.generateClass(model);
        final generated = format(klass.accept(emitter).toString());

        const expected = '''
          String toForm({required bool explode, required bool allowEmpty}) {
            final values = <String>{};
            final mapValues = <Map<String, String>>[];
            if (string != null) {
              final stringForm = string!.toForm(
                explode: explode,
                allowEmpty: allowEmpty,
              );
              values.add(stringForm);
            }
            if (innerChoice != null) {
              switch (innerChoice!.currentEncodingShape) {
              case EncodingShape.simple:
                values.add(
                  innerChoice!.toForm(explode: explode, allowEmpty: allowEmpty),
                );
                break;
                case EncodingShape.complex:
                  final innerChoiceForm = innerChoice!.formProperties(
                    allowEmpty: allowEmpty,
                  );
                  mapValues.add(innerChoiceForm);
                  break;
                case EncodingShape.mixed:
                  throw EncodingException(
                    'Cannot encode field with mixed encoding shape',
                  );
              }
            }
            if (values.isEmpty && mapValues.isEmpty) return '';
            if (mapValues.isNotEmpty && values.isNotEmpty) {
              throw EncodingException(
                'Ambiguous anyOf form encoding for TestAnyOf: mixing simple and complex values',
              );
            }
            if (values.isNotEmpty) {
              if (values.length > 1) {
                throw EncodingException(
                  'Ambiguous anyOf form encoding for TestAnyOf: multiple values provided, anyOf requires exactly one value',
                );
              }
              return values.first;
            } else {
              final map = <String, String>{};
              for (final m in mapValues) { 
                map.addAll(m); 
              }
              return map.toForm(
                explode: explode,
                allowEmpty: allowEmpty,
                alreadyEncoded: true,
              );
            }
          }
        ''';

        expect(
          collapseWhitespace(generated),
          contains(collapseWhitespace(expected)),
        );
      });

      test('uses runtime check for nested anyOf', () {
        final innerAnyOf = AnyOfModel(
          name: 'InnerAnyOf',
          models: {
            (discriminatorValue: null, model: IntegerModel(context: context)),
            (
              discriminatorValue: null,
              model: ClassModel(
                name: 'Inner',
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
          discriminator: null,
          context: context,
        );

        final model = AnyOfModel(
          name: 'TestAnyOf',
          models: {
            (discriminatorValue: null, model: StringModel(context: context)),
            (discriminatorValue: null, model: innerAnyOf),
          },
          discriminator: null,
          context: context,
        );

        final klass = generator.generateClass(model);
        final generated = format(klass.accept(emitter).toString());

        const expected = '''
          if (innerAnyOf != null) {
            switch (innerAnyOf!.currentEncodingShape) {
              case EncodingShape.simple:
                values.add(
                  innerAnyOf!.toForm(explode: explode, allowEmpty: allowEmpty),
                );
                break;
              case EncodingShape.complex:
                final innerAnyOfForm = innerAnyOf!.formProperties(
                  allowEmpty: allowEmpty,
                );
                mapValues.add(innerAnyOfForm);
                break;
              case EncodingShape.mixed:
                throw EncodingException(
                  'Cannot encode field with mixed encoding shape',
                );
            }
          }
        ''';

        expect(
          collapseWhitespace(generated),
          contains(collapseWhitespace(expected)),
        );
      });

      test('uses direct calls for static types without runtime checks', () {
        final model = AnyOfModel(
          name: 'TestAnyOf',
          models: {
            (discriminatorValue: null, model: StringModel(context: context)),
            (discriminatorValue: null, model: IntegerModel(context: context)),
            (
              discriminatorValue: null,
              model: ClassModel(
                name: 'MyClass',
                properties: [
                  Property(
                    name: 'field',
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
          discriminator: null,
          context: context,
        );

        final klass = generator.generateClass(model);
        final generated = format(klass.accept(emitter).toString());

        const expected = '''
          String toForm({required bool explode, required bool allowEmpty}) {
            final values = <String>{};
            final mapValues = <Map<String, String>>[];
            if (string != null) {
              final stringForm = string!.toForm(
                explode: explode,
                allowEmpty: allowEmpty,
              );
              values.add(stringForm);
            }
            if (int != null) {
              final intForm = int!.toForm(explode: explode, allowEmpty: allowEmpty);
              values.add(intForm);
            }
            if (myClass != null) {
              final myClassForm = myClass!.formProperties(allowEmpty: allowEmpty);
              mapValues.add(myClassForm);
            }
            if (values.isEmpty && mapValues.isEmpty) return '';
            if (mapValues.isNotEmpty && values.isNotEmpty) {
              throw EncodingException(
                'Ambiguous anyOf form encoding for TestAnyOf: mixing simple and complex values',
              );
            }
            if (values.isNotEmpty) {
              if (values.length > 1) {
                throw EncodingException(
                  'Ambiguous anyOf form encoding for TestAnyOf: multiple values provided, anyOf requires exactly one value',
                );
              }
              return values.first;
            } else {
              final map = <String, String>{};
              for (final m in mapValues) { 
                map.addAll(m); 
              }
              return map.toForm(
                explode: explode,
                allowEmpty: allowEmpty,
                alreadyEncoded: true,
              );
            }
          }
        ''';

        expect(
          collapseWhitespace(generated),
          contains(collapseWhitespace(expected)),
        );
      });

      test('handles mixed shape with exception in switch', () {
        final innerOneOf = OneOfModel(
          name: 'InnerChoice',
          models: {
            (discriminatorValue: 'a', model: StringModel(context: context)),
            (discriminatorValue: 'b', model: IntegerModel(context: context)),
          },
          discriminator: 'type',
          context: context,
        );

        final model = AnyOfModel(
          name: 'TestAnyOf',
          models: {
            (discriminatorValue: null, model: innerOneOf),
          },
          discriminator: null,
          context: context,
        );

        final klass = generator.generateClass(model);
        final generated = format(klass.accept(emitter).toString());

        const expected = '''
          case EncodingShape.mixed:
            throw EncodingException(
              'Cannot encode field with mixed encoding shape',
            );
        ''';

        expect(
          collapseWhitespace(generated),
          contains(collapseWhitespace(expected)),
        );
      });
    });

    group('toSimple method', () {
      test('uses runtime check for nested oneOf', () {
        final innerOneOf = OneOfModel(
          name: 'InnerChoice',
          models: {
            (discriminatorValue: 'str', model: StringModel(context: context)),
            (
              discriminatorValue: 'obj',
              model: ClassModel(
                name: 'Inner',
                properties: [
                  Property(
                    name: 'field',
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

        final model = AnyOfModel(
          name: 'TestAnyOf',
          models: {
            (discriminatorValue: null, model: StringModel(context: context)),
            (discriminatorValue: null, model: innerOneOf),
          },
          discriminator: null,
          context: context,
        );

        final klass = generator.generateClass(model);
        final generated = format(klass.accept(emitter).toString());

        const expected = '''
          if (innerChoice != null) {
            switch (innerChoice!.currentEncodingShape) {
              case EncodingShape.simple:
                values.add(
                  innerChoice!.toSimple(explode: explode, allowEmpty: allowEmpty),
                );
                break;
              case EncodingShape.complex:
                final innerChoiceSimple = innerChoice!.simpleProperties(
                  allowEmpty: allowEmpty,
                );
                mapValues.add(innerChoiceSimple);
                break;
              case EncodingShape.mixed:
                throw EncodingException(
                  'Cannot encode field with mixed encoding shape',
                );
            }
          }
        ''';

        expect(
          collapseWhitespace(generated),
          contains(collapseWhitespace(expected)),
        );
      });

      test('uses direct calls for static types', () {
        final model = AnyOfModel(
          name: 'TestAnyOf',
          models: {
            (discriminatorValue: null, model: StringModel(context: context)),
            (discriminatorValue: null, model: IntegerModel(context: context)),
          },
          discriminator: null,
          context: context,
        );

        final klass = generator.generateClass(model);
        final generated = format(klass.accept(emitter).toString());

        const expected = '''
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
        ''';

        expect(
          collapseWhitespace(generated),
          contains(collapseWhitespace(expected)),
        );
      });
    });

    group('formProperties method', () {
      test('checks complex at runtime for nested oneOf', () {
        final innerOneOf = OneOfModel(
          name: 'InnerChoice',
          models: {
            (discriminatorValue: 'str', model: StringModel(context: context)),
            (
              discriminatorValue: 'obj',
              model: ClassModel(
                name: 'Inner',
                properties: [
                  Property(
                    name: 'field',
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

        final model = AnyOfModel(
          name: 'TestAnyOf',
          models: {
            (discriminatorValue: null, model: innerOneOf),
          },
          discriminator: null,
          context: context,
        );

        final klass = generator.generateClass(model);
        final generated = format(klass.accept(emitter).toString());

        const expected = '''
          Map<String, String> formProperties({required bool allowEmpty}) {
            final maps = <Map<String, String>>[];
            if (innerChoice != null &&
                innerChoice!.currentEncodingShape == EncodingShape.complex) {
              final innerChoiceForm = innerChoice!.formProperties(
                allowEmpty: allowEmpty,
              );
              maps.add(innerChoiceForm);
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
          contains(collapseWhitespace(expected)),
        );
      });

      test('skips runtime check for static complex types', () {
        final model = AnyOfModel(
          name: 'TestAnyOf',
          models: {
            (
              discriminatorValue: null,
              model: ClassModel(
                name: 'MyClass',
                properties: [
                  Property(
                    name: 'field',
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
          discriminator: null,
          context: context,
        );

        final klass = generator.generateClass(model);
        final generated = format(klass.accept(emitter).toString());

        const expected = '''
          Map<String, String> formProperties({required bool allowEmpty}) {
            final maps = <Map<String, String>>[];
            if (myClass != null) {
            final myClassForm = myClass!.formProperties(allowEmpty: allowEmpty);
            maps.add(myClassForm);
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
          contains(collapseWhitespace(expected)),
        );
      });
    });

    group('simpleProperties method', () {
      test('checks complex at runtime for nested anyOf', () {
        final innerAnyOf = AnyOfModel(
          name: 'InnerAnyOf',
          models: {
            (discriminatorValue: null, model: StringModel(context: context)),
            (
              discriminatorValue: null,
              model: ClassModel(
                name: 'Inner',
                properties: [
                  Property(
                    name: 'field',
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
          discriminator: null,
          context: context,
        );

        final model = AnyOfModel(
          name: 'TestAnyOf',
          models: {
            (discriminatorValue: null, model: innerAnyOf),
          },
          discriminator: null,
          context: context,
        );

        final klass = generator.generateClass(model);
        final generated = format(klass.accept(emitter).toString());

        const expected = '''
          Map<String, String> simpleProperties({required bool allowEmpty}) {
            final maps = <Map<String, String>>[];
            if (innerAnyOf != null &&
                innerAnyOf!.currentEncodingShape == EncodingShape.complex) {
              final Map<String, String> innerAnyOfSimple = innerAnyOf!.simpleProperties(
                allowEmpty: allowEmpty,
              );
              maps.add(innerAnyOfSimple);
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
          contains(collapseWhitespace(expected)),
        );
      });
    });
  });
}
