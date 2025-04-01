import 'package:change_case/change_case.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:meta/meta.dart';
import 'package:tonic_core/tonic_core.dart';
import 'package:tonic_generate/src/util/name_manager.dart';
import 'package:tonic_generate/src/util/property_name_normalizer.dart';
import 'package:tonic_generate/src/util/type_reference_generator.dart';

/// A generator for creating Dart class files from model definitions.
@immutable
class ClassGenerator {
  const ClassGenerator({required this.nameManager, required this.package});

  final NameManager nameManager;
  final String package;

  static const deprecatedPropertyMessage = 'This property is deprecated.';

  ({String code, String filename}) generate(ClassModel model) {
    final emitter = DartEmitter.scoped(
      orderDirectives: true,
      useNullSafetySyntax: true,
    );

    final snakeCaseName = nameManager.modelName(model).toSnakeCase();

    final library = Library((b) {
      b.directives.add(Directive.part('$snakeCaseName.freezed.dart'));
      b.directives.add(Directive.part('$snakeCaseName.g.dart'));
      b.body.add(generateClass(model));
    });

    final formatter = DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    );

    final code = formatter.format(
      '// Generated code - do not modify by hand\n\n${library.accept(emitter)}',
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
            ..annotations.addAll([
              refer(
                'freezed',
                'package:freezed_annotation/freezed_annotation.dart',
              ),
              refer(
                'JsonSerializable',
                'package:json_annotation/json_annotation.dart',
              ).call([], {
                'explicitToJson': literalTrue,
                'includeIfNull': literalTrue,
              }),
            ])
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
              _buildFromJsonConstructor(className),
            ])
            ..methods.add(_buildToJsonMethod(model))
            ..fields.addAll(
              normalizedProperties.map(
                (prop) => generateField(prop.property, prop.normalizedName),
              ),
            ),
    );
  }

  Constructor _buildFromJsonConstructor(String className) => Constructor(
    (b) =>
        b
          ..factory = true
          ..name = 'fromJson'
          ..requiredParameters.add(
            Parameter(
              (b) =>
                  b
                    ..name = 'json'
                    ..type = _buildMapStringDynamicType(),
            ),
          )
          ..lambda = true
          ..body = Code('_\$${className}FromJson(json)'),
  );

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

    final body = Block.of([
      const Code('{'),
      ...normalizedProperties.map((prop) {
        if (prop.property.isRequired || prop.property.isNullable) {
          return Code("r'${prop.property.name}': ${prop.normalizedName},");
        }
        return Code(
          'if (${prop.normalizedName} != null) '
          "r'${prop.property.name}': ${prop.normalizedName},",
        );
      }),
      const Code('}'),
    ]);

    return Method(
      (b) =>
          b
            ..returns = _buildMapStringDynamicType()
            ..name = 'toJson'
            ..lambda = true
            ..body = body,
    );
  }

  Field generateField(Property property, String normalizedName) {
    final annotations = <Expression>[];
    if (property.isDeprecated) {
      annotations.add(
        refer('Deprecated').call([literalString(deprecatedPropertyMessage)]),
      );
    }

    final jsonKey = refer(
      'JsonKey',
      'package:json_annotation/json_annotation.dart',
    );
    annotations.add(
      jsonKey.call(const [], {
        if (!property.isNullable) 'includeIfNull': literalFalse,
        'name': literalString(property.name, raw: true),
      }),
    );

    return Field(
      (b) =>
          b
            ..name = normalizedName
            ..modifier = FieldModifier.final$
            ..type = _getTypeReference(property)
            ..annotations.addAll(annotations),
    );
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
