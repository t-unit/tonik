import 'package:change_case/change_case.dart';
import 'package:tonic_core/tonic_core.dart';

/// Normalizes property names to follow Dart guidelines by converting them
/// to camelCase and handling special cases.
class PropertyNameNormalizer {
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
  List<({String normalizedName, Property property})> normalizeAll(
    List<Property> properties,
  ) {
    final result = <({String normalizedName, Property property})>[];

    // First pass: normalize all names and group by base name
    final normalizedGroups =
        <String, List<({String normalizedName, Property property})>>{};
    for (final property in properties) {
      var normalizedName = _normalize(property.name);
      if (normalizedName.isEmpty) {
        normalizedName = 'field';
      }

      // Extract any trailing numbers from the normalized name
      final numberMatch = RegExp(r'^(.*?)(\d+)$').firstMatch(normalizedName);
      final baseName = numberMatch?.group(1) ?? normalizedName;
      final originalNumber = numberMatch?.group(2);

      // For names with numbers, use the number as part of the base name
      final uniqueKey =
          originalNumber != null ? '$baseName$originalNumber' : baseName;
      normalizedGroups.putIfAbsent(uniqueKey.toLowerCase(), () => []);
      normalizedGroups[uniqueKey.toLowerCase()]!.add((
        normalizedName: normalizedName,
        property: property,
      ),);
    }

    // Second pass: ensure uniqueness within each group
    for (final group in normalizedGroups.values) {
      if (group.isEmpty) continue;

      // Use the first name's casing as the template
      final template = group.first.normalizedName;

      for (var i = 0; i < group.length; i++) {
        final uniqueName = i == 0 ? template : '$template${i + 1}';
        result.add((normalizedName: uniqueName, property: group[i].property));
      }
    }

    return result;
  }

  String _normalize(String propertyName) {
    // Remove leading underscores
    final name = propertyName.replaceAll(RegExp('^_+'), '');
    if (name.isEmpty) return '';

    // Split the name into parts based on common separators and case boundaries
    final parts = name.split(RegExp(r'[_\- ]|(?=[A-Z])'));
    if (parts.isEmpty) return '';

    // Process each part
    final processedParts = <String>[];

    // Handle first part
    final firstPart = parts.first.replaceAll(RegExp('[^a-zA-Z0-9]'), '');
    if (firstPart.isNotEmpty) {
      // Check if the first part ends with a number
      final numberMatch = RegExp(r'^(.*?)(\d+)$').firstMatch(firstPart);
      if (numberMatch != null) {
        final base = numberMatch.group(1) ?? '';
        final number = numberMatch.group(2) ?? '';
        processedParts.add(base.toCamelCase() + number);
      } else {
        processedParts.add(firstPart.toCamelCase());
      }
    }

    // Handle subsequent parts
    for (var i = 1; i < parts.length; i++) {
      var part = parts[i].replaceAll(RegExp('[^a-zA-Z0-9]'), '');
      if (part.isEmpty) continue;

      // Check if the part ends with a number
      final numberMatch = RegExp(r'^(.*?)(\d+)$').firstMatch(part);
      if (numberMatch != null) {
        final base = numberMatch.group(1) ?? '';
        final number = numberMatch.group(2) ?? '';
        if (base.isNotEmpty) {
          part = base.toPascalCase() + number;
        } else {
          part = number;
        }
      } else {
        part = part.toPascalCase();
      }

      processedParts.add(part);
    }

    return processedParts.join();
  }
}
