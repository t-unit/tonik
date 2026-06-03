import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/naming/property_name_normalizer.dart';
import 'package:tonik_generate/src/util/source_file_url.dart';
import 'package:tonik_generate/src/util/spec_literal_string.dart';

/// Returns a compile-time const Dart expression for [jsonValue] that
/// satisfies [targetModel], or `null` when callers should follow their
/// no-default code path.
///
/// A null [jsonValue] returns `null`: the carrier (`Property.defaultValue`
/// is `Object?` with no `hasDefault` flag) cannot distinguish "no default
/// keyword" from "explicit `default: null`", so both collapse to the
/// no-default path.
Expression? materialiseConstDefault({
  required Object? jsonValue,
  required Model targetModel,
  required NameManager nameManager,
  required String package,
}) {
  if (jsonValue == null) return null;

  final resolved = targetModel.resolved;

  return switch (resolved) {
    StringModel() => jsonValue is String ? specLiteralString(jsonValue) : null,
    IntegerModel() => jsonValue is int ? literalNum(jsonValue) : null,
    DoubleModel() => jsonValue is num
        ? literalNum(jsonValue.toDouble())
        : null,
    NumberModel() => jsonValue is num ? literalNum(jsonValue) : null,
    BooleanModel() => jsonValue is bool ? literalBool(jsonValue) : null,
    final EnumModel<dynamic> model => _materialiseEnumDefault(
      model: model,
      jsonValue: jsonValue,
      nameManager: nameManager,
      package: package,
    ),
    _ => null,
  };
}

// Nullable enums route through a typedef + `$Raw`-prefixed actual enum;
// const variant access would need the prefixed symbol, which is not yet
// wired up.
Expression? _materialiseEnumDefault({
  required EnumModel<dynamic> model,
  required Object? jsonValue,
  required NameManager nameManager,
  required String package,
}) {
  if (model.isNullable) return null;

  final entries = model.values.toList();
  final matchedIndex = entries.indexWhere((e) => e.value == jsonValue);
  if (matchedIndex < 0) return null;

  final fallback = model.fallbackValue;
  final inputs = [
    ...entries.map((v) => v.nameOverride ?? v.value.toString()),
    if (fallback != null) fallback.nameOverride ?? fallback.value.toString(),
  ];
  final normalized = normalizeEnumValues(inputs);
  final variantName = normalized[matchedIndex].normalizedName;

  final enumName = nameManager.modelName(model);
  final url = sourceFileUrl(package, 'model', enumName);
  return refer('$enumName.$variantName', url);
}
