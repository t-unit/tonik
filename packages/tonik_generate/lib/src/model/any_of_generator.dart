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

@immutable
class AnyOfGenerator {
  const AnyOfGenerator({required this.nameManager, required this.package});

  final NameManager nameManager;
  final String package;

  ({String code, String filename}) generate(AnyOfModel model) {
    final emitter = DartEmitter(
      allocator: CorePrefixedAllocator(
        additionalImports: ['package:tonik_util/tonik_util.dart'],
      ),
      orderDirectives: true,
      useNullSafetySyntax: true,
    );

    final className = nameManager.modelName(model);
    final snakeCaseName = className.toSnakeCase();

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
  Class generateClass(AnyOfModel model) {
    final className = nameManager.modelName(model);

    final pseudoProperties =
        model.models.map((discriminated) {
          final typeRef = typeReference(
            discriminated.model,
            nameManager,
            package,
          );
          return Property(
            name: typeRef.symbol,
            model: discriminated.model,
            isRequired: false,
            isNullable: true,
            isDeprecated: false,
          );
        }).toList();

    final normalized = normalizeProperties(pseudoProperties);
    final fields =
        normalized.map((n) {
          final ref = typeReference(
            n.property.model,
            nameManager,
            package,
            isNullableOverride: true,
          );
          return Field(
            (b) =>
                b
                  ..name = n.normalizedName
                  ..modifier = FieldModifier.final$
                  ..type = ref,
          );
        }).toList();

    final defaultCtor = Constructor(
      (b) =>
          b
            ..constant = true
            ..optionalParameters.addAll(
              normalized.map(
                (n) => Parameter(
                  (p) =>
                      p
                        ..name = n.normalizedName
                        ..named = true
                        ..toThis = true,
                ),
              ),
            ),
    );

    final fromJsonCtor = _buildFromJsonConstructor(
      className,
      normalized,
    );

    final fromSimpleCtor = _buildFromSimpleConstructor(
      className,
      normalized,
    );

    final propsForEquality =
        normalized
            .map(
              (n) => (
                normalizedName: n.normalizedName,
                hasCollectionValue: n.property.model is ListModel,
              ),
            )
            .toList();

    final copyWithMethod = generateCopyWithMethod(
      className: className,
      properties:
          normalized
              .map(
                (n) => (
                  normalizedName: n.normalizedName,
                  typeRef: typeReference(
                    n.property.model,
                    nameManager,
                    package,
                  ),
                ),
              )
              .toList(),
    );

    final toJsonMethod = _buildToJsonMethod(
      className,
      model,
      normalized,
    );

    final toSimpleMethod = _buildToSimpleMethod(
      className,
      model,
      normalized,
    );

    final simplePropsMethod = _buildSimplePropertiesMethod(
      className,
      model,
      normalized,
    );

    return Class(
      (b) =>
          b
            ..name = className
            ..annotations.add(refer('immutable', 'package:meta/meta.dart'))
            ..constructors.add(defaultCtor)
            ..constructors.add(fromJsonCtor)
            ..constructors.add(fromSimpleCtor)
            ..methods.addAll([
              toJsonMethod,
              toSimpleMethod,
              simplePropsMethod,
              generateEqualsMethod(
                className: className,
                properties: propsForEquality,
              ),
              generateHashCodeMethod(properties: propsForEquality),
              copyWithMethod,
            ])
            ..fields.addAll(fields),
    );
  }

  Constructor _buildFromJsonConstructor(
    String className,
    List<({String normalizedName, Property property})> normalized,
  ) {
    final localDecls = <Code>[];

    for (final n in normalized) {
      final modelType = n.property.model;
      final varName = n.normalizedName;

      final decodeExpr = buildFromJsonValueExpression(
        'json',
        model: modelType,
        nameManager: nameManager,
        package: package,
        contextClass: className,
      );

      final typeRefNullable = typeReference(
        modelType,
        nameManager,
        package,
        isNullableOverride: true,
      );
      localDecls.add(
        Block.of([
          typeRefNullable.code,
          Code(' $varName;'),
          const Code('\ntry {\n  '),
          Code('$varName = '),
          decodeExpr.code,
          const Code(';\n} on '),
          refer('Object', 'dart:core').code,
          const Code(' catch (_) {\n  '),
          Code('$varName = null;'),
          const Code('\n}\n'),
        ]),
      );
    }

    final ctorArgs = {
      for (final n in normalized) n.normalizedName: refer(n.normalizedName),
    };

    return Constructor(
      (b) =>
          b
            ..factory = true
            ..name = 'fromJson'
            ..requiredParameters.add(
              Parameter(
                (p) =>
                    p
                      ..name = 'json'
                      ..type = refer('Object?', 'dart:core'),
              ),
            )
            ..body = Block.of([
              ...localDecls,
              refer(className, package).call([], ctorArgs).returned.statement,
            ]),
    );
  }

  Method _buildToJsonMethod(
    String className,
    AnyOfModel model,
    List<({String normalizedName, Property property})> normalized,
  ) {
    final body = [
      declareFinal(
        'values',
      ).assign(literalList([], refer('Object?', 'dart:core'))).statement,
      declareFinal(
        'mapValues',
      ).assign(literalList([], buildMapStringObjectType())).statement,
    ];

    final hasDiscriminator = model.discriminator != null;
    if (hasDiscriminator) {
      body.add(const Code('String? discriminatorValue;'));
    }

    for (final n in normalized) {
      final name = n.normalizedName;
      final valueExpr = buildToJsonPropertyExpression(
        name,
        n.property,
        forceNonNullReceiver: true,
      );

      final discriminated = model.models.firstWhere(
        (dm) => dm.model == n.property.model,
        orElse: () => (discriminatorValue: null, model: n.property.model),
      );

      final openIf = Code('if ($name != null) {');
      final decl = Block.of([
        const Code('final '),
        refer('Object?', 'dart:core').code,
        Code(' ${name}Json = '),
        Code(valueExpr),
        const Code(';'),
      ]);
      final ifMapOpen = [
        const Code('if ('),
        Code('${name}Json'),
        const Code(' is '),
        buildMapStringObjectType().code,
        const Code(') {'),
      ];
      final addMap = Code('mapValues.add(${name}Json);');
      final maybeDisc =
          hasDiscriminator && discriminated.discriminatorValue != null
              ? Code(
                "discriminatorValue ??= '${discriminated.discriminatorValue}';",
              )
              : const Code('');
      const ifMapClose = Code('}');
      final addValue = Code('values.add(${name}Json);');
      const closeIf = Code('}');

      body.addAll([
        openIf,
        decl,
        ...ifMapOpen,
        addMap,
        maybeDisc,
        ifMapClose,
        addValue,
        closeIf,
      ]);
    }

    body.add(const Code('if (values.isEmpty) return null;'));

    final mergeBlocks = [
      const Code('final map = '),
      literalMap(
        {},
        refer('String', 'dart:core'),
        refer('Object?', 'dart:core'),
      ).statement,
      const Code('for (final m in mapValues) { map.addAll(m); }'),
    ];
    if (hasDiscriminator) {
      mergeBlocks.add(
        Code(
          'if (discriminatorValue != null) { '
          "map.putIfAbsent('${model.discriminator}', "
          '() => discriminatorValue); }',
        ),
      );
    }
    mergeBlocks.add(const Code('return map;'));

    body.addAll([
      const Code('if (mapValues.length == values.length) {'),
      ...mergeBlocks,
      const Code('}'),
      declareConst('_deepEquals')
          .assign(
            refer(
              'DeepCollectionEquality',
              'package:collection/collection.dart',
            ).call([]),
          )
          .statement,
      const Code('final first = values.firstOrNull;'),
      const Code('if (first == null) return null;'),
      const Code('for (final v in values) {'),
      const Code('  if (!_deepEquals.equals(v, first)) {'),
      generateEncodingExceptionExpression(
        'Ambiguous anyOf encoding for $className: inconsistent JSON '
        'representations',
      ).statement,
      const Code('  }'),
      const Code('}'),
      const Code('return first;'),
    ]);

    return Method(
      (b) =>
          b
            ..name = 'toJson'
            ..returns = refer('Object?', 'dart:core')
            ..lambda = false
            ..body = Block.of(body),
    );
  }

  Method _buildToSimpleMethod(
    String className,
    AnyOfModel model,
    List<({String normalizedName, Property property})> normalized,
  ) {
    final body = [
      declareFinal(
        'values',
      ).assign(literalList([], refer('String', 'dart:core'))).statement,
      declareFinal('mapValues')
          .assign(
            literalList(
              [],
              TypeReference(
                (tb) =>
                    tb
                      ..symbol = 'Map'
                      ..url = 'dart:core'
                      ..types.addAll([
                        refer('String', 'dart:core'),
                        refer('String', 'dart:core'),
                      ]),
              ),
            ),
          )
          .statement,
    ];

    final hasDiscriminator = model.discriminator != null;
    if (hasDiscriminator) {
      body.add(const Code('String? discriminatorValue;'));
    }

    for (final n in normalized) {
      final name = n.normalizedName;

      final discriminated = model.models.firstWhere(
        (dm) => dm.model == n.property.model,
        orElse: () => (discriminatorValue: null, model: n.property.model),
      );

      final isComplex = n.property.model.encodingShape != EncodingShape.simple;

      body.addAll([
        Code('if ($name != null) {'),
      ]);

      if (isComplex) {
        final tmp = '${name}Simple';
        body
          ..addAll([
            const Code('final '),
            Code(tmp),
            const Code(' = '),
            Code('$name!.simpleProperties(allowEmpty: allowEmpty);'),
          ])

        ..add(Code('mapValues.add($tmp);'));

        if (hasDiscriminator && discriminated.discriminatorValue != null) {
          body.add(
            Code(
              "discriminatorValue ??= '${discriminated.discriminatorValue}';",
            ),
          );
        }

        body.addAll([
          const Code('values.add('),
          Code('$tmp.toSimple('),
          const Code('explode: explode, '),
          const Code('allowEmpty: allowEmpty'),
          const Code('));'),
        ]);
      } else {
        final tmp = '${name}Simple';
        body
          ..addAll([
            const Code('final '),
            Code(tmp),
            const Code(' = '),
            Code('$name!.toSimple('),
            const Code('explode: explode, '),
            const Code('allowEmpty: allowEmpty'),
            const Code(');'),
          ])
          ..add(Code('values.add($tmp);'));
      }

      body.add(const Code('}'));
    }

    body.addAll([
      const Code("if (values.isEmpty) return '';"),
      const Code(
        'if (mapValues.isNotEmpty && mapValues.length != values.length) {',
      ),
      generateEncodingExceptionExpression(
        'Ambiguous anyOf simple encoding for $className: '
        'mixing simple and complex values',
      ).statement,
      const Code('}'),
    ]);

    final mergeBlocks = <Code>[
      const Code('final map = '),
      literalMap(
        {},
        refer('String', 'dart:core'),
        refer('String', 'dart:core'),
      ).statement,
      const Code('for (final m in mapValues) { map.addAll(m); }'),
    ];
    if (hasDiscriminator) {
      mergeBlocks.addAll([
        const Code('if (discriminatorValue != null) { '),
        Code("map.putIfAbsent('${model.discriminator}', () => "),
        const Code('discriminatorValue'),
        const Code(');'),
        const Code(' }'),
      ]);
    }
    mergeBlocks
      ..add(const Code('return map.toSimple('))
      ..addAll([
        const Code('explode: explode, '),
        const Code('allowEmpty: allowEmpty'),
        const Code(');'),
      ]);

    body.addAll([
      const Code('if (mapValues.length == values.length) {'),
      ...mergeBlocks,
      const Code('}'),

      const Code('final first = values.first;'),
      const Code('for (final v in values) {'),
      const Code('  if (v != first) {'),
      generateEncodingExceptionExpression(
        'Ambiguous anyOf simple encoding for $className: '
        'inconsistent simple representations',
      ).statement,
      const Code('  }'),
      const Code('}'),
      const Code('return first;'),
    ]);

    return Method(
      (b) =>
          b
            ..name = 'toSimple'
            ..returns = refer('String', 'dart:core')
            ..optionalParameters.addAll([
              Parameter(
                (p) =>
                    p
                      ..name = 'explode'
                      ..type = refer('bool', 'dart:core')
                      ..named = true
                      ..required = true,
              ),
              Parameter(
                (p) =>
                    p
                      ..name = 'allowEmpty'
                      ..type = refer('bool', 'dart:core')
                      ..named = true
                      ..required = true,
              ),
            ])
            ..lambda = false
            ..body = Block.of(body),
    );
  }

  Constructor _buildFromSimpleConstructor(
    String className,
    List<({String normalizedName, Property property})> normalized,
  ) {
    final localDecls = <Code>[];

    for (final n in normalized) {
      final modelType = n.property.model;
      final varName = n.normalizedName;

      final decodeExpr = switch (modelType) {
        ClassModel() || AllOfModel() || OneOfModel() || AnyOfModel() => refer(
              nameManager.modelName(modelType),
              package,
            )
            .property('fromSimple')
            .call(
              [
                refer('value'),
              ],
              {
                'explode': refer('explode'),
              },
            ),
        _ => buildSimpleValueExpression(
          refer('value'),
          model: modelType,
          isRequired: true,
          nameManager: nameManager,
          package: package,
          contextClass: className,
        ),
      };

      final typeRefNullable = typeReference(
        modelType,
        nameManager,
        package,
        isNullableOverride: true,
      );

      localDecls.add(
        Block.of([
          typeRefNullable.code,
          Code(' $varName;'),
          const Code('\ntry {\n  '),
          Code('$varName = '),
          decodeExpr.code,
          const Code(';\n} on '),
          refer('Object', 'dart:core').code,
          const Code(' catch (_) {\n  '),
          Code('$varName = null;'),
          const Code('\n}\n'),
        ]),
      );
    }

    final ctorArgs = {
      for (final n in normalized) n.normalizedName: refer(n.normalizedName),
    };

    return Constructor(
      (b) =>
          b
            ..factory = true
            ..name = 'fromSimple'
            ..requiredParameters.add(
              Parameter(
                (p) =>
                    p
                      ..name = 'value'
                      ..type = refer('String?', 'dart:core'),
              ),
            )
            ..optionalParameters.add(
              Parameter(
                (p) =>
                    p
                      ..name = 'explode'
                      ..named = true
                      ..required = true
                      ..type = refer('bool', 'dart:core'),
              ),
            )
            ..body = Block.of([
              ...localDecls,
              refer(className, package).call([], ctorArgs).returned.statement,
            ]),
    );
  }

  Method _buildSimplePropertiesMethod(
    String className,
    AnyOfModel model,
    List<({String normalizedName, Property property})> normalized,
  ) {
    final hasSimple = model.models.any(
      (m) => m.model.encodingShape == EncodingShape.simple,
    );
    final hasComplex = model.models.any(
      (m) => m.model.encodingShape != EncodingShape.simple,
    );

    if (hasSimple && !hasComplex) {
      return Method(
        (b) =>
            b
              ..name = 'simpleProperties'
              ..returns = TypeReference(
                (tb) =>
                    tb
                      ..symbol = 'Map'
                      ..url = 'dart:core'
                      ..types.addAll([
                        refer('String', 'dart:core'),
                        refer('String', 'dart:core'),
                      ]),
              )
              ..optionalParameters.add(
                Parameter(
                  (p) =>
                      p
                        ..name = 'allowEmpty'
                        ..type = refer('bool', 'dart:core')
                        ..named = true
                        ..required = true,
                ),
              )
              ..body =
                  generateEncodingExceptionExpression(
                    'simpleProperties not supported for $className: '
                    'contains primitive values',
                  ).statement,
      );
    }
    final body = <Code>[
      declareFinal('maps')
          .assign(
            literalList(
              [],
              TypeReference(
                (tb) =>
                    tb
                      ..symbol = 'Map'
                      ..url = 'dart:core'
                      ..types.addAll([
                        refer('String', 'dart:core'),
                        refer('String', 'dart:core'),
                      ]),
              ),
            ),
          )
          .statement,
    ];

    for (final n in normalized) {
      final isComplex = n.property.model.encodingShape != EncodingShape.simple;
      if (!isComplex) continue;
      final fn = n.normalizedName;
      final tmp = '${fn}Simple';
      body
        ..add(Code('if ($fn != null) { '))
        ..add(const Code('final '))
        ..add(
          TypeReference(
            (tb) =>
                tb
                  ..symbol = 'Map'
                  ..url = 'dart:core'
                  ..types.addAll([
                    refer('String', 'dart:core'),
                    refer('String', 'dart:core'),
                  ]),
          ).code,
        )
        ..add(Code(' $tmp = '))
        ..add(Code('$fn!.simpleProperties(allowEmpty: allowEmpty);'))
        ..add(const Code(' maps.add('))
        ..add(Code(tmp))
        ..add(const Code(');'))
        ..add(const Code('}'));
    }

    if (hasSimple && hasComplex) {
      for (final n in normalized) {
        final isSimple = n.property.model.encodingShape == EncodingShape.simple;
        if (!isSimple) continue;
        final fn = n.normalizedName;
        body.addAll([
          Code('if ($fn != null) {'),
          generateEncodingExceptionExpression(
            'simpleProperties not supported for $className: '
            'mixing simple and complex values',
          ).statement,
          const Code('}'),
        ]);
      }
    }

    body.addAll([
      const Code('if (maps.isEmpty) return '),
      literalMap(
        {},
        refer('String', 'dart:core'),
        refer('String', 'dart:core'),
      ).code,
      const Code(';'),
      const Code('final map = '),
      literalMap(
        {},
        refer('String', 'dart:core'),
        refer('String', 'dart:core'),
      ).statement,
      const Code('for (final m in maps) { map.addAll(m); }'),
      const Code('return map;'),
    ]);

    return Method(
      (b) =>
          b
            ..name = 'simpleProperties'
            ..returns = TypeReference(
              (tb) =>
                  tb
                    ..symbol = 'Map'
                    ..url = 'dart:core'
                    ..types.addAll([
                      refer('String', 'dart:core'),
                      refer('String', 'dart:core'),
                    ]),
            )
            ..optionalParameters.add(
              Parameter(
                (p) =>
                    p
                      ..name = 'allowEmpty'
                      ..type = refer('bool', 'dart:core')
                      ..named = true
                      ..required = true,
              ),
            )
            ..body = Block.of(body),
    );
  }
}
