import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';

/// Builds the generation-time expression that converts a single [receiver]
/// value to its raw (unescaped) string form, dispatching on [model].
///
/// This is a compile-time dispatch on the model type, not a runtime
/// `.toString()` fallback: each type maps to the conversion that yields its
/// canonical wire string.
Expression buildRawStringExpression(Expression receiver, Model model) {
  return switch (model) {
    StringModel() => receiver,
    IntegerModel() ||
    DoubleModel() ||
    NumberModel() ||
    BooleanModel() ||
    DecimalModel() ||
    UriModel() ||
    DateModel() => receiver.property('toString').call([]),
    DateTimeModel() => receiver.property('toTimeZonedIso8601String').call([]),
    EnumModel<String>() => receiver.property('toJson').call([]),
    EnumModel() =>
      receiver.property('toJson').call([]).property('toString').call([]),
    Base64Model() => receiver.property('toBase64String').call([]),
    BinaryModel() => receiver.property('decodeToString').call([]),
    AliasModel(:final model) => buildRawStringExpression(receiver, model),
    _ => throw UnsupportedError(
      'buildRawStringExpression does not support ${model.runtimeType}',
    ),
  };
}
