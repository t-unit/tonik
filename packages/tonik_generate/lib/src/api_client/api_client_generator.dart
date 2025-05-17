import 'package:change_case/change_case.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:meta/meta.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/util/core_prefixed_allocator.dart';
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
    return Class(
      (b) =>
          b
            ..name = nameManager.tagName(tag)
            ..fields.add(
              Field(
                (b) =>
                    b
                      ..name = '_dio'
                      ..modifier = FieldModifier.final$
                      ..type = refer('Dio', 'package:dio/dio.dart'),
              ),
            )
            ..constructors.add(
              Constructor(
                (b) =>
                    b
                      ..requiredParameters.add(
                        Parameter(
                          (b) =>
                              b
                                ..name = '_dio'
                                ..toThis = true,
                        ),
                      ),
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

    final requiredParams = parameters.where((p) => p.required).toList();
    final optionalParams = parameters.where((p) => !p.required).toList();

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
            ..optionalParameters.addAll([
              ...requiredParams.map((p) => p.rebuild((b) => b..named = true)),
              ...optionalParams.map((p) => p.rebuild((b) => b..named = true)),
            ])
            ..modifier = MethodModifier.async
            ..lambda = true
            ..body =
                refer(
                  nameManager.operationName(operation),
                  package,
                ).call([refer('_dio')]).property('call').call([], {
                  for (final param in parameters) param.name: refer(param.name),
                }).code,
    );
  }
}
