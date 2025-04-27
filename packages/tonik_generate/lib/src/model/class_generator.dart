import 'package:change_case/change_case.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:meta/meta.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/naming/property_name_normalizer.dart';
import 'package:tonik_generate/src/util/copy_with_method_generator.dart';
import 'package:tonik_generate/src/util/core_prefixed_allocator.dart';
import 'package:tonik_generate/src/util/equals_method_generator.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';
import 'package:tonik_generate/src/util/format_with_header.dart';
import 'package:tonik_generate/src/util/hash_code_generator.dart';
import 'package:tonik_generate/src/util/to_json_value_expression_generator.dart';
import 'package:tonik_generate/src/util/type_reference_generator.dart';

/// A generator for creating Dart class files from model definitions.
@immutable
class ClassGenerator {
  const ClassGenerator({required this.nameManager, required this.package});

  final NameManager nameManager;
  final String package;

  static const deprecatedPropertyMessage = 'This property is deprecated.';

  ({String code, String filename}) generate(ClassModel model) {
    final emitter = DartEmitter(
      allocator: CorePrefixedAllocator(),
      orderDirectives: true,
      useNullSafetySyntax: true,
    );

    final snakeCaseName = nameManager.modelName(model).toSnakeCase();

    final library = Library((b) {
      b.body.add(generateClass(model));
    });

    final formatter = DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    );

    final code = formatter.formatWithHeader(library.accept(emitter).toString());

    return (code: code, filename: '$snakeCaseName.dart');
  }

  @visibleForTesting
  Class generateClass(ClassModel model) {
    final className = nameManager.modelName(model);
    final normalizedProperties = normalizeProperties(model.properties.toList());

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
            ..constructors.addAll([
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
              _buildFromJsonConstructor(className, model),
            ])
            ..methods.addAll([
              _buildToJsonMethod(model),
              _buildCopyWithMethod(className, normalizedProperties),
              _buildEqualsMethod(className, normalizedProperties),
              _buildHashCodeMethod(normalizedProperties),
            ])
            ..fields.addAll(
              normalizedProperties.map(
                (prop) => _generateField(prop.property, prop.normalizedName),
              ),
            ),
    );
  }

  Method _buildCopyWithMethod(
    String className,
    List<({String normalizedName, Property property})> properties,
  ) {
    return generateCopyWithMethod(
      className: className,
      properties:
          properties
              .map(
                (prop) => (
                  normalizedName: prop.normalizedName,
                  typeRef: _getTypeReference(prop.property),
                ),
              )
              .toList(),
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

  Constructor _buildFromJsonConstructor(String className, ClassModel model) =>
      Constructor(
        (b) =>
            b
              ..factory = true
              ..name = 'fromJson'
              ..requiredParameters.add(
                Parameter(
                  (b) =>
                      b
                        ..name = 'json'
                        ..type = refer('dynamic', 'dart:core'),
                ),
              )
              ..body = _buildFromJsonBody(className, model),
      );

  Code _buildFromJsonBody(String className, ClassModel model) {
    final normalizedProperties = normalizeProperties(model.properties.toList());

    final invalidJsonError =
        generateArgumentErrorExpression(
          'Invalid JSON for $className: \$json',
        ).statement;

    final codes = <Code>[
      const Code('final map = json;'),
      const Code('if (map is! '),
      buildMapStringDynamicType().code,
      const Code(') {'),
      invalidJsonError,
      const Code('}'),
    ];

    final propertyValidations = <Code>[];
    final propertyAssignments = <String>[];

    for (final prop in normalizedProperties) {
      final property = prop.property;
      final normalizedName = prop.normalizedName;
      final localName = '\$${prop.normalizedName}';
      final jsonKey = property.name;
      final typeCheckCode = _generateTypeCheck(
        property,
        localName,
        jsonKey,
        className,
      );

      propertyValidations.add(typeCheckCode);
      propertyAssignments.add('$normalizedName: $localName');
    }

    codes
      ..addAll(propertyValidations)
      ..add(Code('return $className(${propertyAssignments.join(', ')});'));

    return Block.of(codes);
  }

  Code _generateTypeCheck(
    Property property,
    String localName,
    String jsonKey,
    String className,
  ) {
    final typeRef = typeReference(
      property.model,
      nameManager,
      package,
      isNullableOverride: property.isNullable || !property.isRequired,
    );
    final symbolForMessage = typeRef.symbol;

    final errorMessage =
        'Expected $symbolForMessage${property.isNullable ? '?' : ''} '
        'for ${jsonKey.replaceAll(r'$', r'\$')} of $className, '
        'got \${$localName}';

    final typeCheckError =
        generateArgumentErrorExpression(errorMessage).statement;

    const conditionEnd = Code(') {');

    final checkCodes = <Code>[
      Code("final $localName = map[r'$jsonKey'];"),
      Code('if ($localName is! '),
      typeRef.code,
      conditionEnd,
      typeCheckError,
      const Code('}'),
    ];

    return Block.of(checkCodes);
  }

  Method _buildToJsonMethod(ClassModel model) {
    final normalizedProperties = normalizeProperties(model.properties.toList());

    final parts = <Code>[const Code('{')];
    for (final prop in normalizedProperties) {
      final property = prop.property;
      final name = prop.normalizedName;
      final jsonKeyString = literalString(property.name, raw: true).code;
      final valueExprString = buildToJsonPropertyExpression(name, property);

      if (property.isRequired || property.isNullable) {
        parts.add(Code('$jsonKeyString: $valueExprString, '));
      } else {
        parts.add(Code('if ($name != null) $jsonKeyString: $valueExprString,'));
      }
    }

    parts.add(const Code('}'));

    return Method(
      (b) =>
          b
            ..returns = buildMapStringDynamicType()
            ..name = 'toJson'
            ..lambda = true
            ..body = Block.of(parts),
    );
  }

  Field _generateField(Property property, String normalizedName) {
    final fieldBuilder =
        FieldBuilder()
          ..name = normalizedName
          ..modifier = FieldModifier.final$
          ..type = _getTypeReference(property);

    if (property.isDeprecated) {
      fieldBuilder.annotations.add(
        refer(
          'Deprecated',
          'dart:core',
        ).call([literalString(deprecatedPropertyMessage)]),
      );
    }

    return fieldBuilder.build();
  }

  TypeReference _getTypeReference(Property property) {
    return typeReference(
      property.model,
      nameManager,
      package,
      isNullableOverride: property.isNullable || !property.isRequired,
    );
  }
}
