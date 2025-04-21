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

/// A generator for creating Dart sealed classes and typedefs
/// from RequestBody definitions.
@immutable
class RequestBodyGenerator {
  const RequestBodyGenerator({
    required this.nameManager,
    required this.package,
  });

  final NameManager nameManager;
  final String package;

  ({String code, String filename}) generate(RequestBody requestBody) {
    if (requestBody.contentCount <= 1) {
      throw ArgumentError(
        'RequestBody must have at least 2 content types, '
        'got ${requestBody.contentCount}',
      );
    }

    final emitter = DartEmitter(
      allocator: CorePrefixedAllocator(),
      orderDirectives: true,
      useNullSafetySyntax: true,
    );

    final (name, _) = nameManager.getRequestBodyNames(requestBody);

    final library = Library((b) {
      switch (requestBody) {
        case RequestBodyAlias():
          b.body.add(generateTypedef(requestBody, name));
        case RequestBodyObject():
          b.body.addAll(generateClasses(requestBody, name));
      }
    });

    final formatter = DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    );

    final code = formatter.formatWithHeader(library.accept(emitter).toString());

    return (code: code, filename: '${name.toSnakeCase()}.dart');
  }

  @visibleForTesting
  TypeDef generateTypedef(RequestBodyAlias requestBody, String name) {
    final (targetName, _) = nameManager.getRequestBodyNames(
      requestBody.requestBody,
    );

    return TypeDef(
      (b) =>
          b
            ..name = name
            ..definition = refer(targetName, package),
    );
  }

  @visibleForTesting
  List<Class> generateClasses(RequestBodyObject requestBody, String name) {
    final baseClass = _generateBaseClass(name);
    final subClasses = _generateSubClasses(requestBody, name);

    return [baseClass, ...subClasses];
  }

  Class _generateBaseClass(String className) {
    return Class(
      (b) =>
          b
            ..name = className
            ..sealed = true
            ..annotations.add(refer('immutable', 'package:meta/meta.dart'))
            ..constructors.add(Constructor((b) => b..constant = true)),
    );
  }

  List<Class> _generateSubClasses(
    RequestBodyObject requestBody,
    String parentClassName,
  ) {
    final (_, subclassNames) = nameManager.getRequestBodyNames(requestBody);
    return requestBody.resolvedContent.map((content) {
      final className = subclassNames[content.rawContentType]!;
      final typeRef = typeReference(content.model, nameManager, package);
      final hasCollectionValue = content.model is ListModel;

      return Class(
        (b) =>
            b
              ..name = className
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
                  className: className,
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

  Method _buildHashCodeMethod(bool hasCollectionValue) {
    return generateHashCodeMethod(
      properties: [
        (normalizedName: 'value', hasCollectionValue: hasCollectionValue),
      ],
    );
  }
}
