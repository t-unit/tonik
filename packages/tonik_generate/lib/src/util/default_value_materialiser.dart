import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/util/spec_literal_string.dart';

/// Returns a compile-time const Dart expression for [jsonValue] that
/// satisfies [targetModel], or `null` when callers should follow their
/// no-default code path.
///
/// M1 covers only primitive scalars; composites and non-const leaves
/// (e.g. `DateTimeModel`) return `null` and will route through Strategy B
/// in later milestones.
///
/// Per D14, `jsonValue == null` collapses with "no default keyword" —
/// absent and explicit-null defaults are indistinguishable at the carrier
/// level and produce no observable behaviour difference.
//
// [nameManager] and [package] are unused in M1; they're reserved for
// Strategy B and collection composites where future calls will need to
// emit cross-package type references.
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
    _ => null,
  };
}
