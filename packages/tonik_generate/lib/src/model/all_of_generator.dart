import 'package:change_case/change_case.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:meta/meta.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/naming/name_utils.dart';
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

/// A generator for creating Dart classes from allOf model definitions.
@immutable
class AllOfGenerator {
  const AllOfGenerator({required this.nameManager, required this.package});

  final NameManager nameManager;
  final String package;

  ({String code, String filename}) generate(AllOfModel model) {
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
  Class generateClass(AllOfModel model) {
    final className = nameManager.modelName(model);
    final models = model.models.toList();

    final pseudoProperties =
        models.map((m) {
          final typeRef = typeReference(m, nameManager, package);
          return Property(
            name: typeRef.symbol,
            model: m,
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          );
        }).toList();

    final normalizedProperties = _normalizeModelProperties(pseudoProperties);
    final properties = _buildPropertiesFromNormalized(normalizedProperties);

    return Class(
      (b) =>
          b
            ..name = className
            ..annotations.add(refer('immutable', 'package:meta/meta.dart'))
            ..constructors.add(_buildDefaultConstructor(normalizedProperties))
            ..constructors.addAll([
              _buildFromSimpleConstructor(
                className,
                normalizedProperties,
                model,
              ),
              _buildFromFormConstructor(
                className,
                normalizedProperties,
                model,
              ),
              _buildFromJsonConstructor(className, normalizedProperties),
            ])
            ..methods.addAll([
              _buildCurrentEncodingShapeGetter(model, normalizedProperties),
              _buildToJsonMethod(className, model, normalizedProperties),
              _buildParameterPropertiesMethod(
                className,
                normalizedProperties,
                model,
              ),
              _buildToSimpleMethod(
                normalizedProperties,
                model,
              ),
              _buildToFormMethod(
                className,
                normalizedProperties,
                model,
              ),
              _buildToLabelMethod(
                className,
                normalizedProperties,
                model,
              ),
              generateEqualsMethod(
                className: className,
                properties: properties,
              ),
              generateHashCodeMethod(properties: properties),
              _buildCopyWithMethod(className, normalizedProperties),
            ])
            ..fields.addAll(_buildFields(normalizedProperties)),
    );
  }

  List<({String normalizedName, Property property})> _normalizeModelProperties(
    List<Property> properties,
  ) {
    final normalized =
        properties
            .map(
              (prop) => (
                normalizedName: normalizeSingle(
                  prop.name,
                  preserveNumbers: true,
                ),
                originalValue: prop,
              ),
            )
            .toList();

    final unique = ensureUniqueness(normalized);

    return unique
        .map(
          (item) => (
            normalizedName: item.normalizedName,
            property: item.originalValue,
          ),
        )
        .toList();
  }

  List<Field> _buildFields(
    List<({String normalizedName, Property property})> normalizedProperties,
  ) {
    return normalizedProperties.map((normalized) {
      final typeRef = typeReference(
        normalized.property.model,
        nameManager,
        package,
      );
      return Field(
        (b) =>
            b
              ..name = normalized.normalizedName
              ..modifier = FieldModifier.final$
              ..type = typeRef,
      );
    }).toList();
  }

  List<({String normalizedName, bool hasCollectionValue})>
  _buildPropertiesFromNormalized(
    List<({String normalizedName, Property property})> normalizedProperties,
  ) {
    return normalizedProperties.map((normalized) {
      return (
        normalizedName: normalized.normalizedName,
        hasCollectionValue: normalized.property.model is ListModel,
      );
    }).toList();
  }

  Constructor _buildDefaultConstructor(
    List<({String normalizedName, Property property})> normalizedProperties,
  ) {
    return Constructor(
      (b) =>
          b
            ..constant = true
            ..optionalParameters.addAll(
              normalizedProperties.map((normalized) {
                return Parameter(
                  (b) =>
                      b
                        ..name = normalized.normalizedName
                        ..named = true
                        ..required = true
                        ..toThis = true,
                );
              }),
            ),
    );
  }

  Constructor _buildFromJsonConstructor(
    String className,
    List<({String normalizedName, Property property})> normalizedProperties,
  ) {
    final fromJsonParams = <Expression>[];
    final fieldNames = <String>[];
    for (final normalized in normalizedProperties) {
      fieldNames.add(normalized.normalizedName);
      fromJsonParams.add(
        buildFromJsonValueExpression(
          'json',
          model: normalized.property.model,
          nameManager: nameManager,
          package: package,
          contextClass: className,
        ),
      );
    }

    return Constructor(
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
            ..body =
                refer(className)
                    .call(
                      [],
                      Map.fromEntries(
                        List.generate(
                          fromJsonParams.length,
                          (i) => MapEntry(fieldNames[i], fromJsonParams[i]),
                        ),
                      ),
                    )
                    .returned
                    .statement,
    );
  }

  Method _buildCurrentEncodingShapeGetter(
    AllOfModel model,
    List<({String normalizedName, Property property})> normalizedProperties,
  ) {
    final encodingShapeType = refer(
      'EncodingShape',
      'package:tonik_util/tonik_util.dart',
    );

    // Check if any of the models have dynamic encoding shapes
    final hasDynamicModels = normalizedProperties.any((prop) {
      return prop.property.model.encodingShape == EncodingShape.mixed;
    });

    if (hasDynamicModels) {
      final bodyCode = <Code>[
        const Code('final shapes = <'),
        encodingShapeType.code,
        const Code('>{};'),
      ];

      for (final prop in normalizedProperties) {
        bodyCode.add(
          Code('shapes.add(${prop.normalizedName}.currentEncodingShape);'),
        );
      }

      bodyCode.addAll([
        const Code('if (shapes.length > 1) return '),
        encodingShapeType.property('mixed').statement,
        const Code('return shapes.first;'),
      ]);

      return Method(
        (b) =>
            b
              ..name = 'currentEncodingShape'
              ..type = MethodType.getter
              ..returns = encodingShapeType
              ..lambda = false
              ..body = Block.of(bodyCode),
      );
    }

    // For models without dynamic shapes, use the hardcoded approach
    final shapeRef = switch (model.encodingShape) {
      EncodingShape.simple => encodingShapeType.property('simple'),
      EncodingShape.complex => encodingShapeType.property('complex'),
      EncodingShape.mixed => encodingShapeType.property('mixed'),
    };

    return Method(
      (b) =>
          b
            ..name = 'currentEncodingShape'
            ..type = MethodType.getter
            ..returns = encodingShapeType
            ..lambda = true
            ..body = shapeRef.code,
    );
  }

  Method _buildToJsonMethod(
    String className,
    AllOfModel model,
    List<({String normalizedName, Property property})> normalizedProperties,
  ) {
    // Check if any of the models have dynamic encoding shapes
    final hasDynamicModels = normalizedProperties.any((prop) {
      return prop.property.model.encodingShape == EncodingShape.mixed;
    });

    if (hasDynamicModels) {
      // Generate dynamic logic that checks encoding shape at runtime
      final encodingShapeType = refer(
        'EncodingShape',
        'package:tonik_util/tonik_util.dart',
      );

      final bodyCode = <Code>[
        const Code('if (currentEncodingShape == '),
        encodingShapeType.property('mixed').code,
        const Code(') {'),
        generateEncodingExceptionExpression(
          'Cannot encode $className: mixing simple values (primitives/enums) and complex types is not supported',
        ).statement,
        const Code('}'),
        const Code('final map = '),
        literalMap(
          {},
          refer('String', 'dart:core'),
          refer('Object?', 'dart:core'),
        ).statement,
      ];

      final mapType = buildMapStringObjectType();
      for (final normalized in normalizedProperties) {
        final fieldName = normalized.normalizedName;
        final fieldNameJson = '${fieldName}Json';

        bodyCode.addAll([
          Code('final $fieldNameJson = '),
          refer(fieldName).code,
          const Code('.toJson();'),
          const Code('if ('),
          refer(fieldNameJson).code,
          const Code(' is! '),
          mapType.code,
          const Code(') {'),
          generateEncodingExceptionExpression(
            'Expected $fieldName.toJson() to return Map<String, Object?>, '
            'got \${$fieldNameJson.runtimeType}',
          ).statement,
          const Code('}'),
          const Code('map.addAll('),
          refer(fieldNameJson).code,
          const Code(');'),
        ]);
      }

      bodyCode.add(const Code('return map;'));

      return Method(
        (b) =>
            b
              ..returns = refer('Object?', 'dart:core')
              ..name = 'toJson'
              ..lambda = false
              ..body = Block.of(bodyCode),
      );
    }

    switch (model.encodingShape) {
      case EncodingShape.mixed:
        return Method(
          (b) =>
              b
                ..returns = refer('Object?', 'dart:core')
                ..name = 'toJson'
                ..lambda = true
                ..body =
                    generateEncodingExceptionExpression(
                      'Cannot encode $className: mixing simple values (primitives/enums) and complex types is not supported',
                    ).code,
        );

      case EncodingShape.simple:
        final firstModel = model.models.first;
        final firstFieldName = normalizedProperties.first.normalizedName;

        return Method(
          (b) =>
              b
                ..returns = refer('Object?', 'dart:core')
                ..name = 'toJson'
                ..lambda = true
                ..body = Code(
                  buildToJsonPropertyExpression(
                    firstFieldName,
                    Property(
                      name: firstFieldName,
                      model: firstModel,
                      isRequired: true,
                      isNullable: false,
                      isDeprecated: false,
                    ),
                  ),
                ),
        );

      case EncodingShape.complex:
        final mapType = buildMapStringObjectType();
        final mapParts = <Code>[
          const Code('final map = '),
          literalMap(
            {},
            refer('String', 'dart:core'),
            refer('Object?', 'dart:core'),
          ).statement,
        ];

        for (final normalized in normalizedProperties) {
          final fieldName = normalized.normalizedName;
          final fieldNameJson = '${fieldName}Json';

          mapParts.addAll([
            Code('final $fieldNameJson = '),
            refer(fieldName).code,
            const Code('.toJson();'),
            const Code('if ('),
            refer(fieldNameJson).code,
            const Code(' is! '),
            mapType.code,
            const Code(') {'),
            generateEncodingExceptionExpression(
              'Expected $fieldName.toJson() to return Map<String, Object?>, '
              'got \${$fieldNameJson.runtimeType}',
            ).statement,
            const Code('}'),
            const Code('map.addAll('),
            refer(fieldNameJson).code,
            const Code(');'),
          ]);
        }

        mapParts.add(const Code('return map;'));

        return Method(
          (b) =>
              b
                ..returns = refer('Object?', 'dart:core')
                ..name = 'toJson'
                ..lambda = false
                ..body = Block.of(mapParts),
        );
    }
  }

  Constructor _buildFromSimpleConstructor(
    String className,
    List<({String normalizedName, Property property})> normalizedProperties,
    AllOfModel model,
  ) {
    if (normalizedProperties.isEmpty) {
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
              ..body = Code('return $className();'),
      );
    }

    // If the model cannot be simply encoded, throw an exception
    if (model.cannotBeSimplyEncoded) {
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
              ..body =
                  generateSimpleDecodingExceptionExpression(
                    'Simple encoding not supported for $className: '
                    'contains complex types',
                  ).statement,
      );
    }

