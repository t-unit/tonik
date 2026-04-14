import 'package:change_case/change_case.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:meta/meta.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/naming/property_name_normalizer.dart';
import 'package:tonik_generate/src/util/additional_properties_helpers.dart';
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
import 'package:tonik_generate/src/util/spec_literal_string.dart';
import 'package:tonik_generate/src/util/to_json_value_expression_generator.dart';
import 'package:tonik_generate/src/util/type_reference_generator.dart';
import 'package:tonik_generate/src/util/uri_encode_expression_generator.dart';
import 'package:tonik_util/tonik_util.dart';

/// A generator for creating Dart class files from model definitions.
@immutable
class ClassGenerator {
  const ClassGenerator({
    required this.nameManager,
    required this.package,
    this.useImmutableCollections = false,
  });

  final NameManager nameManager;
  final String package;
  final bool useImmutableCollections;

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
      model,
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
    final hasAP = hasActiveAdditionalProperties(model.additionalProperties);
    final apFieldName = pickAdditionalPropertiesFieldName(normalizedProperties);

    final effectiveCopyWithGetter =
        copyWithGetter ??
        _buildCopyWith(className, normalizedProperties, model)?.getter;

    final sortedProperties = [...normalizedProperties]
      ..sort((a, b) {
        final aRequired =
            a.property.isRequired &&
            !a.property.isReadOnly &&
            !model.isReadOnly;
        final bRequired =
            b.property.isRequired &&
            !b.property.isReadOnly &&
            !model.isReadOnly;
        if (aRequired != bRequired) {
          return aRequired ? -1 : 1;
        }
        return normalizedProperties.indexOf(a) -
            normalizedProperties.indexOf(b);
      });

