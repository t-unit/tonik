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

      final result = generator.generateClass(model);
      final parameterPropertiesMethod = result.methods.firstWhere(
        (m) => m.name == 'parameterProperties',
      );

      expect(parameterPropertiesMethod.type, isNot(MethodType.getter));
      expect(
        parameterPropertiesMethod.returns?.accept(emitter).toString(),
        'Map<String,String>',
      );
      expect(parameterPropertiesMethod.optionalParameters.length, 2);

      final allowEmptyParam = parameterPropertiesMethod.optionalParameters
          .firstWhere((p) => p.name == 'allowEmpty');
      expect(allowEmptyParam.named, isTrue);
      expect(allowEmptyParam.required, isFalse);
      expect(
        allowEmptyParam.defaultTo?.accept(emitter).toString(),
        'true',
      );
      expect(
        allowEmptyParam.type?.accept(emitter).toString(),
        'bool',
      );

      final allowListsParam = parameterPropertiesMethod.optionalParameters
          .firstWhere((p) => p.name == 'allowLists');
      expect(allowListsParam.named, isTrue);
      expect(allowListsParam.required, isFalse);
      expect(
        allowListsParam.defaultTo?.accept(emitter).toString(),
        'true',
      );
      expect(
        allowListsParam.type?.accept(emitter).toString(),
        'bool',
      );
    });

    test(
      'generates parameterProperties method body for simple properties',
      () {
        final model = ClassModel(
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
Map<String, String> parameterProperties({
  bool allowEmpty = true,
  bool allowLists = true,
}) {
  final result = <String, String>{};
  result[r'id'] = id.uriEncode(allowEmpty: allowEmpty);
  if (name != null) {
    result[r'name'] = name!.uriEncode(allowEmpty: allowEmpty);
  } else if (allowEmpty) {
    result[r'name'] = '';
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
        isDeprecated: false,
        name: 'Empty',
        properties: const [],
        context: context,
      );

      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());

      const expectedMethod = '''
Map<String, String> parameterProperties({
  bool allowEmpty = true,
  bool allowLists = true,
}) {
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
        isDeprecated: false,
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
Map<String, String> parameterProperties({
  bool allowEmpty = true,
  bool allowLists = true,
}) {
  final result = <String, String>{};
  if (nullableName != null) {
    result[r'nullable_name'] = nullableName!.uriEncode(
      allowEmpty: allowEmpty,
    );
  } else if (allowEmpty) {
    result[r'nullable_name'] = '';
  }
  if (nullableCount != null) {
    result[r'nullable_count'] = nullableCount!.uriEncode(
      allowEmpty: allowEmpty,
    );
  } else if (allowEmpty) {
    result[r'nullable_count'] = '';
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
          isDeprecated: false,
          name: 'Address',
          properties: const [],
          context: context,
        );

        final model = ClassModel(
          isDeprecated: false,
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
Map<String, String> parameterProperties({
  bool allowEmpty = true,
  bool allowLists = true,
}) =>
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
    test(
      'encodes oneOf property based on runtime encoding shape',
      () {
        final oneOfModel = OneOfModel(
          isDeprecated: false,
          name: 'StringOrClass',
          models: {
            (discriminatorValue: null, model: StringModel(context: context)),
            (
              discriminatorValue: null,
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
            ),
          },
          context: context,
        );

        final model = ClassModel(
          isDeprecated: false,
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
Map<String, String> parameterProperties({
  bool allowEmpty = true,
  bool allowLists = true,
}) {
  final result = <String, String>{};
  if (value.currentEncodingShape == EncodingShape.simple) {
    result[r'value'] = value.toSimple(explode: false, allowEmpty: allowEmpty);
  } else {
    throw EncodingException(
      'parameterProperties not supported for Container: contains complex types',
    );
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
      'encodes anyOf property based on runtime encoding shape',
      () {
        final anyOfModel = AnyOfModel(
          isDeprecated: false,
          name: 'StringOrInt',
          models: {
            (discriminatorValue: null, model: StringModel(context: context)),
            (
              discriminatorValue: null,
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
          context: context,
        );

        final model = ClassModel(
          isDeprecated: false,
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
Map<String, String> parameterProperties({
  bool allowEmpty = true,
  bool allowLists = true,
}) {
  final result = <String, String>{};
  if (data.currentEncodingShape == EncodingShape.simple) {
    result[r'data'] = data.toSimple(explode: false, allowEmpty: allowEmpty);
  } else {
    throw EncodingException(
      'parameterProperties not supported for FlexibleContainer: contains complex types',
    );
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
      'encodes allOf property based on runtime encoding shape',
      () {
        final stringModel = StringModel(context: context);
        final complexModel = ClassModel(
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
        );

        final allOfModel = AllOfModel(
          isDeprecated: false,
          name: 'StringAndInt',
          models: {stringModel, complexModel},
          context: context,
        );

        final model = ClassModel(
          isDeprecated: false,
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
Map<String, String> parameterProperties({
  bool allowEmpty = true,
  bool allowLists = true,
}) {
  final result = <String, String>{};
  if (combined.currentEncodingShape == EncodingShape.simple) {
    result[r'combined'] = combined.toSimple(
      explode: false,
      allowEmpty: allowEmpty,
    );
  } else {
    throw EncodingException(
      'parameterProperties not supported for CombinedContainer: contains complex types',
    );
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
      'preserves optimized path for class with only static simple properties',
      () {
        final model = ClassModel(
          isDeprecated: false,
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
Map<String, String> parameterProperties({
  bool allowEmpty = true,
  bool allowLists = true,
}) {
  final result = <String, String>{};
  result[r'name'] = name.uriEncode(allowEmpty: allowEmpty);
  if (count != null) {
    result[r'count'] = count!.uriEncode(allowEmpty: allowEmpty);
  } else if (allowEmpty) {
    result[r'count'] = '';
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
        isDeprecated: false,
        name: 'ComplexContainer',
        properties: [
          Property(
            name: 'nested',
            model: ClassModel(
              isDeprecated: false,
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
  bool allowLists = true,
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
      'encodes optional oneOf property based on runtime encoding shape',
      () {
        final oneOfModel = OneOfModel(
          isDeprecated: false,
          name: 'StringOrClass',
          models: {
            (discriminatorValue: null, model: StringModel(context: context)),
            (
              discriminatorValue: null,
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
            ),
          },
          context: context,
        );

        final model = ClassModel(
          isDeprecated: false,
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
Map<String, String> parameterProperties({
  bool allowEmpty = true,
  bool allowLists = true,
}) {
  final result = <String, String>{};
  if (value != null) {
    if (value!.currentEncodingShape == EncodingShape.simple) {
      result[r'value'] = value!.toSimple(
        explode: false,
        allowEmpty: allowEmpty,
      );
    } else {
      throw EncodingException(
        'parameterProperties not supported for Container: contains complex types',
      );
    }
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
          isDeprecated: false,
          name: 'StringOrInt1',
          models: {
            (discriminatorValue: null, model: StringModel(context: context)),
            (
              discriminatorValue: null,
              model: ClassModel(
                isDeprecated: false,
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
          context: context,
        );

        final oneOfModel2 = OneOfModel(
          isDeprecated: false,
          name: 'StringOrInt2',
          models: {
            (discriminatorValue: null, model: StringModel(context: context)),
            (
              discriminatorValue: null,
              model: ClassModel(
                isDeprecated: false,
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
          context: context,
        );

        final anyOfModel = AnyOfModel(
          isDeprecated: false,
          name: 'FlexibleData',
          models: {
            (discriminatorValue: null, model: StringModel(context: context)),
            (
              discriminatorValue: null,
              model: ClassModel(
                isDeprecated: false,
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
          context: context,
        );

        final model = ClassModel(
          isDeprecated: false,
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
Map<String, String> parameterProperties({
  bool allowEmpty = true,
  bool allowLists = true,
}) {
  final result = <String, String>{};
  result[r'name'] = name.uriEncode(allowEmpty: allowEmpty);
  if (count != null) {
    result[r'count'] = count.uriEncode(allowEmpty: allowEmpty);
  } else if (allowEmpty) {
    result[r'count'] = '';
  }
  result[r'active'] = active.uriEncode(allowEmpty: allowEmpty);
  if (data1.currentEncodingShape == EncodingShape.simple) {
    result[r'data1'] = data1.toSimple(explode: false, allowEmpty: allowEmpty);
  } else {
    throw EncodingException(
      'parameterProperties not supported for MixedContainer: contains complex types',
    );
  }
  if (data2 != null) {
    if (data2!.currentEncodingShape == EncodingShape.simple) {
      result[r'data2'] = data2!.toSimple(
        explode: false,
        allowEmpty: allowEmpty,
      );
    } else {
      throw EncodingException(
        'parameterProperties not supported for MixedContainer: contains complex types',
      );
    }
  }
  if (flexible.currentEncodingShape == EncodingShape.simple) {
    result[r'flexible'] = flexible.toSimple(
      explode: false,
      allowEmpty: allowEmpty,
    );
  } else {
    throw EncodingException(
      'parameterProperties not supported for MixedContainer: contains complex types',
    );
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
      'generates parameterProperties for class with list of simple types',
      () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'ListContainer',
          properties: [
            Property(
              name: 'tags',
              model: ListModel(
                content: StringModel(context: context),
                context: context,
              ),
              isRequired: false,
              isNullable: true,
              isDeprecated: false,
            ),
          ],
          context: context,
        );

        final result = generator.generateClass(model);
        final classCode = format(result.accept(emitter).toString());

        final parameterPropertiesMethod = result.methods.firstWhere(
          (m) => m.name == 'parameterProperties',
        );

        expect(parameterPropertiesMethod, isNotNull);

        const expectedMethod = '''
Map<String, String> parameterProperties({
  bool allowEmpty = true,
  bool allowLists = true,
}) {
  if (!allowLists && tags != null) {
    throw EncodingException('Lists are not supported in this encoding style');
  }
  final result = <String, String>{};
  if (tags != null) {
    result[r'tags'] = tags!.uriEncode(allowEmpty: allowEmpty);
  } else if (allowEmpty) {
    result[r'tags'] = '';
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
      'generates parameterProperties for class with multiple lists of '
      'simple types',
      () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'MultiListContainer',
          properties: [
            Property(
              name: 'ids',
              model: ListModel(
                content: IntegerModel(context: context),
                context: context,
              ),
              isRequired: false,
              isNullable: true,
              isDeprecated: false,
            ),
            Property(
              name: 'tags',
              model: ListModel(
                content: StringModel(context: context),
                context: context,
              ),
              isRequired: false,
              isNullable: true,
              isDeprecated: false,
            ),
          ],
          context: context,
        );

        final result = generator.generateClass(model);
        final classCode = format(result.accept(emitter).toString());

        final parameterPropertiesMethod = result.methods.firstWhere(
          (m) => m.name == 'parameterProperties',
        );

        expect(parameterPropertiesMethod, isNotNull);

        const expectedMethod = '''
Map<String, String> parameterProperties({
  bool allowEmpty = true,
  bool allowLists = true,
}) {
  if (!allowLists && ids != null) {
    throw EncodingException('Lists are not supported in this encoding style');
  }
  if (!allowLists && tags != null) {
    throw EncodingException('Lists are not supported in this encoding style');
  }
  final result = <String, String>{};
  if (ids != null) {
    result[r'ids'] = ids!
        .map((e) => e.uriEncode(allowEmpty: allowEmpty))
        .toList()
        .uriEncode(allowEmpty: allowEmpty);
  } else if (allowEmpty) {
    result[r'ids'] = '';
  }
  if (tags != null) {
    result[r'tags'] = tags!.uriEncode(allowEmpty: allowEmpty);
  } else if (allowEmpty) {
    result[r'tags'] = '';
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
      'generates parameterProperties for class with required list of '
      'simple types',
      () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'RequiredListContainer',
          properties: [
            Property(
              name: 'tags',
              model: ListModel(
                content: StringModel(context: context),
                context: context,
              ),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          context: context,
        );

        final result = generator.generateClass(model);
        final classCode = format(result.accept(emitter).toString());

        final parameterPropertiesMethod = result.methods.firstWhere(
          (m) => m.name == 'parameterProperties',
        );

        expect(parameterPropertiesMethod, isNotNull);

        const expectedMethod = '''
Map<String, String> parameterProperties({
  bool allowEmpty = true,
  bool allowLists = true,
}) {
  if (!allowLists) {
    throw EncodingException('Lists are not supported in this encoding style');
  }
  final result = <String, String>{};
  result[r'tags'] = tags.uriEncode(allowEmpty: allowEmpty);
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
      'generates parameterProperties for class with mixed simple properties '
      'and lists',
      () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'MixedContainer',
          properties: [
            Property(
              name: 'id',
              model: IntegerModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
            Property(
              name: 'tags',
              model: ListModel(
                content: StringModel(context: context),
                context: context,
              ),
              isRequired: false,
              isNullable: true,
              isDeprecated: false,
            ),
          ],
          context: context,
        );

        final result = generator.generateClass(model);
        final classCode = format(result.accept(emitter).toString());

        final parameterPropertiesMethod = result.methods.firstWhere(
          (m) => m.name == 'parameterProperties',
        );

        expect(parameterPropertiesMethod, isNotNull);

        const expectedMethod = '''
Map<String, String> parameterProperties({
  bool allowEmpty = true,
  bool allowLists = true,
}) {
  if (!allowLists && tags != null) {
    throw EncodingException('Lists are not supported in this encoding style');
  }
  final result = <String, String>{};
  result[r'id'] = id.uriEncode(allowEmpty: allowEmpty);
  if (tags != null) {
    result[r'tags'] = tags!.uriEncode(allowEmpty: allowEmpty);
  } else if (allowEmpty) {
    result[r'tags'] = '';
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
      'throws exception for class with list of complex types',
      () {
        final complexModel = ClassModel(
          isDeprecated: false,
          name: 'ComplexItem',
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

        final model = ClassModel(
          isDeprecated: false,
          name: 'ComplexListContainer',
          properties: [
            Property(
              name: 'items',
              model: ListModel(
                content: complexModel,
                context: context,
              ),
              isRequired: false,
              isNullable: true,
              isDeprecated: false,
            ),
          ],
          context: context,
        );

        final result = generator.generateClass(model);
        final classCode = format(result.accept(emitter).toString());

        final parameterPropertiesMethod = result.methods.firstWhere(
          (m) => m.name == 'parameterProperties',
        );

        expect(parameterPropertiesMethod, isNotNull);

        const expectedMethod = '''
Map<String, String> parameterProperties({
  bool allowEmpty = true,
  bool allowLists = true,
}) =>
    throw EncodingException(
      'parameterProperties not supported for ComplexListContainer: contains complex types',
    );
''';

        expect(
          collapseWhitespace(classCode),
          contains(collapseWhitespace(expectedMethod)),
        );
      },
    );

    test(
      'generates parameterProperties for class with list of enums',
      () {
        final enumModel = EnumModel<String>(
          isDeprecated: false,
          name: 'Status',
          values: {
            const EnumEntry(value: 'active'),
            const EnumEntry(value: 'inactive'),
          },
          isNullable: false,
          context: context,
        );

        final model = ClassModel(
          isDeprecated: false,
          name: 'EnumListContainer',
          properties: [
            Property(
              name: 'statuses',
              model: ListModel(
                content: enumModel,
                context: context,
              ),
              isRequired: false,
              isNullable: true,
              isDeprecated: false,
            ),
          ],
          context: context,
        );

        final result = generator.generateClass(model);
        final classCode = format(result.accept(emitter).toString());

        final parameterPropertiesMethod = result.methods.firstWhere(
          (m) => m.name == 'parameterProperties',
        );

        expect(parameterPropertiesMethod, isNotNull);

        const expectedMethod = '''
Map<String, String> parameterProperties({
  bool allowEmpty = true,
  bool allowLists = true,
}) {
  if (!allowLists && statuses != null) {
    throw EncodingException('Lists are not supported in this encoding style');
  }
  final result = <String, String>{};
  if (statuses != null) {
    result[r'statuses'] = statuses!
        .map((e) => e.uriEncode(allowEmpty: allowEmpty))
        .toList()
        .uriEncode(allowEmpty: allowEmpty);
  } else if (allowEmpty) {
    result[r'statuses'] = '';
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
      'generates parameterProperties that throws when allowLists=true '
      'and list present',
      () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'Filter',
          properties: [
            Property(
              name: 'tags',
              model: ListModel(
                content: StringModel(context: context),
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
  bool allowLists = true,
}) {
  if (!allowLists) {
    throw EncodingException('Lists are not supported in this encoding style');
  }
  final result = <String, String>{};
  result[r'tags'] = tags.uriEncode(allowEmpty: allowEmpty);
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
      'generates parameterProperties that throws when allowLists=true '
      'and nullable list present',
      () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'Filter',
          properties: [
            Property(
              name: 'tags',
              model: ListModel(
                content: StringModel(context: context),
                context: context,
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
Map<String, String> parameterProperties({
  bool allowEmpty = true,
  bool allowLists = true,
}) {
  if (!allowLists && tags != null) {
    throw EncodingException('Lists are not supported in this encoding style');
  }
  final result = <String, String>{};
  if (tags != null) {
    result[r'tags'] = tags!.uriEncode(allowEmpty: allowEmpty);
  } else if (allowEmpty) {
    result[r'tags'] = '';
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
      'generates parameterProperties with allowLists for mixed properties',
      () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'Filter',
          properties: [
            Property(
              name: 'name',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
            Property(
              name: 'tags',
              model: ListModel(
                content: StringModel(context: context),
                context: context,
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
Map<String, String> parameterProperties({
  bool allowEmpty = true,
  bool allowLists = true,
}) {
  if (!allowLists && tags != null) {
    throw EncodingException('Lists are not supported in this encoding style');
  }
  final result = <String, String>{};
  result[r'name'] = name.uriEncode(allowEmpty: allowEmpty);
  if (tags != null) {
    result[r'tags'] = tags!.uriEncode(allowEmpty: allowEmpty);
  } else if (allowEmpty) {
    result[r'tags'] = '';
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
      'generates parameterProperties without list check when no lists present',
      () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'User',
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
Map<String, String> parameterProperties({
  bool allowEmpty = true,
  bool allowLists = true,
}) {
  final result = <String, String>{};
  result[r'name'] = name.uriEncode(allowEmpty: allowEmpty);
  result[r'age'] = age.uriEncode(allowEmpty: allowEmpty);
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
