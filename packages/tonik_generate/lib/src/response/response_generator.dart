import 'package:change_case/change_case.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:meta/meta.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/util/copy_with_method_generator.dart';
import 'package:tonik_generate/src/util/core_prefixed_allocator.dart';
import 'package:tonik_generate/src/util/equals_method_generator.dart';
import 'package:tonik_generate/src/util/format_with_header.dart';
import 'package:tonik_generate/src/util/hash_code_generator.dart';
import 'package:tonik_generate/src/util/response_property_normalizer.dart';
import 'package:tonik_generate/src/util/type_reference_generator.dart';

/// A generator for creating Dart sealed classes and typedefs
/// from Response definitions.
@immutable
class ResponseGenerator {
  const ResponseGenerator({required this.nameManager, required this.package});

  final NameManager nameManager;
  final String package;

  ({String code, String filename}) generate(Response response) {
    if (!response.hasHeaders && response.bodyCount <= 1) {
      throw ArgumentError(
        'Response must have headers or multiple bodies, '
        'got ${response.bodyCount} bodies and no headers',
      );
    }

    final name = nameManager.responseNames(response).baseName;
    final library = Library((b) {
      switch (response) {
        case ResponseAlias():
          b.body.add(generateTypedef(response, name));
        case ResponseObject() when response.bodies.length <= 1:
          b.body.add(generateResponseClass(response));
        case ResponseObject():
          b.body.addAll(generateMultiBodyResponseClasses(response));
      }
    });

    final emitter = DartEmitter(
      allocator: CorePrefixedAllocator(),
      orderDirectives: true,
      useNullSafetySyntax: true,
    );

    final formatter = DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    );

    final code = formatter.formatWithHeader(library.accept(emitter).toString());

