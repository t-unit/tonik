import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/model/all_of_generator.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';

void main() {
  late AllOfGenerator generator;
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
    generator = AllOfGenerator(
      nameManager: nameManager,
      package: 'package:example',
      stableModelSorter: StableModelSorter(),
    );
    context = Context.initial();
    emitter = DartEmitter(useNullSafetySyntax: true);
  });

  group('AllOfGenerator toMatrix generation', () {
    test('generates toMatrix method with correct signature', () {
      final model = AllOfModel(
        isDeprecated: false,
        name: 'AllOfPrimitive',
        models: {
          StringModel(context: context),
          IntegerModel(context: context),
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

    test('generates toMatrix for complex-only AllOf', () {
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

      final model = AllOfModel(
        isDeprecated: false,
        name: 'AllOfComplex',
        models: {class1, class2},
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
          final _$mergedProperties = <String, String>{};
          _$mergedProperties.addAll(
            class1.parameterProperties(allowEmpty: allowEmpty),
          );
          _$mergedProperties.addAll(
            class2.parameterProperties(allowEmpty: allowEmpty),
          );
          return _$mergedProperties.toMatrix(
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

    test('generates toMatrix for primitive-only AllOf', () {
      final model = AllOfModel(
        isDeprecated: false,
        name: 'AllOfPrimitive',
        models: {
          StringModel(context: context),
          IntegerModel(context: context),
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
          final _$intMatrix = int.toMatrix(
            paramName,
            explode: explode,
            allowEmpty: allowEmpty,
          );
          _$values.add(_$intMatrix);
          final _$stringMatrix = string.toMatrix(
            paramName,
            explode: explode,
            allowEmpty: allowEmpty,
          );
          _$values.add(_$stringMatrix);
          if (_$values.length > 1) {
            throw EncodingException(
              r'Inconsistent allOf matrix encoding for AllOfPrimitive: all values must encode to the same result',
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

    test('generates toMatrix with runtime validation for dynamic models', () {
      final anyOfModel = AnyOfModel(
        isDeprecated: false,
        name: 'AnyOfModel',
        models: {
          (discriminatorValue: 'string', model: StringModel(context: context)),
          (
            discriminatorValue: 'complex',
            model: ClassModel(
              isDeprecated: false,
              name: 'ComplexData',
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
            ),
          ),
        },
        discriminator: 'type',
        context: context,
      );

      final classModel = ClassModel(
        isDeprecated: false,
        name: 'ClassModel',
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

      final model = AllOfModel(
        isDeprecated: false,
        name: 'AllOfWithDynamic',
        models: {anyOfModel, classModel},
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
          if (currentEncodingShape == EncodingShape.mixed) {
            throw EncodingException(
              'Simple encoding not supported: contains complex types',
            );
          }
          final _$mergedProperties = <String, String>{};
          _$mergedProperties.addAll(anyOfModel.parameterProperties(allowEmpty: allowEmpty));
          _$mergedProperties.addAll(classModel.parameterProperties(allowEmpty: allowEmpty));
          return _$mergedProperties.toMatrix(
            paramName,
            explode: explode,
            allowEmpty: allowEmpty,
            alreadyEncoded: true,
          );
        }
      ''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(format(expectedMethod))),
      );
    });

    test('generates toMatrix for empty AllOf', () {
      final model = AllOfModel(
        isDeprecated: false,
        name: 'AllOfEmpty',
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
          return ''.toMatrix(paramName, explode: explode, allowEmpty: allowEmpty);
        }
      ''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('generates toMatrix for AllOf with enum', () {
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

      final model = AllOfModel(
        isDeprecated: false,
        name: 'AllOfEnum',
        models: {
          enumModel,
          StringModel(context: context),
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
          final _$statusMatrix = status.toMatrix(
            paramName,
            explode: explode,
            allowEmpty: allowEmpty,
          );
          _$values.add(_$statusMatrix);
          final _$stringMatrix = string.toMatrix(
            paramName,
            explode: explode,
            allowEmpty: allowEmpty,
          );
          _$values.add(_$stringMatrix);
          if (_$values.length > 1) {
            throw EncodingException(
              r'Inconsistent allOf matrix encoding for AllOfEnum: all values must encode to the same result',
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

    test('generates toMatrix for AllOf with nested composition types', () {
      final oneOfModel = OneOfModel(
        isDeprecated: false,
        name: 'OneOfType',
        models: {
          (discriminatorValue: 'string', model: StringModel(context: context)),
          (discriminatorValue: 'int', model: IntegerModel(context: context)),
        },
        context: context,
      );

      final classModel = ClassModel(
        isDeprecated: false,
        name: 'ClassModel',
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

      final model = AllOfModel(
        isDeprecated: false,
        name: 'AllOfNested',
        models: {oneOfModel, classModel},
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
          throw EncodingException(
            'Simple encoding not supported: contains complex types',
          );
        }
      ''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('generates toMatrix that throws for cannotBeSimplyEncoded', () {
      final classModel = ClassModel(
        isDeprecated: false,
        name: 'ClassModel',
        properties: [
          Property(
            name: 'nested',
            model: ClassModel(
              isDeprecated: false,
              name: 'NestedClass',
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
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ],
        context: context,
      );

      final model = AllOfModel(
        isDeprecated: false,
        name: 'AllOfComplex',
        models: {classModel},
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
          final _$mergedProperties = <String, String>{};
          _$mergedProperties.addAll(classModel.parameterProperties(allowEmpty: allowEmpty));
          return _$mergedProperties.toMatrix(
            paramName,
            explode: explode,
            allowEmpty: allowEmpty,
            alreadyEncoded: true,
          );
        }
      ''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(format(expectedMethod))),
      );
    });

    group('toMatrix with list models', () {
      test('generates toMatrix for AllOf with List<String> model', () {
        final listModel = ListModel(
          content: StringModel(context: context),
          context: context,
        );

        final model = AllOfModel(
          isDeprecated: false,
          name: 'AllOfList',
          models: {listModel},
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
            final _$listMatrix = list.toMatrix(
              paramName,
              explode: explode,
              allowEmpty: allowEmpty,
            );
            _$values.add(_$listMatrix);
            if (_$values.length > 1) {
              throw EncodingException(
                r'Inconsistent allOf matrix encoding for AllOfList: all values must encode to the same result',
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

      test('generates toMatrix for AllOf with List<int> model', () {
        final listModel = ListModel(
          content: IntegerModel(context: context),
          context: context,
        );

        final model = AllOfModel(
          isDeprecated: false,
          name: 'AllOfIntList',
          models: {listModel},
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
            final _$listMatrix = list
                .map<String>((e) => e.uriEncode(allowEmpty: allowEmpty))
                .toList()
                .toMatrix(
                  paramName,
                  explode: explode,
                  allowEmpty: allowEmpty,
                  alreadyEncoded: true,
                );
            _$values.add(_$listMatrix);
            if (_$values.length > 1) {
              throw EncodingException(
                r'Inconsistent allOf matrix encoding for AllOfIntList: all values must encode to the same result',
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

      test('generates toMatrix for AllOf with multiple list models', () {
        final listStringModel = ListModel(
          content: StringModel(context: context),
          context: context,
        );
        final listIntModel = ListModel(
          content: IntegerModel(context: context),
          context: context,
        );

        final model = AllOfModel(
          isDeprecated: false,
          name: 'AllOfMultipleLists',
          models: {listStringModel, listIntModel},
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
            final _$listMatrix = list
                .map<String>((e) => e.uriEncode(allowEmpty: allowEmpty))
                .toList()
                .toMatrix(
                  paramName,
                  explode: explode,
                  allowEmpty: allowEmpty,
                  alreadyEncoded: true,
                );
            _$values.add(_$listMatrix);
            final _$list2Matrix = list2.toMatrix(
              paramName,
              explode: explode,
              allowEmpty: allowEmpty,
            );
            _$values.add(_$list2Matrix);
            if (_$values.length > 1) {
              throw EncodingException(
                r'Inconsistent allOf matrix encoding for AllOfMultipleLists: all values must encode to the same result',
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
    });
  });
}
