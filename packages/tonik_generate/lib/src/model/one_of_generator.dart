import 'package:code_builder/code_builder.dart';
import 'package:meta/meta.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/util/composite_guard_builders.dart';
import 'package:tonik_generate/src/util/composite_library_builder.dart';
import 'package:tonik_generate/src/util/doc_comment_formatter.dart';
import 'package:tonik_generate/src/util/equals_method_generator.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';
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

/// A generator for creating sealed Dart classes from OneOf model definitions.
@immutable
class OneOfGenerator {
  const OneOfGenerator({required this.nameManager, required this.package});

  final NameManager nameManager;
  final String package;

  ({String code, String filename}) generate(OneOfModel model) {
    return generateCompositeLibrary(
      model: model,
      isNullable: model.isNullable,
      nameManager: nameManager,
      generateClasses: (actualClassName) =>
          generateClasses(model, actualClassName),
    );
  }

  @visibleForTesting
  List<Class> generateClasses(OneOfModel model, [String? className]) {
    final actualClassName = className ?? nameManager.modelName(model);

    final variantNames = _generateVariantNames(model, actualClassName);
    final baseClass = _generateBaseClass(model, actualClassName, variantNames);
    final subClasses = _generateSubClasses(
      model,
      actualClassName,
      variantNames,
    );

    return [baseClass, ...subClasses];
  }

  /// Generate a map of discriminated model to variant class name
  Map<DiscriminatedModel, String> _generateVariantNames(
    OneOfModel model,
    String parentClassName,
  ) {
    final variantNames = <DiscriminatedModel, String>{};

    for (final discriminatedModel in model.models.toSortedList()) {
      final uniqueVariantName = nameManager.generateVariantName(
        parentClassName: parentClassName,
        model: discriminatedModel.model,
        discriminatorValue: discriminatedModel.discriminatorValue,
      );
      variantNames[discriminatedModel] = uniqueVariantName;
    }

    return variantNames;
  }

