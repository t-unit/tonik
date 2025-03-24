import 'package:change_case/change_case.dart';
import 'package:code_builder/code_builder.dart';
import 'package:meta/meta.dart';
import 'package:tonic_core/tonic_core.dart';
import 'package:tonic_generate/src/util/name_manager.dart';
import 'package:tonic_generate/src/util/property_name_normalizer.dart';

/// A generator for creating Dart class files from model definitions.
@immutable
class ClassGenerator {
  const ClassGenerator({
    required this.nameManger,
    required this.propertyNameNormalizer,
  });

  final NameManger nameManger;
  final PropertyNameNormalizer propertyNameNormalizer;

  static const deprecatedPropertyMessage = 'This property is deprecated.';

  String generate(ClassModel model) {
    final emitter = DartEmitter.scoped(
      orderDirectives: true,
      useNullSafetySyntax: true,
    );

    final library = Library((b) => b..body.add(generateClass(model)));

    final snakeCaseName = nameManger.modelName(model).toSnakeCase();

    final buffer =
        StringBuffer()
          ..writeln('// Generated code - do not modify by hand\n')
          ..writeln("part '$snakeCaseName.freezed.dart';")
          ..writeln("part '$snakeCaseName.g.dart';\n")
          ..write(library.accept(emitter));

    return buffer.toString();
  }

  Class generateClass(ClassModel model) {
    final className = nameManger.modelName(model);
    final normalizedProperties = propertyNameNormalizer.normalizeAll(
      model.properties.toList(),
    );

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
            ..methods.add(_buildToJsonMethod(className))
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
          ..body = Code('=> _\$${className}FromJson(json)'),
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

  Method _buildToJsonMethod(String className) => Method(
    (b) =>
        b
          ..annotations.add(_buildJsonKeyIgnoreAnnotation())
          ..returns = _buildMapStringDynamicType()
          ..name = 'toJson'
          ..body = Code('=> _\$${className}ToJson(this)'),
  );

  Expression _buildJsonKeyIgnoreAnnotation() => refer(
    'JsonKey',
    'package:json_annotation/json_annotation.dart',
  ).call([], {'ignore': literalTrue});

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
    final baseType = switch (property.model) {
      final ListModel m => TypeReference(
        (b) =>
            b
              ..symbol = 'List'
              ..url = 'dart:core'
              ..types.add(
                _getTypeReference(
                  Property(
                    name: '',
                    model: m.content,
                    isRequired: true,
                    isNullable: false,
                    isDeprecated: false,
                  ),
                ),
              ),
      ),
      final NamedModel m => TypeReference(
        (b) => b..symbol = nameManger.modelName(m),
      ),
      StringModel _ => TypeReference(
        (b) =>
            b
              ..symbol = 'String'
              ..url = 'dart:core',
      ),
      IntegerModel _ => TypeReference(
        (b) =>
            b
              ..symbol = 'int'
              ..url = 'dart:core',
      ),
      DoubleModel _ => TypeReference(
        (b) =>
            b
              ..symbol = 'double'
              ..url = 'dart:core',
      ),
      NumberModel _ => TypeReference(
        (b) =>
            b
              ..symbol = 'num'
              ..url = 'dart:core',
      ),
      BooleanModel _ => TypeReference(
        (b) =>
            b
              ..symbol = 'bool'
              ..url = 'dart:core',
      ),
      DateTimeModel _ => TypeReference(
        (b) =>
            b
              ..symbol = 'DateTime'
              ..url = 'dart:core',
      ),
      DateModel _ => TypeReference(
        (b) =>
            b
              ..symbol = 'DateTime'
              ..url = 'dart:core',
      ),
      DecimalModel _ => TypeReference(
        (b) =>
            b
              ..symbol = 'BigDecimal'
              ..url = 'package:big_decimal/big_decimal.dart',
      ),
    };

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
