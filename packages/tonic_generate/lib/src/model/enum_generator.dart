import 'package:change_case/change_case.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:meta/meta.dart';
import 'package:tonic_core/tonic_core.dart';
import 'package:tonic_generate/src/util/core_prefixed_allocator.dart';
import 'package:tonic_generate/src/util/exception_code_generator.dart';
import 'package:tonic_generate/src/util/name_manager.dart';
import 'package:tonic_generate/src/util/property_name_normalizer.dart';

/// A generator for creating Dart enum files from enum model definitions.
@immutable
class EnumGenerator {
  const EnumGenerator({required this.nameManager, required this.package});

  final NameManager nameManager;
  final String package;

  ({String code, String filename}) generate<T>(EnumModel<T> model) {
    final emitter = DartEmitter(
      allocator: CorePrefixedAllocator(),
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

    final code = formatter.format(
      '// Generated code - do not modify by hand\n'
      '// ignore_for_file: unnecessary_raw_strings, unnecessary_brace_in_string_interps\n\n'
      '${library.accept(emitter)}',
    );

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
              AliasModel(name: enumName, model: model, context: model.context),
            )
            : enumName;

    final enumValue = Enum(
      (b) =>
          b
            ..name = model.isNullable ? 'Raw$enumName' : actualEnumName
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
            ..constructors.add(_generateFromJsonConstructor<T>(actualEnumName))
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
                    ..definition = refer('Raw$enumName?'),
            )
            : null;

    return (enumValue: enumValue, typedefValue: typedefValue);
  }

  Constructor _generateFromJsonConstructor<T>(String enumName) {
    const valueParam = 'value';
    final typeCheck = 'value is! $T';
    final typeErrorMessage =
        'Expected $T for $enumName, got \${$valueParam.runtimeType}';
    final valueErrorMessage = 'No matching $enumName for value: \$$valueParam';

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
              Code('if ($typeCheck) {'),
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
