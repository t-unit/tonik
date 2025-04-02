import 'package:change_case/change_case.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:meta/meta.dart';
import 'package:tonic_core/tonic_core.dart';
import 'package:tonic_generate/src/util/name_manager.dart';
import 'package:tonic_generate/src/util/type_reference_generator.dart';

/// A generator for creating sealed Dart classes from OneOf model definitions.
@immutable
class OneOfGenerator {
  const OneOfGenerator({required this.nameManager, required this.package});

  final NameManager nameManager;
  final String package;

  ({String code, String filename}) generate(OneOfModel model) {
    final emitter = DartEmitter.scoped(
      orderDirectives: true,
      useNullSafetySyntax: true,
    );

    final className = nameManager.modelName(model);
    final snakeCaseName = className.toSnakeCase();

    final library = Library((b) {
      b.directives.add(Directive.part('$snakeCaseName.freezed.dart'));
      b.body.add(generateClass(model));
    });

    final formatter = DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    );

    final code = formatter.format(
      '// Generated code - do not modify by hand\n\n${library.accept(emitter)}',
    );

    return (code: code, filename: '$snakeCaseName.dart');
  }

  @visibleForTesting
  Class generateClass(OneOfModel model) {
    final className = nameManager.modelName(model);

    final stringRef = TypeReference(
      (b) =>
          b
            ..symbol = 'String'
            ..url = 'dart:core',
    );

    final dynamicRef = TypeReference(
      (b) =>
          b
            ..symbol = 'dynamic'
            ..url = 'dart:core',
    );

    final mapStringDynamic = TypeReference(
      (b) =>
          b
            ..symbol = 'Map'
            ..url = 'dart:core'
            ..types.addAll([stringRef, dynamicRef]),
    );

    return Class(
      (b) =>
          b
            ..name = className
            ..annotations.add(
              refer(
                'freezed',
                'package:freezed_annotation/freezed_annotation.dart',
              ),
            )
            ..mixins.add(refer('_\$$className'))
            ..sealed = true
            ..constructors.addAll([
              Constructor(
                (b) =>
                    b
                      ..name = '_'
                      ..constant = true,
              ),
              ...model.models.map(
                (discriminatedModel) => _generateConstructor(
                  className,
                  discriminatedModel,
                  model.discriminator,
                ),
              ),
            ])
            ..methods.addAll([
              Method(
                (b) =>
                    b
                      ..name = 'toJson'
                      ..returns = refer('dynamic')
                      ..body = _generateToJsonBody(className, model)
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
                                ..type = refer('dynamic'),
                        ),
                      )
                      ..body = _generateFromJsonBody(className, model)
                      ..lambda = false,
              ),
            ]),
    );
  }

  Constructor _generateConstructor(
    String parentClassName,
    DiscriminatedModel discriminatedModel,
    String? discriminator,
  ) {
    final rawName =
        discriminatedModel.discriminatorValue ??
        nameManager.modelName(discriminatedModel.model);

    final factoryName = rawName.toCamelCase();

    return Constructor(
      (b) =>
          b
            ..constant = true
            ..factory = true
            ..name = factoryName
            ..redirect = Reference(
              '$parentClassName${factoryName.toPascalCase()}',
            )
            ..requiredParameters.add(
              Parameter(
                (b) =>
                    b
                      ..name = 'value'
                      ..type = getTypeReference(
                        discriminatedModel.model,
                        nameManager,
                        package,
                      ),
              ),
            ),
    );
  }

  Code _generateToJsonBody(String className, OneOfModel model) {
    final cases = model.models
        .map((discriminatedModel) {
          final factoryName =
              discriminatedModel.discriminatorValue ??
              nameManager.modelName(discriminatedModel.model);
          final variantName = '$className${factoryName.toPascalCase()}';

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
      Code(
        'final (dynamic json, String? discriminator) = switch (this) {\n'
        '$cases\n'
        '};\n',
      ),
    ];

    if (model.discriminator != null) {
      blocks.add(
        Code(
          'if (discriminator != null && json is Map<String, dynamic>) {\n'
          "  json.putIfAbsent('${model.discriminator}', () => discriminator);\n"
          '}\n\n',
        ),
      );
    }

    blocks.add(const Code('return json;'));

    return Block.of(blocks);
  }

  Code _generateFromJsonBody(String className, OneOfModel model) {
    final blocks = <Code>[];

    // Check for discriminator if present
    if (model.discriminator != null) {
      final discriminatorExpression = declareFinal('discriminator').assign(
        refer('json')
            .isA(
              TypeReference(
                (b) =>
                    b
                      ..symbol = 'Map'
                      ..url = 'dart:core'
                      ..types.addAll([
                        refer('String', 'dart:core'),
                        refer('dynamic', 'dart:core'),
                      ]),
              ),
            )
            .conditional(
              refer('json').index(literalString(model.discriminator!)),
              literalNull,
            ),
      );

      final cases = <Code>[];

      for (final m in model.models.where(
        (m) =>
            m.discriminatorValue != null &&
            m.model is! PrimitiveModel &&
            m.model is! ListModel &&
            model is! EnumModel,
      )) {
        cases.addAll([
          Code("'${m.discriminatorValue}' => "),
          refer(className).code,
          Code('.${m.discriminatorValue!.toCamelCase()}('),
          refer(nameManager.modelName(m.model), package).code,
          const Code('.fromJson(json)),\n'),
        ]);
      }

      cases.add(const Code('_ => null'));

      blocks.addAll([
        discriminatorExpression.statement,
        const Code('final result = '),
        const Code('switch (discriminator) {'),
        ...cases,
        const Code('};\n\n'),
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
        final factoryName =
            (m.discriminatorValue ?? nameManager.modelName(m.model))
                .toCamelCase();
        cases.addAll([
          getTypeReference(m.model, nameManager, package).code,
          const Code(' s => '),
          refer(className).code,
          Code('.$factoryName(s),\n'),
        ]);
      }

      cases.addAll([
        const Code('_ => '),
        refer('ArgumentError', 'dart:core')
            .call([
              literalString(
                'Invalid JSON type for $className: \${json.runtimeType}',
              ),
            ])
            .thrown
            .code,
        const Code(','),
      ]);

      return Block.of([
        refer('return switch').call([refer('json')]).code,
        const Code(' {\n'),
        ...cases,
        const Code('\n};'),
      ]);
    }

    // Handle primitive types.
    for (final m in model.models.where((m) => m.model is PrimitiveModel)) {
      final typeRef = getTypeReference(m.model, nameManager, package);
      final factoryName =
          (m.discriminatorValue ?? nameManager.modelName(m.model))
              .toCamelCase();

      blocks.add(
        Block.of([
          const Code('if ('),
          refer('json').isA(typeRef).code,
          const Code(') {\n'),
          const Code('  return '),
          refer(className).code,
          Code('.$factoryName(json);\n'),
          const Code('}\n'),
        ]),
      );
    }

    // Try complex types.
    for (final m in model.models.where(
      (m) => m.model is! PrimitiveModel && m.discriminatorValue == null,
    )) {
      final factoryName = nameManager.modelName(m.model).toCamelCase();
      final modelName = nameManager.modelName(m.model);
      final mapType = TypeReference(
        (b) =>
            b
              ..symbol = 'Map'
              ..url = 'dart:core'
              ..types.addAll([
                refer('String', 'dart:core'),
                refer('dynamic', 'dart:core'),
              ]),
      );

      blocks.add(
        Block.of([
          const Code('try {\n'),
          const Code('  return '),
          refer(className).property(factoryName).code,
          const Code('('),
          refer(
            modelName,
            package,
          ).property('fromJson').call([refer('json')]).code,
          const Code(');\n'),
          const Code('} catch (_) {}\n'),
        ]),
      );
    }

    // Throw if no match found.
    blocks.add(
      refer(
        'ArgumentError',
        'dart:core',
      ).call([literalString('Invalid JSON for $className')]).thrown.statement,
    );

    return Block.of(blocks);
  }
}
