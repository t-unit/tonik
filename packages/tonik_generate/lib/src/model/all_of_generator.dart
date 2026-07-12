import 'package:code_builder/code_builder.dart';
import 'package:meta/meta.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/naming/name_utils.dart';
import 'package:tonik_generate/src/util/additional_properties_builders.dart';
import 'package:tonik_generate/src/util/additional_properties_helpers.dart';
import 'package:tonik_generate/src/util/built_expression.dart';
import 'package:tonik_generate/src/util/composite_guard_builders.dart';
import 'package:tonik_generate/src/util/composite_library_builder.dart';
import 'package:tonik_generate/src/util/copy_with_method_generator.dart';
import 'package:tonik_generate/src/util/equals_method_generator.dart';
import 'package:tonik_generate/src/util/example_doc_formatter.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';
import 'package:tonik_generate/src/util/flat_value_codec_plan.dart';
import 'package:tonik_generate/src/util/form_entries_expression_builder.dart';
import 'package:tonik_generate/src/util/from_form_value_expression_generator.dart';
import 'package:tonik_generate/src/util/from_json_value_expression_generator.dart';
import 'package:tonik_generate/src/util/from_simple_value_expression_generator.dart';
import 'package:tonik_generate/src/util/hash_code_generator.dart';
import 'package:tonik_generate/src/util/inline_helper_context.dart';
import 'package:tonik_generate/src/util/known_keys_collector.dart';
import 'package:tonik_generate/src/util/spec_literal_string.dart';
import 'package:tonik_generate/src/util/to_json_value_expression_generator.dart';
import 'package:tonik_generate/src/util/to_label_parameter_expression_generator.dart';
import 'package:tonik_generate/src/util/to_matrix_parameter_expression_generator.dart';
import 'package:tonik_generate/src/util/to_simple_parameter_expression_generator.dart';
import 'package:tonik_generate/src/util/type_reference_generator.dart';
import 'package:tonik_generate/src/util/uri_encode_expression_generator.dart';
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
        examples: const [],
        defaultValue: null,
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

    // Nullable public aliases need a Raw-prefixed concrete class.
    final actualClassName =
        className ??
        (model.isNullable
            ? nameManager.modelName(
                AliasModel(
                  name: '\$Raw$publicClassName',
                  model: model,
                  context: model.context,
                  defaultValue: null,
                  examples: const [],
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
        examples: const [],
        defaultValue: null,
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
          ..docs.addAll(
            formatDocsWithExamples(model.description, model.examples),
          )
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

    final fieldApPolicy = activeApPolicy(model.additionalPropertiesPolicy);
    if (fieldApPolicy != null) {
      final apFieldName = nameManager.additionalPropertiesFieldName(
        normalizedProperties,
      );
      fields.add(
        Field(
          (b) => b
            ..name = apFieldName
            ..modifier = FieldModifier.final$
            ..type = apMapTypeReference(
              fieldApPolicy.valueModel,
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
        hasCollectionValue:
            !useImmutableCollections &&
            isCollectionModel(normalized.property.model),
      );
    }).toList();

    if (model != null &&
        activeApPolicy(model.additionalPropertiesPolicy) != null) {
      final apFieldName = nameManager.additionalPropertiesFieldName(
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
        if (activeApPolicy(model.additionalPropertiesPolicy) != null) {
          final apFieldName = nameManager.additionalPropertiesFieldName(
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
    final helperContext = InlineHelperContext(nameManager: nameManager);

    final fromJsonParams = <Expression>[];
    final fieldNames = <String>[];
    final inlineHelpers = <InlineHelper>[];
    for (final normalized in normalizedProperties) {
      fieldNames.add(normalized.normalizedName);
      final built = buildFromJsonValueExpression(
        'json',
        model: normalized.property.model,
        nameManager: nameManager,
        package: package,
        helperContext: helperContext,
        contextClass: className,
        useImmutableCollections: useImmutableCollections,
      );
      inlineHelpers.addAll(built.inlineFunctions);
      fromJsonParams.add(built.unsafeRawBody);
    }

    final hasAP = activeApPolicy(model.additionalPropertiesPolicy) != null;

    if (!hasAP) {
      final returnStatement = refer(className)
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
          .statement;
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
          ..body = Block.of([
            ...spliceInlineHelpers(inlineHelpers),
            returnStatement,
          ]),
      );
    }

    // With additional properties: decode map, collect unknown keys
    final apFieldName = nameManager.additionalPropertiesFieldName(
      normalizedProperties,
    );

    final apPolicy = activeApPolicy(model.additionalPropertiesPolicy)!;
    final codes = <Code>[
      Code(
        r"final _$map = json.decodeMap(context: r'"
        "$className');",
      ),
    ];

    final capture = buildApJsonCaptureLoop(
      AdditionalPropertiesPlan(
        valueModel: apPolicy.valueModel,
        knownWireKeys: collectKnownKeys(model),
      ),
      sourceMapVar: r'_$map',
      nameManager: nameManager,
      package: package,
      contextClass: className,
      helperContext: helperContext,
      useImmutableCollections: useImmutableCollections,
    );
    inlineHelpers.addAll(capture.inlineHelpers);
    codes.addAll(capture.codes);

    final constructorArgs = Map.fromEntries(
      List.generate(
        fromJsonParams.length,
        (i) => MapEntry(fieldNames[i], fromJsonParams[i]),
      ),
    );
    constructorArgs[apFieldName] = useImmutableCollections
        ? refer(
            'IMap',
            'package:fast_immutable_collections/'
                'fast_immutable_collections.dart',
          ).call([refer(r'_$additional')])
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
        ..body = Block.of([
          ...spliceInlineHelpers(inlineHelpers),
          ...codes,
        ]),
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

    // Mixed nested models require runtime shape selection.
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
        final isFieldNullable =
            prop.property.isNullable ||
            !prop.property.isRequired ||
            prop.property.model.isEffectivelyNullable;
        if (isFieldNullable) {
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
        (prop) =>
            prop.property.isNullable ||
            !prop.property.isRequired ||
            prop.property.model.isEffectivelyNullable,
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

    // Static shapes can be emitted as a constant getter.
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
    final helperContext = InlineHelperContext(nameManager: nameManager);
    final inlineHelpers = <InlineHelper>[];

    // Arrays need to be rejected before object-style allOf merging.
    final hasListProperties = normalizedProperties.any(
      (prop) => prop.property.model.resolved is ListModel,
    );
    final allListProperties =
        hasListProperties &&
        normalizedProperties.every(
          (prop) => prop.property.model.resolved is ListModel,
        );

    // JSON cannot merge array and object allOf branches safely.
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
        final built = buildToJsonPropertyExpression(
          fieldName,
          normalized.property,
          nameManager: nameManager,
          package: package,
          helperContext: helperContext,
          contextClass: className,
          contextProperty: normalized.property.name,
          useImmutableCollections: useImmutableCollections,
        );
        inlineHelpers.addAll(built.inlineFunctions);

        jsonParts.addAll([
          Code('final $fieldNameJson = '),
          built.unsafeRawBody.code,
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
          ..body = Block.of([
            ...spliceInlineHelpers(inlineHelpers),
            ...jsonParts,
          ]),
      );
    }

    // Mixed nested models require runtime shape selection.
    final hasDynamicModels = normalizedProperties.any((prop) {
      return prop.property.model.encodingShape == EncodingShape.mixed;
    });

    if (hasDynamicModels) {
      // Runtime shape checks keep mixed allOf from using simple encoders.
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

        final toJsonBuilt = buildToJsonPropertyExpression(
          fieldName,
          normalized.property,
          nameManager: nameManager,
          package: package,
          helperContext: helperContext,
          contextClass: className,
          contextProperty: normalized.property.name,
          forceNonNullReceiver: isNullable,
          useImmutableCollections: useImmutableCollections,
        );
        inlineHelpers.addAll(toJsonBuilt.inlineFunctions);

        final isMapModel = normalized.property.model.resolved is MapModel;

        if (isMapModel) {
          // MapModel properties are already compile-time typed as Map,
          // so no runtime type check is needed.
          bodyCode.addAll([
            Code('final $fieldNameJson = '),
            toJsonBuilt.unsafeRawBody.code,
            const Code(';'),
            const Code(r'_$map.addAll('),
            refer(fieldNameJson).code,
            const Code(');'),
          ]);
        } else {
          bodyCode.addAll([
            Code('final $fieldNameJson = '),
            toJsonBuilt.unsafeRawBody.code,
            const Code(';'),
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
        }
        if (isNullable) {
          bodyCode.add(const Code('}'));
        }
      }

      final apPolicy = activeApPolicy(model.additionalPropertiesPolicy);
      if (apPolicy != null) {
        final apFieldName = nameManager.additionalPropertiesFieldName(
          normalizedProperties,
        );
        final apEncode = buildApJsonEncode(
          AdditionalPropertiesPlan(
            valueModel: apPolicy.valueModel,
            knownWireKeys: collectKnownKeys(model),
          ),
          targetMapVar: r'_$map',
          apAccess: apFieldName,
          nameManager: nameManager,
          package: package,
          contextClass: className,
          helperContext: helperContext,
          useImmutableCollections: useImmutableCollections,
        );
        inlineHelpers.addAll(apEncode.inlineHelpers);
        bodyCode.addAll(apEncode.codes);
      }

      bodyCode.add(const Code(r'return _$map;'));

      return Method(
        (b) => b
          ..annotations.add(refer('override', 'dart:core'))
          ..returns = refer('Object?', 'dart:core')
          ..name = 'toJson'
          ..lambda = false
          ..body = Block.of([
            ...spliceInlineHelpers(inlineHelpers),
            ...bodyCode,
          ]),
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
        final simpleBuilt = buildToJsonPropertyExpression(
          firstFieldName,
          Property(
            name: firstFieldName,
            model: firstModel,
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
          nameManager: nameManager,
          package: package,
          helperContext: helperContext,
          contextClass: className,
          contextProperty: firstFieldName,
          useImmutableCollections: useImmutableCollections,
        );
        inlineHelpers.addAll(simpleBuilt.inlineFunctions);

        if (inlineHelpers.isEmpty) {
          return Method(
            (b) => b
              ..annotations.add(refer('override', 'dart:core'))
              ..returns = refer('Object?', 'dart:core')
              ..name = 'toJson'
              ..lambda = true
              ..body = simpleBuilt.unsafeRawBody.code,
          );
        }
        return Method(
          (b) => b
            ..annotations.add(refer('override', 'dart:core'))
            ..returns = refer('Object?', 'dart:core')
            ..name = 'toJson'
            ..lambda = false
            ..body = Block.of([
              ...spliceInlineHelpers(inlineHelpers),
              const Code('return '),
              simpleBuilt.unsafeRawBody.code,
              const Code(';'),
            ]),
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

          final toJsonBuilt = buildToJsonPropertyExpression(
            fieldName,
            normalized.property,
            nameManager: nameManager,
            package: package,
            helperContext: helperContext,
            contextClass: className,
            contextProperty: normalized.property.name,
            forceNonNullReceiver: isNullable,
            useImmutableCollections: useImmutableCollections,
          );
          inlineHelpers.addAll(toJsonBuilt.inlineFunctions);

          final isMapModel = normalized.property.model.resolved is MapModel;

          if (isMapModel) {
            // MapModel properties are already compile-time typed as Map,
            // so no runtime type check is needed.
            mapParts.addAll([
              Code('final $fieldNameJson = '),
              toJsonBuilt.unsafeRawBody.code,
              const Code(';'),
              const Code(r'_$map.addAll('),
              refer(fieldNameJson).code,
              const Code(');'),
            ]);
          } else {
            mapParts.addAll([
              Code('final $fieldNameJson = '),
              toJsonBuilt.unsafeRawBody.code,
              const Code(';'),
              const Code('if ('),
              refer(fieldNameJson).code,
              const Code(' is! '),
              mapType.code,
              const Code(') {'),
              generateEncodingExceptionExpression(
                'Expected '
                '${fieldName.replaceAll(r'$', r'\$')}.toJson() to '
                'return Map<String, Object?>, '
                'got \${$fieldNameJson.runtimeType}',
              ).statement,
              const Code('}'),
              const Code(r'_$map.addAll('),
              refer(fieldNameJson).code,
              const Code(');'),
            ]);
          }
          if (isNullable) {
            mapParts.add(const Code('}'));
          }
        }

        final mixedApPolicy = activeApPolicy(model.additionalPropertiesPolicy);
        if (mixedApPolicy != null) {
          final apFieldName = nameManager.additionalPropertiesFieldName(
            normalizedProperties,
          );
          final apEncode = buildApJsonEncode(
            AdditionalPropertiesPlan(
              valueModel: mixedApPolicy.valueModel,
              knownWireKeys: collectKnownKeys(model),
            ),
            targetMapVar: r'_$map',
            apAccess: apFieldName,
            nameManager: nameManager,
            package: package,
            contextClass: className,
            helperContext: helperContext,
            useImmutableCollections: useImmutableCollections,
          );
          inlineHelpers.addAll(apEncode.inlineHelpers);
          mapParts.addAll(apEncode.codes);
        }

        mapParts.add(const Code(r'return _$map;'));

        return Method(
          (b) => b
            ..annotations.add(refer('override', 'dart:core'))
            ..returns = refer('Object?', 'dart:core')
            ..name = 'toJson'
            ..lambda = false
            ..body = Block.of([
              ...spliceInlineHelpers(inlineHelpers),
              ...mapParts,
            ]),
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

      constructorArgs[name] = expression.expression;
    }

    final apPolicy = activeApPolicy(model.additionalPropertiesPolicy);

    if (apPolicy == null) {
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
          ..body = refer(
            className,
          ).call([], constructorArgs).returned.statement,
      );
    }

    final apFieldName = nameManager.additionalPropertiesFieldName(
      normalizedProperties,
    );
    final knownKeys = collectKnownKeys(model);
    final listKeys = collectListKeys(model);
    final separator = isForm ? '&' : ',';

    final expectedKeysExpr = literalSet(knownKeys.map(specLiteralString));
    final listKeysExpr = literalSet(listKeys.map(specLiteralString));

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
    ];

    final capture = buildApFlatCaptureLoop(
      AdditionalPropertiesPlan(
        valueModel: apPolicy.valueModel,
        knownWireKeys: knownKeys,
      ),
      format: isForm ? FlatWireFormat.form : FlatWireFormat.simple,
      sourceMapVar: r'_$values',
      nameManager: nameManager,
      package: package,
      contextClass: className,
      useImmutableCollections: useImmutableCollections,
    );
    codes.addAll(capture.codes);

    switch (capture) {
      case CapturingApFlatCapture():
        constructorArgs[apFieldName] = useImmutableCollections
            ? refer(
                'IMap',
                'package:fast_immutable_collections/'
                    'fast_immutable_collections.dart',
              ).call([refer(r'_$additional')])
            : refer(r'_$additional');
      case RejectingApFlatCapture():
        break;
    }

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

  Method _buildParameterPropertiesMethod(
    String className,
    List<({String normalizedName, Property property})> normalizedProperties,
    AllOfModel model,
  ) {
    if (normalizedProperties.isEmpty &&
        activeApPolicy(model.additionalPropertiesPolicy) == null) {
      return Method(
        (b) => b
          ..name = 'parameterProperties'
          ..returns = buildMapStringPropertyValueType()
          ..optionalParameters.addAll(buildParameterPropertiesParameters())
          ..body = buildEmptyMapStringPropertyValue().returned.statement,
      );
    }

    // Arrays need to be rejected before simple scalar handling.
    final hasListProperties = normalizedProperties.any(
      (prop) => prop.property.model.resolved is ListModel,
    );
    final allListProperties =
        hasListProperties &&
        normalizedProperties.every(
          (prop) => prop.property.model.resolved is ListModel,
        );

    if (hasListProperties) {
      final message = allListProperties
          ? 'parameterProperties not supported for $className: contains '
                'array types'
          : 'parameterProperties not supported for $className: allOf '
                'mixing arrays with other types is not supported';

      return Method(
        (b) => b
          ..name = 'parameterProperties'
          ..returns = buildMapStringPropertyValueType()
          ..optionalParameters.addAll(buildParameterPropertiesParameters())
          ..lambda = true
          ..body = generateEncodingExceptionExpression(message, raw: true).code,
      );
    }

    // Maps cannot be represented as flat parameterProperties.
    final hasMapProperties = normalizedProperties.any(
      (prop) => prop.property.model.resolved is MapModel,
    );

    if (hasMapProperties) {
      return Method(
        (b) => b
          ..name = 'parameterProperties'
          ..returns = buildMapStringPropertyValueType()
          ..optionalParameters.addAll(buildParameterPropertiesParameters())
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
          ..returns = buildMapStringPropertyValueType()
          ..optionalParameters.addAll(buildParameterPropertiesParameters())
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
      ).assign(buildEmptyMapStringPropertyValue()).statement,
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
                .call([], {'allowEmpty': refer('allowEmpty')}),
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
                .call([], {'allowEmpty': refer('allowEmpty')}),
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
        ..returns = buildMapStringPropertyValueType()
        ..optionalParameters.addAll(buildParameterPropertiesParameters())
        ..body = Block.of(propertyMergingLines),
    );
  }

  /// Builds the AP loop for parameterProperties in allOf models.
  List<Code> _buildAdditionalPropertiesParameterLoop(
    AllOfModel model,
    List<({String normalizedName, Property property})> normalizedProperties,
  ) {
    final apPolicy = activeApPolicy(model.additionalPropertiesPolicy);
    if (apPolicy == null) return [];

    final apFieldName = nameManager.additionalPropertiesFieldName(
      normalizedProperties,
    );
    final className = nameManager.modelName(model);

    return buildApPropertyValueEntries(
      AdditionalPropertiesPlan(
        valueModel: apPolicy.valueModel,
        knownWireKeys: collectKnownKeys(model),
      ),
      targetVar: r'_$mergedProperties',
      apAccess: apFieldName,
      contextClass: className,
      useImmutableCollections: useImmutableCollections,
    ).codes;
  }

  Method _buildToSimpleMethod(
    List<({String normalizedName, Property property})> normalizedProperties,
    AllOfModel model,
  ) {
    // Mixed nested models require runtime shape selection.
    final hasDynamicModels = normalizedProperties.any((prop) {
      return prop.property.model.encodingShape == EncodingShape.mixed;
    });

    if (hasDynamicModels) {
      // Runtime shape checks keep mixed allOf from using simple encoders.
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
          'explode: explode, allowEmpty: allowEmpty, literal: literal);',
        ),
      ];

      return Method(
        (b) => b
          ..annotations.add(refer('override', 'dart:core'))
          ..name = 'toSimple'
          ..returns = refer('String', 'dart:core')
          ..optionalParameters.addAll(buildSimpleEncodingParameters())
          ..lambda = false
          ..body = Block.of(bodyCode),
      );
    }

    if (model.cannotBeSimplyEncoded) {
      return Method(
        (b) => b
          ..annotations.add(refer('override', 'dart:core'))
          ..name = 'toSimple'
          ..returns = refer('String', 'dart:core')
          ..optionalParameters.addAll(buildSimpleEncodingParameters())
          ..lambda = false
          ..body = generateEncodingExceptionExpression(
            'Simple encoding not supported: contains complex types',
          ).statement,
      );
    }

    if (model.hasComplexTypes) {
      // Simple-list branches are the only complex branches supported here.
      final allComplexAreSimpleLists = normalizedProperties
          .where((p) => p.property.model.encodingShape == EncodingShape.complex)
          .every(
            (p) =>
                p.property.model.resolved is ListModel &&
                (p.property.model.resolved as ListModel).hasSimpleContent,
      );

      if (allComplexAreSimpleLists) {
        final valueCollectionCode = <Code>[
          declareFinal(
            r'_$values',
          ).assign(literalSet([], refer('String', 'dart:core'))).statement,
        ];

        final allNullable = normalizedProperties.every((prop) {
          return prop.property.isNullable ||
              !prop.property.isRequired ||
              prop.property.model.isEffectivelyNullable;
        });
        for (final prop in normalizedProperties) {
          final isFieldNullable =
              prop.property.isNullable ||
              !prop.property.isRequired ||
              prop.property.model.isEffectivelyNullable;
          final receiver = isFieldNullable
              ? refer(prop.normalizedName).nullChecked
              : refer(prop.normalizedName);
          valueCollectionCode.addAll([
            if (isFieldNullable) Code('if (${prop.normalizedName} != null) {'),
            declareFinal('_\$${prop.normalizedName}Simple')
                .assign(
                  buildSimpleParameterExpression(
                    receiver,
                    prop.property.model,
                    explode: refer('explode'),
                    allowEmpty: refer('allowEmpty'),
                    literal: refer('literal'),
                  ).expression,
                )
                .statement,
            refer(r'_$values').property('add').call([
              refer('_\$${prop.normalizedName}Simple'),
            ]).statement,
            if (isFieldNullable) const Code('}'),
          ]);
        }

        valueCollectionCode.addAll([
          const Code(r'if (_$values.length > 1) {'),
          generateEncodingExceptionExpression(
            'Inconsistent allOf simple encoding: '
            'all values must encode to the same result',
          ).statement,
          const Code('}'),
          if (allNullable) ...[
            const Code(r'if (_$values.isEmpty) {'),
            generateEncodingExceptionExpression(
              'Cannot encode to simple: all properties are null',
            ).statement,
            const Code('}'),
          ],
          const Code(r'return _$values.first;'),
        ]);

        return Method(
          (b) => b
            ..annotations.add(refer('override', 'dart:core'))
            ..name = 'toSimple'
            ..returns = refer('String', 'dart:core')
            ..optionalParameters.addAll(buildSimpleEncodingParameters())
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
          ..optionalParameters.addAll(buildSimpleEncodingParameters())
          ..lambda = false
          ..body = Block.of([
            refer('parameterProperties')
                .call([], {'allowEmpty': refer('allowEmpty')})
                .property('toSimple')
                .call([], {
                  'explode': refer('explode'),
                  'allowEmpty': refer('allowEmpty'),
                  'literal': refer('literal'),
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
          ..optionalParameters.addAll(buildSimpleEncodingParameters())
          ..lambda = false
          ..body = const Code("return '';"),
      );
    }

    final primaryField = normalizedProperties.first;
    final isPrimaryFieldNullable =
        primaryField.property.isNullable ||
        !primaryField.property.isRequired ||
        primaryField.property.model.isEffectivelyNullable;
    final primarySimpleReceiver = isPrimaryFieldNullable
        ? refer(primaryField.normalizedName).nullChecked
        : refer(primaryField.normalizedName);
    final primaryResolved = primaryField.property.model.resolved;

    final Code simpleBody;
    if (primaryResolved is Base64Model) {
      simpleBody = primarySimpleReceiver
          .property('toBase64String')
          .call([])
          .property('toSimple')
          .call([], {
            'explode': refer('explode'),
            'allowEmpty': refer('allowEmpty'),
            'literal': refer('literal'),
          })
          .returned
          .statement;
    } else if (primaryResolved is BinaryModel) {
      simpleBody = generateEncodingExceptionExpression(
        'Binary data cannot be simple-encoded',
      ).statement;
    } else {
      simpleBody = primarySimpleReceiver
          .property('toSimple')
          .call([], {
            'explode': refer('explode'),
            'allowEmpty': refer('allowEmpty'),
            'literal': refer('literal'),
          })
          .returned
          .statement;
    }

    return Method(
      (b) => b
        ..annotations.add(refer('override', 'dart:core'))
        ..name = 'toSimple'
        ..returns = refer('String', 'dart:core')
        ..optionalParameters.addAll(buildSimpleEncodingParameters())
        ..lambda = false
        ..body = Block.of([simpleBody]),
    );
  }

  Method _buildToFormMethod(
    String className,
    List<({String normalizedName, Property property})> normalizedProperties,
    AllOfModel model,
  ) {
    Method form(Iterable<Code> body) => Method(
      (b) => b
        ..annotations.add(refer('override', 'dart:core'))
        ..name = 'toForm'
        ..returns = buildParameterEntryListType()
        ..requiredParameters.add(
          Parameter(
            (b) => b
              ..name = 'paramName'
              ..type = refer('String', 'dart:core'),
          ),
        )
        ..optionalParameters.addAll(buildFormEncodingParameters())
        ..lambda = false
        ..body = Block.of(body),
    );

    final emptyEntries = <Code>[
      const Code('return const <'),
      refer('ParameterEntry', 'package:tonik_util/tonik_util.dart').code,
      const Code('>[];'),
    ];

    bool isNullableProp(({String normalizedName, Property property}) prop) =>
        prop.property.isNullable ||
        !prop.property.isRequired ||
        prop.property.model.isEffectivelyNullable;

    final mixedGuard = <Code>[
      const Code('if (currentEncodingShape == '),
      refer(
        'EncodingShape',
        'package:tonik_util/tonik_util.dart',
      ).property('mixed').code,
      const Code(') {'),
      generateEncodingExceptionExpression(
        'Cannot encode $className: mixing simple values '
        '(primitives/enums) and complex types is not supported',
        raw: true,
      ).statement,
      const Code('}'),
    ];

    Expression propFormEntries(Expression receiver, Model propModel) {
      final resolved = propModel.resolved;
      if (resolved is ListModel && resolved.hasSimpleContent) {
        final entries = buildFormEntriesValueExpression(
          receiver,
          propModel,
          paramName: refer('paramName'),
          explode: refer('explode'),
          allowEmpty: refer('allowEmpty'),
          useQueryComponent: refer('useQueryComponent'),
        );
        if (entries != null) return entries;
        return generateEncodingExceptionExpression(
          'Lists with complex content are not supported for encoding',
        );
      }
      if (resolved is Base64Model) {
        return receiver
            .property('toBase64String')
            .call([])
            .property('toForm')
            .call(
              [refer('paramName')],
              {
                'explode': refer('explode'),
                'allowEmpty': refer('allowEmpty'),
                'useQueryComponent': refer('useQueryComponent'),
                'allowReserved': refer('allowReserved'),
              },
            );
      }
      if (resolved is BinaryModel) {
        return generateEncodingExceptionExpression(
          'Binary data cannot be form-encoded',
        );
      }
      return receiver
          .property('toForm')
          .call(
            [refer('paramName')],
            {
              'explode': refer('explode'),
              'allowEmpty': refer('allowEmpty'),
              'useQueryComponent': refer('useQueryComponent'),
              'allowReserved': refer('allowReserved'),
            },
          );
    }

    List<Code> collectAndReturn(
      Iterable<({String normalizedName, Property property})> props, {
      required String inconsistentMessage,
    }) {
      final code = <Code>[
        declareFinal(
          r'_$entryLists',
        ).assign(literalList([], buildParameterEntryListType())).statement,
        declareFinal(
          r'_$values',
        ).assign(literalSet([], refer('String', 'dart:core'))).statement,
      ];

      final allNullable = props.every(isNullableProp);

      for (final prop in props) {
        final nullable = isNullableProp(prop);
        final receiver = nullable
            ? refer(prop.normalizedName).nullChecked
            : refer(prop.normalizedName);
        final entries = propFormEntries(receiver, prop.property.model);
        code.addAll([
          if (nullable) Code('if (${prop.normalizedName} != null) {'),
          declareFinal(
            '_\$${prop.normalizedName}Form',
          ).assign(entries).statement,
          refer(r'_$entryLists').property('add').call([
            refer('_\$${prop.normalizedName}Form'),
          ]).statement,
          refer(r'_$values').property('add').call([
            refer('_\$${prop.normalizedName}Form')
                .property('map')
                .call([
                  Method(
                    (b) => b
                      ..requiredParameters.add(
                        Parameter((p) => p..name = 'e'),
                      )
                      ..body = refer('e').property('value').code,
                  ).closure,
                ])
                .property('join')
                .call([literalString(',')]),
          ]).statement,
          if (nullable) const Code('}'),
        ]);
      }

      code.addAll([
        const Code(r'if (_$values.length > 1) {'),
        generateEncodingExceptionExpression(
          inconsistentMessage,
          raw: true,
        ).statement,
        const Code('}'),
        if (allNullable) ...[
          const Code(r'if (_$entryLists.isEmpty) {'),
          generateEncodingExceptionExpression(
            'Cannot encode $className to encoding: all properties are null',
            raw: true,
          ).statement,
          const Code('}'),
        ],
        const Code(r'return _$entryLists.first;'),
      ]);

      return code;
    }

    final delegateToParameterProperties = refer('parameterProperties')
        .call([], {'allowEmpty': refer('allowEmpty')})
        .property('toForm')
        .call(
          [refer('paramName')],
          {
            'explode': refer('explode'),
            'allowEmpty': refer('allowEmpty'),
            'useQueryComponent': refer('useQueryComponent'),
            'allowReserved': refer('allowReserved'),
            'fieldEncodings': refer('fieldEncodings'),
          },
        )
        .returned
        .statement;

    final hasDynamicModels = normalizedProperties.any(
      (prop) => prop.property.model.encodingShape == EncodingShape.mixed,
    );

    if (hasDynamicModels) {
      final hasDirectPrimitives = normalizedProperties.any(
        (prop) => prop.property.model.encodingShape == EncodingShape.simple,
      );

      if (hasDirectPrimitives) {
        return form([
          ...mixedGuard,
          ...collectAndReturn(
            normalizedProperties,
            inconsistentMessage:
                'Inconsistent allOf form encoding for $className: '
                'all values must encode to the same result',
          ),
        ]);
      }

      return form([...mixedGuard, delegateToParameterProperties]);
    }

    if (model.hasComplexTypes) {
      if (model.hasSimpleTypes) {
        return form([
          generateEncodingExceptionExpression(
            'Form encoding not supported: contains complex types',
          ).statement,
        ]);
      }

      final allComplexAreSimpleLists = normalizedProperties
          .where((p) => p.property.model.encodingShape == EncodingShape.complex)
          .every(
            (p) =>
                p.property.model.resolved is ListModel &&
                (p.property.model.resolved as ListModel).hasSimpleContent,
          );

      if (allComplexAreSimpleLists) {
        return form(
          collectAndReturn(
            normalizedProperties,
            inconsistentMessage:
                'Inconsistent allOf form encoding: '
                'all values must encode to the same result',
          ),
        );
      }

      return form([delegateToParameterProperties]);
    }

    if (normalizedProperties.isEmpty) {
      return form(emptyEntries);
    }

    final primaryField = normalizedProperties.first;
    final primaryReceiver = isNullableProp(primaryField)
        ? refer(primaryField.normalizedName).nullChecked
        : refer(primaryField.normalizedName);

    return form([
      propFormEntries(
        primaryReceiver,
        primaryField.property.model,
      ).returned.statement,
    ]);
  }

  Method _buildToLabelMethod(
    String className,
    List<({String normalizedName, Property property})> normalizedProperties,
    AllOfModel model,
  ) {
    // Mixed nested models require runtime shape validation.
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
          'explode: explode, allowEmpty: allowEmpty);',
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
      final isPrimaryFieldNullable =
          primaryField.property.isNullable ||
          !primaryField.property.isRequired ||
          primaryField.property.model.isEffectivelyNullable;
      final primaryLabelRtReceiver = isPrimaryFieldNullable
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
      // Simple-list branches are the only complex branches supported here.
      final allComplexAreSimpleLists = normalizedProperties
          .where((p) => p.property.model.encodingShape == EncodingShape.complex)
          .every(
            (p) =>
                p.property.model.resolved is ListModel &&
                (p.property.model.resolved as ListModel).hasSimpleContent,
      );

      if (allComplexAreSimpleLists) {
        final valueCollectionCode = <Code>[
          declareFinal(
            r'_$values',
          ).assign(literalSet([], refer('String', 'dart:core'))).statement,
        ];

        final allNullableLabel = normalizedProperties.every((prop) {
          return prop.property.isNullable ||
              !prop.property.isRequired ||
              prop.property.model.isEffectivelyNullable;
        });
        for (final prop in normalizedProperties) {
          final isFieldNullable =
              prop.property.isNullable ||
              !prop.property.isRequired ||
              prop.property.model.isEffectivelyNullable;
          final receiver = isFieldNullable
              ? refer(prop.normalizedName).nullChecked
              : refer(prop.normalizedName);
          valueCollectionCode.addAll([
            if (isFieldNullable) Code('if (${prop.normalizedName} != null) {'),
            declareFinal('_\$${prop.normalizedName}Label')
                .assign(
                  buildLabelParameterExpression(
                    receiver,
                    prop.property.model,
                    explode: refer('explode'),
                    allowEmpty: refer('allowEmpty'),
                  ).expression,
                )
                .statement,
            refer(r'_$values').property('add').call([
              refer('_\$${prop.normalizedName}Label'),
            ]).statement,
            if (isFieldNullable) const Code('}'),
          ]);
        }

        valueCollectionCode.addAll([
          const Code(r'if (_$values.length > 1) {'),
          generateEncodingExceptionExpression(
            'Inconsistent allOf label encoding: '
            'all values must encode to the same result',
          ).statement,
          const Code('}'),
          if (allNullableLabel) ...[
            const Code(r'if (_$values.isEmpty) {'),
            generateEncodingExceptionExpression(
              'Cannot encode $className to encoding: all properties are null',
              raw: true,
            ).statement,
            const Code('}'),
          ],
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
    final isPrimaryFieldNullable =
        primaryField.property.isNullable ||
        !primaryField.property.isRequired ||
        primaryField.property.model.isEffectivelyNullable;
    final primaryLabelReceiver = isPrimaryFieldNullable
        ? refer(primaryField.normalizedName).nullChecked
        : refer(primaryField.normalizedName);
    final primaryResolved = primaryField.property.model.resolved;

    final Code labelBody;
    if (primaryResolved is Base64Model) {
      labelBody = primaryLabelReceiver
          .property('toBase64String')
          .call([])
          .property('toLabel')
          .call([], {
            'explode': refer('explode'),
            'allowEmpty': refer('allowEmpty'),
          })
          .returned
          .statement;
    } else if (primaryResolved is BinaryModel) {
      labelBody = generateEncodingExceptionExpression(
        'Binary data cannot be label-encoded',
      ).statement;
    } else {
      labelBody = primaryLabelReceiver
          .property('toLabel')
          .call([], {
            'explode': refer('explode'),
            'allowEmpty': refer('allowEmpty'),
          })
          .returned
          .statement;
    }

    return Method(
      (b) => b
        ..annotations.add(refer('override', 'dart:core'))
        ..name = 'toLabel'
        ..returns = refer('String', 'dart:core')
        ..optionalParameters.addAll(buildEncodingParameters())
        ..lambda = false
        ..body = labelBody,
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
            .call(
              [refer('paramName')],
              {
                'explode': refer('explode'),
                'allowEmpty': refer('allowEmpty'),
              },
            )
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
      // Simple-list branches are the only complex branches supported here.
      final allComplexAreSimpleLists = normalizedProperties
          .where((p) => p.property.model.encodingShape == EncodingShape.complex)
          .every(
            (p) =>
                p.property.model.resolved is ListModel &&
                (p.property.model.resolved as ListModel).hasSimpleContent,
      );

      if (allComplexAreSimpleLists) {
        final valueCollectionCode = <Code>[
          declareFinal(
            r'_$values',
          ).assign(literalSet([], refer('String', 'dart:core'))).statement,
        ];

        final allNullableMatrix = normalizedProperties.every((prop) {
          return prop.property.isNullable ||
              !prop.property.isRequired ||
              prop.property.model.isEffectivelyNullable;
        });
        for (final prop in normalizedProperties) {
          final isFieldNullable =
              prop.property.isNullable ||
              !prop.property.isRequired ||
              prop.property.model.isEffectivelyNullable;
          final receiver = isFieldNullable
              ? refer(prop.normalizedName).nullChecked
              : refer(prop.normalizedName);
          valueCollectionCode.addAll([
            if (isFieldNullable) Code('if (${prop.normalizedName} != null) {'),
            declareFinal('_\$${prop.normalizedName}Matrix')
                .assign(
                  buildMatrixParameterExpression(
                    receiver,
                    prop.property.model,
                    paramName: refer('paramName'),
                    explode: refer('explode'),
                    allowEmpty: refer('allowEmpty'),
                  ).expression,
                )
                .statement,
            refer(r'_$values').property('add').call([
              refer('_\$${prop.normalizedName}Matrix'),
            ]).statement,
            if (isFieldNullable) const Code('}'),
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
          if (allNullableMatrix) ...[
            const Code(r'if (_$values.isEmpty) {'),
            generateEncodingExceptionExpression(
              'Cannot encode $className to encoding: all properties are null',
              raw: true,
            ).statement,
            const Code('}'),
          ],
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

    final allNullableMatrixPrim = normalizedProperties.every((prop) {
      return prop.property.isNullable ||
          !prop.property.isRequired ||
          prop.property.model.isEffectivelyNullable;
    });
    for (final prop in normalizedProperties) {
      final isFieldNullable =
          prop.property.isNullable ||
          !prop.property.isRequired ||
          prop.property.model.isEffectivelyNullable;
      final receiver = isFieldNullable
          ? refer(prop.normalizedName).nullChecked
          : refer(prop.normalizedName);
      valueCollectionCode.addAll([
        if (isFieldNullable) Code('if (${prop.normalizedName} != null) {'),
        declareFinal('_\$${prop.normalizedName}Matrix')
            .assign(
              buildMatrixParameterExpression(
                receiver,
                prop.property.model,
                paramName: refer('paramName'),
                explode: refer('explode'),
                allowEmpty: refer('allowEmpty'),
              ).expression,
            )
            .statement,
        refer(r'_$values').property('add').call([
          refer('_\$${prop.normalizedName}Matrix'),
        ]).statement,
        if (isFieldNullable) const Code('}'),
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
      if (allNullableMatrixPrim) ...[
        const Code(r'if (_$values.isEmpty) {'),
        generateEncodingExceptionExpression(
          'Cannot encode $className to encoding: all properties are null',
          raw: true,
        ).statement,
        const Code('}'),
      ],
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
        final isSimplePropNullable =
            simpleProp.property.isNullable ||
            !simpleProp.property.isRequired ||
            simpleProp.property.model.isEffectivelyNullable;
        final receiver = isSimplePropNullable
            ? refer(simpleProp.normalizedName).nullChecked
            : refer(simpleProp.normalizedName);
        bodyCode.add(
          uriEncodeReceiverExpression(simpleProp.property.model, receiver)
              .property('uriEncode')
              .call([], {
                'allowEmpty': refer('allowEmpty'),
                'useQueryComponent': refer('useQueryComponent'),
                'allowReserved': refer('allowReserved'),
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
          ..optionalParameters.addAll(buildUriEncodeParameters())
          ..lambda = false
          ..body = Block.of(bodyCode),
      );
    }

    // URI encoding only supports simple property shapes.
    final hasComplexProperties = normalizedProperties.any((prop) {
      return prop.property.model.encodingShape == EncodingShape.complex;
    });

    if (model.cannotBeSimplyEncoded || hasComplexProperties) {
      return Method(
        (b) => b
          ..annotations.add(refer('override', 'dart:core'))
          ..name = 'uriEncode'
          ..returns = refer('String', 'dart:core')
          ..optionalParameters.addAll(buildUriEncodeParameters())
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
          ..optionalParameters.addAll(buildUriEncodeParameters())
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

    final allNullableUri = normalizedProperties.every((prop) {
      return prop.property.isNullable ||
          !prop.property.isRequired ||
          prop.property.model.isEffectivelyNullable;
    });
    for (final prop in normalizedProperties) {
      final isNullable =
          prop.property.isNullable ||
          !prop.property.isRequired ||
          prop.property.model.isEffectivelyNullable;
      final receiver = isNullable
          ? refer(prop.normalizedName).nullChecked
          : refer(prop.normalizedName);
      valueCollectionCode.addAll([
        if (isNullable) Code('if (${prop.normalizedName} != null) {'),
        declareFinal('_\$${prop.normalizedName}Encoded')
            .assign(
              uriEncodeReceiverExpression(
                prop.property.model,
                receiver,
              ).property('uriEncode').call([], {
                'allowEmpty': refer('allowEmpty'),
                'useQueryComponent': refer('useQueryComponent'),
                'allowReserved': refer('allowReserved'),
              }),
            )
            .statement,
        refer(r'_$values').property('add').call([
          refer('_\$${prop.normalizedName}Encoded'),
        ]).statement,
        if (isNullable) const Code('}'),
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
      if (allNullableUri) ...[
        const Code(r'if (_$values.isEmpty) {'),
        generateEncodingExceptionExpression(
          'Cannot encode $className to encoding: all properties are null',
          raw: true,
        ).statement,
        const Code('}'),
      ],
      const Code(r'return _$values.first;'),
    ]);

    return Method(
      (b) => b
        ..annotations.add(refer('override', 'dart:core'))
        ..name = 'uriEncode'
        ..returns = refer('String', 'dart:core')
        ..optionalParameters.addAll(buildUriEncodeParameters())
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

    final copyWithApPolicy = activeApPolicy(model.additionalPropertiesPolicy);
    if (copyWithApPolicy != null) {
      final apFieldName = nameManager.additionalPropertiesFieldName(
        normalizedProperties,
      );
      copyWithProps.add(
        (
          normalizedName: apFieldName,
          typeRef: apMapTypeReference(
            copyWithApPolicy.valueModel,
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
