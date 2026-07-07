/// A style-neutral property value carrying whether it originated as a single
/// scalar or as an array, so the distinction survives until encode time.
///
/// A plain `Map<String, List<String>>` cannot tell `scalar('')` from
/// `array([])`, and an array's element boundaries must be preserved so an
/// encoder can choose between repeated keys and a comma-joined value.
sealed class PropertyValue {
  const PropertyValue();

  /// A single raw (unescaped) value.
  const factory PropertyValue.scalar(String value) = ScalarPropertyValue;

  /// Raw (unescaped) array elements whose boundaries survive until encode time.
  const factory PropertyValue.array(List<String> values) = ArrayPropertyValue;
}

/// A [PropertyValue] holding a single raw value.
final class ScalarPropertyValue extends PropertyValue {
  /// Creates a scalar property value from a raw (unescaped) [value].
  const ScalarPropertyValue(this.value);

  /// The raw (unescaped) value.
  final String value;
}

/// A [PropertyValue] holding raw array elements.
final class ArrayPropertyValue extends PropertyValue {
  /// Creates an array property value from raw (unescaped) [values].
  const ArrayPropertyValue(this.values);

  /// The raw (unescaped) elements.
  final List<String> values;
}
