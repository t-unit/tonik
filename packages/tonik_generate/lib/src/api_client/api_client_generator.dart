import 'package:change_case/change_case.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:meta/meta.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/util/core_prefixed_allocator.dart';
import 'package:tonik_generate/src/util/format_with_header.dart';
import 'package:tonik_generate/src/util/response_type_generator.dart';

@immutable
class ApiClientGenerator {
  const ApiClientGenerator({required this.nameManager, required this.package});

  final NameManager nameManager;
  final String package;

  ({String code, String filename}) generate(
    Set<Operation> operations,
    Tag tag,
  ) {
    final emitter = DartEmitter(
      allocator: CorePrefixedAllocator(),
      orderDirectives: true,
      useNullSafetySyntax: true,
    );

    final className = nameManager.tagName(tag);
    final snakeCaseName = className.toSnakeCase();

    final library = Library((b) {
      b.body.add(generateClass(operations, tag));
    });

    final formatter = DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    );

    final code = formatter.formatWithHeader(library.accept(emitter).toString());

    return (code: code, filename: '$snakeCaseName.dart');
  }

  @visibleForTesting
  Class generateClass(Set<Operation> operations, Tag tag) {
    final className = nameManager.tagName(tag);

    return Class(
      (b) =>
          b
            ..name = className
            ..fields.add(
              Field(
                (b) =>
                    b
                      ..name = '_dio'
                      ..type = refer('Dio', 'package:dio/dio.dart')
                      ..modifier = FieldModifier.final$,
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
            ..methods.addAll(
              operations.map((operation) {
                final operationName = nameManager.operationName(operation);
                final responseType = resultTypeForOperation(
                  operation,
                  nameManager,
                  package,
                );
                return Method(
                  (b) =>
                      b
                        ..name = operationName.toCamelCase()
                        ..returns = TypeReference(
                          (b) =>
                              b
                                ..symbol = 'Future'
                                ..url = 'dart:async'
                                ..types.add(responseType),
                        )
                        ..modifier = MethodModifier.async
                        ..body = refer(operationName, package)
                            .newInstance([
                              refer('_dio', 'package:dio/dio.dart'),
                            ])
                            .property('call')
                            .call([])
                            .code,
                );
              }),
            ),
    );
  }
}
