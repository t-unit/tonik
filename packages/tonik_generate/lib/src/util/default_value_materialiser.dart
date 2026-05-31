import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
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
    _ => null,
  };
}
