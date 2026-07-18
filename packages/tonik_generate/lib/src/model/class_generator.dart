import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/naming/property_name_normalizer.dart';
import 'package:tonik_generate/src/util/additional_properties_builders.dart';
import 'package:tonik_generate/src/util/additional_properties_helpers.dart';
import 'package:tonik_generate/src/util/built_expression.dart';
import 'package:tonik_generate/src/util/copy_with_method_generator.dart';
import 'package:tonik_generate/src/util/core_prefixed_allocator.dart';
import 'package:tonik_generate/src/util/default_resolution.dart';
import 'package:tonik_generate/src/util/equals_method_generator.dart';
import 'package:tonik_generate/src/util/example_doc_formatter.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';
import 'package:tonik_generate/src/util/flat_value_codec_plan.dart';
import 'package:tonik_generate/src/util/format_with_header.dart';
import 'package:tonik_generate/src/util/from_form_value_expression_generator.dart';
import 'package:tonik_generate/src/util/from_json_value_expression_generator.dart';
import 'package:tonik_generate/src/util/from_simple_value_expression_generator.dart';
import 'package:tonik_generate/src/util/hash_code_generator.dart';
import 'package:tonik_generate/src/util/inline_helper_context.dart';
import 'package:tonik_generate/src/util/property_value_expression_generator.dart';
import 'package:tonik_generate/src/util/raw_string_expression_generator.dart';
import 'package:tonik_generate/src/util/spec_literal_string.dart';
import 'package:tonik_generate/src/util/to_json_value_expression_generator.dart';
import 'package:tonik_generate/src/util/type_reference_generator.dart';
import 'package:tonik_util/tonik_util.dart';

