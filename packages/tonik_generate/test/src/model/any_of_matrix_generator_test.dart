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
      package: 'example',
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
        models: [
          (discriminatorValue: 'string', model: StringModel(context: context)),
          (discriminatorValue: 'int', model: IntegerModel(context: context)),
        ],
        context: context,
        examples: const [],
        nameOverride: null,
        description: null,
        discriminator: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
        defaultValue: null,
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
        models: [
          (discriminatorValue: 'string', model: StringModel(context: context)),
          (discriminatorValue: 'int', model: IntegerModel(context: context)),
          (discriminatorValue: 'bool', model: BooleanModel(context: context)),
        ],
        context: context,
        examples: const [],
        nameOverride: null,
        description: null,
        discriminator: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
        defaultValue: null,
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
          if (this.bool != null) {
            final _$boolMatrix = this.bool!.toMatrix(
              paramName,
              explode: explode,
              allowEmpty: allowEmpty,
            );
            _$values.add(_$boolMatrix);
          }
          if (this.int != null) {
            final _$intMatrix = this.int!.toMatrix(
              paramName,
              explode: explode,
              allowEmpty: allowEmpty,
            );
            _$values.add(_$intMatrix);
          }
          if (this.string != null) {
            final _$stringMatrix = this.string!.toMatrix(
              paramName,
              explode: explode,
              allowEmpty: allowEmpty,
            );
            _$values.add(_$stringMatrix);
          }
          if (_$values.isEmpty) return '';
          return _$values.first;
        }
      ''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(format(expectedMethod))),
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
            examples: const [],
            defaultValue: null,
            isReadOnly: false,
            isWriteOnly: false,
            nameOverride: null,
            description: null,
          ),
        ],
        context: context,
        examples: const [],
        nameOverride: null,
        description: null,
        additionalPropertiesPolicy: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
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
            examples: const [],
            defaultValue: null,
            isReadOnly: false,
            isWriteOnly: false,
            nameOverride: null,
            description: null,
          ),
        ],
        context: context,
        examples: const [],
        nameOverride: null,
        description: null,
        additionalPropertiesPolicy: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
      );

      final model = AnyOfModel(
        isDeprecated: false,
        name: 'AnyOfComplex',
        models: [
          (discriminatorValue: 'class1', model: class1),
          (discriminatorValue: 'class2', model: class2),
        ],
        discriminator: 'type',
        context: context,
        examples: const [],
        nameOverride: null,
        description: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
        defaultValue: null,
      );

      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());

      const expectedMethod = r'''
String toMatrix( String paramName, { required bool explode, required bool allowEmpty, }) { final _$mapValues = <Map<String, PropertyValue>>[]; String? _$discriminatorValue; if (this.class1 != null) { final _$class1Matrix = this.class1!.parameterProperties( allowEmpty: allowEmpty, ); _$mapValues.add(_$class1Matrix); _$discriminatorValue ??= r'class1'; } if (this.class2 != null) { final _$class2Matrix = this.class2!.parameterProperties( allowEmpty: allowEmpty, ); _$mapValues.add(_$class2Matrix); _$discriminatorValue ??= r'class2'; } final _$map = <String, PropertyValue>{}; for (final _$m in _$mapValues) { _$map.addAll(_$m); } final _$discValue = _$discriminatorValue; if (_$discValue != null) { _$map.putIfAbsent(r'type', () => PropertyValue.scalar(_$discValue)); } return _$map.toMatrix(paramName, explode: explode, allowEmpty: allowEmpty); }
''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(format(expectedMethod))),
      );
    });

    test(
      'generates toMatrix for mixed AnyOf that throws on ambiguous encoding',
      () {
        final model = AnyOfModel(
          isDeprecated: false,
          name: 'AnyOfMixed',
          models: [
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
                    examples: const [],
                    defaultValue: null,
                    isReadOnly: false,
                    isWriteOnly: false,
                    nameOverride: null,
                    description: null,
                  ),
                ],
                context: context,
                examples: const [],
                nameOverride: null,
                description: null,
                additionalPropertiesPolicy: null,
                isNullable: false,
                isReadOnly: false,
                isWriteOnly: false,
              ),
            ),
          ],
          discriminator: 'type',
          context: context,
          examples: const [],
          nameOverride: null,
          description: null,
          isNullable: false,
          isReadOnly: false,
          isWriteOnly: false,
          defaultValue: null,
        );

        final generatedClass = generator.generateClass(model);
        final classCode = format(
          generatedClass.methods
              .firstWhere((m) => m.name == 'toMatrix')
              .accept(emitter)
              .toString(),
        );

        const expectedMethod = r'''
