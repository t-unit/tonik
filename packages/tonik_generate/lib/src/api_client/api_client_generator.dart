import 'package:change_case/change_case.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:meta/meta.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/util/core_prefixed_allocator.dart';
import 'package:tonik_generate/src/util/doc_comment_formatter.dart';
import 'package:tonik_generate/src/util/format_with_header.dart';
import 'package:tonik_generate/src/util/operation_parameter_generator.dart';
import 'package:tonik_generate/src/util/response_type_generator.dart';

/// Generator for creating API client classes from Operation definitions.
class ApiClientGenerator {
  ApiClientGenerator({required this.nameManager, required this.package});

  final NameManager nameManager;
  final String package;

  ({String code, String filename}) generate(
    Set<Operation> operations,
    Tag tag,
  ) {
    final className = nameManager.tagName(tag);
    final fileNameSnakeCase = className.toSnakeCase();
    final fileName = '$fileNameSnakeCase.dart';

    final library = Library((b) => b..body.add(generateClass(operations, tag)));

    final emitter = DartEmitter(
      allocator: CorePrefixedAllocator(),
      orderDirectives: true,
      useNullSafetySyntax: true,
    );

    final formatter = DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    );

    final code = formatter.formatWithHeader(library.accept(emitter).toString());

    return (code: code, filename: fileName);
  }

  /// Generates the API client class
  @visibleForTesting
  Class generateClass(Set<Operation> operations, Tag tag) {
    // Create private fields for each operation
    final operationFields =
        operations.map((operation) {
          final operationName = nameManager.operationName(operation);
          final fieldName = '_${operationName.toCamelCase()}';

          return Field(
            (b) =>
                b
                  ..name = fieldName
                  ..modifier = FieldModifier.final$
                  ..type = refer(operationName, package),
          );
        }).toList();

    // Create constructor initializers for each operation
    final constructorInitializers =
        operations.map((operation) {
          final operationName = nameManager.operationName(operation);
          final fieldName = '_${operationName.toCamelCase()}';

          return refer(
            fieldName,
          ).assign(refer(operationName, package).call([refer('dio')])).code;
        }).toList();

    return Class(
      (b) =>
          b
            ..name = nameManager.tagName(tag)
            ..fields.addAll(operationFields)
            ..docs.addAll(formatDocComment(tag.description))
            ..constructors.add(
              Constructor(
                (b) =>
                    b
                      ..requiredParameters.add(
                        Parameter(
                          (b) =>
                              b
                                ..name = 'dio'
                                ..type = refer('Dio', 'package:dio/dio.dart'),
                        ),
                      )
                      ..initializers.addAll(constructorInitializers),
              ),
            )
            ..methods.addAll(operations.map(_generateMethod)),
    );
  }

  /// Generates a method for an operation
  Method _generateMethod(Operation operation) {
    final parameters = generateParameters(
      operation: operation,
      nameManager: nameManager,
      package: package,
    );

    final resultType = resultTypeForOperation(operation, nameManager, package);
    final operationFieldName =
        '_${nameManager.operationName(operation).toCamelCase()}';

    final requiredParams = parameters.where((p) => p.required).toList();
    final optionalParams = parameters.where((p) => !p.required).toList();

    final paramMap = {
      for (final param in parameters) param.name: refer(param.name),
    };

    final docs = formatDocComments([operation.summary, operation.description]);

    return Method(
      (b) =>
          b
            ..name = nameManager.operationName(operation).toCamelCase()
            ..returns = TypeReference(
              (b) =>
                  b
                    ..symbol = 'Future'
                    ..url = 'dart:core'
                    ..types.add(resultType),
            )
            ..docs.addAll(docs)
            ..optionalParameters.addAll([
              ...requiredParams.map((p) => p.rebuild((b) => b..named = true)),
              ...optionalParams.map((p) => p.rebuild((b) => b..named = true)),
            ])
            ..modifier = MethodModifier.async
            ..lambda = true
            ..body = refer(operationFieldName).call([], paramMap).code,
    );
  }
}
