import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/model/class_generator.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';

void main() {
  late ClassGenerator generator;
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
    generator = ClassGenerator(
      nameManager: nameManager,
      package: 'package:example',
    );
    context = Context.initial();
    emitter = DartEmitter(useNullSafetySyntax: true);
  });

  group('ClassGenerator labelProperties generation', () {
    test('generates labelProperties for class with only simple properties', () {
      final model = ClassModel(
        name: 'SimpleClass',
        properties: [
          Property(
            name: 'name',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
          Property(
            name: 'age',
            model: IntegerModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ],
        context: context,
      );

      final generatedClass = generator.generateClass(model);
      final labelPropertiesMethod = generatedClass.methods.firstWhere(
        (m) => m.name == 'labelProperties',
      );

      expect(
        labelPropertiesMethod.returns?.accept(emitter).toString(),
        'Map<String,String>',
      );
      expect(labelPropertiesMethod.optionalParameters.length, 1);
      expect(labelPropertiesMethod.optionalParameters[0].name, 'allowEmpty');
      expect(
        labelPropertiesMethod.optionalParameters[0].type
            ?.accept(emitter)
            .toString(),
        'bool',
      );
      expect(labelPropertiesMethod.optionalParameters[0].required, isFalse);

      final classCode = format(generatedClass.accept(emitter).toString());
      const expectedMethod = '''
        Map<String, String> labelProperties({bool allowEmpty = true}) {
          return {
            r'name': name.toLabel(explode: false, allowEmpty: allowEmpty),
            r'age': age.toLabel(explode: false, allowEmpty: allowEmpty),
          };
        }
      ''';
      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('generates labelProperties for required nullable property', () {
      final model = ClassModel(
        name: 'NullableClass',
        properties: [
          Property(
            name: 'name',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: true,
            isDeprecated: false,
          ),
        ],
        context: context,
      );

      final generatedClass = generator.generateClass(model);
      final labelPropertiesMethod = generatedClass.methods.firstWhere(
        (m) => m.name == 'labelProperties',
      );

      expect(
        labelPropertiesMethod.returns?.accept(emitter).toString(),
        'Map<String,String>',
      );
      expect(labelPropertiesMethod.optionalParameters.length, 1);
      expect(labelPropertiesMethod.optionalParameters[0].name, 'allowEmpty');
      expect(
        labelPropertiesMethod.optionalParameters[0].type
            ?.accept(emitter)
            .toString(),
        'bool',
      );
      expect(labelPropertiesMethod.optionalParameters[0].required, isFalse);

      final classCode = format(generatedClass.accept(emitter).toString());
      const expectedMethod = '''
        Map<String, String> labelProperties({bool allowEmpty = true}) {
          return {
            if (allowEmpty || name != null) r'name': name?.toLabel(explode: false, allowEmpty: allowEmpty) ?? '',
          };
        }
      ''';
      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('generates labelProperties for optional property', () {
      final model = ClassModel(
        name: 'OptionalClass',
        properties: [
          Property(
            name: 'name',
            model: StringModel(context: context),
            isRequired: false,
            isNullable: false,
            isDeprecated: false,
          ),
        ],
        context: context,
      );

      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());
      const expectedMethod = '''
        Map<String, String> labelProperties({bool allowEmpty = true}) {
          return {
            if (name != null) r'name': name!.toLabel(explode: false, allowEmpty: allowEmpty),
          };
        }
      ''';
      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('generates labelProperties for empty class', () {
      final model = ClassModel(
        name: 'EmptyClass',
        properties: const [],
        context: context,
      );

      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());
      const expectedMethod = '''
        Map<String, String> labelProperties({bool allowEmpty = true}) => <String, String>{};
      ''';
      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test(
      'generates labelProperties that throws for class with nested class',
      () {
        final model = ClassModel(
          name: 'NestedClass',
          properties: [
            Property(
              name: 'nested',
              model: ClassModel(
                context: context,
                name: 'Nested',
                properties: [
                  Property(
                    name: 'value',
                    model: StringModel(context: context),
                    isRequired: true,
                    isNullable: false,
                    isDeprecated: false,
                  ),
                ],
              ),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          context: context,
        );

        final generatedClass = generator.generateClass(model);
        final classCode = format(generatedClass.accept(emitter).toString());
        const expectedMethod = '''
        Map<String, String> labelProperties({bool allowEmpty = true}) {
          throw EncodingException(
            'labelProperties not supported for NestedClass: contains nested data',
          );
        }
      ''';
        expect(
          collapseWhitespace(classCode),
          contains(collapseWhitespace(expectedMethod)),
        );
      },
    );
  });

  group('ClassGenerator toLabel generation', () {
    test('generates toLabel for class with only simple properties', () {
      final model = ClassModel(
        name: 'SimpleClass',
        properties: [
          Property(
            name: 'name',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
          Property(
            name: 'age',
            model: IntegerModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ],
        context: context,
      );

      final generatedClass = generator.generateClass(model);
      final toLabelMethod = generatedClass.methods.firstWhere(
        (m) => m.name == 'toLabel',
      );

      expect(toLabelMethod.returns?.accept(emitter).toString(), 'String');
      expect(toLabelMethod.optionalParameters.length, 2);
      expect(
        toLabelMethod.optionalParameters.map((p) => p.name),
        containsAll(['explode', 'allowEmpty']),
      );

      final classCode = format(generatedClass.accept(emitter).toString());
      const expectedMethod = '''
        String toLabel({bool explode = false, bool allowEmpty = true}) {
          return labelProperties(
            allowEmpty: allowEmpty,
          ).toLabel(explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true);
        }
      ''';
      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test(
      'generates toLabel that throws for class with nested class property',
      () {
        final model = ClassModel(
          name: 'NestedClass',
          properties: [
            Property(
              name: 'nested',
              model: ClassModel(
                context: context,
                name: 'Nested',
                properties: [
                  Property(
                    name: 'value',
                    model: StringModel(context: context),
                    isRequired: true,
                    isNullable: false,
                    isDeprecated: false,
                  ),
                ],
              ),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          context: context,
        );

        final generatedClass = generator.generateClass(model);
        final classCode = format(generatedClass.accept(emitter).toString());
        const expectedMethod = '''
        String toLabel({bool explode = false, bool allowEmpty = true}) {
          return labelProperties(
            allowEmpty: allowEmpty,
          ).toLabel(explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true);
        }
      ''';
        expect(
          collapseWhitespace(classCode),
          contains(collapseWhitespace(expectedMethod)),
        );
      },
    );
  });

  group('composite model runtime checking for label encoding', () {
    test(
      'generates runtime check for class with oneOf property in '
      'labelProperties',
      () {
        final model = ClassModel(
          name: 'OneOfClass',
          properties: [
            Property(
              name: 'value',
              model: OneOfModel(
                context: context,
                name: 'Value',
                discriminator: 'type',
                models: {
                  (
                    discriminatorValue: 'string',
                    model: StringModel(context: context),
                  ),
                  (
                    discriminatorValue: 'integer',
                    model: IntegerModel(context: context),
                  ),
                },
              ),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          context: context,
        );

        final generatedClass = generator.generateClass(model);
        final classCode = format(generatedClass.accept(emitter).toString());
        const expectedMethod = '''
          Map<String, String> labelProperties({bool allowEmpty = true}) {
            final mergedProperties = <String, String>{};
            if (value.currentEncodingShape != EncodingShape.simple) {
              throw EncodingException(
                'labelProperties not supported for Container: contains complex types',
              );
            }
            mergedProperties['value'] = value.toLabel(
              explode: false,
              allowEmpty: allowEmpty,
            );
            return mergedProperties;
          }
        ''';
        expect(
          collapseWhitespace(classCode),
          contains(collapseWhitespace(expectedMethod)),
        );
      },
    );

    test(
      'generates runtime check for class with anyOf property in '
      'labelProperties',
      () {
        final model = ClassModel(
          name: 'AnyOfClass',
          properties: [
            Property(
              name: 'value',
              model: AnyOfModel(
                context: context,
                name: 'Value',
                discriminator: 'type',
                models: {
                  (
                    discriminatorValue: 'string',
                    model: StringModel(context: context),
                  ),
                  (
                    discriminatorValue: 'integer',
                    model: IntegerModel(context: context),
                  ),
                },
              ),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          context: context,
        );

        final generatedClass = generator.generateClass(model);
        final classCode = format(generatedClass.accept(emitter).toString());
        const expectedMethod = '''
          Map<String, String> labelProperties({bool allowEmpty = true}) {
            final mergedProperties = <String, String>{};
            if (value.currentEncodingShape != EncodingShape.simple) {
              throw EncodingException(
                'labelProperties not supported for Container: contains complex types',
              );
            }
            mergedProperties['value'] = value.toLabel(
              explode: false,
              allowEmpty: allowEmpty,
            );
            return mergedProperties;
          }
        ''';
        expect(
          collapseWhitespace(classCode),
          contains(collapseWhitespace(expectedMethod)),
        );
      },
    );

    test(
      'generates runtime check for class with allOf property in '
      'labelProperties',
      () {
        final model = ClassModel(
          name: 'AllOfClass',
          properties: [
            Property(
              name: 'value',
              model: AllOfModel(
                context: context,
                name: 'Value',
                models: {
                  StringModel(context: context),
                  IntegerModel(context: context),
                },
              ),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          context: context,
        );

        final generatedClass = generator.generateClass(model);
        final classCode = format(generatedClass.accept(emitter).toString());
        const expectedMethod = '''
          Map<String, String> labelProperties({bool allowEmpty = true}) {
            final mergedProperties = <String, String>{};
            if (value.currentEncodingShape != EncodingShape.simple) {
              throw EncodingException(
                'labelProperties not supported for Container: contains complex types',
              );
            }
            mergedProperties['value'] = value.toLabel(
              explode: false,
              allowEmpty: allowEmpty,
            );
            return mergedProperties;
          }
        ''';
        expect(
          collapseWhitespace(classCode),
          contains(collapseWhitespace(expectedMethod)),
        );
      },
    );

    test('generates runtime check for mixed properties with composites', () {
      final model = ClassModel(
        name: 'MixedClass',
        properties: [
          Property(
            name: 'name',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
          Property(
            name: 'composite',
            model: OneOfModel(
              context: context,
              name: 'Composite',
              discriminator: 'type',
              models: {
                (
                  discriminatorValue: 'string',
                  model: StringModel(context: context),
                ),
                (
                  discriminatorValue: 'integer',
                  model: IntegerModel(context: context),
                ),
              },
            ),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
          Property(
            name: 'optionalComposite',
            model: AnyOfModel(
              context: context,
              name: 'OptionalComposite',
              discriminator: 'type',
              models: {
                (
                  discriminatorValue: 'string',
                  model: StringModel(context: context),
                ),
                (
                  discriminatorValue: 'integer',
                  model: IntegerModel(context: context),
                ),
              },
            ),
            isRequired: false,
            isNullable: false,
            isDeprecated: false,
          ),
        ],
        context: context,
      );

      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());
      const expectedMethod = '''
          Map<String, String> labelProperties({bool allowEmpty = true}) {
            final mergedProperties = <String, String>{};
            mergedProperties['name'] = name.toLabel(
              explode: false,
              allowEmpty: allowEmpty,
            );
            if (composite.currentEncodingShape != EncodingShape.simple) {
              throw EncodingException(
                'labelProperties not supported for Container: contains complex types',
              );
            }
            mergedProperties['composite'] = composite.toLabel(
              explode: false,
              allowEmpty: allowEmpty,
            );
            if (allowEmpty || optionalComposite != null) {
              if (optionalComposite != null && optionalComposite!.currentEncodingShape != EncodingShape.simple) {
                throw EncodingException(
                  'labelProperties not supported for Container: contains complex types',
                );
              }
              if (optionalComposite != null) {
                mergedProperties['optionalComposite'] = optionalComposite!.toLabel(
                  explode: false,
                  allowEmpty: allowEmpty,
                );
              }
            }
            return mergedProperties;
          }
        ''';
      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('generates runtime check for nullable composite property', () {
      final model = ClassModel(
        name: 'NullableCompositeClass',
        properties: [
          Property(
            name: 'data',
            model: OneOfModel(
              context: context,
              name: 'Data',
              discriminator: 'type',
              models: {
                (
                  discriminatorValue: 'string',
                  model: StringModel(context: context),
                ),
                (
                  discriminatorValue: 'integer',
                  model: IntegerModel(context: context),
                ),
              },
            ),
            isRequired: true,
            isNullable: true,
            isDeprecated: false,
          ),
        ],
        context: context,
      );

      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());
        const expectedMethod = '''
          Map<String, String> labelProperties({bool allowEmpty = true}) {
            final mergedProperties = <String, String>{};
            if (allowEmpty || data != null) {
              if (data != null && data!.currentEncodingShape != EncodingShape.simple) {
                throw EncodingException(
                  'labelProperties not supported for Container: contains complex types',
                );
              }
              if (data != null) {
                mergedProperties['data'] = data!.toLabel(explode: false, allowEmpty: allowEmpty) ?? '';
              }
            }
            return mergedProperties;
          }
        ''';
      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test(
      'runtime check for complex mixed scenario with primitives and composites',
      () {
        final model = ClassModel(
          name: 'ComplexMixedClass',
          properties: [
            Property(
              name: 'id',
              model: IntegerModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
            Property(
              name: 'name',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: true,
              isDeprecated: false,
            ),
            Property(
              name: 'status',
              model: EnumModel(
                context: context,
                name: 'Status',
                values: const {'active', 'inactive', 'pending'},
                isNullable: false,
              ),
              isRequired: false,
              isNullable: false,
              isDeprecated: false,
            ),
            Property(
              name: 'oneOfValue',
              model: OneOfModel(
                context: context,
                name: 'OneOfValue',
                discriminator: 'type',
                models: {
                  (
                    discriminatorValue: 'string',
                    model: StringModel(context: context),
                  ),
                  (
                    discriminatorValue: 'number',
                    model: IntegerModel(context: context),
                  ),
                },
              ),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
            Property(
              name: 'anyOfValue',
              model: AnyOfModel(
                context: context,
                name: 'AnyOfValue',
                discriminator: 'type',
                models: {
                  (
                    discriminatorValue: 'date',
                    model: DateTimeModel(context: context),
                  ),
                  (
                    discriminatorValue: 'decimal',
                    model: DecimalModel(context: context),
                  ),
                },
              ),
              isRequired: false,
              isNullable: true,
              isDeprecated: false,
            ),
            Property(
              name: 'allOfValue',
              model: AllOfModel(
                context: context,
                name: 'AllOfValue',
                models: {
                  StringModel(context: context),
                  IntegerModel(context: context),
                },
              ),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          context: context,
        );

        final generatedClass = generator.generateClass(model);
        final classCode = format(generatedClass.accept(emitter).toString());
        const expectedMethod = '''
        Map<String, String> labelProperties({bool allowEmpty = true}) {
          final mergedProperties = <String, String>{};
          mergedProperties['id'] = id.toLabel(explode: false, allowEmpty: allowEmpty);
          if (allowEmpty || name != null) {
            mergedProperties['name'] = name?.toLabel(explode: false, allowEmpty: allowEmpty) ?? '';
          }
          if (status != null) {
            mergedProperties['status'] = status!.toLabel(
              explode: false,
              allowEmpty: allowEmpty,
            );
          }
          if (oneOfValue.currentEncodingShape != EncodingShape.simple) {
            throw EncodingException(
              'labelProperties not supported for Container: contains complex types',
            );
          }
          mergedProperties['oneOfValue'] = oneOfValue.toLabel(
            explode: false,
            allowEmpty: allowEmpty,
          );
          if (allowEmpty || anyOfValue != null) {
            if (anyOfValue != null && anyOfValue!.currentEncodingShape != EncodingShape.simple) {
              throw EncodingException(
                'labelProperties not supported for Container: contains complex types',
              );
            }
            if (anyOfValue != null) {
              mergedProperties['anyOfValue'] = anyOfValue!.toLabel(
                explode: false,
                allowEmpty: allowEmpty,
              );
            }
          }
          if (allOfValue.currentEncodingShape != EncodingShape.simple) {
            throw EncodingException(
              'labelProperties not supported for Container: contains complex types',
            );
          }
          mergedProperties['allOfValue'] = allOfValue.toLabel(
            explode: false,
            allowEmpty: allowEmpty,
          );
          return mergedProperties;
        }
      ''';
        expect(
          collapseWhitespace(classCode),
          contains(collapseWhitespace(expectedMethod)),
        );
      },
    );
  });

  group('ClassGenerator toLabel method for label encoding', () {
    test('generates toLabel for class with only simple properties', () {
      final model = ClassModel(
        name: 'SimpleClass',
        properties: [
          Property(
            name: 'name',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
          Property(
            name: 'age',
            model: IntegerModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ],
        context: context,
      );

      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());
      const expectedMethod = '''
        String toLabel({bool explode = false, bool allowEmpty = true}) {
          return labelProperties(
            allowEmpty: allowEmpty,
          ).toLabel(explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true);
        }
      ''';
      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test(
      'generates toLabel for class with composite properties requiring '
      'runtime checks',
      () {
        final model = ClassModel(
          name: 'CompositeClass',
          properties: [
            Property(
              name: 'name',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
            Property(
              name: 'value',
              model: OneOfModel(
                context: context,
                name: 'Value',
                discriminator: 'type',
                models: {
                  (
                    discriminatorValue: 'string',
                    model: StringModel(context: context),
                  ),
                  (
                    discriminatorValue: 'integer',
                    model: IntegerModel(context: context),
                  ),
                },
              ),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          context: context,
        );

        final generatedClass = generator.generateClass(model);
        final classCode = format(generatedClass.accept(emitter).toString());
        const expectedMethod = '''
        String toLabel({bool explode = false, bool allowEmpty = true}) {
          return labelProperties(
            allowEmpty: allowEmpty,
          ).toLabel(explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true);
        }
      ''';
        expect(
          collapseWhitespace(classCode),
          contains(collapseWhitespace(expectedMethod)),
        );
      },
    );

    test(
      'generates toLabel for class with mixed properties including '
      'nullable composites',
      () {
        final model = ClassModel(
          name: 'MixedClass',
          properties: [
            Property(
              name: 'id',
              model: IntegerModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
            Property(
              name: 'optionalValue',
              model: AnyOfModel(
                context: context,
                name: 'OptionalValue',
                discriminator: 'type',
                models: {
                  (
                    discriminatorValue: 'date',
                    model: DateTimeModel(context: context),
                  ),
                  (
                    discriminatorValue: 'decimal',
                    model: DecimalModel(context: context),
                  ),
                },
              ),
              isRequired: false,
              isNullable: true,
              isDeprecated: false,
            ),
          ],
          context: context,
        );

        final generatedClass = generator.generateClass(model);
        final classCode = format(generatedClass.accept(emitter).toString());
        const expectedMethod = '''
        String toLabel({bool explode = false, bool allowEmpty = true}) {
          return labelProperties(
            allowEmpty: allowEmpty,
          ).toLabel(explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true);
        }
      ''';
        expect(
          collapseWhitespace(classCode),
          contains(collapseWhitespace(expectedMethod)),
        );
      },
    );

    test('generates toLabel for empty class', () {
      final model = ClassModel(
        name: 'EmptyClass',
        properties: const [],
        context: context,
      );

      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());
      const expectedMethod = '''
        String toLabel({bool explode = false, bool allowEmpty = true}) {
          return labelProperties(
            allowEmpty: allowEmpty,
          ).toLabel(explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true);
        }
      ''';
      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });
  });
}
