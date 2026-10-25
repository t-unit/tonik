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
    generator = ClassGenerator(nameManager: nameManager, package: 'example');
    context = Context.initial();
    emitter = DartEmitter(useNullSafetySyntax: true);
  });

  test('aliased list properties retain array parameter values', () {
    final list = ListModel(
      content: StringModel(context: context),
      context: context,
      examples: const [],
      name: 'Tags',
      nameOverride: null,
      isNullable: false,
      isContentNullable: false,
      isReadOnly: false,
      isWriteOnly: false,
    );
    final alias = AliasModel(
      model: list,
      context: context,
      examples: const [],
      defaultValue: null,
      name: 'TagsAlias',
      nameOverride: null,
      description: null,
      isDeprecated: false,
      isNullable: false,
      isReadOnly: false,
      isWriteOnly: false,
    );
    final model = ClassModel(
      name: 'Filter',
      isDeprecated: false,
      context: context,
      examples: const [],
      properties: [
        Property(
          name: 'tags',
          model: alias,
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
      nameOverride: null,
      description: null,
      additionalPropertiesPolicy: null,
      isNullable: false,
      isReadOnly: false,
      isWriteOnly: false,
    );

    final method = generator
        .generateClass(model)
        .methods
        .singleWhere((method) => method.name == 'parameterProperties');
    const expected = r'''
      @override
      Map<String, PropertyValue> parameterProperties({bool allowEmpty = true}) {
        final _$result = <String, PropertyValue>{};
        _$result[r'tags'] = PropertyValue.array(this.tags);
        return _$result;
      }
    ''';
    expect(
      collapseWhitespace(format(method.accept(emitter).toString())),
      collapseWhitespace(format(expected)),
    );
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

      final result = generator.generateClass(model);
      final parameterPropertiesMethod = result.methods.firstWhere(
        (m) => m.name == 'parameterProperties',
      );

      expect(
        parameterPropertiesMethod.annotations.single.accept(emitter).toString(),
        'override',
      );
      expect(parameterPropertiesMethod.type, isNot(MethodType.getter));
      expect(
        parameterPropertiesMethod.returns?.accept(emitter).toString(),
        'Map<String,PropertyValue>',
      );
      expect(parameterPropertiesMethod.optionalParameters.length, 1);

      final allowEmptyParam = parameterPropertiesMethod.optionalParameters
          .firstWhere((p) => p.name == 'allowEmpty');
      expect(allowEmptyParam.named, isTrue);
      expect(allowEmptyParam.required, isFalse);
      expect(allowEmptyParam.defaultTo?.accept(emitter).toString(), 'true');
      expect(allowEmptyParam.type?.accept(emitter).toString(), 'bool');
    });

    test('generates parameterProperties method body for simple properties', () {
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
            isReadOnly: false,
            isWriteOnly: false,
            nameOverride: null,
            description: null,
          ),
          Property(
            name: 'name',
            model: StringModel(context: context),
            isRequired: false,
            isNullable: true,
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

      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());

      const expectedMethod = r'''
@override
Map<String, PropertyValue> parameterProperties({bool allowEmpty = true}) {
  final _$result = <String, PropertyValue>{};
  _$result[r'id'] = PropertyValue.scalar(this.id.toString());
  if (this.name != null) {
    _$result[r'name'] = PropertyValue.scalar(this.name!);
  }
  return _$result;
}
''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(format(expectedMethod))),
      );
    });

    test('generates parameterProperties method body for empty model', () {
      final model = ClassModel(
        isDeprecated: false,
        name: 'Empty',
        properties: const [],
        context: context,
        examples: const [],
        nameOverride: null,
        description: null,
        additionalPropertiesPolicy: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
      );

      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());

      const expectedMethod = '''
@override
Map<String, PropertyValue> parameterProperties({bool allowEmpty = true}) { return <String, PropertyValue>{}; }
''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(format(expectedMethod))),
      );
    });

    test('omits null nullable properties from parameterProperties', () {
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
            isReadOnly: false,
            isWriteOnly: false,
            nameOverride: null,
            description: null,
          ),
          Property(
            name: 'nullable_count',
            model: IntegerModel(context: context),
            isRequired: true,
            isNullable: true,
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

      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());

      const expectedMethod = r'''
@override
Map<String, PropertyValue> parameterProperties({bool allowEmpty = true}) {
  final _$result = <String, PropertyValue>{};
  if (this.nullableName != null) {
    _$result[r'nullable_name'] = PropertyValue.scalar(this.nullableName!);
  }
  if (this.nullableCount != null) {
    _$result[r'nullable_count'] = PropertyValue.scalar(
      this.nullableCount!.toString(),
    );
  }
  return _$result;
}
''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(format(expectedMethod))),
      );
    });

    test('generates parameterProperties method that throws for '
        'complex properties', () {
      final nestedClass = ClassModel(
        isDeprecated: false,
        name: 'Address',
        properties: const [],
        context: context,
        examples: const [],
        nameOverride: null,
        description: null,
        additionalPropertiesPolicy: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
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

      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());

      const expectedMethod = '''
@override
Map<String, PropertyValue> parameterProperties({bool allowEmpty = true}) =>
  throw EncodingException(
    r'parameterProperties not supported for User: contains complex types',
  );
''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(format(expectedMethod))),
      );
    });
  });

  group('composite model runtime checking for parameterProperties', () {
    test('encodes oneOf property based on runtime encoding shape', () {
      final oneOfModel = OneOfModel(
        isDeprecated: false,
        name: 'StringOrClass',
        models: [
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

      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());

      const expectedMethod = r'''
@override
Map<String, PropertyValue> parameterProperties({bool allowEmpty = true}) {
  final _$result = <String, PropertyValue>{};
  if (this.value.currentEncodingShape == EncodingShape.simple) {
    _$result[r'value'] = PropertyValue.scalar(
      encodeAnyValueToString(this.value.toJson(), allowEmpty: allowEmpty),
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
        contains(collapseWhitespace(format(expectedMethod))),
      );
    });

    test('encodes anyOf property based on runtime encoding shape', () {
      final anyOfModel = AnyOfModel(
        isDeprecated: false,
        name: 'StringOrInt',
        models: [
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

      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());

      const expectedMethod = r'''
@override
Map<String, PropertyValue> parameterProperties({bool allowEmpty = true}) {
  final _$result = <String, PropertyValue>{};
  if (this.data.currentEncodingShape == EncodingShape.simple) {
    _$result[r'data'] = PropertyValue.scalar(
      encodeAnyValueToString(this.data.toJson(), allowEmpty: allowEmpty),
    );
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
        contains(collapseWhitespace(format(expectedMethod))),
      );
    });

    test('encodes allOf property based on runtime encoding shape', () {
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

      final allOfModel = AllOfModel(
        isDeprecated: false,
        name: 'StringAndInt',
        models: [stringModel, complexModel],
        context: context,
        examples: const [],
        nameOverride: null,
        description: null,
        additionalPropertiesPolicy: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
        defaultValue: null,
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

      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());

      const expectedMethod = r'''
@override
Map<String, PropertyValue> parameterProperties({bool allowEmpty = true}) {
  final _$result = <String, PropertyValue>{};
  if (this.combined.currentEncodingShape == EncodingShape.simple) {
    _$result[r'combined'] = PropertyValue.scalar(
      encodeAnyValueToString(this.combined.toJson(), allowEmpty: allowEmpty),
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
        contains(collapseWhitespace(format(expectedMethod))),
      );
    });

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
              isReadOnly: false,
              isWriteOnly: false,
              nameOverride: null,
              description: null,
            ),
            Property(
              name: 'count',
              model: IntegerModel(context: context),
              isRequired: false,
              isNullable: true,
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

        final generatedClass = generator.generateClass(model);
        final classCode = format(generatedClass.accept(emitter).toString());

        const expectedMethod = r'''
@override
Map<String, PropertyValue> parameterProperties({bool allowEmpty = true}) {
  final _$result = <String, PropertyValue>{};
  _$result[r'name'] = PropertyValue.scalar(this.name);
  if (this.count != null) {
    _$result[r'count'] = PropertyValue.scalar(this.count!.toString());
  }
  return _$result;
}
''';

        expect(
          collapseWhitespace(classCode),
          contains(collapseWhitespace(format(expectedMethod))),
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

      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());

      const expectedMethod = '''
@override
Map<String, PropertyValue> parameterProperties({bool allowEmpty = true}) =>
    throw EncodingException(
      r'parameterProperties not supported for ComplexContainer: contains complex types',
    );
''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(format(expectedMethod))),
      );
    });

    test('encodes optional oneOf property based on runtime encoding shape', () {
      final oneOfModel = OneOfModel(
        isDeprecated: false,
        name: 'StringOrClass',
        models: [
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

      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());

      const expectedMethod = r'''
@override
Map<String, PropertyValue> parameterProperties({bool allowEmpty = true}) {
  final _$result = <String, PropertyValue>{};
  if (this.value != null) {
    if (this.value!.currentEncodingShape == EncodingShape.simple) {
      _$result[r'value'] = PropertyValue.scalar(
        encodeAnyValueToString(this.value!.toJson(), allowEmpty: allowEmpty),
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
        contains(collapseWhitespace(format(expectedMethod))),
      );
    });

    test(
      'handles class with multiple properties (mixed optimized/runtime checks)',
      () {
        final oneOfModel1 = OneOfModel(
          isDeprecated: false,
          name: 'StringOrInt1',
          models: [
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

        final oneOfModel2 = OneOfModel(
          isDeprecated: false,
          name: 'StringOrInt2',
          models: [
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

        final anyOfModel = AnyOfModel(
          isDeprecated: false,
          name: 'FlexibleData',
          models: [
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
              isReadOnly: false,
              isWriteOnly: false,
              nameOverride: null,
              description: null,
            ),
            Property(
              name: 'count',
              model: IntegerModel(context: context),
              isRequired: false,
              isNullable: true,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
              isReadOnly: false,
              isWriteOnly: false,
              nameOverride: null,
              description: null,
            ),
            Property(
              name: 'active',
              model: BooleanModel(context: context),
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
            // Composite properties (runtime checks)
            Property(
              name: 'data1',
              model: oneOfModel1,
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
            Property(
              name: 'data2',
              model: oneOfModel2,
              isRequired: false,
              isNullable: true,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
              isReadOnly: false,
              isWriteOnly: false,
              nameOverride: null,
              description: null,
            ),
            Property(
              name: 'flexible',
              model: anyOfModel,
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

        final generatedClass = generator.generateClass(model);
        final classCode = format(generatedClass.accept(emitter).toString());

        const expectedMethod = r'''
@override
Map<String, PropertyValue> parameterProperties({bool allowEmpty = true}) {
  final _$result = <String, PropertyValue>{};
  _$result[r'name'] = PropertyValue.scalar(this.name);
  if (this.count != null) {
    _$result[r'count'] = PropertyValue.scalar(this.count!.toString());
  }
  _$result[r'active'] = PropertyValue.scalar(this.active.toString());
  if (this.data1.currentEncodingShape == EncodingShape.simple) {
    _$result[r'data1'] = PropertyValue.scalar(
      encodeAnyValueToString(this.data1.toJson(), allowEmpty: allowEmpty),
    );
  } else {
    throw EncodingException(
      r'parameterProperties not supported for MixedContainer: contains complex types',
    );
  }
  if (this.data2 != null) {
    if (this.data2!.currentEncodingShape == EncodingShape.simple) {
      _$result[r'data2'] = PropertyValue.scalar(
        encodeAnyValueToString(this.data2!.toJson(), allowEmpty: allowEmpty),
      );
    } else {
      throw EncodingException(
        r'parameterProperties not supported for MixedContainer: contains complex types',
      );
    }
  }
  if (this.flexible.currentEncodingShape == EncodingShape.simple) {
    _$result[r'flexible'] = PropertyValue.scalar(
      encodeAnyValueToString(this.flexible.toJson(), allowEmpty: allowEmpty),
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
          contains(collapseWhitespace(format(expectedMethod))),
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
                name: null,
                nameOverride: null,
                isNullable: false,
                isContentNullable: false,
                isReadOnly: false,
                isWriteOnly: false,
              ),
              isRequired: false,
              isNullable: true,
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

        final result = generator.generateClass(model);
        final classCode = format(result.accept(emitter).toString());

        final parameterPropertiesMethod = result.methods.firstWhere(
          (m) => m.name == 'parameterProperties',
        );

        expect(parameterPropertiesMethod, isNotNull);

        const expectedMethod = r'''
@override
Map<String, PropertyValue> parameterProperties({bool allowEmpty = true}) {
  final _$result = <String, PropertyValue>{};
  if (this.tags != null) {
    _$result[r'tags'] = PropertyValue.array(this.tags!);
  }
  return _$result;
}
''';

        expect(
          collapseWhitespace(classCode),
          contains(collapseWhitespace(format(expectedMethod))),
        );
      },
    );

    test('generates parameterProperties for class with multiple lists of '
        'simple types', () {
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
              name: null,
              nameOverride: null,
              isNullable: false,
              isContentNullable: false,
              isReadOnly: false,
              isWriteOnly: false,
            ),
            isRequired: false,
            isNullable: true,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
            isReadOnly: false,
            isWriteOnly: false,
            nameOverride: null,
            description: null,
          ),
          Property(
            name: 'tags',
            model: ListModel(
              content: StringModel(context: context),
              context: context,
              examples: const [],
              name: null,
              nameOverride: null,
              isNullable: false,
              isContentNullable: false,
              isReadOnly: false,
              isWriteOnly: false,
            ),
            isRequired: false,
            isNullable: true,
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

      final result = generator.generateClass(model);
      final classCode = format(result.accept(emitter).toString());

      final parameterPropertiesMethod = result.methods.firstWhere(
        (m) => m.name == 'parameterProperties',
      );

      expect(parameterPropertiesMethod, isNotNull);

      const expectedMethod = r'''
@override
Map<String, PropertyValue> parameterProperties({bool allowEmpty = true}) {
  final _$result = <String, PropertyValue>{};
  if (this.ids != null) {
    _$result[r'ids'] = PropertyValue.array(
      this.ids!.map((e) => e.toString()).toList(),
    );
  }
  if (this.tags != null) {
    _$result[r'tags'] = PropertyValue.array(this.tags!);
  }
  return _$result;
}
''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(format(expectedMethod))),
      );
    });

    test('generates parameterProperties for class with required list of '
        'simple types', () {
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
              name: null,
              nameOverride: null,
              isNullable: false,
              isContentNullable: false,
              isReadOnly: false,
              isWriteOnly: false,
            ),
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

      final result = generator.generateClass(model);
      final classCode = format(result.accept(emitter).toString());

      final parameterPropertiesMethod = result.methods.firstWhere(
        (m) => m.name == 'parameterProperties',
      );

      expect(parameterPropertiesMethod, isNotNull);

      const expectedMethod = r'''
@override
Map<String, PropertyValue> parameterProperties({bool allowEmpty = true}) {
  final _$result = <String, PropertyValue>{};
  _$result[r'tags'] = PropertyValue.array(this.tags);
  return _$result;
}
''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(format(expectedMethod))),
      );
    });

    test('generates parameterProperties for class with mixed simple properties '
        'and lists', () {
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
            isReadOnly: false,
            isWriteOnly: false,
            nameOverride: null,
            description: null,
          ),
          Property(
            name: 'tags',
            model: ListModel(
              content: StringModel(context: context),
              context: context,
              examples: const [],
              name: null,
              nameOverride: null,
              isNullable: false,
              isContentNullable: false,
              isReadOnly: false,
              isWriteOnly: false,
            ),
            isRequired: false,
            isNullable: true,
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

      final result = generator.generateClass(model);
      final classCode = format(result.accept(emitter).toString());

      final parameterPropertiesMethod = result.methods.firstWhere(
        (m) => m.name == 'parameterProperties',
      );

      expect(parameterPropertiesMethod, isNotNull);

      const expectedMethod = r'''
@override
Map<String, PropertyValue> parameterProperties({bool allowEmpty = true}) {
  final _$result = <String, PropertyValue>{};
  _$result[r'id'] = PropertyValue.scalar(this.id.toString());
  if (this.tags != null) {
    _$result[r'tags'] = PropertyValue.array(this.tags!);
  }
  return _$result;
}
''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(format(expectedMethod))),
      );
    });

    test('throws exception for class with list of complex types', () {
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
              name: null,
              nameOverride: null,
              isNullable: false,
              isContentNullable: false,
              isReadOnly: false,
              isWriteOnly: false,
            ),
            isRequired: false,
            isNullable: true,
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

      final result = generator.generateClass(model);
      final classCode = format(result.accept(emitter).toString());

      final parameterPropertiesMethod = result.methods.firstWhere(
        (m) => m.name == 'parameterProperties',
      );

      expect(parameterPropertiesMethod, isNotNull);

      const expectedMethod = '''
@override
Map<String, PropertyValue> parameterProperties({bool allowEmpty = true}) =>
    throw EncodingException(
      r'parameterProperties not supported for ComplexListContainer: contains complex types',
    );
''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(format(expectedMethod))),
      );
    });

    test('generates parameterProperties for class with list of enums', () {
      final enumModel = EnumModel<String>(
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
              name: null,
              nameOverride: null,
              isNullable: false,
              isContentNullable: false,
              isReadOnly: false,
              isWriteOnly: false,
            ),
            isRequired: false,
            isNullable: true,
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

      final result = generator.generateClass(model);
      final classCode = format(result.accept(emitter).toString());

      final parameterPropertiesMethod = result.methods.firstWhere(
        (m) => m.name == 'parameterProperties',
      );

      expect(parameterPropertiesMethod, isNotNull);

      const expectedMethod = r'''
@override
Map<String, PropertyValue> parameterProperties({bool allowEmpty = true}) {
  final _$result = <String, PropertyValue>{};
  if (this.statuses != null) {
    _$result[r'statuses'] = PropertyValue.array(
      this.statuses!.map((e) => e.toJson()).toList(),
    );
  }
  return _$result;
}
''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(format(expectedMethod))),
      );
    });

    test('generates parameterProperties for a list of composite content as raw '
        'elements', () {
      final oneOfModel = OneOfModel(
        isDeprecated: false,
        name: 'StringOrInt',
        models: [
          (discriminatorValue: null, model: StringModel(context: context)),
          (discriminatorValue: null, model: IntegerModel(context: context)),
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

      final model = ClassModel(
        isDeprecated: false,
        name: 'CompositeListContainer',
        properties: [
          Property(
            name: 'items',
            model: ListModel(
              content: oneOfModel,
              context: context,
              examples: const [],
              name: null,
              nameOverride: null,
              isNullable: false,
              isContentNullable: false,
              isReadOnly: false,
              isWriteOnly: false,
            ),
            isRequired: false,
            isNullable: true,
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

      final result = generator.generateClass(model);
      final classCode = format(result.accept(emitter).toString());

      const expectedMethod = r'''
@override
Map<String, PropertyValue> parameterProperties({bool allowEmpty = true}) {
  final _$result = <String, PropertyValue>{};
  if (this.items != null) {
    _$result[r'items'] = PropertyValue.array(
      this.items!
          .map(
            (e) => encodeAnyValueToString(e.toJson(), allowEmpty: allowEmpty),
          )
          .toList(),
    );
  }
  return _$result;
}
''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(format(expectedMethod))),
      );
    });

    test(
      'generates parameterProperties with an array value for a required list '
      'property',
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
                name: null,
                nameOverride: null,
                isNullable: false,
                isContentNullable: false,
                isReadOnly: false,
                isWriteOnly: false,
              ),
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

        final generatedClass = generator.generateClass(model);
        final classCode = format(generatedClass.accept(emitter).toString());

        const expectedMethod = r'''
@override
Map<String, PropertyValue> parameterProperties({bool allowEmpty = true}) {
  final _$result = <String, PropertyValue>{};
  _$result[r'tags'] = PropertyValue.array(this.tags);
  return _$result;
}
''';

        expect(
          collapseWhitespace(classCode),
          contains(collapseWhitespace(format(expectedMethod))),
        );
      },
    );

    test(
      'generates parameterProperties with an array value for a nullable list '
      'property',
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
                name: null,
                nameOverride: null,
                isNullable: false,
                isContentNullable: false,
                isReadOnly: false,
                isWriteOnly: false,
              ),
              isRequired: false,
              isNullable: true,
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

        final generatedClass = generator.generateClass(model);
        final classCode = format(generatedClass.accept(emitter).toString());

        const expectedMethod = r'''
@override
Map<String, PropertyValue> parameterProperties({bool allowEmpty = true}) {
  final _$result = <String, PropertyValue>{};
  if (this.tags != null) {
    _$result[r'tags'] = PropertyValue.array(this.tags!);
  }
  return _$result;
}
''';

        expect(
          collapseWhitespace(classCode),
          contains(collapseWhitespace(format(expectedMethod))),
        );
      },
    );

    test('generates parameterProperties with scalar and array values for mixed '
        'properties', () {
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
            isReadOnly: false,
            isWriteOnly: false,
            nameOverride: null,
            description: null,
          ),
          Property(
            name: 'tags',
            model: ListModel(
              content: StringModel(context: context),
              context: context,
              examples: const [],
              name: null,
              nameOverride: null,
              isNullable: false,
              isContentNullable: false,
              isReadOnly: false,
              isWriteOnly: false,
            ),
            isRequired: false,
            isNullable: true,
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

      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());

      const expectedMethod = r'''
@override
Map<String, PropertyValue> parameterProperties({bool allowEmpty = true}) {
  final _$result = <String, PropertyValue>{};
  _$result[r'name'] = PropertyValue.scalar(this.name);
  if (this.tags != null) {
    _$result[r'tags'] = PropertyValue.array(this.tags!);
  }
  return _$result;
}
''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(format(expectedMethod))),
      );
    });

    test('generates parameterProperties with scalar values for scalar-only '
        'properties', () {
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
            isReadOnly: false,
            isWriteOnly: false,
            nameOverride: null,
            description: null,
          ),
          Property(
            name: 'age',
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

      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());

      const expectedMethod = r'''
@override
Map<String, PropertyValue> parameterProperties({bool allowEmpty = true}) {
  final _$result = <String, PropertyValue>{};
  _$result[r'name'] = PropertyValue.scalar(this.name);
  _$result[r'age'] = PropertyValue.scalar(this.age.toString());
  return _$result;
}
''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(format(expectedMethod))),
      );
    });

    test('emits the raw scalar form for every simple property type', () {
      final model = ClassModel(
        isDeprecated: false,
        name: 'AllScalarTypes',
        properties: [
          Property(
            name: 'ratio',
            model: DoubleModel(context: context),
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
          Property(
            name: 'quantity',
            model: NumberModel(context: context),
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
          Property(
            name: 'createdAt',
            model: DateTimeModel(context: context),
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
          Property(
            name: 'birthday',
            model: DateModel(context: context),
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
          Property(
            name: 'price',
            model: DecimalModel(context: context),
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
          Property(
            name: 'link',
            model: UriModel(context: context),
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
          Property(
            name: 'status',
            model: EnumModel<String>(
              isDeprecated: false,
              name: 'Status',
              values: {const EnumEntry(value: 'active', nameOverride: null)},
              isNullable: false,
              context: context,
              examples: const [],
              nameOverride: null,
              description: null,
              defaultValue: null,
              fallbackValue: null,
              isReadOnly: false,
              isWriteOnly: false,
            ),
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
          Property(
            name: 'level',
            model: EnumModel<int>(
              isDeprecated: false,
              name: 'Level',
              values: {const EnumEntry(value: 1, nameOverride: null)},
              isNullable: false,
              context: context,
              examples: const [],
              nameOverride: null,
              description: null,
              defaultValue: null,
              fallbackValue: null,
              isReadOnly: false,
              isWriteOnly: false,
            ),
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
          Property(
            name: 'blob',
            model: BinaryModel(context: context),
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

      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());

      const expectedMethod = r'''
@override
Map<String, PropertyValue> parameterProperties({bool allowEmpty = true}) {
  final _$result = <String, PropertyValue>{};
  _$result[r'ratio'] = PropertyValue.scalar(this.ratio.toString());
  _$result[r'quantity'] = PropertyValue.scalar(this.quantity.toString());
  _$result[r'createdAt'] = PropertyValue.scalar(
    this.createdAt.toTimeZonedIso8601String(),
  );
  _$result[r'birthday'] = PropertyValue.scalar(this.birthday.toString());
  _$result[r'price'] = PropertyValue.scalar(this.price.toPlainString());
  _$result[r'link'] = PropertyValue.scalar(this.link.toString());
  _$result[r'status'] = PropertyValue.scalar(this.status.toJson());
  _$result[r'level'] = PropertyValue.scalar(this.level.toJson().toString());
  _$result[r'blob'] = PropertyValue.scalar(this.blob.toBytes().decodeToString());
  return _$result;
}
''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(format(expectedMethod))),
      );
    });

    test('mixed model AnyModel property encodes through the unknown flat '
        'scalar boundary', () {
      final model = ClassModel(
        isDeprecated: false,
        name: 'DynamicContainer',
        properties: [
          Property(
            name: 'data',
            model: AnyModel(context: context),
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

      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());

      const expectedMethod = r'''
@override
Map<String, PropertyValue> parameterProperties({bool allowEmpty = true}) {
  final _$result = <String, PropertyValue>{};
  if (this.data != null) {
    _$result[r'data'] = PropertyValue.scalar(
      encodeUnknownFlatScalar(this.data!, context: r'DynamicContainer.data'),
    );
  }
  return _$result;
}
''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(format(expectedMethod))),
      );
    });

    test('AnyModel encoding context preserves dollar-prefixed class names', () {
      final model = ClassModel(
        isDeprecated: false,
        name: r'$20100401Payments',
        properties: [
          Property(
            name: 'Parameter',
            model: AnyModel(context: context),
            isRequired: false,
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

      final method = generator
          .generateClass(model)
          .methods
          .singleWhere((method) => method.name == 'parameterProperties');
      const expected = r'''
@override
Map<String, PropertyValue> parameterProperties({bool allowEmpty = true}) {
  final _$result = <String, PropertyValue>{};
  if (this.parameter != null) {
    _$result[r'Parameter'] = PropertyValue.scalar(
      encodeUnknownFlatScalar(
        this.parameter!,
        context: r'$20100401Payments.Parameter',
      ),
    );
  }
  return _$result;
}
''';
      expect(
        collapseWhitespace(format(method.accept(emitter).toString())),
        collapseWhitespace(format(expected)),
      );
    });

    test('omits an optional forbidden property from a simple query object', () {
      final model = ClassModel(
        name: 'ProfileFilter',
        isDeprecated: false,
        context: context,
        examples: const [],
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
          Property(
            name: 'password',
            model: NeverModel(context: context, isNullable: false),
            isRequired: false,
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
        nameOverride: null,
        description: null,
        additionalPropertiesPolicy: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
      );

      final method = generator
          .generateClass(model)
          .methods
          .singleWhere((method) => method.name == 'parameterProperties');
      const expected = r'''
@override
Map<String, PropertyValue> parameterProperties({bool allowEmpty = true}) {
  final _$result = <String, PropertyValue>{};
  _$result[r'name'] = PropertyValue.scalar(this.name);
  return _$result;
}
''';
      expect(
        collapseWhitespace(format(method.accept(emitter).toString())),
        collapseWhitespace(format(expected)),
      );
    });

    test('omits an optional forbidden alias beside a string list', () {
      final model = ClassModel(
        name: 'ProfileListFilter',
        isDeprecated: false,
        context: context,
        examples: const [],
        properties: [
          Property(
            name: 'tags',
            model: ListModel(
              content: StringModel(context: context),
              context: context,
              examples: const [],
              name: null,
              nameOverride: null,
              isNullable: false,
              isContentNullable: false,
              isReadOnly: false,
              isWriteOnly: false,
            ),
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
          Property(
            name: 'password',
            model: AliasModel(
              name: 'Forbidden',
              model: NeverModel(context: context, isNullable: false),
              context: context,
              examples: const [],
              defaultValue: null,
              nameOverride: null,
              description: null,
              isDeprecated: false,
              isNullable: false,
              isReadOnly: false,
              isWriteOnly: false,
            ),
            isRequired: false,
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
        nameOverride: null,
        description: null,
        additionalPropertiesPolicy: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
      );

      final method = generator
          .generateClass(model)
          .methods
          .singleWhere((method) => method.name == 'parameterProperties');
      const expected = r'''
@override
Map<String, PropertyValue> parameterProperties({bool allowEmpty = true}) {
  final _$result = <String, PropertyValue>{};
  _$result[r'tags'] = PropertyValue.array(this.tags);
  return _$result;
}
''';
      expect(
        collapseWhitespace(format(method.accept(emitter).toString())),
        collapseWhitespace(format(expected)),
      );
    });

    test('omits an optional forbidden property beside an Any scalar', () {
      final model = ClassModel(
        name: 'ProfileMixedFilter',
        isDeprecated: false,
        context: context,
        examples: const [],
        properties: [
          Property(
            name: 'data',
            model: AnyModel(context: context),
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
          Property(
            name: 'password',
            model: NeverModel(context: context, isNullable: false),
            isRequired: false,
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
        nameOverride: null,
        description: null,
        additionalPropertiesPolicy: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
      );

      final method = generator
          .generateClass(model)
          .methods
          .singleWhere((method) => method.name == 'parameterProperties');
      const expected = r'''
@override
Map<String, PropertyValue> parameterProperties({bool allowEmpty = true}) {
  final _$result = <String, PropertyValue>{};
  if (this.data != null) {
    _$result[r'data'] = PropertyValue.scalar(
      encodeUnknownFlatScalar(this.data!, context: r'ProfileMixedFilter.data'),
    );
  }
  return _$result;
}
''';
      expect(
        collapseWhitespace(format(method.accept(emitter).toString())),
        collapseWhitespace(format(expected)),
      );
    });

    test('rejects a required write-only forbidden property beside a list', () {
      final model = ClassModel(
        name: 'RequiredForbiddenFilter',
        isDeprecated: false,
        context: context,
        examples: const [],
        properties: [
          Property(
            name: 'tags',
            model: ListModel(
              content: StringModel(context: context),
              context: context,
              examples: const [],
              name: null,
              nameOverride: null,
              isNullable: false,
              isContentNullable: false,
              isReadOnly: false,
              isWriteOnly: false,
            ),
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
          Property(
            name: 'password',
            model: NeverModel(context: context, isNullable: false),
            isRequired: true,
            isNullable: false,
            isWriteOnly: true,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
            isReadOnly: false,
            nameOverride: null,
            description: null,
          ),
        ],
        nameOverride: null,
        description: null,
        additionalPropertiesPolicy: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
      );

      final method = generator
          .generateClass(model)
          .methods
          .singleWhere((method) => method.name == 'parameterProperties');
      const expected = r'''
@override
Map<String, PropertyValue> parameterProperties({bool allowEmpty = true}) {
  final _$result = <String, PropertyValue>{};
  _$result[r'tags'] = PropertyValue.array(this.tags);
  throw EncodingException(
    r'Cannot encode NeverModel property password: this type does not permit any value',
  );
  return _$result;
}
''';
      expect(
        collapseWhitespace(format(method.accept(emitter).toString())),
        collapseWhitespace(format(expected)),
      );
    });

    test(
      'mixed model NeverModel property throws that no value is permitted',
      () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'ForbiddenContainer',
          properties: [
            Property(
              name: 'data',
              model: AnyModel(context: context),
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
            Property(
              name: 'forbidden',
              model: NeverModel(context: context, isNullable: false),
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

        final generatedClass = generator.generateClass(model);
        final classCode = format(
          generatedClass.methods
              .firstWhere((m) => m.name == 'parameterProperties')
              .accept(emitter)
              .toString(),
        );

        const expectedMethod = r'''
@override
Map<String, PropertyValue> parameterProperties({bool allowEmpty = true}) {
  final _$result = <String, PropertyValue>{};
  if (this.data != null) {
    _$result[r'data'] = PropertyValue.scalar(
      encodeUnknownFlatScalar(this.data!, context: r'ForbiddenContainer.data'),
    );
  }
  throw EncodingException(
    r'Cannot encode NeverModel property forbidden: this type does not permit any value',
  );
  return _$result;
}
''';

        expect(
          collapseWhitespace(classCode),
          contains(collapseWhitespace(format(expectedMethod))),
        );
      },
    );

    test(
      'simple model NeverModel property throws that no value is permitted',
      () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'ForbiddenSimpleContainer',
          properties: [
            Property(
              name: 'label',
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
            Property(
              name: 'forbidden',
              model: NeverModel(context: context, isNullable: false),
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

        final generatedClass = generator.generateClass(model);
        final classCode = format(generatedClass.accept(emitter).toString());

        const expectedMethod = r'''
@override
Map<String, PropertyValue> parameterProperties({bool allowEmpty = true}) {
  final _$result = <String, PropertyValue>{};
  _$result[r'label'] = PropertyValue.scalar(this.label);
  throw EncodingException(
    r'Cannot encode NeverModel property forbidden: this type does not permit any value',
  );
  return _$result;
}
''';

        expect(
          collapseWhitespace(classCode),
          contains(collapseWhitespace(format(expectedMethod))),
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
          nameOverride: null,
          description: null,
          isDeprecated: false,
          isReadOnly: false,
          isWriteOnly: false,
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

        final generatedClass = generator.generateClass(model);
        final classCode = format(generatedClass.accept(emitter).toString());

        // Should generate null-aware encoding because the model is nullable
        const expectedMethod = r'''
@override
Map<String, PropertyValue> parameterProperties({bool allowEmpty = true}) {
  final _$result = <String, PropertyValue>{};
  if (this.description != null) {
    _$result[r'description'] = PropertyValue.scalar(this.description!);
  }
  return _$result;
}
''';

        expect(
          collapseWhitespace(classCode),
          contains(collapseWhitespace(format(expectedMethod))),
        );
      },
    );

    test('generates parameterProperties with null check for required property '
        'referencing nullable AliasModel in mixed-shape model', () {
      // Same scenario in mixed-shape context
      final nullableAlias = AliasModel(
        name: 'NullableDescription',
        model: StringModel(context: context),
        isNullable: true,
        context: context,
        examples: const [],
        defaultValue: null,
        nameOverride: null,
        description: null,
        isDeprecated: false,
        isReadOnly: false,
        isWriteOnly: false,
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
            isReadOnly: false,
            isWriteOnly: false,
            nameOverride: null,
            description: null,
          ),
          Property(
            name: 'tags',
            model: ListModel(
              content: StringModel(context: context),
              context: context,
              examples: const [],
              name: null,
              nameOverride: null,
              isNullable: false,
              isContentNullable: false,
              isReadOnly: false,
              isWriteOnly: false,
            ),
            isRequired: false,
            isNullable: true,
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

      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());

      // The simple property with nullable model should have null check
      expect(
        collapseWhitespace(classCode),
        contains(
          collapseWhitespace(r'''
if (this.description != null) {
  _$result[r'description'] = PropertyValue.scalar(this.description!);
}'''),
        ),
      );
    });

    test(
      'generates null-aware array value for a nullable ListModel property',
      () {
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
                name: null,
                nameOverride: null,
                isContentNullable: false,
                isReadOnly: false,
                isWriteOnly: false,
              ),
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

        final generatedClass = generator.generateClass(model);
        final classCode = format(generatedClass.accept(emitter).toString());

        const expectedMethod = r'''
@override
Map<String, PropertyValue> parameterProperties({bool allowEmpty = true}) {
  final _$result = <String, PropertyValue>{};
  if (this.items != null) {
    _$result[r'items'] = PropertyValue.array(this.items!);
  }
  return _$result;
}
''';

        expect(
          collapseWhitespace(classCode),
          contains(collapseWhitespace(format(expectedMethod))),
        );
      },
    );

    test('toForm inherits encoding through parameterProperties', () {
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
            isReadOnly: false,
            isWriteOnly: false,
            nameOverride: null,
            description: null,
          ),
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
      );

      final generatedClass = generator.generateClass(model);
      expect(generatedClass.extend?.symbol, 'ObjectParameterEncodable');
    });

    test('generates null-safe toJson and fromJson for required property '
        'referencing AliasModel that wraps nullable ClassModel', () {
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
            isReadOnly: false,
            isWriteOnly: false,
            nameOverride: null,
            description: null,
          ),
        ],
        context: context,
        isNullable: true,
        examples: const [],
        nameOverride: null,
        description: null,
        additionalPropertiesPolicy: null,
        isReadOnly: false,
        isWriteOnly: false,
      );

      final outerAlias = AliasModel(
        name: 'Outer',
        model: innerClass,
        context: context,
        examples: const [],
        defaultValue: null,
        nameOverride: null,
        description: null,
        isDeprecated: false,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
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

      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());

      // toJson should use null-safe access because the underlying model
      // is nullable via typedef chain
      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace("r'inner': this.inner?.toJson()")),
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
    });

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
          nameOverride: null,
          description: null,
          isDeprecated: false,
          isReadOnly: false,
          isWriteOnly: false,
        );

        final outerAlias = AliasModel(
          name: 'OuterAlias',
          model: innerAlias,
          context: context,
          examples: const [],
          defaultValue: null,
          nameOverride: null,
          description: null,
          isDeprecated: false,
          isNullable: false,
          isReadOnly: false,
          isWriteOnly: false,
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

        final generatedClass = generator.generateClass(model);
        final classCode = format(generatedClass.accept(emitter).toString());

        // Should generate null-aware encoding because the nested alias
        // is nullable
        const expectedMethod = r'''
@override
Map<String, PropertyValue> parameterProperties({bool allowEmpty = true}) {
  final _$result = <String, PropertyValue>{};
  if (this.label != null) {
    _$result[r'label'] = PropertyValue.scalar(this.label!);
  }
  return _$result;
}
''';

        expect(
          collapseWhitespace(classCode),
          contains(collapseWhitespace(format(expectedMethod))),
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

        final generatedClass = generator.generateClass(model);
        final classCode = format(generatedClass.accept(emitter).toString());

        const expectedMethod = r'''
@override
Map<String, PropertyValue> parameterProperties({bool allowEmpty = true}) {
  final _$result = <String, PropertyValue>{};
  _$result[r'signature'] = PropertyValue.scalar(this.signature.toBase64String());
  return _$result;
}
''';

        expect(
          collapseWhitespace(classCode),
          contains(collapseWhitespace(format(expectedMethod))),
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

        final generatedClass = generator.generateClass(model);
        final classCode = format(generatedClass.accept(emitter).toString());

        const expectedMethod = r'''
@override
Map<String, PropertyValue> parameterProperties({bool allowEmpty = true}) {
  final _$result = <String, PropertyValue>{};
  if (this.signature != null) {
    _$result[r'signature'] = PropertyValue.scalar(
      this.signature!.toBase64String(),
    );
  }
  return _$result;
}
''';

        expect(
          collapseWhitespace(classCode),
          contains(collapseWhitespace(format(expectedMethod))),
        );
      },
    );

    test('base64-encodes optional byte property before percent-encoding', () {
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

      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());

      const expectedMethod = r'''
@override
Map<String, PropertyValue> parameterProperties({bool allowEmpty = true}) {
  final _$result = <String, PropertyValue>{};
  if (this.signature != null) {
    _$result[r'signature'] = PropertyValue.scalar(
      this.signature!.toBase64String(),
    );
  }
  return _$result;
}
''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(format(expectedMethod))),
      );
    });

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
              isReadOnly: false,
              isWriteOnly: false,
              nameOverride: null,
              description: null,
            ),
          ],
          context: context,
          additionalPropertiesPolicy: AllowedAdditionalProperties(
            valueModel: StringModel(context: context),
            origin: AdditionalPropertiesOrigin.explicit,
          ),
          examples: const [],
          nameOverride: null,
          description: null,
          isNullable: false,
          isReadOnly: false,
          isWriteOnly: false,
        );

        final generatedClass = generator.generateClass(model);
        final classCode = format(generatedClass.accept(emitter).toString());

        const expectedMethod = r'''
@override
Map<String, PropertyValue> parameterProperties({bool allowEmpty = true}) {
  final _$result = <String, PropertyValue>{};
  _$result[r'declared'] = PropertyValue.scalar(this.declared);
  const _$knownKeys = {r'declared'};
  for (final _$e in this.additionalProperties.entries) {
    if (_$knownKeys.contains(_$e.key)) {
      throw EncodingException(
        r'Additional property keys must not collide with declared wire keys of Bag',
      );
    }
    _$result[_$e.key] = PropertyValue.scalar(_$e.value);
  }
  return _$result;
}
''';

        expect(
          collapseWhitespace(classCode),
          contains(collapseWhitespace(format(expectedMethod))),
        );
      },
    );

    test('base64-encodes byte additionalProperties values before '
        'percent-encoding', () {
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
            isReadOnly: false,
            isWriteOnly: false,
            nameOverride: null,
            description: null,
          ),
        ],
        context: context,
        additionalPropertiesPolicy: AllowedAdditionalProperties(
          valueModel: Base64Model(context: context),
          origin: AdditionalPropertiesOrigin.explicit,
        ),
        examples: const [],
        nameOverride: null,
        description: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
      );

      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());

      const expectedMethod = r'''
@override
Map<String, PropertyValue> parameterProperties({bool allowEmpty = true}) {
  final _$result = <String, PropertyValue>{};
  _$result[r'name'] = PropertyValue.scalar(this.name);
  const _$knownKeys = {r'name'};
  for (final _$e in this.additionalProperties.entries) {
    if (_$knownKeys.contains(_$e.key)) {
      throw EncodingException(
        r'Additional property keys must not collide with declared wire keys of Filter',
      );
    }
    _$result[_$e.key] = PropertyValue.scalar(_$e.value.toBase64String());
  }
  return _$result;
}
''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(format(expectedMethod))),
      );
    });

    test('base64-encodes byte property in list-shaped parameterProperties', () {
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
            isReadOnly: false,
            isWriteOnly: false,
            nameOverride: null,
            description: null,
          ),
          Property(
            name: 'tags',
            model: ListModel(
              content: StringModel(context: context),
              context: context,
              examples: const [],
              name: null,
              nameOverride: null,
              isNullable: false,
              isContentNullable: false,
              isReadOnly: false,
              isWriteOnly: false,
            ),
            isRequired: false,
            isNullable: true,
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

      final result = generator.generateClass(model);
      final method = result.methods.firstWhere(
        (m) => m.name == 'parameterProperties',
      );
      final methodCode = format(method.accept(emitter).toString());

      const expectedMethod = r'''
@override
Map<String, PropertyValue> parameterProperties({bool allowEmpty = true}) {
  final _$result = <String, PropertyValue>{};
  _$result[r'signature'] = PropertyValue.scalar(this.signature.toBase64String());
  if (this.tags != null) {
    _$result[r'tags'] = PropertyValue.array(this.tags!);
  }
  return _$result;
}
''';

      expect(
        collapseWhitespace(methodCode),
        collapseWhitespace(format(expectedMethod)),
      );
    });

    test('base64-encodes byte property in mixed-shape parameterProperties', () {
      final oneOfModel = OneOfModel(
        isDeprecated: false,
        name: 'StringOrClass',
        models: [
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
            isReadOnly: false,
            isWriteOnly: false,
            nameOverride: null,
            description: null,
          ),
          Property(
            name: 'value',
            model: oneOfModel,
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

      final result = generator.generateClass(model);
      final method = result.methods.firstWhere(
        (m) => m.name == 'parameterProperties',
      );
      final methodCode = format(method.accept(emitter).toString());

      const expectedMethod = r'''
@override
Map<String, PropertyValue> parameterProperties({bool allowEmpty = true}) {
  final _$result = <String, PropertyValue>{};
  _$result[r'signature'] = PropertyValue.scalar(this.signature.toBase64String());
  if (this.value.currentEncodingShape == EncodingShape.simple) {
    _$result[r'value'] = PropertyValue.scalar(encodeAnyValueToString(this.value.toJson(), allowEmpty: allowEmpty));
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
    });

    test('base64-encodes nullable byte additionalProperties values and omits '
        'null entries', () {
      final nullableByte = AliasModel(
        name: 'NullableSignature',
        model: Base64Model(context: context),
        context: context,
        isNullable: true,
        examples: const [],
        defaultValue: null,
        nameOverride: null,
        description: null,
        isDeprecated: false,
        isReadOnly: false,
        isWriteOnly: false,
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
            isReadOnly: false,
            isWriteOnly: false,
            nameOverride: null,
            description: null,
          ),
        ],
        context: context,
        additionalPropertiesPolicy: AllowedAdditionalProperties(
          valueModel: nullableByte,
          origin: AdditionalPropertiesOrigin.explicit,
        ),
        examples: const [],
        nameOverride: null,
        description: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
      );

      final result = generator.generateClass(model);
      final method = result.methods.firstWhere(
        (m) => m.name == 'parameterProperties',
      );
      final methodCode = format(method.accept(emitter).toString());

      const expectedMethod = r'''
@override
Map<String, PropertyValue> parameterProperties({bool allowEmpty = true}) {
  final _$result = <String, PropertyValue>{};
  _$result[r'name'] = PropertyValue.scalar(this.name);
  const _$knownKeys = {r'name'};
  for (final _$e in this.additionalProperties.entries) {
    if (_$knownKeys.contains(_$e.key)) {
      throw EncodingException(
        r'Additional property keys must not collide with declared wire keys of Filter',
      );
    }
    final _$v = _$e.value;
    if (_$v == null) continue;
    _$result[_$e.key] = PropertyValue.scalar(_$v.toBase64String());
  }
  return _$result;
}
''';

      expect(
        collapseWhitespace(methodCode),
        collapseWhitespace(format(expectedMethod)),
      );
    });
  });
}
