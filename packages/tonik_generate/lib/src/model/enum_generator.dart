import 'package:change_case/change_case.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:meta/meta.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/naming/property_name_normalizer.dart';
import 'package:tonik_generate/src/util/core_prefixed_allocator.dart';
import 'package:tonik_generate/src/util/doc_comment_formatter.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';
import 'package:tonik_generate/src/util/format_with_header.dart';
import 'package:tonik_generate/src/util/type_reference_generator.dart';

/// A generator for creating Dart enum files from enum model definitions.
@immutable
class EnumGenerator {
  const EnumGenerator({required this.nameManager});

  final NameManager nameManager;

  ({String code, String filename}) generate<T>(EnumModel<T> model) {
    final emitter = DartEmitter(
      allocator: CorePrefixedAllocator(
        additionalImports: ['package:tonik_util/tonik_util.dart'],
      ),
      orderDirectives: true,
      useNullSafetySyntax: true,
    );

    final publicEnumName = nameManager.modelName(model);
    final snakeCaseName = publicEnumName.toSnakeCase();

    final library = Library((b) {
      final generated = generateEnum(model, publicEnumName);
      b.body.addAll([
        if (generated.typedefValue != null) generated.typedefValue!,
        generated.enumValue,
      ]);
    });

    final formatter = DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    );

    final code = formatter.formatWithHeader(library.accept(emitter).toString());