String toMatrix( String paramName, { required bool explode, required bool allowEmpty, }) { final _$values = <String>{}; final _$mapValues = <Map<String, PropertyValue>>[]; String? _$discriminatorValue; if (this.data != null) { final _$dataMatrix = this.data!.parameterProperties(allowEmpty: allowEmpty); _$mapValues.add(_$dataMatrix); _$discriminatorValue ??= r'data'; } if (this.string != null) { final _$stringMatrix = this.string!.toMatrix( paramName, explode: explode, allowEmpty: allowEmpty, ); _$values.add(_$stringMatrix); } if (_$values.isEmpty && _$mapValues.isEmpty) return ''; if (_$mapValues.isNotEmpty && _$values.isNotEmpty) { throw EncodingException( r'Ambiguous anyOf matrix encoding for AnyOfMixed: mixing simple and complex values', ); } if (_$values.isNotEmpty) { return _$values.first; } else { final _$map = <String, PropertyValue>{}; for (final _$m in _$mapValues) { _$map.addAll(_$m); } final _$discValue = _$discriminatorValue; if (_$discValue != null) { _$map.putIfAbsent(r'type', () => PropertyValue.scalar(_$discValue)); } return _$map.toMatrix( paramName, explode: explode, allowEmpty: allowEmpty, ); } }
''';

        expect(
          collapseWhitespace(classCode),
          contains(collapseWhitespace(format(expectedMethod))),
        );
      },
    );

    test('generates toMatrix for AnyOf with enum variants', () {
      final enumModel = EnumModel(
        isDeprecated: false,
        name: 'Status',
        values: {
          const EnumEntry(value: 'active', nameOverride: null),
          const EnumEntry(value: 'inactive', nameOverride: null),
        },
        isNullable: false,
        context: context,
        examples: const [],
        nameOverride: null,
        description: null,
        defaultValue: null,
        fallbackValue: null,
        isReadOnly: false,
        isWriteOnly: false,
      );

      final model = AnyOfModel(
        isDeprecated: false,
        name: 'AnyOfEnum',
        models: [
          (discriminatorValue: 'status', model: enumModel),
          (discriminatorValue: 'string', model: StringModel(context: context)),
        ],
        context: context,
        examples: const [],
        nameOverride: null,
        description: null,
        discriminator: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
        defaultValue: null,
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
          if (this.status != null) {
            final _$statusMatrix = this.status!.toMatrix(
              paramName,
              explode: explode,
              allowEmpty: allowEmpty,
            );
            _$values.add(_$statusMatrix);
          }
          if (this.string != null) {
            final _$stringMatrix = this.string!.toMatrix(
              paramName,
              explode: explode,
              allowEmpty: allowEmpty,
            );
            _$values.add(_$stringMatrix);
          }
          if (_$values.isEmpty) return '';
          return _$values.first;
        }
      ''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(format(expectedMethod))),
      );
    });

    test('generates toMatrix for empty AnyOf', () {
      final model = AnyOfModel(
        isDeprecated: false,
        name: 'AnyOfEmpty',
        models: const [],
        context: context,
        examples: const [],
        nameOverride: null,
        description: null,
        discriminator: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
        defaultValue: null,
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
        contains(collapseWhitespace(format(expectedMethod))),
      );
    });

    test('generates toMatrix for AnyOf with nested composition types', () {
      final oneOfModel = OneOfModel(
        isDeprecated: false,
        name: 'OneOfType',
        models: [
          (discriminatorValue: 'string', model: StringModel(context: context)),
          (discriminatorValue: 'int', model: IntegerModel(context: context)),
        ],
        context: context,
        examples: const [],
        nameOverride: null,
        description: null,
        discriminator: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
        defaultValue: null,
      );

      final model = AnyOfModel(
        isDeprecated: false,
        name: 'AnyOfNested',
        models: [
          (discriminatorValue: 'oneof', model: oneOfModel),
          (discriminatorValue: 'bool', model: BooleanModel(context: context)),
        ],
        context: context,
        examples: const [],
        nameOverride: null,
        description: null,
        discriminator: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
        defaultValue: null,
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
          if (this.bool != null) {
            final _$boolMatrix = this.bool!.toMatrix(
              paramName,
              explode: explode,
              allowEmpty: allowEmpty,
            );
            _$values.add(_$boolMatrix);
          }
          if (this.oneOfType != null) {
            final _$oneOfTypeMatrix = this.oneOfType!.toMatrix(
              paramName,
              explode: explode,
              allowEmpty: allowEmpty,
            );
            _$values.add(_$oneOfTypeMatrix);
          }
          if (_$values.isEmpty) return '';
          return _$values.first;
        }
      ''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(format(expectedMethod))),
      );
    });

    test('toMatrix uses runtime check for nested oneOf', () {
      final innerOneOf = OneOfModel(
        isDeprecated: false,
        name: 'InnerChoice',
        models: [
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
                  examples: const [],
                  defaultValue: null,
                  isReadOnly: false,
                  isWriteOnly: false,
                  nameOverride: null,
                  description: null,
                ),
              ],
              context: context,
              examples: const [],
              nameOverride: null,
              description: null,
              additionalPropertiesPolicy: null,
              isNullable: false,
              isReadOnly: false,
              isWriteOnly: false,
            ),
          ),
        ],
        discriminator: 'type',
        context: context,
        examples: const [],
        nameOverride: null,
        description: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
        defaultValue: null,
      );

      final model = AnyOfModel(
        isDeprecated: false,
        name: 'TestAnyOf',
        models: [
          (discriminatorValue: null, model: StringModel(context: context)),
          (discriminatorValue: null, model: innerOneOf),
        ],
        context: context,
        examples: const [],
        nameOverride: null,
        description: null,
        discriminator: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
        defaultValue: null,
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
          final _$mapValues = <Map<String, PropertyValue>>[];
          if (this.innerChoice != null) {
            switch (this.innerChoice!.currentEncodingShape) {
              case EncodingShape.simple:
                _$values.add(
                  this.innerChoice!.toMatrix(
                    paramName,
                    explode: explode,
                    allowEmpty: allowEmpty,
                  ),
                );
                break;
              case EncodingShape.complex:
                final _$innerChoiceMatrix = this.innerChoice!.parameterProperties(
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
          if (this.string != null) {
            final _$stringMatrix = this.string!.toMatrix(
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
            return _$values.first;
          } else {
            final _$map = <String, PropertyValue>{};
            for (final _$m in _$mapValues) {
              _$map.addAll(_$m);
            }
            return _$map.toMatrix(
              paramName,
              explode: explode,
              allowEmpty: allowEmpty,
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
          examples: const [],
          name: null,
          nameOverride: null,
          isNullable: false,
          isContentNullable: false,
          isReadOnly: false,
          isWriteOnly: false,
        );

        final model = AnyOfModel(
          isDeprecated: false,
          name: 'StringOrList',
          models: [
            (discriminatorValue: null, model: StringModel(context: context)),
            (discriminatorValue: null, model: listModel),
          ],
          context: context,
          examples: const [],
          nameOverride: null,
          description: null,
          discriminator: null,
          isNullable: false,
          isReadOnly: false,
          isWriteOnly: false,
          defaultValue: null,
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
            if (this.list != null) {
              final _$listMatrix = this.list!.toMatrix(
                paramName,
                explode: explode,
                allowEmpty: allowEmpty,
              );
              _$values.add(_$listMatrix);
            }
            if (this.string != null) {
              final _$stringMatrix = this.string!.toMatrix(
                paramName,
                explode: explode,
                allowEmpty: allowEmpty,
              );
              _$values.add(_$stringMatrix);
            }
            if (_$values.isEmpty) return '';
            return _$values.first;
          }
        ''';
        expect(
          collapseWhitespace(classCode),
          contains(collapseWhitespace(format(expectedMethod))),
        );
      });

      test('generates toMatrix for AnyOf with List<int> variant', () {
        final listModel = ListModel(
          content: IntegerModel(context: context),
          context: context,
          examples: const [],
          name: null,
          nameOverride: null,
          isNullable: false,
          isContentNullable: false,
          isReadOnly: false,
          isWriteOnly: false,
        );

        final model = AnyOfModel(
          isDeprecated: false,
          name: 'StringOrIntList',
          models: [
            (discriminatorValue: null, model: StringModel(context: context)),
            (discriminatorValue: null, model: listModel),
          ],
          context: context,
          examples: const [],
          nameOverride: null,
          description: null,
          discriminator: null,
          isNullable: false,
          isReadOnly: false,
          isWriteOnly: false,
          defaultValue: null,
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
            if (this.list != null) {
              final _$listMatrix = this.list!
                  .map<String>(
                    (e) => e.uriEncode(allowEmpty: allowEmpty, textEncoding: utf8),
                  )
                  .toList()
                  .toMatrix(
                    paramName,
                    explode: explode,
                    allowEmpty: allowEmpty,
                    alreadyEncoded: true,
                  );
              _$values.add(_$listMatrix);
            }
            if (this.string != null) {
              final _$stringMatrix = this.string!.toMatrix(
                paramName,
                explode: explode,
                allowEmpty: allowEmpty,
              );
              _$values.add(_$stringMatrix);
            }
            if (_$values.isEmpty) return '';
            return _$values.first;
          }
        ''';
        expect(
          collapseWhitespace(classCode),
          contains(collapseWhitespace(format(expectedMethod))),
        );
      });

      test('generates toMatrix for AnyOf with only list variants', () {
        final listStringModel = ListModel(
          content: StringModel(context: context),
          context: context,
          examples: const [],
          name: null,
          nameOverride: null,
          isNullable: false,
          isContentNullable: false,
          isReadOnly: false,
          isWriteOnly: false,
        );
        final listIntModel = ListModel(
          content: IntegerModel(context: context),
          context: context,
          examples: const [],
          name: null,
          nameOverride: null,
          isNullable: false,
          isContentNullable: false,
          isReadOnly: false,
          isWriteOnly: false,
        );

        final model = AnyOfModel(
          isDeprecated: false,
          name: 'StringListOrIntList',
          models: [
            (discriminatorValue: null, model: listStringModel),
            (discriminatorValue: null, model: listIntModel),
          ],
          context: context,
          examples: const [],
          nameOverride: null,
          description: null,
          discriminator: null,
          isNullable: false,
          isReadOnly: false,
          isWriteOnly: false,
          defaultValue: null,
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
            if (this.list2 != null) {
              final _$list2Matrix = this.list2!
                  .map<String>(
                    (e) => e.uriEncode(allowEmpty: allowEmpty, textEncoding: utf8),
                  )
                  .toList()
                  .toMatrix(
                    paramName,
                    explode: explode,
                    allowEmpty: allowEmpty,
                    alreadyEncoded: true,
                  );
              _$values.add(_$list2Matrix);
            }
            if (this.list != null) {
              final _$listMatrix = this.list!.toMatrix(
                paramName,
                explode: explode,
                allowEmpty: allowEmpty,
              );
              _$values.add(_$listMatrix);
            }
            if (_$values.isEmpty) return '';
            return _$values.first;
          }
        ''';
        expect(
          collapseWhitespace(classCode),
          contains(collapseWhitespace(format(expectedMethod))),
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
                examples: const [],
                defaultValue: null,
                isReadOnly: false,
                isWriteOnly: false,
                nameOverride: null,
                description: null,
              ),
            ],
            context: context,
            examples: const [],
            nameOverride: null,
            description: null,
            additionalPropertiesPolicy: null,
            isNullable: false,
            isReadOnly: false,
            isWriteOnly: false,
          );
          final listOfClassModel = ListModel(
            content: classModel,
            context: context,
            examples: const [],
            name: null,
            nameOverride: null,
            isNullable: false,
            isContentNullable: false,
            isReadOnly: false,
            isWriteOnly: false,
          );

          final model = AnyOfModel(
            isDeprecated: false,
            name: 'RowsOrModel',
            models: [
              (discriminatorValue: null, model: listOfClassModel),
              (discriminatorValue: null, model: classModel),
            ],
            context: context,
            examples: const [],
            nameOverride: null,
            description: null,
            discriminator: null,
            isNullable: false,
            isReadOnly: false,
            isWriteOnly: false,
            defaultValue: null,
          );

          final generatedClass = generator.generateClass(model);
          final generated = format(generatedClass.accept(emitter).toString());

          // AnyOf uses if-guards, not a switch. Verify the list branch throws.
          expect(
            collapseWhitespace(generated),
            contains(
              collapseWhitespace(
                'if (this.list != null) { throw EncodingException('
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
