import 'package:change_case/change_case.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:meta/meta.dart';
import 'package:tonic_core/tonic_core.dart';
import 'package:tonic_generate/src/util/core_prefixed_allocator.dart';
import 'package:tonic_generate/src/util/exception_code_generator.dart';
import 'package:tonic_generate/src/util/name_manager.dart';
import 'package:tonic_generate/src/util/property_name_normalizer.dart';
import 'package:tonic_generate/src/util/to_json_value_expression_generator.dart';
import 'package:tonic_generate/src/util/type_reference_generator.dart';

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
      b.directives.add(Directive.part('$snakeCaseName.freezed.dart'));
      b.body.add(generateClass(model));
    });

    final formatter = DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    );

    final code = formatter.format(
      '// Generated code - do not modify by hand\n'
      '// ignore_for_file: unnecessary_raw_strings, unnecessary_brace_in_string_interps\n\n'
      '${library.accept(emitter)}',
    );

    return (code: code, filename: '$snakeCaseName.dart');
  }

  @visibleForTesting
  Class generateClass(ClassModel model) {
    final className = nameManager.modelName(model);
    final normalizedProperties = normalizeAll(model.properties.toList());

    return Class(
      (b) =>
          b
            ..name = className
            ..annotations.add(
              refer(
                'freezed',
                'package:freezed_annotation/freezed_annotation.dart',
              ),
            )
            ..mixins.add(refer('_\$$className'))
            ..constructors.addAll([
              Constructor(
                (b) =>
                    b
                      ..constant = true
                      ..optionalParameters.addAll(
                        normalizedProperties.map(
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
            ..methods.add(_buildToJsonMethod(model))
            ..fields.addAll(
              normalizedProperties.map(
                (prop) => _generateField(prop.property, prop.normalizedName),
              ),
            ),
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
    final normalizedProperties = normalizeAll(model.properties.toList());

    final invalidJsonError =
        generateArgumentErrorExpression(
          'Invalid JSON for $className: \$json',
        ).statement;

    final codes = <Code>[
      const Code('final map = json;'),
      const Code('if (map is! '),
      _buildMapStringDynamicType().code,
      const Code(') {'),
      invalidJsonError,
      const Code('}'),
    ];

    final propertyValidations = <Code>[];
    final propertyAssignments = <String>[];

    for (final prop in normalizedProperties) {
      final property = prop.property;
      final normalizedName = prop.normalizedName;
      final jsonKey = property.name;
      final typeCheckCode = _generateTypeCheck(
        property,
        normalizedName,
        jsonKey,
        className,
      );

      propertyValidations.add(typeCheckCode);
      propertyAssignments.add('$normalizedName: $normalizedName');
    }

    codes
      ..addAll(propertyValidations)
      ..add(Code('return $className(${propertyAssignments.join(', ')});'));

    return Block.of(codes);
  }

  Code _generateTypeCheck(
    Property property,
    String normalizedName,
    String jsonKey,
    String className,
  ) {
    final typeRef = getTypeReference(property.model, nameManager, package);
    final symbolForMessage = typeRef.symbol;

    final errorMessage =
        'Expected $symbolForMessage${property.isNullable ? '?' : ''} '
        'for $jsonKey of $className, got \${$normalizedName}';

    final typeCheckError =
        generateArgumentErrorExpression(errorMessage).statement;

    final conditionStart =
        property.isNullable
            ? Code('if ($normalizedName != null && $normalizedName is! ')
            : Code('if ($normalizedName is! ');

    const conditionEnd = Code(') {');

    final checkCodes = <Code>[
      Code("final $normalizedName = map[r'$jsonKey'];"),
      conditionStart,
      typeRef.code,
      conditionEnd,
      typeCheckError,
      const Code('}'),
    ];

    return Block.of(checkCodes);
  }

  TypeReference _buildMapStringDynamicType() => TypeReference(
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
                    ..symbol = 'dynamic'
                    ..url = 'dart:core',
            ),
          ]),
  );

  Method _buildToJsonMethod(ClassModel model) {
    final normalizedProperties = normalizeAll(model.properties.toList());

    final parts = <Code>[const Code('{')];
    for (final prop in normalizedProperties) {
      final property = prop.property;
      final name = prop.normalizedName;
      final jsonKeyString = literalString(property.name, raw: true).code;
      final valueExprString = buildToJsonValueExpression(name, property);

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
            ..returns = _buildMapStringDynamicType()
            ..name = 'toJson'
            ..lambda = true
            ..body = Block.of(parts),
    );
  }

  Field _generateField(Property property, String normalizedName) {
    final fieldBuilder = FieldBuilder()
      ..name = normalizedName
      ..modifier = FieldModifier.final$
      ..type = _getTypeReference(property);

    if (property.isDeprecated) {
      fieldBuilder.annotations.add(
        refer('Deprecated').call([literalString(deprecatedPropertyMessage)]),
      );
    }

    return fieldBuilder.build();
  }

  TypeReference _getTypeReference(Property property) {
    final baseType = getTypeReference(property.model, nameManager, package);

    return property.isNullable || !property.isRequired
        ? TypeReference(
          (b) =>
              b
                ..symbol = baseType.symbol
                ..url = baseType.url
                ..types.addAll(baseType.types)
                ..isNullable = true,
        )
        : baseType;
  }
}