    return (code: code, filename: '$snakeCaseName.dart');
  }

  @visibleForTesting
  ({Enum enumValue, TypeDef? typedefValue}) generateEnum<T>(
    EnumModel<T> model,
    String enumName,
  ) {
    if (T != String && T != int) {
      throw ArgumentError(
        'EnumGenerator only supports String and int values. '
        'Got type: $T for ${model.name ?? model.context.path.join('.')}',
      );
    }

    // Collect all values for normalization (using nameOverride if provided)
    final allValuesToNormalize = [
      ...model.values.map((v) => v.nameOverride ?? v.value.toString()),
      if (model.fallbackValue != null)
        model.fallbackValue!.nameOverride ??
            model.fallbackValue!.value.toString(),
    ];

    final normalizedValues = normalizeEnumValues(allValuesToNormalize);
    final enumValues = _generateEnumValues(model, normalizedValues);

    // Get the fallback normalized name for use in fromJson and encoding methods
    final fallbackNormalizedName = model.fallbackValue != null
        ? normalizedValues[model.values.length].normalizedName
        : '';

    // Generate unique name for nullable enum with prefix to allow
    // using a typedef to express the nullable type.
    final actualEnumName = model.isNullable
        ? nameManager.modelName(
            AliasModel(
              name: '\$Raw$enumName',
              model: model,
              context: model.context,
            ),
          )
        : enumName;

    final enumValue = Enum(
      (b) {
        b
          ..name = actualEnumName
          ..docs.addAll(formatDocComment(model.description))
          ..implements.addAll([
            refer('MatrixEncodable', 'package:tonik_util/tonik_util.dart'),
            refer('LabelEncodable', 'package:tonik_util/tonik_util.dart'),
            refer('SimpleEncodable', 'package:tonik_util/tonik_util.dart'),
            refer('FormEncodable', 'package:tonik_util/tonik_util.dart'),
            refer('JsonEncodable', 'package:tonik_util/tonik_util.dart'),
            refer('UriEncodable', 'package:tonik_util/tonik_util.dart'),
          ]);

        if (model.isDeprecated) {
          b.annotations.add(
            refer('Deprecated', 'dart:core').call([
              literalString('This enum is deprecated.'),
            ]),
          );
        }

        b
          ..constructors.add(
            Constructor(
              (b) => b
                ..constant = true
                ..requiredParameters.add(
                  Parameter(
                    (b) => b
                      ..name = 'rawValue'
                      ..toThis = true,
                  ),
                ),
            ),
          )
          ..constructors.add(
            _generateFromJsonConstructor<T>(
              enumName,
              actualEnumName,
              model,
              fallbackNormalizedName,
            ),
          )
          ..constructors.add(
            _generateFromSimpleConstructor<T>(enumName, actualEnumName),
          )
          ..constructors.add(
            _generateFromFormConstructor<T>(enumName, actualEnumName),
          )
          ..methods.add(
            _generateToJsonMethod<T>(
              actualEnumName,
              fallbackNormalizedName,
              model.fallbackValue != null,
            ),
          )
          ..methods.add(
            Method(
              (b) => b
                ..name = 'currentEncodingShape'
                ..type = MethodType.getter
                ..returns = refer(
                  'EncodingShape',
                  'package:tonik_util/tonik_util.dart',
                )
                ..lambda = true
                ..body = refer(
                  'EncodingShape',
                  'package:tonik_util/tonik_util.dart',
                ).property('simple').code,
            ),
          )
          ..methods.add(
            _generateToSimpleMethod<T>(
              actualEnumName,
              fallbackNormalizedName,
              model.fallbackValue != null,
            ),
          )
          ..methods.add(
            _generateToFormMethod<T>(
              actualEnumName,
              fallbackNormalizedName,
              model.fallbackValue != null,
            ),
          )
          ..methods.add(
            _generateToLabelMethod<T>(
              actualEnumName,
              fallbackNormalizedName,
              model.fallbackValue != null,
            ),
          )
          ..methods.add(
            _generateUriEncodeMethod<T>(
              actualEnumName,
              fallbackNormalizedName,
              model.fallbackValue != null,
            ),
          )
          ..methods.add(
            _generateToMatrixMethod<T>(
              actualEnumName,
              fallbackNormalizedName,
              model.fallbackValue != null,
            ),
          )
          ..fields.add(
            Field(
              (b) => b
                ..name = 'rawValue'
                ..modifier = FieldModifier.final$
                ..type = refer(T.toString(), 'dart:core'),
            ),
          )
          ..values.addAll(enumValues);
      },
    );

    final typedefValue = model.isNullable
        ? TypeDef(
            (b) => b
              ..name = enumName
              ..definition = refer('$actualEnumName?'),
          )
        : null;

    return (enumValue: enumValue, typedefValue: typedefValue);
  }

  Constructor _generateFromSimpleConstructor<T>(
    String publicEnumName,
    String actualEnumName,
  ) {
    const valueParam = 'value';
    const explodeParam = 'explode';
    const contextParam = 'context';
    final decodeMethod = T == String ? 'decodeSimpleString' : 'decodeSimpleInt';

    return Constructor(
      (b) => b
        ..factory = true
        ..name = 'fromSimple'
        ..requiredParameters.add(
          Parameter(
            (b) => b
              ..name = valueParam
              ..type = refer('String?', 'dart:core'),
          ),
        )
        ..optionalParameters.addAll([
          Parameter(
            (b) => b
              ..name = explodeParam
              ..type = refer('bool', 'dart:core')
              ..named = true
              ..required = true,
          ),
          Parameter(
            (b) => b
              ..name = contextParam
              ..type = refer('String?', 'dart:core')
              ..named = true,
          ),
        ])
        ..body = Block.of([
          refer(actualEnumName)
              .property('fromJson')
              .call([
                refer(valueParam).property(decodeMethod).call([], {
                  contextParam: refer(contextParam),
                }, []),
              ])
              .returned
              .statement,
        ]),
    );
  }

  Constructor _generateFromFormConstructor<T>(
    String publicEnumName,
    String actualEnumName,
  ) {
    const valueParam = 'value';
    const explodeParam = 'explode';
    const contextParam = 'context';
    final decodeMethod = T == String ? 'decodeFormString' : 'decodeFormInt';

    return Constructor(
      (b) => b
        ..factory = true
        ..name = 'fromForm'
        ..requiredParameters.add(
          Parameter(
            (b) => b
              ..name = valueParam
              ..type = refer('String?', 'dart:core'),
          ),
        )
        ..optionalParameters.addAll([
          Parameter(
            (b) => b
              ..name = explodeParam
              ..type = refer('bool', 'dart:core')
              ..named = true
              ..required = true,
          ),
          Parameter(
            (b) => b
              ..name = contextParam
              ..type = refer('String?', 'dart:core')
              ..named = true,
          ),
        ])
        ..body = Block.of([
          refer(actualEnumName)
              .property('fromJson')
              .call([
                refer(valueParam).property(decodeMethod).call([], {
                  contextParam: refer(contextParam),
                }, []),
              ])
              .returned
              .statement,
        ]),
    );
  }

  Constructor _generateFromJsonConstructor<T>(
    String publicEnumName,
    String actualEnumName,
    EnumModel<T> model,
    String fallbackNormalizedName,
  ) {
    const valueParam = 'value';
    final typeReference = refer(T.toString(), 'dart:core');
    final typeErrorMessage =
        'Expected $T for $publicEnumName, got \${$valueParam.runtimeType}';
    final valueErrorMessage =
        'No matching $publicEnumName for value: \$$valueParam';

    return Constructor(
      (b) => b
        ..factory = true
        ..name = 'fromJson'
        ..requiredParameters.add(
          Parameter(
            (b) => b
              ..name = valueParam
              ..type = refer('dynamic', 'dart:core'),
          ),
        )
        ..body = Block.of([
          Code.scope((a) => 'if (value is! ${a(typeReference)}) {'),
          generateDecodingExceptionExpression(
            typeErrorMessage,
            raw: true,
          ).statement,
          const Code('}'),
          refer('values')
              .property('firstWhere')
              .call(
                [
                  Method(
                    (mb) => mb
                      ..requiredParameters.add(
                        Parameter((pb) => pb..name = 'e'),
                      )
                      ..body = refer(
                        'e',
                      ).property('rawValue').equalTo(refer(valueParam)).code,
                  ).closure,
                ],
                {
                  'orElse': model.fallbackValue != null
                      ? Method(
                          (mb) => mb
                            ..body = refer(
                              actualEnumName,
                            ).property(fallbackNormalizedName).code,
                        ).closure
                      : Method(
                          (mb) =>
                              mb
                                ..body = generateDecodingExceptionExpression(
                                  valueErrorMessage,
                                  raw: true,
                                ).code,
                        ).closure,
                },
              )
              .returned
              .statement,
        ]),
    );
  }

  Method _generateToJsonMethod<T>(
    String actualEnumName,
    String fallbackNormalizedName,
    bool hasFallback,
  ) {
    if (!hasFallback) {
      return Method(
        (b) => b
          ..annotations.add(refer('override', 'dart:core'))
          ..name = 'toJson'
          ..returns = refer(T.toString(), 'dart:core')
          ..lambda = true
          ..body = const Code('rawValue'),
      );
    }

    return Method(
      (b) => b
        ..annotations.add(refer('override', 'dart:core'))
        ..name = 'toJson'
        ..returns = refer(T.toString(), 'dart:core')
        ..lambda = false
        ..body = Block.of([
          Code('if (this == $actualEnumName.$fallbackNormalizedName) {'),
          generateEncodingExceptionExpression(
            'Cannot encode unknown enum value',
            raw: true,
          ).statement,
          const Code('}'),
          const Code('return rawValue;'),
        ]),
    );
  }

  Method _generateToSimpleMethod<T>(
    String actualEnumName,
    String fallbackNormalizedName,
    bool hasFallback,
  ) {
    if (!hasFallback) {
      return Method(
        (b) => b
          ..annotations.add(refer('override', 'dart:core'))
          ..name = 'toSimple'
          ..returns = refer('String', 'dart:core')
          ..lambda = true
          ..optionalParameters.addAll(buildEncodingParameters())
          ..body = const Code(
            'rawValue.toSimple(explode: explode, allowEmpty: allowEmpty)',
          ),
      );
    }

    return Method(
      (b) => b
        ..annotations.add(refer('override', 'dart:core'))
        ..name = 'toSimple'
        ..returns = refer('String', 'dart:core')
        ..lambda = false
        ..optionalParameters.addAll(buildEncodingParameters())
        ..body = Block.of([
          Code('if (this == $actualEnumName.$fallbackNormalizedName) {'),
          generateEncodingExceptionExpression(
            'Cannot encode unknown enum value',
            raw: true,
          ).statement,
          const Code('}'),
          const Code(
            '''
return rawValue.toSimple(explode: explode, allowEmpty: allowEmpty);
''',
          ),
        ]),
    );
  }

  Method _generateToFormMethod<T>(
    String actualEnumName,
    String fallbackNormalizedName,
    bool hasFallback,
  ) {
    if (!hasFallback) {
      return Method(
        (b) => b
          ..annotations.add(refer('override', 'dart:core'))
          ..name = 'toForm'
          ..returns = refer('String', 'dart:core')
          ..lambda = true
          ..optionalParameters.addAll(buildFormEncodingParameters())
          ..body = const Code(
            'rawValue.toForm(explode: explode, allowEmpty: allowEmpty)',
          ),
      );
    }

    return Method(
      (b) => b
        ..annotations.add(refer('override', 'dart:core'))
        ..name = 'toForm'
        ..returns = refer('String', 'dart:core')
        ..lambda = false
        ..optionalParameters.addAll(buildFormEncodingParameters())
        ..body = Block.of([
          Code('if (this == $actualEnumName.$fallbackNormalizedName) {'),
          generateEncodingExceptionExpression(
            'Cannot encode unknown enum value',
            raw: true,
          ).statement,
          const Code('}'),
          const Code(
            '''
return rawValue.toForm(explode: explode, allowEmpty: allowEmpty);
''',
          ),
        ]),
    );
  }

  Method _generateToLabelMethod<T>(
    String actualEnumName,
    String fallbackNormalizedName,
    bool hasFallback,
  ) {
    if (!hasFallback) {
      return Method(
        (b) => b
          ..annotations.add(refer('override', 'dart:core'))
          ..name = 'toLabel'
          ..returns = refer('String', 'dart:core')
          ..lambda = true
          ..optionalParameters.addAll(buildEncodingParameters())
          ..body = const Code(
            'rawValue.toLabel(explode: explode, allowEmpty: allowEmpty)',
          ),
      );
    }

    return Method(
      (b) => b
        ..annotations.add(refer('override', 'dart:core'))
        ..name = 'toLabel'
        ..returns = refer('String', 'dart:core')
        ..lambda = false
        ..optionalParameters.addAll(buildEncodingParameters())
        ..body = Block.of([
          Code('if (this == $actualEnumName.$fallbackNormalizedName) {'),
          generateEncodingExceptionExpression(
            'Cannot encode unknown enum value',
            raw: true,
          ).statement,
          const Code('}'),
          const Code(
            '''
return rawValue.toLabel(explode: explode, allowEmpty: allowEmpty);
''',
          ),
        ]),
    );
  }

  Method _generateUriEncodeMethod<T>(
    String actualEnumName,
    String fallbackNormalizedName,
    bool hasFallback,
  ) {
    if (!hasFallback) {
      return Method(
        (b) => b
          ..name = 'uriEncode'
          ..annotations.add(refer('override', 'dart:core'))
          ..returns = refer('String', 'dart:core')
          ..lambda = true
          ..optionalParameters.addAll([
            Parameter(
              (b) => b
                ..name = 'allowEmpty'
                ..type = refer('bool', 'dart:core')
                ..named = true
                ..required = true,
            ),
            Parameter(
              (b) => b
                ..name = 'useQueryComponent'
                ..type = refer('bool', 'dart:core')
                ..named = true
                ..required = false
                ..defaultTo = literalFalse.code,
            ),
          ])
          ..body = const Code(
            'rawValue.uriEncode(allowEmpty: allowEmpty, '
            'useQueryComponent: useQueryComponent)',
          ),
      );
    }

    return Method(
      (b) => b
        ..name = 'uriEncode'
        ..annotations.add(refer('override', 'dart:core'))
        ..returns = refer('String', 'dart:core')
        ..lambda = false
        ..optionalParameters.addAll([
          Parameter(
            (b) => b
              ..name = 'allowEmpty'
              ..type = refer('bool', 'dart:core')
              ..named = true
              ..required = true,
          ),
          Parameter(
            (b) => b
              ..name = 'useQueryComponent'
              ..type = refer('bool', 'dart:core')
              ..named = true
              ..required = false
              ..defaultTo = literalFalse.code,
          ),
        ])
        ..body = Block.of([
          Code('if (this == $actualEnumName.$fallbackNormalizedName) {'),
          generateEncodingExceptionExpression(
            'Cannot encode unknown enum value',
            raw: true,
          ).statement,
          const Code('}'),
          const Code(
            'return rawValue.uriEncode(allowEmpty: allowEmpty, '
            'useQueryComponent: useQueryComponent);',
          ),
        ]),
    );
  }

  Method _generateToMatrixMethod<T>(
    String actualEnumName,
    String fallbackNormalizedName,
    bool hasFallback,
  ) {
    if (!hasFallback) {
      return Method(
        (b) => b
          ..annotations.add(refer('override', 'dart:core'))
          ..name = 'toMatrix'
          ..returns = refer('String', 'dart:core')
          ..lambda = true
          ..requiredParameters.add(
            Parameter(
              (b) => b
                ..name = 'paramName'
                ..type = refer('String', 'dart:core'),
            ),
          )
          ..optionalParameters.addAll(buildEncodingParameters())
          ..body = const Code(
            '''rawValue.toMatrix(paramName, explode: explode, allowEmpty: allowEmpty)''',
          ),
      );
    }

    return Method(
      (b) => b
        ..annotations.add(refer('override', 'dart:core'))
        ..name = 'toMatrix'
        ..returns = refer('String', 'dart:core')
        ..lambda = false
        ..requiredParameters.add(
          Parameter(
            (b) => b
              ..name = 'paramName'
              ..type = refer('String', 'dart:core'),
          ),
        )
        ..optionalParameters.addAll(buildEncodingParameters())
        ..body = Block.of([
          Code('if (this == $actualEnumName.$fallbackNormalizedName) {'),
          generateEncodingExceptionExpression(
            'Cannot encode unknown enum value',
            raw: true,
          ).statement,
          const Code('}'),
          const Code(
            '''
return rawValue.toMatrix(paramName, explode: explode, allowEmpty: allowEmpty);
''',
          ),
        ]),
    );
  }

  List<EnumValue> _generateEnumValues<T>(
    EnumModel<T> model,
    List<({String normalizedName, String originalValue})> normalizedValues,
  ) {
    final values = model.values.toList();
    final enumValues = values.asMap().entries.map((entry) {
      final rawValue = entry.value.value;
      // Always use normalized name
      // (nameOverride is used as input to normalization)
      final enumName = normalizedValues[entry.key].normalizedName;

      return EnumValue(
        (b) => b
          ..name = enumName
          ..arguments.add(
            rawValue is int
                ? literalNum(rawValue)
                : literalString(rawValue.toString(), raw: true),
          ),
      );
    }).toList();

    // Add fallback value at the end if present
    if (model.fallbackValue != null) {
      final fallbackRawValue = model.fallbackValue!.value;
      // Always use normalized name
      // (nameOverride is used as input to normalization)
      final fallbackName = normalizedValues[values.length].normalizedName;

      enumValues.add(
        EnumValue(
          (b) => b
            ..name = fallbackName
            ..arguments.add(
              fallbackRawValue is int
                  ? literalNum(fallbackRawValue)
                  : literalString(fallbackRawValue.toString(), raw: true),
            ),
        ),
      );
    }

    return enumValues;
  }
}
