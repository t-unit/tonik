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
    final normalizedProperties = normalizeProperties(model.properties.toList());

    return Class(
      (b) =>
          b
            ..name = className
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
    final parameters = <Parameter>[];
    final assignments = <Code>[];

    for (final prop in properties) {
      final name = prop.normalizedName;
      final property = prop.property;
      final typeRef = _getTypeReference(property);

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

  Method _buildEqualsMethod(
    String className,
    List<({String normalizedName, Property property})> properties,
  ) {
    var hasCollectionProperties = false;
    final comparisons = <String>[];

    for (final prop in properties) {
      final name = prop.normalizedName;
      final property = prop.property;

      if (property.model is ListModel) {
        hasCollectionProperties = true;
        comparisons.add('_deepEquals.equals(other.$name, $name)');
      } else {
        comparisons.add('other.$name == $name');
      }
    }

    final methodBuilder =
        MethodBuilder()
          ..name = 'operator =='
          ..returns = refer('bool', 'dart:core')
          ..annotations.add(refer('override', 'dart:core'))
          ..requiredParameters.add(
            Parameter(
              (b) =>
                  b
                    ..name = 'other'
                    ..type = refer('Object', 'dart:core'),
            ),
          );

    final codeLines = <Code>[
      Code.scope((allocate) {
        final identical = allocate(refer('identical', 'dart:core'));
        return 'if ($identical(this, other)) return true;';
      }),
    ];

    if (hasCollectionProperties) {
      codeLines.add(
        declareConst('_deepEquals')
            .assign(
              refer(
                'DeepCollectionEquality',
                'package:collection/collection.dart',
              ).call([]),
            )
            .statement,
      );
    }

    if (properties.isEmpty) {
      codeLines.add(Code('return other is $className;'));
    } else {
      codeLines
        ..add(Code('return other is $className && '))
        ..add(Code('  ${comparisons.join(' && ')};'));
    }

    methodBuilder.body = Block.of(codeLines);

    return methodBuilder.build();
  }

  Method _buildHashCodeMethod(
    List<({String normalizedName, Property property})> properties,
  ) {
    final hasCollections = properties.any(
      (prop) => prop.property.model is ListModel,
    );

    final codeLines = <Code>[];

    if (properties.isEmpty) {
      codeLines.add(
        refer('runtimeType').property('hashCode').returned.statement,
      );
      return Method(
        (b) =>
            b
              ..name = 'hashCode'
              ..type = MethodType.getter
              ..returns = refer('int', 'dart:core')
              ..annotations.add(refer('override', 'dart:core'))
              ..body = Block.of(codeLines),
      );
    }

    if (properties.length == 1) {
      // If there's only one property, just return its hashCode
      final propName = properties.first.normalizedName;
      if (properties.first.property.model is ListModel) {
        if (hasCollections) {
          codeLines.add(
            declareConst('_deepEquals')
                .assign(
                  refer(
                    'DeepCollectionEquality',
                    'package:collection/collection.dart',
                  ).call([]),
                )
                .statement,
          );
        }
        codeLines.add(
          refer(
            '_deepEquals',
          ).property('hash').call([refer(propName)]).returned.statement,
        );
      } else {
        codeLines.add(refer(propName).property('hashCode').returned.statement);
      }
      return Method(
        (b) =>
            b
              ..name = 'hashCode'
              ..type = MethodType.getter
              ..returns = refer('int', 'dart:core')
              ..annotations.add(refer('override', 'dart:core'))
              ..body = Block.of(codeLines),
      );
    }

    if (hasCollections) {
      codeLines.add(
        declareConst('_deepEquals')
            .assign(
              refer(
                'DeepCollectionEquality',
                'package:collection/collection.dart',
              ).call([]),
            )
            .statement,
      );

      final objectHashArgs = <Expression>[];

      for (final prop in properties) {
        final name = prop.normalizedName;
        if (prop.property.model is ListModel) {
          objectHashArgs.add(
            refer('_deepEquals').property('hash').call([refer(name)]),
          );
        } else {
          objectHashArgs.add(refer(name));
        }
      }

      codeLines.add(
        refer(
          'Object',
          'dart:core',
        ).property('hash').call(objectHashArgs).returned.statement,
      );
    } else {
      final hashArgs =
          properties.map((prop) => refer(prop.normalizedName)).toList();

      codeLines.add(
        refer(
          'Object',
          'dart:core',
        ).property('hash').call(hashArgs).returned.statement,
      );
    }

    return Method(
      (b) =>
          b
            ..name = 'hashCode'
            ..type = MethodType.getter
            ..returns = refer('int', 'dart:core')
            ..annotations.add(refer('override', 'dart:core'))
            ..body = Block.of(codeLines),
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
    final typeRef = typeReference(property.model, nameManager, package);
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

  Method _buildToJsonMethod(ClassModel model) {
    final normalizedProperties = normalizeProperties(model.properties.toList());

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