    // If all types are complex, each model should decode from the same single
    // value
    if (model.hasComplexTypes) {
      final propertyAssignments = <MapEntry<String, Expression>>[];

      for (final normalized in normalizedProperties) {
        final name = normalized.normalizedName;
        final modelType = normalized.property.model;

        // Each model attempts to decode from the single value
        final expression = switch (modelType) {
          EnumModel() => typeReference(modelType, nameManager, package)
              .property('fromSimple')
              .call([refer('value')], {'explode': refer('explode')}),
          _ =>
            modelType.encodingShape == EncodingShape.simple
                ? buildSimpleValueExpression(
                  refer('value'),
                  model: modelType,
                  isRequired: !normalized.property.isNullable,
                  nameManager: nameManager,
                  package: package,
                  contextClass: className,
                  contextProperty: name,
                  explode: refer('explode'),
                )
                : typeReference(modelType, nameManager, package)
                    .property('fromSimple')
                    .call([refer('value')], {'explode': refer('explode')}),
        };

        propertyAssignments.add(MapEntry(name, expression));
      }

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
              ..body =
                  refer(className, package)
                      .call([], {
                        for (final entry in propertyAssignments)
                          entry.key: entry.value,
                      })
                      .returned
                      .statement,
      );
    }

    // For primitive-only AllOf models, decode from single value to all models
    final propertyAssignments = <MapEntry<String, Expression>>[];

    for (final normalized in normalizedProperties) {
      final name = normalized.normalizedName;
      final modelType = normalized.property.model;
      final isNullable = normalized.property.isNullable;

      propertyAssignments.add(
        MapEntry(
          name,
          buildSimpleValueExpression(
            refer('value'),
            model: modelType,
            isRequired: !isNullable,
            nameManager: nameManager,
            package: package,
            contextClass: className,
            contextProperty: name,
            explode: refer('explode'),
          ),
        ),
      );
    }

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
            ..body =
                refer(className, package)
                    .call([], {
                      for (final entry in propertyAssignments)
                        entry.key: entry.value,
                    })
                    .returned
                    .statement,
    );
  }

  Method _buildParameterPropertiesMethod(
    String className,
    List<({String normalizedName, Property property})> normalizedProperties,
    AllOfModel model,
  ) {
    if (normalizedProperties.isEmpty) {
      return Method(
        (b) =>
            b
              ..name = 'parameterProperties'
              ..returns = buildMapStringStringType()
              ..optionalParameters.add(
                Parameter(
                  (b) =>
                      b
                        ..name = 'allowEmpty'
                        ..type = refer('bool', 'dart:core')
                        ..named = true
                        ..required = false
                        ..defaultTo = literalTrue.code,
                ),
              )
              ..body = buildEmptyMapStringString().returned.statement,
      );
    }

    if (model.hasSimpleTypes) {
      return Method(
        (b) =>
            b
              ..name = 'parameterProperties'
              ..returns = buildMapStringStringType()
              ..optionalParameters.add(
                Parameter(
                  (b) =>
                      b
                        ..name = 'allowEmpty'
                        ..type = refer('bool', 'dart:core')
                        ..named = true
                        ..required = false
                        ..defaultTo = literalTrue.code,
                ),
              )
              ..body =
                  generateEncodingExceptionExpression(
                    'parameterProperties not supported for $className: contains primitive types',
                  ).statement,
      );
    }

    final propertyMergingLines = [
      declareFinal(
        'mergedProperties',
      ).assign(buildEmptyMapStringString()).statement,
    ];

    for (final normalized in normalizedProperties) {
      propertyMergingLines.add(
        refer('mergedProperties').property('addAll').call([
          refer(normalized.normalizedName).property('parameterProperties').call(
            [],
            {'allowEmpty': refer('allowEmpty')},
          ),
        ]).statement,
      );
    }

    propertyMergingLines.add(
      refer('mergedProperties').returned.statement,
    );

    return Method(
      (b) =>
          b
            ..name = 'parameterProperties'
            ..returns = buildMapStringStringType()
            ..optionalParameters.add(
              Parameter(
                (b) =>
                    b
                      ..name = 'allowEmpty'
                      ..type = refer('bool', 'dart:core')
                      ..named = true
                      ..required = false
                      ..defaultTo = literalTrue.code,
              ),
            )
            ..body = Block.of(propertyMergingLines),
    );
  }

  Method _buildToSimpleMethod(
    List<({String normalizedName, Property property})> normalizedProperties,
    AllOfModel model,
  ) {
    // Check if any of the models have dynamic encoding shapes
    final hasDynamicModels = normalizedProperties.any((prop) {
      return prop.property.model.encodingShape == EncodingShape.mixed;
    });

    if (hasDynamicModels) {
      // Generate dynamic logic that checks encoding shape at runtime
      final encodingShapeType = refer(
        'EncodingShape',
        'package:tonik_util/tonik_util.dart',
      );

      final bodyCode = <Code>[
        const Code('if (currentEncodingShape == '),
        encodingShapeType.property('mixed').code,
        const Code(') {'),
        generateEncodingExceptionExpression(
          'Simple encoding not supported: contains complex types',
        ).statement,
        const Code('}'),
        const Code('return parameterProperties('),
        const Code('allowEmpty: allowEmpty,'),
        const Code(
          ').toSimple('
          'explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true);',
        ),
      ];

      return Method(
        (b) =>
            b
              ..name = 'toSimple'
              ..returns = refer('String', 'dart:core')
              ..optionalParameters.addAll(buildEncodingParameters())
              ..lambda = false
              ..body = Block.of(bodyCode),
      );
    }

    final dynamicModels =
        normalizedProperties.where((prop) {
          final shape = prop.property.model.encodingShape;
          return shape == EncodingShape.mixed;
        }).toList();

    final hasDynamicModelsOld = dynamicModels.isNotEmpty;
    final needsRuntimeValidation = hasDynamicModelsOld && model.hasSimpleTypes;

    if (needsRuntimeValidation) {
      final encodingShapeType = refer(
        'EncodingShape',
        'package:tonik_util/tonik_util.dart',
      );
      final validationCode = <Code>[];

      for (final prop in dynamicModels) {
        validationCode.addAll([
          Code('if (${prop.normalizedName}.currentEncodingShape != '),
          encodingShapeType.property('simple').code,
          const Code(') {'),
          refer('EncodingException', 'package:tonik_util/tonik_util.dart')
              .call([
                literalString(
                  'Cannot encode mixed allOf ${model.name}: '
                  '${prop.normalizedName} is complex',
                ),
              ])
              .thrown
              .statement,
          const Code('}'),
        ]);
      }

      validationCode.addAll([
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
      ]);

      return Method(
        (b) =>
            b
              ..name = 'toSimple'
              ..returns = refer('String', 'dart:core')
              ..optionalParameters.addAll(buildEncodingParameters())
              ..lambda = false
              ..body = Block.of(validationCode),
      );
    }

    if (model.cannotBeSimplyEncoded) {
      return Method(
        (b) =>
            b
              ..name = 'toSimple'
              ..returns = refer('String', 'dart:core')
              ..optionalParameters.addAll(buildEncodingParameters())
              ..lambda = false
              ..body =
                  generateEncodingExceptionExpression(
                    'Simple encoding not supported: contains complex types',
                  ).statement,
      );
    }

    if (model.hasComplexTypes) {
      return Method(
        (b) =>
            b
              ..name = 'toSimple'
              ..returns = refer('String', 'dart:core')
              ..optionalParameters.addAll(buildEncodingParameters())
              ..lambda = false
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
    }

    if (normalizedProperties.isEmpty) {
      return Method(
        (b) =>
            b
              ..name = 'toSimple'
              ..returns = refer('String', 'dart:core')
              ..optionalParameters.addAll(buildEncodingParameters())
              ..lambda = false
              ..body = const Code("return '';"),
      );
    }

    final primaryField = normalizedProperties.first;

    return Method(
      (b) =>
          b
            ..name = 'toSimple'
            ..returns = refer('String', 'dart:core')
            ..optionalParameters.addAll(buildEncodingParameters())
            ..lambda = false
            ..body = Block.of([
              refer(primaryField.normalizedName)
                  .property('toSimple')
                  .call([], {
                    'explode': refer('explode'),
                    'allowEmpty': refer('allowEmpty'),
                  })
                  .returned
                  .statement,
            ]),
    );
  }

  Constructor _buildFromFormConstructor(
    String className,
    List<({String normalizedName, Property property})> normalizedProperties,
    AllOfModel model,
  ) {
    if (normalizedProperties.isEmpty) {
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
              ..body = Code('return $className();'),
      );
    }

    if (model.cannotBeSimplyEncoded) {
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
              ..body =
                  generateSimpleDecodingExceptionExpression(
                    'Simple encoding not supported for $className: '
                    'contains complex types',
                  ).statement,
      );
    }

    if (model.hasComplexTypes) {
      final propertyAssignments = <MapEntry<String, Expression>>[];

      for (final normalized in normalizedProperties) {
        final name = normalized.normalizedName;
        final modelType = normalized.property.model;

        final expression = switch (modelType) {
          EnumModel() => typeReference(modelType, nameManager, package)
              .property('fromForm')
              .call([refer('value')], {'explode': refer('explode')}),
          _ =>
            modelType.encodingShape == EncodingShape.simple
                ? buildFromFormValueExpression(
                  refer('value'),
                  model: modelType,
                  isRequired: !normalized.property.isNullable,
                  nameManager: nameManager,
                  package: package,
                  contextClass: className,
                  contextProperty: name,
                  explode: refer('explode'),
                )
                : typeReference(modelType, nameManager, package)
                    .property('fromForm')
                    .call([refer('value')], {'explode': refer('explode')}),
        };

        propertyAssignments.add(MapEntry(name, expression));
      }

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
              ..body =
                  refer(className, package)
                      .call([], {
                        for (final entry in propertyAssignments)
                          entry.key: entry.value,
                      })
                      .returned
                      .statement,
      );
    }

    final propertyAssignments = <MapEntry<String, Expression>>[];

    for (final normalized in normalizedProperties) {
      final name = normalized.normalizedName;
      final modelType = normalized.property.model;
      final isNullable = normalized.property.isNullable;

      propertyAssignments.add(
        MapEntry(
          name,
          buildFromFormValueExpression(
            refer('value'),
            model: modelType,
            isRequired: !isNullable,
            nameManager: nameManager,
            package: package,
            contextClass: className,
            contextProperty: name,
            explode: refer('explode'),
          ),
        ),
      );
    }

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
            ..body =
                refer(className, package)
                    .call([], {
                      for (final entry in propertyAssignments)
                        entry.key: entry.value,
                    })
                    .returned
                    .statement,
    );
  }

  Method _buildToFormMethod(
    String className,
    List<({String normalizedName, Property property})> normalizedProperties,
    AllOfModel model,
  ) {
    // Check if any of the models have dynamic encoding shapes
    final hasDynamicModels = normalizedProperties.any((prop) {
      return prop.property.model.encodingShape == EncodingShape.mixed;
    });

    if (hasDynamicModels) {
      // Generate dynamic logic that checks encoding shape at runtime
      final encodingShapeType = refer(
        'EncodingShape',
        'package:tonik_util/tonik_util.dart',
      );

      final bodyCode = <Code>[
        const Code('if (currentEncodingShape == '),
        encodingShapeType.property('mixed').code,
        const Code(') {'),
        generateEncodingExceptionExpression(
          'Cannot encode $className: mixing simple values (primitives/enums) and complex types is not supported',
        ).statement,
        const Code('}'),
        const Code('final map = <'),
        refer('String', 'dart:core').code,
        const Code(', '),
        refer('String', 'dart:core').code,
        const Code('>{};'),
      ];

      for (final prop in normalizedProperties) {
        bodyCode.add(
          Code(
            'map.addAll(${prop.normalizedName} '
            '.parameterProperties(allowEmpty: allowEmpty));',
          ),
        );
      }

      bodyCode.addAll([
        const Code(
          'return map.toForm( '
          'explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true);',
        ),
      ]);

      return Method(
        (b) =>
            b
              ..name = 'toForm'
              ..returns = refer('String', 'dart:core')
              ..optionalParameters.addAll(buildEncodingParameters())
              ..lambda = false
              ..body = Block.of(bodyCode),
      );
    }

    final dynamicModels =
        normalizedProperties.where((prop) {
          final shape = prop.property.model.encodingShape;
          return shape == EncodingShape.mixed;
        }).toList();

    final hasDynamicModelsOld = dynamicModels.isNotEmpty;
    final needsRuntimeValidation = hasDynamicModelsOld && model.hasSimpleTypes;

    if (needsRuntimeValidation) {
      final encodingShapeType = refer(
        'EncodingShape',
        'package:tonik_util/tonik_util.dart',
      );
      final validationCode = <Code>[];

      for (final prop in dynamicModels) {
        validationCode.addAll([
          Code('if (${prop.normalizedName}.currentEncodingShape != '),
          encodingShapeType.property('simple').code,
          const Code(') {'),
          refer('EncodingException', 'package:tonik_util/tonik_util.dart')
              .call([
                literalString(
                  'Cannot encode mixed allOf ${model.name}: '
                  '${prop.normalizedName} is complex',
                ),
              ])
              .thrown
              .statement,
          const Code('}'),
        ]);
      }

      final primaryField = normalizedProperties.first;
      validationCode.addAll([
        refer(primaryField.normalizedName)
            .property('toForm')
            .call([], {
              'explode': refer('explode'),
              'allowEmpty': refer('allowEmpty'),
            })
            .returned
            .statement,
      ]);

      return Method(
        (b) =>
            b
              ..name = 'toForm'
              ..returns = refer('String', 'dart:core')
              ..optionalParameters.addAll(buildEncodingParameters())
              ..lambda = false
              ..body = Block.of(validationCode),
      );
    }

    if (model.hasComplexTypes) {
      final encodingShapeType = refer(
        'EncodingShape',
        'package:tonik_util/tonik_util.dart',
      );

      // Find all dynamic types (anyOf/oneOf) that need runtime validation.
      final allDynamicModels =
          normalizedProperties.where((prop) {
            return prop.property.model.encodingShape == EncodingShape.mixed;
          }).toList();

      // If there are NO dynamic models AND we still have simple+complex mix,
      // it means we have a truly mixed allOf (primitive + class) which cannot
      // be encoded.
      if (allDynamicModels.isEmpty && model.hasSimpleTypes) {
        return Method(
          (b) =>
              b
                ..name = 'toForm'
                ..returns = refer('String', 'dart:core')
                ..optionalParameters.addAll(buildEncodingParameters())
                ..lambda = false
                ..body =
                    generateEncodingExceptionExpression(
                      'Simple encoding not supported: contains complex types',
                    ).statement,
        );
      }

      if (allDynamicModels.isEmpty) {
        return Method(
          (b) =>
              b
                ..name = 'toForm'
                ..returns = refer('String', 'dart:core')
                ..optionalParameters.addAll(buildEncodingParameters())
                ..lambda = false
                ..body =
                    refer('parameterProperties')
                        .call([], {'allowEmpty': refer('allowEmpty')})
                        .property('toForm')
                        .call([], {
                          'explode': refer('explode'),
                          'allowEmpty': refer('allowEmpty'),
                          'alreadyEncoded': literalBool(true),
                        })
                        .returned
                        .statement,
        );
      }

      // If we have dynamic models, we need to validate and manually merge.
      final bodyCode = <Code>[];

      // Validate that all dynamic models (anyOf/oneOf) are in complex state.
      for (final prop in allDynamicModels) {
        bodyCode.addAll([
          Code('if (${prop.normalizedName}.currentEncodingShape != '),
          encodingShapeType.property('complex').code,
          const Code(') {'),
          refer('EncodingException', 'package:tonik_util/tonik_util.dart')
              .call([
                literalString(
                  'Cannot encode mixed allOf ${model.name}: '
                  '${prop.normalizedName} is not complex',
                ),
              ])
              .thrown
              .statement,
          const Code('}'),
        ]);
      }

      // Manually merge all parameterProperties.
      bodyCode.addAll([
        const Code('final map = <'),
        refer('String', 'dart:core').code,
        const Code(', '),
        refer('String', 'dart:core').code,
        const Code('>{};'),
      ]);

      for (final prop in normalizedProperties) {
        bodyCode.add(
          Code(
            'map.addAll(${prop.normalizedName} '
            '.parameterProperties(allowEmpty: allowEmpty));',
          ),
        );
      }

      bodyCode.addAll([
        const Code(
          'return map.toForm( '
          'explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true);',
        ),
      ]);

      return Method(
        (b) =>
            b
              ..name = 'toForm'
              ..returns = refer('String', 'dart:core')
              ..optionalParameters.addAll(buildEncodingParameters())
              ..lambda = false
              ..body = Block.of(bodyCode),
      );
    }

    if (normalizedProperties.isEmpty) {
      return Method(
        (b) =>
            b
              ..name = 'toForm'
              ..returns = refer('String', 'dart:core')
              ..optionalParameters.addAll(buildEncodingParameters())
              ..lambda = false
              ..body = const Code("return '';"),
      );
    }

    final primaryField = normalizedProperties.first;

    return Method(
      (b) =>
          b
            ..name = 'toForm'
            ..returns = refer('String', 'dart:core')
            ..optionalParameters.addAll(buildEncodingParameters())
            ..lambda = false
            ..body = Block.of([
              refer(primaryField.normalizedName)
                  .property('toForm')
                  .call([], {
                    'explode': refer('explode'),
                    'allowEmpty': refer('allowEmpty'),
                  })
                  .returned
                  .statement,
            ]),
    );
  }

  Method _buildToLabelMethod(
    String className,
    List<({String normalizedName, Property property})> normalizedProperties,
    AllOfModel model,
  ) {
    // Check if the parent model has mixed encoding shape
    final hasDynamicModels = normalizedProperties.any((prop) {
      return prop.property.model.encodingShape == EncodingShape.mixed;
    });

    if (hasDynamicModels) {
      final encodingShapeType = refer(
        'EncodingShape',
        'package:tonik_util/tonik_util.dart',
      );

      final bodyCode = <Code>[
        const Code('if (currentEncodingShape == '),
        encodingShapeType.property('mixed').code,
        const Code(') {'),
        generateEncodingExceptionExpression(
          'Simple encoding not supported: contains complex types',
        ).statement,
        const Code('}'),
        const Code('return parameterProperties('),
        const Code('allowEmpty: allowEmpty,'),
        const Code(
          ').toLabel('
          'explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true);',
        ),
      ];

      return Method(
        (b) =>
            b
              ..name = 'toLabel'
              ..returns = refer('String', 'dart:core')
              ..optionalParameters.addAll(buildEncodingParameters())
              ..lambda = false
              ..body = Block.of(bodyCode),
      );
    }

    final dynamicModels =
        normalizedProperties.where((prop) {
          final shape = prop.property.model.encodingShape;
          return shape == EncodingShape.mixed;
        }).toList();

    final hasDynamicModelsOld = dynamicModels.isNotEmpty;
    final needsRuntimeValidation = hasDynamicModelsOld && model.hasSimpleTypes;

    if (needsRuntimeValidation) {
      final encodingShapeType = refer(
        'EncodingShape',
        'package:tonik_util/tonik_util.dart',
      );
      final validationCode = <Code>[];

      for (final prop in dynamicModels) {
        validationCode.addAll([
          Code('if (${prop.normalizedName}.currentEncodingShape != '),
          encodingShapeType.property('simple').code,
          const Code(') {'),
          refer('EncodingException', 'package:tonik_util/tonik_util.dart')
              .call([
                literalString(
                  'Cannot encode mixed allOf ${model.name}: '
                  '${prop.normalizedName} is complex',
                ),
              ])
              .thrown
              .statement,
          const Code('}'),
        ]);
      }

      final primaryField = normalizedProperties.first;
      validationCode.addAll([
        refer(primaryField.normalizedName)
            .property('toLabel')
            .call([], {
              'explode': refer('explode'),
              'allowEmpty': refer('allowEmpty'),
            })
            .returned
            .statement,
      ]);

      return Method(
        (b) =>
            b
              ..name = 'toLabel'
              ..returns = refer('String', 'dart:core')
              ..optionalParameters.addAll(buildEncodingParameters())
              ..lambda = false
              ..body = Block.of(validationCode),
      );
    }

    if (model.cannotBeSimplyEncoded) {
      return Method(
        (b) =>
            b
              ..name = 'toLabel'
              ..returns = refer('String', 'dart:core')
              ..optionalParameters.addAll(buildEncodingParameters())
              ..lambda = false
              ..body =
                  generateEncodingExceptionExpression(
                    'Simple encoding not supported: contains complex types',
                  ).statement,
      );
    }

    if (model.hasComplexTypes) {
      return Method(
        (b) =>
            b
              ..name = 'toLabel'
              ..returns = refer('String', 'dart:core')
              ..optionalParameters.addAll(buildEncodingParameters())
              ..lambda = false
              ..body =
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
      );
    }

    if (normalizedProperties.isEmpty) {
      return Method(
        (b) =>
            b
              ..name = 'toLabel'
              ..returns = refer('String', 'dart:core')
              ..optionalParameters.addAll(buildEncodingParameters())
              ..lambda = false
              ..body = const Code("return '';"),
      );
    }

    final primaryField = normalizedProperties.first;

    return Method(
      (b) =>
          b
            ..name = 'toLabel'
            ..returns = refer('String', 'dart:core')
            ..optionalParameters.addAll(buildEncodingParameters())
            ..lambda = false
            ..body =
                refer(primaryField.normalizedName)
                    .property('toLabel')
                    .call([], {
                      'explode': refer('explode'),
                      'allowEmpty': refer('allowEmpty'),
                    })
                    .returned
                    .statement,
    );
  }

  Method _buildCopyWithMethod(
    String className,
    List<({String normalizedName, Property property})> normalizedProperties,
  ) {
    return generateCopyWithMethod(
      className: className,
      properties:
          normalizedProperties.map((normalized) {
            final typeRef = typeReference(
              normalized.property.model,
              nameManager,
              package,
            );
            return (
              normalizedName: normalized.normalizedName,
              typeRef: typeRef,
            );
          }).toList(),
    );
  }
}
