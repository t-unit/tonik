import 'package:change_case/change_case.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:meta/meta.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/naming/property_name_normalizer.dart';
import 'package:tonik_generate/src/util/core_prefixed_allocator.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';
import 'package:tonik_generate/src/util/format_with_header.dart';

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

    final normalizedValues = normalizeEnumValues(
      model.values.map((v) => v.toString()).toList(),
    );
    final enumValues = _generateEnumValues(model, normalizedValues);

    // Generate unique name for nullable enum with prefix to allow
    // using a typedef to express the nullable type.
    final actualEnumName =
        model.isNullable
            ? nameManager.modelName(
              AliasModel(
                name: 'Raw$enumName',
                model: model,
                context: model.context,
              ),
            )
            : enumName;

    final enumValue = Enum(
      (b) =>
          b
            ..name = actualEnumName
            ..constructors.add(
              Constructor(
                (b) =>
                    b
                      ..constant = true
                      ..requiredParameters.add(
                        Parameter(
                          (b) =>
                              b
                                ..name = 'rawValue'
                                ..toThis = true,
                        ),
                      ),
              ),
            )
            ..constructors.add(
              _generateFromJsonConstructor<T>(enumName, actualEnumName),
            )
            ..constructors.add(
              _generateFromSimpleConstructor<T>(enumName, actualEnumName),
            )
            ..constructors.add(
              _generateFromFormConstructor<T>(enumName, actualEnumName),
            )
            ..methods.add(
              Method(
                (b) =>
                    b
                      ..name = 'toJson'
                      ..returns = refer(T.toString(), 'dart:core')
                      ..lambda = true
                      ..body = const Code('rawValue'),
              ),
            )
            ..methods.add(
              Method(
                (b) =>
                    b
                      ..name = 'currentEncodingShape'
                      ..type = MethodType.getter
                      ..returns = refer('EncodingShape', 'package:tonik_util/tonik_util.dart')
                      ..lambda = true
                      ..body = refer('EncodingShape', 'package:tonik_util/tonik_util.dart')
                          .property('simple')
                          .code,
              ),
            )
            ..methods.add(
              _generateToSimpleMethod<T>(),
            )
            ..methods.add(
              _generateToFormMethod<T>()
            )
            ..fields.add(
              Field(
                (b) =>
                    b
                      ..name = 'rawValue'
                      ..modifier = FieldModifier.final$
                      ..type = refer(T.toString(), 'dart:core'),
              ),
            )
            ..values.addAll(enumValues),
    );

    final typedefValue =
        model.isNullable
            ? TypeDef(
              (b) =>
                  b
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
      (b) =>
          b
            ..factory = true
            ..name = 'fromSimple'
            ..requiredParameters.add(
              Parameter(
                (b) =>
                    b
                      ..name = valueParam
                      ..type = refer('String?', 'dart:core'),
              ),
            )
            ..optionalParameters.addAll([
              Parameter(
                (b) =>
                    b
                      ..name = explodeParam
                      ..type = refer('bool', 'dart:core')
                      ..named = true
                      ..required = true,
              ),
              Parameter(
                (b) =>
                    b
                      ..name = contextParam
                      ..type = refer('String?', 'dart:core')
                      ..named = true,
              ),
            ])
            ..body = Block.of([
              refer(actualEnumName)
                  .property('fromJson')
                  .call([
                    refer(valueParam)
                        .property(decodeMethod)
                        .call([], {contextParam: refer(contextParam)}, []),
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
      (b) =>
          b
            ..factory = true
            ..name = 'fromForm'
            ..requiredParameters.add(
              Parameter(
                (b) =>
                    b
                      ..name = valueParam
                      ..type = refer('String?', 'dart:core'),
              ),
            )
            ..optionalParameters.addAll([
              Parameter(
                (b) =>
                    b
                      ..name = explodeParam
                      ..type = refer('bool', 'dart:core')
                      ..named = true
                      ..required = true,
              ),
              Parameter(
                (b) =>
                    b
                      ..name = contextParam
                      ..type = refer('String?', 'dart:core')
                      ..named = true,
              ),
            ])
            ..body = Block.of([
              refer(actualEnumName)
                  .property('fromJson')
                  .call([
                    refer(valueParam)
                        .property(decodeMethod)
                        .call([], {contextParam: refer(contextParam)}, []),
                  ])
                  .returned
                  .statement,
            ]),
    );
  }

  Constructor _generateFromJsonConstructor<T>(
    String publicEnumName,
    String actualEnumName,
  ) {
    const valueParam = 'value';
    final typeReference = refer(T.toString(), 'dart:core');
    final typeErrorMessage =
        'Expected $T for $publicEnumName, got \${$valueParam.runtimeType}';
    final valueErrorMessage =
        'No matching $publicEnumName for value: \$$valueParam';

    return Constructor(
      (b) =>
          b
            ..factory = true
            ..name = 'fromJson'
            ..requiredParameters.add(
              Parameter(
                (b) =>
                    b
                      ..name = valueParam
                      ..type = refer('dynamic', 'dart:core'),
              ),
            )
            ..body = Block.of([
              Code.scope((a) => 'if (value is! ${a(typeReference)}) {'),
              generateFormatExceptionExpression(typeErrorMessage).statement,
              const Code('}'),
              const Code('return values.firstWhere('),
              const Code('(e) => e.rawValue == $valueParam,'),
              const Code('orElse: () => '),
              generateFormatExceptionExpression(valueErrorMessage).code,
              const Code(');'),
            ]),
    );
  }

  Method _generateToSimpleMethod<T>() {
    return Method(
      (b) =>
          b
            ..name = 'toSimple'
            ..returns = refer('String', 'dart:core')
            ..lambda = true
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
            ..body = const Code(
              'rawValue.toSimple(explode: explode, allowEmpty: allowEmpty)',
            ),
    );
  }

  Method _generateToFormMethod<T>() {
    return Method(
      (b) =>
          b
            ..name = 'toForm'
            ..returns = refer('String', 'dart:core')
            ..lambda = true
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
            ..body = const Code(
              'rawValue.toForm(explode: explode, allowEmpty: allowEmpty)',
            ),
    );
  }

  List<EnumValue> _generateEnumValues<T>(
    EnumModel<T> model,
    List<({String normalizedName, String originalValue})> normalizedValues,
  ) {
    final values = model.values.toList();
    return values.asMap().entries.map((entry) {
      final value = entry.value;
      final normalizedName = normalizedValues[entry.key].normalizedName;

      return EnumValue(
        (b) =>
            b
              ..name = normalizedName
              ..arguments.add(
                value is int
                    ? literalNum(value)
                    : literalString(value.toString(), raw: true),
              ),
      );
    }).toList();
  }
}
