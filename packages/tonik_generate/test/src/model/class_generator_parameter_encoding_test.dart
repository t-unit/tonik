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

  final format = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  ).format;

  setUp(() {
    nameGenerator = NameGenerator();
    nameManager = NameManager(
      generator: nameGenerator,
      stableModelSorter: StableModelSorter(),
    );
    generator = ClassGenerator(
      nameManager: nameManager,
      package: 'example',
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
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: context,
        examples: const [],
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
      expect(parameterPropertiesMethod.optionalParameters.length, 5);

      final allowReservedParam = parameterPropertiesMethod.optionalParameters
          .firstWhere((p) => p.name == 'allowReserved');
      expect(allowReservedParam.named, isTrue);
      expect(allowReservedParam.required, isFalse);
      expect(
        allowReservedParam.defaultTo?.accept(emitter).toString(),
        'false',
      );

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

      final useQueryComponentParam = parameterPropertiesMethod
          .optionalParameters
          .firstWhere((p) => p.name == 'useQueryComponent');
      expect(useQueryComponentParam.named, isTrue);
      expect(useQueryComponentParam.required, isFalse);
      expect(
        useQueryComponentParam.defaultTo?.accept(emitter).toString(),
        'false',
      );
      expect(
        useQueryComponentParam.type?.accept(emitter).toString(),
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
              examples: const [],
              defaultValue: null,
            ),
            Property(
              name: 'name',
              model: StringModel(context: context),
              isRequired: false,
              isNullable: true,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: context,
          examples: const [],
        );

        final generatedClass = generator.generateClass(model);
        final classCode = format(generatedClass.accept(emitter).toString());

        const expectedMethod = r'''
Map<String, String> parameterProperties({
  bool allowEmpty = true,
  bool allowLists = true,
  bool useQueryComponent = false,
  bool allowReserved = false, Map<String, FormFieldEncoding> fieldEncodings = const {},
}) {
  final _$result = <String, String>{};
  _$result[r'id'] = id.uriEncode(
    allowEmpty: allowEmpty,
    useQueryComponent: useQueryComponent,
    allowReserved: fieldEncodings[r'id']?.allowReserved ?? allowReserved,
  );
  if (name != null) {
    _$result[r'name'] = name!.uriEncode(
      allowEmpty: allowEmpty,
      useQueryComponent: useQueryComponent,
      allowReserved: fieldEncodings[r'name']?.allowReserved ?? allowReserved,
    );
  } else if (allowEmpty) {
    _$result[r'name'] = '';
  }
  return _$result;
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
        examples: const [],
      );

      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());

      const expectedMethod = '''
Map<String, String> parameterProperties({
  bool allowEmpty = true,
  bool allowLists = true,
  bool useQueryComponent = false,
  bool allowReserved = false, Map<String, FormFieldEncoding> fieldEncodings = const {},
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
            examples: const [],
            defaultValue: null,
          ),
          Property(
            name: 'nullable_count',
            model: IntegerModel(context: context),
            isRequired: true,
            isNullable: true,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: context,
        examples: const [],
      );

      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());

      const expectedMethod = r'''
Map<String, String> parameterProperties({
  bool allowEmpty = true,
  bool allowLists = true,
  bool useQueryComponent = false,
  bool allowReserved = false, Map<String, FormFieldEncoding> fieldEncodings = const {},
}) {
  final _$result = <String, String>{};
  if (nullableName != null) {
    _$result[r'nullable_name'] = nullableName!.uriEncode(
      allowEmpty: allowEmpty,
      useQueryComponent: useQueryComponent,
      allowReserved: fieldEncodings[r'nullable_name']?.allowReserved ?? allowReserved,
    );
  } else if (allowEmpty) {
    _$result[r'nullable_name'] = '';
  }
  if (nullableCount != null) {
    _$result[r'nullable_count'] = nullableCount!.uriEncode(
      allowEmpty: allowEmpty,
      useQueryComponent: useQueryComponent,
      allowReserved: fieldEncodings[r'nullable_count']?.allowReserved ?? allowReserved,
    );
  } else if (allowEmpty) {
    _$result[r'nullable_count'] = '';
  }
  return _$result;
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
          examples: const [],
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
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: context,
          examples: const [],
        );

        final generatedClass = generator.generateClass(model);
        final classCode = format(generatedClass.accept(emitter).toString());

        const expectedMethod = '''
Map<String, String> parameterProperties({
  bool allowEmpty = true,
  bool allowLists = true,
  bool useQueryComponent = false,
  bool allowReserved = false, Map<String, FormFieldEncoding> fieldEncodings = const {},
}) =>
  throw EncodingException(
    r'parameterProperties not supported for User: contains complex types',
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
                    examples: const [],
                    defaultValue: null,
                  ),
                ],
                context: context,
                examples: const [],
              ),
            ),
          },
          context: context,
          examples: const [],
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
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: context,
          examples: const [],
        );

        final generatedClass = generator.generateClass(model);
        final classCode = format(generatedClass.accept(emitter).toString());

        const expectedMethod = r'''
Map<String, String> parameterProperties({
  bool allowEmpty = true,
  bool allowLists = true,
  bool useQueryComponent = false,
  bool allowReserved = false, Map<String, FormFieldEncoding> fieldEncodings = const {},
}) {
  final _$result = <String, String>{};
  if (value.currentEncodingShape == EncodingShape.simple) {
    _$result[r'value'] = value.toSimple(
      explode: false,
      allowEmpty: allowEmpty,
    );
  } else {
    throw EncodingException(
      r'parameterProperties not supported for Container: contains complex types',
    );
  }
  return _$result;
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
                    examples: const [],
                    defaultValue: null,
                  ),
                ],
                context: context,
                examples: const [],
              ),
            ),
          },
          context: context,
          examples: const [],
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
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: context,
          examples: const [],
        );

        final generatedClass = generator.generateClass(model);
        final classCode = format(generatedClass.accept(emitter).toString());

        const expectedMethod = r'''
