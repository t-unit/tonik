import 'package:change_case/change_case.dart';
import 'package:code_builder/code_builder.dart';
import 'package:collection/collection.dart';
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
import 'package:tonik_generate/src/util/from_json_value_expression_generator.dart';
import 'package:tonik_generate/src/util/from_simple_value_expression_generator.dart';
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
      allocator: CorePrefixedAllocator(
        additionalImports: ['package:tonik_util/tonik_util.dart'],
      ),
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

    // Only add fromSimple if all properties are supported
    bool isPrimitiveOrSupportedEnumOrOneOf(Model m) {
      var target = m;
      while (target is AliasModel) {
        target = target.model;
      }
      if (target is PrimitiveModel) return true;
      if (target is EnumModel) return true;
      if (target is OneOfModel) {
        return target.models.every(
          (dm) => isPrimitiveOrSupportedEnumOrOneOf(dm.model),
        );
      }
      return false;
    }

    final unsupported = normalizedProperties.firstWhereOrNull(
      (prop) => !isPrimitiveOrSupportedEnumOrOneOf(prop.property.model),
    );
    final fromSimpleCtor =
        unsupported == null
            ? _buildFromSimpleConstructor(className, model)
            : null;

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
              if (fromSimpleCtor != null) fromSimpleCtor,
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

  Constructor _buildFromSimpleConstructor(String className, ClassModel model) {
    final normalizedProperties = normalizeProperties(model.properties.toList());

    // If there are no properties, just return the constructor call
    if (normalizedProperties.isEmpty) {
      return Constructor(
        (b) =>
            b
              ..factory = true
              ..name = 'fromSimple'
              ..requiredParameters.add(
                Parameter(
                  (b) =>
                      b
                        ..name = 'value'
                        ..type = refer('String?', 'dart:core'),
                ),
              )
              ..body = Code('return $className();'),
      );
    }

    final propertyAssignments = <MapEntry<String, Expression>>[];
    for (var i = 0; i < normalizedProperties.length; i++) {
      final prop = normalizedProperties[i];
      final name = prop.normalizedName;
      final modelType = prop.property.model;
      final isNullable = prop.property.isNullable;

      propertyAssignments.add(
        MapEntry(
          name,
          buildSimpleValueExpression(
            refer('properties[$i]'),
            model: modelType,
            isRequired: !isNullable,
            nameManager: nameManager,
            package: package,
            contextClass: className,
            contextProperty: name,
          ),
        ),
      );
    }

    return Constructor(
      (b) =>
          b
            ..factory = true
            ..name = 'fromSimple'
            ..requiredParameters.add(
              Parameter(
                (b) =>
                    b
                      ..name = 'value'
                      ..type = refer('String?', 'dart:core'),
              ),
            )
            ..body = Block.of([
              const Code('final properties = '),
              Code("value.decodeSimpleStringList(context: r'$className');"),
              Code('if (properties.length < ${normalizedProperties.length}) {'),
              generateSimpleDecodingExceptionExpression(
                'Invalid value for $className: \$value',
              ).statement,
              const Code('}'),
              refer(className, package)
                  .call([], {
                    for (final entry in propertyAssignments)
                      entry.key: entry.value,
                  })
                  .returned
                  .statement,
            ]),
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
                        ..type = refer('Object?', 'dart:core'),
                ),
              )
              ..body = _buildFromJsonBody(className, model),
      );

  Code _buildFromJsonBody(String className, ClassModel model) {
    final normalizedProperties = normalizeProperties(model.properties.toList());

    // If there are no properties, just return the constructor call
    if (normalizedProperties.isEmpty) {
      return Block.of([Code('return $className();')]);
    }

    final codes = <Code>[
      Code("final map = json.decodeMap(context: '$className');"),
    ];

    final propertyAssignments = <Code>[];

    for (final prop in normalizedProperties) {
      final property = prop.property;
      final normalizedName = prop.normalizedName;
      final jsonKey = property.name;

      final valueExpr =
          buildFromJsonValueExpression(
            "map[r'$jsonKey']",
            model: property.model,
            nameManager: nameManager,
            package: package,
            contextClass: className,
            contextProperty: jsonKey,
            isNullable: property.isNullable || !property.isRequired,
          ).code;

      propertyAssignments
        ..add(Code('$normalizedName: '))
        ..add(valueExpr)
        ..add(const Code(','));
    }

    codes
      ..add(Code('return $className('))
      ..addAll(propertyAssignments)
      ..add(const Code(');'));

    return Block.of(codes);
  }

  Method _buildToJsonMethod(ClassModel model) {
    final normalizedProperties = normalizeProperties(model.properties.toList());
    final propertyAssignments = <String>[];
    for (final prop in normalizedProperties) {
      final name = prop.normalizedName;
      final property = prop.property;
      final value = buildToJsonPropertyExpression(name, property);

      if (!property.isRequired && !property.isNullable) {
        propertyAssignments.add(
          "if ($name != null) r'${property.name}': $value",
        );
      } else {
        propertyAssignments.add("r'${property.name}': $value");
      }
    }

    return Method(
      (b) =>
          b
            ..name = 'toJson'
            ..returns = refer('Object?', 'dart:core')
            ..lambda = true
            ..body = Code('{${propertyAssignments.join(', ')}}'),
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
