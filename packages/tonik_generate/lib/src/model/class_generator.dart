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
              _buildFromSimpleConstructor(className, model),
              _buildFromJsonConstructor(className, model),
            ])
            ..methods.addAll([
              _buildToJsonMethod(model),
              _buildCopyWithMethod(className, normalizedProperties),
              _buildEqualsMethod(className, normalizedProperties),
              _buildHashCodeMethod(normalizedProperties),
              _buildSimplePropertiesMethod(model, normalizedProperties),
              _buildToSimpleMethod(className, model, normalizedProperties),
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

    final hasOnlySimpleProperties = model.properties.every((property) {
      return property.model.encodingShape == EncodingShape.simple;
    });

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
            ..optionalParameters.add(
              Parameter(
                (b) =>
                    b
                      ..name = 'explode'
                      ..type = refer('bool', 'dart:core')
                      ..named = true
                      ..required = true,
              ),
            )
            ..body = _buildFromSimpleBody(
              className,
              normalizedProperties,
              hasOnlySimpleProperties,
            ),
    );
  }

  Block _buildFromSimpleBody(
    String className,
    List<({String normalizedName, Property property})> properties,
    bool hasOnlySimpleProperties,
  ) {
    if (properties.isEmpty) {
      return Block.of([Code('return $className();')]);
    }

    if (!hasOnlySimpleProperties) {
      return Block.of([
        generateEncodingExceptionExpression(
          'Simple encoding not supported for $className: '
          'contains complex types',
        ).statement,
      ]);
    }

    final propertyNames = properties.map((p) => p.property.name).toSet();

    final constructorArgs = <String, Expression>{};
    for (final prop in properties) {
      final normalizedName = prop.normalizedName;
      final propertyName = prop.property.name;
      final modelType = prop.property.model;
      final isNullable = prop.property.isNullable;

      constructorArgs[normalizedName] = buildSimpleValueExpression(
        refer("values['$propertyName']"),
        model: modelType,
        isRequired: !isNullable,
        nameManager: nameManager,
        package: package,
        contextClass: className,
        contextProperty: propertyName,
      );
    }

    return Block.of([
      // Null/empty check
      const Code('if (value == null || value.isEmpty) {'),
      generateSimpleDecodingExceptionExpression(
        'Invalid empty value for $className',
      ).statement,
      const Code('}'),

      // Parse into key-value pairs (only part that differs by explode mode)
      declareFinal('values')
          .assign(
            literalMap(
              {},
              refer('String', 'dart:core'),
              refer('String', 'dart:core'),
            ),
          )
          .statement,
      _buildExplodeParsingLogic(),

      // Shared validation and construction (no duplication)
      _buildKeyValidationLogic(propertyNames),

      // Constructor call
      refer(className, package).call([], constructorArgs).returned.statement,
    ]);
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

  Method _buildSimplePropertiesMethod(
    ClassModel model,
    List<({String normalizedName, Property property})> properties,
  ) {
    final hasComplexData = properties.any((prop) {
      final propertyModel = prop.property.model;
      return propertyModel.encodingShape != EncodingShape.simple;
    });

    if (hasComplexData) {
      return Method(
        (b) =>
            b
              ..name = 'simpleProperties'
              ..returns = TypeReference(
                (b) =>
                    b
                      ..symbol = 'Map'
                      ..url = 'dart:core'
                      ..types.addAll([
                        TypeReference(
                          (b) =>
                              b
                                ..symbol = 'String'
                                ..url = 'dart:core',
                        ),
                        TypeReference(
                          (b) =>
                              b
                                ..symbol = 'String'
                                ..url = 'dart:core',
                        ),
                      ]),
              )
              ..optionalParameters.add(
                Parameter(
                  (b) =>
                      b
                        ..name = 'allowEmpty'
                        ..type = refer('bool', 'dart:core')
                        ..named = true
                        ..defaultTo = literalBool(true).code,
                ),
              )
              ..body =
                  generateEncodingExceptionExpression(
                    'simpleProperties not supported for ${model.name}: '
                    'contains nested data',
                  ).statement,
      );
    }

    final mapEntries = <Code>[];

    for (final prop in properties) {
      final property = prop.property;
      final fieldName = prop.normalizedName;
      final rawName = property.name;

      if (property.isRequired && property.isNullable) {
        mapEntries.add(
          Code(
            'if (allowEmpty || $fieldName != null) '
            "r'$rawName': $fieldName?.toSimple(explode: false, "
            "allowEmpty: allowEmpty) ?? '',",
          ),
        );
      } else if (!property.isRequired) {
        mapEntries.add(
          Code(
            "if ($fieldName != null) r'$rawName': "
            '$fieldName!.toSimple(explode: false, allowEmpty: allowEmpty),',
          ),
        );
      } else {
        mapEntries.add(
          Code(
            "r'$rawName': $fieldName.toSimple(explode: false, "
            'allowEmpty: allowEmpty),',
          ),
        );
      }
    }

    final returnStatement =
        properties.isEmpty
            ? literalMap(
              {},
              TypeReference(
                (b) =>
                    b
                      ..symbol = 'String'
                      ..url = 'dart:core',
              ),
              TypeReference(
                (b) =>
                    b
                      ..symbol = 'String'
                      ..url = 'dart:core',
              ),
            ).code
            : Code('return {\n${mapEntries.map((e) => '  $e').join('\n')}\n};');

    return Method(
      (b) =>
          b
            ..name = 'simpleProperties'
            ..returns = TypeReference(
              (b) =>
                  b
                    ..symbol = 'Map'
                    ..url = 'dart:core'
                    ..types.addAll([
                      TypeReference(
                        (b) =>
                            b
                              ..symbol = 'String'
                              ..url = 'dart:core',
                      ),
                      TypeReference(
                        (b) =>
                            b
                              ..symbol = 'String'
                              ..url = 'dart:core',
                      ),
                    ]),
            )
            ..optionalParameters.add(
              Parameter(
                (b) =>
                    b
                      ..name = 'allowEmpty'
                      ..type = refer('bool', 'dart:core')
                      ..named = true
                      ..defaultTo = literalBool(true).code,
              ),
            )
            ..lambda = properties.isEmpty
            ..body = returnStatement,
    );
  }

  Method _buildToSimpleMethod(
    String className,
    ClassModel model,
    List<({String normalizedName, Property property})> properties,
  ) {
    final hasComplexData = properties.any((prop) {
      final propertyModel = prop.property.model;
      return propertyModel.encodingShape != EncodingShape.simple;
    });

    if (hasComplexData) {
      return Method(
        (b) =>
            b
              ..name = 'toSimple'
              ..returns = refer('String', 'dart:core')
              ..optionalParameters.addAll([
                Parameter(
                  (b) =>
                      b
                        ..name = 'explode'
                        ..type = refer('bool', 'dart:core')
                        ..named = true
                        ..required = true,
                ),
                Parameter(
                  (b) =>
                      b
                        ..name = 'allowEmpty'
                        ..type = refer('bool', 'dart:core')
                        ..named = true
                        ..required = true,
                ),
              ])
              ..body = Block.of([
                generateEncodingExceptionExpression(
                  'toSimple not supported for $className: '
                  'contains nested data',
                ).statement,
              ]),
      );
    }

    if (properties.isEmpty) {
      return Method(
        (b) =>
            b
              ..name = 'toSimple'
              ..returns = refer('String', 'dart:core')
              ..optionalParameters.addAll([
                Parameter(
                  (b) =>
                      b
                        ..name = 'explode'
                        ..type = refer('bool', 'dart:core')
                        ..named = true
                        ..required = true,
                ),
                Parameter(
                  (b) =>
                      b
                        ..name = 'allowEmpty'
                        ..type = refer('bool', 'dart:core')
                        ..named = true
                        ..required = true,
                ),
              ])
              ..body = Block.of([
                literalString('').returned.statement,
              ]),
      );
    }

    return Method(
      (b) =>
          b
            ..name = 'toSimple'
            ..returns = refer('String', 'dart:core')
            ..optionalParameters.addAll([
              Parameter(
                (b) =>
                    b
                      ..name = 'explode'
                      ..type = refer('bool', 'dart:core')
                      ..named = true
                      ..required = true,
              ),
              Parameter(
                (b) =>
                    b
                      ..name = 'allowEmpty'
                      ..type = refer('bool', 'dart:core')
                      ..named = true
                      ..required = true,
              ),
            ])
            ..body = Block.of([
              refer('simpleProperties')
                  .call([], {'allowEmpty': refer('allowEmpty')})
                  .property('toSimple')
                  .call([], {
                    'explode': refer('explode'),
                    'allowEmpty': refer('allowEmpty'),
                  })
                  .returned
                  .statement,
            ]),
    );
  }

  Code _buildExplodeParsingLogic() {
    return Block.of([
      const Code('if (explode) {'),
      // explode=true: prop1=val1,prop2=val2
      declareFinal('pairs')
          .assign(
            refer('value').property('split').call([literalString(',')]),
          )
          .statement,
      const Code('for (final pair in pairs) {'),
      declareFinal('parts')
          .assign(
            refer('pair').property('split').call([literalString('=')]),
          )
          .statement,
      const Code('if (parts.length != 2) {'),
      generateSimpleDecodingExceptionExpression(
        r'Invalid key=value pair format: $pair',
      ).statement,
      const Code('}'),
      refer('values')
          .index(
            refer('Uri', 'dart:core').property('decodeComponent').call([
              refer('parts').index(literalNum(0)),
            ]),
          )
          .assign(refer('parts').index(literalNum(1)))
          .statement,
      const Code('}'),
      const Code('} else {'),
      // explode=false: prop1,val1,prop2,val2
      declareFinal('parts')
          .assign(
            refer('value').property('split').call([literalString(',')]),
          )
          .statement,
      const Code('if (parts.length % 2 != 0) {'),
      generateSimpleDecodingExceptionExpression(
        'Invalid alternating key-value format: expected even number of '
        r'parts, got ${parts.length}',
      ).statement,
      const Code('}'),
      const Code('for (var i = 0; i < parts.length; i += 2) {'),
      refer('values')
          .index(
            refer('Uri', 'dart:core').property('decodeComponent').call([
              refer('parts').index(refer('i')),
            ]),
          )
          .assign(refer('parts').index(refer('i').operatorAdd(literalNum(1))))
          .statement,
      const Code('}'),
      const Code('}'),
    ]);
  }

  Code _buildKeyValidationLogic(Set<String> propertyNames) {
    final expectedKeysLiteral = literalSet(
      propertyNames.map(literalString),
      refer('String', 'dart:core'),
    );

    return Block.of([
      // const expectedKeys = {'prop1', 'prop2'};
      declareConst('expectedKeys').assign(expectedKeysLiteral).statement,

      // for (final key in values.keys) {
      const Code('for (final key in values.keys) {'),
      const Code('if (!expectedKeys.contains(key)) {'),
      generateSimpleDecodingExceptionExpression(
        r'Unknown property: $key',
      ).statement,
      const Code('}'),
      const Code('}'),
    ]);
  }
}
