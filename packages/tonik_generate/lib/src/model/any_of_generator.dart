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
        model.models.map((discriminated) {
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

    final fromJsonCtor = _buildFromJsonConstructor(
      className,
      normalized,
    );

    final fromSimpleCtor = _buildFromSimpleConstructor(
      className,
      normalized,
    );

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

    final toJsonMethod = _buildToJsonMethod(
      className,
      model,
      normalized,
    );

    final toSimpleMethod = _buildToSimpleMethod(
      className,
      model,
      normalized,
    );

    final toFormMethod = _buildToFormMethod(
      className,
      model,
      normalized,
    );

    final simplePropsMethod = _buildSimplePropertiesMethod(
      className,
      model,
      normalized,
    );

    final formPropsMethod = _buildFormPropertiesMethod(
      className,
      model,
      normalized,
    );

    return Class(
      (b) =>
          b
            ..name = className
            ..annotations.add(refer('immutable', 'package:meta/meta.dart'))
            ..constructors.add(defaultCtor)
            ..constructors.add(fromJsonCtor)
            ..constructors.add(fromSimpleCtor)
            ..constructors.add(fromFormCtor)
            ..methods.addAll([
              _buildCurrentEncodingShapeGetter(className, normalized),
              toJsonMethod,
              toSimpleMethod,
              toFormMethod,
              simplePropsMethod,
              formPropsMethod,
              generateEqualsMethod(
                className: className,
                properties: propsForEquality,
              ),
              generateHashCodeMethod(properties: propsForEquality),
              copyWithMethod,
            ])
            ..fields.addAll(fields),
    );
  }

  Reference _nullableTypeReference(Model model) => typeReference(
    model,
    nameManager,
    package,
    isNullableOverride: true,
  );

  bool needsRuntimeShapeCheck(Model model) {
    return model is CompositeModel;
  }

  /// Generates encoding code for a field with proper shape handling.
  ///
  /// For static types (primitives, classes), generates direct method calls.
  /// For dynamic types (oneOf, anyOf, allOf), generates runtime switch on
  /// currentEncodingShape.
  List<Code> _generateFieldEncoding({
    required String fieldName,
    required Model fieldModel,
    required String tmpVarName,
    required bool isForm,
    String? discriminatorValue,
  }) {
    final toMethodName = isForm ? 'toForm' : 'toSimple';
    final propertiesMethodName = isForm ? 'formProperties' : 'simpleProperties';
    final codes = <Code>[];

    if (!needsRuntimeShapeCheck(fieldModel)) {
      if (fieldModel.encodingShape == EncodingShape.simple) {
        codes
          ..add(
            Code(
              'final $tmpVarName = $fieldName!.$toMethodName( '
              'explode: explode, allowEmpty: allowEmpty);',
            ),
          )
          ..add(Code('values.add($tmpVarName);'));
      } else {
        codes
          ..add(
            Code(
              'final $tmpVarName = '
              '$fieldName!.$propertiesMethodName(allowEmpty: allowEmpty);',
            ),
          )
          ..add(Code('mapValues.add($tmpVarName);'));

        if (discriminatorValue != null) {
          codes.add(Code("discriminatorValue ??= '$discriminatorValue';"));
        }

        codes.add(
          Code(
            'values.add($tmpVarName.$toMethodName('
            'explode: explode, allowEmpty: allowEmpty));',
          ),
        );
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
        ..add(const Code(':'))
        ..add(
          Code(
            'values.add($fieldName!.$toMethodName('
            'explode: explode, allowEmpty: allowEmpty));',
          ),
        )
        ..add(const Code('break;'))
        ..add(const Code('case '))
        ..add(encodingShapeRef.property('complex').code)
        ..add(const Code(':'))
        ..add(
          Code(
            'final $tmpVarName = '
            '$fieldName!.$propertiesMethodName(allowEmpty: allowEmpty);',
          ),
        )
        ..add(Code('mapValues.add($tmpVarName);'));

      if (discriminatorValue != null) {
        codes.add(Code("discriminatorValue ??= '$discriminatorValue';"));
      }

      codes
        ..add(
          Code(
            'values.add($tmpVarName.$toMethodName('
            'explode: explode, allowEmpty: allowEmpty));',
          ),
        )
        ..add(const Code('break;'))
        ..add(const Code('case '))
        ..add(encodingShapeRef.property('mixed').code)
        ..add(const Code(':'))
        ..add(
          generateEncodingExceptionExpression(
            'Cannot encode field with mixed encoding shape',
          ).code,
        )
        ..add(const Code(';'))
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
    for (final dm in model.models) dm.model: dm.discriminatorValue,
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
              refer(className, package).call([], ctorArgs).returned.statement,
            ]),
    );
  }

  Method _buildToJsonMethod(
    String className,
    AnyOfModel model,
    List<({String normalizedName, Property property})> normalizedProperties,
  ) {
    final body = [
      declareFinal(
        'values',
      ).assign(literalList([], refer('Object?', 'dart:core'))).statement,
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
              ? Code("discriminatorValue ??= '$discValue';")
              : const Code('');
      const ifMapClose = Code('}');
      final addValue = Code('values.add(${name}Json);');
      const closeIf = Code('}');

      body.addAll([
        openIf,
        decl,
        ...ifMapOpen,
        addMap,
        maybeDisc,
        ifMapClose,
        addValue,
        closeIf,
      ]);
    }

    body.add(const Code('if (values.isEmpty) return null;'));

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

    body.addAll([
      const Code('if (values.length > 1) {'),
      generateEncodingExceptionExpression(
        'Ambiguous anyOf encoding for $className: multiple values provided, '
        'anyOf requires exactly one value',
      ).statement,
      const Code('}'),
      const Code('return values.first;'),
    ]);

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
    final body = [
      declareFinal(
        'values',
      ).assign(literalList([], refer('String', 'dart:core'))).statement,
      declareFinal(
        'mapValues',
      ).assign(literalList([], buildMapStringStringType())).statement,
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
      final discValue = discMap[n.property.model];

      body
        ..add(Code('if ($name != null) {'))
        ..addAll(
          _generateFieldEncoding(
            fieldName: name,
            fieldModel: n.property.model,
            tmpVarName: '${name}Simple',
            isForm: false,
            discriminatorValue: hasDiscriminator ? discValue : null,
          ),
        )
        ..add(const Code('}'));
    }

    body.addAll([
      const Code("if (values.isEmpty) return '';"),
      const Code(
        'if (mapValues.isNotEmpty && mapValues.length != values.length) {',
      ),
      generateEncodingExceptionExpression(
        'Ambiguous anyOf simple encoding for $className: '
        'mixing simple and complex values',
      ).statement,
      const Code('}'),
    ]);

    final mergeBlocks = <Code>[
      const Code('final map = '),
      literalMap(
        {},
        refer('String', 'dart:core'),
        refer('String', 'dart:core'),
      ).statement,
      const Code('for (final m in mapValues) { map.addAll(m); }'),
    ];
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

    body.addAll([
      const Code('if (values.length > 1) {'),
      generateEncodingExceptionExpression(
        'Ambiguous anyOf simple encoding for $className: '
        'multiple values provided, anyOf requires exactly one value',
      ).statement,
      const Code('}'),
      const Code('return values.first;'),
    ]);

    return Method(
      (b) =>
          b
            ..name = 'toSimple'
            ..returns = refer('String', 'dart:core')
            ..optionalParameters.addAll([
              Parameter(
                (p) =>
                    p
                      ..name = 'explode'
                      ..type = refer('bool', 'dart:core')
                      ..named = true
                      ..required = true,
              ),
              Parameter(
                (p) =>
                    p
                      ..name = 'allowEmpty'
                      ..type = refer('bool', 'dart:core')
                      ..named = true
                      ..required = true,
              ),
            ])
            ..lambda = false
            ..body = Block.of(body),
    );
  }

  Constructor _buildFromSimpleConstructor(
    String className,
    List<({String normalizedName, Property property})> normalizedProperties,
  ) {
    final localDecls = <Code>[];

    for (final n in normalizedProperties) {
      final modelType = n.property.model;
      final varName = n.normalizedName;

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

    final ctorArgs = {
      for (final n in normalizedProperties)
        n.normalizedName: refer(n.normalizedName),
    };

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
              Parameter(
                (p) =>
                    p
                      ..name = 'explode'
                      ..named = true
                      ..required = true
                      ..type = refer('bool', 'dart:core'),
              ),
            )
            ..body = Block.of([
              ...localDecls,
              refer(className, package).call([], ctorArgs).returned.statement,
            ]),
    );
  }

  Constructor _buildFromFormConstructor(
    String className,
    List<({String normalizedName, Property property})> normalizedProperties,
  ) {
    final localDecls = <Code>[];

    for (final n in normalizedProperties) {
      final modelType = n.property.model;
      final varName = n.normalizedName;

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

    final ctorArgs = {
      for (final n in normalizedProperties)
        n.normalizedName: refer(n.normalizedName),
    };

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
              Parameter(
                (p) =>
                    p
                      ..name = 'explode'
                      ..named = true
                      ..required = true
                      ..type = refer('bool', 'dart:core'),
              ),
            )
            ..body = Block.of([
              ...localDecls,
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
      final isSimple = n.property.model.encodingShape == EncodingShape.simple;

      body.add(Code('if ($name != null) {'));
      if (isSimple) {
        body.addAll([
          const Code('  shapes.add('),
          encodingShapeType.property('simple').code,
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
      encodingShapeType.property('mixed').code,
      const Code(';'),
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

  Method _buildSimplePropertiesMethod(
    String className,
    AnyOfModel model,
    List<({String normalizedName, Property property})> normalizedProperties,
  ) {
    final hasSimple = model.models.any(
      (m) => m.model.encodingShape == EncodingShape.simple,
    );
    final hasComplex = model.models.any(
      (m) => m.model.encodingShape != EncodingShape.simple,
    );

    if (hasSimple && !hasComplex) {
      return Method(
        (b) =>
            b
              ..name = 'simpleProperties'
              ..returns = buildMapStringStringType()
              ..optionalParameters.add(
                Parameter(
                  (p) =>
                      p
                        ..name = 'allowEmpty'
                        ..type = refer('bool', 'dart:core')
                        ..named = true
                        ..required = true,
                ),
              )
              ..body =
                  generateEncodingExceptionExpression(
                    'simpleProperties not supported for $className: '
                    'contains primitive values',
                  ).statement,
      );
    }
    final body = <Code>[
      declareFinal(
        'maps',
      ).assign(literalList([], buildMapStringStringType())).statement,
    ];

    for (final n in normalizedProperties) {
      final fn = n.normalizedName;
      final tmp = '${fn}Simple';

      if (needsRuntimeShapeCheck(n.property.model)) {
        body
          ..add(Code('if ($fn != null && '))
          ..add(Code('$fn!.currentEncodingShape == '))
          ..add(
            refer(
              'EncodingShape',
              'package:tonik_util/tonik_util.dart',
            ).property('complex').code,
          )
          ..add(const Code(') { '))
          ..add(const Code('final '))
          ..add(buildMapStringStringType().code)
          ..add(Code(' $tmp = '))
          ..add(Code('$fn!.simpleProperties(allowEmpty: allowEmpty);'))
          ..add(const Code(' maps.add('))
          ..add(Code(tmp))
          ..add(const Code(');'))
          ..add(const Code('}'));
      } else if (n.property.model.encodingShape == EncodingShape.complex) {
        body
          ..add(Code('if ($fn != null) { '))
          ..add(const Code('final '))
          ..add(buildMapStringStringType().code)
          ..add(Code(' $tmp = '))
          ..add(Code('$fn!.simpleProperties(allowEmpty: allowEmpty);'))
          ..add(const Code(' maps.add('))
          ..add(Code(tmp))
          ..add(const Code(');'))
          ..add(const Code('}'));
      }
    }

    if (hasSimple && hasComplex) {
      for (final n in normalizedProperties) {
        final isSimple = n.property.model.encodingShape == EncodingShape.simple;
        if (!isSimple) continue;
        final fn = n.normalizedName;
        body.addAll([
          Code('if ($fn != null) {'),
          generateEncodingExceptionExpression(
            'simpleProperties not supported for $className: '
            'mixing simple and complex values',
          ).statement,
          const Code('}'),
        ]);
      }
    }

    body.addAll([
      const Code('if (maps.isEmpty) return '),
      literalMap(
        {},
        refer('String', 'dart:core'),
        refer('String', 'dart:core'),
      ).code,
      const Code(';'),
      const Code('final map = '),
      literalMap(
        {},
        refer('String', 'dart:core'),
        refer('String', 'dart:core'),
      ).statement,
      const Code('for (final m in maps) { map.addAll(m); }'),
      const Code('return map;'),
    ]);

    return Method(
      (b) =>
          b
            ..name = 'simpleProperties'
            ..returns = buildMapStringStringType()
            ..optionalParameters.add(
              Parameter(
                (p) =>
                    p
                      ..name = 'allowEmpty'
                      ..type = refer('bool', 'dart:core')
                      ..named = true
                      ..required = true,
              ),
            )
            ..body = Block.of(body),
    );
  }

  Method _buildToFormMethod(
    String className,
    AnyOfModel model,
    List<({String normalizedName, Property property})> normalizedProperties,
  ) {
    final body = [
      declareFinal(
        'values',
      ).assign(literalList([], refer('String', 'dart:core'))).statement,
      declareFinal(
        'mapValues',
      ).assign(literalList([], buildMapStringStringType())).statement,
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
      final discValue = discMap[n.property.model];

      body
        ..add(Code('if ($name != null) {'))
        ..addAll(
          _generateFieldEncoding(
            fieldName: name,
            fieldModel: n.property.model,
            tmpVarName: '${name}Form',
            isForm: true,
            discriminatorValue: hasDiscriminator ? discValue : null,
          ),
        )
        ..add(const Code('}'));
    }

    body.addAll([
      const Code("if (values.isEmpty) return '';"),
      const Code(
        'if (mapValues.isNotEmpty && mapValues.length != values.length) {',
      ),
      generateEncodingExceptionExpression(
        'Ambiguous anyOf form encoding for $className: '
        'mixing simple and complex values',
      ).statement,
      const Code('}'),
    ]);

    final mergeBlocks = <Code>[
      const Code('final map = '),
      literalMap(
        {},
        refer('String', 'dart:core'),
        refer('String', 'dart:core'),
      ).statement,
      const Code('for (final m in mapValues) { map.addAll(m); }'),
    ];
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
        const Code('allowEmpty: allowEmpty'),
        const Code(');'),
      ]);

    body.addAll([
      const Code('if (values.length > 1) {'),
      generateEncodingExceptionExpression(
        'Ambiguous anyOf form encoding for $className: '
        'multiple values provided, anyOf requires exactly one value',
      ).statement,
      const Code('}'),
      const Code('return values.first;'),
    ]);

    return Method(
      (b) =>
          b
            ..name = 'toForm'
            ..returns = refer('String', 'dart:core')
            ..optionalParameters.addAll([
              Parameter(
                (p) =>
                    p
                      ..name = 'explode'
                      ..type = refer('bool', 'dart:core')
                      ..named = true
                      ..required = true,
              ),
              Parameter(
                (p) =>
                    p
                      ..name = 'allowEmpty'
                      ..type = refer('bool', 'dart:core')
                      ..named = true
                      ..required = true,
              ),
            ])
            ..lambda = false
            ..body = Block.of(body),
    );
  }

  Method _buildFormPropertiesMethod(
    String className,
    AnyOfModel model,
    List<({String normalizedName, Property property})> normalizedProperties,
  ) {
    final hasSimple = model.models.any(
      (m) => m.model.encodingShape == EncodingShape.simple,
    );
    final hasComplex = model.models.any(
      (m) => m.model.encodingShape != EncodingShape.simple,
    );

    if (hasSimple && !hasComplex) {
      return Method(
        (b) =>
            b
              ..name = 'formProperties'
              ..returns = buildMapStringStringType()
              ..optionalParameters.add(
                Parameter(
                  (p) =>
                      p
                        ..name = 'allowEmpty'
                        ..type = refer('bool', 'dart:core')
                        ..named = true
                        ..required = true,
                ),
              )
              ..body =
                  literalMap(
                    {},
                    refer('String', 'dart:core'),
                    refer('String', 'dart:core'),
                  ).returned.statement,
      );
    }

    final body = <Code>[
      declareFinal(
        'maps',
      ).assign(literalList([], buildMapStringStringType())).statement,
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
      final fn = n.normalizedName;
      final tmp = '${fn}Form';
      final discValue = discMap[n.property.model];

      if (needsRuntimeShapeCheck(n.property.model)) {
        body
          ..add(Code('if ($fn != null && '))
          ..add(Code('$fn!.currentEncodingShape == '))
          ..add(
            refer(
              'EncodingShape',
              'package:tonik_util/tonik_util.dart',
            ).property('complex').code,
          )
          ..add(const Code(') {'))
          ..add(const Code('final '))
          ..add(Code('$tmp = '))
          ..add(Code('$fn!.formProperties(allowEmpty: allowEmpty);'))
          ..add(const Code(' maps.add('))
          ..add(Code(tmp))
          ..add(const Code(');'));

        if (hasDiscriminator && discValue != null) {
          body.add(
            Code("discriminatorValue ??= '$discValue';"),
          );
        }

        body.add(const Code('}'));
      } else if (n.property.model.encodingShape == EncodingShape.complex) {
        body
          ..add(Code('if ($fn != null) { '))
          ..add(const Code('final '))
          ..add(Code('$tmp = '))
          ..add(Code('$fn!.formProperties(allowEmpty: allowEmpty);'))
          ..add(const Code(' maps.add('))
          ..add(Code(tmp))
          ..add(const Code(');'));

        if (hasDiscriminator && discValue != null) {
          body.add(
            Code("discriminatorValue ??= '$discValue';"),
          );
        }

        body.add(const Code('}'));
      }
    }

    body.addAll([
      const Code('if (maps.isEmpty) return '),
      literalMap(
        {},
        refer('String', 'dart:core'),
        refer('String', 'dart:core'),
      ).code,
      const Code(';'),
      const Code('final map = '),
      literalMap(
        {},
        refer('String', 'dart:core'),
        refer('String', 'dart:core'),
      ).statement,
      const Code('for (final m in maps) { map.addAll(m); }'),
    ]);

    if (hasDiscriminator) {
      body.addAll([
        const Code('if (discriminatorValue != null) { '),
        Code("map.putIfAbsent('${model.discriminator}', () => "),
        const Code('discriminatorValue'),
        const Code(');'),
        const Code(' }'),
      ]);
    }

    body.add(const Code('return map;'));

    return Method(
      (b) =>
          b
            ..name = 'formProperties'
            ..returns = buildMapStringStringType()
            ..optionalParameters.add(
              Parameter(
                (p) =>
                    p
                      ..name = 'allowEmpty'
                      ..type = refer('bool', 'dart:core')
                      ..named = true
                      ..required = true,
              ),
            )
            ..body = Block.of(body),
    );
  }
}
