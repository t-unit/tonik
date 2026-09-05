import 'package:meta/meta.dart';

/// A style-neutral property value carrying whether it originated as a single
/// scalar or as an array, so the distinction survives until encode time.
///
/// A plain `Map<String, List<String>>` cannot tell `scalar('x')` from
/// `array(['x'])`, and an array's element boundaries must be preserved so an
/// encoder can choose between repeated keys and a comma-joined value.
sealed class const PropertyValue() {
  /// A single raw (unescaped) value.
  const factory scalar(String value) = ScalarPropertyValue;

  /// Raw (unescaped) array elements whose boundaries survive until encode time.
  const factory array(List<String> values) = ArrayPropertyValue;
}

/// A [PropertyValue] holding a single raw value.
@immutable
final class const ScalarPropertyValue(
  /// The raw (unescaped) value.
  final String value,
) extends PropertyValue;

/// A [PropertyValue] holding raw array elements.
@immutable
final class const ArrayPropertyValue(
  /// The raw (unescaped) elements.
  final List<String> values,
) extends PropertyValue;
