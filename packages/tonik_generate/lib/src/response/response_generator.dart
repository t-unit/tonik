import 'package:change_case/change_case.dart';
import 'package:code_builder/code_builder.dart';
import 'package:meta/meta.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/naming/property_name_normalizer.dart';
import 'package:tonik_generate/src/util/core_prefixed_allocator.dart';
import 'package:tonik_generate/src/util/equals_method_generator.dart';
import 'package:tonik_generate/src/util/hash_code_generator.dart';
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

    final name = nameManager.responseName(response);

    switch (response) {
      case ResponseAlias():
        final typedef = generateTypedef(response, name);
        final library = Library((b) => b.body.add(typedef));
        final code = _formatLibrary(library);
        return (code: code, filename: '${name.toSnakeCase()}.dart');
      case ResponseObject():
        throw UnimplementedError(
          'Complex response objects not yet implemented',
        );
    }
  }

  @visibleForTesting
  TypeDef generateTypedef(ResponseAlias response, String name) {
    final targetName = nameManager.responseName(response.response);

    return TypeDef(
      (b) =>
          b
            ..name = name
            ..definition = refer(targetName),
    );
  }

  @visibleForTesting
  Class generateResponseClass(ResponseObject response) {
    final className = nameManager.responseName(response);
    final properties = <Property>[];

    // Add header properties
    for (final header in response.headers.entries) {
      final headerObject = header.value.resolve(name: header.key);
      final name = header.key;

      properties.add(
        Property(
          name: name.toLowerCase() == 'body' ? '${name}Header' : name,
          model: headerObject.model,
          isRequired: headerObject.isRequired,
          isNullable: false,
          isDeprecated: headerObject.isDeprecated,
        ),
      );
    }

    final body = response.bodies.first;
    properties.add(
      Property(
        name: 'body',
        model: body.model,
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
      ),
    );

    final normalizedProperties = normalizeProperties(properties);

    final sortedProperties = [...normalizedProperties]..sort((a, b) {
      // Required fields come before non-required fields
      if (a.property.isRequired != b.property.isRequired) {
        return a.property.isRequired ? -1 : 1;
      }
      // Keep original order for fields with same required status
      return normalizedProperties.indexOf(a) - normalizedProperties.indexOf(b);
    });

    return Class(
      (b) =>
          b
            ..name = className
            ..annotations.add(refer('immutable', 'package:meta/meta.dart'))
            ..constructors.add(
              Constructor(
                (b) =>
                    b
                      ..constant = true
                      ..optionalParameters.addAll(
                        sortedProperties.map(
                          (prop) => Parameter(
                            (b) =>
                                b
                                  ..name = prop.normalizedName
                                  ..named = true
                                  ..required = prop.property.isRequired
                                  ..toThis = true,
                          ),
                        ),
                      ),
              ),
            )
            ..methods.addAll([
              _buildEqualsMethod(className, sortedProperties),
              _buildHashCodeMethod(sortedProperties),
              _buildCopyWithMethod(className, sortedProperties),
            ])
            ..fields.addAll(
              sortedProperties.map(
                (prop) => Field(
                  (b) =>
                      b
                        ..name = prop.normalizedName
                        ..modifier = FieldModifier.final$
                        ..type = typeReference(
                          prop.property.model,
                          nameManager,
                          package,
                          isNullableOverride: !prop.property.isRequired,
                        ),
                ),
              ),
            ),
    );
  }

  Method _buildEqualsMethod(
    String className,
    List<({String normalizedName, Property property})> properties,
  ) {
    return generateEqualsMethod(
      className: className,
      properties:
          properties
              .map(
                (prop) => (
                  normalizedName: prop.normalizedName,
                  hasCollectionValue: prop.property.model is ListModel,
                ),
              )
              .toList(),
    );
  }

  Method _buildHashCodeMethod(
    List<({String normalizedName, Property property})> properties,
  ) {
    return generateHashCodeMethod(
      properties:
          properties
              .map(
                (p) => (
                  normalizedName: p.normalizedName,
                  hasCollectionValue: p.property.model is ListModel,
                ),
              )
              .toList(),
    );
  }

  Method _buildCopyWithMethod(
    String className,
    List<({String normalizedName, Property property})> properties,
  ) {
    final parameters = <Parameter>[];
    final assignments = <Code>[];

    for (final prop in properties) {
      final name = prop.normalizedName;
      final property = prop.property;
      final typeRef = typeReference(property.model, nameManager, package);

      parameters.add(
        Parameter(
          (b) =>
              b
                ..name = name
                ..named = true
                ..type = TypeReference(
                  (b) =>
                      b
                        ..symbol = typeRef.symbol
                        ..url = typeRef.url
                        ..types.addAll(typeRef.types)
                        ..isNullable = true,
                ),
        ),
      );

      assignments.add(Code('$name: $name ?? this.$name,'));
    }

    return Method(
      (b) =>
          b
            ..name = 'copyWith'
            ..returns = refer(className)
            ..optionalParameters.addAll(parameters)
            ..body = Code(
              'return $className(\n  ${assignments.join('\n  ')}\n);',
            ),
    );
  }

  String _formatLibrary(Library library) {
    final emitter = DartEmitter(
      allocator: CorePrefixedAllocator(),
      orderDirectives: true,
      useNullSafetySyntax: true,
    );

    return '// Generated code - do not modify by hand\n'
        '// ignore_for_file: lines_longer_than_80_chars\n'
        '${library.accept(emitter)}';
  }
}
