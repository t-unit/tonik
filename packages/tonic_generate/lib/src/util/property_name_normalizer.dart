import 'package:tonic_core/tonic_core.dart';
import 'package:tonic_generate/src/util/name_utils.dart';

/// Normalizes a list of properties to follow Dart guidelines.
/// Ensures all normalized names are unique by appending numbers if needed.
///
/// Examples:
/// - user_name -> userName
/// - _name -> name
/// - UserName -> userName
/// - user-name -> userName2 (if userName already exists)
/// - user123 -> user123
/// - empty string or _ -> field1, field2, etc.
List<({String normalizedName, Property property})> normalizeProperties(
  List<Property> properties,
) {
  final normalized =
      properties
          .map(
            (prop) => (
              normalizedName: normalizeSingle(prop.name, preserveNumbers: true),
              originalValue: prop,
            ),
          )
          .toList();

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
  final normalized =
      values
          .map(
            (value) => (
              normalizedName: normalizeEnumValueName(value),
              originalValue: value,
            ),
          )
          .toList();

  return ensureUniqueness(normalized);
}
