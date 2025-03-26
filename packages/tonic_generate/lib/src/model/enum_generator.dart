import 'package:change_case/change_case.dart';
import 'package:code_builder/code_builder.dart';
import 'package:meta/meta.dart';
import 'package:spell_out_numbers/spell_out_numbers.dart';
import 'package:tonic_core/tonic_core.dart';
import 'package:tonic_generate/src/util/name_manager.dart';
import 'package:tonic_generate/src/util/property_name_normalizer.dart';

/// A generator for creating Dart enum files from enum model definitions.
@immutable
class EnumGenerator {
  const EnumGenerator({
    required this.nameManger,
    required this.propertyNameNormalizer,
    required this.package,
  });

  final NameManger nameManger;
  final PropertyNameNormalizer propertyNameNormalizer;
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

    final values = _generateEnumValues(model);
    final uniqueValues = _ensureUniqueNames(values);

    // Generate unique name for nullable enum with prefix to allow 
    // using a typedef to express the nullable type.
    final actualEnumName = model.isNullable
        ? nameManger.modelName(
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
            ..annotations.add(
              refer('JsonEnum', 'package:json_annotation/json_annotation.dart'),
            )
            ..values.addAll(uniqueValues),
    );

    final typedefValue = model.isNullable
        ? TypeDef((b) => b
          ..name = enumName
          ..definition = refer('$actualEnumName?'),)
        : null;

    return (enumValue: enumValue, typedefValue: typedefValue);
  }

  List<EnumValue> _generateEnumValues<T extends Object>(EnumModel<T> model) {
    return model.values.map((value) {
      // Add @JsonValue annotation with the original value
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
              ..name = _normalizeEnumValueName(value)
              ..annotations.add(annotation),
      );
    }).toList();
  }

  String _normalizeEnumValueName(Object value) {
    // For integer values, spell out the number
    if (value is int) {
      final words = EnglishNumberScheme().toWord(value);
      return words.toCamelCase();
    }

    final str = value.toString();

    // Handle underscore-only values
    if (RegExp(r'^_+$').hasMatch(str)) {
      return 'value';
    }

    // For string values, just use camelCase
    return str.toCamelCase();
  }

  List<EnumValue> _ensureUniqueNames(List<EnumValue> values) {
    final usedNames = <String>{};
    final result = <EnumValue>[];
    final baseNames = <String, int>{};

    for (final value in values) {
      final baseName = value.name;
      var name = baseName;

      // If this base name has been seen before, increment its counter
      baseNames.putIfAbsent(baseName, () => 1);
      final counter = baseNames[baseName]!;

      // If the name is already used, append the counter
      if (usedNames.contains(name)) {
        name = '$baseName${counter + 1}';
        baseNames[baseName] = counter + 1;
      }

      usedNames.add(name);

      // If the name was changed, create a new EnumValue
      if (name != value.name) {
        result.add(
          EnumValue(
            (b) =>
                b
                  ..name = name
                  ..annotations.addAll(value.annotations),
          ),
        );
      } else {
        result.add(value);
      }
    }

    return result;
  }
}
