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

/// A generator for creating Dart classes from allOf model definitions.
@immutable
class AllOfGenerator {
  const AllOfGenerator({required this.nameManager, required this.package});

  final NameManager nameManager;
  final String package;

  ({String code, String filename}) generate(AllOfModel model) {
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
  Class generateClass(AllOfModel model) {
    final className = nameManager.modelName(model);
    final models = model.models.toList();

    final pseudoProperties =
        models.map((m) {
          final rawName = switch (m) {
            final NamedModel named => named.name ?? 'Model',
            StringModel() => 'String',
            IntegerModel() => 'int',
            DoubleModel() => 'double',
            NumberModel() => 'num',
            BooleanModel() => 'bool',
            DateTimeModel() => 'DateTime',
            DateModel() => 'Date',
            DecimalModel() => 'BigDecimal',
            UriModel() => 'Uri',
            _ => 'Model',
          };

          return Property(
            name: rawName,
            model: m,
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          );
        }).toList();

    final normalizedProperties = normalizeProperties(pseudoProperties);
    final properties = _buildPropertiesFromNormalized(normalizedProperties);

    return Class(
      (b) =>
          b
            ..name = className
            ..annotations.add(refer('immutable', 'package:meta/meta.dart'))
            ..constructors.add(_buildDefaultConstructor(normalizedProperties))
            ..constructors.addAll([
              _buildFromSimpleConstructor(
                className,
                normalizedProperties,
                model,
              ),
              _buildFromJsonConstructor(className, normalizedProperties),
            ])
            ..methods.addAll([
              _buildToJsonMethod(className, model, normalizedProperties),
              _buildToSimpleMethod(
                normalizedProperties,
                model,
              ),
              generateEqualsMethod(
                className: className,
                properties: properties,
              ),
              generateHashCodeMethod(properties: properties),
              _buildCopyWithMethod(className, normalizedProperties),
            ])
            ..fields.addAll(_buildFields(normalizedProperties)),
    );
  }

  List<Field> _buildFields(
    List<({String normalizedName, Property property})> normalizedProperties,
  ) {
    return normalizedProperties.map((normalized) {
      final typeRef = typeReference(
        normalized.property.model,
        nameManager,
        package,
      );
      return Field(
        (b) =>
            b
              ..name = normalized.normalizedName
              ..modifier = FieldModifier.final$
              ..type = typeRef,
      );
    }).toList();
  }

  List<({String normalizedName, bool hasCollectionValue})>
  _buildPropertiesFromNormalized(
    List<({String normalizedName, Property property})> normalizedProperties,
  ) {
    return normalizedProperties.map((normalized) {
      return (
        normalizedName: normalized.normalizedName,
        hasCollectionValue: normalized.property.model is ListModel,
      );
    }).toList();
  }

  Constructor _buildDefaultConstructor(
    List<({String normalizedName, Property property})> normalizedProperties,
  ) {
    return Constructor(
      (b) =>
          b
            ..constant = true
            ..optionalParameters.addAll(
              normalizedProperties.map((normalized) {
                return Parameter(
                  (b) =>
                      b
                        ..name = normalized.normalizedName
                        ..named = true
                        ..required = true
                        ..toThis = true,
                );
              }),
            ),
    );
  }

  Constructor _buildFromJsonConstructor(
    String className,
    List<({String normalizedName, Property property})> normalizedProperties,
  ) {
    final fromJsonParams = <Expression>[];
    final fieldNames = <String>[];
    for (final normalized in normalizedProperties) {
      fieldNames.add(normalized.normalizedName);
      fromJsonParams.add(
        buildFromJsonValueExpression(
          'json',
          model: normalized.property.model,
          nameManager: nameManager,
          package: package,
          contextClass: className,
        ),
      );
    }

    return Constructor(
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
            ..body = Block.of([
              refer(className)
                  .call(
                    [],
                    Map.fromEntries(
                      List.generate(
                        fromJsonParams.length,
                        (i) => MapEntry(fieldNames[i], fromJsonParams[i]),
                      ),
                    ),
                  )
                  .returned
                  .statement,
            ]),
    );
  }

  Method _buildToJsonMethod(
    String className,
    AllOfModel model,
    List<({String normalizedName, Property property})> normalizedProperties,
  ) {
    switch (model.encodingShape) {
      case EncodingShape.mixed:
        return Method(
          (b) =>
              b
                ..returns = refer('Object?', 'dart:core')
                ..name = 'toJson'
                ..lambda = true
                ..body =
                    generateEncodingExceptionExpression(
                      'Cannot encode $className: mixing simple values (primitives/enums) and complex types is not supported',
                    ).code,
        );

      case EncodingShape.simple:
        final firstModel = model.models.first;
        final firstFieldName = normalizedProperties.first.normalizedName;

        return Method(
          (b) =>
              b
                ..returns = refer('Object?', 'dart:core')
                ..name = 'toJson'
                ..lambda = true
                ..body = Code(
                  buildToJsonPropertyExpression(
                    firstFieldName,
                    Property(
                      name: firstFieldName,
                      model: firstModel,
                      isRequired: true,
                      isNullable: false,
                      isDeprecated: false,
                    ),
                  ),
                ),
        );

      case EncodingShape.complex:
        final mapType = buildMapStringObjectType();
        final mapParts = <Code>[
          const Code('final map = '),
          literalMap(
            {},
            refer('String', 'dart:core'),
            refer('Object?', 'dart:core'),
          ).statement,
        ];

        for (final normalized in normalizedProperties) {
          final fieldName = normalized.normalizedName;
          final fieldNameJson = '${fieldName}Json';

          mapParts.addAll([
            Code('final $fieldNameJson = '),
            refer(fieldName).code,
            const Code('.toJson();'),
            const Code('if ('),
            refer(fieldNameJson).code,
            const Code(' is! '),
            mapType.code,
            const Code(') {'),
            generateEncodingExceptionExpression(
              'Expected $fieldName.toJson() to return Map<String, Object?>, '
              'got \${$fieldNameJson.runtimeType}',
            ).statement,
            const Code('}'),
            const Code('map.addAll('),
            refer(fieldNameJson).code,
            const Code(');'),
          ]);
        }

        mapParts.add(const Code('return map;'));

        return Method(
          (b) =>
              b
                ..returns = refer('Object?', 'dart:core')
                ..name = 'toJson'
                ..lambda = false
                ..body = Block.of(mapParts),
        );
    }
  }

  Constructor _buildFromSimpleConstructor(
    String className,
    List<({String normalizedName, Property property})> normalizedProperties,
    AllOfModel model,
  ) {
    if (model.encodingShape != EncodingShape.simple) {
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
                generateSimpleDecodingExceptionExpression(
                  'Simple encoding not supported for $className: '
                  'contains complex types',
                ).statement,
              ]),
      );
    }

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
      final normalized = normalizedProperties[i];
      final name = normalized.normalizedName;
      final modelType = normalized.property.model;
      final isNullable = normalized.property.isNullable;

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

  /// Builds a toSimple method for simple types.
  Method _buildToSimpleMethod(
    List<({String normalizedName, Property property})> normalizedProperties,
    AllOfModel model,
  ) {
    if (model.encodingShape != EncodingShape.simple) {
      return Method(
        (b) =>
            b
              ..name = 'toSimple'
              ..returns = refer('String?', 'dart:core')
              ..lambda = false
              ..body = Block.of([
                generateSimpleDecodingExceptionExpression(
                  'Simple encoding not supported: contains complex types',
                ).statement,
              ]),
      );
    }

    // Build the list of field values to encode
    final fieldNames = normalizedProperties
        .map((normalized) => normalized.normalizedName)
        .join(', ');

    return Method(
      (b) =>
          b
            ..name = 'toSimple'
            ..returns = refer('String?', 'dart:core')
            ..lambda = true
            ..body = Code('[$fieldNames].encodeSimpleStringList()'),
    );
  }

  Method _buildCopyWithMethod(
    String className,
    List<({String normalizedName, Property property})> normalizedProperties,
  ) {
    return generateCopyWithMethod(
      className: className,
      properties:
          normalizedProperties.map((normalized) {
            final typeRef = typeReference(
              normalized.property.model,
              nameManager,
              package,
            );
            return (
              normalizedName: normalized.normalizedName,
              typeRef: typeRef,
            );
          }).toList(),
    );
  }
}
