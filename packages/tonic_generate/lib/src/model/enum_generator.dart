import 'package:change_case/change_case.dart';
import 'package:code_builder/code_builder.dart';
import 'package:meta/meta.dart';
import 'package:tonic_core/tonic_core.dart';
import 'package:tonic_generate/src/util/name_manager.dart';
import 'package:tonic_generate/src/util/property_name_normalizer.dart';

/// A generator for creating Dart enum files from enum model definitions.
@immutable
class EnumGenerator {
  const EnumGenerator({required this.nameManager, required this.package});

  final NameManager nameManager;
  final String package;

  ({String code, String filename}) generate<T extends Object>(
    EnumModel<T> model,
  ) {
    final emitter = DartEmitter.scoped(
      orderDirectives: true,
      useNullSafetySyntax: true,
    );

    final publicEnumName = nameManager.modelName(model);
    final snakeCaseName = publicEnumName.toSnakeCase();

    final library = Library((b) {
      b.directives.add(Directive.part('$snakeCaseName.g.dart'));

      final generated = generateEnum(model, publicEnumName);
      b.body.addAll([
        if (generated.typedefValue != null) generated.typedefValue!,
        generated.enumValue,
      ]);
    });

    final buffer =
        StringBuffer()
          ..writeln('// Generated code - do not modify by hand\n')
          ..write(library.accept(emitter));

    return (code: buffer.toString(), filename: '$snakeCaseName.dart');
  }

  @visibleForTesting
  ({Enum enumValue, TypeDef? typedefValue}) generateEnum<T extends Object>(
    EnumModel<T> model,
    String enumName,
  ) {
    if (T != String && T != int) {
      throw ArgumentError(
        'EnumGenerator only supports String and int values. '
        'Got type: $T',
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
            ..annotations.add(
              refer(
                'JsonEnum',
                'package:json_annotation/json_annotation.dart',
              ).call([], {'valueField': literalString('rawValue')}),
            )
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
                      ..returns = refer(T.toString())
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
                      ..type = refer(T.toString()),
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

  Constructor _generateFromJsonConstructor<T extends Object>(String enumName) {
    const valueParam = 'value';
    final typeCheck = 'value is! $T';
    final typeError =
        "throw FormatException('Expected $T for "
        "$enumName, got \${$valueParam.runtimeType}');";
    final valueError =
        "throw FormatException('No matching $enumName "
        "for value: \$$valueParam')";

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
                      ..type = refer('dynamic'),
              ),
            )
            ..body = Block.of([
              Code('if ($typeCheck) {'),
              Code(typeError),
              const Code('}'),
              const Code('return values.firstWhere('),
              const Code('(e) => e.rawValue == $valueParam,'),
              Code('orElse: () => $valueError);'),
            ]),
    );
  }

  List<EnumValue> _generateEnumValues<T extends Object>(
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
                    : literalString(value.toString()),
              ),
      );
    }).toList();
  }
}
