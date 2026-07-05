import 'package:meta/meta.dart';

/// Per-property encoding options threaded into a form-style `toForm` call:
/// whether an object property opts into reserved-character preservation and,
/// for array properties, whether it explodes into repeated `name=value`
/// entries.
@immutable
class FormFieldEncoding {
  /// Creates a descriptor; [allowReserved] defaults to false.
  const FormFieldEncoding({this.allowReserved = false, this.explode});

  /// When true, reserved characters in this property's value stay literal
  /// except the form delimiters `& = +`.
  final bool allowReserved;

  /// Per-property array explode. When true, a list property emits one repeated
  /// `name=value` entry per element, which requires a matching entry in the
  /// `explodedValues` map passed to `Map<String, String>.toForm`; when false it
  /// stays a single comma-joined entry. Null when the property is not an
  /// exploded array.
  final bool? explode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FormFieldEncoding &&
          runtimeType == other.runtimeType &&
          allowReserved == other.allowReserved &&
          explode == other.explode;

  @override
  int get hashCode => Object.hash(allowReserved, explode);

  @override
  String toString() =>
      'FormFieldEncoding(allowReserved: $allowReserved, explode: $explode)';
}
