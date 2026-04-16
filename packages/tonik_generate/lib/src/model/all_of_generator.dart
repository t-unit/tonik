import 'package:code_builder/code_builder.dart';
import 'package:meta/meta.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/naming/name_utils.dart';
import 'package:tonik_generate/src/util/additional_properties_helpers.dart';
import 'package:tonik_generate/src/util/composite_guard_builders.dart';
import 'package:tonik_generate/src/util/composite_library_builder.dart';
import 'package:tonik_generate/src/util/copy_with_method_generator.dart';
import 'package:tonik_generate/src/util/doc_comment_formatter.dart';
import 'package:tonik_generate/src/util/equals_method_generator.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';
import 'package:tonik_generate/src/util/from_form_value_expression_generator.dart';
import 'package:tonik_generate/src/util/from_json_value_expression_generator.dart';
import 'package:tonik_generate/src/util/from_simple_value_expression_generator.dart';
import 'package:tonik_generate/src/util/hash_code_generator.dart';
import 'package:tonik_generate/src/util/known_keys_collector.dart';
import 'package:tonik_generate/src/util/spec_literal_string.dart';
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
  const AllOfGenerator({
    required this.nameManager,
    required this.package,
    required this.stableModelSorter,
    this.useImmutableCollections = false,
  });

  final NameManager nameManager;
  final String package;
  final StableModelSorter stableModelSorter;
  final bool useImmutableCollections;

  ({String code, String filename}) generate(AllOfModel model) {
    return generateCompositeLibrary(
      model: model,
      isNullable: model.isNullable,
      nameManager: nameManager,
      generateClasses: (actualClassName) =>
          generateClasses(model, actualClassName),
    );
  }

  /// Generates the main class and the copyWith infrastructure classes.
  @visibleForTesting
  List<Spec> generateClasses(AllOfModel model, [String? className]) {
    final actualClassName = className ?? nameManager.modelName(model);
    final models = stableModelSorter.sortModels(model.models);

    final pseudoProperties = models.map((m) {
      final typeRef = typeReference(
        m,
        nameManager,
        package,
        useImmutableCollections: useImmutableCollections,
      );
      final isNullable = m.isEffectivelyNullable;
      return Property(
        name: typeRef.symbol,
        model: m,
        isRequired: !isNullable,
        isNullable: isNullable,
        isDeprecated: false,
      );
    }).toList();

    final normalizedProperties = _normalizeModelProperties(pseudoProperties);

    final copyWithResult = _buildCopyWith(
      actualClassName,
      normalizedProperties,
      model,
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

    final models = stableModelSorter.sortModels(model.models);

    final pseudoProperties = models.map((m) {
      final typeRef = typeReference(
        m,
        nameManager,
        package,
        useImmutableCollections: useImmutableCollections,
      );
      final isNullable = m.isEffectivelyNullable;
      return Property(
        name: typeRef.symbol,
        model: m,
        isRequired: !isNullable,
        isNullable: isNullable,
        isDeprecated: false,
      );
    }).toList();

    final normalizedProperties = _normalizeModelProperties(pseudoProperties);
    final properties = _buildPropertiesFromNormalized(
      normalizedProperties,
      model,
    );

    final effectiveCopyWithGetter =
        copyWithGetter ??
        _buildCopyWith(actualClassName, normalizedProperties, model)?.getter;

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

        final encodingExceptionBody = generateEncodingExceptionExpression(
          '$actualClassName is read-only and cannot be encoded.',
          raw: true,
        ).code;

        b
          ..constructors.add(
            _buildDefaultConstructor(normalizedProperties, model),
          )
          ..constructors.addAll([
            if (model.isWriteOnly)
              buildWriteOnlyFromSimpleConstructor(actualClassName)
            else
              _buildFromValueConstructor(
                isForm: false,
                className: actualClassName,
                normalizedProperties: normalizedProperties,
                model: model,
              ),
            if (model.isWriteOnly)
              buildWriteOnlyFromFormConstructor(actualClassName)
            else
              _buildFromValueConstructor(
                isForm: true,
                className: actualClassName,
                normalizedProperties: normalizedProperties,
                model: model,
              ),
            if (model.isWriteOnly)
              buildWriteOnlyFromJsonConstructor(actualClassName)
            else
              _buildFromJsonConstructor(
                actualClassName,
                normalizedProperties,
                model,
              ),
          ])
          ..methods.addAll([
            if (model.isReadOnly)
              buildReadOnlyCurrentEncodingShapeGetter(encodingExceptionBody)
            else
              _buildCurrentEncodingShapeGetter(model, normalizedProperties),
            if (model.isReadOnly)
              buildReadOnlyToJsonMethod(encodingExceptionBody)
            else
              _buildToJsonMethod(actualClassName, model, normalizedProperties),
            if (model.isReadOnly)
              buildReadOnlyParameterPropertiesMethod(encodingExceptionBody)
            else
              _buildParameterPropertiesMethod(
                actualClassName,
                normalizedProperties,
                model,
              ),
            if (model.isReadOnly)
              buildReadOnlyToSimpleMethod(encodingExceptionBody)
            else
              _buildToSimpleMethod(
                normalizedProperties,
                model,
              ),
            if (model.isReadOnly)
              buildReadOnlyToFormMethod(encodingExceptionBody)
            else
              _buildToFormMethod(
                actualClassName,
                normalizedProperties,
                model,
              ),
            if (model.isReadOnly)
              buildReadOnlyToLabelMethod(encodingExceptionBody)
            else
              _buildToLabelMethod(
                actualClassName,
                normalizedProperties,
                model,
              ),
            if (model.isReadOnly)
              buildReadOnlyToMatrixMethod(encodingExceptionBody)
            else
              _buildToMatrixMethod(
                actualClassName,
                normalizedProperties,
                model,
              ),
            if (model.isReadOnly)
              buildReadOnlyToDeepObjectMethod(encodingExceptionBody)
            else
              buildToDeepObjectMethod(),
            if (model.isReadOnly)
              buildReadOnlyUriEncodeMethod(encodingExceptionBody)
            else
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
          ..fields.addAll(_buildFields(normalizedProperties, model));
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
    AllOfModel model,
  ) {
    final fields = normalizedProperties.map((normalized) {
      final typeRef = typeReference(
        normalized.property.model,
        nameManager,
        package,
        isNullableOverride: model.isReadOnly,
        useImmutableCollections: useImmutableCollections,
      );
      return Field(
        (b) => b
          ..name = normalized.normalizedName
          ..modifier = FieldModifier.final$
          ..type = typeRef,
      );
    }).toList();

    if (hasActiveAdditionalProperties(model.additionalProperties)) {
      final apFieldName = pickAdditionalPropertiesFieldName(
        normalizedProperties,
      );
      fields.add(
        Field(
          (b) => b
            ..name = apFieldName
            ..modifier = FieldModifier.final$
            ..type = additionalPropertiesType(
              model.additionalProperties,
              nameManager,
              package,
              useImmutableCollections: useImmutableCollections,
            ),
        ),
      );
    }

    return fields;
  }

  List<({String normalizedName, bool hasCollectionValue})>
  _buildPropertiesFromNormalized(
    List<({String normalizedName, Property property})> normalizedProperties, [
    AllOfModel? model,
  ]) {
    final props = normalizedProperties.map((normalized) {
      return (
        normalizedName: normalized.normalizedName,
        hasCollectionValue: !useImmutableCollections &&
            isCollectionModel(normalized.property.model),
      );
    }).toList();

    if (model != null &&
        hasActiveAdditionalProperties(model.additionalProperties)) {
      final apFieldName = pickAdditionalPropertiesFieldName(
        normalizedProperties,
      );
      props.add(
        (
          normalizedName: apFieldName,
          hasCollectionValue: !useImmutableCollections,
        ),
      );
    }

    return props;
  }

  Constructor _buildDefaultConstructor(
    List<({String normalizedName, Property property})> normalizedProperties,
    AllOfModel model,
  ) {
    return Constructor(
      (b) {
        b
          ..constant = true
          ..optionalParameters.addAll(
            normalizedProperties.map((normalized) {
              return Parameter(
                (b) => b
                  ..name = normalized.normalizedName
                  ..named = true
                  ..required = !model.isReadOnly
                  ..toThis = true,
              );
            }),
          );
        if (hasActiveAdditionalProperties(model.additionalProperties)) {
          final apFieldName = pickAdditionalPropertiesFieldName(
            normalizedProperties,
          );
          b.optionalParameters.add(
            Parameter(
              (b) => b
                ..name = apFieldName
                ..named = true
                ..required = false
                ..defaultTo = useImmutableCollections
                    ? refer(
                        'IMapConst',
                        'package:fast_immutable_collections/'
                            'fast_immutable_collections.dart',
                      ).constInstance([literalConstMap({})]).code
                    : const Code('const {}')
                ..toThis = true,
            ),
          );
        }
      },
    );
  }

  Constructor _buildFromJsonConstructor(
    String className,
    List<({String normalizedName, Property property})> normalizedProperties,
    AllOfModel model,
  ) {
    final fromJsonParams = <Expression>[];
    final fieldNames = <String>[];
    for (final normalized in normalizedProperties) {
      fieldNames.add(normalized.normalizedName);
      final expr = buildFromJsonValueExpression(
        'json',
        model: normalized.property.model,
        nameManager: nameManager,
        package: package,
        contextClass: className,
        useImmutableCollections: useImmutableCollections,
      );
      fromJsonParams.add(expr);
    }

    final hasAP = hasActiveAdditionalProperties(model.additionalProperties);

    if (!hasAP) {
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
                    (i) => MapEntry(
                      fieldNames[i],
                      fromJsonParams[i],
                    ),
                  ),
                ),
              )
              .returned
              .statement,
      );
    }

    // With additional properties: decode map, collect unknown keys
    final apFieldName = pickAdditionalPropertiesFieldName(normalizedProperties);
    final knownKeys = collectKnownKeys(model);
    final knownKeysLiteral = knownKeys.map((k) => "r'$k'").join(', ');

    final ap = model.additionalProperties;
    final codes = <Code>[
      Code(
        r"final _$map = json.decodeMap(context: r'"
        "$className');",
      ),
      Code(
        'const _\$knownKeys = {$knownKeysLiteral};',
      ),
    ];

    final mapType = additionalPropertiesType(
      model.additionalProperties,
      nameManager,
      package,
    );

    codes.add(
      declareFinal(r'_$additional')
          .assign(
            literalMap(
              {},
              refer('String', 'dart:core'),
              mapType.types.last,
            ),
          )
          .statement,
    );

    if (ap is TypedAdditionalProperties) {
      final decodeExpr = buildFromJsonValueExpression(
        r'_$entry.value',
        model: ap.valueModel,
        nameManager: nameManager,
        package: package,
        contextClass: className,
        contextProperty: 'additionalProperties',
        useImmutableCollections: useImmutableCollections,
      );
      codes.addAll([
        const Code(r'for (final _$entry in _$map.entries) {'),
        const Code(r'if (!_$knownKeys.contains(_$entry.key)) {'),
        const Code(r'_$additional[_$entry.key] = '),
        decodeExpr.code,
        const Code(';'),
        const Code('}'),
        const Code('}'),
      ]);
    } else {
      codes.addAll([
        const Code(r'for (final _$entry in _$map.entries) {'),
        const Code(r'if (!_$knownKeys.contains(_$entry.key)) {'),
        const Code(r'_$additional[_$entry.key] = _$entry.value;'),
        const Code('}'),
        const Code('}'),
      ]);
    }

    final constructorArgs = Map.fromEntries(
      List.generate(
        fromJsonParams.length,
        (i) => MapEntry(fieldNames[i], fromJsonParams[i]),
      ),
    );
    constructorArgs[apFieldName] = useImmutableCollections
        ? refer(r'_$additional').property('lock')
        : refer(r'_$additional');

    codes.add(
      refer(className).call([], constructorArgs).returned.statement,
    );

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
        ..body = Block.of(codes),
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
        const Code(r'final _$shapes = <'),
        encodingShapeType.code,
        const Code('>{};'),
      ];

      for (final prop in normalizedProperties) {
        if (prop.property.model.isEffectivelyNullable) {
          bodyCode.addAll([
            Code('if (${prop.normalizedName} != null) {'),
            Code(
              '  _\$shapes.add(${prop.normalizedName}!.currentEncodingShape);',
            ),
            const Code('}'),
          ]);
        } else {
          bodyCode.add(
            Code(
              '_\$shapes.add(${prop.normalizedName}.currentEncodingShape);',
            ),
          );
        }
      }

      final hasNullableModels = normalizedProperties.any(
        (prop) => prop.property.model.isEffectivelyNullable,
      );
      if (hasNullableModels) {
        bodyCode.addAll([
          const Code(r'if (_$shapes.isEmpty) return '),
          encodingShapeType.property('complex').code,
          const Code(';'),
        ]);
      }
      bodyCode.addAll([
        const Code(r'if (_$shapes.length > 1) return '),
        encodingShapeType.property('mixed').statement,
        const Code(r'return _$shapes.first;'),
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
      (prop) => prop.property.model.resolved is ListModel,
    );
    final allListProperties =
        hasListProperties &&
        normalizedProperties.every(
          (prop) => prop.property.model.resolved is ListModel,
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
        declareFinal(r'_$values')
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
        final fieldNameJson = '_\$${fieldName}Json';

        jsonParts.addAll([
          Code('final $fieldNameJson = '),
          buildToJsonPropertyExpression(
            fieldName,
            normalized.property,
            useImmutableCollections: useImmutableCollections,
          ).code,
          const Code(';'),
          refer(
            r'_$values',
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
        refer(r'_$values').property('length').code,
        const Code('; i++) {'),
        const Code('if (!'),
        refer('deepEquals').property('equals').call([
          refer(r'_$values').index(literalNum(0)),
          refer(r'_$values').index(refer('i')),
        ]).code,
        const Code(') {'),
        generateEncodingExceptionExpression(
          'Inconsistent allOf JSON encoding: all arrays must encode to '
          'the same result',
        ).statement,
        const Code('}'),
        const Code('}'),
        const Code('return '),
        refer(r'_$values').property('first').code,
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
        const Code(r'final _$map = '),
        buildEmptyMapStringObject().statement,
      ];

      final mapType = buildMapStringObjectType();
      for (final normalized in normalizedProperties) {
        final fieldName = normalized.normalizedName;
        final fieldNameJson = '_\$${fieldName}Json';
        final isNullable = normalized.property.model.isEffectivelyNullable;

        if (isNullable) {
          bodyCode.add(Code('if ($fieldName != null) {'));
        }
        bodyCode.addAll([
          Code('final $fieldNameJson = '),
          if (isNullable)
            Code('$fieldName!.toJson();')
          else ...[
            refer(fieldName).code,
            const Code('.toJson();'),
          ],
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
          const Code(r'_$map.addAll('),
          refer(fieldNameJson).code,
          const Code(');'),
        ]);
        if (isNullable) {
          bodyCode.add(const Code('}'));
        }
      }

      if (hasActiveAdditionalProperties(model.additionalProperties)) {
        final apFieldName = pickAdditionalPropertiesFieldName(
          normalizedProperties,
        );
        final ap = model.additionalProperties;
        final apAccess = useImmutableCollections
            ? '$apFieldName.unlock'
            : apFieldName;
        if (ap is TypedAdditionalProperties) {
          final apExpr = buildToJsonAdditionalPropertiesExpression(
            apFieldName,
            ap.valueModel,
            useImmutableCollections: useImmutableCollections,
          );
          bodyCode.addAll([
            const Code(r'_$map.addAll('),
            apExpr.code,
            const Code(');'),
          ]);
        } else {
          bodyCode.add(
            Code(
              r'_$map.addAll('
              '$apAccess);',
            ),
          );
        }
      }

      bodyCode.add(const Code(r'return _$map;'));

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
              useImmutableCollections: useImmutableCollections,
            ).code,
        );

      case EncodingShape.complex:
        // Lists are handled earlier, so this is only for non-list complex types
        final mapType = buildMapStringObjectType();
        final mapParts = <Code>[
          const Code(r'final _$map = '),
          buildEmptyMapStringObject().statement,
        ];

        for (final normalized in normalizedProperties) {
          final fieldName = normalized.normalizedName;
          final fieldNameJson = '_\$${fieldName}Json';
          final isNullable = normalized.property.model.isEffectivelyNullable;

          if (isNullable) {
            mapParts.add(Code('if ($fieldName != null) {'));
          }
          mapParts.addAll([
            Code('final $fieldNameJson = '),
            if (isNullable)
              Code('$fieldName!.toJson();')
            else ...[
              refer(fieldName).code,
              const Code('.toJson();'),
            ],
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
            const Code(r'_$map.addAll('),
            refer(fieldNameJson).code,
            const Code(');'),
          ]);
          if (isNullable) {
            mapParts.add(const Code('}'));
          }
        }

        if (hasActiveAdditionalProperties(model.additionalProperties)) {
          final apFieldName = pickAdditionalPropertiesFieldName(
            normalizedProperties,
          );
          final ap = model.additionalProperties;
          final apAccess = useImmutableCollections
              ? '$apFieldName.unlock'
              : apFieldName;
          if (ap is TypedAdditionalProperties) {
            final apExpr = buildToJsonAdditionalPropertiesExpression(
              apFieldName,
              ap.valueModel,
              useImmutableCollections: useImmutableCollections,
            );
            mapParts.addAll([
              const Code(r'_$map.addAll('),
              apExpr.code,
              const Code(');'),
            ]);
          } else {
            mapParts.add(
              Code(
                r'_$map.addAll('
                '$apAccess);',
              ),
            );
          }
        }

        mapParts.add(const Code(r'return _$map;'));

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

  /// Builds a fromSimple or fromForm factory constructor for allOf.
  Constructor _buildFromValueConstructor({
    required bool isForm,
    required String className,
    required List<({String normalizedName, Property property})>
    normalizedProperties,
    required AllOfModel model,
  }) {
    final constructorName = isForm ? 'fromForm' : 'fromSimple';

    if (normalizedProperties.isEmpty) {
      return Constructor(
        (b) => b
          ..factory = true
          ..name = constructorName
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

    final constructorArgs = <String, Expression>{};

    for (final normalized in normalizedProperties) {
      final name = normalized.normalizedName;
      final modelType = normalized.property.model;

      final expression = isForm
          ? buildFromFormValueExpression(
              refer('value'),
              model: modelType,
              isRequired: !normalized.property.isNullable,
              nameManager: nameManager,
              package: package,
              contextClass: className,
              contextProperty: name,
              explode: refer('explode'),
              useImmutableCollections: useImmutableCollections,
            )
          : buildSimpleValueExpression(
              refer('value'),
              model: modelType,
              isRequired: !normalized.property.isNullable,
              nameManager: nameManager,
              package: package,
              contextClass: className,
              contextProperty: name,
              explode: refer('explode'),
            );

      constructorArgs[name] = expression;
    }

    final captureAP = _hasStringCapturableAP(model);

    if (!captureAP) {
      return Constructor(
        (b) => b
          ..factory = true
          ..name = constructorName
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
          ..body = refer(className)
              .call([], constructorArgs)
              .returned
              .statement,
      );
    }

    final apFieldName = pickAdditionalPropertiesFieldName(
      normalizedProperties,
    );
    final knownKeys = collectKnownKeys(model);
    final listKeys = collectListKeys(model);
    final separator = isForm ? '&' : ',';

    final knownKeysLiteral = knownKeys.map((k) => "r'$k'").join(', ');
    final expectedKeysExpr =
        literalSet(knownKeys.map(specLiteralString));
    final listKeysExpr = literalSet(listKeys.map(specLiteralString));

    final strRef = refer('String', 'dart:core');

    final codes = <Code>[
      declareFinal(r'_$values')
          .assign(
            refer('value').property('decodeObject').call([], {
              'explode': refer('explode'),
              'explodeSeparator': literalString(separator),
              'expectedKeys': expectedKeysExpr,
              'listKeys': listKeysExpr,
              'context': specLiteralString(className),
              'captureAdditionalKeys': literalTrue,
            }),
          )
          .statement,
      Code('const _\$knownKeys = {$knownKeysLiteral};'),
      declareFinal(r'_$additional')
          .assign(literalMap({}, strRef, strRef))
          .statement,
      const Code(r'for (final _$entry in _$values.entries) {'),
      const Code(r'if (!_$knownKeys.contains(_$entry.key)) {'),
      Code(
        r'_$additional[_$entry.key] = _$entry.value.'
        '${isForm ? 'decodeFormString' : 'decodeSimpleString'}'
        "(context: r'$className.additionalProperties');",
      ),
      const Code('}'),
      const Code('}'),
    ];

    constructorArgs[apFieldName] = useImmutableCollections
        ? refer(r'_$additional').property('lock')
        : refer(r'_$additional');

    codes.add(
      refer(className).call([], constructorArgs).returned.statement,
    );

    return Constructor(
      (b) => b
        ..factory = true
        ..name = constructorName
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
        ..body = Block.of(codes),
    );
  }

  /// Whether the allOf model has additional properties that can be captured
  /// from string-based encodings (simple/form).
  ///
  /// Only unrestricted AP or typed AP with string values can be captured,
  /// since simple/form encoding produces string key-value pairs.
  bool _hasStringCapturableAP(AllOfModel model) {
    final ap = model.additionalProperties;
    if (ap is UnrestrictedAdditionalProperties) return true;
    if (ap is TypedAdditionalProperties) {
      final resolved = ap.valueModel.resolved;
      return resolved is StringModel;
    }
    return false;
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
      (prop) => prop.property.model.resolved is ListModel,
    );
    final allListProperties =
        hasListProperties &&
        normalizedProperties.every(
          (prop) => prop.property.model.resolved is ListModel,
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

    // Check if we have any map properties
    final hasMapProperties = normalizedProperties.any(
      (prop) => prop.property.model.resolved is MapModel,
    );

    if (hasMapProperties) {
      return Method(
        (b) => b
          ..name = 'parameterProperties'
          ..returns = buildMapStringStringType()
          ..optionalParameters.addAll([
            buildBoolParameter('allowEmpty', defaultValue: true),
            buildBoolParameter('allowLists', defaultValue: true),
          ])
          ..lambda = true
          ..body = generateEncodingExceptionExpression(
            'parameterProperties not supported for $className: '
            'contains map types',
            raw: true,
          ).code,
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
        r'_$mergedProperties',
      ).assign(buildEmptyMapStringString()).statement,
    ];

    for (final normalized in normalizedProperties) {
      final isNullable = normalized.property.model.isEffectivelyNullable;
      if (isNullable) {
        propertyMergingLines.addAll([
          Code('if (${normalized.normalizedName} != null) {'),
          refer(r'_$mergedProperties').property('addAll').call([
            refer(normalized.normalizedName).nullChecked
                .property(
                  'parameterProperties',
                )
                .call(
                  [],
                  {
                    'allowEmpty': refer('allowEmpty'),
                    'allowLists': refer('allowLists'),
                  },
                ),
          ]).statement,
          const Code('}'),
        ]);
      } else {
        propertyMergingLines.add(
          refer(r'_$mergedProperties').property('addAll').call([
            refer(normalized.normalizedName)
                .property(
                  'parameterProperties',
                )
                .call(
                  [],
                  {
                    'allowEmpty': refer('allowEmpty'),
                    'allowLists': refer('allowLists'),
                  },
                ),
          ]).statement,
        );
      }
    }

    propertyMergingLines
      ..addAll(
        _buildAdditionalPropertiesParameterLoop(model, normalizedProperties),
      )
      ..add(
        refer(r'_$mergedProperties').returned.statement,
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

  /// Builds the AP loop for parameterProperties in allOf models.
  List<Code> _buildAdditionalPropertiesParameterLoop(
    AllOfModel model,
    List<({String normalizedName, Property property})> normalizedProperties,
  ) {
    if (!hasActiveAdditionalProperties(model.additionalProperties)) return [];

    final apFieldName = pickAdditionalPropertiesFieldName(
      normalizedProperties,
    );
    final ap = model.additionalProperties;

    if (ap is TypedAdditionalProperties &&
        ap.valueModel.encodingShape == EncodingShape.simple) {
      final uriEncodeCall = ap.valueModel.isEffectivelyNullable
          ? r'_$e.value?.uriEncode(allowEmpty: allowEmpty) '
                "?? ''"
          : r'_$e.value.uriEncode(allowEmpty: allowEmpty)';
      return [
        Code('''
for (final _\$e in $apFieldName.entries) {
  _\$mergedProperties[_\$e.key] = $uriEncodeCall;
}'''),
      ];
    } else if (ap is UnrestrictedAdditionalProperties) {
      return [
        Code(
          'for (final _\$e in $apFieldName.entries) { '
          r"_$mergedProperties[_$e.key] = _$e.value?.toString() ?? ''; }",
        ),
      ];
    } else {
      // Typed with complex value model — throw
      return [
        Code(
          'if ($apFieldName.isNotEmpty) {',
        ),
        generateEncodingExceptionExpression(
          'Additional properties with complex types cannot be parameter '
          'encoded.',
          raw: true,
        ).statement,
        const Code('}'),
      ];
    }
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
                p.property.model.resolved is ListModel &&
                (p.property.model.resolved as ListModel).hasSimpleContent,
          );

      if (allComplexAreSimpleLists) {
        // Lists with simple content can be encoded directly with toSimple
        final valueCollectionCode = <Code>[
          declareFinal(
            r'_$values',
          ).assign(literalSet([], refer('String', 'dart:core'))).statement,
        ];

        for (final prop in normalizedProperties) {
          valueCollectionCode.addAll([
            declareFinal('_\$${prop.normalizedName}Simple')
                .assign(
                  buildSimpleParameterExpression(
                    refer(prop.normalizedName),
                    prop.property.model,
                    explode: refer('explode'),
                    allowEmpty: refer('allowEmpty'),
                  ),
                )
                .statement,
            refer(r'_$values').property('add').call([
              refer('_\$${prop.normalizedName}Simple'),
            ]).statement,
          ]);
        }

        valueCollectionCode.addAll([
          const Code(r'if (_$values.length > 1) {'),
          generateEncodingExceptionExpression(
            'Inconsistent allOf simple encoding: '
            'all values must encode to the same result',
          ).statement,
          const Code('}'),
          const Code(r'return _$values.first;'),
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
    final primarySimpleReceiver =
        primaryField.property.model.isEffectivelyNullable
        ? refer(primaryField.normalizedName).nullChecked
        : refer(primaryField.normalizedName);

    return Method(
      (b) => b
        ..annotations.add(refer('override', 'dart:core'))
        ..name = 'toSimple'
        ..returns = refer('String', 'dart:core')
        ..optionalParameters.addAll(buildEncodingParameters())
        ..lambda = false
        ..body = Block.of([
          primarySimpleReceiver
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
            r'_$values',
          ).assign(literalSet([], refer('String', 'dart:core'))).statement,
        ];

        // Call toForm on each property and collect results.
        for (final prop in normalizedProperties) {
          final isNullable = prop.property.model.isEffectivelyNullable;
          final receiver = isNullable
              ? refer(prop.normalizedName).nullChecked
              : refer(prop.normalizedName);
          bodyCode.addAll([
            declareFinal('_\$${prop.normalizedName}Form')
                .assign(
                  receiver.property('toForm').call([], {
                    'explode': refer('explode'),
                    'allowEmpty': refer('allowEmpty'),
                    'useQueryComponent': refer('useQueryComponent'),
                  }),
                )
                .statement,
            refer(r'_$values').property('add').call([
              refer('_\$${prop.normalizedName}Form'),
            ]).statement,
          ]);
        }

        bodyCode.addAll([
          const Code(r'if (_$values.length > 1) {'),
          generateEncodingExceptionExpression(
            'Inconsistent allOf form encoding for $className: '
            'all values must encode to the same result',
            raw: true,
          ).statement,
          const Code('}'),
          const Code(r'return _$values.first;'),
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
      // runtime. Generate runtime check and delegate to parameterProperties.
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
      ];

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
      final primaryFormRtReceiver =
          primaryField.property.model.isEffectivelyNullable
          ? refer(primaryField.normalizedName).nullChecked
          : refer(primaryField.normalizedName);
      validationCode.addAll([
        primaryFormRtReceiver
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
                  p.property.model.resolved is ListModel &&
                  (p.property.model.resolved as ListModel).hasSimpleContent,
            );

        if (allComplexAreSimpleLists) {
          // Lists with simple content can be encoded directly with toForm
          final valueCollectionCode = <Code>[
            declareFinal(
              r'_$values',
            ).assign(literalSet([], refer('String', 'dart:core'))).statement,
          ];

          for (final prop in normalizedProperties) {
            valueCollectionCode.addAll([
              declareFinal('_\$${prop.normalizedName}Form')
                  .assign(
                    buildFormParameterExpression(
                      refer(prop.normalizedName),
                      prop.property.model,
                      explode: refer('explode'),
                      allowEmpty: refer('allowEmpty'),
                    ),
                  )
                  .statement,
              refer(r'_$values').property('add').call([
                refer('_\$${prop.normalizedName}Form'),
              ]).statement,
            ]);
          }

          valueCollectionCode.addAll([
            const Code(r'if (_$values.length > 1) {'),
            generateEncodingExceptionExpression(
              'Inconsistent allOf form encoding: '
              'all values must encode to the same result',
              raw: true,
            ).statement,
            const Code('}'),
            const Code(r'return _$values.first;'),
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

      // If we have dynamic models, validate and delegate to
      // parameterProperties.
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

      bodyCode.add(
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
    final primaryFormReceiver =
        primaryField.property.model.isEffectivelyNullable
        ? refer(primaryField.normalizedName).nullChecked
        : refer(primaryField.normalizedName);

    return Method(
      (b) => b
        ..annotations.add(refer('override', 'dart:core'))
        ..name = 'toForm'
        ..returns = refer('String', 'dart:core')
        ..optionalParameters.addAll(buildFormEncodingParameters())
        ..lambda = false
        ..body = Block.of([
          primaryFormReceiver
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
      final primaryLabelRtReceiver =
          primaryField.property.model.isEffectivelyNullable
          ? refer(primaryField.normalizedName).nullChecked
          : refer(primaryField.normalizedName);
      validationCode.addAll([
        primaryLabelRtReceiver
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
                p.property.model.resolved is ListModel &&
                (p.property.model.resolved as ListModel).hasSimpleContent,
          );

      if (allComplexAreSimpleLists) {
        // Lists with simple content can be encoded directly with toLabel
        final valueCollectionCode = <Code>[
          declareFinal(
            r'_$values',
          ).assign(literalSet([], refer('String', 'dart:core'))).statement,
        ];

        for (final prop in normalizedProperties) {
          valueCollectionCode.addAll([
            declareFinal('_\$${prop.normalizedName}Label')
                .assign(
                  buildLabelParameterExpression(
                    refer(prop.normalizedName),
                    prop.property.model,
                    explode: refer('explode'),
                    allowEmpty: refer('allowEmpty'),
                  ),
                )
                .statement,
            refer(r'_$values').property('add').call([
              refer('_\$${prop.normalizedName}Label'),
            ]).statement,
          ]);
        }

        valueCollectionCode.addAll([
          const Code(r'if (_$values.length > 1) {'),
          generateEncodingExceptionExpression(
            'Inconsistent allOf label encoding: '
            'all values must encode to the same result',
          ).statement,
          const Code('}'),
          const Code(r'return _$values.first;'),
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
    final primaryLabelReceiver =
        primaryField.property.model.isEffectivelyNullable
        ? refer(primaryField.normalizedName).nullChecked
        : refer(primaryField.normalizedName);

    return Method(
      (b) => b
        ..annotations.add(refer('override', 'dart:core'))
        ..name = 'toLabel'
        ..returns = refer('String', 'dart:core')
        ..optionalParameters.addAll(buildEncodingParameters())
        ..lambda = false
        ..body = primaryLabelReceiver
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
        refer('parameterProperties')
            .call([], {'allowEmpty': refer('allowEmpty')})
            .property('toMatrix')
            .call([refer('paramName')], {
              'explode': refer('explode'),
              'allowEmpty': refer('allowEmpty'),
              'alreadyEncoded': literalBool(true),
            })
            .returned
            .statement,
      ];

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
                p.property.model.resolved is ListModel &&
                (p.property.model.resolved as ListModel).hasSimpleContent,
          );

      if (allComplexAreSimpleLists) {
        // Lists with simple content can be encoded directly with toMatrix
        final valueCollectionCode = <Code>[
          declareFinal(
            r'_$values',
          ).assign(literalSet([], refer('String', 'dart:core'))).statement,
        ];

        for (final prop in normalizedProperties) {
          valueCollectionCode.addAll([
            declareFinal('_\$${prop.normalizedName}Matrix')
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
            refer(r'_$values').property('add').call([
              refer('_\$${prop.normalizedName}Matrix'),
            ]).statement,
          ]);
        }

        valueCollectionCode.addAll([
          const Code(r'if (_$values.length > 1) {'),
          generateEncodingExceptionExpression(
            'Inconsistent allOf matrix encoding for $className: '
            'all values must encode to the same result',
            raw: true,
          ).statement,
          const Code('}'),
          const Code(r'return _$values.first;'),
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

      // For non-list complex types, delegate to parameterProperties
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
          ..body = refer('parameterProperties')
              .call([], {'allowEmpty': refer('allowEmpty')})
              .property('toMatrix')
              .call([refer('paramName')], {
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
        r'_$values',
      ).assign(literalSet([], refer('String', 'dart:core'))).statement,
    ];

    for (final prop in normalizedProperties) {
      valueCollectionCode.addAll([
        declareFinal('_\$${prop.normalizedName}Matrix')
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
        refer(r'_$values').property('add').call([
          refer('_\$${prop.normalizedName}Matrix'),
        ]).statement,
      ]);
    }

    valueCollectionCode.addAll([
      const Code(r'if (_$values.length > 1) {'),
      generateEncodingExceptionExpression(
        'Inconsistent allOf matrix encoding for $className: '
        'all values must encode to the same result',
        raw: true,
      ).statement,
      const Code('}'),
      const Code(r'return _$values.first;'),
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
        final receiver = simpleProp.property.model.isEffectivelyNullable
            ? refer(simpleProp.normalizedName).nullChecked
            : refer(simpleProp.normalizedName);
        bodyCode.add(
          receiver
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
        r'_$values',
      ).assign(literalSet([], refer('String', 'dart:core'))).statement,
    ];

    for (final prop in normalizedProperties) {
      final isNullable = prop.property.model.isEffectivelyNullable;
      final receiver = isNullable
          ? refer(prop.normalizedName).nullChecked
          : refer(prop.normalizedName);
      valueCollectionCode.addAll([
        declareFinal('_\$${prop.normalizedName}Encoded')
            .assign(
              receiver.property('uriEncode').call([], {
                'allowEmpty': refer('allowEmpty'),
                'useQueryComponent': refer('useQueryComponent'),
              }),
            )
            .statement,
        refer(r'_$values').property('add').call([
          refer('_\$${prop.normalizedName}Encoded'),
        ]).statement,
      ]);
    }

    valueCollectionCode.addAll([
      const Code(r'if (_$values.length > 1) {'),
      generateEncodingExceptionExpression(
        'Inconsistent allOf encoding for $className: '
        'all values must encode to the same result',
        raw: true,
      ).statement,
      const Code('}'),
      const Code(r'return _$values.first;'),
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
    AllOfModel model,
  ) {
    final copyWithProps = normalizedProperties.map((normalized) {
      final typeRef = typeReference(
        normalized.property.model,
        nameManager,
        package,
        isNullableOverride:
            normalized.property.isNullable ||
            !normalized.property.isRequired ||
            model.isReadOnly,
        useImmutableCollections: useImmutableCollections,
      );
      final propModel = normalized.property.model;
      final resolvedModel = propModel is AliasModel
          ? propModel.resolved
          : propModel;
      return (
        normalizedName: normalized.normalizedName,
        typeRef: typeRef,
        // Skip cast for AnyModel since its typedef is Object?
        skipCast: resolvedModel is AnyModel,
      );
    }).toList();

    if (hasActiveAdditionalProperties(model.additionalProperties)) {
      final apFieldName = pickAdditionalPropertiesFieldName(
        normalizedProperties,
      );
      copyWithProps.add(
        (
          normalizedName: apFieldName,
          typeRef: additionalPropertiesType(
            model.additionalProperties,
            nameManager,
            package,
            useImmutableCollections: useImmutableCollections,
          ),
          skipCast: false,
        ),
      );
    }

    return generateCopyWith(
      className: className,
      properties: copyWithProps,
    );
  }
}
