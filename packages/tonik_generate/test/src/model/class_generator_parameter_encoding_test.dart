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

  group('parameterProperties method', () {
    test('generates parameterProperties method signature', () {
      final model = ClassModel(
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

      final result = generator.generateClass(model);
      final parameterPropertiesMethod = result.methods.firstWhere(
        (m) => m.name == 'parameterProperties',
      );

      expect(parameterPropertiesMethod.type, isNot(MethodType.getter));
      expect(
        parameterPropertiesMethod.returns?.accept(emitter).toString(),
        'Map<String,String>',
      );
      expect(parameterPropertiesMethod.optionalParameters.length, 1);
      expect(
        parameterPropertiesMethod.optionalParameters.first.name,
        'allowEmpty',
      );
      expect(
        parameterPropertiesMethod.optionalParameters.first.named,
        isTrue,
      );
      expect(
        parameterPropertiesMethod.optionalParameters.first.required,
        isFalse,
      );
      expect(
        parameterPropertiesMethod.optionalParameters.first.defaultTo
            ?.accept(emitter)
            .toString(),
        'true',
      );
    });

    test(
      'generates parameterProperties method body for simple properties',
      () {
        final model = ClassModel(
          name: 'User',
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
Map<String, String> parameterProperties({bool allowEmpty = true}) {
  final result = <String, String>{};
  result['id'] = id.uriEncode(allowEmpty: allowEmpty);
  if (name != null) {
    result['name'] = name!.uriEncode(allowEmpty: allowEmpty);
  } else if (allowEmpty) {
    result['name'] = '';
  }
  return result;
}
''';

        expect(
          collapseWhitespace(classCode),
          contains(collapseWhitespace(expectedMethod)),
        );
      },
    );

    test('generates parameterProperties method body for empty model', () {
      final model = ClassModel(
        name: 'Empty',
        properties: const [],
        context: context,
      );

      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());

      const expectedMethod = '''
Map<String, String> parameterProperties({bool allowEmpty = true}) {
  return <String, String>{};
}
''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('handles allowEmpty parameter for nullable properties', () {
      final model = ClassModel(
        name: 'Container',
        properties: [
          Property(
            name: 'nullable_name',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: true,
            isDeprecated: false,
          ),
          Property(
            name: 'nullable_count',
            model: IntegerModel(context: context),
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
Map<String, String> parameterProperties({bool allowEmpty = true}) {
  final result = <String, String>{};
  if (nullableName != null) {
    result['nullable_name'] = nullableName!.uriEncode(allowEmpty: allowEmpty);
  } else if (allowEmpty) {
    result['nullable_name'] = '';
  }
  if (nullableCount != null) {
    result['nullable_count'] = nullableCount!.uriEncode(
      allowEmpty: allowEmpty,
    );
  } else if (allowEmpty) {
    result['nullable_count'] = '';
  }
  return result;
}
''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test(
      'generates parameterProperties method that throws for '
      'complex properties',
      () {
        final nestedClass = ClassModel(
          name: 'Address',
          properties: const [],
          context: context,
        );

        final model = ClassModel(
          name: 'User',
          properties: [
            Property(
              name: 'address',
              model: nestedClass,
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
Map<String, String> parameterProperties({bool allowEmpty = true}) =>
  throw EncodingException(
    'parameterProperties not supported for User: contains complex types',
  );
''';

        expect(
          collapseWhitespace(classCode),
          contains(collapseWhitespace(expectedMethod)),
        );
      },
    );
  });

  group('composite model runtime checking for parameterProperties', () {
    test('generates runtime check for class with oneOf property', () {
      final oneOfModel = OneOfModel(
        name: 'StringOrClass',
        models: {
          (discriminatorValue: null, model: StringModel(context: context)),
          (
            discriminatorValue: null,
            model: ClassModel(
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
          ),
        },
        discriminator: null,
        context: context,
      );

      final model = ClassModel(
        name: 'Container',
        properties: [
          Property(
            name: 'value',
            model: oneOfModel,
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
Map<String, String> parameterProperties({bool allowEmpty = true}) {
  final result = <String, String>{};
  if (value.currentEncodingShape != EncodingShape.simple) {
    throw EncodingException(
      'parameterProperties not supported for Container: contains complex types',
    );
  }
  result.addAll(value.parameterProperties(allowEmpty: allowEmpty));
  return result;
}
''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('generates runtime check for class with anyOf property', () {
      final anyOfModel = AnyOfModel(
        name: 'StringOrInt',
        models: {
          (discriminatorValue: null, model: StringModel(context: context)),
          (
            discriminatorValue: null,
            model: ClassModel(
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
        discriminator: null,
        context: context,
      );

      final model = ClassModel(
        name: 'FlexibleContainer',
        properties: [
          Property(
            name: 'data',
            model: anyOfModel,
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
Map<String, String> parameterProperties({bool allowEmpty = true}) {
  final result = <String, String>{};
  if (data.currentEncodingShape != EncodingShape.simple) {
    throw EncodingException(
      'parameterProperties not supported for FlexibleContainer: contains complex types',
    );
  }
  result.addAll(data.parameterProperties(allowEmpty: allowEmpty));
  return result;
}
''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('generates runtime check for class with allOf property', () {
      final stringModel = StringModel(context: context);
      final complexModel = ClassModel(
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
      );

      final allOfModel = AllOfModel(
        name: 'StringAndInt',
        models: {stringModel, complexModel},
        context: context,
      );

      final model = ClassModel(
        name: 'CombinedContainer',
        properties: [
          Property(
            name: 'combined',
            model: allOfModel,
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
Map<String, String> parameterProperties({bool allowEmpty = true}) {
  final result = <String, String>{};
  if (combined.currentEncodingShape != EncodingShape.simple) {
    throw EncodingException(
      'parameterProperties not supported for CombinedContainer: contains complex types',
    );
  }
  result.addAll(combined.parameterProperties(allowEmpty: allowEmpty));
  return result;
}
''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test(
      'preserves optimized path for class with only static simple properties',
      () {
        final model = ClassModel(
          name: 'SimpleContainer',
          properties: [
            Property(
              name: 'name',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
            Property(
              name: 'count',
              model: IntegerModel(context: context),
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
Map<String, String> parameterProperties({bool allowEmpty = true}) {
  final result = <String, String>{};
  result['name'] = name.uriEncode(allowEmpty: allowEmpty);
  if (count != null) {
    result['count'] = count!.uriEncode(allowEmpty: allowEmpty);
  } else if (allowEmpty) {
    result['count'] = '';
  }
  return result;
}
''';

        expect(
          collapseWhitespace(classCode),
          contains(collapseWhitespace(expectedMethod)),
        );
      },
    );

    test('rejects class with truly complex properties at compile time', () {
      final model = ClassModel(
        name: 'ComplexContainer',
        properties: [
          Property(
            name: 'nested',
            model: ClassModel(
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
              context: context,
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
Map<String, String> parameterProperties({
  bool allowEmpty = true,
}) =>
  throw EncodingException(
    'parameterProperties not supported for ComplexContainer: contains complex types',
  );
''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test(
      'generates runtime check with null checks for optional (not required) '
      'oneOf property',
      () {
        final oneOfModel = OneOfModel(
          name: 'StringOrClass',
          models: {
            (discriminatorValue: null, model: StringModel(context: context)),
            (
              discriminatorValue: null,
              model: ClassModel(
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
            ),
          },
          discriminator: null,
          context: context,
        );

        final model = ClassModel(
          name: 'Container',
          properties: [
            Property(
              name: 'value',
              model: oneOfModel,
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
Map<String, String> parameterProperties({bool allowEmpty = true}) {
  final result = <String, String>{};
  if (value != null && value!.currentEncodingShape != EncodingShape.simple) {
    throw EncodingException(
      'parameterProperties not supported for Container: contains complex types',
    );
  }
  if (value != null) {
    result.addAll(value!.parameterProperties(allowEmpty: allowEmpty));
  }
  return result;
}
''';

        expect(
          collapseWhitespace(classCode),
          contains(collapseWhitespace(expectedMethod)),
        );
      },
    );

    test(
      'handles class with multiple properties (mixed optimized/runtime checks)',
      () {
        final oneOfModel1 = OneOfModel(
          name: 'StringOrInt1',
          models: {
            (discriminatorValue: null, model: StringModel(context: context)),
            (
              discriminatorValue: null,
              model: ClassModel(
                name: 'ComplexData1',
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
          discriminator: null,
          context: context,
        );

        final oneOfModel2 = OneOfModel(
          name: 'StringOrInt2',
          models: {
            (discriminatorValue: null, model: StringModel(context: context)),
            (
              discriminatorValue: null,
              model: ClassModel(
                name: 'ComplexData2',
                properties: [
                  Property(
                    name: 'flag',
                    model: BooleanModel(context: context),
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

        final anyOfModel = AnyOfModel(
          name: 'FlexibleData',
          models: {
            (discriminatorValue: null, model: StringModel(context: context)),
            (
              discriminatorValue: null,
              model: ClassModel(
                name: 'FlexibleComplex',
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
              ),
            ),
          },
          discriminator: null,
          context: context,
        );

        final model = ClassModel(
          name: 'MixedContainer',
          properties: [
            // Always simple properties (optimized path)
            Property(
              name: 'name',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
            Property(
              name: 'count',
              model: IntegerModel(context: context),
              isRequired: false,
              isNullable: true,
              isDeprecated: false,
            ),
            Property(
              name: 'active',
              model: BooleanModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
            // Composite properties (runtime checks)
            Property(
              name: 'data1',
              model: oneOfModel1,
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
            Property(
              name: 'data2',
              model: oneOfModel2,
              isRequired: false,
              isNullable: true,
              isDeprecated: false,
            ),
            Property(
              name: 'flexible',
              model: anyOfModel,
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
Map<String, String> parameterProperties({bool allowEmpty = true}) {
  final result = <String, String>{};
  result['name'] = name.uriEncode(allowEmpty: allowEmpty);
  if (count != null) {
    result['count'] = count.uriEncode(allowEmpty: allowEmpty);
  } else if (allowEmpty) {
    result['count'] = '';
  }
  result['active'] = active.uriEncode(allowEmpty: allowEmpty);
  if (data1.currentEncodingShape != EncodingShape.simple) {
    throw EncodingException(
      'parameterProperties not supported for MixedContainer: contains complex types',
    );
  }
  result.addAll(data1.parameterProperties(allowEmpty: allowEmpty));
  if (data2 != null && data2!.currentEncodingShape != EncodingShape.simple) {
    throw EncodingException(
      'parameterProperties not supported for MixedContainer: contains complex types',
    );
  }
  if (data2 != null) {
    result.addAll(data2!.parameterProperties(allowEmpty: allowEmpty));
  }
  if (flexible.currentEncodingShape != EncodingShape.simple) {
    throw EncodingException(
      'parameterProperties not supported for MixedContainer: contains complex types',
    );
  }
  result.addAll(flexible.parameterProperties(allowEmpty: allowEmpty));
  return result;
}
''';

        expect(
          collapseWhitespace(classCode),
          contains(collapseWhitespace(expectedMethod)),
        );
      },
    );
  });
}
