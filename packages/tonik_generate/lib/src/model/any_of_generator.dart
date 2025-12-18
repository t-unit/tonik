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
import 'package:tonik_generate/src/util/to_form_parameter_expression_generator.dart';
import 'package:tonik_generate/src/util/to_json_value_expression_generator.dart';
import 'package:tonik_generate/src/util/to_label_parameter_expression_generator.dart';
import 'package:tonik_generate/src/util/to_matrix_parameter_expression_generator.dart';
import 'package:tonik_generate/src/util/to_simple_parameter_expression_generator.dart';
import 'package:tonik_generate/src/util/type_reference_generator.dart';
import 'package:tonik_util/tonik_util.dart';

@immutable
class AnyOfGenerator {
  const AnyOfGenerator({required this.nameManager, required this.package});

  final NameManager nameManager;
  final String package;

  ({String code, String filename}) generate(AnyOfModel model) {
    final emitter = DartEmitter(
      allocator: CorePrefixedAllocator(
        additionalImports: ['package:tonik_util/tonik_util.dart'],
      ),
      orderDirectives: true,
      useNullSafetySyntax: true,
    );

    final className = nameManager.modelName(model);
    final snakeCaseName = className.toSnakeCase();

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
  Class generateClass(AnyOfModel model) {
    final className = nameManager.modelName(model);

    final pseudoProperties =
        model.models.toSortedList().map((discriminated) {
          final typeRef = typeReference(
            discriminated.model,
            nameManager,
            package,
          );
          return Property(
            name: typeRef.symbol,
            model: discriminated.model,
            isRequired: false,
            isNullable: true,
            isDeprecated: false,
          );
        }).toList();

    final normalized = normalizeProperties(pseudoProperties);
    final fields =
        normalized.map((n) {
          final ref = typeReference(
            n.property.model,
            nameManager,
            package,
            isNullableOverride: true,
          );
          return Field(
            (b) =>
                b
                  ..name = n.normalizedName
                  ..modifier = FieldModifier.final$
                  ..type = ref,
          );
        }).toList();

    final defaultCtor = Constructor(
      (b) =>
          b
            ..constant = true
            ..optionalParameters.addAll(
              normalized.map(
                (n) => Parameter(
                  (p) =>
                      p
                        ..name = n.normalizedName
                        ..named = true
                        ..toThis = true,
                ),
              ),
            ),
    );

    final fromJsonCtor = _buildFromJsonConstructor(className, normalized);

    final fromSimpleCtor = _buildFromSimpleConstructor(className, normalized);

    final fromFormCtor = _buildFromFormConstructor(
      className,
      normalized,
    );

    final propsForEquality =
        normalized
            .map(
              (n) => (
                normalizedName: n.normalizedName,
                hasCollectionValue: n.property.model is ListModel,
              ),
            )
            .toList();

    final copyWithMethod = generateCopyWithMethod(
      className: className,
      properties:
          normalized
              .map(
                (n) => (
                  normalizedName: n.normalizedName,
                  typeRef: typeReference(
                    n.property.model,
                    nameManager,
                    package,
                  ),
                ),
              )
              .toList(),
    );

    return Class(
      (b) {
        b
          ..name = className
          ..docs.addAll(formatDocComment(model.description))
          ..annotations.add(refer('immutable', 'package:meta/meta.dart'));

        if (model.isDeprecated) {
          b.annotations.add(
            refer('Deprecated', 'dart:core').call([
              literalString('This class is deprecated.'),
            ]),
          );
        }

        b
          ..constructors.add(defaultCtor)
          ..constructors.add(fromJsonCtor)
          ..constructors.add(fromSimpleCtor)
          ..constructors.add(fromFormCtor)
          ..methods.addAll([
            _buildCurrentEncodingShapeGetter(className, normalized),
            _buildToJsonMethod(className, model, normalized),
            _buildParameterPropertiesMethod(className, model, normalized),
            _buildToSimpleMethod(className, model, normalized),
            _buildToFormMethod(className, model, normalized),
            _buildToLabelMethod(className, model, normalized),
            _buildToMatrixMethod(className, model, normalized),
            _buildToDeepObjectMethod(className, model, normalized),
            _buildUriEncodeMethod(className, model, normalized),
            generateEqualsMethod(
              className: className,
              properties: propsForEquality,
            ),
            generateHashCodeMethod(properties: propsForEquality),
            copyWithMethod,
          ])
          ..fields.addAll(fields);
      },
    );
  }

  Reference _nullableTypeReference(Model model) => typeReference(
    model,
    nameManager,
    package,
    isNullableOverride: true,
  );
  List<Code> _generateFieldEncoding({
    required String fieldName,
    required Model fieldModel,
    required String tmpVarName,
    required bool isForm,
    required bool needsValues,
    required bool needsMapValues,
    String? discriminatorValue,
  }) {
    final toMethodName = isForm ? 'toForm' : 'toSimple';
    final codes = <Code>[];

    if (fieldModel.encodingShape == EncodingShape.simple) {
      codes.add(
        Code(
          'final $tmpVarName = $fieldName!.$toMethodName( '
          'explode: explode, allowEmpty: allowEmpty);',
        ),
      );
      if (needsValues) {
        codes.add(Code('values.add($tmpVarName);'));
      }
    } else if (fieldModel.encodingShape == EncodingShape.complex) {
      // Lists with simple content can be encoded directly
      if (fieldModel is ListModel && fieldModel.hasSimpleContent) {
        final buildExpr =
            isForm
                ? buildFormParameterExpression
                : buildSimpleParameterExpression;
        codes.add(
          Block.of([
            Code('final $tmpVarName = '),
            buildExpr(
              refer(fieldName).nullChecked,
              fieldModel,
              explode: refer('explode'),
              allowEmpty: refer('allowEmpty'),
            ).statement,
          ]),
        );
        if (needsValues) {
          codes.add(Code('values.add($tmpVarName);'));
        }
      } else if (fieldModel is ListModel) {
        // Lists with complex content cannot be encoded
        codes.add(
          refer('EncodingException', 'package:tonik_util/tonik_util.dart')
              .call([
                literalString(
                  'Lists with complex content are not supported for encoding',
                ),
              ])
              .thrown
              .statement,
        );
      } else {
        // For complex types (classes, composites), use parameterProperties
        codes.add(
          Code(
            'final $tmpVarName = '
            '$fieldName!.parameterProperties(allowEmpty: allowEmpty);',
          ),
        );
        if (needsMapValues) {
          codes.add(Code('mapValues.add($tmpVarName);'));
        }

        if (discriminatorValue != null) {
          codes.add(
            Code("discriminatorValue ??= r'$discriminatorValue';"),
          );
        }
      }
    } else {
      final encodingShapeRef = refer(
        'EncodingShape',
        'package:tonik_util/tonik_util.dart',
      );

      codes
        ..add(Code('switch ($fieldName!.currentEncodingShape) {'))
        ..add(const Code('case '))
        ..add(encodingShapeRef.property('simple').code)
        ..add(const Code(':'));
      if (needsValues) {
        codes.add(
          Code(
            'values.add($fieldName!.$toMethodName('
            'explode: explode, allowEmpty: allowEmpty));',
          ),
        );
      }
      codes
        ..add(const Code('break;'))
        ..add(const Code('case '))
        ..add(encodingShapeRef.property('complex').code)
        ..add(const Code(':'))
        ..add(
          Code(
            'final $tmpVarName = '
            '$fieldName!.parameterProperties(allowEmpty: allowEmpty);',
          ),
        );
      if (needsMapValues) {
        codes.add(Code('mapValues.add($tmpVarName);'));
      }

      if (discriminatorValue != null) {
        codes.add(Code("discriminatorValue ??= r'$discriminatorValue';"));
      }

      codes
        ..add(const Code('break;'))
        ..add(const Code('case '))
        ..add(encodingShapeRef.property('mixed').code)
        ..add(const Code(':'))
        ..add(
          generateEncodingExceptionExpression(
            'Cannot encode field with mixed encoding shape',
          ).statement,
        )
        ..add(const Code('}'));
    }

    return codes;
  }

  List<Code> _generateFieldEncodingLabel({
    required String fieldName,
    required Model fieldModel,
    required String tmpVarName,
    required bool needsValues,
    required bool needsMapValues,
    String? discriminatorValue,
  }) {
    final codes = <Code>[];

    if (fieldModel.encodingShape == EncodingShape.simple) {
      codes.add(
        Code(
          'final $tmpVarName = $fieldName!.toLabel( '
          'explode: explode, allowEmpty: allowEmpty);',
        ),
      );
      if (needsValues) {
        codes.add(Code('values.add($tmpVarName);'));
      }
    } else if (fieldModel.encodingShape == EncodingShape.complex) {
      // Lists with simple content can be encoded directly
      if (fieldModel is ListModel && fieldModel.hasSimpleContent) {
        codes.add(
          Block.of([
            Code('final $tmpVarName = '),
            buildLabelParameterExpression(
              refer(fieldName).nullChecked,
              fieldModel,
              explode: refer('explode'),
              allowEmpty: refer('allowEmpty'),
            ).statement,
          ]),
        );
        if (needsValues) {
          codes.add(Code('values.add($tmpVarName);'));
        }
      } else if (fieldModel is ListModel) {
        // Lists with complex content cannot be encoded
        codes.add(
          refer('EncodingException', 'package:tonik_util/tonik_util.dart')
              .call([
                literalString(
                  'Lists with complex content are not supported for encoding',
                ),
              ])
              .thrown
              .statement,
        );
      } else {
        // For complex types (classes, composites), use parameterProperties
        codes.add(
          Code(
            'final $tmpVarName = '
            '$fieldName!.parameterProperties(allowEmpty: allowEmpty);',
          ),
        );
        if (needsMapValues) {
          codes.add(Code('mapValues.add($tmpVarName);'));
        }

        if (discriminatorValue != null) {
          codes.add(
            Code("discriminatorValue ??= r'$discriminatorValue';"),
          );
        }
      }
    } else {
      final encodingShapeRef = refer(
        'EncodingShape',
        'package:tonik_util/tonik_util.dart',
      );

      codes
        ..add(Code('switch ($fieldName!.currentEncodingShape) {'))
        ..add(const Code('case '))
        ..add(encodingShapeRef.property('simple').code)
        ..add(const Code(':'));
      if (needsValues) {
        codes.add(
          Code(
            'values.add($fieldName!.toLabel('
            'explode: explode, allowEmpty: allowEmpty));',
          ),
        );
      }
      codes
        ..add(const Code('break;'))
        ..add(const Code('case '))
        ..add(encodingShapeRef.property('complex').code)
        ..add(const Code(':'))
        ..add(
          Code(
            'final $tmpVarName = '
            '$fieldName!.parameterProperties(allowEmpty: allowEmpty);',
          ),
        );
      if (needsMapValues) {
        codes.add(Code('mapValues.add($tmpVarName);'));
      }

      if (discriminatorValue != null) {
        codes.add(Code("discriminatorValue ??= r'$discriminatorValue';"));
      }

      codes
        ..add(const Code('break;'))
        ..add(const Code('case '))
        ..add(encodingShapeRef.property('mixed').code)
        ..add(const Code(':'))
        ..add(
          generateEncodingExceptionExpression(
            'Cannot encode field with mixed encoding shape',
          ).statement,
        )
        ..add(const Code('}'));
    }

    return codes;
  }

  Code _tryAssignLocal({
    required String variableName,
    required Reference nullableType,
    required Expression decodeExpression,
  }) {
    return Block.of([
      nullableType.code,
      Code(' $variableName;'),
      const Code('\ntry {\n  '),
      Code('$variableName = '),
      decodeExpression.code,
      const Code(';\n} on '),
      refer('Object', 'dart:core').code,
      const Code(' catch (_) {\n  '),
      Code('$variableName = null;'),
      const Code('\n}\n'),
    ]);
  }

  Map<Model, String?> _discriminatorMap(AnyOfModel model) => {
    for (final dm in model.models.toSortedList())
      dm.model: dm.discriminatorValue,
  };

  Constructor _buildFromJsonConstructor(
    String className,
    List<({String normalizedName, Property property})> normalizedProperties,
  ) {
    final localDecls = <Code>[];

    for (final n in normalizedProperties) {
      final modelType = n.property.model;
      final varName = n.normalizedName;

      final decodeExpr = buildFromJsonValueExpression(
        'json',
        model: modelType,
        nameManager: nameManager,
        package: package,
        contextClass: className,
      );

      localDecls.add(
        _tryAssignLocal(
          variableName: varName,
          nullableType: _nullableTypeReference(modelType),
          decodeExpression: decodeExpr,
        ),
      );
    }

    final ctorArgs = {
      for (final n in normalizedProperties)
        n.normalizedName: refer(n.normalizedName),
    };

    final validationCheck = _buildAllNullValidation(
      normalizedProperties,
      'Invalid JSON for $className: all variants failed to decode',
      generateJsonDecodingExceptionExpression,
    );

    return Constructor(
      (b) =>
          b
            ..factory = true
            ..name = 'fromJson'
            ..requiredParameters.add(
              Parameter(
                (p) =>
                    p
                      ..name = 'json'
                      ..type = refer('Object?', 'dart:core'),
              ),
            )
            ..body = Block.of([
              ...localDecls,
              validationCheck,
              refer(className, package).call([], ctorArgs).returned.statement,
            ]),
    );
  }

  Method _buildToJsonMethod(
    String className,
    AnyOfModel model,
    List<({String normalizedName, Property property})> normalizedProperties,
  ) {
    final body = <Code>[
      declareFinal(
        'values',
      ).assign(literalSet([], refer('Object?', 'dart:core'))).statement,
      declareFinal(
        'mapValues',
      ).assign(literalList([], buildMapStringObjectType())).statement,
    ];

    final hasDiscriminator = model.discriminator != null;
    final discMap = _discriminatorMap(model);
    if (hasDiscriminator) {
      body
        ..add(
          TypeReference(
            (b) =>
                b
                  ..symbol = 'String'
                  ..url = 'dart:core'
                  ..isNullable = true,
          ).code,
        )
        ..add(const Code(' discriminatorValue;'));
    }

    for (final n in normalizedProperties) {
      final name = n.normalizedName;
      final valueExpr = buildToJsonPropertyExpression(
        name,
        n.property,
        forceNonNullReceiver: true,
      );

      final discValue = discMap[n.property.model];

      final openIf = Code('if ($name != null) {');
      final decl = Block.of([
        const Code('final '),
        refer('Object?', 'dart:core').code,
        Code(' ${name}Json = '),
        Code(valueExpr),
        const Code(';'),
      ]);

      final blocks = <Code>[openIf, decl];

      // Runtime type checking - add to appropriate collection based on actual
      // type
      final ifMapOpen = [
        const Code('if ('),
        Code('${name}Json'),
        const Code(' is '),
        buildMapStringObjectType().code,
        const Code(') {'),
      ];
      final addMap = Code('mapValues.add(${name}Json);');
      final maybeDisc =
          hasDiscriminator && discValue != null
              ? Code("discriminatorValue ??= r'$discValue';")
              : const Code('');

      blocks
        ..addAll([
          ...ifMapOpen,
          addMap,
          maybeDisc,
          const Code('} else {'),
          Code('values.add(${name}Json);'),
          const Code('}'),
        ])
        ..add(const Code('}'));

      body.addAll(blocks);
    }

    // Handle empty case
    body
      ..add(const Code('if (values.isEmpty && mapValues.isEmpty) return null;'))
      // Handle mixed encoding at runtime - throw exception
      ..addAll([
        const Code('if (values.isNotEmpty && mapValues.isNotEmpty) {'),
        generateEncodingExceptionExpression(
          'Mixed encoding not supported for $className: cannot encode both '
          'simple and complex values',
        ).statement,
        const Code('}'),
      ])
      // Handle simple values only
      ..addAll([
        const Code('if (values.isNotEmpty) {'),
        const Code('if (values.length > 1) {'),
        generateEncodingExceptionExpression(
          'Ambiguous anyOf encoding for $className: multiple values provided, '
          'anyOf requires exactly one value',
        ).statement,
        const Code('}'),
        const Code('return values.first;'),
        const Code('}'),
      ]);

    // Handle complex values only - merge maps
    final mergeBlocks = [
      const Code('final map = '),
      literalMap(
        {},
        refer('String', 'dart:core'),
        refer('Object?', 'dart:core'),
      ).statement,
      const Code('for (final m in mapValues) { map.addAll(m); }'),
    ];
    if (hasDiscriminator) {
      mergeBlocks.add(
        Code(
          'if (discriminatorValue != null) { '
          "map.putIfAbsent('${model.discriminator}', "
          '() => discriminatorValue); }',
        ),
      );
    }
    mergeBlocks.add(const Code('return map;'));

    body
      ..addAll([
        const Code('if (mapValues.isNotEmpty) {'),
        ...mergeBlocks,
        const Code('}'),
      ])
      // Fallback
      ..add(const Code('return null;'));

    return Method(
      (b) =>
          b
            ..name = 'toJson'
            ..returns = refer('Object?', 'dart:core')
            ..lambda = false
            ..body = Block.of(body),
    );
  }

  Method _buildToSimpleMethod(
    String className,
    AnyOfModel model,
    List<({String normalizedName, Property property})> normalizedProperties,
  ) {
    final hasRuntimeChecks = normalizedProperties.any((prop) {
      return prop.property.model.encodingShape == EncodingShape.mixed;
    });

    final needsValues =
        hasRuntimeChecks ||
        normalizedProperties.any((prop) {
          final model = prop.property.model;
          if (model is ListModel) {
            return model.hasSimpleContent;
          }
          return model.encodingShape == EncodingShape.simple;
        });
    final needsMapValues =
        hasRuntimeChecks ||
        normalizedProperties.any((prop) {
          final model = prop.property.model;
          if (model is ListModel) {
            return !model.hasSimpleContent;
          }
          return model.encodingShape != EncodingShape.simple;
        });

    final body = <Code>[];

    if (needsValues) {
      body.add(
        declareFinal(
          'values',
        ).assign(literalSet([], refer('String', 'dart:core'))).statement,
      );
    }

    if (needsMapValues) {
      body.add(
        declareFinal(
          'mapValues',
        ).assign(literalList([], buildMapStringStringType())).statement,
      );
    }

    final hasDiscriminator = model.discriminator != null;
    final discMap = _discriminatorMap(model);

    final hasComplexFields =
        hasDiscriminator &&
        normalizedProperties.any((prop) {
          final model = prop.property.model;
          return model.encodingShape != EncodingShape.simple;
        });

    if (hasComplexFields) {
      body
        ..add(
          TypeReference(
            (b) =>
                b
                  ..symbol = 'String'
                  ..url = 'dart:core'
                  ..isNullable = true,
          ).code,
        )
        ..add(const Code(' discriminatorValue;'));
    }

    for (final n in normalizedProperties) {
      final name = n.normalizedName;
      final discValue = discMap[n.property.model];

      body
        ..add(Code('if ($name != null) {'))
        ..addAll(
          _generateFieldEncoding(
            fieldName: name,
            fieldModel: n.property.model,
            tmpVarName: '${name}Simple',
            isForm: false,
            needsValues: needsValues,
            needsMapValues: needsMapValues,
            discriminatorValue: hasDiscriminator ? discValue : null,
          ),
        )
        ..add(const Code('}'));
    }

    final mergeBlocks = <Code>[
      const Code('final map = '),
      buildEmptyMapStringString().statement,
    ];

    if (needsMapValues) {
      mergeBlocks.add(
        const Code('for (final m in mapValues) { map.addAll(m); }'),
      );
    }
    if (hasDiscriminator) {
      mergeBlocks.addAll([
        const Code('if (discriminatorValue != null) { '),
        Code("map.putIfAbsent('${model.discriminator}', () => "),
        const Code('discriminatorValue'),
        const Code(');'),
        const Code(' }'),
      ]);
    }
    mergeBlocks
      ..add(const Code('return map.toSimple('))
      ..addAll([
        const Code('explode: explode, '),
        const Code('allowEmpty: allowEmpty, '),
        const Code('alreadyEncoded: true'),
        const Code(');'),
      ]);

    if (needsValues && needsMapValues) {
      // Mixed types - check for ambiguity
      body.addAll([
        const Code("if (values.isEmpty && mapValues.isEmpty) return '';"),
        const Code('if (mapValues.isNotEmpty && values.isNotEmpty) {'),
        generateEncodingExceptionExpression(
          'Ambiguous anyOf simple encoding for $className: '
          'mixing simple and complex values',
        ).statement,
        const Code('}'),
        const Code('if (values.isNotEmpty) {'),
        const Code('if (values.length > 1) {'),
        generateEncodingExceptionExpression(
          'Ambiguous anyOf simple encoding for $className: '
          'multiple values provided, anyOf requires exactly one value',
        ).statement,
        const Code('}'),
        const Code('return values.first;'),
        const Code('} else {'),
        ...mergeBlocks,
        const Code('}'),
      ]);
    } else if (needsValues) {
      body.addAll([
        const Code("if (values.isEmpty) return '';"),
        const Code('if (values.length > 1) {'),
        generateEncodingExceptionExpression(
          'Ambiguous anyOf simple encoding for $className: '
          'multiple values provided, anyOf requires exactly one value',
        ).statement,
        const Code('}'),
        const Code('return values.first;'),
      ]);
    } else if (needsMapValues) {
      body.addAll(mergeBlocks);
    } else {
      body.add(const Code("return '';"));
    }

    return Method(
      (b) =>
          b
            ..name = 'toSimple'
            ..returns = refer('String', 'dart:core')
            ..optionalParameters.addAll(buildEncodingParameters())
            ..lambda = false
            ..body = Block.of(body),
    );
  }

  Constructor _buildFromSimpleConstructor(
    String className,
    List<({String normalizedName, Property property})> normalizedProperties,
  ) {
    final localDecls = <Code>[];
    final decodableProperties =
        <({String normalizedName, Property property})>[];
    final nonDecodableProperties =
        <({String normalizedName, Property property})>[];

    for (final n in normalizedProperties) {
      final modelType = n.property.model;
      final varName = n.normalizedName;

      if (modelType is ListModel && !modelType.hasSimpleContent) {
        nonDecodableProperties.add(n);
      } else {
        decodableProperties.add(n);

        final decodeExpr = switch (modelType) {
          EnumModel() ||
          ClassModel() ||
          AllOfModel() ||
          OneOfModel() ||
          AnyOfModel() => refer(
                nameManager.modelName(modelType),
                package,
              )
              .property('fromSimple')
              .call(
                [
                  refer('value'),
                ],
                {
                  'explode': refer('explode'),
                },
              ),
          _ => buildSimpleValueExpression(
            refer('value'),
            model: modelType,
            isRequired: true,
            nameManager: nameManager,
            package: package,
            contextClass: className,
            explode: refer('explode'),
          ),
        };

        localDecls.add(
          _tryAssignLocal(
            variableName: varName,
            nullableType: _nullableTypeReference(modelType),
            decodeExpression: decodeExpr,
          ),
        );
      }
    }

    final ctorArgs = {
      for (final n in normalizedProperties)
        n.normalizedName:
            nonDecodableProperties.contains(n)
                ? literalNull
                : refer(n.normalizedName),
    };

    final validationCheck = _buildAllNullValidation(
      decodableProperties,
      'Invalid simple value for $className: all variants failed to decode',
      generateSimpleDecodingExceptionExpression,
    );

    return Constructor(
      (b) =>
          b
            ..factory = true
            ..name = 'fromSimple'
            ..requiredParameters.add(
              Parameter(
                (p) =>
                    p
                      ..name = 'value'
                      ..type = refer('String?', 'dart:core'),
              ),
            )
            ..optionalParameters.add(
              buildBoolParameter('explode', required: true),
            )
            ..body = Block.of([
              ...localDecls,
              validationCheck,
              refer(className, package).call([], ctorArgs).returned.statement,
            ]),
    );
  }

  Constructor _buildFromFormConstructor(
    String className,
    List<({String normalizedName, Property property})> normalizedProperties,
  ) {
    final localDecls = <Code>[];
    final decodableProperties =
        <({String normalizedName, Property property})>[];
    final nonDecodableProperties =
        <({String normalizedName, Property property})>[];

    for (final n in normalizedProperties) {
      final modelType = n.property.model;
      final varName = n.normalizedName;

      if (modelType is ListModel && !modelType.hasSimpleContent) {
        nonDecodableProperties.add(n);
      } else {
        decodableProperties.add(n);

        final decodeExpr = switch (modelType) {
          EnumModel() ||
          ClassModel() ||
          AllOfModel() ||
          OneOfModel() ||
          AnyOfModel() => refer(
                nameManager.modelName(modelType),
                package,
              )
              .property('fromForm')
              .call(
                [
                  refer('value'),
                ],
                {
                  'explode': refer('explode'),
                },
              ),
          _ => buildFromFormValueExpression(
            refer('value'),
            model: modelType,
            isRequired: true,
            nameManager: nameManager,
            package: package,
            contextClass: className,
          ),
        };

        localDecls.add(
          _tryAssignLocal(
            variableName: varName,
            nullableType: _nullableTypeReference(modelType),
            decodeExpression: decodeExpr,
          ),
        );
      }
    }

    final ctorArgs = {
      for (final n in normalizedProperties)
        n.normalizedName:
            nonDecodableProperties.contains(n)
                ? literalNull
                : refer(n.normalizedName),
    };

    final validationCheck = _buildAllNullValidation(
      decodableProperties,
      'Invalid form value for $className: all variants failed to decode',
      generateFormatDecodingExceptionExpression,
    );

    return Constructor(
      (b) =>
          b
            ..factory = true
            ..name = 'fromForm'
            ..requiredParameters.add(
              Parameter(
                (p) =>
                    p
                      ..name = 'value'
                      ..type = refer('String?', 'dart:core'),
              ),
            )
            ..optionalParameters.add(
              buildBoolParameter('explode', required: true),
            )
            ..body = Block.of([
              ...localDecls,
              validationCheck,
              refer(className, package).call([], ctorArgs).returned.statement,
            ]),
    );
  }

  Method _buildCurrentEncodingShapeGetter(
    String className,
    List<({String normalizedName, Property property})> normalizedProperties,
  ) {
    final encodingShapeType = refer(
      'EncodingShape',
      'package:tonik_util/tonik_util.dart',
    );

    final body = <Code>[
      const Code('final shapes = <'),
      encodingShapeType.code,
      const Code('>{};'),
    ];

    for (final n in normalizedProperties) {
      final name = n.normalizedName;
      final fieldModel = n.property.model;
      final isSimple = fieldModel.encodingShape == EncodingShape.simple;
      final isList = fieldModel is ListModel;

      body.add(Code('if ($name != null) {'));
      if (isSimple) {
        body.addAll([
          const Code('  shapes.add('),
          encodingShapeType.property('simple').code,
          const Code(');'),
        ]);
      } else if (isList) {
        body.addAll([
          const Code('  shapes.add('),
          encodingShapeType.property('complex').code,
          const Code(');'),
        ]);
      } else {
        body.add(Code('  shapes.add($name!.currentEncodingShape);'));
      }
      body.add(const Code('}'));
    }

    body.addAll([
      const Code('if (shapes.isEmpty) {'),
      const Code('  throw '),
      refer('StateError', 'dart:core').call([
        literalString('At least one field must be non-null in anyOf'),
      ]).statement,
      const Code('}'),
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
            ..body = Block.of(body),
    );
  }

  Method _buildToFormMethod(
    String className,
    AnyOfModel model,
    List<({String normalizedName, Property property})> normalizedProperties,
  ) {
    final hasRuntimeChecks = normalizedProperties.any((prop) {
      return prop.property.model.encodingShape == EncodingShape.mixed;
    });

    final needsValues =
        hasRuntimeChecks ||
        normalizedProperties.any((prop) {
          final model = prop.property.model;
          if (model is ListModel) {
            return model.hasSimpleContent;
          }
          return model.encodingShape == EncodingShape.simple;
        });
    final needsMapValues =
        hasRuntimeChecks ||
        normalizedProperties.any((prop) {
          final model = prop.property.model;
          if (model is ListModel) {
            return !model.hasSimpleContent;
          }
          return model.encodingShape != EncodingShape.simple;
        });

    final body = <Code>[];

    if (needsValues) {
      body.add(
        declareFinal(
          'values',
        ).assign(literalSet([], refer('String', 'dart:core'))).statement,
      );
    }

    if (needsMapValues) {
      body.add(
        declareFinal(
          'mapValues',
        ).assign(literalList([], buildMapStringStringType())).statement,
      );
    }

    final hasDiscriminator = model.discriminator != null;
    final discMap = _discriminatorMap(model);
    if (hasDiscriminator) {
      body
        ..add(
          TypeReference(
            (b) =>
                b
                  ..symbol = 'String'
                  ..url = 'dart:core'
                  ..isNullable = true,
          ).code,
        )
        ..add(const Code(' discriminatorValue;'));
    }

    for (final n in normalizedProperties) {
      final name = n.normalizedName;
      final discValue = discMap[n.property.model];

      body
        ..add(Code('if ($name != null) {'))
        ..addAll(
          _generateFieldEncoding(
            fieldName: name,
            fieldModel: n.property.model,
            tmpVarName: '${name}Form',
            isForm: true,
            needsValues: needsValues,
            needsMapValues: needsMapValues,
            discriminatorValue: hasDiscriminator ? discValue : null,
          ),
        )
        ..add(const Code('}'));
    }

    final mergeBlocks = <Code>[
      const Code('final map = '),
      buildEmptyMapStringString().statement,
    ];

    if (needsMapValues) {
      mergeBlocks.add(
        const Code('for (final m in mapValues) { map.addAll(m); }'),
      );
    }

    if (hasDiscriminator) {
      mergeBlocks.addAll([
        const Code('if (discriminatorValue != null) { '),
        Code("map.putIfAbsent('${model.discriminator}', () => "),
        const Code('discriminatorValue'),
        const Code(');'),
        const Code(' }'),
      ]);
    }
    mergeBlocks
      ..add(const Code('return map.toForm('))
      ..addAll([
        const Code('explode: explode, '),
        const Code('allowEmpty: allowEmpty, '),
        const Code('alreadyEncoded: true'),
        const Code(');'),
      ]);

    if (needsValues && needsMapValues) {
      body.addAll([
        const Code("if (values.isEmpty && mapValues.isEmpty) return '';"),
        const Code('if (mapValues.isNotEmpty && values.isNotEmpty) {'),
        generateEncodingExceptionExpression(
          'Ambiguous anyOf form encoding for $className: '
          'mixing simple and complex values',
        ).statement,
        const Code('}'),
        const Code('if (values.isNotEmpty) {'),
        const Code('if (values.length > 1) {'),
        generateEncodingExceptionExpression(
          'Ambiguous anyOf form encoding for $className: '
          'multiple values provided, anyOf requires exactly one value',
        ).statement,
        const Code('}'),
        const Code('return values.first;'),
        const Code('} else {'),
        ...mergeBlocks,
        const Code('}'),
      ]);
    } else if (needsValues) {
      body.addAll([
        const Code("if (values.isEmpty) return '';"),
        const Code('if (values.length > 1) {'),
        generateEncodingExceptionExpression(
          'Ambiguous anyOf form encoding for $className: '
          'multiple values provided, anyOf requires exactly one value',
        ).statement,
        const Code('}'),
        const Code('return values.first;'),
      ]);
    } else if (needsMapValues) {
      body.addAll(mergeBlocks);
    } else {
      body.add(const Code("return '';"));
    }

    return Method(
      (b) =>
          b
            ..name = 'toForm'
            ..returns = refer('String', 'dart:core')
            ..optionalParameters.addAll(buildEncodingParameters())
            ..lambda = false
            ..body = Block.of(body),
    );
  }

  Method _buildParameterPropertiesMethod(
    String className,
    AnyOfModel model,
    List<({String normalizedName, Property property})> normalizedProperties,
  ) {
    final hasOnlySimpleTypes = normalizedProperties.every(
      (prop) => prop.property.model.encodingShape == EncodingShape.simple,
    );

    if (hasOnlySimpleTypes) {
      return Method(
        (b) =>
            b
              ..name = 'parameterProperties'
              ..returns = buildMapStringStringType()
              ..optionalParameters.addAll([
                buildBoolParameter('allowEmpty', defaultValue: true),
                buildBoolParameter('allowLists', defaultValue: true),
              ])
              ..body =
                  generateEncodingExceptionExpression(
                    'parameterProperties not supported for $className: '
                    'contains only simple types',
                  ).statement,
      );
    }

    final hasRuntimeChecks = normalizedProperties.any(
      (prop) => prop.property.model.encodingShape == EncodingShape.mixed,
    );

    final hasSimpleTypes = normalizedProperties.any(
      (prop) => prop.property.model.encodingShape == EncodingShape.simple,
    );

    final needsMapValues =
        hasRuntimeChecks ||
        normalizedProperties.any(
          (prop) => prop.property.model.encodingShape != EncodingShape.simple,
        );

    final body = <Code>[];

    if (needsMapValues) {
      body.addAll([
        const Code(r'final _$mapValues = <'),
        buildMapStringStringType().code,
        const Code('>[];'),
      ]);
    }

    final hasDiscriminator = model.discriminator != null;
    final discMap = _discriminatorMap(model);

    if (hasDiscriminator) {
      body
        ..add(
          TypeReference(
            (b) =>
                b
                  ..symbol = 'String'
                  ..url = 'dart:core'
                  ..isNullable = true,
          ).code,
        )
        ..add(const Code(r' _$discriminatorValue;'));
    }

    for (final n in normalizedProperties) {
      final name = n.normalizedName;
      final discValue = discMap[n.property.model];
      final fieldModel = n.property.model;

      final needsProcessing =
          needsMapValues &&
          (fieldModel.encodingShape == EncodingShape.complex ||
              fieldModel.encodingShape == EncodingShape.mixed);

      if (needsProcessing) {
        body
          ..add(Code('if ($name != null) {'))
          ..addAll(
            _generateFieldParameterPropertiesEncoding(
              fieldName: name,
              fieldModel: fieldModel,
              hasDiscriminator: hasDiscriminator,
              discriminatorValue: hasDiscriminator ? discValue : null,
            ),
          )
          ..add(const Code('}'));
      } else if (fieldModel is ListModel) {
        body
          ..add(Code('if ($name != null) {'))
          ..add(const Code('if (!allowLists) {'))
          ..add(
            generateEncodingExceptionExpression(
              'Lists are not supported in this encoding style',
            ).statement,
          )
          ..add(const Code('}'))
          ..add(
            generateEncodingExceptionExpression(
              'Lists are not supported in parameterProperties',
            ).statement,
          )
          ..add(const Code('}'));
      }
    }

    if (hasSimpleTypes) {
      for (final n in normalizedProperties) {
        final name = n.normalizedName;
        final fieldModel = n.property.model;

        if (fieldModel.encodingShape == EncodingShape.simple) {
          body.addAll([
            Code('if ($name != null) {'),
            generateEncodingExceptionExpression(
              'Cannot encode anyOf with simple type to map in '
              'parameterProperties',
            ).statement,
            const Code('}'),
          ]);
        }
      }
    }

    final mergeBlocks = <Code>[
      const Code(r'final _$map = '),
      buildEmptyMapStringString().statement,
    ];

    if (needsMapValues) {
      mergeBlocks.add(
        const Code(r'for (final m in _$mapValues) { _$map.addAll(m); }'),
      );
    }

    if (hasDiscriminator) {
      mergeBlocks.addAll([
        const Code(r'if (_$discriminatorValue != null) { '),
        Code("_\$map.putIfAbsent('${model.discriminator}', () => "),
        const Code(r'_$discriminatorValue'),
        const Code(');'),
        const Code(' }'),
      ]);
    }

    mergeBlocks.add(const Code(r'return _$map;'));

    if (needsMapValues || hasSimpleTypes) {
      body.addAll(mergeBlocks);
    } else {
      body.add(buildEmptyMapStringString().returned.statement);
    }

    return Method(
      (b) =>
          b
            ..name = 'parameterProperties'
            ..returns = buildMapStringStringType()
            ..optionalParameters.addAll([
              buildBoolParameter('allowEmpty', defaultValue: true),
              buildBoolParameter('allowLists', defaultValue: true),
            ])
            ..lambda = false
            ..body = Block.of(body),
    );
  }

  List<Code> _generateFieldParameterPropertiesEncoding({
    required String fieldName,
    required Model fieldModel,
    required bool hasDiscriminator,
    String? discriminatorValue,
  }) {
    final codes = <Code>[];

    if (fieldModel.encodingShape == EncodingShape.complex) {
      // Lists cannot use parameterProperties
      if (fieldModel is ListModel) {
        codes
          ..add(const Code('if (!allowLists) {'))
          ..add(
            generateEncodingExceptionExpression(
              'Lists are not supported in this encoding style',
            ).statement,
          )
          ..add(const Code('}'))
          ..add(
            refer('EncodingException', 'package:tonik_util/tonik_util.dart')
                .call([
                  literalString(
                    'Lists are not supported in parameterProperties',
                  ),
                ])
                .thrown
                .statement,
          );
      } else {
        codes.add(
          Code(
            r'_$mapValues.add('
            '$fieldName!.parameterProperties(allowEmpty: allowEmpty, '
            'allowLists: allowLists));',
          ),
        );

        if (discriminatorValue != null) {
          codes.add(
            Code("_\$discriminatorValue ??= r'$discriminatorValue';"),
          );
        }
      }
    } else if (fieldModel.encodingShape == EncodingShape.mixed) {
      final encodingShapeRef = refer(
        'EncodingShape',
        'package:tonik_util/tonik_util.dart',
      );

      final switchBody = <Code>[
        const Code('case '),
        encodingShapeRef.property('simple').code,
        const Code(':'),
        generateEncodingExceptionExpression(
          'Cannot encode simple type to map in parameterProperties',
        ).statement,
        const Code('case '),
        encodingShapeRef.property('complex').code,
        const Code(':'),
        Code(
          r'_$mapValues.add('
          '$fieldName!.parameterProperties(allowEmpty: allowEmpty, '
          'allowLists: allowLists));',
        ),
      ];

      if (discriminatorValue != null) {
        switchBody.add(
          Code("_\$discriminatorValue ??= r'$discriminatorValue';"),
        );
      }

      switchBody.addAll([
        const Code('break;'),
        const Code('case '),
        encodingShapeRef.property('mixed').code,
        const Code(':'),
        generateEncodingExceptionExpression(
          'Cannot encode field with mixed encoding shape',
        ).statement,
      ]);

      codes
        ..add(Code('switch ($fieldName!.currentEncodingShape) {'))
        ..addAll(switchBody)
        ..add(const Code('}'));
    }

    return codes;
  }

  Method _buildToLabelMethod(
    String className,
    AnyOfModel model,
    List<({String normalizedName, Property property})> normalizedProperties,
  ) {
    final hasRuntimeChecks = normalizedProperties.any((prop) {
      return prop.property.model.encodingShape == EncodingShape.mixed;
    });

    final needsValues =
        hasRuntimeChecks ||
        normalizedProperties.any((prop) {
          final model = prop.property.model;
          if (model is ListModel) {
            return model.hasSimpleContent;
          }
          return model.encodingShape == EncodingShape.simple;
        });
    final needsMapValues =
        hasRuntimeChecks ||
        normalizedProperties.any((prop) {
          final model = prop.property.model;
          if (model is ListModel) {
            return !model.hasSimpleContent;
          }
          return model.encodingShape != EncodingShape.simple;
        });

    final body = <Code>[];

    if (needsValues) {
      body.add(
        declareFinal(
          'values',
        ).assign(literalSet([], refer('String', 'dart:core'))).statement,
      );
    }

    if (needsMapValues) {
      body.add(
        declareFinal(
          'mapValues',
        ).assign(literalList([], buildMapStringStringType())).statement,
      );
    }

    final hasDiscriminator = model.discriminator != null;
    final discMap = _discriminatorMap(model);
    if (hasDiscriminator) {
      body
        ..add(
          TypeReference(
            (b) =>
                b
                  ..symbol = 'String'
                  ..url = 'dart:core'
                  ..isNullable = true,
          ).code,
        )
        ..add(const Code(' discriminatorValue;'));
    }

    for (final n in normalizedProperties) {
      final name = n.normalizedName;
      final discValue = discMap[n.property.model];

      body
        ..add(Code('if ($name != null) {'))
        ..addAll(
          _generateFieldEncodingLabel(
            fieldName: name,
            fieldModel: n.property.model,
            tmpVarName: '${name}Label',
            needsValues: needsValues,
            needsMapValues: needsMapValues,
            discriminatorValue: hasDiscriminator ? discValue : null,
          ),
        )
        ..add(const Code('}'));
    }

    final mergeBlocks = <Code>[
      const Code('final map = '),
      buildEmptyMapStringString().statement,
    ];

    if (needsMapValues) {
      mergeBlocks.add(
        const Code('for (final m in mapValues) { map.addAll(m); }'),
      );
    }

    if (hasDiscriminator) {
      mergeBlocks.addAll([
        const Code('if (discriminatorValue != null) { '),
        Code("map.putIfAbsent('${model.discriminator}', () => "),
        const Code('discriminatorValue'),
        const Code(');'),
        const Code(' }'),
      ]);
    }
    mergeBlocks
      ..add(const Code('return map.toLabel('))
      ..addAll([
        const Code('explode: explode, '),
        const Code('allowEmpty: allowEmpty, '),
        const Code('alreadyEncoded: true'),
        const Code(');'),
      ]);

    if (needsValues && needsMapValues) {
      body.addAll([
        const Code("if (values.isEmpty && mapValues.isEmpty) return '';"),
        const Code('if (mapValues.isNotEmpty && values.isNotEmpty) {'),
        generateEncodingExceptionExpression(
          'Ambiguous anyOf label encoding for $className: '
          'mixing simple and complex values',
        ).statement,
        const Code('}'),
        const Code('if (values.isNotEmpty) {'),
        const Code('if (values.length > 1) {'),
        generateEncodingExceptionExpression(
          'Ambiguous anyOf label encoding for $className: '
          'multiple values provided, anyOf requires exactly one value',
        ).statement,
        const Code('}'),
        const Code('return values.first;'),
        const Code('} else {'),
        ...mergeBlocks,
        const Code('}'),
      ]);
    } else if (needsValues) {
      body.addAll([
        const Code("if (values.isEmpty) return '';"),
        const Code('if (values.length > 1) {'),
        generateEncodingExceptionExpression(
          'Ambiguous anyOf label encoding for $className: '
          'multiple values provided, anyOf requires exactly one value',
        ).statement,
        const Code('}'),
        const Code('return values.first;'),
      ]);
    } else if (needsMapValues) {
      body.addAll(mergeBlocks);
    } else {
      body.add(const Code("return '';"));
    }

    return Method(
      (b) =>
          b
            ..name = 'toLabel'
            ..returns = refer('String', 'dart:core')
            ..optionalParameters.addAll(buildEncodingParameters())
            ..lambda = false
            ..body = Block.of(body),
    );
  }

  Method _buildToMatrixMethod(
    String className,
    AnyOfModel model,
    List<({String normalizedName, Property property})> normalizedProperties,
  ) {
    final hasRuntimeChecks = normalizedProperties.any((prop) {
      return prop.property.model.encodingShape == EncodingShape.mixed;
    });

    final needsValues =
        hasRuntimeChecks ||
        normalizedProperties.any((prop) {
          final model = prop.property.model;
          // Lists with simple content can be encoded directly to strings
          if (model is ListModel) {
            return model.hasSimpleContent;
          }
          return model.encodingShape == EncodingShape.simple;
        });
    final needsMapValues =
        hasRuntimeChecks ||
        normalizedProperties.any((prop) {
          final model = prop.property.model;
          // Lists with complex content need parameterProperties
          if (model is ListModel) {
            return !model.hasSimpleContent;
          }
          return model.encodingShape != EncodingShape.simple;
        });

    final body = <Code>[];

    if (needsValues) {
      body.add(
        declareFinal(
          'values',
        ).assign(literalSet([], refer('String', 'dart:core'))).statement,
      );
    }

    if (needsMapValues) {
      body.add(
        declareFinal(
          'mapValues',
        ).assign(literalList([], buildMapStringStringType())).statement,
      );
    }

    final hasDiscriminator = model.discriminator != null;
    final discMap = _discriminatorMap(model);
    if (hasDiscriminator) {
      body
        ..add(
          TypeReference(
            (b) =>
                b
                  ..symbol = 'String'
                  ..url = 'dart:core'
                  ..isNullable = true,
          ).code,
        )
        ..add(const Code(' discriminatorValue;'));
    }

    for (final n in normalizedProperties) {
      final name = n.normalizedName;
      final discValue = discMap[n.property.model];

      body
        ..add(Code('if ($name != null) {'))
        ..addAll(
          _generateFieldEncodingMatrix(
            fieldName: name,
            fieldModel: n.property.model,
            tmpVarName: '${name}Matrix',
            needsValues: needsValues,
            needsMapValues: needsMapValues,
            discriminatorValue: hasDiscriminator ? discValue : null,
          ),
        )
        ..add(const Code('}'));
    }

    final mergeBlocks = <Code>[
      const Code('final map = '),
      buildEmptyMapStringString().statement,
    ];

    if (needsMapValues) {
      mergeBlocks.add(
        const Code('for (final m in mapValues) { map.addAll(m); }'),
      );
    }

    if (hasDiscriminator) {
      mergeBlocks.addAll([
        const Code('if (discriminatorValue != null) { '),
        Code("map.putIfAbsent('${model.discriminator}', () => "),
        const Code('discriminatorValue'),
        const Code(');'),
        const Code(' }'),
      ]);
    }
    mergeBlocks
      ..add(const Code('return map.toMatrix('))
      ..addAll([
        const Code('paramName, '),
        const Code('explode: explode, '),
        const Code('allowEmpty: allowEmpty, '),
        const Code('alreadyEncoded: true'),
        const Code(');'),
      ]);

    if (needsValues && needsMapValues) {
      body.addAll([
        const Code("if (values.isEmpty && mapValues.isEmpty) return '';"),
        const Code('if (mapValues.isNotEmpty && values.isNotEmpty) {'),
        generateEncodingExceptionExpression(
          'Ambiguous anyOf matrix encoding for $className: '
          'mixing simple and complex values',
        ).statement,
        const Code('}'),
        const Code('if (values.isNotEmpty) {'),
        const Code('if (values.length > 1) {'),
        generateEncodingExceptionExpression(
          'Ambiguous anyOf matrix encoding for $className: '
          'multiple values provided, anyOf requires exactly one value',
        ).statement,
        const Code('}'),
        const Code('return values.first;'),
        const Code('} else {'),
        ...mergeBlocks,
        const Code('}'),
      ]);
    } else if (needsValues) {
      body.addAll([
        const Code("if (values.isEmpty) return '';"),
        const Code('if (values.length > 1) {'),
        generateEncodingExceptionExpression(
          'Ambiguous anyOf matrix encoding for $className: '
          'multiple values provided, anyOf requires exactly one value',
        ).statement,
        const Code('}'),
        const Code('return values.first;'),
      ]);
    } else if (needsMapValues) {
      body.addAll(mergeBlocks);
    } else {
      body.add(const Code("return '';"));
    }

    return Method(
      (b) =>
          b
            ..name = 'toMatrix'
            ..returns = refer('String', 'dart:core')
            ..requiredParameters.add(
              Parameter(
                (b) =>
                    b
                      ..name = 'paramName'
                      ..type = refer('String', 'dart:core'),
              ),
            )
            ..optionalParameters.addAll(buildEncodingParameters())
            ..lambda = false
            ..body = Block.of(body),
    );
  }

  Method _buildToDeepObjectMethod(
    String className,
    AnyOfModel model,
    List<({String normalizedName, Property property})> normalizedProperties,
  ) {
    return Method(
      (b) =>
          b
            ..name = 'toDeepObject'
            ..returns = TypeReference(
              (b) =>
                  b
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
                (b) =>
                    b
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
    AnyOfModel model,
    List<({String normalizedName, Property property})> normalizedProperties,
  ) {
    final body = <Code>[];

    for (final n in normalizedProperties) {
      final name = n.normalizedName;
      final propertyModel = n.property.model;

      // Check if this property can be URI encoded
      if (propertyModel.encodingShape == EncodingShape.complex) {
        // Complex types cannot be URI encoded
        body
          ..add(Code('if ($name != null) {'))
          ..add(
            generateEncodingExceptionExpression(
              'Cannot uriEncode $className: contains complex type',
            ).statement,
          )
          ..add(const Code('}'));
      } else {
        // Simple or mixed types can call uriEncode
        body
          ..add(Code('if ($name != null) {'))
          ..add(
            Code(
              'return $name!.uriEncode(allowEmpty: allowEmpty);',
            ),
          )
          ..add(const Code('}'));
      }
    }

    body.add(
      generateEncodingExceptionExpression(
        'Cannot uriEncode $className: no value set',
      ).statement,
    );

    return Method(
      (b) =>
          b
            ..name = 'uriEncode'
            ..returns = refer('String', 'dart:core')
            ..optionalParameters.add(
              Parameter(
                (b) =>
                    b
                      ..name = 'allowEmpty'
                      ..type = refer('bool', 'dart:core')
                      ..named = true
                      ..required = true,
              ),
            )
            ..lambda = false
            ..body = Block.of(body),
    );
  }

  List<Code> _generateFieldEncodingMatrix({
    required String fieldName,
    required Model fieldModel,
    required String tmpVarName,
    required bool needsValues,
    required bool needsMapValues,
    String? discriminatorValue,
  }) {
    final codes = <Code>[];

    if (fieldModel.encodingShape == EncodingShape.simple) {
      codes.add(
        Block.of([
          Code('final $tmpVarName = '),
          buildMatrixParameterExpression(
            refer(fieldName).nullChecked,
            fieldModel,
            paramName: refer('paramName'),
            explode: refer('explode'),
            allowEmpty: refer('allowEmpty'),
          ).statement,
        ]),
      );
      if (needsValues) {
        codes.add(Code('values.add($tmpVarName);'));
      }
    } else if (fieldModel.encodingShape == EncodingShape.complex) {
      // Lists with simple content can be encoded directly with toMatrix
      if (fieldModel is ListModel && fieldModel.hasSimpleContent) {
        codes.add(
          Block.of([
            Code('final $tmpVarName = '),
            buildMatrixParameterExpression(
              refer(fieldName).nullChecked,
              fieldModel,
              paramName: refer('paramName'),
              explode: refer('explode'),
              allowEmpty: refer('allowEmpty'),
            ).statement,
          ]),
        );
        if (needsValues) {
          codes.add(Code('values.add($tmpVarName);'));
        }
      } else if (fieldModel is ListModel) {
        // Lists with complex content cannot be encoded
        codes.add(
          refer('EncodingException', 'package:tonik_util/tonik_util.dart')
              .call([
                literalString(
                  'Lists with complex content are not supported for encoding',
                ),
              ])
              .thrown
              .statement,
        );
      } else {
        // For complex types (classes, composites), use parameterProperties
        codes.add(
          Code(
            'final $tmpVarName = '
            '$fieldName!.parameterProperties(allowEmpty: allowEmpty);',
          ),
        );
        if (needsMapValues) {
          codes.add(Code('mapValues.add($tmpVarName);'));
        }

        if (discriminatorValue != null) {
          codes.add(
            Code("discriminatorValue ??= r'$discriminatorValue';"),
          );
        }
      }
    } else {
      final encodingShapeRef = refer(
        'EncodingShape',
        'package:tonik_util/tonik_util.dart',
      );

      // For mixed encoding shape, check at runtime if it's a list
      if (fieldModel is ListModel) {
        // Lists can be encoded directly even though they have complex shape
        codes.add(
          Block.of([
            Code('final $tmpVarName = '),
            buildMatrixParameterExpression(
              refer(fieldName).nullChecked,
              fieldModel,
              paramName: refer('paramName'),
              explode: refer('explode'),
              allowEmpty: refer('allowEmpty'),
            ).statement,
          ]),
        );
        if (needsValues) {
          codes.add(Code('values.add($tmpVarName);'));
        }
      } else {
        // For non-list mixed types, use runtime switch
        codes
          ..add(Code('switch ($fieldName!.currentEncodingShape) {'))
          ..add(const Code('case '))
          ..add(encodingShapeRef.property('simple').code)
          ..add(const Code(':'));
        if (needsValues) {
          codes.add(
            refer('values').property('add').call([
              buildMatrixParameterExpression(
                refer(fieldName).nullChecked,
                fieldModel,
                paramName: refer('paramName'),
                explode: refer('explode'),
                allowEmpty: refer('allowEmpty'),
              ),
            ]).statement,
          );
        }
        codes
          ..add(const Code('break;'))
          ..add(const Code('case '))
          ..add(encodingShapeRef.property('complex').code)
          ..add(const Code(':'))
          ..add(
            Code(
              'final $tmpVarName = '
              '$fieldName!.parameterProperties(allowEmpty: allowEmpty);',
            ),
          );
        if (needsMapValues) {
          codes.add(Code('mapValues.add($tmpVarName);'));
        }

        if (discriminatorValue != null) {
          codes.add(Code("discriminatorValue ??= r'$discriminatorValue';"));
        }

        codes
          ..add(const Code('break;'))
          ..add(const Code('case '))
          ..add(encodingShapeRef.property('mixed').code)
          ..add(const Code(':'))
          ..add(
            generateEncodingExceptionExpression(
              'Cannot encode field with mixed encoding shape',
            ).statement,
          )
          ..add(const Code('}'));
      }
    }

    return codes;
  }

  Code _buildAllNullValidation(
    List<({String normalizedName, Property property})> normalizedProperties,
    String errorMessage,
    Expression Function(String) exceptionGenerator,
  ) {
    if (normalizedProperties.isEmpty) {
      return const Code('');
    }

    final nullChecks = normalizedProperties
        .map((n) => '${n.normalizedName} == null')
        .join(' && ');

    return Block.of([
      Code('if ($nullChecks) {'),
      exceptionGenerator(errorMessage).statement,
      const Code('}'),
    ]);
  }
}
