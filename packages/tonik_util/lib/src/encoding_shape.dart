/// Represents the encoding shape of a model.
///
/// This indicates how a model can be encoded in simple/form encoding:
/// - [simple]: Can be encoded as a single string value (primitives, enums).
/// - [complex]: Can only be encoded as key-value pairs (objects, lists).
/// - [mixed]: Contains both simple and complex types (some compositions).
enum EncodingShape {
  /// Simple types that encode to a single string value.
  simple,

  /// Complex types that encode to key-value pairs.
  complex,

  /// Mixed types containing both simple and complex.
  mixed,
}
