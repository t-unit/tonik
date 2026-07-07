import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';

/// Builds the generation-time expression that converts a single [receiver]
/// value to its raw (unescaped) string form, dispatching on [model].
///
/// The conversion is chosen per model type: each type maps to the specific
/// method that yields its canonical wire string.
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
    // String enums must precede the catch-all, which also matches them.
    EnumModel<String>() => receiver.property('toJson').call([]),
    EnumModel() =>
      receiver.property('toJson').call([]).property('toString').call([]),
    Base64Model() => receiver.property('toBase64String').call([]),
    BinaryModel() =>
      receiver.property('toBytes').call([]).property('decodeToString').call([]),
    AliasModel(:final model) => buildRawStringExpression(receiver, model),
    _ => throw UnsupportedError(
      'buildRawStringExpression does not support ${model.runtimeType}',
    ),
  };
}