final Logger _classGeneratorLog = Logger('ClassGenerator');

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

    final fileName = nameManager.fileNameForClass(nameManager.modelName(model));
    final generatedClasses = generateClasses(model);

    final library = Library((b) {
      b.body.addAll(generatedClasses);
    });

    final formatter = DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    );

    final code = formatter.formatWithHeader(library.accept(emitter).toString());

    return (code: code, filename: fileName);
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
              defaultValue: null,
              examples: const [],
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
    final hasAP = activeApPolicy(model.additionalPropertiesPolicy) != null;
    final apFieldName = nameManager.additionalPropertiesFieldName(
      normalizedProperties,
    );
    final defaultsByName = _resolveDefaults(
      normalizedProperties,
      className,
      apFieldName: hasAP ? apFieldName : null,
    );

    final effectiveCopyWithGetter =
        copyWithGetter ??
        _buildCopyWith(className, normalizedProperties, model)?.getter;

    bool hasConstDefault(({String normalizedName, Property property}) p) =>
        defaultsByName[p.normalizedName] is ConstDefaultBinding;

    bool isParamRequired(({String normalizedName, Property property}) p) =>
        !hasConstDefault(p) &&
        p.property.isRequired &&
        !p.property.isReadOnly &&
        !model.isReadOnly;

    final sortedProperties = [...normalizedProperties]
      ..sort((a, b) {
        final aRequired = isParamRequired(a);
        final bRequired = isParamRequired(b);
        if (aRequired != bRequired) {
          return aRequired ? -1 : 1;
        }
        return normalizedProperties.indexOf(a) -
            normalizedProperties.indexOf(b);
      });

    // IList/IMap support native deep equality, so immutable collections do
    // not need DeepCollectionEquality.
    final equalityProps = normalizedProperties
        .map(
          (prop) => (
            normalizedName: prop.normalizedName,
            hasCollectionValue:
                !useImmutableCollections &&
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

        b.constructors.addAll([
          Constructor(
            (b) {
              b
                ..constant = true
                ..optionalParameters.addAll(
                  sortedProperties.map(
                    (prop) {
                      final defaulted = defaultsByName[prop.normalizedName];
                      return Parameter(
                        (b) => b
                          ..name = prop.normalizedName
                          ..named = true
                          ..required = isParamRequired(prop)
                          ..defaultTo = defaulted is ConstDefaultBinding
                              ? refer(defaulted.memberName).code
                              : null
                          ..toThis = true,
                      );
                    },
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
          _buildFromSimpleConstructor(className, model, defaultsByName),
          _buildFromJsonConstructor(className, model, defaultsByName),
          _buildFromFormConstructor(className, model, defaultsByName),
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
          _buildUriEncodeMethod(className),
        ]);

        for (final prop in normalizedProperties) {
          final defaulted = defaultsByName[prop.normalizedName];
          switch (defaulted) {
            case null:
              break;
            case ConstDefaultBinding(:final resolved):
              b.fields.add(defaultField(resolved));
            case RuntimeDefaultBinding(:final resolved):
              b.methods.add(resolved.getter);
          }
        }

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
                ..type = apMapTypeReference(
                  activeApPolicy(model.additionalPropertiesPolicy)!.valueModel,
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

  Map<String, DefaultBinding> _resolveDefaults(
    List<({String normalizedName, Property property})> normalizedProperties,
    String className, {
    String? apFieldName,
  }) {
    final reservedNames = <String>{
      for (final p in normalizedProperties) p.normalizedName,
      ?apFieldName,
    };

    final result = <String, DefaultBinding>{};
    for (final prop in normalizedProperties) {
      final raw = prop.property.effectiveDefaultValue;
      if (raw == null) continue;

      var dropped = false;
      final resolved = resolveSingleDefault(
        normalizedName: prop.normalizedName,
        specName: prop.property.name,
        model: prop.property.model,
        rawDefault: raw,
        containerName: className,
        reservedNames: reservedNames,
        nameManager: nameManager,
        package: package,
        onDroppedDefault: (message) {
          dropped = true;
          _classGeneratorLog.warning(message);
        },
        isNullableOverride: prop.property.isNullable,
        useImmutableCollections: useImmutableCollections,
      );
      if (resolved != null) {
        result[prop.normalizedName] = ConstDefaultBinding(resolved);
        continue;
      }
      if (dropped) continue;

      final runtime = resolveRuntimeDefault(
        normalizedName: prop.normalizedName,
        specName: prop.property.name,
        model: prop.property.model,
        rawDefault: raw,
        containerName: className,
        reservedNames: reservedNames,
        nameManager: nameManager,
        package: package,
        isNullableOverride: prop.property.isNullable,
        useImmutableCollections: useImmutableCollections,
      );
      if (runtime == null) continue;
      _classGeneratorLog.fine(
        'Routing default to runtime fallback for '
        '$className.${prop.property.name}.',
      );
      result[prop.normalizedName] = RuntimeDefaultBinding(runtime);
    }
    return result;
  }

  Expression _defaultIfAbsent({
    required Expression decoded,
    required String key,
    required DefaultBinding defaulted,
  }) => refer(r'_$values')
      .property('containsKey')
      .call([specLiteralString(key)])
      .conditional(decoded, refer(defaulted.memberName));

  CopyWithResult? _buildCopyWith(
    String className,
    List<({String normalizedName, Property property})> properties,
    ClassModel model,
  ) {
    final copyWithProps = properties.map(
      (prop) {
        final propModel = prop.property.model;
        final resolvedModel = propModel.resolved;
        return (
          normalizedName: prop.normalizedName,
          typeRef: _getSchemaAwareTypeReference(prop.property, model),
          skipCast: resolvedModel is AnyModel,
        );
      },
    ).toList();

    final copyWithApPolicy = activeApPolicy(model.additionalPropertiesPolicy);
    if (copyWithApPolicy != null) {
      final apFieldName = nameManager.additionalPropertiesFieldName(properties);
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

  Constructor _buildFromSimpleConstructor(
    String className,
    ClassModel model,
    Map<String, DefaultBinding> defaultsByName,
  ) {
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
          defaultsByName,
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
    Map<String, DefaultBinding> defaultsByName,
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
      final defaulted = defaultsByName[normalizedName];
      final isRequired = prop.property.isRequired && !prop.property.isWriteOnly;
      final isNullable =
          prop.property.isNullable || modelType.isEffectivelyNullable;
      final decodeIsRequired = defaulted != null
          ? !isNullable
          : isRequired && !isNullable;

      var expr = buildSimpleValueExpression(
        refer('_\$values[${specLiteralStringCode(propertyName)}]'),
        model: modelType,
        isRequired: decodeIsRequired,
        nameManager: nameManager,
        package: package,
        contextClass: className,
        contextProperty: propertyName,
        explode: refer('explode'),
      ).expression;

      if (useImmutableCollections && isCollectionModel(modelType)) {
        final effectivelyNullable = isNullable || !isRequired;
        expr = effectivelyNullable
            ? expr.nullSafeProperty('lock')
            : expr.property('lock');
      }

      if (defaulted != null) {
        expr = _defaultIfAbsent(
          decoded: expr,
          key: propertyName,
          defaulted: defaulted,
        );
      }

      constructorArgs[normalizedName] = expr;
    }

    for (final name in writeOnlyRequiredNames) {
      constructorArgs.putIfAbsent(name, () => literalNull);
    }

    final expectedKeys = properties.map((p) => p.property.name).toSet();
    final listKeys = properties
        .where((p) => p.property.model is ListModel)
        .map((p) => p.property.name)
        .toSet();

    final apPolicy = activeApPolicy(classModel.additionalPropertiesPolicy);
    final decodeObjectArgs = <String, Expression>{
      'explode': refer('explode'),
      'explodeSeparator': literalString(','),
      'expectedKeys': literalSet(expectedKeys.map(specLiteralString)),
      'listKeys': literalSet(listKeys.map(specLiteralString)),
      'context': specLiteralString(className),
    };
    if (apPolicy != null) {
      decodeObjectArgs['captureAdditionalKeys'] = literalTrue;
    }

    final codes = <Code>[
      declareFinal(r'_$values')
          .assign(
            refer('value').property('decodeObject').call([], decodeObjectArgs),
          )
          .statement,
    ];

    if (apPolicy != null) {
      final apFieldName = nameManager.additionalPropertiesFieldName(
        allProperties,
      );
      final capture = buildApFlatCaptureLoop(
        AdditionalPropertiesPlan(
          valueModel: apPolicy.valueModel,
          knownWireKeys: expectedKeys,
        ),
        format: FlatWireFormat.simple,
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
    }

    codes.add(
      refer(className).call([], constructorArgs).returned.statement,
    );

    return Block.of(codes);
  }

  Constructor _buildFromJsonConstructor(
    String className,
    ClassModel model,
    Map<String, DefaultBinding> defaultsByName,
  ) {
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
        ..body = _buildFromJsonBody(className, model, defaultsByName),
    );
  }

  Code _buildFromJsonBody(
    String className,
    ClassModel model,
    Map<String, DefaultBinding> defaultsByName,
  ) {
    final normalizedProperties = normalizeProperties(
      model.properties.where((p) => !p.isWriteOnly).toList(),
    );
    final hasAP = activeApPolicy(model.additionalPropertiesPolicy) != null;
    final apFieldName = hasAP
        ? nameManager.additionalPropertiesFieldName(
            normalizeProperties(model.properties.toList()),
          )
        : null;
    final helperContext = InlineHelperContext(nameManager: nameManager);
    final inlineHelpers = <InlineHelper>[];

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
      final defaulted = defaultsByName[normalizedName];

      final decodeIsNullable = defaulted != null
          ? property.isNullable || property.model.isEffectivelyNullable
          : property.isNullable ||
                !requiredInResponse ||
                property.model.isEffectivelyNullable;

      final valueBuilt = buildFromJsonValueExpression(
        '_\$map[${specLiteralStringCode(jsonKey)}]',
        model: property.model,
        nameManager: nameManager,
        package: package,
        helperContext: helperContext,
        contextClass: className,
        contextProperty: jsonKey,
        isNullable: decodeIsNullable,
        useImmutableCollections: useImmutableCollections,
      );
      inlineHelpers.addAll(valueBuilt.inlineFunctions);

      propertyAssignments.add(Code('$normalizedName: '));
      if (defaulted != null) {
        propertyAssignments
          ..add(
            Code(
              r'_$map.containsKey('
              '${specLiteralStringCode(jsonKey)}) ? ',
            ),
          )
          ..add(valueBuilt.unsafeRawBody.code)
          ..add(const Code(' : '))
          ..add(refer(defaulted.memberName).code);
      } else {
        propertyAssignments.add(valueBuilt.unsafeRawBody.code);
      }
      propertyAssignments.add(const Code(','));
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

    if (hasAP) {
      final apPolicy = activeApPolicy(model.additionalPropertiesPolicy)!;
      final capture = buildApJsonCaptureLoop(
        AdditionalPropertiesPlan(
          valueModel: apPolicy.valueModel,
          knownWireKeys: model.properties.map((p) => p.name).toSet(),
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

      if (useImmutableCollections) {
        propertyAssignments
          ..add(Code('$apFieldName: '))
          ..add(
            refer(
              'IMap',
              'package:fast_immutable_collections/'
                  'fast_immutable_collections.dart',
            ).call([refer(r'_$additional')]).code,
          )
          ..add(const Code(','));
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

    return Block.of([
      ...spliceInlineHelpers(inlineHelpers),
      ...codes,
    ]);
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

    final helperContext = InlineHelperContext(nameManager: nameManager);
    final inlineHelpers = <InlineHelper>[];

    final requiredWriteOnlyNonNullable = normalizedProperties
        .where(
          (p) =>
              p.property.isWriteOnly &&
              p.property.isRequired &&
              !p.property.isNullable,
        )
        .toList();

    final mapEntries = <Code>[];
    for (final prop in normalizedProperties) {
      final name = prop.normalizedName;
      final property = prop.property;
      final requiredInRequest = property.isRequired && !property.isReadOnly;
      final forceNonNullReceiver =
          property.isWriteOnly && requiredInRequest && !property.isNullable;

      final valueBuilt = buildToJsonPropertyExpression(
        name,
        property,
        nameManager: nameManager,
        package: package,
        helperContext: helperContext,
        contextClass: className,
        contextProperty: property.name,
        forceNonNullReceiver: forceNonNullReceiver,
        useImmutableCollections: useImmutableCollections,
      );
      inlineHelpers.addAll(valueBuilt.inlineFunctions);

      final keyLiteral = specLiteralStringCode(property.name);
      if (!requiredInRequest && !property.isNullable) {
        mapEntries
          ..add(Code('if ($name != null) $keyLiteral: '))
          ..add(valueBuilt.unsafeRawBody.code)
          ..add(const Code(','));
      } else {
        mapEntries
          ..add(Code('$keyLiteral: '))
          ..add(valueBuilt.unsafeRawBody.code)
          ..add(const Code(','));
      }
    }

    final toJsonApPolicy = activeApPolicy(model.additionalPropertiesPolicy);
    final apEncodeCodes = <Code>[];
    if (toJsonApPolicy != null) {
      final allNormalized = normalizeProperties(model.properties.toList());
      final apFieldName = nameManager.additionalPropertiesFieldName(
        allNormalized,
      );
      final apEncode = buildApJsonEncode(
        AdditionalPropertiesPlan(
          valueModel: toJsonApPolicy.valueModel,
          knownWireKeys: model.properties.map((p) => p.name).toSet(),
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
      apEncodeCodes.addAll(apEncode.codes);
    }

    final helperPrelude = spliceInlineHelpers(inlineHelpers);

    if (toJsonApPolicy != null) {
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
            ...helperPrelude,
            ...nullChecks,
            const Code(r'final _$map = <'),
            refer('String', 'dart:core').code,
            const Code(', '),
            refer('Object?', 'dart:core').code,
            const Code('>{'),
            ...mapEntries,
            const Code('};'),
            ...apEncodeCodes,
            const Code(r'return _$map;'),
          ]),
      );
    }

    if (requiredWriteOnlyNonNullable.isEmpty) {
      if (helperPrelude.isEmpty) {
        // Type an empty literal explicitly: a bare `{}` infers Map<dynamic,
        // dynamic>, which composite guards reject as not Map<String, Object?>.
        final mapOpen = mapEntries.isEmpty
            ? <Code>[
                const Code('<'),
                refer('String', 'dart:core').code,
                const Code(', '),
                refer('Object?', 'dart:core').code,
                const Code('>{'),
              ]
            : <Code>[const Code('{')];
        return Method(
          (b) => b
            ..annotations.add(refer('override', 'dart:core'))
            ..name = 'toJson'
            ..returns = refer('Object?', 'dart:core')
            ..lambda = true
            ..body = Block.of([
              ...mapOpen,
              ...mapEntries,
              const Code('}'),
            ]),
        );
      }
      return Method(
        (b) => b
          ..annotations.add(refer('override', 'dart:core'))
          ..name = 'toJson'
          ..returns = refer('Object?', 'dart:core')
          ..body = Block.of([
            ...helperPrelude,
            const Code('return {'),
            ...mapEntries,
            const Code('};'),
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
          ...helperPrelude,
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
      ..docs.addAll(
        formatDocsWithExamples(property.description, property.examples),
      )
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
          ..returns = buildMapStringPropertyValueType()
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
    final apPolicy = activeApPolicy(model.additionalPropertiesPolicy);
    if (apPolicy == null) return [];

    final allNormalized = normalizeProperties(model.properties.toList());
    final apFieldName = nameManager.additionalPropertiesFieldName(
      allNormalized,
    );
    final className = nameManager.modelName(model);

    return buildApPropertyValueEntries(
      AdditionalPropertiesPlan(
        valueModel: apPolicy.valueModel,
        knownWireKeys: model.properties.map((p) => p.name).toSet(),
      ),
      targetVar: r'_$result',
      apAccess: apFieldName,
      contextClass: className,
      useImmutableCollections: useImmutableCollections,
    ).codes;
  }

  List<Parameter> _buildParameterPropertiesParameters() =>
      buildParameterPropertiesParameters();

  Code _scalarPropertyAssignment(String propertyName, Expression raw) =>
      refer(r'_$result')
          .index(specLiteralString(propertyName))
          .assign(propertyValueScalar(raw))
          .statement;

  Expression _rawScalarExpression(Expression receiver, Model model) {
    return switch (model.resolved) {
      OneOfModel() || AnyOfModel() || AllOfModel() =>
        refer(
          'encodeAnyValueToString',
          'package:tonik_util/tonik_util.dart',
        ).call(
          [receiver.property('toJson').call([])],
          {
            'allowEmpty': refer('allowEmpty'),
          },
        ),
      _ => buildRawStringExpression(receiver, model),
    };
  }

  List<Code> _buildScalarPropertyAssignment({
    required String name,
    required String propertyName,
    required bool isRequired,
    required bool isNullable,
    required bool isFieldNullable,
    required Model model,
  }) {
    Code assign(Expression receiver) => _scalarPropertyAssignment(
      propertyName,
      _rawScalarExpression(receiver, model),
    );

    if (isRequired && !isNullable && !isFieldNullable) {
      return [assign(refer(name))];
    }

    final checked = refer(name).nullChecked;
    if (isRequired && !isNullable) {
      return [
        Code('if ($name == null) {'),
        generateEncodingExceptionExpression(
          'Required property $propertyName is null.',
          raw: true,
        ).statement,
        const Code('}'),
        assign(checked),
      ];
    }

    return [
      Code('if ($name != null) {'),
      assign(checked),
      const Code('} else if (allowEmpty) {'),
      _scalarPropertyAssignment(propertyName, literalString('')),
      const Code('}'),
    ];
  }

  Method _buildSimpleParameterPropertiesMethod(
    String className,
    List<({String normalizedName, Property property})> properties,
    ClassModel model,
  ) {
    if (properties.isEmpty &&
        activeApPolicy(model.additionalPropertiesPolicy) == null) {
      return Method(
        (b) => b
          ..name = 'parameterProperties'
          ..returns = buildMapStringPropertyValueType()
          ..optionalParameters.addAll(_buildParameterPropertiesParameters())
          ..body = buildEmptyMapStringPropertyValue().returned.statement,
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
      final resolvedModel = model.resolved;

      if (resolvedModel is NeverModel) {
        propertyAssignments.add(
          generateEncodingExceptionExpression(
            'Cannot encode NeverModel property $propertyName: '
            'this type does not permit any value',
            raw: true,
          ).statement,
        );
        continue;
      }

      propertyAssignments.addAll(
        _buildScalarPropertyAssignment(
          name: name,
          propertyName: propertyName,
          isRequired: isRequired,
          isNullable: isNullable,
          isFieldNullable: isFieldNullable,
          model: model,
        ),
      );
    }

    final methodBody = [
      const Code(r'final _$result = '),
      buildEmptyMapStringPropertyValue().statement,
      ...propertyAssignments,
      ..._buildAdditionalPropertiesParameterLoop(model),
      const Code(r'return _$result;'),
    ];

    return Method(
      (b) => b
        ..name = 'parameterProperties'
        ..returns = buildMapStringPropertyValueType()
        ..optionalParameters.addAll(_buildParameterPropertiesParameters())
        ..body = Block.of(methodBody),
    );
  }

  Method _buildListParameterPropertiesMethod(
    String className,
    List<({String normalizedName, Property property})> properties,
    ClassModel model,
  ) {
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
        propertyAssignments.addAll(
          _buildScalarPropertyAssignment(
            name: name,
            propertyName: propertyName,
            isRequired: isRequired,
            isNullable: isNullable,
            isFieldNullable: isFieldNullable,
            model: fieldModel,
          ),
        );
      } else if (fieldModel is ListModel && fieldModel.hasSimpleContent) {
        final valueRef = (isRequired && !isNullable)
            ? (isFieldNullable ? refer(name).nullChecked : refer(name))
            : refer(name).nullChecked;
        final rawList = buildRawStringListExpression(
          valueRef,
          fieldModel.content,
          isContentNullable:
              fieldModel.isContentNullable ||
              fieldModel.content.isEffectivelyNullable,
          useImmutableCollections: useImmutableCollections,
        );

        final assignmentExpr = refer(r'_$result')
            .index(specLiteralString(propertyName))
            .assign(propertyValueArray(rawList));

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
          propertyAssignments
            ..add(Code('if ($name != null) {'))
            ..add(assignmentExpr.statement)
            ..add(const Code('} else if (allowEmpty) {'))
            ..add(_scalarPropertyAssignment(propertyName, literalString('')))
            ..add(const Code('}'));
        }
      }
    }

    final methodBody = <Code>[
      const Code(r'final _$result = '),
      buildEmptyMapStringPropertyValue().statement,
      ...propertyAssignments,
      ..._buildAdditionalPropertiesParameterLoop(model),
      const Code(r'return _$result;'),
    ];

    return Method(
      (b) => b
        ..name = 'parameterProperties'
        ..returns = buildMapStringPropertyValueType()
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
        ..returns = buildMapStringPropertyValueType()
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
      final resolvedModel = model.resolved;

      if (resolvedModel is AnyModel) {
        propertyAssignments.addAll([
          Code('if ($name != null) {'),
          _scalarPropertyAssignment(
            propertyName,
            refer(
              'encodeUnknownFlatScalar',
              'package:tonik_util/tonik_util.dart',
            ).call(
              [refer(name).nullChecked],
              {'context': literalString('$className.$propertyName')},
            ),
          ),
          const Code('} else if (allowEmpty) {'),
          _scalarPropertyAssignment(propertyName, literalString('')),
          const Code('}'),
        ]);
        continue;
      }

      if (resolvedModel is NeverModel) {
        propertyAssignments.add(
          generateEncodingExceptionExpression(
            'Cannot encode NeverModel property $propertyName: '
            'this type does not permit any value',
            raw: true,
          ).statement,
        );
        continue;
      }

      if (model.encodingShape == .simple) {
        propertyAssignments.addAll(
          _buildScalarPropertyAssignment(
            name: name,
            propertyName: propertyName,
            isRequired: isRequired,
            isNullable: isNullable,
            isFieldNullable: isFieldNullable,
            model: model,
          ),
        );
      } else {
        final isFieldNullable = isNullable || !isRequired;
        final encodingShapeRef = refer(
          'EncodingShape',
          'package:tonik_util/tonik_util.dart',
        );

        Code mixedScalarAssign(Expression receiver) =>
            _scalarPropertyAssignment(
              propertyName,
              refer(
                'encodeAnyValueToString',
                'package:tonik_util/tonik_util.dart',
              ).call(
                [receiver.property('toJson').call([])],
                {
                  'allowEmpty': refer('allowEmpty'),
                },
              ),
            );

        if (isFieldNullable) {
          propertyAssignments.addAll([
            Code('if ($name != null) {'),
            Code('  if ($name!.currentEncodingShape == '),
            encodingShapeRef.property('simple').code,
            const Code(') {'),
            mixedScalarAssign(refer(name).nullChecked),
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
            mixedScalarAssign(refer(name)),
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
      buildEmptyMapStringPropertyValue().statement,
      ...propertyAssignments,
      ..._buildAdditionalPropertiesParameterLoop(model),
      const Code(r'return _$result;'),
    ];

    return Method(
      (b) => b
        ..name = 'parameterProperties'
        ..returns = buildMapStringPropertyValueType()
        ..optionalParameters.addAll(_buildParameterPropertiesParameters())
        ..body = Block.of(methodBody),
    );
  }

  Method _buildToSimpleMethod() => Method(
    (b) => b
      ..annotations.add(refer('override', 'dart:core'))
      ..name = 'toSimple'
      ..returns = refer('String', 'dart:core')
      ..optionalParameters.addAll(buildSimpleEncodingParameters())
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

  Constructor _buildFromFormConstructor(
    String className,
    ClassModel model,
    Map<String, DefaultBinding> defaultsByName,
  ) {
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
          defaultsByName,
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
    Map<String, DefaultBinding> defaultsByName,
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
      final defaulted = defaultsByName[normalizedName];
      final isRequired = prop.property.isRequired && !prop.property.isWriteOnly;
      final isNullable =
          prop.property.isNullable || modelType.isEffectivelyNullable;
      final decodeIsRequired = defaulted != null
          ? !isNullable
          : isRequired && !isNullable;

      var expr = buildFromFormValueExpression(
        refer('_\$values[${specLiteralStringCode(propertyName)}]'),
        model: modelType,
        isRequired: decodeIsRequired,
        nameManager: nameManager,
        package: package,
        contextClass: className,
        contextProperty: propertyName,
        explode: refer('explode'),
        useImmutableCollections: useImmutableCollections,
      ).expression;

      if (defaulted != null) {
        expr = _defaultIfAbsent(
          decoded: expr,
          key: propertyName,
          defaulted: defaulted,
        );
      }

      constructorArgs[normalizedName] = expr;
    }

    for (final name in writeOnlyRequiredNames) {
      constructorArgs.putIfAbsent(name, () => literalNull);
    }

    final expectedKeys = properties.map((p) => p.property.name).toSet();
    final listKeys = properties
        .where((p) => p.property.model is ListModel)
        .map((p) => p.property.name)
        .toSet();

    final apPolicy = activeApPolicy(classModel.additionalPropertiesPolicy);
    final decodeObjectArgs = <String, Expression>{
      'explode': refer('explode'),
      'explodeSeparator': literalString('&'),
      'expectedKeys': literalSet(expectedKeys.map(specLiteralString)),
      'listKeys': literalSet(listKeys.map(specLiteralString)),
      'context': specLiteralString(className),
    };
    if (apPolicy != null) {
      decodeObjectArgs['captureAdditionalKeys'] = literalTrue;
    }

    final codes = <Code>[
      declareFinal(r'_$values')
          .assign(
            refer('value').property('decodeObject').call([], decodeObjectArgs),
          )
          .statement,
    ];

    if (apPolicy != null) {
      final apFieldName = nameManager.additionalPropertiesFieldName(
        allProperties,
      );
      final capture = buildApFlatCaptureLoop(
        AdditionalPropertiesPlan(
          valueModel: apPolicy.valueModel,
          knownWireKeys: expectedKeys,
        ),
        format: FlatWireFormat.form,
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
      ..returns = buildParameterEntryListType()
      ..requiredParameters.add(
        Parameter(
          (b) => b
            ..name = 'paramName'
            ..type = refer('String', 'dart:core'),
        ),
      )
      ..optionalParameters.addAll(buildFormEncodingParameters())
      ..body = Block.of([
        refer('parameterProperties')
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
      ..optionalParameters.addAll(buildDeepObjectEncodingParameters())
      ..body = Block.of([
        refer('parameterProperties')
            .call([], {'allowEmpty': refer('allowEmpty')})
            .property('toDeepObject')
            .call(
              [refer('paramName')],
              {
                'explode': refer('explode'),
                'allowEmpty': refer('allowEmpty'),
                'allowReserved': refer('allowReserved'),
              },
            )
            .returned
            .statement,
      ]),
  );

  Method _buildUriEncodeMethod(String className) => Method(
    (b) => b
      ..annotations.add(refer('override', 'dart:core'))
      ..name = 'uriEncode'
      ..returns = refer('String', 'dart:core')
      ..optionalParameters.addAll(buildUriEncodeParameters())
      ..lambda = false
      ..body = generateEncodingExceptionExpression(
        'Cannot uriEncode $className: complex types cannot be URI-encoded',
        raw: true,
      ).statement,
  );

}
