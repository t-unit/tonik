import 'package:change_case/change_case.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:meta/meta.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/util/copy_with_method_generator.dart';
import 'package:tonik_generate/src/util/core_prefixed_allocator.dart';
import 'package:tonik_generate/src/util/equals_method_generator.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';
import 'package:tonik_generate/src/util/format_with_header.dart';
import 'package:tonik_generate/src/util/from_json_value_expression_generator.dart';
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
    final properties = _buildProperties(models);

    return Class(
      (b) =>
          b
            ..name = className
            ..annotations.add(refer('immutable', 'package:meta/meta.dart'))
            ..constructors.add(_buildDefaultConstructor(models))
            ..constructors.add(_buildFromJsonConstructor(className, models))
            ..methods.addAll([
              _buildToJsonMethod(className, model),
              generateEqualsMethod(
                className: className,
                properties: properties,
              ),
              generateHashCodeMethod(properties: properties),
              _buildCopyWithMethod(className, models),
            ])
            ..fields.addAll(_buildFields(models)),
    );
  }

  List<Field> _buildFields(List<Model> models) {
    return models.map((model) {
      final typeRef = typeReference(model, nameManager, package);
      final fieldName = typeRef.symbol.toCamelCase();
      return Field(
        (b) =>
            b
              ..name = fieldName
              ..modifier = FieldModifier.final$
              ..type = typeRef,
      );
    }).toList();
  }

  List<({String normalizedName, bool hasCollectionValue})> _buildProperties(
    List<Model> models,
  ) {
    return models.map((model) {
      final typeRef = typeReference(model, nameManager, package);
      final fieldName = typeRef.symbol.toCamelCase();
      return (normalizedName: fieldName, hasCollectionValue: false);
    }).toList();
  }

  Constructor _buildDefaultConstructor(List<Model> models) {
    return Constructor(
      (b) =>
          b
            ..constant = true
            ..optionalParameters.addAll(
              models.map((model) {
                final typeRef = typeReference(model, nameManager, package);
                final fieldName = typeRef.symbol.toCamelCase();
                return Parameter(
                  (b) =>
                      b
                        ..name = fieldName
                        ..named = true
                        ..required = true
                        ..toThis = true,
                );
              }),
            ),
    );
  }

  Constructor _buildFromJsonConstructor(String className, List<Model> models) {
    final fromJsonParams = <Expression>[];
    final fieldNames = <String>[];
    for (final model in models) {
      final typeRef = typeReference(model, nameManager, package);
      final fieldName = typeRef.symbol.toCamelCase();
      fieldNames.add(fieldName);
      fromJsonParams.add(
        buildFromJsonValueExpression(
          'json',
          model: model,
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

  Method _buildToJsonMethod(String className, AllOfModel model) {
    switch (model.encodingShape) {
      case EncodingShape.mixed:
        return Method(
          (b) =>
              b
                ..returns = refer('Object?', 'dart:core')
                ..name = 'toJson'
                ..lambda = true
                ..body = Block.of([
                  generateEncodingExceptionExpression(
                    'Cannot encode $className: mixing simple values (primitives/enums) and complex types is not supported',
                  ).statement,
                ]),
        );

      case EncodingShape.simple:
        final firstModel = model.models.first;
        final firstFieldType = typeReference(firstModel, nameManager, package);
        final firstFieldName = firstFieldType.symbol.toCamelCase();

        return Method(
          (b) =>
              b
                ..returns = refer('Object?', 'dart:core')
                ..name = 'toJson'
                ..lambda = true
                ..body = Block.of([
                  Code(
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
                ]),
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

        for (final model in model.models) {
          final typeRef = typeReference(model, nameManager, package);
          final fieldName = typeRef.symbol.toCamelCase();
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

  Method _buildCopyWithMethod(String className, List<Model> models) {
    return generateCopyWithMethod(
      className: className,
      properties:
          models.map((model) {
            final typeRef = typeReference(model, nameManager, package);
            final fieldName = typeRef.symbol.toCamelCase();
            return (normalizedName: fieldName, typeRef: typeRef);
          }).toList(),
    );
  }
}