Map<String, String> parameterProperties({
  bool allowEmpty = true,
  bool allowLists = true,
  bool useQueryComponent = false,
  bool allowReserved = false, Map<String, FormFieldEncoding> fieldEncodings = const {},
}) {
  final _$result = <String, String>{};
  if (data.currentEncodingShape == EncodingShape.simple) {
    _$result[r'data'] = data.toSimple(explode: false, allowEmpty: allowEmpty);
  } else {
    throw EncodingException(
      r'parameterProperties not supported for FlexibleContainer: contains complex types',
    );
  }
  return _$result;
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
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: context,
          examples: const [],
        );

        final allOfModel = AllOfModel(
          isDeprecated: false,
          name: 'StringAndInt',
          models: {stringModel, complexModel},
          context: context,
          examples: const [],
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
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: context,
          examples: const [],
        );

        final generatedClass = generator.generateClass(model);
        final classCode = format(generatedClass.accept(emitter).toString());

        const expectedMethod = r'''
Map<String, String> parameterProperties({
  bool allowEmpty = true,
  bool allowLists = true,
  bool useQueryComponent = false,
  bool allowReserved = false, Map<String, FormFieldEncoding> fieldEncodings = const {},
}) {
  final _$result = <String, String>{};
  if (combined.currentEncodingShape == EncodingShape.simple) {
    _$result[r'combined'] = combined.toSimple(
      explode: false,
      allowEmpty: allowEmpty,
    );
  } else {
    throw EncodingException(
      r'parameterProperties not supported for CombinedContainer: contains complex types',
    );
  }
  return _$result;
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
              examples: const [],
              defaultValue: null,
            ),
            Property(
              name: 'count',
              model: IntegerModel(context: context),
              isRequired: false,
              isNullable: true,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: context,
          examples: const [],
        );

        final generatedClass = generator.generateClass(model);
        final classCode = format(generatedClass.accept(emitter).toString());

        const expectedMethod = r'''
Map<String, String> parameterProperties({
  bool allowEmpty = true,
  bool allowLists = true,
  bool useQueryComponent = false,
  bool allowReserved = false, Map<String, FormFieldEncoding> fieldEncodings = const {},
}) {
  final _$result = <String, String>{};
  _$result[r'name'] = name.uriEncode(
    allowEmpty: allowEmpty,
    useQueryComponent: useQueryComponent,
    allowReserved: fieldEncodings[r'name']?.allowReserved ?? allowReserved,
  );
  if (count != null) {
    _$result[r'count'] = count!.uriEncode(
      allowEmpty: allowEmpty,
      useQueryComponent: useQueryComponent,
      allowReserved: fieldEncodings[r'count']?.allowReserved ?? allowReserved,
    );
  } else if (allowEmpty) {
    _$result[r'count'] = '';
  }
  return _$result;
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
                  examples: const [],
                  defaultValue: null,
                ),
              ],
              context: context,
              examples: const [],
            ),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: context,
        examples: const [],
      );

      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());

      const expectedMethod = '''
Map<String, String> parameterProperties({
  bool allowEmpty = true,
  bool allowLists = true,
  bool useQueryComponent = false,
  bool allowReserved = false, Map<String, FormFieldEncoding> fieldEncodings = const {},
}) =>
  throw EncodingException(
    r'parameterProperties not supported for ComplexContainer: contains complex types',
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
                    examples: const [],
                    defaultValue: null,
                  ),
                ],
                context: context,
                examples: const [],
              ),
            ),
          },
          context: context,
          examples: const [],
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
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: context,
          examples: const [],
        );

        final generatedClass = generator.generateClass(model);
        final classCode = format(generatedClass.accept(emitter).toString());

        const expectedMethod = r'''
