import 'package:change_case/change_case.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:meta/meta.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/util/core_prefixed_allocator.dart';
import 'package:tonik_generate/src/util/equals_method_generator.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';
import 'package:tonik_generate/src/util/format_with_header.dart';
import 'package:tonik_generate/src/util/hash_code_generator.dart';
import 'package:tonik_generate/src/util/type_reference_generator.dart';

/// A generator for creating sealed Dart classes from OneOf model definitions.
@immutable
class OneOfGenerator {
  const OneOfGenerator({required this.nameManager, required this.package});

  final NameManager nameManager;
  final String package;

  ({String code, String filename}) generate(OneOfModel model) {
    final emitter = DartEmitter(
      allocator: CorePrefixedAllocator(),
      orderDirectives: true,
      useNullSafetySyntax: true,
    );

    final className = nameManager.modelName(model);
    final snakeCaseName = className.toSnakeCase();

    final library = Library((b) {
      b.body.addAll(generateClasses(model));
    });

    final formatter = DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    );

    final code = formatter.formatWithHeader(library.accept(emitter).toString());

    return (code: code, filename: '$snakeCaseName.dart');
  }

  @visibleForTesting
  List<Class> generateClasses(OneOfModel model) {
    final className = nameManager.modelName(model);

    // Pre-generate variant names and store them for reuse
    final variantNames = _generateVariantNames(model, className);

    final baseClass = _generateBaseClass(model, className, variantNames);
    final subClasses = _generateSubClasses(model, className, variantNames);

    return [baseClass, ...subClasses];
  }

  /// Generate a map of discriminated model to variant class name
  Map<DiscriminatedModel, String> _generateVariantNames(
    OneOfModel model,
    String parentClassName,
  ) {
    final variantNames = <DiscriminatedModel, String>{};

    for (final discriminatedModel in model.models) {
      final rawName =
          discriminatedModel.discriminatorValue ??
          nameManager.modelName(discriminatedModel.model);

      final dummyClass = ClassModel(
        name: '$parentClassName${rawName.toPascalCase()}',
        properties: const [],
        context: model.context,
      );

      final uniqueVariantName = nameManager.modelName(dummyClass);
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
      (b) =>
          b
            ..name = className
            ..sealed = true
            ..annotations.add(refer('immutable', 'package:meta/meta.dart'))
            ..constructors.add(Constructor((b) => b..constant = true))
            ..methods.addAll([
              Method(
                (b) =>
                    b
                      ..name = 'toJson'
                      ..returns = refer('Object?', 'dart:core')
                      ..body = _generateToJsonBody(
                        className,
                        model,
                        variantNames,
                      )
                      ..lambda = false,
              ),
              Method(
                (b) =>
                    b
                      ..name = 'fromJson'
                      ..static = true
                      ..returns = refer(className)
                      ..requiredParameters.add(
                        Parameter(
                          (b) =>
                              b
                                ..name = 'json'
                                ..type = refer('Object?', 'dart:core'),
                        ),
                      )
                      ..body = _generateFromJsonBody(
                        className,
                        model,
                        variantNames,
                      )
                      ..lambda = false,
              ),
            ]),
    );
  }

  List<Class> _generateSubClasses(
    OneOfModel model,
    String parentClassName,
    Map<DiscriminatedModel, String> variantNames,
  ) {
    return model.models.map((discriminatedModel) {
      final variantName = variantNames[discriminatedModel]!;

      final typeRef = typeReference(
        discriminatedModel.model,
        nameManager,
        package,
      );

      final hasCollectionValue = discriminatedModel.model is ListModel;

      return Class(
        (b) =>
            b
              ..name = variantName
              ..extend = refer(parentClassName)
              ..annotations.add(refer('immutable', 'package:meta/meta.dart'))
              ..fields.add(
                Field(
                  (b) =>
                      b
                        ..name = 'value'
                        ..modifier = FieldModifier.final$
                        ..type = typeRef,
                ),
              )
              ..constructors.add(
                Constructor(
                  (b) =>
                      b
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
      );
    }).toList();
  }

  Code _generateToJsonBody(
    String className,
    OneOfModel model,
    Map<DiscriminatedModel, String> variantNames,
  ) {
    final cases = model.models
        .map((discriminatedModel) {
          final variantName = variantNames[discriminatedModel]!;

          final isPrimitive = discriminatedModel.model is PrimitiveModel;
          final jsonValue = isPrimitive ? 'value' : 'value.toJson()';
          final discriminatorValue =
              discriminatedModel.discriminatorValue != null
                  ? "'${discriminatedModel.discriminatorValue}'"
                  : 'null';

          return '$variantName(:final value) => '
              '($jsonValue, $discriminatorValue)';
        })
        .join(',\n');

    final blocks = [
      Code.scope((allocate) {
        final dynamicRef = refer('dynamic', 'dart:core');
        final stringNullableRef = refer('String?', 'dart:core');

        return 'final (${allocate(dynamicRef)} json, '
            '${allocate(stringNullableRef)} discriminator) = switch (this) {\n'
            '$cases\n'
            '};\n';
      }),
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

      for (final m in model.models.where(
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
          const Code(',\n'),
        ]);
      }

      resultCases.add(const Code('_ => null'));

      blocks.addAll([
        ...discriminatorCode,
        const Code('final result = '),
        const Code('switch (discriminator) {\n'),
        ...resultCases,
        const Code('\n};\n'),
        const Code('if (result != null) {\n'),
        const Code('  return result;\n'),
        const Code('}\n'),
      ]);
    }

    // Check for primitive types
    final hasPrimitives = model.models.any((m) => m.model is PrimitiveModel);
    final hasOnlyPrimitives =
        !model.models.any((m) => m.model is! PrimitiveModel);

    if (hasPrimitives && hasOnlyPrimitives) {
      final cases = <Code>[];

      for (final m in model.models.where((m) => m.model is PrimitiveModel)) {
        final variantName = variantNames[m]!;

        cases.addAll([
          typeReference(m.model, nameManager, package).code,
          Code(' s => $variantName(s), '),
        ]);
      }

      cases.addAll([
        const Code('_ => '),
        generateJsonDecodingExceptionExpression(
          'Invalid JSON type for $className: \${json.runtimeType}',
        ).code,
        const Code(','),
      ]);

      return Block.of([
        const Code('return switch (json) {\n'),
        ...cases,
        const Code('\n};'),
      ]);
    }

    // Handle primitive types.
    for (final m in model.models.where((m) => m.model is PrimitiveModel)) {
      final typeRef = typeReference(m.model, nameManager, package);
      final variantName = variantNames[m]!;

      blocks.add(
        Block.of([
          const Code('if ('),
          refer('json').isA(typeRef).code,
          const Code(') {\n'),
          const Code('  return '),
          refer(variantName).call([refer('json')]).statement,
          const Code('}\n'),
        ]),
      );
    }

    // Try complex types.
    for (final m in model.models.where(
      (m) => m.model is! PrimitiveModel && m.discriminatorValue == null,
    )) {
      final modelName = nameManager.modelName(m.model);
      final variantName = variantNames[m]!;

      blocks.add(
        Block.of([
          const Code('try {\n'),
          const Code('  return '),
          refer(variantName).call([
            refer(
              modelName,
              package,
            ).property('fromJson').call([refer('json')]),
          ]).code,
          const Code(';\n'),
          const Code('} on '),
          refer('Object', 'dart:core').code,
          const Code(' catch(_) {}\n'),
        ]),
      );
    }

    // Throw if no match found.
    blocks.add(
      generateJsonDecodingExceptionExpression(
        'Invalid JSON for $className',
      ).statement,
    );

    return Block.of(blocks);
  }

  Method _buildHashCodeMethod(bool hasCollectionValue) {
    return generateHashCodeMethod(
      properties: [
        (normalizedName: 'value', hasCollectionValue: hasCollectionValue),
      ],
    );
  }
}
