import 'package:change_case/change_case.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:meta/meta.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/naming/property_name_normalizer.dart';
import 'package:tonik_generate/src/util/copy_with_method_generator.dart';
import 'package:tonik_generate/src/util/core_prefixed_allocator.dart';
import 'package:tonik_generate/src/util/doc_comment_formatter.dart';
import 'package:tonik_generate/src/util/equals_method_generator.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';
import 'package:tonik_generate/src/util/format_with_header.dart';
import 'package:tonik_generate/src/util/from_form_value_expression_generator.dart';
import 'package:tonik_generate/src/util/from_json_value_expression_generator.dart';
import 'package:tonik_generate/src/util/from_simple_value_expression_generator.dart';
import 'package:tonik_generate/src/util/hash_code_generator.dart';
import 'package:tonik_generate/src/util/to_json_value_expression_generator.dart';
import 'package:tonik_generate/src/util/type_reference_generator.dart';
import 'package:tonik_generate/src/util/uri_encode_expression_generator.dart';
import 'package:tonik_util/tonik_util.dart';

/// A generator for creating Dart class files from model definitions.
@immutable
class ClassGenerator {
  const ClassGenerator({required this.nameManager, required this.package});

  final NameManager nameManager;
  final String package;

  static const deprecatedPropertyMessage = 'This property is deprecated.';

  ({String code, String filename}) generate(ClassModel model) {
    final emitter = DartEmitter(
      allocator: CorePrefixedAllocator(
        additionalImports: ['package:tonik_util/tonik_util.dart'],
      ),
      orderDirectives: true,
      useNullSafetySyntax: true,
    );

    final snakeCaseName = nameManager.modelName(model).toSnakeCase();
    final generatedClasses = generateClasses(model);

    final library = Library((b) {
      b.body.addAll(generatedClasses);
    });

    final formatter = DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    );

    final code = formatter.formatWithHeader(library.accept(emitter).toString());