Map<String, String> parameterProperties({
  bool allowEmpty = true,
  bool allowLists = true,
  bool useQueryComponent = false,
  bool allowReserved = false, Map<String, FormFieldEncoding> fieldEncodings = const {},
}) {
  final _$result = <String, String>{};
  if (value != null) {
    if (value!.currentEncodingShape == EncodingShape.simple) {
      _$result[r'value'] = value!.toSimple(
        explode: false,
        allowEmpty: allowEmpty,
      );
    } else {
      throw EncodingException(
        r'parameterProperties not supported for Container: contains complex types',
      );
    }
  }
  return _$result;
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
                    examples: const [],
                    defaultValue: null,
                  ),
                ],
                context: context,
                examples: const [],
              ),
            ),
          },
          context: context,
          examples: const [],
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
                    examples: const [],
                    defaultValue: null,
                  ),
                ],
                context: context,
                examples: const [],
              ),
            ),
          },
          context: context,
          examples: const [],
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
                    examples: const [],
                    defaultValue: null,
                  ),
                ],
                context: context,
                examples: const [],
              ),
            ),
          },
          context: context,
          examples: const [],
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
              examples: const [],
              defaultValue: null,
            ),
            Property(
              name: 'count',
              model: IntegerModel(context: context),
              isRequired: false,
              isNullable: true,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
            Property(
              name: 'active',
              model: BooleanModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
            // Composite properties (runtime checks)
            Property(
              name: 'data1',
              model: oneOfModel1,
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
            Property(
              name: 'data2',
              model: oneOfModel2,
              isRequired: false,
              isNullable: true,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
            Property(
              name: 'flexible',
              model: anyOfModel,
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: context,
          examples: const [],
        );

        final generatedClass = generator.generateClass(model);
        final classCode = format(generatedClass.accept(emitter).toString());

        const expectedMethod = r'''
Map<String, String> parameterProperties({
  bool allowEmpty = true,
  bool allowLists = true,
  bool useQueryComponent = false,
  bool allowReserved = false, Map<String, FormFieldEncoding> fieldEncodings = const {},
}) {
  final _$result = <String, String>{};
  _$result[r'name'] = name.uriEncode(
    allowEmpty: allowEmpty,
    useQueryComponent: useQueryComponent,
    allowReserved: fieldEncodings[r'name']?.allowReserved ?? allowReserved,
  );
  if (count != null) {
    _$result[r'count'] = count!.uriEncode(
      allowEmpty: allowEmpty,
      useQueryComponent: useQueryComponent,
      allowReserved: fieldEncodings[r'count']?.allowReserved ?? allowReserved,
    );
  } else if (allowEmpty) {
    _$result[r'count'] = '';
  }
  _$result[r'active'] = active.uriEncode(
    allowEmpty: allowEmpty,
    useQueryComponent: useQueryComponent,
    allowReserved: fieldEncodings[r'active']?.allowReserved ?? allowReserved,
  );
  if (data1.currentEncodingShape == EncodingShape.simple) {
    _$result[r'data1'] = data1.toSimple(
      explode: false,
      allowEmpty: allowEmpty,
    );
  } else {
    throw EncodingException(
      r'parameterProperties not supported for MixedContainer: contains complex types',
    );
  }
  if (data2 != null) {
    if (data2!.currentEncodingShape == EncodingShape.simple) {
      _$result[r'data2'] = data2!.toSimple(
        explode: false,
        allowEmpty: allowEmpty,
      );
    } else {
      throw EncodingException(
        r'parameterProperties not supported for MixedContainer: contains complex types',
      );
    }
  }
  if (flexible.currentEncodingShape == EncodingShape.simple) {
    _$result[r'flexible'] = flexible.toSimple(
      explode: false,
      allowEmpty: allowEmpty,
    );
  } else {
    throw EncodingException(
      r'parameterProperties not supported for MixedContainer: contains complex types',
    );
  }
  return _$result;
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
                examples: const [],
              ),
              isRequired: false,
              isNullable: true,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: context,
          examples: const [],
        );

        final result = generator.generateClass(model);
        final classCode = format(result.accept(emitter).toString());

        final parameterPropertiesMethod = result.methods.firstWhere(
          (m) => m.name == 'parameterProperties',
        );

        expect(parameterPropertiesMethod, isNotNull);

        const expectedMethod = r'''
Map<String, String> parameterProperties({
  bool allowEmpty = true,
  bool allowLists = true,
  bool useQueryComponent = false,
  bool allowReserved = false, Map<String, FormFieldEncoding> fieldEncodings = const {},
}) {
  if (!allowLists && tags != null) {
    throw EncodingException('Lists are not supported in this encoding style');
  }
  final _$result = <String, String>{};
  if (tags != null) {
    _$result[r'tags'] = tags!.uriEncode(
      allowEmpty: allowEmpty,
      useQueryComponent: useQueryComponent,
      allowReserved: fieldEncodings[r'tags']?.allowReserved ?? allowReserved,
    );
  } else if (allowEmpty) {
    _$result[r'tags'] = '';
  }
  return _$result;
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
                examples: const [],
              ),
              isRequired: false,
              isNullable: true,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
            Property(
              name: 'tags',
              model: ListModel(
                content: StringModel(context: context),
                context: context,
                examples: const [],
              ),
              isRequired: false,
              isNullable: true,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: context,
          examples: const [],
        );

        final result = generator.generateClass(model);
        final classCode = format(result.accept(emitter).toString());

        final parameterPropertiesMethod = result.methods.firstWhere(
          (m) => m.name == 'parameterProperties',
        );

        expect(parameterPropertiesMethod, isNotNull);

        const expectedMethod = r'''
Map<String, String> parameterProperties({
  bool allowEmpty = true,
  bool allowLists = true,
  bool useQueryComponent = false,
  bool allowReserved = false, Map<String, FormFieldEncoding> fieldEncodings = const {},
}) {
  if (!allowLists && ids != null) {
    throw EncodingException('Lists are not supported in this encoding style');
  }
  if (!allowLists && tags != null) {
    throw EncodingException('Lists are not supported in this encoding style');
  }
  final _$result = <String, String>{};
  if (ids != null) {
    _$result[r'ids'] = ids!
        .map(
          (e) => e.uriEncode(
            allowEmpty: allowEmpty,
            useQueryComponent: useQueryComponent,
            allowReserved: fieldEncodings[r'ids']?.allowReserved ?? allowReserved,
          ),
        )
        .toList()
        .uriEncode(
          allowEmpty: allowEmpty,
          useQueryComponent: useQueryComponent,
          allowReserved: fieldEncodings[r'ids']?.allowReserved ?? allowReserved,
        );
  } else if (allowEmpty) {
    _$result[r'ids'] = '';
  }
  if (tags != null) {
    _$result[r'tags'] = tags!.uriEncode(
      allowEmpty: allowEmpty,
      useQueryComponent: useQueryComponent,
      allowReserved: fieldEncodings[r'tags']?.allowReserved ?? allowReserved,
    );
  } else if (allowEmpty) {
    _$result[r'tags'] = '';
  }
  return _$result;
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
                examples: const [],
              ),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: context,
          examples: const [],
        );

        final result = generator.generateClass(model);
        final classCode = format(result.accept(emitter).toString());

        final parameterPropertiesMethod = result.methods.firstWhere(
          (m) => m.name == 'parameterProperties',
        );

        expect(parameterPropertiesMethod, isNotNull);

        const expectedMethod = r'''
Map<String, String> parameterProperties({
  bool allowEmpty = true,
  bool allowLists = true,
  bool useQueryComponent = false,
  bool allowReserved = false, Map<String, FormFieldEncoding> fieldEncodings = const {},
}) {
  if (!allowLists) {
    throw EncodingException('Lists are not supported in this encoding style');
  }
  final _$result = <String, String>{};
  _$result[r'tags'] = tags.uriEncode(
    allowEmpty: allowEmpty,
    useQueryComponent: useQueryComponent,
    allowReserved: fieldEncodings[r'tags']?.allowReserved ?? allowReserved,
  );
  return _$result;
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
              examples: const [],
              defaultValue: null,
            ),
            Property(
              name: 'tags',
              model: ListModel(
                content: StringModel(context: context),
                context: context,
                examples: const [],
              ),
              isRequired: false,
              isNullable: true,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: context,
          examples: const [],
        );

        final result = generator.generateClass(model);
        final classCode = format(result.accept(emitter).toString());

        final parameterPropertiesMethod = result.methods.firstWhere(
          (m) => m.name == 'parameterProperties',
        );

        expect(parameterPropertiesMethod, isNotNull);

        const expectedMethod = r'''
Map<String, String> parameterProperties({
  bool allowEmpty = true,
  bool allowLists = true,
  bool useQueryComponent = false,
  bool allowReserved = false, Map<String, FormFieldEncoding> fieldEncodings = const {},
}) {
  if (!allowLists && tags != null) {
    throw EncodingException('Lists are not supported in this encoding style');
  }
  final _$result = <String, String>{};
  _$result[r'id'] = id.uriEncode(
    allowEmpty: allowEmpty,
    useQueryComponent: useQueryComponent,
    allowReserved: fieldEncodings[r'id']?.allowReserved ?? allowReserved,
  );
  if (tags != null) {
    _$result[r'tags'] = tags!.uriEncode(
      allowEmpty: allowEmpty,
      useQueryComponent: useQueryComponent,
      allowReserved: fieldEncodings[r'tags']?.allowReserved ?? allowReserved,
    );
  } else if (allowEmpty) {
    _$result[r'tags'] = '';
  }
  return _$result;
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
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: context,
          examples: const [],
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
                examples: const [],
              ),
              isRequired: false,
              isNullable: true,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: context,
          examples: const [],
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
  bool useQueryComponent = false,
  bool allowReserved = false, Map<String, FormFieldEncoding> fieldEncodings = const {},
}) =>
    throw EncodingException(
      r'parameterProperties not supported for ComplexListContainer: contains complex types',
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
          examples: const [],
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
                examples: const [],
              ),
              isRequired: false,
              isNullable: true,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: context,
          examples: const [],
        );

        final result = generator.generateClass(model);
        final classCode = format(result.accept(emitter).toString());

        final parameterPropertiesMethod = result.methods.firstWhere(
          (m) => m.name == 'parameterProperties',
        );

        expect(parameterPropertiesMethod, isNotNull);

        const expectedMethod = r'''
Map<String, String> parameterProperties({
  bool allowEmpty = true,
  bool allowLists = true,
  bool useQueryComponent = false,
  bool allowReserved = false, Map<String, FormFieldEncoding> fieldEncodings = const {},
}) {
  if (!allowLists && statuses != null) {
    throw EncodingException('Lists are not supported in this encoding style');
  }
  final _$result = <String, String>{};
  if (statuses != null) {
    _$result[r'statuses'] = statuses!
        .map(
          (e) => e.uriEncode(
            allowEmpty: allowEmpty,
            useQueryComponent: useQueryComponent,
            allowReserved: fieldEncodings[r'statuses']?.allowReserved ?? allowReserved,
          ),
        )
        .toList()
        .uriEncode(
          allowEmpty: allowEmpty,
          useQueryComponent: useQueryComponent,
          allowReserved: fieldEncodings[r'statuses']?.allowReserved ?? allowReserved,
        );
  } else if (allowEmpty) {
    _$result[r'statuses'] = '';
  }
  return _$result;
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
                examples: const [],
              ),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: context,
          examples: const [],
        );

        final generatedClass = generator.generateClass(model);
        final classCode = format(generatedClass.accept(emitter).toString());

        const expectedMethod = r'''
Map<String, String> parameterProperties({
  bool allowEmpty = true,
  bool allowLists = true,
  bool useQueryComponent = false,
  bool allowReserved = false, Map<String, FormFieldEncoding> fieldEncodings = const {},
}) {
  if (!allowLists) {
    throw EncodingException('Lists are not supported in this encoding style');
  }
  final _$result = <String, String>{};
  _$result[r'tags'] = tags.uriEncode(
    allowEmpty: allowEmpty,
    useQueryComponent: useQueryComponent,
    allowReserved: fieldEncodings[r'tags']?.allowReserved ?? allowReserved,
  );
  return _$result;
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
                examples: const [],
              ),
              isRequired: false,
              isNullable: true,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: context,
          examples: const [],
        );

        final generatedClass = generator.generateClass(model);
        final classCode = format(generatedClass.accept(emitter).toString());

        const expectedMethod = r'''
Map<String, String> parameterProperties({
  bool allowEmpty = true,
  bool allowLists = true,
  bool useQueryComponent = false,
  bool allowReserved = false, Map<String, FormFieldEncoding> fieldEncodings = const {},
}) {
  if (!allowLists && tags != null) {
    throw EncodingException('Lists are not supported in this encoding style');
  }
  final _$result = <String, String>{};
  if (tags != null) {
    _$result[r'tags'] = tags!.uriEncode(
      allowEmpty: allowEmpty,
      useQueryComponent: useQueryComponent,
      allowReserved: fieldEncodings[r'tags']?.allowReserved ?? allowReserved,
    );
  } else if (allowEmpty) {
    _$result[r'tags'] = '';
  }
  return _$result;
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
              examples: const [],
              defaultValue: null,
            ),
            Property(
              name: 'tags',
              model: ListModel(
                content: StringModel(context: context),
                context: context,
                examples: const [],
              ),
              isRequired: false,
              isNullable: true,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: context,
          examples: const [],
        );

        final generatedClass = generator.generateClass(model);
        final classCode = format(generatedClass.accept(emitter).toString());

        const expectedMethod = r'''
Map<String, String> parameterProperties({
  bool allowEmpty = true,
  bool allowLists = true,
  bool useQueryComponent = false,
  bool allowReserved = false, Map<String, FormFieldEncoding> fieldEncodings = const {},
}) {
  if (!allowLists && tags != null) {
    throw EncodingException('Lists are not supported in this encoding style');
  }
  final _$result = <String, String>{};
  _$result[r'name'] = name.uriEncode(
    allowEmpty: allowEmpty,
    useQueryComponent: useQueryComponent,
    allowReserved: fieldEncodings[r'name']?.allowReserved ?? allowReserved,
  );
  if (tags != null) {
    _$result[r'tags'] = tags!.uriEncode(
      allowEmpty: allowEmpty,
      useQueryComponent: useQueryComponent,
      allowReserved: fieldEncodings[r'tags']?.allowReserved ?? allowReserved,
    );
  } else if (allowEmpty) {
    _$result[r'tags'] = '';
  }
  return _$result;
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
              examples: const [],
              defaultValue: null,
            ),
            Property(
              name: 'age',
              model: IntegerModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: context,
          examples: const [],
        );

        final generatedClass = generator.generateClass(model);
        final classCode = format(generatedClass.accept(emitter).toString());

        const expectedMethod = r'''
Map<String, String> parameterProperties({
  bool allowEmpty = true,
  bool allowLists = true,
  bool useQueryComponent = false,
  bool allowReserved = false, Map<String, FormFieldEncoding> fieldEncodings = const {},
}) {
  final _$result = <String, String>{};
  _$result[r'name'] = name.uriEncode(
    allowEmpty: allowEmpty,
    useQueryComponent: useQueryComponent,
    allowReserved: fieldEncodings[r'name']?.allowReserved ?? allowReserved,
  );
  _$result[r'age'] = age.uriEncode(
    allowEmpty: allowEmpty,
    useQueryComponent: useQueryComponent,
    allowReserved: fieldEncodings[r'age']?.allowReserved ?? allowReserved,
  );
  return _$result;
}
''';

        expect(
          collapseWhitespace(classCode),
          contains(collapseWhitespace(expectedMethod)),
        );
      },
    );

    test(
      'generates parameterProperties with null check for required property '
      'referencing nullable AliasModel (simple encoding, defaultValue: null)',
      () {
        // AliasModel with isNullable=true means the typedef is
        // `typedef Foo = String?`, so the field type is nullable even though
        // Property.isNullable is false.
        final nullableAlias = AliasModel(
          name: 'NullableDescription',
          model: StringModel(context: context),
          isNullable: true,
          context: context,
          examples: const [],
          defaultValue: null,
        );

        final model = ClassModel(
          isDeprecated: false,
          name: 'Item',
          properties: [
            Property(
              name: 'description',
              model: nullableAlias,
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: context,
          examples: const [],
        );

        final generatedClass = generator.generateClass(model);
        final classCode = format(generatedClass.accept(emitter).toString());

        // Should generate null-aware encoding because the model is nullable
        const expectedMethod = r'''
Map<String, String> parameterProperties({
  bool allowEmpty = true,
  bool allowLists = true,
  bool useQueryComponent = false,
  bool allowReserved = false, Map<String, FormFieldEncoding> fieldEncodings = const {},
}) {
  final _$result = <String, String>{};
  if (description != null) {
    _$result[r'description'] = description!.uriEncode(
      allowEmpty: allowEmpty,
      useQueryComponent: useQueryComponent,
      allowReserved: fieldEncodings[r'description']?.allowReserved ?? allowReserved,
    );
  } else if (allowEmpty) {
    _$result[r'description'] = '';
  }
  return _$result;
}
''';

        expect(
          collapseWhitespace(classCode),
          contains(collapseWhitespace(expectedMethod)),
        );
      },
    );

    test(
      'generates parameterProperties with null check for required property '
      'referencing nullable AliasModel in mixed-shape model',
      () {
        // Same scenario in mixed-shape context
        final nullableAlias = AliasModel(
          name: 'NullableDescription',
          model: StringModel(context: context),
          isNullable: true,
          context: context,
          examples: const [],
          defaultValue: null,
        );

        final model = ClassModel(
          isDeprecated: false,
          name: 'MixedItem',
          properties: [
            Property(
              name: 'description',
              model: nullableAlias,
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
            Property(
              name: 'tags',
              model: ListModel(
                content: StringModel(context: context),
                context: context,
                examples: const [],
              ),
              isRequired: false,
              isNullable: true,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: context,
          examples: const [],
        );

        final generatedClass = generator.generateClass(model);
        final classCode = format(generatedClass.accept(emitter).toString());

        // The simple property with nullable model should have null check
        expect(
          collapseWhitespace(classCode),
          contains(
            collapseWhitespace(r'''
if (description != null) {
  _$result[r'description'] = description!.uriEncode(
    allowEmpty: allowEmpty,
    useQueryComponent: useQueryComponent,
    allowReserved: fieldEncodings[r'description']?.allowReserved ?? allowReserved,
  );
} else if (allowEmpty) {
  _$result[r'description'] = '';
}'''),
          ),
        );
      },
    );

    test(
      'generates parameterProperties with null check for required property '
      'referencing nullable ListModel',
      () {
        // ListModel with isNullable=true
        final model = ClassModel(
          isDeprecated: false,
          name: 'Container',
          properties: [
            Property(
              name: 'items',
              model: ListModel(
                content: StringModel(context: context),
                context: context,
                isNullable: true,
                examples: const [],
              ),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: context,
          examples: const [],
        );

        final generatedClass = generator.generateClass(model);
        final classCode = format(generatedClass.accept(emitter).toString());

        // Should NOT have the unconditional "if (!allowLists)" guard
        // because the list is nullable (even though required)
        expect(
          collapseWhitespace(classCode),
          isNot(
            contains(
              collapseWhitespace(
                'if (!allowLists) {'
                "  throw EncodingException('Lists are not supported",
              ),
            ),
          ),
        );

        // Should have null-aware access
        expect(
          collapseWhitespace(classCode),
          contains(collapseWhitespace('if (items != null)')),
        );
      },
    );

    test(
      'toForm calls parameterProperties with useQueryComponent',
      () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'FormData',
          properties: [
            Property(
              name: 'name',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
            Property(
              name: 'value',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: context,
          examples: const [],
        );

        final generatedClass = generator.generateClass(model);
        final classCode = format(generatedClass.accept(emitter).toString());

        const expectedMethod = '''
List<ParameterEntry> toForm(
  String paramName, {
  required bool explode,
  required bool allowEmpty,
  bool useQueryComponent = false,
  bool allowReserved = false, Map<String, FormFieldEncoding> fieldEncodings = const {},
}) {
  return parameterProperties(
    allowEmpty: allowEmpty,
    useQueryComponent: useQueryComponent,
    allowReserved: allowReserved, fieldEncodings: fieldEncodings,
  ).toForm(
    paramName,
    explode: explode,
    allowEmpty: allowEmpty,
    alreadyEncoded: true,
    useQueryComponent: useQueryComponent,
    fieldEncodings: fieldEncodings,
  );
}
''';

        expect(
          collapseWhitespace(classCode),
          contains(collapseWhitespace(expectedMethod)),
        );
      },
    );

    test(
      'generates null-safe toJson and fromJson for required property '
      'referencing AliasModel that wraps nullable ClassModel',
      () {
        // AliasModel(isNullable: false) wrapping ClassModel(isNullable: true)
        // simulates `typedef Outer = Inner; typedef Inner = $RawInner?;`
        final innerClass = ClassModel(
          isDeprecated: false,
          name: 'Inner',
          properties: [
            Property(
              name: 'value',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: context,
          isNullable: true,
          examples: const [],
        );

        final outerAlias = AliasModel(
          name: 'Outer',
          model: innerClass,
          context: context,
          examples: const [],
          defaultValue: null,
        );

        final model = ClassModel(
          isDeprecated: false,
          name: 'Container',
          properties: [
            Property(
              name: 'inner',
              model: outerAlias,
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: context,
          examples: const [],
        );

        final generatedClass = generator.generateClass(model);
        final classCode = format(generatedClass.accept(emitter).toString());

        // toJson should use null-safe access because the underlying model
        // is nullable via typedef chain
        expect(
          collapseWhitespace(classCode),
          contains(collapseWhitespace("r'inner': inner?.toJson()")),
        );

        // fromJson should use null-safe decoding
        expect(
          collapseWhitespace(classCode),
          contains(
            collapseWhitespace(
              r"_$map[r'inner'] == null ? null "
              r": Inner.fromJson(_$map[r'inner'])",
            ),
          ),
        );
      },
    );

    test(
      'generates parameterProperties with null check for property '
      'referencing nested AliasModel chain where inner alias is nullable',
      () {
        // AliasModel(isNullable: false) wrapping
        //   AliasModel(isNullable: true) wrapping StringModel
        // simulates `typedef Outer = Inner; typedef Inner = String?;`
        final innerAlias = AliasModel(
          name: 'InnerAlias',
          model: StringModel(context: context),
          isNullable: true,
          context: context,
          examples: const [],
          defaultValue: null,
        );

        final outerAlias = AliasModel(
          name: 'OuterAlias',
          model: innerAlias,
          context: context,
          examples: const [],
          defaultValue: null,
        );

        final model = ClassModel(
          isDeprecated: false,
          name: 'Wrapper',
          properties: [
            Property(
              name: 'label',
              model: outerAlias,
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: context,
          examples: const [],
        );

        final generatedClass = generator.generateClass(model);
        final classCode = format(generatedClass.accept(emitter).toString());

        // Should generate null-aware encoding because the nested alias
        // is nullable
        const expectedMethod = r'''
Map<String, String> parameterProperties({
  bool allowEmpty = true,
  bool allowLists = true,
  bool useQueryComponent = false,
  bool allowReserved = false, Map<String, FormFieldEncoding> fieldEncodings = const {},
}) {
  final _$result = <String, String>{};
  if (label != null) {
    _$result[r'label'] = label!.uriEncode(
      allowEmpty: allowEmpty,
      useQueryComponent: useQueryComponent,
      allowReserved: fieldEncodings[r'label']?.allowReserved ?? allowReserved,
    );
  } else if (allowEmpty) {
    _$result[r'label'] = '';
  }
  return _$result;
}
''';

        expect(
          collapseWhitespace(classCode),
          contains(collapseWhitespace(expectedMethod)),
        );
      },
    );

    test(
      'base64-encodes required non-null byte property before percent-encoding',
      () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'Filter',
          properties: [
            Property(
              name: 'signature',
              model: Base64Model(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: context,
          examples: const [],
        );

        final generatedClass = generator.generateClass(model);
        final classCode = format(generatedClass.accept(emitter).toString());

        const expectedMethod = r'''
Map<String, String> parameterProperties({
  bool allowEmpty = true,
  bool allowLists = true,
  bool useQueryComponent = false,
  bool allowReserved = false, Map<String, FormFieldEncoding> fieldEncodings = const {},
}) {
  final _$result = <String, String>{};
  _$result[r'signature'] = signature.toBase64String().uriEncode(
    allowEmpty: allowEmpty,
    useQueryComponent: useQueryComponent,
    allowReserved: fieldEncodings[r'signature']?.allowReserved ?? allowReserved,
  );
  return _$result;
}
''';

        expect(
          collapseWhitespace(classCode),
          contains(collapseWhitespace(expectedMethod)),
        );
      },
    );

    test(
      'base64-encodes required nullable byte property before percent-encoding',
      () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'Filter',
          properties: [
            Property(
              name: 'signature',
              model: Base64Model(context: context),
              isRequired: true,
              isNullable: true,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: context,
          examples: const [],
        );

        final generatedClass = generator.generateClass(model);
        final classCode = format(generatedClass.accept(emitter).toString());

        const expectedMethod = r'''
Map<String, String> parameterProperties({
  bool allowEmpty = true,
  bool allowLists = true,
  bool useQueryComponent = false,
  bool allowReserved = false, Map<String, FormFieldEncoding> fieldEncodings = const {},
}) {
  final _$result = <String, String>{};
  if (signature != null) {
    _$result[r'signature'] = signature!.toBase64String().uriEncode(
      allowEmpty: allowEmpty,
      useQueryComponent: useQueryComponent,
      allowReserved: fieldEncodings[r'signature']?.allowReserved ?? allowReserved,
    );
  } else if (allowEmpty) {
    _$result[r'signature'] = '';
  }
  return _$result;
}
''';

        expect(
          collapseWhitespace(classCode),
          contains(collapseWhitespace(expectedMethod)),
        );
      },
    );

    test(
      'base64-encodes optional byte property before percent-encoding',
      () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'Filter',
          properties: [
            Property(
              name: 'signature',
              model: Base64Model(context: context),
              isRequired: false,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: context,
          examples: const [],
        );

        final generatedClass = generator.generateClass(model);
        final classCode = format(generatedClass.accept(emitter).toString());

        const expectedMethod = r'''
Map<String, String> parameterProperties({
  bool allowEmpty = true,
  bool allowLists = true,
  bool useQueryComponent = false,
  bool allowReserved = false, Map<String, FormFieldEncoding> fieldEncodings = const {},
}) {
  final _$result = <String, String>{};
  if (signature != null) {
    _$result[r'signature'] = signature!.toBase64String().uriEncode(
      allowEmpty: allowEmpty,
      useQueryComponent: useQueryComponent,
      allowReserved: fieldEncodings[r'signature']?.allowReserved ?? allowReserved,
    );
  } else if (allowEmpty) {
    _$result[r'signature'] = '';
  }
  return _$result;
}
''';

        expect(
          collapseWhitespace(classCode),
          contains(collapseWhitespace(expectedMethod)),
        );
      },
    );

    test(
      'emits the additionalProperties loop alongside a declared property whose '
      'reserved flag is keyed per property',
      () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'Bag',
          properties: [
            Property(
              name: 'declared',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: context,
          additionalProperties: TypedAdditionalProperties(
            valueModel: StringModel(context: context),
          ),
          examples: const [],
        );

        final generatedClass = generator.generateClass(model);
        final classCode = format(generatedClass.accept(emitter).toString());

        const expectedMethod = r'''
Map<String, String> parameterProperties({
  bool allowEmpty = true,
  bool allowLists = true,
  bool useQueryComponent = false,
  bool allowReserved = false,
  Map<String, FormFieldEncoding> fieldEncodings = const {},
}) {
  final _$result = <String, String>{};
  _$result[r'declared'] = declared.uriEncode(
    allowEmpty: allowEmpty,
    useQueryComponent: useQueryComponent,
    allowReserved: fieldEncodings[r'declared']?.allowReserved ?? allowReserved,
  );
  for (final _$e in additionalProperties.entries) {
    _$result[_$e.key] = _$e.value.uriEncode(
      allowEmpty: allowEmpty,
      useQueryComponent: useQueryComponent,
      allowReserved: allowReserved,
    );
  }
  return _$result;
}
''';

        expect(
          collapseWhitespace(classCode),
          contains(collapseWhitespace(expectedMethod)),
        );
      },
    );

    test(
      'base64-encodes byte additionalProperties values before '
      'percent-encoding',
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
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: context,
          additionalProperties: TypedAdditionalProperties(
            valueModel: Base64Model(context: context),
          ),
          examples: const [],
        );

        final generatedClass = generator.generateClass(model);
        final classCode = format(generatedClass.accept(emitter).toString());

        const expectedMethod = r'''
Map<String, String> parameterProperties({
  bool allowEmpty = true,
  bool allowLists = true,
  bool useQueryComponent = false,
  bool allowReserved = false, Map<String, FormFieldEncoding> fieldEncodings = const {},
}) {
  final _$result = <String, String>{};
  _$result[r'name'] = name.uriEncode(
    allowEmpty: allowEmpty,
    useQueryComponent: useQueryComponent,
    allowReserved: fieldEncodings[r'name']?.allowReserved ?? allowReserved,
  );
  for (final _$e in additionalProperties.entries) {
    _$result[_$e.key] = _$e.value.toBase64String().uriEncode(
      allowEmpty: allowEmpty,
      useQueryComponent: useQueryComponent,
      allowReserved: allowReserved,
    );
  }
  return _$result;
}
''';

        expect(
          collapseWhitespace(classCode),
          contains(collapseWhitespace(expectedMethod)),
        );
      },
    );

    test(
      'base64-encodes byte property in list-shaped parameterProperties',
      () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'Filter',
          properties: [
            Property(
              name: 'signature',
              model: Base64Model(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
            Property(
              name: 'tags',
              model: ListModel(
                content: StringModel(context: context),
                context: context,
                examples: const [],
              ),
              isRequired: false,
              isNullable: true,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: context,
          examples: const [],
        );

        final result = generator.generateClass(model);
        final method = result.methods.firstWhere(
          (m) => m.name == 'parameterProperties',
        );
        final methodCode = format(method.accept(emitter).toString());

        const expectedMethod = r'''
Map<String, String> parameterProperties({
  bool allowEmpty = true,
  bool allowLists = true,
  bool useQueryComponent = false,
  bool allowReserved = false, Map<String, FormFieldEncoding> fieldEncodings = const {},
}) {
  if (!allowLists && tags != null) {
    throw EncodingException('Lists are not supported in this encoding style');
  }
  final _$result = <String, String>{};
  _$result[r'signature'] = signature.toBase64String().uriEncode(
    allowEmpty: allowEmpty,
    useQueryComponent: useQueryComponent,
    allowReserved: fieldEncodings[r'signature']?.allowReserved ?? allowReserved,
  );
  if (tags != null) {
    _$result[r'tags'] = tags!.uriEncode(
      allowEmpty: allowEmpty,
      useQueryComponent: useQueryComponent,
      allowReserved: fieldEncodings[r'tags']?.allowReserved ?? allowReserved,
    );
  } else if (allowEmpty) {
    _$result[r'tags'] = '';
  }
  return _$result;
}
''';

        expect(
          collapseWhitespace(methodCode),
          collapseWhitespace(format(expectedMethod)),
        );
      },
    );

    test(
      'base64-encodes byte property in mixed-shape parameterProperties',
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
                    examples: const [],
                    defaultValue: null,
                  ),
                ],
                context: context,
                examples: const [],
              ),
            ),
          },
          context: context,
          examples: const [],
        );

        final model = ClassModel(
          isDeprecated: false,
          name: 'ByteMixedContainer',
          properties: [
            Property(
              name: 'signature',
              model: Base64Model(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
            Property(
              name: 'value',
              model: oneOfModel,
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: context,
          examples: const [],
        );

        final result = generator.generateClass(model);
        final method = result.methods.firstWhere(
          (m) => m.name == 'parameterProperties',
        );
        final methodCode = format(method.accept(emitter).toString());

        const expectedMethod = r'''
Map<String, String> parameterProperties({
  bool allowEmpty = true,
  bool allowLists = true,
  bool useQueryComponent = false,
  bool allowReserved = false, Map<String, FormFieldEncoding> fieldEncodings = const {},
}) {
  final _$result = <String, String>{};
  _$result[r'signature'] = signature.toBase64String().uriEncode(
    allowEmpty: allowEmpty,
    useQueryComponent: useQueryComponent,
    allowReserved: fieldEncodings[r'signature']?.allowReserved ?? allowReserved,
  );
  if (value.currentEncodingShape == EncodingShape.simple) {
    _$result[r'value'] = value.toSimple(explode: false, allowEmpty: allowEmpty);
  } else {
    throw EncodingException(
      r'parameterProperties not supported for ByteMixedContainer: contains complex types',
    );
  }
  return _$result;
}
''';

        expect(
          collapseWhitespace(methodCode),
          collapseWhitespace(format(expectedMethod)),
        );
      },
    );

    test(
      'base64-encodes nullable byte additionalProperties values before '
      'percent-encoding',
      () {
        final nullableByte = AliasModel(
          name: 'NullableSignature',
          model: Base64Model(context: context),
          context: context,
          isNullable: true,
          examples: const [],
          defaultValue: null,
        );

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
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: context,
          additionalProperties: TypedAdditionalProperties(
            valueModel: nullableByte,
          ),
          examples: const [],
        );

        final result = generator.generateClass(model);
        final method = result.methods.firstWhere(
          (m) => m.name == 'parameterProperties',
        );
        final methodCode = format(method.accept(emitter).toString());

        const expectedMethod = r'''
Map<String, String> parameterProperties({
  bool allowEmpty = true,
  bool allowLists = true,
  bool useQueryComponent = false,
  bool allowReserved = false, Map<String, FormFieldEncoding> fieldEncodings = const {},
}) {
  final _$result = <String, String>{};
  _$result[r'name'] = name.uriEncode(
    allowEmpty: allowEmpty,
    useQueryComponent: useQueryComponent,
    allowReserved: fieldEncodings[r'name']?.allowReserved ?? allowReserved,
  );
  for (final _$e in additionalProperties.entries) {
    _$result[_$e.key] =
        _$e.value?.toBase64String().uriEncode(
          allowEmpty: allowEmpty,
          useQueryComponent: useQueryComponent,
          allowReserved: allowReserved,
        ) ??
        '';
  }
  return _$result;
}
''';

        expect(
          collapseWhitespace(methodCode),
          collapseWhitespace(format(expectedMethod)),
        );
      },
    );
  });
}