  Class _generateBaseClass(
    OneOfModel model,
    String className,
    Map<DiscriminatedModel, String> variantNames,
  ) {
    return Class(
      (b) {
        b
          ..name = className
          ..sealed = true
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
          '$className is read-only and cannot be encoded.',
          raw: true,
        ).code;

        b
          ..constructors.add(Constructor((b) => b..constant = true))
          ..constructors.add(
            model.isWriteOnly
                ? buildWriteOnlyFromSimpleConstructor(className)
                : _generateFromValueConstructor(
                    isForm: false,
                    className: className,
                    model: model,
                    variantNames: variantNames,
                  ),
          )
          ..constructors.add(
            model.isWriteOnly
                ? buildWriteOnlyFromFormConstructor(className)
                : _generateFromValueConstructor(
                    isForm: true,
                    className: className,
                    model: model,
                    variantNames: variantNames,
                  ),
          )
          ..methods.addAll([
            if (model.isReadOnly)
              buildReadOnlyCurrentEncodingShapeGetter(encodingExceptionBody)
            else
              _generateCurrentEncodingShapeGetter(model, variantNames),
            if (model.isReadOnly)
              buildReadOnlyParameterPropertiesMethod(encodingExceptionBody)
            else
              _generateParameterPropertiesMethod(
                className,
                model,
                variantNames,
              ),
            _generateToSimpleMethod(className, model, variantNames),
            _generateToFormMethod(className, model, variantNames),
            _generateToLabelMethod(className, model, variantNames),
            _generateToMatrixMethod(className, model, variantNames),
            buildToDeepObjectMethod(),
            if (model.isReadOnly)
              buildReadOnlyUriEncodeMethod(encodingExceptionBody)
            else
              _generateUriEncodeMethod(className, model, variantNames),
            Method(
              (b) => b
                ..annotations.add(refer('override', 'dart:core'))
                ..name = 'toJson'
                ..returns = refer('Object?', 'dart:core')
                ..body = model.isReadOnly
                    ? encodingExceptionBody
                    : _generateToJsonBody(className, model, variantNames)
                ..lambda = model.isReadOnly,
            ),
          ])
          ..constructors.add(
            model.isWriteOnly
                ? buildWriteOnlyFromJsonConstructor(className)
                : Constructor(
                    (b) => b
                      ..factory = true
                      ..name = 'fromJson'
                      ..requiredParameters.add(
                        Parameter(
                          (p) => p
                            ..name = 'json'
                            ..type = refer('Object?', 'dart:core'),
                        ),
                      )
                      ..body = _generateFromJsonBody(
                        className,
                        model,
                        variantNames,
                      ),
                  ),
          );
      },
    );
  }

  List<Class> _generateSubClasses(
    OneOfModel model,
    String parentClassName,
    Map<DiscriminatedModel, String> variantNames,
  ) {
    final classes = <Class>[];

    for (final discriminatedModel in model.models.toSortedList()) {
      final variantName = variantNames[discriminatedModel]!;

      final typeRef = typeReference(
        discriminatedModel.model,
        nameManager,
        package,
      );

      final hasCollectionValue = discriminatedModel.model is ListModel;

      classes.add(
        Class(
          (b) => b
            ..name = variantName
            ..extend = refer(parentClassName)
            ..annotations.add(refer('immutable', 'package:meta/meta.dart'))
            ..fields.add(
              Field(
                (b) => b
                  ..name = 'value'
                  ..modifier = FieldModifier.final$
                  ..type = typeRef,
              ),
            )
            ..constructors.add(
              Constructor(
                (b) => b
                  ..constant = true
                  ..requiredParameters.add(
                    Parameter((b) => b..name = 'this.value'),
                  ),
              ),
            )
            ..methods.addAll([
              generateEqualsMethod(
                className: variantName,
                properties: [
                  (
                    normalizedName: 'value',
                    hasCollectionValue: hasCollectionValue,
                  ),
                ],
              ),
              _buildHashCodeMethod(hasCollectionValue),
            ]),
        ),
      );
    }

    return classes;
  }

  Code _generateToJsonBody(
    String className,
    OneOfModel model,
    Map<DiscriminatedModel, String> variantNames,
  ) {
    final caseCodes = <Code>[];
    final sortedModels = model.models.toSortedList();
    for (var i = 0; i < sortedModels.length; i++) {
      final discriminatedModel = sortedModels[i];
      final variantName = variantNames[discriminatedModel]!;

      final property = Property(
        name: 'value',
        model: discriminatedModel.model,
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
      );
      final jsonValueExpr = buildToJsonPropertyExpression('value', property);
      final discriminatorValue = discriminatedModel.discriminatorValue != null
          ? "'${discriminatedModel.discriminatorValue}'"
          : 'null';

      caseCodes
        ..add(Code('$variantName(:final value) => ('))
        ..add(jsonValueExpr.code)
        ..add(Code(', $discriminatorValue)'));
      if (i < sortedModels.length - 1) {
        caseCodes.add(const Code(',\n'));
      }
    }

    final blocks = <Code>[
      const Code('final ('),
      refer('dynamic', 'dart:core').code,
      const Code(' json, '),
      refer('String?', 'dart:core').code,
      const Code(' discriminator) = switch (this) {\n'),
      ...caseCodes,
      const Code('\n};'),
    ];

    if (model.discriminator != null) {
      blocks.addAll([
        const Code('if (discriminator != null && json is '),
        buildMapStringObjectType().code,
        const Code(') {'),
        Code(
          "json.putIfAbsent('${model.discriminator}', () => discriminator);",
        ),
        const Code('}'),
      ]);
    }

    blocks.add(const Code('return json;'));

    return Block.of(blocks);
  }

  Code _generateFromJsonBody(
    String className,
    OneOfModel model,
    Map<DiscriminatedModel, String> variantNames,
  ) {
    final blocks = <Code>[];

    if (model.discriminator != null) {
      final discriminatorCode = [
        const Code('final discriminator = json is '),
        buildMapStringObjectType().code,
        const Code(' ? '),
        Code("json['${model.discriminator}']"),
        const Code(' : null;'),
      ];

      final resultCases = <Code>[];

      for (final m in model.models.toSortedList().where(
        (m) =>
            m.discriminatorValue != null &&
            m.model is! PrimitiveModel &&
            m.model is! ListModel &&
            model is! EnumModel,
      )) {
        final variantName = variantNames[m]!;

        resultCases.addAll([
          Code("'${m.discriminatorValue}' => "),
          refer(variantName).call([
            refer(
              nameManager.modelName(m.model),
              package,
            ).property('fromJson').call([refer('json')]),
          ]).code,
          const Code(','),
        ]);
      }

      resultCases.add(const Code('_ => null'));

      blocks.addAll([
        ...discriminatorCode,
        const Code('final result = switch (discriminator) {'),
        ...resultCases,
        const Code('};'),
        const Code('if (result != null) {'),
        const Code('return result;'),
        const Code('}'),
      ]);
    }

    final hasPrimitives = model.models.any((m) => m.model is PrimitiveModel);
    final hasOnlyPrimitives = !model.models.any(
      (m) => m.model is! PrimitiveModel,
    );

    if (hasPrimitives && hasOnlyPrimitives) {
      final cases = <Code>[];

      for (final m in model.models.toSortedList().where(
        (m) => m.model is PrimitiveModel,
      )) {
        final variantName = variantNames[m]!;

        cases.addAll([
          typeReference(m.model, nameManager, package).code,
          Code(' s => $variantName(s),'),
        ]);
      }

      cases.addAll([
        const Code('_ => '),
        generateJsonDecodingExceptionExpression(
          'Invalid JSON type for $className: \${json.runtimeType}',
          raw: true,
        ).code,
        const Code(','),
      ]);

      return Block.of([
        const Code('return switch (json) {'),
        ...cases,
        const Code('};'),
      ]);
    }

    for (final m in model.models.toSortedList().where(
      (m) => m.model is PrimitiveModel,
    )) {
      final typeRef = typeReference(m.model, nameManager, package);
      final variantName = variantNames[m]!;

      blocks.addAll([
        const Code('if ('),
        refer('json').isA(typeRef).code,
        const Code(') {'),
        refer(variantName).call([refer('json')]).returned.statement,
        const Code('}'),
      ]);
    }

    // Fallback: try all non-primitive variants when discriminator doesn't match
    for (final m in model.models.toSortedList().where(
      (m) => m.model is! PrimitiveModel,
    )) {
      final modelType = m.model;
      final modelName = nameManager.modelName(modelType);
      final variantName = variantNames[m]!;

      if (modelType is ListModel) {
        final decodeExpr = buildFromJsonValueExpression(
          'json',
          model: modelType,
          nameManager: nameManager,
          package: package,
          contextClass: className,
        );
        blocks.addAll([
          const Code('try {'),
          refer(variantName).call([decodeExpr]).returned.statement,
          const Code('} on '),
          refer('Object', 'dart:core').code,
          const Code(' catch(_) {}'),
        ]);
      } else {
        blocks.addAll([
          const Code('try {'),
          refer(variantName)
              .call([
                refer(
                  modelName,
                  package,
                ).property('fromJson').call([refer('json')]),
              ])
              .returned
              .statement,
          const Code('} on '),
          refer('Object', 'dart:core').code,
          const Code(' catch(_) {}'),
        ]);
      }
    }

    blocks.add(
      generateJsonDecodingExceptionExpression(
        'Invalid JSON for $className',
      ).statement,
    );

    return Block.of(blocks);
  }

  /// Builds a fromSimple or fromForm factory constructor for oneOf.
  Constructor _generateFromValueConstructor({
    required bool isForm,
    required String className,
    required OneOfModel model,
    required Map<DiscriminatedModel, String> variantNames,
  }) {
    final constructorName = isForm ? 'fromForm' : 'fromSimple';
    final encodingStyleName = isForm ? 'form' : 'simple';
    final bodyBlocks = <Code>[];

    if (model.discriminator != null) {
      final hasDiscriminatedComplexTypes = model.models.any(
        (m) => m.discriminatorValue != null && m.model is! PrimitiveModel,
      );

      if (hasDiscriminatedComplexTypes) {
        bodyBlocks.addAll([
          const Code('if (explode && value != null && value.isNotEmpty) {'),
          const Code("final pairs = value.split(',');"),
          refer('String?', 'dart:core').code,
          const Code(' discriminator;'),
          const Code('for (final pair in pairs) {'),
          const Code("final parts = pair.split('=');"),
          const Code('if (parts.length == 2) {'),
          const Code('final key = '),
          refer('Uri', 'dart:core').property('decodeComponent').call([
            refer('parts').index(literalNum(0)),
          ]).statement,
          Code("if (key == '${model.discriminator}') {"),
          const Code('discriminator = parts[1];'),
          const Code('break;'),
          const Code('}'),
          const Code('}'),
          const Code('}'),
        ]);

        for (final m in model.models.toSortedList().where(
          (m) => m.discriminatorValue != null && m.model is! PrimitiveModel,
        )) {
          final variantName = variantNames[m]!;
          final modelType = m.model;

          bodyBlocks.addAll([
            Code("if (discriminator == '${m.discriminatorValue}') {"),
            const Code('return '),
            refer(variantName).call([
              refer(
                    nameManager.modelName(modelType),
                    package,
                  )
                  .property(constructorName)
                  .call(
                    [refer('value')],
                    {'explode': refer('explode')},
                  ),
            ]).statement,
            const Code('}'),
          ]);
        }

        bodyBlocks.add(const Code('}'));
      }
    }

    for (final m in model.models.toSortedList()) {
      final variantName = variantNames[m]!;
      final modelType = m.model;

      final tryBody = <Code>[];

      if (modelType is PrimitiveModel) {
        final decodeExpr = isForm
            ? buildFromFormValueExpression(
                refer('value'),
                model: modelType,
                isRequired: true,
                nameManager: nameManager,
                package: package,
                contextClass: className,
                explode: refer('explode'),
              )
            : buildSimpleValueExpression(
                refer('value'),
                model: modelType,
                isRequired: true,
                nameManager: nameManager,
                package: package,
                contextClass: className,
                explode: refer('explode'),
              );
        tryBody.add(refer(variantName).call([decodeExpr]).returned.statement);
      } else if (modelType is ListModel && modelType.hasSimpleContent) {
        final decodeExpr = isForm
            ? buildFromFormValueExpression(
                refer('value'),
                model: modelType,
                isRequired: true,
                nameManager: nameManager,
                package: package,
                contextClass: className,
                explode: refer('explode'),
              )
            : buildSimpleValueExpression(
                refer('value'),
                model: modelType,
                isRequired: true,
                nameManager: nameManager,
                package: package,
                contextClass: className,
                explode: refer('explode'),
              );
        tryBody.add(
          refer(variantName).call([decodeExpr]).returned.statement,
        );
      } else if (modelType is ListModel) {
        continue;
      } else {
        final innerDecode =
            refer(
                  nameManager.modelName(modelType),
                  package,
                )
                .property(constructorName)
                .call([refer('value')], {'explode': refer('explode')});
        tryBody.add(
          refer(variantName).call([innerDecode]).returned.statement,
        );
      }

      bodyBlocks.addAll([
        const Code('try {'),
        ...tryBody,
        const Code('} on '),
        refer('DecodingException', 'package:tonik_util/tonik_util.dart').code,
        const Code(' catch (_) {} on '),
        refer('FormatException', 'dart:core').code,
        const Code(' catch (_) {}'),
      ]);
    }

    bodyBlocks.add(
      generateSimpleDecodingExceptionExpression(
        'Invalid $encodingStyleName value for $className',
      ).statement,
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
        ..body = Block.of(bodyBlocks),
    );
  }

  Method _generateToSimpleMethod(
    String className,
    OneOfModel model,
    Map<DiscriminatedModel, String> variantNames,
  ) {
    final caseCodes = <Code>[];

    for (final m in model.models.toSortedList()) {
      final variantName = variantNames[m]!;

      final encodingShape = m.model.encodingShape;
      final discriminatorValue = m.discriminatorValue;

      if (model.discriminator != null &&
          encodingShape != EncodingShape.simple &&
          discriminatorValue != null) {
        if (encodingShape == EncodingShape.mixed) {
          caseCodes.addAll([
            Code.scope(
              (allocate) => '${allocate(refer(variantName))}(:final value) => ',
            ),
            refer('value')
                .property('currentEncodingShape')
                .equalTo(refer('EncodingShape').property('complex'))
                .code,
            const Code('? {'),
            const Code('...'),
            refer('value').property('parameterProperties').call([], {
              'allowEmpty': refer('allowEmpty'),
            }).code,
            const Code(','),
            Code("'${model.discriminator}': '$discriminatorValue',"),
            const Code('}'),
            const Code(
              '.toSimple(explode: explode, allowEmpty: allowEmpty, '
              'alreadyEncoded: true) : ',
            ),
            refer('value').property('toSimple').call([], {
              'explode': refer('explode'),
              'allowEmpty': refer('allowEmpty'),
            }).code,
            const Code(','),
          ]);
        } else {
          caseCodes.addAll([
            Code.scope(
              (allocate) => '${allocate(refer(variantName))}(:final value) => ',
            ),
            const Code('{'),
            const Code('...'),
            refer('value').property('parameterProperties').call([], {
              'allowEmpty': refer('allowEmpty'),
            }).code,
            const Code(','),
            Code("'${model.discriminator}': '$discriminatorValue',"),
            const Code('}'),
            const Code(
              '.toSimple(explode: '
              'explode, allowEmpty: allowEmpty, alreadyEncoded: true),',
            ),
          ]);
        }
      } else if (m.model is ListModel &&
          (m.model as ListModel).hasSimpleContent) {
        // Lists with simple content can be encoded using helper
        caseCodes.addAll([
          Code.scope(
            (allocate) => '${allocate(refer(variantName))}(:final value) => ',
          ),
          buildSimpleParameterExpression(
            refer('value'),
            m.model as ListModel,
            explode: refer('explode'),
            allowEmpty: refer('allowEmpty'),
          ).code,
          const Code(','),
        ]);
      } else if (m.model is ListModel) {
        // Lists with complex content cannot be encoded
        caseCodes.addAll([
          Code.scope(
            (allocate) => '${allocate(refer(variantName))}() => ',
          ),
          refer('EncodingException', 'package:tonik_util/tonik_util.dart')
              .call([
                literalString(
                  'Lists with complex content are not supported for encoding',
                ),
              ])
              .thrown
              .code,
          const Code(','),
        ]);
      } else {
        caseCodes.addAll([
          Code.scope(
            (allocate) => '${allocate(refer(variantName))}(:final value) => ',
          ),
          refer('value').property('toSimple').call([], {
            'explode': refer('explode'),
            'allowEmpty': refer('allowEmpty'),
          }).code,
          const Code(','),
        ]);
      }
    }

    final body = Block.of([
      const Code('return switch (this) {'),
      ...caseCodes,
      const Code('};'),
    ]);

    return Method(
      (b) => b
        ..annotations.add(refer('override', 'dart:core'))
        ..name = 'toSimple'
        ..returns = refer('String', 'dart:core')
        ..optionalParameters.addAll(buildEncodingParameters())
        ..lambda = false
        ..body = body,
    );
  }

  Method _generateToFormMethod(
    String className,
    OneOfModel model,
    Map<DiscriminatedModel, String> variantNames,
  ) {
    final caseCodes = <Code>[];

    for (final m in model.models.toSortedList()) {
      final variantName = variantNames[m]!;

      final encodingShape = m.model.encodingShape;
      final discriminatorValue = m.discriminatorValue;

      if (model.discriminator != null &&
          encodingShape != EncodingShape.simple &&
          discriminatorValue != null) {
        if (encodingShape == EncodingShape.mixed) {
          caseCodes.addAll([
            Code.scope(
              (allocate) => '${allocate(refer(variantName))}(:final value) => ',
            ),
            refer('value')
                .property('currentEncodingShape')
                .equalTo(refer('EncodingShape').property('complex'))
                .code,
            const Code('? {'),
            const Code('...'),
            refer('value').property('parameterProperties').call([], {
              'allowEmpty': refer('allowEmpty'),
            }).code,
            const Code(','),
            Code("'${model.discriminator}': '$discriminatorValue',"),
            const Code('}'),
            const Code(
              '.toForm(explode: explode, allowEmpty: allowEmpty, '
              'useQueryComponent: useQueryComponent) : ',
            ),
            refer('value').property('toForm').call([], {
              'explode': refer('explode'),
              'allowEmpty': refer('allowEmpty'),
              'useQueryComponent': refer('useQueryComponent'),
            }).code,
            const Code(','),
          ]);
        } else {
          caseCodes.addAll([
            Code.scope(
              (allocate) => '${allocate(refer(variantName))}(:final value) => ',
            ),
            const Code('{'),
            const Code('...'),
            refer('value').property('parameterProperties').call([], {
              'allowEmpty': refer('allowEmpty'),
            }).code,
            const Code(','),
            Code("'${model.discriminator}': '$discriminatorValue',"),
            const Code('}'),
            const Code(
              '.toForm(explode: '
              'explode, allowEmpty: allowEmpty, '
              'useQueryComponent: useQueryComponent),',
            ),
          ]);
        }
      } else if (m.model is ListModel &&
          (m.model as ListModel).hasSimpleContent) {
        // Lists with simple content can be encoded using helper
        caseCodes.addAll([
          Code.scope(
            (allocate) => '${allocate(refer(variantName))}(:final value) => ',
          ),
          buildFormParameterExpression(
            refer('value'),
            m.model as ListModel,
            explode: refer('explode'),
            allowEmpty: refer('allowEmpty'),
          ).code,
          const Code(','),
        ]);
      } else if (m.model is ListModel) {
        // Lists with complex content cannot be encoded
        caseCodes.addAll([
          Code.scope(
            (allocate) => '${allocate(refer(variantName))}() => ',
          ),
          refer('EncodingException', 'package:tonik_util/tonik_util.dart')
              .call([
                literalString(
                  'Lists with complex content are not supported for encoding',
                ),
              ])
              .thrown
              .code,
          const Code(','),
        ]);
      } else {
        caseCodes.addAll([
          Code.scope(
            (allocate) => '${allocate(refer(variantName))}(:final value) => ',
          ),
          refer('value').property('toForm').call([], {
            'explode': refer('explode'),
            'allowEmpty': refer('allowEmpty'),
            'useQueryComponent': refer('useQueryComponent'),
          }).code,
          const Code(','),
        ]);
      }
    }

    final body = Block.of([
      const Code('return switch (this) {'),
      ...caseCodes,
      const Code('};'),
    ]);

    return Method(
      (b) => b
        ..annotations.add(refer('override', 'dart:core'))
        ..name = 'toForm'
        ..returns = refer('String', 'dart:core')
        ..optionalParameters.addAll(buildFormEncodingParameters())
        ..lambda = false
        ..body = body,
    );
  }

  Method _buildHashCodeMethod(bool hasCollectionValue) {
    return generateHashCodeMethod(
      properties: [
        (normalizedName: 'value', hasCollectionValue: hasCollectionValue),
      ],
    );
  }

  Method _generateCurrentEncodingShapeGetter(
    OneOfModel model,
    Map<DiscriminatedModel, String> variantNames,
  ) {
    final caseCodes = <Code>[];

    for (final m in model.models.toSortedList()) {
      final variantName = variantNames[m]!;
      final isSimple = m.model.encodingShape == EncodingShape.simple;
      final isList = m.model is ListModel;

      if (isSimple) {
        caseCodes.addAll([
          Code('$variantName() => '),
          refer(
            'EncodingShape',
            'package:tonik_util/tonik_util.dart',
          ).property('simple').code,
          const Code(','),
        ]);
      } else if (isList) {
        // Lists always have complex encoding shape
        caseCodes.addAll([
          Code('$variantName() => '),
          refer(
            'EncodingShape',
            'package:tonik_util/tonik_util.dart',
          ).property('complex').code,
          const Code(','),
        ]);
      } else {
        caseCodes.addAll([
          Code('$variantName(:final value) => '),
          const Code('value.currentEncodingShape,'),
        ]);
      }
    }

    final body = Block.of([
      const Code('return switch (this) {'),
      ...caseCodes,
      const Code('};'),
    ]);

    return Method(
      (b) => b
        ..name = 'currentEncodingShape'
        ..type = MethodType.getter
        ..returns = refer(
          'EncodingShape',
          'package:tonik_util/tonik_util.dart',
        )
        ..lambda = false
        ..body = body,
    );
  }

  Method _generateParameterPropertiesMethod(
    String className,
    OneOfModel model,
    Map<DiscriminatedModel, String> variantNames,
  ) {
    final hasOnlyPrimitives = !model.models.any(
      (m) => m.model is! PrimitiveModel,
    );

    if (hasOnlyPrimitives) {
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
            'only contains primitive types',
            raw: true,
          ).code,
      );
    }

    final caseCodes = <Code>[];

    for (final m in model.models.toSortedList()) {
      final variantName = variantNames[m]!;
      final encodingShape = m.model.encodingShape;
      final discriminatorValue = m.discriminatorValue;

      if (encodingShape == EncodingShape.simple) {
        caseCodes
          ..add(Code('$variantName() => '))
          ..add(
            generateEncodingExceptionExpression(
              'parameterProperties not supported for $className: '
              'cannot determine properties at runtime',
              raw: true,
            ).code,
          );
      } else if (encodingShape == EncodingShape.mixed) {
        caseCodes.add(Code('$variantName(:final value) => '));

        if (discriminatorValue != null) {
          caseCodes.addAll([
            const Code('value.currentEncodingShape == '),
            refer(
              'EncodingShape',
              'package:tonik_util/tonik_util.dart',
            ).property('complex').code,
            const Code('? {'),
            const Code('...'),
            refer('value').property('parameterProperties').call([], {
              'allowEmpty': refer('allowEmpty'),
              'allowLists': refer('allowLists'),
            }).code,
            const Code(','),
            Code("'${model.discriminator}': '$discriminatorValue',"),
            const Code('} : '),
            generateEncodingExceptionExpression(
              'parameterProperties not supported for $className: '
              'cannot determine properties at runtime',
              raw: true,
            ).code,
          ]);
        } else {
          caseCodes.addAll([
            const Code('value.currentEncodingShape == '),
            refer(
              'EncodingShape',
              'package:tonik_util/tonik_util.dart',
            ).property('complex').code,
            const Code('? '),
            refer('value').property('parameterProperties').call([], {
              'allowEmpty': refer('allowEmpty'),
              'allowLists': refer('allowLists'),
            }).code,
            const Code(': '),
            generateEncodingExceptionExpression(
              'parameterProperties not supported for $className: '
              'cannot determine properties at runtime',
              raw: true,
            ).code,
          ]);
        }
      } else {
        if (m.model is ListModel) {
          caseCodes
            ..add(Code('$variantName() => '))
            ..add(
              generateEncodingExceptionExpression(
                'Lists are not supported in parameterProperties',
              ).code,
            );
        } else {
          caseCodes.add(Code('$variantName(:final value) => '));
          if (discriminatorValue != null) {
            caseCodes.addAll([
              const Code('{'),
              const Code('...'),
              refer('value').property('parameterProperties').call([], {
                'allowEmpty': refer('allowEmpty'),
                'allowLists': refer('allowLists'),
              }).code,
              const Code(','),
              Code("'${model.discriminator}': '$discriminatorValue',"),
              const Code('}'),
            ]);
          } else {
            caseCodes.add(
              refer('value').property('parameterProperties').call([], {
                'allowEmpty': refer('allowEmpty'),
                'allowLists': refer('allowLists'),
              }).code,
            );
          }
        }
      }
      caseCodes.add(const Code(','));
    }

    final body = Block.of([
      const Code('return switch (this) {'),
      ...caseCodes,
      const Code('};'),
    ]);

    return Method(
      (b) => b
        ..name = 'parameterProperties'
        ..returns = buildMapStringStringType()
        ..optionalParameters.addAll([
          buildBoolParameter('allowEmpty', defaultValue: true),
          buildBoolParameter('allowLists', defaultValue: true),
        ])
        ..lambda = false
        ..body = body,
    );
  }

  Method _generateToLabelMethod(
    String className,
    OneOfModel model,
    Map<DiscriminatedModel, String> variantNames,
  ) {
    final caseCodes = <Code>[];

    for (final m in model.models.toSortedList()) {
      final variantName = variantNames[m]!;

      final encodingShape = m.model.encodingShape;
      final discriminatorValue = m.discriminatorValue;

      if (model.discriminator != null &&
          encodingShape != EncodingShape.simple &&
          discriminatorValue != null) {
        if (encodingShape == EncodingShape.mixed) {
          caseCodes.addAll([
            Code.scope(
              (allocate) => '${allocate(refer(variantName))}(:final value) => ',
            ),
            refer('value')
                .property('currentEncodingShape')
                .equalTo(refer('EncodingShape').property('complex'))
                .code,
            const Code('? {'),
            const Code('...'),
            refer('value').property('parameterProperties').call([], {
              'allowEmpty': refer('allowEmpty'),
            }).code,
            const Code(','),
            Code("'${model.discriminator}': '$discriminatorValue',"),
            const Code('}'),
            const Code(
              '.toLabel(explode: explode, allowEmpty: allowEmpty, '
              'alreadyEncoded: true) : ',
            ),
            refer('value').property('toLabel').call([], {
              'explode': refer('explode'),
              'allowEmpty': refer('allowEmpty'),
            }).code,
            const Code(','),
          ]);
        } else {
          caseCodes.addAll([
            Code.scope(
              (allocate) => '${allocate(refer(variantName))}(:final value) => ',
            ),
            const Code('{  ...'),
            refer('value').property('parameterProperties').call([], {
              'allowEmpty': refer('allowEmpty'),
            }).code,
            const Code(','),
            Code("'${model.discriminator}': '$discriminatorValue',"),
            const Code('}'),
            const Code(
              '.toLabel(explode: explode, allowEmpty: allowEmpty, '
              'alreadyEncoded: true),',
            ),
          ]);
        }
      } else if (m.model is ListModel &&
          (m.model as ListModel).hasSimpleContent) {
        // Lists with simple content can be encoded using helper
        caseCodes.addAll([
          Code.scope(
            (allocate) => '${allocate(refer(variantName))}(:final value) => ',
          ),
          buildLabelParameterExpression(
            refer('value'),
            m.model as ListModel,
            explode: refer('explode'),
            allowEmpty: refer('allowEmpty'),
          ).code,
          const Code(','),
        ]);
      } else if (m.model is ListModel) {
        // Lists with complex content cannot be encoded
        caseCodes.addAll([
          Code.scope(
            (allocate) => '${allocate(refer(variantName))}() => ',
          ),
          refer('EncodingException', 'package:tonik_util/tonik_util.dart')
              .call([
                literalString(
                  'Lists with complex content are not supported for encoding',
                ),
              ])
              .thrown
              .code,
          const Code(','),
        ]);
      } else {
        caseCodes.addAll([
          Code.scope(
            (allocate) => '${allocate(refer(variantName))}(:final value) => ',
          ),
          refer('value').property('toLabel').call([], {
            'explode': refer('explode'),
            'allowEmpty': refer('allowEmpty'),
          }).code,
          const Code(','),
        ]);
      }
    }

    final body = Block.of([
      const Code('return switch (this) {'),
      ...caseCodes,
      const Code('};'),
    ]);

    return Method(
      (b) => b
        ..annotations.add(refer('override', 'dart:core'))
        ..name = 'toLabel'
        ..returns = refer('String', 'dart:core')
        ..optionalParameters.addAll(buildEncodingParameters())
        ..lambda = false
        ..body = body,
    );
  }

  Method _generateToMatrixMethod(
    String className,
    OneOfModel model,
    Map<DiscriminatedModel, String> variantNames,
  ) {
    final caseCodes = <Code>[];

    for (final m in model.models.toSortedList()) {
      final variantName = variantNames[m]!;

      caseCodes.addAll([
        Code.scope(
          (allocate) => '${allocate(refer(variantName))}(:final value) => ',
        ),
        buildMatrixParameterExpression(
          refer('value'),
          m.model,
          paramName: refer('paramName'),
          explode: refer('explode'),
          allowEmpty: refer('allowEmpty'),
        ).code,
        const Code(','),
      ]);
    }

    final body = Block.of([
      const Code('return switch (this) {'),
      ...caseCodes,
      const Code('};'),
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
        ..body = body,
    );
  }

  Method _generateUriEncodeMethod(
    String className,
    OneOfModel model,
    Map<DiscriminatedModel, String> variantNames,
  ) {
    final caseCodes = <Code>[];

    for (final m in model.models.toSortedList()) {
      final variantName = variantNames[m]!;
      final modelType = m.model;

      // Check if this variant can be URI encoded
      if (modelType.encodingShape == EncodingShape.complex) {
        // Complex types cannot be URI encoded - don't destructure value
        caseCodes.addAll([
          Code.scope(
            (allocate) => '${allocate(refer(variantName))}() => ',
          ),
          generateEncodingExceptionExpression(
            'Cannot uriEncode $className: variant contains complex type',
            raw: true,
          ).code,
          const Code(','),
        ]);
      } else {
        // Simple or mixed types can call uriEncode
        caseCodes.addAll([
          Code.scope(
            (allocate) => '${allocate(refer(variantName))}(:final value) => ',
          ),
          refer('value').property('uriEncode').call([], {
            'allowEmpty': refer('allowEmpty'),
            'useQueryComponent': refer('useQueryComponent'),
          }).code,
          const Code(','),
        ]);
      }
    }

    final body = Block.of([
      const Code('return switch (this) {'),
      ...caseCodes,
      const Code('};'),
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
        ..body = body,
    );
  }
}