    return (code: code, filename: '${name.toSnakeCase()}.dart');
  }

  @visibleForTesting
  TypeDef generateTypedef(ResponseAlias response, String name) {
    final targetName = nameManager.responseNames(response.response).baseName;

    return TypeDef(
      (b) => b
        ..name = name
        ..definition = refer(targetName, package),
    );
  }

  @visibleForTesting
  Class generateResponseClass(ResponseObject response) {
    final className = nameManager.responseNames(response).baseName;
    final properties = normalizeResponseProperties(response);

    final equalsMethod = generateEqualsMethod(
      className: className,
      properties: properties
          .map(
            (prop) => (
              normalizedName: prop.normalizedName,
              hasCollectionValue: prop.property.model is ListModel,
            ),
          )
          .toList(),
    );

    final hashCodeMethod = generateHashCodeMethod(
      properties: properties
          .map(
            (p) => (
              normalizedName: p.normalizedName,
              hasCollectionValue: p.property.model is ListModel,
            ),
          )
          .toList(),
    );

    final copyWithMethod = generateCopyWithMethod(
      className: className,
      properties: properties
          .map(
            (prop) => (
              normalizedName: prop.normalizedName,
              typeRef: typeReference(
                prop.property.model,
                nameManager,
                package,
              ),
            ),
          )
          .toList(),
    );

    return Class(
      (b) => b
        ..name = className
        ..annotations.add(refer('immutable', 'package:meta/meta.dart'))
        ..constructors.add(
          Constructor(
            (b) => b
              ..constant = true
              ..optionalParameters.addAll(
                properties.map(
                  (prop) => Parameter(
                    (b) => b
                      ..name = prop.normalizedName
                      ..named = true
                      ..required = prop.property.isRequired
                      ..toThis = true,
                  ),
                ),
              ),
          ),
        )
        ..methods.addAll([equalsMethod, hashCodeMethod, copyWithMethod])
        ..fields.addAll(
          properties.map(
            (prop) => Field(
              (b) {
                b
                  ..name = prop.normalizedName
                  ..modifier = FieldModifier.final$
                  ..type = typeReference(
                    prop.property.model,
                    nameManager,
                    package,
                    isNullableOverride: !prop.property.isRequired,
                  );

                if (prop.property.isDeprecated) {
                  b.annotations.add(
                    refer('Deprecated', 'dart:core').call([
                      literalString('This field is deprecated.'),
                    ]),
                  );
                }
              },
            ),
          ),
        ),
    );
  }

  @visibleForTesting
  List<Class> generateMultiBodyResponseClasses(ResponseObject response) {
    final className = nameManager.responseNames(response).baseName;
    final normalizedBaseProperties = normalizeResponseProperties(response);

    // Create base sealed class
    final baseClass = Class(
      (b) => b
        ..name = className
        ..sealed = true
        ..annotations.add(refer('immutable', 'package:meta/meta.dart'))
        ..constructors.add(
          Constructor(
            (b) => b
              ..constant = true
              ..optionalParameters.addAll(
                normalizedBaseProperties.map(
                  (prop) => Parameter(
                    (b) => b
                      ..name = prop.normalizedName
                      ..named = true
                      ..required = prop.property.isRequired
                      ..toThis = true,
                  ),
                ),
              ),
          ),
        )
        ..fields.addAll(
          normalizedBaseProperties.map(
            (prop) => Field(
              (b) {
                b
                  ..name = prop.normalizedName
                  ..modifier = FieldModifier.final$
                  ..type = typeReference(
                    prop.property.model,
                    nameManager,
                    package,
                    isNullableOverride: !prop.property.isRequired,
                  );

                if (prop.property.isDeprecated) {
                  b.annotations.add(
                    refer('Deprecated', 'dart:core').call([
                      literalString('This field is deprecated.'),
                    ]),
                  );
                }
              },
            ),
          ),
        ),
    );

    // Create implementation classes for each body type
    final implementationClasses = response.bodies.map((body) {
      final implementationName = nameManager
          .responseNames(response)
          .implementationNames[body.rawContentType]!;

      // Create properties for equals and hashCode methods
      final allProperties = normalizeResponseProperties(
        ResponseObject(
          name: null,
          context: response.context,
          headers: response.headers,
          description: '',
          bodies: {
            ResponseBody(
              model: body.model,
              rawContentType: 'application/json',
              contentType: ContentType.json,
            ),
          },
        ),
      );

      final equalsMethod = generateEqualsMethod(
        className: implementationName,
        properties: allProperties
            .map(
              (prop) => (
                normalizedName: prop.normalizedName,
                hasCollectionValue: prop.property.model is ListModel,
              ),
            )
            .toList(),
      );

      final hashCodeMethod = generateHashCodeMethod(
        properties: allProperties
            .map(
              (p) => (
                normalizedName: p.normalizedName,
                hasCollectionValue: p.property.model is ListModel,
              ),
            )
            .toList(),
      );

      final methods = [equalsMethod, hashCodeMethod];

      // Add copyWith method if we have headers
      if (response.headers.isNotEmpty) {
        final copyWithMethod = generateCopyWithMethod(
          className: implementationName,
          properties: allProperties
              .map(
                (prop) => (
                  normalizedName: prop.normalizedName,
                  typeRef: typeReference(
                    prop.property.model,
                    nameManager,
                    package,
                  ),
                ),
              )
              .toList(),
        );
        methods.add(copyWithMethod);
      }

      return Class(
        (b) => b
          ..name = implementationName
          ..extend = refer(className)
          ..annotations.add(
            refer('immutable', 'package:meta/meta.dart'),
          )
          ..constructors.add(
            Constructor(
              (b) => b
                ..constant = true
                ..optionalParameters.addAll([
                  ...normalizedBaseProperties.map(
                    (prop) => Parameter(
                      (b) => b
                        ..name = prop.normalizedName
                        ..named = true
                        ..required = prop.property.isRequired
                        ..toSuper = true,
                    ),
                  ),
                  Parameter(
                    (b) => b
                      ..name = 'body'
                      ..named = true
                      ..required = true
                      ..toThis = true,
                  ),
                ]),
            ),
          )
          ..methods.addAll(methods)
          ..fields.add(
            Field(
              (b) => b
                ..name = 'body'
                ..modifier = FieldModifier.final$
                ..type = typeReference(
                  body.model,
                  nameManager,
                  package,
                ),
            ),
          ),
      );
    }).toList();

    return [baseClass, ...implementationClasses];
  }
}
