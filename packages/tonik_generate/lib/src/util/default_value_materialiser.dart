import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/util/source_file_url.dart';
import 'package:tonik_generate/src/util/spec_literal_string.dart';
import 'package:tonik_generate/src/util/type_reference_generator.dart';

const _ficUrl =
    'package:fast_immutable_collections/fast_immutable_collections.dart';

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
  bool useImmutableCollections = false,
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
    final ListModel model => _materialiseListDefault(
      model: model,
      jsonValue: jsonValue,
      nameManager: nameManager,
      package: package,
      useImmutableCollections: useImmutableCollections,
    ),
    final MapModel model => _materialiseMapDefault(
      model: model,
      jsonValue: jsonValue,
      nameManager: nameManager,
      package: package,
      useImmutableCollections: useImmutableCollections,
    ),
    AnyModel() => _materialiseAnyDefault(jsonValue),
    _ => null,
  };
}

Expression? _materialiseEnumDefault({
  required EnumModel<dynamic> model,
  required Object? jsonValue,
  required NameManager nameManager,
  required String package,
}) {
  // Nullable enum's actual name is $Raw-prefixed; const variant ref not wired.
  if (model.isNullable) return null;

  final entries = model.values.toList();
  final matchedIndex = entries.indexWhere((e) => e.value == jsonValue);
  if (matchedIndex < 0) return null;

  final variantName =
      nameManager.enumVariantNames(model).valueNames[matchedIndex];
  final enumName = nameManager.modelName(model);
  final url = sourceFileUrl(package, 'model', enumName);
  return refer('$enumName.$variantName', url);
}

Expression? _materialiseListDefault({
  required ListModel model,
  required Object? jsonValue,
  required NameManager nameManager,
  required String package,
  required bool useImmutableCollections,
}) {
  if (jsonValue is! List) return null;

  final itemModel = model.content;
  final items = <Expression>[];
  for (final item in jsonValue) {
    final entry = materialiseConstDefault(
      jsonValue: item,
      targetModel: itemModel,
      nameManager: nameManager,
      package: package,
      useImmutableCollections: useImmutableCollections,
    );
    if (entry == null) return null;
    items.add(entry);
  }

  final itemType = typeReference(
    itemModel,
    nameManager,
    package,
    useImmutableCollections: useImmutableCollections,
  );
  final literal = literalConstList(items, itemType);
  if (!useImmutableCollections) return literal;
  return refer('IListConst', _ficUrl).constInstance([literal]);
}

Expression? _materialiseMapDefault({
  required MapModel model,
  required Object? jsonValue,
  required NameManager nameManager,
  required String package,
  required bool useImmutableCollections,
}) {
  if (jsonValue is! Map) return null;

  final valueModel = model.valueModel;
  final entries = <Object?, Object?>{};
  for (final entry in jsonValue.entries) {
    final key = entry.key;
    if (key is! String) return null;
    final value = materialiseConstDefault(
      jsonValue: entry.value,
      targetModel: valueModel,
      nameManager: nameManager,
      package: package,
      useImmutableCollections: useImmutableCollections,
    );
    if (value == null) return null;
    entries[specLiteralString(key)] = value;
  }

  final valueType = typeReference(
    valueModel,
    nameManager,
    package,
    useImmutableCollections: useImmutableCollections,
  );
  final literal = literalConstMap(
    entries,
    refer('String', 'dart:core'),
    valueType,
  );
  if (!useImmutableCollections) return literal;
  return refer('IMapConst', _ficUrl).constInstance([literal]);
}

Expression? _materialiseAnyDefault(Object? jsonValue) {
  switch (jsonValue) {
    case null:
      return literalNull;
    case final bool value:
      return literalBool(value);
    case final num value:
      return literalNum(value);
    case final String value:
      return specLiteralString(value);
    case final List<Object?> value:
      final items = <Expression>[];
      for (final item in value) {
        final entry = _materialiseAnyDefault(item);
        if (entry == null) return null;
        items.add(entry);
      }
      return literalConstList(items, refer('Object?', 'dart:core'));
    case final Map<Object?, Object?> value:
      final entries = <Object?, Object?>{};
      for (final entry in value.entries) {
        final key = entry.key;
        if (key is! String) return null;
        final mapped = _materialiseAnyDefault(entry.value);
        if (mapped == null) return null;
        entries[specLiteralString(key)] = mapped;
      }
      return literalConstMap(
        entries,
        refer('String', 'dart:core'),
        refer('Object?', 'dart:core'),
      );
  }
  return null;
}
