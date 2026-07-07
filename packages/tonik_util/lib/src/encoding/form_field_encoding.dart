import 'package:meta/meta.dart';

/// Per-property encoding options threaded into a form-style `toForm` call so
/// individual object properties can opt into reserved-character preservation.
@immutable
class FormFieldEncoding {
  /// Creates a descriptor; [allowReserved] defaults to false.
  const FormFieldEncoding({this.allowReserved = false, this.explode});

  /// When true, reserved characters in this property's value stay literal
  /// except the form delimiters `& = +`.
  final bool allowReserved;

  /// When true, an array property is exploded into repeated keys by the
  /// `Map<String, PropertyValue>` form encoder; when false or null the array
  /// is comma-joined into a single entry.
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
