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
  final format = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  ).format;

  setUp(() {
    nameGenerator = NameGenerator();
    nameManager = NameManager(
      generator: nameGenerator,
      stableModelSorter: StableModelSorter(),
    );
    generator = AnyOfGenerator(
      nameManager: nameManager,
      package: 'package:example',
      stableModelSorter: StableModelSorter(),
    );
    context = Context.initial();
    emitter = DartEmitter(useNullSafetySyntax: true);
  });

  group('AnyOfGenerator toMatrix generation', () {
    test('generates toMatrix method with correct signature', () {
      final model = AnyOfModel(
        isDeprecated: false,
        name: 'AnyOfPrimitive',
        models: {
          (discriminatorValue: 'string', model: StringModel(context: context)),
          (discriminatorValue: 'int', model: IntegerModel(context: context)),
        },
        context: context,
      );

      final generatedClass = generator.generateClass(model);
      final toMatrixMethod = generatedClass.methods.firstWhere(
        (m) => m.name == 'toMatrix',
      );

      expect(toMatrixMethod.returns?.accept(emitter).toString(), 'String');
      expect(toMatrixMethod.requiredParameters.length, 1);
      expect(toMatrixMethod.requiredParameters.first.name, 'paramName');
      expect(
        toMatrixMethod.requiredParameters.first.type
            ?.accept(emitter)
            .toString(),
        'String',
      );
      expect(toMatrixMethod.optionalParameters.length, 2);
      expect(
        toMatrixMethod.optionalParameters.map((p) => p.name),
        containsAll(['explode', 'allowEmpty']),
      );
    });

    test('generates toMatrix for primitive-only AnyOf', () {
      final model = AnyOfModel(
        isDeprecated: false,
        name: 'AnyOfPrimitive',
        models: {
          (discriminatorValue: 'string', model: StringModel(context: context)),
          (discriminatorValue: 'int', model: IntegerModel(context: context)),
          (discriminatorValue: 'bool', model: BooleanModel(context: context)),
        },
        context: context,
      );

      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());

      const expectedMethod = r'''
        String toMatrix(
          String paramName, {
          required bool explode,
          required bool allowEmpty,
        }) {
          final _$values = <String>{};
          if (bool != null) {
            final _$boolMatrix = bool!.toMatrix(
              paramName,
              explode: explode,
              allowEmpty: allowEmpty,
            );
            _$values.add(_$boolMatrix);
          }
          if (int != null) {
            final _$intMatrix = int!.toMatrix(
              paramName,
              explode: explode,
              allowEmpty: allowEmpty,
            );
            _$values.add(_$intMatrix);
          }
          if (string != null) {
            final _$stringMatrix = string!.toMatrix(
              paramName,
              explode: explode,
              allowEmpty: allowEmpty,
            );
            _$values.add(_$stringMatrix);
          }
          if (_$values.isEmpty) return '';
          if (_$values.length > 1) {
            throw EncodingException(
              r'Ambiguous anyOf matrix encoding for AnyOfPrimitive: multiple values provided, anyOf requires exactly one value',
            );
          }
          return _$values.first;
        }
      ''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('generates toMatrix for complex-only AnyOf', () {
      final class1 = ClassModel(
        isDeprecated: false,
        name: 'Class1',
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

      final class2 = ClassModel(
        isDeprecated: false,
        name: 'Class2',
        properties: [
          Property(
            name: 'number',
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
        name: 'AnyOfComplex',
        models: {
          (discriminatorValue: 'class1', model: class1),
          (discriminatorValue: 'class2', model: class2),
        },
        discriminator: 'type',
        context: context,
      );

      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());

      const expectedMethod = r'''
        String toMatrix(
          String paramName, {
          required bool explode,
          required bool allowEmpty,
        }) {
          final _$mapValues = <Map<String, String>>[];
          String? _$discriminatorValue;
          if (class1 != null) {
            final _$class1Matrix = class1!.parameterProperties(
              allowEmpty: allowEmpty,
            );
            _$mapValues.add(_$class1Matrix);
            _$discriminatorValue ??= r'class1';
          }
          if (class2 != null) {
            final _$class2Matrix = class2!.parameterProperties(
              allowEmpty: allowEmpty,
            );
            _$mapValues.add(_$class2Matrix);
            _$discriminatorValue ??= r'class2';
          }
          final _$map = <String, String>{};
          for (final _$m in _$mapValues) {
            _$map.addAll(_$m);
          }
          final _$discValue = _$discriminatorValue;
          if (_$discValue != null) {
            _$map.putIfAbsent('type', () => _$discValue);
          }
          return _$map.toMatrix(
            paramName,
            explode: explode,
            allowEmpty: allowEmpty,
            alreadyEncoded: true,
          );
        }
      ''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test(
      'generates toMatrix for mixed AnyOf that throws on ambiguous encoding',
      () {
        final model = AnyOfModel(
          isDeprecated: false,
          name: 'AnyOfMixed',
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
          discriminator: 'type',
          context: context,
        );

        final generatedClass = generator.generateClass(model);
        final classCode = format(generatedClass.accept(emitter).toString());

        const expectedMethod = r'''
        String toMatrix(
          String paramName, {
          required bool explode,
          required bool allowEmpty,
        }) {
          final _$values = <String>{};
          final _$mapValues = <Map<String, String>>[];
          String? _$discriminatorValue;
          if (data != null) {
            final _$dataMatrix = data!.parameterProperties(allowEmpty: allowEmpty);
            _$mapValues.add(_$dataMatrix);
            _$discriminatorValue ??= r'data';
          }
          if (string != null) {
            final _$stringMatrix = string!.toMatrix(
              paramName,
              explode: explode,
              allowEmpty: allowEmpty,
            );
            _$values.add(_$stringMatrix);
          }
          if (_$values.isEmpty && _$mapValues.isEmpty) return '';
          if (_$mapValues.isNotEmpty && _$values.isNotEmpty) {
            throw EncodingException(
              r'Ambiguous anyOf matrix encoding for AnyOfMixed: mixing simple and complex values',
            );
          }
          if (_$values.isNotEmpty) {
            if (_$values.length > 1) {
              throw EncodingException(
                r'Ambiguous anyOf matrix encoding for AnyOfMixed: multiple values provided, anyOf requires exactly one value',
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
              _$map.putIfAbsent('type', () => _$discValue);
            }
            return _$map.toMatrix(
              paramName,
              explode: explode,
              allowEmpty: allowEmpty,
              alreadyEncoded: true,
            );
          }
        }
      ''';

        expect(
          collapseWhitespace(classCode),
          contains(collapseWhitespace(expectedMethod)),
        );
      },
    );

    test('generates toMatrix for AnyOf with enum variants', () {
      final enumModel = EnumModel(
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
        name: 'AnyOfEnum',
        models: {
          (discriminatorValue: 'status', model: enumModel),
          (discriminatorValue: 'string', model: StringModel(context: context)),
        },
        context: context,
      );

      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());

      const expectedMethod = r'''
        String toMatrix(
          String paramName, {
          required bool explode,
          required bool allowEmpty,
        }) {
          final _$values = <String>{};
          if (status != null) {
            final _$statusMatrix = status!.toMatrix(
              paramName,
              explode: explode,
              allowEmpty: allowEmpty,
            );
            _$values.add(_$statusMatrix);
          }
          if (string != null) {
            final _$stringMatrix = string!.toMatrix(
              paramName,
              explode: explode,
              allowEmpty: allowEmpty,
            );
            _$values.add(_$stringMatrix);
          }
          if (_$values.isEmpty) return '';
          if (_$values.length > 1) {
            throw EncodingException(
              r'Ambiguous anyOf matrix encoding for AnyOfEnum: multiple values provided, anyOf requires exactly one value',
            );
          }
          return _$values.first;
        }
      ''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('generates toMatrix for empty AnyOf', () {
      final model = AnyOfModel(
        isDeprecated: false,
        name: 'AnyOfEmpty',
        models: const {},
        context: context,
      );

      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());

      const expectedMethod = '''
        String toMatrix(
          String paramName, {
          required bool explode,
          required bool allowEmpty,
        }) {
          return '';
        }
      ''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('generates toMatrix for AnyOf with nested composition types', () {
      final oneOfModel = OneOfModel(
        isDeprecated: false,
        name: 'OneOfType',
        models: {
          (discriminatorValue: 'string', model: StringModel(context: context)),
          (discriminatorValue: 'int', model: IntegerModel(context: context)),
        },
        context: context,
      );

      final model = AnyOfModel(
        isDeprecated: false,
        name: 'AnyOfNested',
        models: {
          (discriminatorValue: 'oneof', model: oneOfModel),
          (discriminatorValue: 'bool', model: BooleanModel(context: context)),
        },
        context: context,
      );

      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());

      const expectedMethod = r'''
        String toMatrix(
          String paramName, {
          required bool explode,
          required bool allowEmpty,
        }) {
          final _$values = <String>{};
          if (bool != null) {
            final _$boolMatrix = bool!.toMatrix(
              paramName,
              explode: explode,
              allowEmpty: allowEmpty,
            );
            _$values.add(_$boolMatrix);
          }
          if (oneOfType != null) {
            final _$oneOfTypeMatrix = oneOfType!.toMatrix(
              paramName,
              explode: explode,
              allowEmpty: allowEmpty,
            );
            _$values.add(_$oneOfTypeMatrix);
          }
          if (_$values.isEmpty) return '';
          if (_$values.length > 1) {
            throw EncodingException(
              r'Ambiguous anyOf matrix encoding for AnyOfNested: multiple values provided, anyOf requires exactly one value',
            );
          }
          return _$values.first;
        }
      ''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('toMatrix uses runtime check for nested oneOf', () {
      final innerOneOf = OneOfModel(
        isDeprecated: false,
        name: 'InnerChoice',
        models: {
          (discriminatorValue: 'str', model: StringModel(context: context)),
          (
            discriminatorValue: 'obj',
            model: ClassModel(
              isDeprecated: false,
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
        isDeprecated: false,
        name: 'TestAnyOf',
        models: {
          (discriminatorValue: null, model: StringModel(context: context)),
          (discriminatorValue: null, model: innerOneOf),
        },
        context: context,
      );

      final klass = generator.generateClass(model);
      final generated = format(klass.accept(emitter).toString());

      const expected = r'''
        String toMatrix(
          String paramName, {
          required bool explode,
          required bool allowEmpty,
        }) {
          final _$values = <String>{};
          final _$mapValues = <Map<String, String>>[];
          if (innerChoice != null) {
            switch (innerChoice!.currentEncodingShape) {
              case EncodingShape.simple:
                _$values.add(
                  innerChoice!.toMatrix(
                    paramName,
                    explode: explode,
                    allowEmpty: allowEmpty,
                  ),
                );
                break;
              case EncodingShape.complex:
                final _$innerChoiceMatrix = innerChoice!.parameterProperties(
                  allowEmpty: allowEmpty,
                );
                _$mapValues.add(_$innerChoiceMatrix);
                break;
              case EncodingShape.mixed:
                throw EncodingException(
                  'Cannot encode field with mixed encoding shape',
                );
            }
          }
          if (string != null) {
            final _$stringMatrix = string!.toMatrix(
              paramName,
              explode: explode,
              allowEmpty: allowEmpty,
            );
            _$values.add(_$stringMatrix);
          }
          if (_$values.isEmpty && _$mapValues.isEmpty) return '';
          if (_$mapValues.isNotEmpty && _$values.isNotEmpty) {
            throw EncodingException(
              r'Ambiguous anyOf matrix encoding for TestAnyOf: mixing simple and complex values',
            );
          }
          if (_$values.isNotEmpty) {
            if (_$values.length > 1) {
              throw EncodingException(
                r'Ambiguous anyOf matrix encoding for TestAnyOf: multiple values provided, anyOf requires exactly one value',
              );
            }
            return _$values.first;
          } else {
            final _$map = <String, String>{};
            for (final _$m in _$mapValues) {
              _$map.addAll(_$m);
            }
            return _$map.toMatrix(
              paramName,
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

    group('toMatrix with list models', () {
      test('generates toMatrix for AnyOf with List<String> variant', () {
        final listModel = ListModel(
          content: StringModel(context: context),
          context: context,
        );

        final model = AnyOfModel(
          isDeprecated: false,
          name: 'StringOrList',
          models: {
            (discriminatorValue: null, model: StringModel(context: context)),
            (discriminatorValue: null, model: listModel),
          },
          context: context,
        );

        final generatedClass = generator.generateClass(model);
        final classCode = format(generatedClass.accept(emitter).toString());

        const expectedMethod = r'''
          String toMatrix(
            String paramName, {
            required bool explode,
            required bool allowEmpty,
          }) {
            final _$values = <String>{};
            if (list != null) {
              final _$listMatrix = list!.toMatrix(
                paramName,
                explode: explode,
                allowEmpty: allowEmpty,
              );
              _$values.add(_$listMatrix);
            }
            if (string != null) {
              final _$stringMatrix = string!.toMatrix(
                paramName,
                explode: explode,
                allowEmpty: allowEmpty,
              );
              _$values.add(_$stringMatrix);
            }
            if (_$values.isEmpty) return '';
            if (_$values.length > 1) {
              throw EncodingException(
                r'Ambiguous anyOf matrix encoding for StringOrList: multiple values provided, anyOf requires exactly one value',
              );
            }
            return _$values.first;
          }
        ''';
        expect(
          collapseWhitespace(classCode),
          contains(collapseWhitespace(expectedMethod)),
        );
      });

      test('generates toMatrix for AnyOf with List<int> variant', () {
        final listModel = ListModel(
          content: IntegerModel(context: context),
          context: context,
        );

        final model = AnyOfModel(
          isDeprecated: false,
          name: 'StringOrIntList',
          models: {
            (discriminatorValue: null, model: StringModel(context: context)),
            (discriminatorValue: null, model: listModel),
          },
          context: context,
        );

        final generatedClass = generator.generateClass(model);
        final classCode = format(generatedClass.accept(emitter).toString());

        const expectedMethod = r'''
          String toMatrix(
            String paramName, {
            required bool explode,
            required bool allowEmpty,
          }) {
            final _$values = <String>{};
            if (list != null) {
              final _$listMatrix = list!
                  .map<String>((e) => e.uriEncode(allowEmpty: allowEmpty))
                  .toList()
                  .toMatrix(
                    paramName,
                    explode: explode,
                    allowEmpty: allowEmpty,
                    alreadyEncoded: true,
                  );
              _$values.add(_$listMatrix);
            }
            if (string != null) {
              final _$stringMatrix = string!.toMatrix(
                paramName,
                explode: explode,
                allowEmpty: allowEmpty,
              );
              _$values.add(_$stringMatrix);
            }
            if (_$values.isEmpty) return '';
            if (_$values.length > 1) {
              throw EncodingException(
                r'Ambiguous anyOf matrix encoding for StringOrIntList: multiple values provided, anyOf requires exactly one value',
              );
            }
            return _$values.first;
          }
        ''';
        expect(
          collapseWhitespace(classCode),
          contains(collapseWhitespace(expectedMethod)),
        );
      });

      test('generates toMatrix for AnyOf with only list variants', () {
        final listStringModel = ListModel(
          content: StringModel(context: context),
          context: context,
        );
        final listIntModel = ListModel(
          content: IntegerModel(context: context),
          context: context,
        );

        final model = AnyOfModel(
          isDeprecated: false,
          name: 'StringListOrIntList',
          models: {
            (discriminatorValue: null, model: listStringModel),
            (discriminatorValue: null, model: listIntModel),
          },
          context: context,
        );

        final generatedClass = generator.generateClass(model);
        final classCode = format(generatedClass.accept(emitter).toString());

        const expectedMethod = r'''
          String toMatrix(
            String paramName, {
            required bool explode,
            required bool allowEmpty,
          }) {
            final _$values = <String>{};
            if (list != null) {
              final _$listMatrix = list!
                  .map<String>((e) => e.uriEncode(allowEmpty: allowEmpty))
                  .toList()
                  .toMatrix(
                    paramName,
                    explode: explode,
                    allowEmpty: allowEmpty,
                    alreadyEncoded: true,
                  );
              _$values.add(_$listMatrix);
            }
            if (list2 != null) {
              final _$list2Matrix = list2!.toMatrix(
                paramName,
                explode: explode,
                allowEmpty: allowEmpty,
              );
              _$values.add(_$list2Matrix);
            }
            if (_$values.isEmpty) return '';
            if (_$values.length > 1) {
              throw EncodingException(
                r'Ambiguous anyOf matrix encoding for StringListOrIntList: multiple values provided, anyOf requires exactly one value',
              );
            }
            return _$values.first;
          }
        ''';
        expect(
          collapseWhitespace(classCode),
          contains(collapseWhitespace(expectedMethod)),
        );
      });

      test(
        'generates EncodingException for AnyOf with List<ClassModel> variant',
        () {
          final classModel = ClassModel(
            isDeprecated: false,
            name: 'Row',
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
          final listOfClassModel = ListModel(
            content: classModel,
            context: context,
          );

          final model = AnyOfModel(
            isDeprecated: false,
            name: 'RowsOrModel',
            models: {
              (discriminatorValue: null, model: listOfClassModel),
              (discriminatorValue: null, model: classModel),
            },
            context: context,
          );

          final generatedClass = generator.generateClass(model);
          final generated = format(generatedClass.accept(emitter).toString());

          // AnyOf uses if-guards, not a switch. Verify the list branch throws.
          expect(
            collapseWhitespace(generated),
            contains(
              collapseWhitespace(
                'if (list != null) { throw EncodingException('
                " 'Lists with complex content are not supported"
                " for encoding', ); }",
              ),
            ),
          );
        },
      );
    });
  });
}
