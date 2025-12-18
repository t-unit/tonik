import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/util/to_json_value_expression_generator.dart';
import 'package:tonik_generate/src/util/type_reference_generator.dart';

/// Generator for creating data method for operations.
class DataGenerator {
  const DataGenerator({required this.nameManager, required this.package});

  final NameManager nameManager;
  final String package;

  /// Generates a data expression for the operation.
  Method generateDataMethod(Operation operation) {
    final requestBody = operation.requestBody;
    if (requestBody == null || requestBody.resolvedContent.isEmpty) {
      return Method(
        (b) => b
          ..name = '_data'
          ..returns = refer('Object?', 'dart:core')
          ..lambda = false
          ..body = const Code('return null;'),
      );
    }

    final content = requestBody.resolvedContent;
    final hasMultipleContent = content.length > 1;
    final isRequired = requestBody.isRequired;

    if (hasMultipleContent) {
      final parameterType = TypeReference(
        (b) => b
          ..symbol = nameManager.requestBodyNames(requestBody).$1
          ..url = package
          ..isNullable = !isRequired,
      );

      return Method(
        (b) => b
          ..name = '_data'
          ..returns = refer('Object?', 'dart:core')
          ..optionalParameters.add(
            Parameter(
              (b) => b
                ..name = 'body'
                ..type = parameterType
                ..named = true
                ..required = isRequired,
            ),
          )
          ..lambda = false
          ..body = Block.of([
            if (!isRequired) const Code('if (body == null) return null;\n'),
            const Code('return switch (body) {'),
            ...content.map((c) {
              final variantName = nameManager
                  .requestBodyNames(requestBody)
                  .$2[c.rawContentType]!;
              final valueExpr = buildToJsonPropertyExpression(
                'value',
                Property(
                  name: 'value',
                  model: c.model,
                  isRequired: true,
                  isNullable: false,
                  isDeprecated: false,
                ),
              );
              return Code.scope(
                (a) =>
                    'final ${a(refer(variantName, package))} value => '
                    'value.$valueExpr,',
              );
            }),
            const Code('\n};'),
          ]),
      );
    }

    final model = content.first.model;
    final parameterType = typeReference(
      model,
      nameManager,
      package,
      isNullableOverride: !isRequired,
    );

    final property = Property(
      name: 'body',
      model: model,
      isRequired: isRequired,
      isNullable: !isRequired,
      isDeprecated: false,
    );

    return Method(
      (b) => b
        ..name = '_data'
        ..returns = refer('Object?', 'dart:core')
        ..optionalParameters.add(
          Parameter(
            (b) => b
              ..name = 'body'
              ..type = parameterType
              ..named = true
              ..required = true,
          ),
        )
        ..lambda = false
        ..body = Code(
          'return ${buildToJsonPropertyExpression('body', property)};',
        ),
    );
  }
}
