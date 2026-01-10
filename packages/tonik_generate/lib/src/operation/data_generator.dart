import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/util/to_form_value_expression_generator.dart';
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

      // Build switch cases for multiple content types
      final switchCases = <Code>[];
      for (final c in content) {
        final variantName = nameManager
            .requestBodyNames(requestBody)
            .$2[c.rawContentType]!;

        switchCases
          ..add(const Code('final '))
          ..add(refer(variantName, package).code)
          ..add(const Code(' value => value.'));

        switch (c.contentType) {
          case .text || .bytes:
            switchCases.add(const Code('value,'));
          case .json:
            switchCases.add(
              buildToJsonPropertyExpression(
                'value',
                Property(
                  name: 'value',
                  model: c.model,
                  isRequired: true,
                  isNullable: false,
                  isDeprecated: false,
                ),
              ).code,
            );
            switchCases.add(const Code(','));
          case .form:
            switchCases.add(
              buildToFormValueExpression(
                'value',
                c.model,
                useQueryComponent: true,
                explodeLiteral: true,
                allowEmptyLiteral: true,
              ).code,
            );
            switchCases.add(const Code(','));
        }
      }

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
            ...switchCases,
            const Code('\n};'),
          ]),
      );
    }

    final model = content.first.model;
    final contentType = content.first.contentType;
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

    // Build return expression based on content type
    final bodyCode = [const Code('return ')];
    switch (contentType) {
      case ContentType.text || ContentType.bytes:
        bodyCode.add(const Code('body;'));
      case ContentType.json:
        bodyCode
          ..add(buildToJsonPropertyExpression('body', property).code)
          ..add(const Code(';'));
      case ContentType.form:
        final formExpr = buildToFormValueExpression(
          'body',
          model,
          useQueryComponent: true,
          explodeLiteral: true,
          allowEmptyLiteral: true,
        );
        bodyCode
          ..add(formExpr.code)
          ..add(const Code(';'));
    }

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
        ..body = Block.of(bodyCode),
    );
  }
}
