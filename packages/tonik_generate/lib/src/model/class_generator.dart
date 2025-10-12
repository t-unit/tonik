import 'package:change_case/change_case.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:meta/meta.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/naming/property_name_normalizer.dart';
import 'package:tonik_generate/src/util/copy_with_method_generator.dart';
import 'package:tonik_generate/src/util/core_prefixed_allocator.dart';
import 'package:tonik_generate/src/util/equals_method_generator.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';
import 'package:tonik_generate/src/util/format_with_header.dart';
import 'package:tonik_generate/src/util/from_form_value_expression_generator.dart';
import 'package:tonik_generate/src/util/from_json_value_expression_generator.dart';
import 'package:tonik_generate/src/util/from_simple_value_expression_generator.dart';
import 'package:tonik_generate/src/util/hash_code_generator.dart';
import 'package:tonik_generate/src/util/to_json_value_expression_generator.dart';
import 'package:tonik_generate/src/util/type_reference_generator.dart';
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

    final library = Library((b) {
      b.body.add(generateClass(model));
    });

    final formatter = DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    );

    final code = formatter.formatWithHeader(library.accept(emitter).toString());

    return (code: code, filename: '$snakeCaseName.dart');
  }

  @visibleForTesting
  Class generateClass(ClassModel model) {
    final className = nameManager.modelName(model);
    final normalizedProperties = normalizeProperties(model.properties.toList());

    final sortedProperties = [...normalizedProperties]..sort((a, b) {
      // Required fields come before non-required fields
      if (a.property.isRequired != b.property.isRequired) {
        return a.property.isRequired ? -1 : 1;
      }
      // Keep original order for fields with same required status
      return normalizedProperties.indexOf(a) - normalizedProperties.indexOf(b);
    });

    return Class(
      (b) =>
          b
            ..name = className
            ..annotations.add(refer('immutable', 'package:meta/meta.dart'))
            ..constructors.addAll([
              Constructor(
                (b) =>
                    b
                      ..constant = true
                      ..optionalParameters.addAll(
                        sortedProperties.map(
                          (prop) => Parameter(
                            (b) =>
                                b
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
            ])
            ..methods.addAll([
              _buildToJsonMethod(model),
              _buildCopyWithMethod(className, normalizedProperties),
              _buildEqualsMethod(className, normalizedProperties),
              _buildHashCodeMethod(normalizedProperties),
              _buildCurrentEncodingShapeGetter(normalizedProperties),
              _buildSimplePropertiesMethod(model, normalizedProperties),
              _buildToSimpleMethod(className, model, normalizedProperties),
              _buildFormPropertiesMethod(model, normalizedProperties),
              _buildToFormMethod(className, model, normalizedProperties),
              _buildLabelPropertiesMethod(model, normalizedProperties),
              _buildToLabelMethod(className, model, normalizedProperties),
            ])
            ..fields.addAll(
              normalizedProperties.map(
                (prop) => _generateField(prop.property, prop.normalizedName),
              ),
            ),
    );
  }

  Method _buildCopyWithMethod(
    String className,
    List<({String normalizedName, Property property})> properties,
  ) {
    return generateCopyWithMethod(
      className: className,
      properties:
          properties
              .map(
                (prop) => (
                  normalizedName: prop.normalizedName,
                  typeRef: _getTypeReference(prop.property),
                ),
              )
              .toList(),
    );
  }

  Method _buildEqualsMethod(
    String className,
    List<({String normalizedName, Property property})> properties,
  ) {
    return generateEqualsMethod(
      className: className,
      properties:
          properties
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
      properties:
          properties
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
    final normalizedProperties = normalizeProperties(model.properties.toList());

    final hasOnlySimpleProperties = model.properties.every((property) {
      return property.model.encodingShape == EncodingShape.simple;
    });

    return Constructor(
      (b) =>
          b
            ..factory = true
            ..name = 'fromSimple'
            ..requiredParameters.add(
              Parameter(
                (b) =>
                    b
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
              hasOnlySimpleProperties,
            ),
    );
  }

  Block _buildFromSimpleBody(
    String className,
    List<({String normalizedName, Property property})> properties,
    bool hasOnlySimpleProperties,
  ) {
    if (properties.isEmpty) {
      return Block.of([Code('return $className();')]);
    }

    if (!hasOnlySimpleProperties) {
      return Block.of([
        generateEncodingExceptionExpression(
          'Simple encoding not supported for $className: '
          'contains complex types',
        ).statement,
      ]);
    }

    final constructorArgs = <String, Expression>{};
    for (final prop in properties) {
      final normalizedName = prop.normalizedName;
      final propertyName = prop.property.name;
      final modelType = prop.property.model;
      final isNullable = prop.property.isNullable;

      constructorArgs[normalizedName] = buildSimpleValueExpression(
        refer("values['$propertyName']"),
        model: modelType,
        isRequired: !isNullable,
        nameManager: nameManager,
        package: package,
        contextClass: className,
        contextProperty: propertyName,
        explode: refer('explode'),
      );
    }

    return Block.of([
      // Null/empty check
      const Code('if (value == null || value.isEmpty) {'),
      generateSimpleDecodingExceptionExpression(
        'Invalid empty value for $className',
      ).statement,
      const Code('}'),

      // Parse into key-value pairs (only part that differs by explode mode)
      declareFinal('values')
          .assign(
            buildEmptyMapStringString(),
          )
          .statement,
      _buildExplodeParsingLogic(),

      // Constructor call
      refer(className, package).call([], constructorArgs).returned.statement,
    ]);
  }

  Constructor _buildFromJsonConstructor(String className, ClassModel model) =>
      Constructor(
        (b) =>
            b
              ..factory = true
              ..name = 'fromJson'
              ..requiredParameters.add(
                Parameter(
                  (b) =>
                      b
                        ..name = 'json'
                        ..type = refer('Object?', 'dart:core'),
                ),
              )
              ..body = _buildFromJsonBody(className, model),
      );

  Code _buildFromJsonBody(String className, ClassModel model) {
    final normalizedProperties = normalizeProperties(model.properties.toList());

    // If there are no properties, just return the constructor call
    if (normalizedProperties.isEmpty) {
      return Block.of([Code('return $className();')]);
    }

    final codes = <Code>[
      Code("final map = json.decodeMap(context: '$className');"),
    ];

    final propertyAssignments = <Code>[];

    for (final prop in normalizedProperties) {
      final property = prop.property;
      final normalizedName = prop.normalizedName;
      final jsonKey = property.name;

      final valueExpr =
          buildFromJsonValueExpression(
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
    final normalizedProperties = normalizeProperties(model.properties.toList());
    final propertyAssignments = <String>[];
    for (final prop in normalizedProperties) {
      final name = prop.normalizedName;
      final property = prop.property;
      final value = buildToJsonPropertyExpression(name, property);

      if (!property.isRequired && !property.isNullable) {
        propertyAssignments.add(
          "if ($name != null) r'${property.name}': $value",
        );
      } else {
        propertyAssignments.add("r'${property.name}': $value");
      }
    }

    return Method(
      (b) =>
          b
            ..name = 'toJson'
            ..returns = refer('Object?', 'dart:core')
            ..lambda = true
            ..body = Code('{${propertyAssignments.join(', ')}}'),
    );
  }

  Field _generateField(Property property, String normalizedName) {
    final fieldBuilder =
        FieldBuilder()
          ..name = normalizedName
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

  Method _buildCurrentEncodingShapeGetter(
    List<({String normalizedName, Property property})> properties,
  ) {
    final shapeRef = refer(
      'EncodingShape',
      'package:tonik_util/tonik_util.dart',
    ).property('complex');

    return Method(
      (b) =>
          b
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

  Method _buildSimplePropertiesMethod(
    ClassModel model,
    List<({String normalizedName, Property property})> properties,
  ) {
    return _buildPropertiesMethod(
      model,
      properties,
      'simpleProperties',
      'toSimple',
    );
  }

  Method _buildToSimpleMethod(
    String className,
    ClassModel model,
    List<({String normalizedName, Property property})> properties,
  ) {
    return _buildToMethod(
      className,
      model,
      properties,
      'toSimple',
      'simpleProperties',
    );
  }

  Code _buildExplodeParsingLogic() {
    return Block.of([
      const Code('if (explode) {'),
      // explode=true: prop1=val1,prop2=val2
      declareFinal('pairs')
          .assign(
            refer('value').property('split').call([literalString(',')]),
          )
          .statement,
      const Code('for (final pair in pairs) {'),
      declareFinal('parts')
          .assign(
            refer('pair').property('split').call([literalString('=')]),
          )
          .statement,
      const Code('if (parts.length != 2) {'),
      generateSimpleDecodingExceptionExpression(
        r'Invalid key=value pair format: $pair',
      ).statement,
      const Code('}'),
      refer('values')
          .index(
            refer('Uri', 'dart:core').property('decodeComponent').call([
              refer('parts').index(literalNum(0)),
            ]),
          )
          .assign(refer('parts').index(literalNum(1)))
          .statement,
      const Code('}'),
      const Code('} else {'),
      // explode=false: prop1,val1,prop2,val2
      declareFinal('parts')
          .assign(
            refer('value').property('split').call([literalString(',')]),
          )
          .statement,
      const Code('if (parts.length % 2 != 0) {'),
      generateSimpleDecodingExceptionExpression(
        'Invalid alternating key-value format: expected even number of '
        r'parts, got ${parts.length}',
      ).statement,
      const Code('}'),
      const Code('for (var i = 0; i < parts.length; i += 2) {'),
      refer('values')
          .index(
            refer('Uri', 'dart:core').property('decodeComponent').call([
              refer('parts').index(refer('i')),
            ]),
          )
          .assign(refer('parts').index(refer('i').operatorAdd(literalNum(1))))
          .statement,
      const Code('}'),
      const Code('}'),
    ]);
  }

  Constructor _buildFromFormConstructor(String className, ClassModel model) {
    final normalizedProperties = normalizeProperties(model.properties.toList());

    final hasOnlySimpleProperties = model.properties.every((property) {
      return property.model.encodingShape == EncodingShape.simple;
    });

    return Constructor(
      (b) =>
          b
            ..factory = true
            ..name = 'fromForm'
            ..requiredParameters.add(
              Parameter(
                (b) =>
                    b
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
              hasOnlySimpleProperties,
            ),
    );
  }

  Block _buildFromFormBody(
    String className,
    List<({String normalizedName, Property property})> properties,
    bool hasOnlySimpleProperties,
  ) {
    if (properties.isEmpty) {
      return Block.of([Code('return $className();')]);
    }

    if (!hasOnlySimpleProperties) {
      return Block.of([
        generateSimpleDecodingExceptionExpression(
          'Form encoding not supported for $className: '
          'contains complex types',
        ).statement,
      ]);
    }

    final constructorArgs = <String, Expression>{};
    for (final prop in properties) {
      final normalizedName = prop.normalizedName;
      final propertyName = prop.property.name;
      final modelType = prop.property.model;
      final isNullable = prop.property.isNullable;

      constructorArgs[normalizedName] = buildFromFormValueExpression(
        refer("values['$propertyName']"),
        model: modelType,
        isRequired: !isNullable,
        nameManager: nameManager,
        package: package,
        contextClass: className,
        contextProperty: propertyName,
        explode: refer('explode'),
      );
    }

    return Block.of([
      const Code('if (value == null || value.isEmpty) {'),
      generateSimpleDecodingExceptionExpression(
        'Invalid empty value for $className',
      ).statement,
      const Code('}'),

      declareFinal('values')
          .assign(
            buildEmptyMapStringString(),
          )
          .statement,

      _buildExplodeParsingLogic(),
      refer(className, package).call([], constructorArgs).returned.statement,
    ]);
  }

  Method _buildFormPropertiesMethod(
    ClassModel model,
    List<({String normalizedName, Property property})> properties,
  ) {
    return _buildPropertiesMethod(
      model,
      properties,
      'formProperties',
      'toForm',
    );
  }

  Method _buildToFormMethod(
    String className,
    ClassModel model,
    List<({String normalizedName, Property property})> properties,
  ) {
    return _buildToMethod(
      className,
      model,
      properties,
      'toForm',
      'formProperties',
    );
  }

  /// Shared method to build properties methods (simpleProperties/formProperties).
  Method _buildPropertiesMethod(
    ClassModel model,
    List<({String normalizedName, Property property})> properties,
    String methodName,
    String encodingType,
  ) {
    // Check if we have any truly complex data (ClassModel, ListModel)
    // that can never be simple
    final hasTrulyComplexData = properties.any((prop) {
      final propertyModel = prop.property.model;
      return propertyModel is ClassModel || propertyModel is ListModel;
    });

    if (hasTrulyComplexData) {
      return Method(
        (b) =>
            b
              ..name = methodName
              ..returns = buildMapStringStringType()
              ..optionalParameters.add(
                Parameter(
                  (b) =>
                      b
                        ..name = 'allowEmpty'
                        ..type = refer('bool', 'dart:core')
                        ..named = true
                        ..defaultTo = literalBool(true).code,
                ),
              )
              ..body =
                  generateEncodingExceptionExpression(
                    '$methodName not supported for ${model.name}: '
                    'contains nested data',
                  ).statement,
      );
    }

    // Check if we have any composite models that need runtime checking
    final hasCompositeModels = properties.any((prop) {
      final propertyModel = prop.property.model;
      return propertyModel is CompositeModel;
    });

    if (hasCompositeModels) {
      return _buildPropertiesMethodWithRuntimeChecks(
        model,
        properties,
        methodName,
        encodingType,
      );
    }

    // Optimized path for simple properties only
    final mapEntries = <Code>[];

    for (final prop in properties) {
      final property = prop.property;
      final fieldName = prop.normalizedName;
      final rawName = property.name;

      mapEntries.add(
        _buildPropertyMapEntryExpression(
          fieldName,
          rawName,
          property,
          encodingType,
        ),
      );
    }

    final returnStatement =
        properties.isEmpty
            ? buildEmptyMapStringString().code
            : Block.of([
              const Code('return '),
              const Code('{'),
              ...mapEntries,
              const Code('};'),
            ]);

    return Method(
      (b) =>
          b
            ..name = methodName
            ..returns = buildMapStringStringType()
            ..optionalParameters.add(
              buildBoolParameter('allowEmpty', defaultValue: true),
            )
            ..lambda = properties.isEmpty
            ..body = returnStatement,
    );
  }

  /// Builds properties method with runtime checks for composite models.
  Method _buildPropertiesMethodWithRuntimeChecks(
    ClassModel model,
    List<({String normalizedName, Property property})> properties,
    String methodName,
    String encodingType,
  ) {
    final className = nameManager.modelName(model);
    final statements = [
      const Code('final mergedProperties = '),
      buildEmptyMapStringString().statement,
    ];

    for (final prop in properties) {
      final property = prop.property;
      final fieldName = prop.normalizedName;
      final rawName = property.name;
      final propertyModel = property.model;

      if (propertyModel is CompositeModel) {
        // Generate runtime check for composite models
        if (property.isRequired) {
          statements
            ..add(Code('if ( $fieldName.currentEncodingShape != '))
            ..add(
              refer(
                'EncodingShape.simple',
                'package:tonik_util/tonik_util.dart',
              ).code,
            )
            ..add(const Code(' ) {'))
            ..add(
              generateEncodingExceptionExpression(
                '''$methodName not supported for $className: contains complex types''',
              ).statement,
            )
            ..add(const Code('}'))
            ..add(
              Code(
                '''
                mergedProperties.addAll(
                  $fieldName.$methodName(allowEmpty: allowEmpty),
                );
                ''',
              ),
            );
        } else {
          // Handle nullable composite models
          statements
            ..add(
              Code(
                '''
                if ( $fieldName != null && $fieldName?.currentEncodingShape != ''',
              ),
            )
            ..add(
              refer(
                'EncodingShape.simple',
                'package:tonik_util/tonik_util.dart',
              ).code,
            )
            ..add(const Code(' ) {'))
            ..add(
              generateEncodingExceptionExpression(
                '''$methodName not supported for $className: contains complex types''',
              ).statement,
            )
            ..add(const Code('}'))
            ..add(
              Code(
                '''
                if ($fieldName != null) { 
                  mergedProperties.addAll($fieldName!.$methodName(allowEmpty: allowEmpty)); 
                }''',
              ),
            );
        }
      } else {
        // Handle simple properties with optimized path
        if (property.isRequired && property.isNullable) {
          statements.add(
            Code(
              '''
            if (allowEmpty || $fieldName != null) { 
              mergedProperties[r'$rawName'] = $fieldName?.$encodingType(
                explode: false, 
                allowEmpty: allowEmpty,
              ) ?? ''; }''',
            ),
          );
        } else if (!property.isRequired) {
          statements.add(
            Code(
              '''
              if ($fieldName != null) { 
                mergedProperties[r'$rawName'] = $fieldName!.$encodingType(
                  explode: false, 
                  allowEmpty: allowEmpty,
                ); 
              }''',
            ),
          );
        } else {
          statements.add(
            Code(
              '''
              mergedProperties[r'$rawName'] = $fieldName.$encodingType(
                explode: false, 
                allowEmpty: allowEmpty,
              );
              ''',
            ),
          );
        }
      }
    }

    statements.add(const Code('return mergedProperties;'));

    return Method(
      (b) =>
          b
            ..name = methodName
            ..returns = buildMapStringStringType()
            ..optionalParameters.add(
              buildBoolParameter('allowEmpty', defaultValue: true),
            )
            ..body = Block.of(statements),
    );
  }

  /// Creates a Code object that correctly builds a property map entry
  /// expression with conditional logic for required/nullable properties.
  Code _buildPropertyMapEntryExpression(
    String fieldName,
    String rawName,
    Property property,
    String encodingType,
  ) {
    if (property.isRequired && property.isNullable) {
      return Code(
        'if (allowEmpty || $fieldName != null) '
        "r'$rawName': $fieldName?.$encodingType(explode: false, "
        "allowEmpty: allowEmpty) ?? '',",
      );
    } else if (!property.isRequired) {
      return Code(
        "if ($fieldName != null) r'$rawName': "
        '$fieldName!.$encodingType(explode: false, allowEmpty: allowEmpty),',
      );
    } else {
      return Code(
        "r'$rawName': $fieldName.$encodingType(explode: false, "
        'allowEmpty: allowEmpty),',
      );
    }
  }

  /// Shared method to build to methods (toSimple/toForm).
  Method _buildToMethod(
    String className,
    ClassModel model,
    List<({String normalizedName, Property property})> properties,
    String methodName,
    String propertiesMethodName,
  ) {
    // Check if we have any truly complex data (ClassModel, ListModel)
    // that can never be simple
    final hasTrulyComplexData = properties.any((prop) {
      final propertyModel = prop.property.model;
      return propertyModel is ClassModel || propertyModel is ListModel;
    });

    if (hasTrulyComplexData) {
      return Method(
        (b) =>
            b
              ..name = methodName
              ..returns = refer('String', 'dart:core')
              ..optionalParameters.addAll([
                ...buildEncodingParameters(),
              ])
              ..body = Block.of([
                generateEncodingExceptionExpression(
                  '$methodName not supported for $className: '
                  'contains nested data',
                ).statement,
              ]),
      );
    }

    if (properties.isEmpty) {
      return Method(
        (b) =>
            b
              ..name = methodName
              ..returns = refer('String', 'dart:core')
              ..optionalParameters.addAll([
                ...buildEncodingParameters(),
              ])
              ..lambda = methodName == 'toForm'
              ..body =
                  methodName == 'toForm'
                      ? literalString('').code
                      : Block.of([
                        literalString('').returned.statement,
                      ]),
      );
    }

    return Method(
      (b) =>
          b
            ..name = methodName
            ..returns = refer('String', 'dart:core')
            ..optionalParameters.addAll([
              buildBoolParameter('explode', required: true),
              Parameter(
                (b) =>
                    b
                      ..name = 'allowEmpty'
                      ..type = refer('bool', 'dart:core')
                      ..named = true
                      ..required = true,
              ),
            ])
            ..body = Block.of([
              refer(propertiesMethodName)
                  .call([], {'allowEmpty': refer('allowEmpty')})
                  .property(methodName)
                  .call(
                    [],
                    methodName == 'toForm'
                        ? {
                          'explode': refer('explode'),
                          'allowEmpty': refer('allowEmpty'),
                          'alreadyEncoded': literalBool(true),
                        }
                        : {
                          'explode': refer('explode'),
                          'allowEmpty': refer('allowEmpty'),
                        },
                  )
                  .returned
                  .statement,
            ]),
    );
  }

  Method _buildLabelPropertiesMethod(
    ClassModel model,
    List<({String normalizedName, Property property})> properties,
  ) {
    // Check if we have any truly complex data (ClassModel, ListModel)
    // that can never be simple
    final hasTrulyComplexData = properties.any((prop) {
      final propertyModel = prop.property.model;
      return propertyModel is ClassModel || propertyModel is ListModel;
    });

    if (hasTrulyComplexData) {
      return Method(
        (b) =>
            b
              ..name = 'labelProperties'
              ..returns = buildMapStringStringType()
              ..optionalParameters.add(
                Parameter(
                  (b) =>
                      b
                        ..name = 'allowEmpty'
                        ..type = refer('bool', 'dart:core')
                        ..named = true
                        ..defaultTo = literalBool(true).code,
                ),
              )
              ..body =
                  generateEncodingExceptionExpression(
                    'labelProperties not supported for ${model.name}: '
                    'contains nested data',
                  ).statement,
      );
    }

    // Check if we have any composite models that need runtime checking
    final hasCompositeModels = properties.any((prop) {
      final propertyModel = prop.property.model;
      return propertyModel is CompositeModel;
    });

    if (hasCompositeModels) {
      return _buildLabelPropertiesMethodWithRuntimeChecks(
        model,
        properties,
      );
    }

    // Optimized path for simple properties only
    final mapEntries = <Code>[];

    for (final prop in properties) {
      final property = prop.property;
      final fieldName = prop.normalizedName;
      final rawName = property.name;

      mapEntries.add(
        _buildPropertyMapEntryExpression(
          fieldName,
          rawName,
          property,
          'toLabel',
        ),
      );
    }

    final returnStatement =
        properties.isEmpty
            ? buildEmptyMapStringString().code
            : Block.of([
              const Code('return {'),
              ...mapEntries,
              const Code('};'),
            ]);

    return Method(
      (b) =>
          b
            ..name = 'labelProperties'
            ..returns = buildMapStringStringType()
            ..optionalParameters.add(
              buildBoolParameter('allowEmpty', defaultValue: true),
            )
            ..lambda = properties.isEmpty
            ..body = returnStatement,
    );
  }

  /// Builds a labelProperties method with runtime checks for composite models.
  Method _buildLabelPropertiesMethodWithRuntimeChecks(
    ClassModel model,
    List<({String normalizedName, Property property})> properties,
  ) {
    final statements = <Code>[
      const Code('final mergedProperties = '),
      buildEmptyMapStringString().statement,
    ];

    for (final prop in properties) {
      final property = prop.property;
      final fieldName = prop.normalizedName;
      final rawName = property.name;
      final propertyModel = property.model;

      if (propertyModel is CompositeModel) {
        // Runtime check for composite models
        if (property.isRequired && !property.isNullable) {
          // Required non-nullable composite property
          statements.addAll([
            Code('if ($fieldName.currentEncodingShape != '),
            refer(
              'EncodingShape.simple',
              'package:tonik_util/tonik_util.dart',
            ).code,
            const Code(') {'),
            generateEncodingExceptionExpression(
              'labelProperties not supported for Container: '
              'contains complex types',
            ).statement,
            const Code('}'),
            Code('''
              mergedProperties['$rawName'] = $fieldName.toLabel(
                explode: false, 
                allowEmpty: allowEmpty
              );
            '''),
          ]);
        } else if (property.isRequired && property.isNullable) {
          // Required nullable composite property
          statements.addAll([
            Code('if (allowEmpty || $fieldName != null) {'),
            Code(
              'if ($fieldName != null && $fieldName!.currentEncodingShape != ',
            ),
            refer(
              'EncodingShape.simple',
              'package:tonik_util/tonik_util.dart',
            ).code,
            const Code(') {'),
            generateEncodingExceptionExpression(
              'labelProperties not supported for Container: '
              'contains complex types',
            ).statement,
            const Code('}'),
            Code('if ($fieldName != null) {'),
            Code('''
              mergedProperties['$rawName'] = $fieldName!.toLabel(explode: false, allowEmpty: allowEmpty) ?? '';
            '''),
            const Code('}'),
            const Code('}'),
          ]);
        } else {
          // Optional composite property
          statements.addAll([
            Code('if (allowEmpty || $fieldName != null) {'),
            Code(
              'if ($fieldName != null && $fieldName!.currentEncodingShape != ',
            ),
            refer(
              'EncodingShape.simple',
              'package:tonik_util/tonik_util.dart',
            ).code,
            const Code(') {'),
            generateEncodingExceptionExpression(
              'labelProperties not supported for Container: '
              'contains complex types',
            ).statement,
            const Code('}'),
            Code('if ($fieldName != null) {'),
            Code(
              "  mergedProperties['$rawName'] = "
              '$fieldName!.toLabel(explode: false, allowEmpty: allowEmpty);',
            ),
            const Code('}'),
            const Code('}'),
          ]);
        }
      } else {
        // Simple property - use the standard pattern
        if (property.isRequired && property.isNullable) {
          statements.add(
            Code('''
              if (allowEmpty || $fieldName != null) {
                mergedProperties['$rawName'] = $fieldName?.toLabel(
                  explode: false, 
                  allowEmpty: allowEmpty
                ) ?? '';
              }
            '''),
          );
        } else if (!property.isRequired) {
          statements.add(
            Code('''
              if ($fieldName != null) {
                mergedProperties['$rawName'] = $fieldName!.toLabel(
                  explode: false, 
                  allowEmpty: allowEmpty
                );
              }
            '''),
          );
        } else {
          statements.add(
            Code('''
              mergedProperties['$rawName'] = $fieldName.toLabel(
                explode: false, 
                allowEmpty: allowEmpty
              );
            '''),
          );
        }
      }
    }

    statements.add(const Code('return mergedProperties;'));

    return Method(
      (b) =>
          b
            ..name = 'labelProperties'
            ..returns = buildMapStringStringType()
            ..optionalParameters.add(
              buildBoolParameter('allowEmpty', defaultValue: true),
            )
            ..body = Block.of(statements),
    );
  }

  /// Builds a toLabel method for label encoding.
  ///
  /// This method delegates to labelProperties and then calls toLabel on the
  /// result.
  Method _buildToLabelMethod(
    String className,
    ClassModel model,
    List<({String normalizedName, Property property})> properties,
  ) {
    return Method(
      (b) =>
          b
            ..name = 'toLabel'
            ..returns = refer('String', 'dart:core')
            ..optionalParameters.addAll(buildEncodingParameters())
            ..body = Block.of([
              const Code('return labelProperties(allowEmpty: allowEmpty)'),
              const Code(
                '\n  .toLabel(explode: explode, allowEmpty: allowEmpty, '
                'alreadyEncoded: true);',
              ),
            ]),
    );
  }
}
