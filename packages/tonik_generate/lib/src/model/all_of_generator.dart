import 'package:code_builder/code_builder.dart';
import 'package:meta/meta.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/naming/name_utils.dart';
import 'package:tonik_generate/src/naming/property_name_normalizer.dart';
import 'package:tonik_generate/src/util/additional_properties_helpers.dart';
import 'package:tonik_generate/src/util/built_expression.dart';
import 'package:tonik_generate/src/util/composite_guard_builders.dart';
import 'package:tonik_generate/src/util/composite_library_builder.dart';
import 'package:tonik_generate/src/util/copy_with_method_generator.dart';
import 'package:tonik_generate/src/util/equals_method_generator.dart';
import 'package:tonik_generate/src/util/example_doc_formatter.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';
import 'package:tonik_generate/src/util/form_entries_expression_builder.dart';
import 'package:tonik_generate/src/util/form_exploded_values_generator.dart';
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
    final normalizedProperties = _memberFields(model);

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
                  defaultValue: null,
                  examples: const [],
                ),
              )
            : publicClassName);

    final normalizedProperties = _memberFields(model);
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

  /// The normalized fields, one per allOf member, that back the generated
  /// class. Shared by class generation and exploded-values access so the two
  /// cannot drift on member field names.
  List<({String normalizedName, Property property})> _memberFields(
    AllOfModel model,
  ) {
    final pseudo = stableModelSorter.sortModels(model.models).map((m) {
      final isNullable = m.isEffectivelyNullable;
      return Property(
        name: typeReference(
          m,
          nameManager,
          package,
          useImmutableCollections: useImmutableCollections,
        ).symbol,
        model: m,
        isRequired: !isNullable,
        isNullable: isNullable,
        isDeprecated: false,
        examples: const [],
        defaultValue: null,
      );
    }).toList();
    return _normalizeModelProperties(pseudo);
  }

  /// Collects the simple-content array properties reachable through the allOf's
  /// object members — the exact set the request-body call site marks `explode`
  /// via its field encodings — keeping the exploded-values channel and that
  /// field encoding activating the same properties. Direct array members are
  /// excluded: [_buildParameterPropertiesMethod] rejects them, so the call site
  /// never activates them and any exploded-values entry would be dead.
  ///
  /// The counterpart traversal is `_collectFormProperties` in
  /// `to_form_value_expression_generator.dart`, which builds the request-body
  /// field-encoding descriptors: both must walk the same property set in
  /// lock-step or the exploded-values entries and the descriptors diverge.
  List<FormPropertyBinding> _collectExplodedArrayBindings(
    List<({String normalizedName, Property property})> members,
  ) {
    final bindings = <FormPropertyBinding>[];
    for (final member in members) {
      final root = refer(member.normalizedName);
      final nullable = member.property.model.isEffectivelyNullable;
      _collectArrayBindings(
        member.property.model,
        field: root,
        receiverNullable: nullable,
        memberGuard: nullable ? root : null,
        into: bindings,
      );
    }
    return bindings;
  }

  /// Descends nested allOf members and one level of a member's ClassModel
  /// properties, accumulating a force-unwrapped value access ([field]) and a
  /// parallel null-safe access to the member ([memberGuard]) so a nullable
  /// composition link short-circuits the null test while the mapped value stays
  /// non-nullable.
  ///
  /// [memberGuard] is null-safe access to the member that owns the reached
  /// property, or null when no composition link on the path is nullable. The
  /// leaf array property's own nullability is captured separately (as the
  /// binding's `leafGuard`) so the merge fold can tell an absent member from a
  /// present member with a null array — the two resolve to different winners.
  ///
  /// [receiverNullable] is the nullability of the immediate [field] receiver —
  /// whether the link that produced it was nullable, not whether any earlier
  /// link was. Force-unwrapping and null-aware access are decided per link from
  /// this, so a non-nullable link nested under a nullable one emits neither an
  /// unnecessary `!` nor a `?.` on a non-nullable receiver.
  void _collectArrayBindings(
    Model memberModel, {
    required Expression field,
    required bool receiverNullable,
    required Expression? memberGuard,
    required List<FormPropertyBinding> into,
  }) {
    Expression descendField(String name) => receiverNullable
        ? field.nullChecked.property(name)
        : field.property(name);

    switch (memberModel.resolved) {
      case final ClassModel m:
        for (final p in normalizeProperties(m.properties.toList())) {
          if (!isExplodedFormArrayProperty(p.property)) continue;
          final listModel = p.property.model as ListModel;
          final leafAccess = descendField(p.normalizedName);
          final leafNullable =
              isSchemaAwareFieldNullable(
                p.property,
                memberIsReadOnly: m.isReadOnly,
              ) ||
              listModel.isNullable;
          into.add((
            field: leafNullable ? leafAccess.nullChecked : leafAccess,
            memberGuard: memberGuard,
            leafGuard: leafNullable ? leafAccess : null,
            property: p.property,
          ));
        }
      case final AllOfModel m:
        for (final member in _memberFields(m)) {
          final linkNullable = member.property.model.isEffectivelyNullable;
          final nestedGuard = memberGuard != null
              ? memberGuard.nullSafeProperty(member.normalizedName)
              : (linkNullable ? field.property(member.normalizedName) : null);
          _collectArrayBindings(
            member.property.model,
            field: descendField(member.normalizedName),
            receiverNullable: linkNullable,
            memberGuard: nestedGuard,
            into: into,
          );
        }
      default:
        break;
    }
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
      final apFieldName = nameManager.additionalPropertiesFieldName(
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
        hasCollectionValue:
            !useImmutableCollections &&
            isCollectionModel(normalized.property.model),
      );
    }).toList();

    if (model != null &&
        hasActiveAdditionalProperties(model.additionalProperties)) {
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
        if (hasActiveAdditionalProperties(model.additionalProperties)) {
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

    final hasAP = hasActiveAdditionalProperties(model.additionalProperties);

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
      useImmutableCollections: useImmutableCollections,
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
      final decodeBuilt = buildFromJsonValueExpression(
        r'_$entry.value',
        model: ap.valueModel,
        nameManager: nameManager,
        package: package,
        helperContext: helperContext,
        contextClass: className,
        contextProperty: 'additionalProperties',
        useImmutableCollections: useImmutableCollections,
      );
      inlineHelpers.addAll(decodeBuilt.inlineFunctions);
      codes.addAll([
        const Code(r'for (final _$entry in _$map.entries) {'),
        const Code(r'if (!_$knownKeys.contains(_$entry.key)) {'),
        const Code(r'_$additional[_$entry.key] = '),
        decodeBuilt.unsafeRawBody.code,
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
    final helperContext = InlineHelperContext(nameManager: nameManager);
    final inlineHelpers = <InlineHelper>[];

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

      if (hasActiveAdditionalProperties(model.additionalProperties)) {
        final apFieldName = nameManager.additionalPropertiesFieldName(
          normalizedProperties,
        );
        final ap = model.additionalProperties;
        final apAccess = useImmutableCollections
            ? '$apFieldName.unlock'
            : apFieldName;
        if (ap is TypedAdditionalProperties) {
          final apBuilt = buildToJsonAdditionalPropertiesExpression(
            apFieldName,
            ap.valueModel,
            nameManager: nameManager,
            package: package,
            helperContext: helperContext,
            contextClass: className,
            useImmutableCollections: useImmutableCollections,
          );
          inlineHelpers.addAll(apBuilt.inlineFunctions);
          bodyCode.addAll([
            const Code(r'_$map.addAll('),
            apBuilt.unsafeRawBody.code,
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

        if (hasActiveAdditionalProperties(model.additionalProperties)) {
          final apFieldName = nameManager.additionalPropertiesFieldName(
            normalizedProperties,
          );
          final ap = model.additionalProperties;
          final apAccess = useImmutableCollections
              ? '$apFieldName.unlock'
              : apFieldName;
          if (ap is TypedAdditionalProperties) {
            final apBuilt = buildToJsonAdditionalPropertiesExpression(
              apFieldName,
              ap.valueModel,
              nameManager: nameManager,
              package: package,
              helperContext: helperContext,
              contextClass: className,
              useImmutableCollections: useImmutableCollections,
            );
            inlineHelpers.addAll(apBuilt.inlineFunctions);
            mapParts.addAll([
              const Code(r'_$map.addAll('),
              apBuilt.unsafeRawBody.code,
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

    final knownKeysLiteral = knownKeys.map((k) => "r'$k'").join(', ');
    final expectedKeysExpr = literalSet(knownKeys.map(specLiteralString));
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
      declareFinal(
        r'_$additional',
      ).assign(literalMap({}, strRef, strRef)).statement,
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
          ..optionalParameters.addAll(buildParameterPropertiesParameters())
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
          ..optionalParameters.addAll(buildParameterPropertiesParameters())
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
          ..returns = buildMapStringStringType()
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
                    'allowReserved': refer('allowReserved'),
                    'fieldEncodings': refer('fieldEncodings'),
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
                    'allowReserved': refer('allowReserved'),
                    'fieldEncodings': refer('fieldEncodings'),
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
        ..optionalParameters.addAll(buildParameterPropertiesParameters())
        ..body = Block.of(propertyMergingLines),
    );
  }

  /// Builds the AP loop for parameterProperties in allOf models.
  List<Code> _buildAdditionalPropertiesParameterLoop(
    AllOfModel model,
    List<({String normalizedName, Property property})> normalizedProperties,
  ) {
    if (!hasActiveAdditionalProperties(model.additionalProperties)) return [];

    final apFieldName = nameManager.additionalPropertiesFieldName(
      normalizedProperties,
    );
    final ap = model.additionalProperties;

    if (ap is TypedAdditionalProperties &&
        ap.valueModel.encodingShape == EncodingShape.simple) {
      final uriEncodeCall = ap.valueModel.isEffectivelyNullable
          ? '${uriEncodeReceiver(ap.valueModel, r'_$e.value?')}'
                '.uriEncode(allowEmpty: allowEmpty, '
                "allowReserved: allowReserved) ?? ''"
          : '${uriEncodeReceiver(ap.valueModel, r'_$e.value')}'
                '.uriEncode(allowEmpty: allowEmpty, '
                'allowReserved: allowReserved)';
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
          })
          .returned
          .statement;
    }

    return Method(
      (b) => b
        ..annotations.add(refer('override', 'dart:core'))
        ..name = 'toSimple'
        ..returns = refer('String', 'dart:core')
        ..optionalParameters.addAll(buildEncodingParameters())
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
            .call([refer('paramName')], {
              'explode': refer('explode'),
              'allowEmpty': refer('allowEmpty'),
              'useQueryComponent': refer('useQueryComponent'),
              'allowReserved': refer('allowReserved'),
            });
      }
      if (resolved is BinaryModel) {
        return generateEncodingExceptionExpression(
          'Binary data cannot be form-encoded',
        );
      }
      return receiver.property('toForm').call([refer('paramName')], {
        'explode': refer('explode'),
        'allowEmpty': refer('allowEmpty'),
        'useQueryComponent': refer('useQueryComponent'),
        'allowReserved': refer('allowReserved'),
      });
    }

    List<Code> collectAndReturn(
      Iterable<({String normalizedName, Property property})> props, {
      required String inconsistentMessage,
    }) {
      final code = <Code>[
        declareFinal(r'_$entryLists')
            .assign(literalList([], buildParameterEntryListType()))
            .statement,
        declareFinal(r'_$values')
            .assign(literalSet([], refer('String', 'dart:core')))
            .statement,
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
          declareFinal('_\$${prop.normalizedName}Form')
              .assign(entries)
              .statement,
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

    final explodedValues = buildFormExplodedValuesLiteral(
      _collectExplodedArrayBindings(normalizedProperties),
      useImmutableCollections: useImmutableCollections,
    );

    final delegateToParameterProperties = refer('parameterProperties')
        .call([], {
          'allowEmpty': refer('allowEmpty'),
          'allowReserved': refer('allowReserved'),
          'fieldEncodings': refer('fieldEncodings'),
        })
        .property('toForm')
        .call([refer('paramName')], {
          'explode': refer('explode'),
          'allowEmpty': refer('allowEmpty'),
          'alreadyEncoded': literalBool(true),
          'useQueryComponent': refer('useQueryComponent'),
          'fieldEncodings': refer('fieldEncodings'),
          'explodedValues': ?explodedValues,
        })
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
                'alreadyEncoded': literalBool(true),
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
                  'alreadyEncoded': literalBool(true),
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
              uriEncodeReceiverExpression(prop.property.model, receiver)
                  .property('uriEncode')
                  .call([], {
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

    if (hasActiveAdditionalProperties(model.additionalProperties)) {
      final apFieldName = nameManager.additionalPropertiesFieldName(
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
