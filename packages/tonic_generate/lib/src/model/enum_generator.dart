import 'package:change_case/change_case.dart';
import 'package:code_builder/code_builder.dart';
import 'package:meta/meta.dart';
import 'package:tonic_core/tonic_core.dart';
import 'package:tonic_generate/src/util/name_manager.dart';
import 'package:tonic_generate/src/util/property_name_normalizer.dart';

/// A generator for creating Dart enum files from enum model definitions.
@immutable
class EnumGenerator {
  const EnumGenerator({
    required this.nameManger,
    required this.package,
  });

  final NameManger nameManger;
  final String package;

  ({String code, String filename}) generate<T extends Object>(
    EnumModel<T> model,
  ) {
    final emitter = DartEmitter.scoped(
      orderDirectives: true,
      useNullSafetySyntax: true,
    );

    final publicEnumName = nameManger.modelName(model);
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
    final actualEnumName = model.isNullable
        ? nameManger.modelName(
            AliasModel(
              name: enumName,
              model: model,
              context: model.context,
            ),
          )
        : enumName;

    final enumValue = Enum(
      (b) =>
          b
            ..name = model.isNullable ? 'Raw$enumName' : actualEnumName
            ..annotations.add(
              refer('JsonEnum', 'package:json_annotation/json_annotation.dart'),
            )
            ..values.addAll(enumValues),
    );

    final typedefValue = model.isNullable
        ? TypeDef((b) => b
          ..name = enumName
          ..definition = refer('Raw$enumName?'),)
        : null;

    return (enumValue: enumValue, typedefValue: typedefValue);
  }

  List<EnumValue> _generateEnumValues<T extends Object>(
    EnumModel<T> model,
    List<({String normalizedName, String originalValue})> normalizedValues,
  ) {
    final values = model.values.toList();
    return values.asMap().entries.map((entry) {
      final value = entry.value;
      final normalizedName = normalizedValues[entry.key].normalizedName;

      final annotation = refer(
        '@JsonValue',
        'package:json_annotation/json_annotation.dart',
      ).call([
        if (value is int)
          literalNum(value)
        else
          literalString(value.toString()),
      ]);

      return EnumValue(
        (b) =>
            b
              ..name = normalizedName
              ..annotations.add(annotation),
      );
    }).toList();
  }
}
