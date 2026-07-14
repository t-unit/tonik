import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_utils.dart';

/// Normalizes a list of properties to follow Dart guidelines.
/// Ensures all normalized names are unique by appending numbers if needed.
///
/// If a property has a nameOverride set, it uses that value (sanitized)
/// instead of normalizing from the original name.
///
/// Examples:
/// - user_name -> userName
/// - _name -> name
/// - UserName -> userName
/// - user-name -> userName2 (if userName already exists)
/// - user123 -> user123
/// - empty string or _ -> field1, field2, etc.
/// - property with nameOverride='customName' -> customName
///
/// [reservedNameReplacements] maps normalized names owned by the generated
/// container to the name a property should use instead. The replacement is
/// applied after normalization and before uniqueness handling.
List<({String normalizedName, Property property})> normalizeProperties(
  List<Property> properties, {
  Map<String, String> reservedNameReplacements = const {},
}) {
  final normalizedReservedNameReplacements = {
    for (final entry in reservedNameReplacements.entries)
      normalizeSingle(
        entry.key,
        preserveNumbers: true,
      ).toLowerCase(): normalizeSingle(
        entry.value,
        preserveNumbers: true,
      ),
  };

  final normalized = properties.map((prop) {
    final normalizedName = prop.nameOverride != null
        ? normalizeSingle(
            prop.nameOverride!,
            preserveNumbers: true,
          )
        : normalizeSingle(prop.name, preserveNumbers: true);
    return (
      normalizedName:
          normalizedReservedNameReplacements[normalizedName.toLowerCase()] ??
          normalizedName,
      originalValue: prop,
    );
  }).toList();

  final unique = ensureUniqueness(
    normalized,
    defaultPrefix: defaultFieldPrefix,
  );

  return unique
      .map(
        (item) => (
          normalizedName: item.normalizedName,
          property: item.originalValue,
        ),
      )
      .toList();
}

/// Normalizes a list of enum values to follow Dart guidelines.
/// Ensures all normalized names are unique by appending numbers if needed.
///
/// Examples:
/// - [user_name, userName] -> [userName, userName2]
/// - [123, one_two_three] -> [oneHundredTwentyThree, oneTwoThree]
/// - [_, __, ___] -> [value, value2, value3]
List<({String normalizedName, String originalValue})> normalizeEnumValues(
  List<String> values,
) {
  final normalized = values
      .map(
        (value) => (
          normalizedName: normalizeEnumValueName(value),
          originalValue: value,
        ),
      )
      .toList();

  return ensureUniqueness(normalized);
}