    return (code: code, filename: '$snakeCaseName.dart');
  }

  @visibleForTesting
  List<Spec> generateClasses(ClassModel model) {
    final className = nameManager.modelName(model);
    final actualClassName = model.isNullable
        ? nameManager.modelName(
            AliasModel(
              name: '\$Raw$className',
              model: model,
              context: model.context,
            ),
          )
        : className;

    final normalizedProperties = normalizeProperties(model.properties.toList());

    final copyWithResult = _buildCopyWith(
      actualClassName,
      normalizedProperties,
    );

    return [
      _generateClassWithName(
        model,
        actualClassName,
        copyWithGetter: copyWithResult?.getter,
      ),
      if (copyWithResult != null) ...[
        copyWithResult.interfaceClass,
        copyWithResult.implClass,
      ],
      if (model.isNullable)
        TypeDef(
          (b) => b
            ..name = className
            ..definition = refer('$actualClassName?'),
        ),
    ];
  }

  @visibleForTesting
  Class generateClass(ClassModel model, [Method? copyWithGetter]) {
    final className = nameManager.modelName(model);
    return _generateClassWithName(
      model,
      className,
      copyWithGetter: copyWithGetter,
    );
  }

  Class _generateClassWithName(
    ClassModel model,
    String className, {
    Method? copyWithGetter,
  }) {
    final normalizedProperties = normalizeProperties(model.properties.toList());

    final effectiveCopyWithGetter =
        copyWithGetter ??
        _buildCopyWith(className, normalizedProperties)?.getter;

    final sortedProperties = [...normalizedProperties]
      ..sort((a, b) {
        if (a.property.isRequired != b.property.isRequired) {
          return a.property.isRequired ? -1 : 1;
        }
        return normalizedProperties.indexOf(a) -
            normalizedProperties.indexOf(b);
      });

    return Class(
      (b) {
        b
          ..name = className
          ..docs.addAll(formatDocComment(model.description))
          ..annotations.add(refer('immutable', 'package:meta/meta.dart'))
          ..implements.add(
            refer('ParameterEncodable', 'package:tonik_util/tonik_util.dart'),
          );

        if (model.isDeprecated) {
          b.annotations.add(
            refer('Deprecated', 'dart:core').call([
              literalString('This class is deprecated.'),
            ]),
          );
        }

        b.constructors.addAll([
          Constructor(
            (b) => b
              ..constant = true
              ..optionalParameters.addAll(
                sortedProperties.map(
                  (prop) => Parameter(
                    (b) => b
                      ..name = prop.normalizedName
                      ..named = true
                      ..required = prop.property.isRequired
                      ..toThis = true,
                  ),
                ),
              ),
          ),
          _buildFromSimpleConstructor(className, model),
          _buildFromJsonConstructor(className, model),
          _buildFromFormConstructor(className, model),
        ]);

        b.methods.addAll([
          _buildToJsonMethod(model),
          ?effectiveCopyWithGetter,
          _buildEqualsMethod(className, normalizedProperties),
          _buildHashCodeMethod(normalizedProperties),
          _buildCurrentEncodingShapeGetter(),
          _buildParameterPropertiesMethod(
            model,
            normalizedProperties
                .where((p) => !p.property.isReadOnly)
                .toList(),
          ),
          _buildToSimpleMethod(),
          _buildToFormMethod(),
          _buildToLabelMethod(),
          _buildToMatrixMethod(),
          _buildToDeepObjectMethod(),
        ]);

        b.fields.addAll(
          normalizedProperties.map(
            (prop) => _generateField(prop.property, prop.normalizedName),
          ),
        );
      },
    );
  }

  CopyWithResult? _buildCopyWith(
    String className,
    List<({String normalizedName, Property property})> properties,
  ) {
    return generateCopyWith(
      className: className,
      properties: properties.map(
        (prop) {
          final model = prop.property.model;
          final resolvedModel = model is AliasModel ? model.resolved : model;
          return (
            normalizedName: prop.normalizedName,
            typeRef: _getTypeReference(prop.property),
            skipCast: resolvedModel is AnyModel,
          );
        },
      ).toList(),
    );
  }

  Method _buildEqualsMethod(
    String className,
    List<({String normalizedName, Property property})> properties,
  ) {
    return generateEqualsMethod(
      className: className,
      properties: properties
          .map(
            (prop) => (
              normalizedName: prop.normalizedName,
              hasCollectionValue: prop.property.model is ListModel,
            ),
          )
          .toList(),
    );
  }

  Method _buildHashCodeMethod(
    List<({String normalizedName, Property property})> properties,
  ) {
    return generateHashCodeMethod(
      properties: properties
          .map(
            (p) => (
              normalizedName: p.normalizedName,
              hasCollectionValue: p.property.model is ListModel,
            ),
          )
          .toList(),
    );
  }

  Constructor _buildFromSimpleConstructor(String className, ClassModel model) {
    final readProperties =
        model.properties.where((p) => !p.isWriteOnly).toList();
    final normalizedProperties = normalizeProperties(readProperties);

    final canBeSimplyEncoded = readProperties.every((property) {
      final propertyModel = property.model;
      final shape = propertyModel.encodingShape;

      if (shape == .simple || shape == .mixed) {
        return true;
      }

      if (propertyModel is ListModel && propertyModel.hasSimpleContent) {
        return true;
      }

      return false;
    });

    return Constructor(
      (b) => b
        ..factory = true
        ..name = 'fromSimple'
        ..requiredParameters.add(
          Parameter(
            (b) => b
              ..name = 'value'
              ..type = refer('String?', 'dart:core'),
          ),
        )
        ..optionalParameters.add(
          buildBoolParameter('explode', required: true),
        )
        ..body = _buildFromSimpleBody(
          className,
          normalizedProperties,
          canBeSimplyEncoded,
        ),
    );
  }

  Block _buildFromSimpleBody(
    String className,
    List<({String normalizedName, Property property})> properties,
    bool canBeSimplyEncoded,
  ) {
    if (properties.isEmpty) {
      return Block.of([Code('return $className();')]);
    }

    if (!canBeSimplyEncoded) {
      return Block.of([
        generateSimpleDecodingExceptionExpression(
          'Simple encoding not supported for $className: '
          'contains complex types',
          raw: true,
        ).statement,
      ]);
    }

    final constructorArgs = <String, Expression>{};
    for (final prop in properties) {
      final normalizedName = prop.normalizedName;
      final propertyName = prop.property.name;
      final modelType = prop.property.model;
      final isRequired = prop.property.isRequired;
      final isNullable = prop.property.isNullable;

      constructorArgs[normalizedName] = buildSimpleValueExpression(
        refer("values[r'$propertyName']"),
        model: modelType,
        isRequired: isRequired && !isNullable,
        nameManager: nameManager,
        package: package,
        contextClass: className,
        contextProperty: propertyName,
        explode: refer('explode'),
      );
    }

    // Build expectedKeys and listKeys sets
    final expectedKeys = properties.map((p) => p.property.name).toSet();
    final listKeys = properties
        .where((p) => p.property.model is ListModel)
        .map((p) => p.property.name)
        .toSet();

    return Block.of([
      declareFinal('values')
          .assign(
            refer('value').property('decodeObject').call([], {
              'explode': refer('explode'),
              'explodeSeparator': literalString(','),
              'expectedKeys': literalSet(
                expectedKeys.map((k) => literalString(k, raw: true)),
              ),
              'listKeys': literalSet(
                listKeys.map((k) => literalString(k, raw: true)),
              ),
              'context': literalString(className, raw: true),
            }),
          )
          .statement,

      refer(className, package).call([], constructorArgs).returned.statement,
    ]);
  }

  Constructor _buildFromJsonConstructor(String className, ClassModel model) =>
      Constructor(
        (b) => b
          ..factory = true
          ..name = 'fromJson'
          ..requiredParameters.add(
            Parameter(
              (b) => b
                ..name = 'json'
                ..type = refer('Object?', 'dart:core'),
            ),
          )
          ..body = _buildFromJsonBody(className, model),
      );

  Code _buildFromJsonBody(String className, ClassModel model) {
    final normalizedProperties = normalizeProperties(
      model.properties
          .where((p) => !p.isWriteOnly)
          .toList(),
    );

    // If there are no properties, just return the constructor call.
    if (normalizedProperties.isEmpty) {
      return Block.of([Code('return $className();')]);
    }

    final codes = <Code>[
      Code("final map = json.decodeMap(context: r'$className');"),
    ];

    final propertyAssignments = <Code>[];

    for (final prop in normalizedProperties) {
      final property = prop.property;
      final normalizedName = prop.normalizedName;
      final jsonKey = property.name;

      final valueExpr = buildFromJsonValueExpression(
        "map[r'$jsonKey']",
        model: property.model,
        nameManager: nameManager,
        package: package,
        contextClass: className,
        contextProperty: jsonKey,
        isNullable: property.isNullable || !property.isRequired,
      ).code;

      propertyAssignments
        ..add(Code('$normalizedName: '))
        ..add(valueExpr)
        ..add(const Code(','));
    }

    codes
      ..add(Code('return $className('))
      ..addAll(propertyAssignments)
      ..add(const Code(');'));

    return Block.of(codes);
  }

  Method _buildToJsonMethod(ClassModel model) {
    final normalizedProperties = normalizeProperties(
      model.properties
          .where((p) => !p.isReadOnly)
          .toList(),
    );

    // Build the map entries, handling optional properties with if-blocks
    final mapEntries = <Code>[];
    for (final prop in normalizedProperties) {
      final name = prop.normalizedName;
      final property = prop.property;
      final valueExpr = buildToJsonPropertyExpression(name, property);

      if (!property.isRequired && !property.isNullable) {
        mapEntries
          ..add(Code("if ($name != null) r'${property.name}': "))
          ..add(valueExpr.code)
          ..add(const Code(','));
      } else {
        mapEntries
          ..add(Code("r'${property.name}': "))
          ..add(valueExpr.code)
          ..add(const Code(','));
      }
    }

    return Method(
      (b) => b
        ..annotations.add(refer('override', 'dart:core'))
        ..name = 'toJson'
        ..returns = refer('Object?', 'dart:core')
        ..lambda = true
        ..body = Block.of([
          const Code('{'),
          ...mapEntries,
          const Code('}'),
        ]),
    );
  }

  Field _generateField(Property property, String normalizedName) {
    final fieldBuilder = FieldBuilder()
      ..name = normalizedName
      ..docs.addAll(formatDocComment(property.description))
      ..modifier = FieldModifier.final$
      ..type = _getTypeReference(property);

    if (property.isDeprecated) {
      fieldBuilder.annotations.add(
        refer(
          'Deprecated',
          'dart:core',
        ).call([literalString(deprecatedPropertyMessage)]),
      );
    }

    return fieldBuilder.build();
  }

  TypeReference _getTypeReference(Property property) {
    return typeReference(
      property.model,
      nameManager,
      package,
      isNullableOverride: property.isNullable || !property.isRequired,
    );
  }

  Method _buildCurrentEncodingShapeGetter() {
    final shapeRef = refer(
      'EncodingShape',
      'package:tonik_util/tonik_util.dart',
    ).property('complex');

    return Method(
      (b) => b
        ..name = 'currentEncodingShape'
        ..type = MethodType.getter
        ..returns = refer(
          'EncodingShape',
          'package:tonik_util/tonik_util.dart',
        )
        ..lambda = true
        ..body = shapeRef.code,
    );
  }

  Method _buildParameterPropertiesMethod(
    ClassModel model,
    List<({String normalizedName, Property property})> properties,
  ) {
    final className = nameManager.modelName(model);

    final hasOnlySimpleProperties = properties.every(
      (prop) => prop.property.model.encodingShape == EncodingShape.simple,
    );

    if (hasOnlySimpleProperties) {
      return _buildSimpleParameterPropertiesMethod(className, properties);
    }

    final hasComplexProperties = properties.any(
      (prop) => prop.property.model.encodingShape == EncodingShape.complex,
    );

    if (hasComplexProperties) {
      final allComplexAreSimpleLists = properties
          .where((p) => p.property.model.encodingShape == EncodingShape.complex)
          .every(
            (p) =>
                p.property.model is ListModel &&
                (p.property.model as ListModel).hasSimpleContent,
          );

      if (allComplexAreSimpleLists) {
        return _buildListParameterPropertiesMethod(className, properties);
      }

      return _buildComplexParameterPropertiesMethod(className, properties);
    }

    return _buildMixedParameterPropertiesMethod(className, properties);
  }

  List<Parameter> _buildParameterPropertiesParameters() {
    return [
      Parameter(
        (b) => b
          ..name = 'allowEmpty'
          ..type = refer('bool', 'dart:core')
          ..named = true
          ..required = false
          ..defaultTo = literalTrue.code,
      ),
      Parameter(
        (b) => b
          ..name = 'allowLists'
          ..type = refer('bool', 'dart:core')
          ..named = true
          ..required = false
          ..defaultTo = literalTrue.code,
      ),
      Parameter(
        (b) => b
          ..name = 'useQueryComponent'
          ..type = refer('bool', 'dart:core')
          ..named = true
          ..required = false
          ..defaultTo = literalFalse.code,
      ),
    ];
  }

  Method _buildSimpleParameterPropertiesMethod(
    String className,
    List<({String normalizedName, Property property})> properties,
  ) {
    if (properties.isEmpty) {
      return Method(
        (b) => b
          ..name = 'parameterProperties'
          ..returns = buildMapStringStringType()
          ..optionalParameters.addAll(_buildParameterPropertiesParameters())
          ..body = buildEmptyMapStringString().returned.statement,
      );
    }

    final propertyAssignments = <Code>[];

    for (final prop in properties) {
      final name = prop.normalizedName;
      final propertyName = prop.property.name;
      final isRequired = prop.property.isRequired;
      final isNullable = prop.property.isNullable;
      final model = prop.property.model;
      final resolvedModel = model is AliasModel ? model.resolved : model;

      if (resolvedModel is NeverModel) {
        propertyAssignments.addAll([
          generateEncodingExceptionExpression(
            'Cannot encode NeverModel property $propertyName: '
            'this type does not permit any value',
            raw: true,
          ).statement,
        ]);
        continue;
      }

      if (isRequired && !isNullable) {
        propertyAssignments.add(
          Code(
            "result[r'$propertyName'] = "
            '$name.uriEncode(allowEmpty: allowEmpty, '
            'useQueryComponent: useQueryComponent);',
          ),
        );
      } else if (isRequired && isNullable) {
        propertyAssignments.add(
          Code('''
if ($name != null) {
  result[r'$propertyName'] = $name!.uriEncode(allowEmpty: allowEmpty, useQueryComponent: useQueryComponent);
} else if (allowEmpty) {
  result[r'$propertyName'] = '';
}'''),
        );
      } else {
        propertyAssignments.add(
          Code('''
if ($name != null) {
  result[r'$propertyName'] = $name!.uriEncode(allowEmpty: allowEmpty, useQueryComponent: useQueryComponent);
} else if (allowEmpty) {
  result[r'$propertyName'] = '';
}'''),
        );
      }
    }

    final methodBody = [
      const Code('final result = '),
      buildEmptyMapStringString().statement,
      ...propertyAssignments,
      const Code('return result;'),
    ];

    return Method(
      (b) => b
        ..name = 'parameterProperties'
        ..returns = buildMapStringStringType()
        ..optionalParameters.addAll(_buildParameterPropertiesParameters())
        ..body = Block.of(methodBody),
    );
  }

  Method _buildListParameterPropertiesMethod(
    String className,
    List<({String normalizedName, Property property})> properties,
  ) {
    final listProperties = properties
        .where(
          (p) =>
              p.property.model is ListModel &&
              (p.property.model as ListModel).hasSimpleContent,
        )
        .toList();

    final hasRequiredNonNullableLists = listProperties.any(
      (p) => p.property.isRequired && !p.property.isNullable,
    );

    final methodBody = <Code>[];

    if (hasRequiredNonNullableLists) {
      methodBody.addAll([
        const Code('if (!allowLists) {'),
        generateEncodingExceptionExpression(
          'Lists are not supported in this encoding style',
        ).statement,
        const Code('}'),
      ]);
    }

    final propertyAssignments = <Code>[];

    for (final prop in properties) {
      final name = prop.normalizedName;
      final propertyName = prop.property.name;
      final fieldModel = prop.property.model;
      final isRequired = prop.property.isRequired;
      final isNullable = prop.property.isNullable;

      if (fieldModel.encodingShape == EncodingShape.simple) {
        if (isRequired && !isNullable) {
          propertyAssignments.add(
            Code(
              "result[r'$propertyName'] = "
              '$name.uriEncode(allowEmpty: allowEmpty, '
              'useQueryComponent: useQueryComponent);',
            ),
          );
        } else {
          propertyAssignments.add(
            Code('''
if ($name != null) {
  result[r'$propertyName'] = $name!.uriEncode(allowEmpty: allowEmpty, useQueryComponent: useQueryComponent);
} else if (allowEmpty) {
  result[r'$propertyName'] = '';
}'''),
          );
        }
      } else if (fieldModel is ListModel && fieldModel.hasSimpleContent) {
        final valueRef = (isRequired && !isNullable)
            ? refer(name)
            : refer(name).nullChecked;
        final encodeExpr = buildUriEncodeExpression(
          valueRef,
          fieldModel,
          allowEmpty: refer('allowEmpty'),
          useQueryComponent: refer('useQueryComponent'),
        );

        final assignmentExpr = refer(
          'result',
        ).index(literalString(propertyName, raw: true)).assign(encodeExpr);

        if (isRequired && !isNullable) {
          propertyAssignments.add(assignmentExpr.statement);
        } else {
          methodBody
            ..add(
              Code('if (!allowLists && $name != null) {'),
            )
            ..add(
              generateEncodingExceptionExpression(
                'Lists are not supported in this encoding style',
              ).statement,
            )
            ..add(const Code('}'));

          propertyAssignments
            ..add(
              Code('if ($name != null) {'),
            )
            ..add(assignmentExpr.statement)
            ..add(
              Code('''
} else if (allowEmpty) {
  result[r'$propertyName'] = '';
}'''),
            );
        }
      }
    }

    methodBody.addAll([
      const Code('final result = '),
      buildEmptyMapStringString().statement,
      ...propertyAssignments,
      const Code('return result;'),
    ]);

    return Method(
      (b) => b
        ..name = 'parameterProperties'
        ..returns = buildMapStringStringType()
        ..optionalParameters.addAll(_buildParameterPropertiesParameters())
        ..body = Block.of(methodBody),
    );
  }

  Method _buildComplexParameterPropertiesMethod(
    String className,
    List<({String normalizedName, Property property})> properties,
  ) {
    return Method(
      (b) => b
        ..name = 'parameterProperties'
        ..returns = buildMapStringStringType()
        ..optionalParameters.addAll(_buildParameterPropertiesParameters())
        ..body = generateEncodingExceptionExpression(
          'parameterProperties not supported for $className: '
          'contains complex types',
          raw: true,
        ).code,
    );
  }

  Method _buildMixedParameterPropertiesMethod(
    String className,
    List<({String normalizedName, Property property})> properties,
  ) {
    final propertyAssignments = <Code>[];

    for (final prop in properties) {
      final name = prop.normalizedName;
      final propertyName = prop.property.name;
      final isRequired = prop.property.isRequired;
      final isNullable = prop.property.isNullable;
      final model = prop.property.model;
      final resolvedModel = model is AliasModel ? model.resolved : model;

      if (resolvedModel is AnyModel) {
        propertyAssignments.add(
          Code("result[r'$propertyName'] = $name?.toString() ?? '';"),
        );
        continue;
      }

      if (resolvedModel is NeverModel) {
        propertyAssignments.addAll([
          generateEncodingExceptionExpression(
            'Cannot encode NeverModel property $propertyName: '
            'this type does not permit any value',
            raw: true,
          ).statement,
        ]);
        continue;
      }

      if (model.encodingShape == .simple) {
        if (isRequired && !isNullable) {
          propertyAssignments.add(
            Code(
              "result[r'$propertyName'] = "
              '$name.uriEncode(allowEmpty: allowEmpty, '
              'useQueryComponent: useQueryComponent);',
            ),
          );
        } else if (isRequired && isNullable) {
          propertyAssignments.add(
            Code('''
if ($name != null) {
  result[r'$propertyName'] = $name!.uriEncode(allowEmpty: allowEmpty, useQueryComponent: useQueryComponent);
} else if (allowEmpty) {
  result[r'$propertyName'] = '';
}'''),
          );
        } else {
          propertyAssignments.add(
            Code('''
if ($name != null) {
  result[r'$propertyName'] = $name!.uriEncode(allowEmpty: allowEmpty, useQueryComponent: useQueryComponent);
} else if (allowEmpty) {
  result[r'$propertyName'] = '';
}'''),
          );
        }
      } else {
        final isFieldNullable = isNullable || !isRequired;
        final encodingShapeRef = refer(
          'EncodingShape',
          'package:tonik_util/tonik_util.dart',
        );

        if (isFieldNullable) {
          propertyAssignments.addAll([
            Code('if ($name != null) {'),
            Code('  if ($name!.currentEncodingShape == '),
            encodingShapeRef.property('simple').code,
            const Code(') {'),
            Code(
              "    result[r'$propertyName'] = "
              '$name!.toSimple(explode: false, allowEmpty: allowEmpty);',
            ),
            const Code('} else {'),
            generateEncodingExceptionExpression(
              'parameterProperties not supported for $className: '
              'contains complex types',
              raw: true,
            ).statement,
            const Code('}}'),
          ]);
        } else {
          propertyAssignments.addAll([
            Code('if ($name.currentEncodingShape == '),
            encodingShapeRef.property('simple').code,
            const Code(') {'),
            Code(
              "  result[r'$propertyName'] = "
              '$name.toSimple(explode: false, allowEmpty: allowEmpty);',
            ),
            const Code('} else {'),
            generateEncodingExceptionExpression(
              'parameterProperties not supported for $className: '
              'contains complex types',
              raw: true,
            ).statement,
            const Code('}'),
          ]);
        }
      }
    }

    final methodBody = [
      const Code('final result = '),
      buildEmptyMapStringString().statement,
      ...propertyAssignments,
      const Code('return result;'),
    ];

    return Method(
      (b) => b
        ..name = 'parameterProperties'
        ..returns = buildMapStringStringType()
        ..optionalParameters.addAll(_buildParameterPropertiesParameters())
        ..body = Block.of(methodBody),
    );
  }

  Method _buildToSimpleMethod() => Method(
    (b) => b
      ..annotations.add(refer('override', 'dart:core'))
      ..name = 'toSimple'
      ..returns = refer('String', 'dart:core')
      ..optionalParameters.addAll(buildEncodingParameters())
      ..body = Block.of([
        refer('parameterProperties')
            .call([], {'allowEmpty': refer('allowEmpty')})
            .property('toSimple')
            .call([], {
              'explode': refer('explode'),
              'allowEmpty': refer('allowEmpty'),
              'alreadyEncoded': literalBool(true),
            })
            .returned
            .statement,
      ]),
  );

  Constructor _buildFromFormConstructor(String className, ClassModel model) {
    final readProperties =
        model.properties.where((p) => !p.isWriteOnly).toList();
    final normalizedProperties = normalizeProperties(readProperties);

    final canBeFormEncoded = readProperties.every((property) {
      final propertyModel = property.model;
      final shape = propertyModel.encodingShape;

      if (shape == .simple || shape == .mixed) {
        return true;
      }

      if (propertyModel is ListModel && propertyModel.hasSimpleContent) {
        return true;
      }

      return false;
    });

    return Constructor(
      (b) => b
        ..factory = true
        ..name = 'fromForm'
        ..requiredParameters.add(
          Parameter(
            (b) => b
              ..name = 'value'
              ..type = refer('String?', 'dart:core'),
          ),
        )
        ..optionalParameters.add(
          buildBoolParameter('explode', required: true),
        )
        ..body = _buildFromFormBody(
          className,
          normalizedProperties,
          canBeFormEncoded,
        ),
    );
  }

  Block _buildFromFormBody(
    String className,
    List<({String normalizedName, Property property})> properties,
    bool canBeFormEncoded,
  ) {
    if (properties.isEmpty) {
      return Block.of([Code('return $className();')]);
    }

    if (!canBeFormEncoded) {
      return Block.of([
        generateFormatDecodingExceptionExpression(
          'Form encoding not supported for $className: contains complex types',
          raw: true,
        ).statement,
      ]);
    }

    final constructorArgs = <String, Expression>{};
    for (final prop in properties) {
      final normalizedName = prop.normalizedName;
      final propertyName = prop.property.name;
      final modelType = prop.property.model;
      final isRequired = prop.property.isRequired;
      final isNullable = prop.property.isNullable;

      constructorArgs[normalizedName] = buildFromFormValueExpression(
        refer("values[r'$propertyName']"),
        model: modelType,
        isRequired: isRequired && !isNullable,
        nameManager: nameManager,
        package: package,
        contextClass: className,
        contextProperty: propertyName,
        explode: refer('explode'),
      );
    }

    // Build expectedKeys and listKeys sets
    final expectedKeys = properties.map((p) => p.property.name).toSet();
    final listKeys = properties
        .where((p) => p.property.model is ListModel)
        .map((p) => p.property.name)
        .toSet();

    return Block.of([
      declareFinal('values')
          .assign(
            refer('value').property('decodeObject').call([], {
              'explode': refer('explode'),
              'explodeSeparator': literalString('&'),
              'expectedKeys': literalSet(
                expectedKeys.map((k) => literalString(k, raw: true)),
              ),
              'listKeys': literalSet(
                listKeys.map((k) => literalString(k, raw: true)),
              ),
              'context': literalString(className, raw: true),
            }),
          )
          .statement,

      refer(className, package).call([], constructorArgs).returned.statement,
    ]);
  }

  Method _buildToFormMethod() => Method(
    (b) => b
      ..annotations.add(refer('override', 'dart:core'))
      ..name = 'toForm'
      ..returns = refer('String', 'dart:core')
      ..optionalParameters.addAll(buildFormEncodingParameters())
      ..body = Block.of([
        refer('parameterProperties')
            .call([], {
              'allowEmpty': refer('allowEmpty'),
              'useQueryComponent': refer('useQueryComponent'),
            })
            .property('toForm')
            .call([], {
              'explode': refer('explode'),
              'allowEmpty': refer('allowEmpty'),
              'alreadyEncoded': literalBool(true),
              'useQueryComponent': refer('useQueryComponent'),
            })
            .returned
            .statement,
      ]),
  );

  Method _buildToLabelMethod() => Method(
    (b) => b
      ..annotations.add(refer('override', 'dart:core'))
      ..name = 'toLabel'
      ..returns = refer('String', 'dart:core')
      ..optionalParameters.addAll(buildEncodingParameters())
      ..body = Block.of([
        refer('parameterProperties')
            .call([], {'allowEmpty': refer('allowEmpty')})
            .property('toLabel')
            .call([], {
              'explode': refer('explode'),
              'allowEmpty': refer('allowEmpty'),
              'alreadyEncoded': literalBool(true),
            })
            .returned
            .statement,
      ]),
  );

  Method _buildToMatrixMethod() => Method(
    (b) => b
      ..annotations.add(refer('override', 'dart:core'))
      ..name = 'toMatrix'
      ..returns = refer('String', 'dart:core')
      ..requiredParameters.add(
        Parameter(
          (b) => b
            ..name = 'paramName'
            ..type = refer('String', 'dart:core'),
        ),
      )
      ..optionalParameters.addAll(buildEncodingParameters())
      ..body = Block.of([
        refer('parameterProperties')
            .call([], {'allowEmpty': refer('allowEmpty')})
            .property('toMatrix')
            .call(
              [refer('paramName')],
              {
                'explode': refer('explode'),
                'allowEmpty': refer('allowEmpty'),
                'alreadyEncoded': literalBool(true),
              },
            )
            .returned
            .statement,
      ]),
  );

  Method _buildToDeepObjectMethod() => Method(
    (b) => b
      ..annotations.add(refer('override', 'dart:core'))
      ..name = 'toDeepObject'
      ..returns = TypeReference(
        (b) => b
          ..symbol = 'List'
          ..url = 'dart:core'
          ..types.add(
            refer(
              'ParameterEntry',
              'package:tonik_util/tonik_util.dart',
            ),
          ),
      )
      ..requiredParameters.add(
        Parameter(
          (b) => b
            ..name = 'paramName'
            ..type = refer('String', 'dart:core'),
        ),
      )
      ..optionalParameters.addAll(buildEncodingParameters())
      ..body = Block.of([
        refer('parameterProperties')
            .call([], {
              'allowEmpty': refer('allowEmpty'),
              'allowLists': literalBool(false),
            })
            .property('toDeepObject')
            .call(
              [refer('paramName')],
              {
                'explode': refer('explode'),
                'allowEmpty': refer('allowEmpty'),
                'alreadyEncoded': literalBool(true),
              },
            )
            .returned
            .statement,
      ]),
  );
}
