import 'package:change_case/change_case.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:meta/meta.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/util/core_prefixed_allocator.dart';
import 'package:tonik_generate/src/util/equals_method_generator.dart';
import 'package:tonik_generate/src/util/format_with_header.dart';
import 'package:tonik_generate/src/util/hash_code_generator.dart';
import 'package:tonik_generate/src/util/type_reference_generator.dart';

@immutable
class ResponseWrapperGenerator {
  const ResponseWrapperGenerator({
    required this.nameManager,
    required this.package,
  });

  final NameManager nameManager;
  final String package;

  ({String code, String filename}) generate(Operation operation) {
    final emitter = DartEmitter(
      allocator: CorePrefixedAllocator(),
      orderDirectives: true,
      useNullSafetySyntax: true,
    );

    final (baseName, _) = nameManager.responseWrapperNames(operation);
    final classes = generateClasses(operation);

    final library = Library((b) {
      b.body.addAll(classes);
    });

    final formatter = DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    );

    final code = formatter.formatWithHeader(library.accept(emitter).toString());
    final filename = '${baseName.toSnakeCase()}.dart';
    return (code: code, filename: filename);
  }

  @visibleForTesting
  List<Class> generateClasses(Operation operation) {
    if (operation.responses.isEmpty) {
      throw ArgumentError('At least one response is required');
    }

    final (baseName, subclassNames) = nameManager.responseWrapperNames(
      operation,
    );

    final baseClass = Class(
      (b) =>
          b
            ..name = baseName
            ..sealed = true
            ..constructors.add(Constructor((b) => b..constant = true)),
    );

    final classes = <Class>[baseClass];

    for (final entry in subclassNames.entries) {
      final status = entry.key;
      final subclassName = entry.value;
      final response = operation.responses[status];
      Field? bodyField;

      if (response != null && response.bodyCount == 1 && !response.hasHeaders) {
        final body = response.resolved.bodies.first;
        bodyField = Field(
          (b) =>
              b
                ..name = 'body'
                ..modifier = FieldModifier.final$
                ..type = typeReference(body.model, nameManager, package),
        );
      } else if (response != null &&
          (response.bodyCount > 1 || response.hasHeaders)) {
        final responseClassName =
            nameManager.responseNames(response.resolved).baseName;

        bodyField = Field(
          (b) =>
              b
                ..name = 'body'
                ..modifier = FieldModifier.final$
                ..type = refer(responseClassName, package),
        );
      }

      final properties =
          bodyField == null
              ? <({String normalizedName, bool hasCollectionValue})>[]
              : [(normalizedName: bodyField.name, hasCollectionValue: false)];

      final equalsMethod = generateEqualsMethod(
        className: subclassName,
        properties: properties,
      );

      final hashCodeMethod = generateHashCodeMethod(properties: properties);

      classes.add(
        Class(
          (b) =>
              b
                ..name = subclassName
                ..extend = refer(baseName)
                ..annotations.add(refer('immutable', 'package:meta/meta.dart'))
                ..fields.addAll(bodyField == null ? [] : [bodyField])
                ..methods.addAll([equalsMethod, hashCodeMethod])
                ..constructors.add(
                  Constructor((cb) {
                    cb.constant = true;
                    if (bodyField != null) {
                      cb.optionalParameters.add(
                        Parameter(
                          (pb) =>
                              pb
                                ..name = bodyField!.name
                                ..named = true
                                ..required = true
                                ..toThis = true,
                        ),
                      );
                    }
                  }),
                ),
        ),
      );
    }
    return classes;
  }
}