    // Build equality/hashCode property tuples including additional properties.
    // When useImmutableCollections is true, IList/IMap support native deep
    // equality so we do not need DeepCollectionEquality for those fields.
    final equalityProps = normalizedProperties
        .map(
          (prop) => (
            normalizedName: prop.normalizedName,
            hasCollectionValue: !useImmutableCollections &&
                isCollectionModel(prop.property.model),
          ),
        )
        .toList();
    if (hasAP) {
      equalityProps.add(
        (
          normalizedName: apFieldName,
          hasCollectionValue: !useImmutableCollections,
        ),
      );
    }

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
            (b) {
              b
                ..constant = true
                ..optionalParameters.addAll(
                  sortedProperties.map(
                    (prop) => Parameter(
                      (b) => b
                        ..name = prop.normalizedName
                        ..named = true
                        ..required =
                            prop.property.isRequired &&
                            !prop.property.isReadOnly &&
                            !model.isReadOnly
                        ..toThis = true,
                    ),
                  ),
                );
              if (hasAP) {
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
          ),
          _buildFromSimpleConstructor(className, model),
          _buildFromJsonConstructor(className, model),
          _buildFromFormConstructor(className, model),
        ]);

        b.methods.addAll([
          _buildToJsonMethod(model),
          ?effectiveCopyWithGetter,
          generateEqualsMethod(
            className: className,
            properties: equalityProps,
          ),
          generateHashCodeMethod(properties: equalityProps),
          _buildCurrentEncodingShapeGetter(),
          _buildParameterPropertiesMethod(
            model,
            normalizedProperties.where((p) => !p.property.isReadOnly).toList(),
          ),
          _buildToSimpleMethod(),
          _buildToFormMethod(),
          _buildToLabelMethod(),
          _buildToMatrixMethod(),
          _buildToDeepObjectMethod(),
        ]);

        b.fields.addAll(
          normalizedProperties.map(
            (prop) => _generateField(
              prop.property,
              prop.normalizedName,
              classModel: model,
            ),
          ),
        );

        if (hasAP) {
          b.fields.add(
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
      },
    );
  }

  CopyWithResult? _buildCopyWith(
    String className,
    List<({String normalizedName, Property property})> properties,
    ClassModel model,
  ) {
    final copyWithProps = properties.map(
      (prop) {
        final propModel = prop.property.model;
        final resolvedModel = propModel is AliasModel
            ? propModel.resolved
            : propModel;
        return (
          normalizedName: prop.normalizedName,
          typeRef: _getSchemaAwareTypeReference(prop.property, model),
          skipCast: resolvedModel is AnyModel,
        );
      },
    ).toList();

    if (hasActiveAdditionalProperties(model.additionalProperties)) {
      final apFieldName = pickAdditionalPropertiesFieldName(properties);
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

  Constructor _buildFromSimpleConstructor(String className, ClassModel model) {
    // Schema-level writeOnly: decoding is never valid.
    if (model.isWriteOnly) {
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
          ..lambda = true
          ..body = generateSimpleDecodingExceptionExpression(
            '$className is write-only and cannot be decoded.',
            raw: true,
          ).code,
      );
    }

    final readProperties = model.properties
        .where((p) => !p.isWriteOnly)
        .toList();
    final normalizedProperties = normalizeProperties(readProperties);
    final allProperties = normalizeProperties(model.properties.toList());
    final writeOnlyRequiredNames = normalizeProperties(
      model.properties.where((p) => p.isWriteOnly && p.isRequired).toList(),
    ).map((p) => p.normalizedName).toList();

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
          model.properties.isNotEmpty,
          allProperties,
          writeOnlyRequiredNames,
          model,
        ),
    );
  }

  Block _buildFromSimpleBody(
    String className,
    List<({String normalizedName, Property property})> properties,
    bool canBeSimplyEncoded,
    bool hasAnyProperties,
    List<({String normalizedName, Property property})> allProperties,
    List<String> writeOnlyRequiredNames,
    ClassModel classModel,
  ) {
    if (properties.isEmpty) {
      if (hasAnyProperties) {
        final constructorArgs = <String, Expression>{
          for (final prop in allProperties) prop.normalizedName: literalNull,
        };

        return Block.of([
          refer(className).call([], constructorArgs).returned.statement,
        ]);
      }
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
      final isRequired = prop.property.isRequired && !prop.property.isWriteOnly;
      final isNullable =
          prop.property.isNullable || modelType.isEffectivelyNullable;

      var expr = buildSimpleValueExpression(
        refer('_\$values[${specLiteralStringCode(propertyName)}]'),
        model: modelType,
        isRequired: isRequired && !isNullable,
        nameManager: nameManager,
        package: package,
        contextClass: className,
        contextProperty: propertyName,
        explode: refer('explode'),
      );

      if (useImmutableCollections && isCollectionModel(modelType)) {
        final effectivelyNullable = isNullable || !isRequired;
        expr = effectivelyNullable
            ? expr.nullSafeProperty('lock')
            : expr.property('lock');
      }

      constructorArgs[normalizedName] = expr;
    }

    for (final name in writeOnlyRequiredNames) {
      constructorArgs.putIfAbsent(name, () => literalNull);
    }

    // Build expectedKeys and listKeys sets
    final expectedKeys = properties.map((p) => p.property.name).toSet();
    final listKeys = properties
        .where((p) => p.property.model is ListModel)
        .map((p) => p.property.name)
        .toSet();

    final captureAP = _hasStringCapturableAP(classModel);
    final decodeObjectArgs = <String, Expression>{
      'explode': refer('explode'),
      'explodeSeparator': literalString(','),
      'expectedKeys': literalSet(expectedKeys.map(specLiteralString)),
      'listKeys': literalSet(listKeys.map(specLiteralString)),
      'context': specLiteralString(className),
    };
    if (captureAP) {
      decodeObjectArgs['captureAdditionalKeys'] = literalTrue;
    }

    final codes = <Code>[
      declareFinal(r'_$values')
          .assign(
            refer('value').property('decodeObject').call([], decodeObjectArgs),
          )
          .statement,
    ];

    final ap = classModel.additionalProperties;
    if (captureAP && ap != null) {
      final apFieldName = pickAdditionalPropertiesFieldName(allProperties);
      final knownKeySet = expectedKeys.map(specLiteralStringCode).join(', ');
      final mapType = additionalPropertiesType(ap, nameManager, package);
      codes.addAll([
        Code('const _\$knownKeys = {$knownKeySet};'),
        declareFinal(r'_$additional')
            .assign(
              literalMap(
                {},
                refer('String', 'dart:core'),
                mapType.types.last,
              ),
            )
            .statement,
        const Code(r'for (final _$entry in _$values.entries) {'),
        const Code(r'if (!_$knownKeys.contains(_$entry.key)) {'),
      ]);

      if (ap is TypedAdditionalProperties) {
        final decodeExpr = buildSimpleValueExpression(
          refer(r'_$entry').property('value'),
          model: ap.valueModel,
          isRequired: true,
          nameManager: nameManager,
          explode: refer('explode'),
          package: package,
          contextClass: className,
          contextProperty: 'additionalProperties',
        );
        codes.addAll([
          const Code(r'_$additional[_$entry.key] = '),
          decodeExpr.code,
          const Code(';'),
        ]);
      } else {
        codes.addAll([
          const Code(r'_$additional[_$entry.key] = '),
          refer(
            r'_$entry',
          ).property('value').property('decodeSimpleString').call([], {
            'context': specLiteralString(
              '$className.additionalProperties',
            ),
          }).code,
          const Code(';'),
        ]);
      }

      codes.addAll([
        const Code('}'),
        const Code('}'),
      ]);
      constructorArgs[apFieldName] = useImmutableCollections
          ? refer(r'_$additional').property('lock')
          : refer(r'_$additional');
    }

    codes.add(
      refer(className).call([], constructorArgs).returned.statement,
    );

    return Block.of(codes);
  }

  Constructor _buildFromJsonConstructor(String className, ClassModel model) {
    // Schema-level writeOnly: decoding is never valid.
    if (model.isWriteOnly) {
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
          ..lambda = true
          ..body = generateJsonDecodingExceptionExpression(
            '$className is write-only and cannot be decoded.',
            raw: true,
          ).code,
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
        ..body = _buildFromJsonBody(className, model),
    );
  }

  Code _buildFromJsonBody(String className, ClassModel model) {
    final normalizedProperties = normalizeProperties(
      model.properties.where((p) => !p.isWriteOnly).toList(),
    );
    final hasAP = hasActiveAdditionalProperties(model.additionalProperties);
    final apFieldName = hasAP
        ? pickAdditionalPropertiesFieldName(
            normalizeProperties(model.properties.toList()),
          )
        : null;

    // If there are no readable properties and no additional properties,
    // return an empty model.
    if (normalizedProperties.isEmpty && !hasAP) {
      if (model.properties.isNotEmpty) {
        final constructorArgs = <String, Expression>{
          for (final prop in normalizeProperties(model.properties.toList()))
            prop.normalizedName: literalNull,
        };

        return Block.of([
          refer(className).call([], constructorArgs).returned.statement,
        ]);
      }
      return Block.of([Code('return $className();')]);
    }

    final codes = <Code>[
      Code(
        r"final _$map = json.decodeMap(context: r'"
        "$className');",
      ),
    ];

    final propertyAssignments = <Code>[];

    for (final prop in normalizedProperties) {
      final property = prop.property;
      final normalizedName = prop.normalizedName;
      final jsonKey = property.name;
      final requiredInResponse = property.isRequired && !property.isWriteOnly;

      final valueExpression = buildFromJsonValueExpression(
        '_\$map[${specLiteralStringCode(jsonKey)}]',
        model: property.model,
        nameManager: nameManager,
        package: package,
        contextClass: className,
        contextProperty: jsonKey,
        isNullable:
            property.isNullable ||
            !requiredInResponse ||
            property.model.isEffectivelyNullable,
        useImmutableCollections: useImmutableCollections,
      );

      propertyAssignments
        ..add(Code('$normalizedName: '))
        ..add(valueExpression.code)
        ..add(const Code(','));
    }

    final writeOnlyRequiredProperties = normalizeProperties(
      model.properties.where((p) => p.isWriteOnly && p.isRequired).toList(),
    );

    for (final prop in writeOnlyRequiredProperties) {
      propertyAssignments
        ..add(Code('${prop.normalizedName}: '))
        ..add(literalNull.code)
        ..add(const Code(','));
    }

    // Collect additional properties from the JSON map.
    if (hasAP) {
      final knownKeys = model.properties
          .map((p) => specLiteralStringCode(p.name))
          .join(', ');
      codes.add(Code('const _\$knownKeys = {$knownKeys};'));

      final ap = model.additionalProperties;
      final mapType = additionalPropertiesType(
        model.additionalProperties,
        nameManager,
        package,
      );

      codes.addAll([
        declareFinal(r'_$additional')
            .assign(
              literalMap(
                {},
                refer('String', 'dart:core'),
                mapType.types.last,
              ),
            )
            .statement,
        const Code(r'for (final _$entry in _$map.entries) {'),
        const Code(r'if (!_$knownKeys.contains(_$entry.key)) {'),
      ]);

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
          const Code(r'_$additional[_$entry.key] = '),
          decodeExpr.code,
          const Code(';'),
        ]);
      } else {
        // Unrestricted: Map<String, Object?>
        codes.add(
          const Code(r'_$additional[_$entry.key] = _$entry.value;'),
        );
      }

      codes.addAll([
        const Code('}'),
        const Code('}'),
      ]);

      if (useImmutableCollections) {
        propertyAssignments
          ..add(Code('$apFieldName: '))
          ..add(const Code(r'_$additional.lock,'));
      } else {
        propertyAssignments
          ..add(Code('$apFieldName: '))
          ..add(const Code(r'_$additional,'));
      }
    }

    codes
      ..add(Code('return $className('))
      ..addAll(propertyAssignments)
      ..add(const Code(');'));

    return Block.of(codes);
  }

  Method _buildToJsonMethod(ClassModel model) {
    final className = nameManager.modelName(model);

    // Schema-level readOnly: encoding is never valid.
    if (model.isReadOnly) {
      return Method(
        (b) => b
          ..annotations.add(refer('override', 'dart:core'))
          ..name = 'toJson'
          ..returns = refer('Object?', 'dart:core')
          ..lambda = true
          ..body = generateEncodingExceptionExpression(
            '$className is read-only and cannot be encoded.',
            raw: true,
          ).code,
      );
    }

    final normalizedProperties = normalizeProperties(
      model.properties.where((p) => !p.isReadOnly).toList(),
    );

    final requiredWriteOnlyNonNullable = normalizedProperties
        .where(
          (p) =>
              p.property.isWriteOnly &&
              p.property.isRequired &&
              !p.property.isNullable,
        )
        .toList();

    // Build the map entries, handling optional properties with if-blocks
    final mapEntries = <Code>[];
    for (final prop in normalizedProperties) {
      final name = prop.normalizedName;
      final property = prop.property;
      final requiredInRequest = property.isRequired && !property.isReadOnly;
      final forceNonNullReceiver =
          property.isWriteOnly && requiredInRequest && !property.isNullable;

      final valueExpr = buildToJsonPropertyExpression(
        name,
        property,
        forceNonNullReceiver: forceNonNullReceiver,
        useImmutableCollections: useImmutableCollections,
      );

      final keyLiteral = specLiteralStringCode(property.name);
      if (!requiredInRequest && !property.isNullable) {
        mapEntries
          ..add(Code('if ($name != null) $keyLiteral: '))
          ..add(valueExpr.code)
          ..add(const Code(','));
      } else {
        mapEntries
          ..add(Code('$keyLiteral: '))
          ..add(valueExpr.code)
          ..add(const Code(','));
      }
    }

    if (hasActiveAdditionalProperties(model.additionalProperties)) {
      final allNormalized = normalizeProperties(model.properties.toList());
      final apFieldName = pickAdditionalPropertiesFieldName(allNormalized);
      final ap = model.additionalProperties;
      // When using immutable collections, unlock the IMap before spreading.
      final apAccess = useImmutableCollections
          ? '$apFieldName.unlock'
          : apFieldName;
      if (ap is TypedAdditionalProperties) {
        final valueModel = ap.valueModel;
        // For complex types, encode each value via toJson.
        // For simple/primitive types, pass through.
        if (valueModel.encodingShape == EncodingShape.complex) {
          mapEntries.add(
            Code.scope(
              (a) =>
                  '...$apAccess.map('
                  '(k, v) => ${a(refer('MapEntry', 'dart:core'))}'
                  '(k, v.toJson())),',
            ),
          );
        } else {
          mapEntries.add(Code('...$apAccess,'));
        }
      } else {
        // Unrestricted: values are already Object?
        mapEntries.add(Code('...$apAccess,'));
      }
    }

    if (requiredWriteOnlyNonNullable.isEmpty) {
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

    final nullChecks = <Code>[];
    for (final prop in requiredWriteOnlyNonNullable) {
      nullChecks
        ..add(Code('if (${prop.normalizedName} == null) {'))
        ..add(
          generateEncodingExceptionExpression(
            'Required property ${prop.property.name} is null.',
            raw: true,
          ).statement,
        )
        ..add(const Code('}'));
    }

    return Method(
      (b) => b
        ..annotations.add(refer('override', 'dart:core'))
        ..name = 'toJson'
        ..returns = refer('Object?', 'dart:core')
        ..body = Block.of([
          ...nullChecks,
          const Code('return {'),
          ...mapEntries,
          const Code('};'),
        ]),
    );
  }

  Field _generateField(
    Property property,
    String normalizedName, {
    ClassModel? classModel,
  }) {
    final fieldBuilder = FieldBuilder()
      ..name = normalizedName
      ..docs.addAll(formatDocComment(property.description))
      ..modifier = FieldModifier.final$
      ..type = classModel != null
          ? _getSchemaAwareTypeReference(property, classModel)
          : _getTypeReference(property);

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
      isNullableOverride:
          property.isNullable ||
          !property.isRequired ||
          property.isReadOnly ||
          property.isWriteOnly,
      useImmutableCollections: useImmutableCollections,
    );
  }

  /// Returns a type reference for a property, considering schema-level flags.
  TypeReference _getSchemaAwareTypeReference(
    Property property,
    ClassModel model,
  ) {
    return typeReference(
      property.model,
      nameManager,
      package,
      isNullableOverride:
          property.isNullable ||
          !property.isRequired ||
          property.isReadOnly ||
          property.isWriteOnly ||
          model.isReadOnly,
      useImmutableCollections: useImmutableCollections,
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

    // Schema-level readOnly: encoding is never valid.
    if (model.isReadOnly) {
      return Method(
        (b) => b
          ..name = 'parameterProperties'
          ..returns = buildMapStringStringType()
          ..optionalParameters.addAll(_buildParameterPropertiesParameters())
          ..lambda = true
          ..body = generateEncodingExceptionExpression(
            '$className is read-only and cannot be encoded.',
            raw: true,
          ).code,
      );
    }

    final hasOnlySimpleProperties = properties.every(
      (prop) => prop.property.model.encodingShape == EncodingShape.simple,
    );

    if (hasOnlySimpleProperties) {
      return _buildSimpleParameterPropertiesMethod(
        className,
        properties,
        model,
      );
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
        return _buildListParameterPropertiesMethod(
          className,
          properties,
          model,
        );
      }

      return _buildComplexParameterPropertiesMethod(className, properties);
    }

    return _buildMixedParameterPropertiesMethod(
      className,
      properties,
      model,
    );
  }

  List<Code> _buildAdditionalPropertiesParameterLoop(ClassModel model) {
    if (!hasActiveAdditionalProperties(model.additionalProperties)) return [];

    final allNormalized = normalizeProperties(model.properties.toList());
    final apFieldName = pickAdditionalPropertiesFieldName(allNormalized);
    final ap = model.additionalProperties;

    if (ap is TypedAdditionalProperties &&
        ap.valueModel.encodingShape == EncodingShape.simple) {
      final uriEncodeCall = ap.valueModel.isEffectivelyNullable
          ? r'_$e.value?.uriEncode(allowEmpty: allowEmpty, '
                "useQueryComponent: useQueryComponent) ?? ''"
          : r'_$e.value.uriEncode(allowEmpty: allowEmpty, '
                'useQueryComponent: useQueryComponent)';
      return [
        Code('''
for (final _\$e in $apFieldName.entries) {
  _\$result[_\$e.key] = $uriEncodeCall;
}'''),
      ];
    } else if (ap is UnrestrictedAdditionalProperties) {
      return [
        Code(
          'for (final _\$e in $apFieldName.entries) { '
          r"_$result[_$e.key] = _$e.value?.toString() ?? ''; }",
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
    ClassModel model,
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
      final isRequired = prop.property.isRequired && !prop.property.isReadOnly;
      final isNullable =
          prop.property.isNullable || prop.property.model.isEffectivelyNullable;
      final isFieldNullable = isNullable || prop.property.isWriteOnly;
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
        if (isFieldNullable) {
          propertyAssignments
            ..add(Code('if ($name == null) {'))
            ..add(
              generateEncodingExceptionExpression(
                'Required property $propertyName is null.',
                raw: true,
              ).statement,
            )
            ..add(const Code('}'))
            ..add(
              Code(
                '_\$result[${specLiteralStringCode(propertyName)}] = '
                '$name!.uriEncode(allowEmpty: allowEmpty, '
                'useQueryComponent: useQueryComponent);',
              ),
            );
        } else {
          propertyAssignments.add(
            Code(
              '_\$result[${specLiteralStringCode(propertyName)}] = '
              '$name.uriEncode(allowEmpty: allowEmpty, '
              'useQueryComponent: useQueryComponent);',
            ),
          );
        }
      } else if (isRequired && isNullable) {
        propertyAssignments.add(
          Code('''
if ($name != null) {
  _\$result[${specLiteralStringCode(propertyName)}] = $name!.uriEncode(allowEmpty: allowEmpty, useQueryComponent: useQueryComponent);
} else if (allowEmpty) {
  _\$result[${specLiteralStringCode(propertyName)}] = '';
}'''),
        );
      } else {
        propertyAssignments.add(
          Code('''
if ($name != null) {
  _\$result[${specLiteralStringCode(propertyName)}] = $name!.uriEncode(allowEmpty: allowEmpty, useQueryComponent: useQueryComponent);
} else if (allowEmpty) {
  _\$result[${specLiteralStringCode(propertyName)}] = '';
}'''),
        );
      }
    }

    final methodBody = [
      const Code(r'final _$result = '),
      buildEmptyMapStringString().statement,
      ...propertyAssignments,
      ..._buildAdditionalPropertiesParameterLoop(model),
      const Code(r'return _$result;'),
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
    ClassModel model,
  ) {
    final listProperties = properties
        .where(
          (p) =>
              p.property.model is ListModel &&
              (p.property.model as ListModel).hasSimpleContent,
        )
        .toList();

    final hasRequiredNonNullableLists = listProperties.any(
      (p) =>
          p.property.isRequired &&
          !p.property.isReadOnly &&
          !p.property.isNullable &&
          !p.property.model.isEffectivelyNullable,
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
      final isRequired = prop.property.isRequired && !prop.property.isReadOnly;
      final isNullable =
          prop.property.isNullable || fieldModel.isEffectivelyNullable;
      final isFieldNullable = isNullable || prop.property.isWriteOnly;

      if (fieldModel.encodingShape == EncodingShape.simple) {
        if (isRequired && !isNullable) {
          if (isFieldNullable) {
            propertyAssignments
              ..add(Code('if ($name == null) {'))
              ..add(
                generateEncodingExceptionExpression(
                  'Required property $propertyName is null.',
                  raw: true,
                ).statement,
              )
              ..add(const Code('}'))
              ..add(
                Code(
                  '_\$result[${specLiteralStringCode(propertyName)}] = '
                  '$name!.uriEncode(allowEmpty: allowEmpty, '
                  'useQueryComponent: useQueryComponent);',
                ),
              );
          } else {
            propertyAssignments.add(
              Code(
                '_\$result[${specLiteralStringCode(propertyName)}] = '
                '$name.uriEncode(allowEmpty: allowEmpty, '
                'useQueryComponent: useQueryComponent);',
              ),
            );
          }
        } else {
          propertyAssignments.add(
            Code('''
if ($name != null) {
  _\$result[${specLiteralStringCode(propertyName)}] = $name!.uriEncode(allowEmpty: allowEmpty, useQueryComponent: useQueryComponent);
} else if (allowEmpty) {
  _\$result[${specLiteralStringCode(propertyName)}] = '';
}'''),
          );
        }
      } else if (fieldModel is ListModel && fieldModel.hasSimpleContent) {
        final valueRef = (isRequired && !isNullable)
            ? (isFieldNullable ? refer(name).nullChecked : refer(name))
            : refer(name).nullChecked;
        final encodeExpr = buildUriEncodeExpression(
          valueRef,
          fieldModel,
          allowEmpty: refer('allowEmpty'),
          useQueryComponent: refer('useQueryComponent'),
          useImmutableCollections: useImmutableCollections,
        );

        final assignmentExpr = refer(
          r'_$result',
        ).index(specLiteralString(propertyName)).assign(encodeExpr);

        if (isRequired && !isNullable) {
          if (isFieldNullable) {
            propertyAssignments
              ..add(Code('if ($name == null) {'))
              ..add(
                generateEncodingExceptionExpression(
                  'Required property $propertyName is null.',
                  raw: true,
                ).statement,
              )
              ..add(const Code('}'));
          }
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
  _\$result[${specLiteralStringCode(propertyName)}] = '';
}'''),
            );
        }
      }
    }

    methodBody.addAll([
      const Code(r'final _$result = '),
      buildEmptyMapStringString().statement,
      ...propertyAssignments,
      ..._buildAdditionalPropertiesParameterLoop(model),
      const Code(r'return _$result;'),
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
    ClassModel model,
  ) {
    final propertyAssignments = <Code>[];

    for (final prop in properties) {
      final name = prop.normalizedName;
      final propertyName = prop.property.name;
      final isRequired = prop.property.isRequired && !prop.property.isReadOnly;
      final isNullable =
          prop.property.isNullable || prop.property.model.isEffectivelyNullable;
      final isFieldNullable = isNullable || prop.property.isWriteOnly;
      final model = prop.property.model;
      final resolvedModel = model is AliasModel ? model.resolved : model;

      if (resolvedModel is AnyModel) {
        propertyAssignments.add(
          Code(
            '_\$result[${specLiteralStringCode(propertyName)}] = '
            "$name?.toString() ?? '';",
          ),
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
          if (isFieldNullable) {
            propertyAssignments
              ..add(Code('if ($name == null) {'))
              ..add(
                generateEncodingExceptionExpression(
                  'Required property $propertyName is null.',
                  raw: true,
                ).statement,
              )
              ..add(const Code('}'))
              ..add(
                Code(
                  '_\$result[${specLiteralStringCode(propertyName)}] = '
                  '$name!.uriEncode(allowEmpty: allowEmpty, '
                  'useQueryComponent: useQueryComponent);',
                ),
              );
          } else {
            propertyAssignments.add(
              Code(
                '_\$result[${specLiteralStringCode(propertyName)}] = '
                '$name.uriEncode(allowEmpty: allowEmpty, '
                'useQueryComponent: useQueryComponent);',
              ),
            );
          }
        } else if (isRequired && isNullable) {
          propertyAssignments.add(
            Code('''
if ($name != null) {
  _\$result[${specLiteralStringCode(propertyName)}] = $name!.uriEncode(allowEmpty: allowEmpty, useQueryComponent: useQueryComponent);
} else if (allowEmpty) {
  _\$result[${specLiteralStringCode(propertyName)}] = '';
}'''),
          );
        } else {
          propertyAssignments.add(
            Code('''
if ($name != null) {
  _\$result[${specLiteralStringCode(propertyName)}] = $name!.uriEncode(allowEmpty: allowEmpty, useQueryComponent: useQueryComponent);
} else if (allowEmpty) {
  _\$result[${specLiteralStringCode(propertyName)}] = '';
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
              '    _\$result[${specLiteralStringCode(propertyName)}] = '
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
              '  _\$result[${specLiteralStringCode(propertyName)}] = '
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
      const Code(r'final _$result = '),
      buildEmptyMapStringString().statement,
      ...propertyAssignments,
      ..._buildAdditionalPropertiesParameterLoop(model),
      const Code(r'return _$result;'),
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
    // Schema-level writeOnly: decoding is never valid.
    if (model.isWriteOnly) {
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
          ..lambda = true
          ..body = generateFormDecodingExceptionExpression(
            '$className is write-only and cannot be decoded.',
            raw: true,
          ).code,
      );
    }

    final readProperties = model.properties
        .where((p) => !p.isWriteOnly)
        .toList();
    final normalizedProperties = normalizeProperties(readProperties);
    final allProperties = normalizeProperties(model.properties.toList());
    final writeOnlyRequiredNames = normalizeProperties(
      model.properties.where((p) => p.isWriteOnly && p.isRequired).toList(),
    ).map((p) => p.normalizedName).toList();

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
          model.properties.isNotEmpty,
          allProperties,
          writeOnlyRequiredNames,
          model,
        ),
    );
  }

  Block _buildFromFormBody(
    String className,
    List<({String normalizedName, Property property})> properties,
    bool canBeFormEncoded,
    bool hasAnyProperties,
    List<({String normalizedName, Property property})> allProperties,
    List<String> writeOnlyRequiredNames,
    ClassModel classModel,
  ) {
    if (properties.isEmpty) {
      if (hasAnyProperties) {
        final constructorArgs = <String, Expression>{
          for (final prop in allProperties) prop.normalizedName: literalNull,
        };

        return Block.of([
          refer(className).call([], constructorArgs).returned.statement,
        ]);
      }
      return Block.of([Code('return $className();')]);
    }

    if (!canBeFormEncoded) {
      return Block.of([
        generateFormDecodingExceptionExpression(
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
      final isRequired = prop.property.isRequired && !prop.property.isWriteOnly;
      final isNullable =
          prop.property.isNullable || modelType.isEffectivelyNullable;

      constructorArgs[normalizedName] = buildFromFormValueExpression(
        refer('_\$values[${specLiteralStringCode(propertyName)}]'),
        model: modelType,
        isRequired: isRequired && !isNullable,
        nameManager: nameManager,
        package: package,
        contextClass: className,
        contextProperty: propertyName,
        explode: refer('explode'),
        useImmutableCollections: useImmutableCollections,
      );
    }

    for (final name in writeOnlyRequiredNames) {
      constructorArgs.putIfAbsent(name, () => literalNull);
    }

    // Build expectedKeys and listKeys sets
    final expectedKeys = properties.map((p) => p.property.name).toSet();
    final listKeys = properties
        .where((p) => p.property.model is ListModel)
        .map((p) => p.property.name)
        .toSet();

    final captureAP = _hasStringCapturableAP(classModel);
    final decodeObjectArgs = <String, Expression>{
      'explode': refer('explode'),
      'explodeSeparator': literalString('&'),
      'expectedKeys': literalSet(expectedKeys.map(specLiteralString)),
      'listKeys': literalSet(listKeys.map(specLiteralString)),
      'context': specLiteralString(className),
    };
    if (captureAP) {
      decodeObjectArgs['captureAdditionalKeys'] = literalTrue;
    }

    final codes = <Code>[
      declareFinal(r'_$values')
          .assign(
            refer('value').property('decodeObject').call([], decodeObjectArgs),
          )
          .statement,
    ];

    final ap = classModel.additionalProperties;
    if (captureAP && ap != null) {
      final apFieldName = pickAdditionalPropertiesFieldName(allProperties);
      final knownKeySet = expectedKeys.map(specLiteralStringCode).join(', ');
      final mapType = additionalPropertiesType(ap, nameManager, package);
      codes.addAll([
        Code('const _\$knownKeys = {$knownKeySet};'),
        declareFinal(r'_$additional')
            .assign(
              literalMap(
                {},
                refer('String', 'dart:core'),
                mapType.types.last,
              ),
            )
            .statement,
        const Code(r'for (final _$entry in _$values.entries) {'),
        const Code(r'if (!_$knownKeys.contains(_$entry.key)) {'),
      ]);

      if (ap is TypedAdditionalProperties) {
        final decodeExpr = buildFromFormValueExpression(
          refer(r'_$entry').property('value'),
          model: ap.valueModel,
          isRequired: true,
          nameManager: nameManager,
          package: package,
          contextClass: className,
          contextProperty: 'additionalProperties',
          explode: refer('explode'),
          useImmutableCollections: useImmutableCollections,
        );
        codes.addAll([
          const Code(r'_$additional[_$entry.key] = '),
          decodeExpr.code,
          const Code(';'),
        ]);
      } else {
        codes.addAll([
          const Code(r'_$additional[_$entry.key] = '),
          refer(r'_$entry').property('value').property('decodeFormString').call(
            [],
            {
              'context': specLiteralString(
                '$className.additionalProperties',
              ),
            },
          ).code,
          const Code(';'),
        ]);
      }

      codes.addAll([
        const Code('}'),
        const Code('}'),
      ]);
      constructorArgs[apFieldName] = useImmutableCollections
          ? refer(r'_$additional').property('lock')
          : refer(r'_$additional');
    }

    codes.add(
      refer(className).call([], constructorArgs).returned.statement,
    );

    return Block.of(codes);
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

  bool _hasStringCapturableAP(ClassModel model) {
    final ap = model.additionalProperties;
    if (ap is UnrestrictedAdditionalProperties) return true;
    if (ap is TypedAdditionalProperties) {
      final resolved = ap.valueModel is AliasModel
          ? (ap.valueModel as AliasModel).resolved
          : ap.valueModel;
      return resolved is StringModel ||
          resolved is IntegerModel ||
          resolved is NumberModel ||
          resolved is DoubleModel ||
          resolved is BooleanModel ||
          resolved is DecimalModel ||
          resolved is DateTimeModel ||
          resolved is DateModel ||
          resolved is UriModel;
    }
    return false;
  }
}
