import 'package:change_case/change_case.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:meta/meta.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/naming/name_utils.dart';
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
import 'package:tonik_generate/src/util/to_form_parameter_expression_generator.dart';
import 'package:tonik_generate/src/util/to_json_value_expression_generator.dart';
import 'package:tonik_generate/src/util/to_label_parameter_expression_generator.dart';
import 'package:tonik_generate/src/util/to_matrix_parameter_expression_generator.dart';
import 'package:tonik_generate/src/util/to_simple_parameter_expression_generator.dart';
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

    final publicClassName = nameManager.modelName(model);
    final snakeCaseName = publicClassName.toSnakeCase();

    // Generate unique name for nullable allOf with Raw prefix to allow
    // using a typedef to express the nullable type.
    final actualClassName = model.isNullable
        ? nameManager.modelName(
            AliasModel(
              name: '\$Raw$publicClassName',
              model: model,
              context: model.context,
            ),
          )
        : publicClassName;

    final generatedClasses = generateClasses(model, actualClassName);

    final library = Library((b) {
      b.body.addAll(generatedClasses);

      // Add typedef for nullable allOf.
      if (model.isNullable) {
        b.body.add(
          TypeDef(
            (b) => b
              ..name = publicClassName
              ..definition = refer('$actualClassName?'),
          ),
        );
      }
    });

    final formatter = DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    );

    final code = formatter.formatWithHeader(library.accept(emitter).toString());

    return (code: code, filename: '$snakeCaseName.dart');
  }

  /// Generates the main class and the copyWith infrastructure classes.
  @visibleForTesting
  List<Spec> generateClasses(AllOfModel model, [String? className]) {
    final actualClassName = className ?? nameManager.modelName(model);
    final models = model.models.toSortedList();

    final pseudoProperties = models.map((m) {
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

    final copyWithResult = _buildCopyWith(
      actualClassName,
      normalizedProperties,
    );

    return [
      generateClass(model, copyWithResult?.getter, actualClassName),
      if (copyWithResult != null) ...[
        copyWithResult.interfaceClass,
        copyWithResult.implClass,
      ],
    ];
  }

  @visibleForTesting
  Class generateClass(
    AllOfModel model, [
    Method? copyWithGetter,
    String? className,
  ]) {
    final publicClassName = nameManager.modelName(model);

    // Use provided className, or generate Raw prefix for nullable models.
    final actualClassName =
        className ??
        (model.isNullable
            ? nameManager.modelName(
                AliasModel(
                  name: '\$Raw$publicClassName',
                  model: model,
                  context: model.context,
                ),
              )
            : publicClassName);

    final models = model.models.toSortedList();

    final pseudoProperties = models.map((m) {
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

    final effectiveCopyWithGetter =
        copyWithGetter ??
        _buildCopyWith(actualClassName, normalizedProperties)?.getter;

    return Class(
      (b) {
        b
          ..name = actualClassName
          ..docs.addAll(formatDocComment(model.description))
          ..annotations.add(refer('immutable', 'package:meta/meta.dart'))
          ..implements.add(
            refer('ParameterEncodable', 'package:tonik_util/tonik_util.dart'),
          )
          ..implements.add(
            refer('UriEncodable', 'package:tonik_util/tonik_util.dart'),
          );

        if (model.isDeprecated) {
          b.annotations.add(
            refer('Deprecated', 'dart:core').call([
              literalString('This class is deprecated.'),
            ]),
          );
        }

        b
          ..constructors.add(_buildDefaultConstructor(normalizedProperties))
          ..constructors.addAll([
            _buildFromSimpleConstructor(
              actualClassName,
              normalizedProperties,
              model,
            ),
            _buildFromFormConstructor(
              actualClassName,
              normalizedProperties,
              model,
            ),
            _buildFromJsonConstructor(actualClassName, normalizedProperties),
          ])
          ..methods.addAll([
            _buildCurrentEncodingShapeGetter(model, normalizedProperties),
            _buildToJsonMethod(actualClassName, model, normalizedProperties),
            _buildParameterPropertiesMethod(
              actualClassName,
              normalizedProperties,
              model,
            ),
            _buildToSimpleMethod(
              normalizedProperties,
              model,
            ),
            _buildToFormMethod(
              actualClassName,
              normalizedProperties,
              model,
            ),
            _buildToLabelMethod(
              actualClassName,
              normalizedProperties,
              model,
            ),
            _buildToMatrixMethod(
              actualClassName,
              normalizedProperties,
              model,
            ),
            _buildToDeepObjectMethod(),
            _buildUriEncodeMethod(
              actualClassName,
              normalizedProperties,
              model,
            ),
            generateEqualsMethod(
              className: actualClassName,
              properties: properties,
            ),
            generateHashCodeMethod(properties: properties),
            ?effectiveCopyWithGetter,
          ])
          ..fields.addAll(_buildFields(normalizedProperties));
      },
    );
  }

  List<({String normalizedName, Property property})> _normalizeModelProperties(
    List<Property> properties,
  ) {
    final normalized = properties
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
        (b) => b
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
      (b) => b
        ..constant = true
        ..optionalParameters.addAll(
          normalizedProperties.map((normalized) {
            return Parameter(
              (b) => b
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
        ..body = refer(className)
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
        (b) => b
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
      (b) => b
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
    // Check for list properties first (before any other logic)
    final hasListProperties = normalizedProperties.any(
      (prop) => prop.property.model is ListModel,
    );
    final allListProperties =
        hasListProperties &&
        normalizedProperties.every(
          (prop) => prop.property.model is ListModel,
        );

    // If we have lists mixed with other types, throw exception
    if (hasListProperties && !allListProperties) {
      return Method(
        (b) => b
          ..annotations.add(refer('override', 'dart:core'))
          ..returns = refer('Object?', 'dart:core')
          ..name = 'toJson'
          ..lambda = true
          ..body = generateEncodingExceptionExpression(
            'Cannot encode $className to JSON: allOf mixing arrays '
            'with other types is not supported',
            raw: true,
          ).code,
      );
    }

    // If all properties are lists, handle like simple encoding
    if (allListProperties) {
      final jsonParts = <Code>[
        declareFinal('values')
            .assign(
              literalList(
                [],
                refer('Object?', 'dart:core'),
              ),
            )
            .statement,
      ];

      for (final normalized in normalizedProperties) {
        final fieldName = normalized.normalizedName;
        final fieldNameJson = '${fieldName}Json';

        jsonParts.addAll([
          Code('final $fieldNameJson = '),
          buildToJsonPropertyExpression(
            fieldName,
            normalized.property,
          ).code,
          const Code(';'),
          refer(
            'values',
          ).property('add').call([refer(fieldNameJson)]).statement,
        ]);
      }

      jsonParts.addAll([
        const Code('const deepEquals = '),
        refer(
          'DeepCollectionEquality',
          'package:collection/collection.dart',
        ).newInstance([]).code,
        const Code(';'),
        const Code('for (var i = 1; i < '),
        refer('values').property('length').code,
        const Code('; i++) {'),
        const Code('if (!'),
        refer('deepEquals').property('equals').call([
          refer('values').index(literalNum(0)),
          refer('values').index(refer('i')),
        ]).code,
        const Code(') {'),
        generateEncodingExceptionExpression(
          'Inconsistent allOf JSON encoding: all arrays must encode to '
          'the same result',
        ).statement,
        const Code('}'),
        const Code('}'),
        const Code('return '),
        refer('values').property('first').code,
        const Code(';'),
      ]);

      return Method(
        (b) => b
          ..annotations.add(refer('override', 'dart:core'))
          ..returns = refer('Object?', 'dart:core')
          ..name = 'toJson'
          ..lambda = false
          ..body = Block.of(jsonParts),
      );
    }

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
          raw: true,
        ).statement,
        const Code('}'),
        const Code('final map = '),
        buildEmptyMapStringObject().statement,
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
            'Expected ${fieldName.replaceAll(r'$', r'\$')}.toJson() to '
            'return Map<String, Object?>, got \${$fieldNameJson.runtimeType}',
          ).statement,
          const Code('}'),
          const Code('map.addAll('),
          refer(fieldNameJson).code,
          const Code(');'),
        ]);
      }

      bodyCode.add(const Code('return map;'));

      return Method(
        (b) => b
          ..annotations.add(refer('override', 'dart:core'))
          ..returns = refer('Object?', 'dart:core')
          ..name = 'toJson'
          ..lambda = false
          ..body = Block.of(bodyCode),
      );
    }

    switch (model.encodingShape) {
      case EncodingShape.mixed:
        return Method(
          (b) => b
            ..annotations.add(refer('override', 'dart:core'))
            ..returns = refer('Object?', 'dart:core')
            ..name = 'toJson'
            ..lambda = true
            ..body = generateEncodingExceptionExpression(
              'Cannot encode $className: mixing simple values (primitives/enums) and complex types is not supported',
              raw: true,
            ).code,
        );

      case EncodingShape.simple:
        final firstModel = model.models.first;
        final firstFieldName = normalizedProperties.first.normalizedName;

        return Method(
          (b) => b
            ..annotations.add(refer('override', 'dart:core'))
            ..returns = refer('Object?', 'dart:core')
            ..name = 'toJson'
            ..lambda = true
            ..body = buildToJsonPropertyExpression(
              firstFieldName,
              Property(
                name: firstFieldName,
                model: firstModel,
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
              ),
            ).code,
        );

      case EncodingShape.complex:
        // Lists are handled earlier, so this is only for non-list complex types
        final mapType = buildMapStringObjectType();
        final mapParts = <Code>[
          const Code('final map = '),
          buildEmptyMapStringObject().statement,
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
              'Expected ${fieldName.replaceAll(r'$', r'\$')}.toJson() to '
              'return Map<String, Object?>, got \${$fieldNameJson.runtimeType}',
            ).statement,
            const Code('}'),
            const Code('map.addAll('),
            refer(fieldNameJson).code,
            const Code(');'),
          ]);
        }

        mapParts.add(const Code('return map;'));

        return Method(
          (b) => b
            ..annotations.add(refer('override', 'dart:core'))
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
          ..body = Code('return $className();'),
      );
    }

    if (model.hasComplexTypes) {
      final propertyAssignments = <MapEntry<String, Expression>>[];

      for (final normalized in normalizedProperties) {
        final name = normalized.normalizedName;
        final modelType = normalized.property.model;

        final expression = buildSimpleValueExpression(
          refer('value'),
          model: modelType,
          isRequired: !normalized.property.isNullable,
          nameManager: nameManager,
          package: package,
          contextClass: className,
          contextProperty: name,
          explode: refer('explode'),
        );

        propertyAssignments.add(MapEntry(name, expression));
      }

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
          ..body = refer(className, package)
              .call([], {
                for (final entry in propertyAssignments) entry.key: entry.value,
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
        ..body = refer(className, package)
            .call([], {
              for (final entry in propertyAssignments) entry.key: entry.value,
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
        (b) => b
          ..name = 'parameterProperties'
          ..returns = buildMapStringStringType()
          ..optionalParameters.addAll([
            buildBoolParameter('allowEmpty', defaultValue: true),
            buildBoolParameter('allowLists', defaultValue: true),
          ])
          ..body = buildEmptyMapStringString().returned.statement,
      );
    }

    // Check if we have any list properties FIRST (before simple types check)
    final hasListProperties = normalizedProperties.any(
      (prop) => prop.property.model is ListModel,
    );
    final allListProperties =
        hasListProperties &&
        normalizedProperties.every(
          (prop) => prop.property.model is ListModel,
        );

    // If we have lists (either all or mixed), throw exception
    if (hasListProperties) {
      final message = allListProperties
          ? 'parameterProperties not supported for $className: contains '
                'array types'
          : 'parameterProperties not supported for $className: allOf '
                'mixing arrays with other types is not supported';

      return Method(
        (b) => b
          ..name = 'parameterProperties'
          ..returns = buildMapStringStringType()
          ..optionalParameters.addAll([
            buildBoolParameter('allowEmpty', defaultValue: true),
            buildBoolParameter('allowLists', defaultValue: true),
          ])
          ..lambda = true
          ..body = generateEncodingExceptionExpression(message, raw: true).code,
      );
    }

    if (model.hasSimpleTypes) {
      return Method(
        (b) => b
          ..name = 'parameterProperties'
          ..returns = buildMapStringStringType()
          ..optionalParameters.addAll([
            buildBoolParameter('allowEmpty', defaultValue: true),
            buildBoolParameter('allowLists', defaultValue: true),
          ])
          ..body = generateEncodingExceptionExpression(
            'parameterProperties not supported for $className: '
            'contains primitive types',
            raw: true,
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
            {
              'allowEmpty': refer('allowEmpty'),
              'allowLists': refer('allowLists'),
            },
          ),
        ]).statement,
      );
    }

    propertyMergingLines.add(
      refer('mergedProperties').returned.statement,
    );

    return Method(
      (b) => b
        ..name = 'parameterProperties'
        ..returns = buildMapStringStringType()
        ..optionalParameters.addAll([
          buildBoolParameter('allowEmpty', defaultValue: true),
          buildBoolParameter('allowLists', defaultValue: true),
        ])
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
        (b) => b
          ..annotations.add(refer('override', 'dart:core'))
          ..name = 'toSimple'
          ..returns = refer('String', 'dart:core')
          ..optionalParameters.addAll(buildEncodingParameters())
          ..lambda = false
          ..body = Block.of(bodyCode),
      );
    }

    final dynamicModels = normalizedProperties.where((prop) {
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
        (b) => b
          ..annotations.add(refer('override', 'dart:core'))
          ..name = 'toSimple'
          ..returns = refer('String', 'dart:core')
          ..optionalParameters.addAll(buildEncodingParameters())
          ..lambda = false
          ..body = Block.of(validationCode),
      );
    }

    if (model.cannotBeSimplyEncoded) {
      return Method(
        (b) => b
          ..annotations.add(refer('override', 'dart:core'))
          ..name = 'toSimple'
          ..returns = refer('String', 'dart:core')
          ..optionalParameters.addAll(buildEncodingParameters())
          ..lambda = false
          ..body = generateEncodingExceptionExpression(
            'Simple encoding not supported: contains complex types',
          ).statement,
      );
    }

    if (model.hasComplexTypes) {
      // Check if all complex types are lists with simple content
      final allComplexAreSimpleLists = normalizedProperties
          .where((p) => p.property.model.encodingShape == EncodingShape.complex)
          .every(
            (p) =>
                p.property.model is ListModel &&
                (p.property.model as ListModel).hasSimpleContent,
          );

      if (allComplexAreSimpleLists) {
        // Lists with simple content can be encoded directly with toSimple
        final valueCollectionCode = <Code>[
          declareFinal(
            'values',
          ).assign(literalSet([], refer('String', 'dart:core'))).statement,
        ];

        for (final prop in normalizedProperties) {
          valueCollectionCode.addAll([
            declareFinal('${prop.normalizedName}Simple')
                .assign(
                  buildSimpleParameterExpression(
                    refer(prop.normalizedName),
                    prop.property.model,
                    explode: refer('explode'),
                    allowEmpty: refer('allowEmpty'),
                  ),
                )
                .statement,
            refer('values').property('add').call([
              refer('${prop.normalizedName}Simple'),
            ]).statement,
          ]);
        }

        valueCollectionCode.addAll([
          const Code('if (values.length > 1) {'),
          generateEncodingExceptionExpression(
            'Inconsistent allOf simple encoding: '
            'all values must encode to the same result',
          ).statement,
          const Code('}'),
          const Code('return values.first;'),
        ]);

        return Method(
          (b) => b
            ..annotations.add(refer('override', 'dart:core'))
            ..name = 'toSimple'
            ..returns = refer('String', 'dart:core')
            ..optionalParameters.addAll(buildEncodingParameters())
            ..lambda = false
            ..body = Block.of(valueCollectionCode),
        );
      }

      // For non-list complex types, use parameterProperties
      return Method(
        (b) => b
          ..annotations.add(refer('override', 'dart:core'))
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
        (b) => b
          ..annotations.add(refer('override', 'dart:core'))
          ..name = 'toSimple'
          ..returns = refer('String', 'dart:core')
          ..optionalParameters.addAll(buildEncodingParameters())
          ..lambda = false
          ..body = const Code("return '';"),
      );
    }

    final primaryField = normalizedProperties.first;

    return Method(
      (b) => b
        ..annotations.add(refer('override', 'dart:core'))
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
          ..body = Code('return $className();'),
      );
    }

    if (model.hasComplexTypes) {
      final propertyAssignments = <MapEntry<String, Expression>>[];

      for (final normalized in normalizedProperties) {
        final name = normalized.normalizedName;
        final modelType = normalized.property.model;

        final expression = buildFromFormValueExpression(
          refer('value'),
          model: modelType,
          isRequired: !normalized.property.isNullable,
          nameManager: nameManager,
          package: package,
          contextClass: className,
          contextProperty: name,
          explode: refer('explode'),
        );

        propertyAssignments.add(MapEntry(name, expression));
      }

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
          ..body = refer(className, package)
              .call([], {
                for (final entry in propertyAssignments) entry.key: entry.value,
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
        ..body = refer(className, package)
            .call([], {
              for (final entry in propertyAssignments) entry.key: entry.value,
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
      // Check if we have DIRECT primitives
      // (not dynamic models that might be simple).
      final hasDirectPrimitives = normalizedProperties.any((prop) {
        final model = prop.property.model;
        return model.encodingShape == EncodingShape.simple &&
            model.encodingShape != EncodingShape.mixed;
      });

      // If we have direct primitives mixed with dynamic models,
      // we need runtime validation.
      // The dynamic models might be in simple state, making the entire
      // allOf simple and encodable.
      if (hasDirectPrimitives) {
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
            raw: true,
          ).statement,
          const Code('}'),
          declareFinal(
            'values',
          ).assign(literalSet([], refer('String', 'dart:core'))).statement,
        ];

        // Call toForm on each property and collect results.
        for (final prop in normalizedProperties) {
          bodyCode.addAll([
            declareFinal('${prop.normalizedName}Form')
                .assign(
                  refer(prop.normalizedName).property('toForm').call([], {
                    'explode': refer('explode'),
                    'allowEmpty': refer('allowEmpty'),
                    'useQueryComponent': refer('useQueryComponent'),
                  }),
                )
                .statement,
            refer('values').property('add').call([
              refer('${prop.normalizedName}Form'),
            ]).statement,
          ]);
        }

        bodyCode.addAll([
          const Code('if (values.length > 1) {'),
          generateEncodingExceptionExpression(
            'Inconsistent allOf form encoding for $className: '
            'all values must encode to the same result',
            raw: true,
          ).statement,
          const Code('}'),
          const Code('return values.first;'),
        ]);

        return Method(
          (b) => b
            ..annotations.add(refer('override', 'dart:core'))
            ..name = 'toForm'
            ..returns = refer('String', 'dart:core')
            ..optionalParameters.addAll(buildFormEncodingParameters())
            ..lambda = false
            ..body = Block.of(bodyCode),
        );
      }

      // No direct primitives, only dynamic models that could be mixed at
      // runtime. Generate runtime check.
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
          raw: true,
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
        (b) => b
          ..annotations.add(refer('override', 'dart:core'))
          ..name = 'toForm'
          ..returns = refer('String', 'dart:core')
          ..optionalParameters.addAll(buildFormEncodingParameters())
          ..lambda = false
          ..body = Block.of(bodyCode),
      );
    }

    final dynamicModels = normalizedProperties.where((prop) {
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
        (b) => b
          ..annotations.add(refer('override', 'dart:core'))
          ..name = 'toForm'
          ..returns = refer('String', 'dart:core')
          ..optionalParameters.addAll(buildFormEncodingParameters())
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
      final allDynamicModels = normalizedProperties.where((prop) {
        return prop.property.model.encodingShape == EncodingShape.mixed;
      }).toList();

      // If there are NO dynamic models AND we still have simple+complex mix,
      // it means we have a truly mixed allOf (primitive + class) which cannot
      // be encoded.
      if (allDynamicModels.isEmpty && model.hasSimpleTypes) {
        return Method(
          (b) => b
            ..annotations.add(refer('override', 'dart:core'))
            ..name = 'toForm'
            ..returns = refer('String', 'dart:core')
            ..optionalParameters.addAll(buildFormEncodingParameters())
            ..lambda = false
            ..body = generateEncodingExceptionExpression(
              'Form encoding not supported: contains complex types',
            ).statement,
        );
      }

      if (allDynamicModels.isEmpty) {
        // Check if all complex types are lists with simple content
        final allComplexAreSimpleLists = normalizedProperties
            .where(
              (p) => p.property.model.encodingShape == EncodingShape.complex,
            )
            .every(
              (p) =>
                  p.property.model is ListModel &&
                  (p.property.model as ListModel).hasSimpleContent,
            );

        if (allComplexAreSimpleLists) {
          // Lists with simple content can be encoded directly with toForm
          final valueCollectionCode = <Code>[
            declareFinal(
              'values',
            ).assign(literalSet([], refer('String', 'dart:core'))).statement,
          ];

          for (final prop in normalizedProperties) {
            valueCollectionCode.addAll([
              declareFinal('${prop.normalizedName}Form')
                  .assign(
                    buildFormParameterExpression(
                      refer(prop.normalizedName),
                      prop.property.model,
                      explode: refer('explode'),
                      allowEmpty: refer('allowEmpty'),
                    ),
                  )
                  .statement,
              refer('values').property('add').call([
                refer('${prop.normalizedName}Form'),
              ]).statement,
            ]);
          }

          valueCollectionCode.addAll([
            const Code('if (values.length > 1) {'),
            generateEncodingExceptionExpression(
              'Inconsistent allOf form encoding: '
              'all values must encode to the same result',
              raw: true,
            ).statement,
            const Code('}'),
            const Code('return values.first;'),
          ]);

          return Method(
            (b) => b
              ..annotations.add(refer('override', 'dart:core'))
              ..name = 'toForm'
              ..returns = refer('String', 'dart:core')
              ..optionalParameters.addAll(buildFormEncodingParameters())
              ..lambda = false
              ..body = Block.of(valueCollectionCode),
          );
        }

        // For non-list complex types, use parameterProperties
        return Method(
          (b) => b
            ..annotations.add(refer('override', 'dart:core'))
            ..name = 'toForm'
            ..returns = refer('String', 'dart:core')
            ..optionalParameters.addAll(buildFormEncodingParameters())
            ..lambda = false
            ..body = refer('parameterProperties')
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
        (b) => b
          ..annotations.add(refer('override', 'dart:core'))
          ..name = 'toForm'
          ..returns = refer('String', 'dart:core')
          ..optionalParameters.addAll(buildFormEncodingParameters())
          ..lambda = false
          ..body = Block.of(bodyCode),
      );
    }

    if (normalizedProperties.isEmpty) {
      return Method(
        (b) => b
          ..annotations.add(refer('override', 'dart:core'))
          ..name = 'toForm'
          ..returns = refer('String', 'dart:core')
          ..optionalParameters.addAll(buildFormEncodingParameters())
          ..lambda = false
          ..body = const Code("return '';"),
      );
    }

    final primaryField = normalizedProperties.first;

    return Method(
      (b) => b
        ..annotations.add(refer('override', 'dart:core'))
        ..name = 'toForm'
        ..returns = refer('String', 'dart:core')
        ..optionalParameters.addAll(buildFormEncodingParameters())
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
        (b) => b
          ..annotations.add(refer('override', 'dart:core'))
          ..name = 'toLabel'
          ..returns = refer('String', 'dart:core')
          ..optionalParameters.addAll(buildEncodingParameters())
          ..lambda = false
          ..body = Block.of(bodyCode),
      );
    }

    final dynamicModels = normalizedProperties.where((prop) {
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
        (b) => b
          ..annotations.add(refer('override', 'dart:core'))
          ..name = 'toLabel'
          ..returns = refer('String', 'dart:core')
          ..optionalParameters.addAll(buildEncodingParameters())
          ..lambda = false
          ..body = Block.of(validationCode),
      );
    }

    if (model.cannotBeSimplyEncoded) {
      return Method(
        (b) => b
          ..annotations.add(refer('override', 'dart:core'))
          ..name = 'toLabel'
          ..returns = refer('String', 'dart:core')
          ..optionalParameters.addAll(buildEncodingParameters())
          ..lambda = false
          ..body = generateEncodingExceptionExpression(
            'Simple encoding not supported: contains complex types',
          ).statement,
      );
    }

    if (model.hasComplexTypes) {
      // Check if all complex types are lists with simple content
      final allComplexAreSimpleLists = normalizedProperties
          .where((p) => p.property.model.encodingShape == EncodingShape.complex)
          .every(
            (p) =>
                p.property.model is ListModel &&
                (p.property.model as ListModel).hasSimpleContent,
          );

      if (allComplexAreSimpleLists) {
        // Lists with simple content can be encoded directly with toLabel
        final valueCollectionCode = <Code>[
          declareFinal(
            'values',
          ).assign(literalSet([], refer('String', 'dart:core'))).statement,
        ];

        for (final prop in normalizedProperties) {
          valueCollectionCode.addAll([
            declareFinal('${prop.normalizedName}Label')
                .assign(
                  buildLabelParameterExpression(
                    refer(prop.normalizedName),
                    prop.property.model,
                    explode: refer('explode'),
                    allowEmpty: refer('allowEmpty'),
                  ),
                )
                .statement,
            refer('values').property('add').call([
              refer('${prop.normalizedName}Label'),
            ]).statement,
          ]);
        }

        valueCollectionCode.addAll([
          const Code('if (values.length > 1) {'),
          generateEncodingExceptionExpression(
            'Inconsistent allOf label encoding: '
            'all values must encode to the same result',
          ).statement,
          const Code('}'),
          const Code('return values.first;'),
        ]);

        return Method(
          (b) => b
            ..annotations.add(refer('override', 'dart:core'))
            ..name = 'toLabel'
            ..returns = refer('String', 'dart:core')
            ..optionalParameters.addAll(buildEncodingParameters())
            ..lambda = false
            ..body = Block.of(valueCollectionCode),
        );
      }

      // For non-list complex types, use parameterProperties
      return Method(
        (b) => b
          ..annotations.add(refer('override', 'dart:core'))
          ..name = 'toLabel'
          ..returns = refer('String', 'dart:core')
          ..optionalParameters.addAll(buildEncodingParameters())
          ..lambda = false
          ..body = refer('parameterProperties')
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
        (b) => b
          ..annotations.add(refer('override', 'dart:core'))
          ..name = 'toLabel'
          ..returns = refer('String', 'dart:core')
          ..optionalParameters.addAll(buildEncodingParameters())
          ..lambda = false
          ..body = const Code("return '';"),
      );
    }

    final primaryField = normalizedProperties.first;

    return Method(
      (b) => b
        ..annotations.add(refer('override', 'dart:core'))
        ..name = 'toLabel'
        ..returns = refer('String', 'dart:core')
        ..optionalParameters.addAll(buildEncodingParameters())
        ..lambda = false
        ..body = refer(primaryField.normalizedName)
            .property('toLabel')
            .call([], {
              'explode': refer('explode'),
              'allowEmpty': refer('allowEmpty'),
            })
            .returned
            .statement,
    );
  }

  Method _buildToMatrixMethod(
    String className,
    List<({String normalizedName, Property property})> normalizedProperties,
    AllOfModel model,
  ) {
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
        const Code('final mergedProperties = '),
        buildEmptyMapStringString().statement,
      ];

      for (final prop in normalizedProperties) {
        bodyCode.add(
          refer('mergedProperties').property('addAll').call([
            refer(prop.normalizedName).property('parameterProperties').call(
              [],
              {
                'allowEmpty': refer('allowEmpty'),
              },
            ),
          ]).statement,
        );
      }

      bodyCode.addAll([
        const Code(
          'return mergedProperties.toMatrix( '
          'paramName, explode: explode, allowEmpty: allowEmpty, '
          'alreadyEncoded: true);',
        ),
      ]);

      return Method(
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
          ..lambda = false
          ..body = Block.of(bodyCode),
      );
    }

    if (model.cannotBeSimplyEncoded) {
      return Method(
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
          ..lambda = false
          ..body = generateEncodingExceptionExpression(
            'Simple encoding not supported: contains complex types',
          ).statement,
      );
    }

    if (model.hasComplexTypes) {
      // Check if all complex types are lists with simple content
      final allComplexAreSimpleLists = normalizedProperties
          .where((p) => p.property.model.encodingShape == EncodingShape.complex)
          .every(
            (p) =>
                p.property.model is ListModel &&
                (p.property.model as ListModel).hasSimpleContent,
          );

      if (allComplexAreSimpleLists) {
        // Lists with simple content can be encoded directly with toMatrix
        final valueCollectionCode = <Code>[
          declareFinal(
            'values',
          ).assign(literalSet([], refer('String', 'dart:core'))).statement,
        ];

        for (final prop in normalizedProperties) {
          valueCollectionCode.addAll([
            declareFinal('${prop.normalizedName}Matrix')
                .assign(
                  buildMatrixParameterExpression(
                    refer(prop.normalizedName),
                    prop.property.model,
                    paramName: refer('paramName'),
                    explode: refer('explode'),
                    allowEmpty: refer('allowEmpty'),
                  ),
                )
                .statement,
            refer('values').property('add').call([
              refer('${prop.normalizedName}Matrix'),
            ]).statement,
          ]);
        }

        valueCollectionCode.addAll([
          const Code('if (values.length > 1) {'),
          generateEncodingExceptionExpression(
            'Inconsistent allOf matrix encoding for $className: '
            'all values must encode to the same result',
            raw: true,
          ).statement,
          const Code('}'),
          const Code('return values.first;'),
        ]);

        return Method(
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
            ..lambda = false
            ..body = Block.of(valueCollectionCode),
        );
      }

      // For non-list complex types, use parameterProperties
      final propertyMergingLines = [
        declareFinal(
          'mergedProperties',
        ).assign(buildEmptyMapStringString()).statement,
      ];

      for (final normalized in normalizedProperties) {
        propertyMergingLines.add(
          refer('mergedProperties').property('addAll').call([
            refer(
              normalized.normalizedName,
            ).property('parameterProperties').call([], {
              'allowEmpty': refer('allowEmpty'),
            }),
          ]).statement,
        );
      }

      propertyMergingLines.add(
        const Code(
          'return mergedProperties.toMatrix( '
          'paramName, explode: explode, allowEmpty: allowEmpty, '
          'alreadyEncoded: true);',
        ),
      );

      return Method(
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
          ..lambda = false
          ..body = Block.of(propertyMergingLines),
      );
    }

    if (normalizedProperties.isEmpty) {
      return Method(
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
          ..lambda = false
          ..body = literalString('')
              .property('toMatrix')
              .call(
                [refer('paramName')],
                {
                  'explode': refer('explode'),
                  'allowEmpty': refer('allowEmpty'),
                },
              )
              .returned
              .statement,
      );
    }

    // For primitive-only AllOf, collect all values and validate they're equal
    final valueCollectionCode = <Code>[
      declareFinal(
        'values',
      ).assign(literalSet([], refer('String', 'dart:core'))).statement,
    ];

    for (final prop in normalizedProperties) {
      valueCollectionCode.addAll([
        declareFinal('${prop.normalizedName}Matrix')
            .assign(
              buildMatrixParameterExpression(
                refer(prop.normalizedName),
                prop.property.model,
                paramName: refer('paramName'),
                explode: refer('explode'),
                allowEmpty: refer('allowEmpty'),
              ),
            )
            .statement,
        refer('values').property('add').call([
          refer('${prop.normalizedName}Matrix'),
        ]).statement,
      ]);
    }

    valueCollectionCode.addAll([
      const Code('if (values.length > 1) {'),
      generateEncodingExceptionExpression(
        'Inconsistent allOf matrix encoding for $className: '
        'all values must encode to the same result',
        raw: true,
      ).statement,
      const Code('}'),
      const Code('return values.first;'),
    ]);

    return Method(
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
        ..lambda = false
        ..body = Block.of(valueCollectionCode),
    );
  }

  Method _buildToDeepObjectMethod() {
    return Method(
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

  Method _buildUriEncodeMethod(
    String className,
    List<({String normalizedName, Property property})> normalizedProperties,
    AllOfModel model,
  ) {
    final hasDynamicModels = normalizedProperties.any((prop) {
      return prop.property.model.encodingShape == EncodingShape.mixed;
    });

    if (hasDynamicModels) {
      final encodingShapeType = refer(
        'EncodingShape',
        'package:tonik_util/tonik_util.dart',
      );

      final bodyCode = <Code>[
        const Code('if (currentEncodingShape != '),
        encodingShapeType.property('simple').code,
        const Code(') {'),
        generateEncodingExceptionExpression(
          'Cannot uriEncode $className: contains complex types',
          raw: true,
        ).statement,
        const Code('}'),
      ];

      if (normalizedProperties.isNotEmpty) {
        final simpleProp = normalizedProperties.firstWhere(
          (prop) =>
              prop.property.model.encodingShape == EncodingShape.simple ||
              prop.property.model.encodingShape == EncodingShape.mixed,
          orElse: () => normalizedProperties.first,
        );
        bodyCode.add(
          refer(simpleProp.normalizedName)
              .property('uriEncode')
              .call([], {
                'allowEmpty': refer('allowEmpty'),
                'useQueryComponent': refer('useQueryComponent'),
              })
              .returned
              .statement,
        );
      } else {
        bodyCode.add(literalString('').returned.statement);
      }

      return Method(
        (b) => b
          ..annotations.add(refer('override', 'dart:core'))
          ..name = 'uriEncode'
          ..returns = refer('String', 'dart:core')
          ..optionalParameters.addAll([
            Parameter(
              (b) => b
                ..name = 'allowEmpty'
                ..type = refer('bool', 'dart:core')
                ..named = true
                ..required = true,
            ),
            Parameter(
              (b) => b
                ..name = 'useQueryComponent'
                ..type = refer('bool', 'dart:core')
                ..named = true
                ..defaultTo = literalBool(false).code,
            ),
          ])
          ..lambda = false
          ..body = Block.of(bodyCode),
      );
    }

    // Check if any property is complex (cannot be URI encoded)
    final hasComplexProperties = normalizedProperties.any((prop) {
      return prop.property.model.encodingShape == EncodingShape.complex;
    });

    if (model.cannotBeSimplyEncoded || hasComplexProperties) {
      return Method(
        (b) => b
          ..annotations.add(refer('override', 'dart:core'))
          ..name = 'uriEncode'
          ..returns = refer('String', 'dart:core')
          ..optionalParameters.addAll([
            Parameter(
              (b) => b
                ..name = 'allowEmpty'
                ..type = refer('bool', 'dart:core')
                ..named = true
                ..required = true,
            ),
            Parameter(
              (b) => b
                ..name = 'useQueryComponent'
                ..type = refer('bool', 'dart:core')
                ..named = true
                ..defaultTo = literalBool(false).code,
            ),
          ])
          ..lambda = false
          ..body = generateEncodingExceptionExpression(
            'Cannot uriEncode $className: contains complex types',
            raw: true,
          ).statement,
      );
    }

    if (normalizedProperties.isEmpty) {
      return Method(
        (b) => b
          ..annotations.add(refer('override', 'dart:core'))
          ..name = 'uriEncode'
          ..returns = refer('String', 'dart:core')
          ..optionalParameters.addAll([
            Parameter(
              (b) => b
                ..name = 'allowEmpty'
                ..type = refer('bool', 'dart:core')
                ..named = true
                ..required = true,
            ),
            Parameter(
              (b) => b
                ..name = 'useQueryComponent'
                ..type = refer('bool', 'dart:core')
                ..named = true
                ..defaultTo = literalBool(false).code,
            ),
          ])
          ..lambda = true
          ..body = literalString('').code,
      );
    }

    // For AllOf, all properties must encode to the same value
    final valueCollectionCode = <Code>[
      declareFinal(
        'values',
      ).assign(literalSet([], refer('String', 'dart:core'))).statement,
    ];

    for (final prop in normalizedProperties) {
      valueCollectionCode.addAll([
        declareFinal('${prop.normalizedName}Encoded')
            .assign(
              refer(prop.normalizedName).property('uriEncode').call([], {
                'allowEmpty': refer('allowEmpty'),
                'useQueryComponent': refer('useQueryComponent'),
              }),
            )
            .statement,
        refer('values').property('add').call([
          refer('${prop.normalizedName}Encoded'),
        ]).statement,
      ]);
    }

    valueCollectionCode.addAll([
      const Code('if (values.length > 1) {'),
      generateEncodingExceptionExpression(
        'Inconsistent allOf encoding for $className: '
        'all values must encode to the same result',
        raw: true,
      ).statement,
      const Code('}'),
      const Code('return values.first;'),
    ]);

    return Method(
      (b) => b
        ..annotations.add(refer('override', 'dart:core'))
        ..name = 'uriEncode'
        ..returns = refer('String', 'dart:core')
        ..optionalParameters.addAll([
          Parameter(
            (b) => b
              ..name = 'allowEmpty'
              ..type = refer('bool', 'dart:core')
              ..named = true
              ..required = true,
          ),
          Parameter(
            (b) => b
              ..name = 'useQueryComponent'
              ..type = refer('bool', 'dart:core')
              ..named = true
              ..defaultTo = literalBool(false).code,
          ),
        ])
        ..lambda = false
        ..body = Block.of(valueCollectionCode),
    );
  }

  CopyWithResult? _buildCopyWith(
    String className,
    List<({String normalizedName, Property property})> normalizedProperties,
  ) {
    return generateCopyWith(
      className: className,
      properties: normalizedProperties.map((normalized) {
        final typeRef = typeReference(
          normalized.property.model,
          nameManager,
          package,
          isNullableOverride:
              normalized.property.isNullable || !normalized.property.isRequired,
        );
        final model = normalized.property.model;
        final resolvedModel = model is AliasModel ? model.resolved : model;
        return (
          normalizedName: normalized.normalizedName,
          typeRef: typeRef,
          // Skip cast for AnyModel since its typedef is Object?
          skipCast: resolvedModel is AnyModel,
        );
      }).toList(),
    );
  }
}
