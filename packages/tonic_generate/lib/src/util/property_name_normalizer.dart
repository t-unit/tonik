import 'package:change_case/change_case.dart';
import 'package:spell_out_numbers/spell_out_numbers.dart';
import 'package:tonic_core/tonic_core.dart';

/// Default prefix used for empty or invalid enum values.
const _defaultEnumPrefix = 'value';

/// Default prefix used for empty or invalid field names.
const _defaultFieldPrefix = 'field';

/// Reserved Dart keywords that cannot be used as identifiers.
const _dartKeywords = {
  'abstract',
  'as',
  'assert',
  'async',
  'await',
  'base',
  'break',
  'case',
  'catch',
  'class',
  'const',
  'continue',
  'covariant',
  'default',
  'deferred',
  'do',
  'dynamic',
  'else',
  'enum',
  'export',
  'extends',
  'extension',
  'external',
  'factory',
  'false',
  'final',
  'finally',
  'for',
  'Function',
  'get',
  'hide',
  'if',
  'implements',
  'import',
  'in',
  'interface',
  'is',
  'late',
  'library',
  'mixin',
  'new',
  'null',
  'of',
  'on',
  'operator',
  'part',
  'required',
  'rethrow',
  'return',
  'sealed',
  'set',
  'show',
  'static',
  'super',
  'switch',
  'sync',
  'this',
  'throw',
  'true',
  'try',
  'type',
  'typedef',
  'var',
  'void',
  'when',
  'with',
  'while',
  'yield',
};

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
              normalizedName: _normalizeSingle(
                prop.name,
                preserveNumbers: true,
              ),
              originalValue: prop,
            ),
          )
          .toList();

  final unique = _ensureUniqueness(
    normalized,
    defaultPrefix: _defaultFieldPrefix,
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
              normalizedName: _normalizeEnumValueName(value),
              originalValue: value,
            ),
          )
          .toList();

  return _ensureUniqueness(normalized);
}

/// Normalizes an enum value name, handling special cases like integers.
String _normalizeEnumValueName(String value) {
  // For integer values, spell out the number
  if (RegExp(r'^\d+$').hasMatch(value)) {
    final number = int.parse(value);
    final words = EnglishNumberScheme().toWord(number);
    final normalized = _normalizeSingle(words);
    return normalized.isEmpty ? _defaultEnumPrefix : normalized;
  }

  final normalized = _normalizeSingle(value);
  return normalized.isEmpty ? _defaultEnumPrefix : normalized;
}

/// Ensures a name is not a Dart keyword by adding a $ prefix if necessary.
String _ensureNotKeyword(String name) {
  final lower = name.toLowerCase();
  if (_dartKeywords.contains(lower)) {
    return '\$$lower';
  }
  return name;
}

/// Processes a part of a name, handling numbers and casing.
/// If [isFirstPart] is true, numbers at the start will be moved to the end.
({String processed, String? number}) _processPart(
  String part, {
  required bool isFirstPart,
}) {
  final processedPart = part.replaceAll(RegExp('[^a-zA-Z0-9]'), '');
  if (processedPart.isEmpty) return (processed: '', number: null);

  // Handle numbers differently for first part vs subsequent parts
  if (isFirstPart) {
    final numberMatch = RegExp(r'^(\d+)(.+)$').firstMatch(processedPart);
    if (numberMatch != null) {
      final number = numberMatch.group(1)!;
      final rest = numberMatch.group(2)!;
      return (processed: rest.toCamelCase(), number: number);
    }
    return (processed: processedPart.toCamelCase(), number: null);
  } else {
    final numberMatch = RegExp(
      r'^(\d+)(.+)$|^(.+?)(\d+)$',
    ).firstMatch(processedPart);
    if (numberMatch != null) {
      final leadingNumber = numberMatch.group(1);
      final leadingRest = numberMatch.group(2);
      final trailingBase = numberMatch.group(3);
      final trailingNumber = numberMatch.group(4);

      if (leadingNumber != null && leadingRest != null) {
        return (processed: leadingRest.toPascalCase(), number: leadingNumber);
      } else if (trailingBase != null && trailingNumber != null) {
        return (processed: trailingBase.toPascalCase(), number: trailingNumber);
      }
    }
    return (processed: processedPart.toPascalCase(), number: null);
  }
}

/// Splits a string into parts based on common separators and case boundaries.
List<String> _splitIntoParts(String value) =>
    value.split(RegExp(r'[_\- ]|(?=[A-Z])'));

/// Processes parts into a normalized name.
String _processPartsIntoName(List<String> parts) {
  if (parts.isEmpty) return '';

  final processedParts = <String>[];

  // Process first part
  final firstResult = _processPart(parts.first, isFirstPart: true);
  if (firstResult.processed.isNotEmpty) {
    processedParts.add(firstResult.processed);
    if (firstResult.number != null) {
      processedParts.add(firstResult.number!);
    }
  }

  // Process remaining parts
  for (var i = 1; i < parts.length; i++) {
    final result = _processPart(parts[i], isFirstPart: false);
    if (result.processed.isNotEmpty) {
      processedParts.add(result.processed);
      if (result.number != null) {
        processedParts.add(result.number!);
      }
    }
  }

  return processedParts.join();
}

/// Normalizes a single name to follow Dart guidelines.
String _normalizeSingle(String name, {bool preserveNumbers = false}) {
  // Handle empty or underscore-only strings
  if (name.isEmpty || RegExp(r'^_+$').hasMatch(name)) {
    return '';
  }

  // Remove leading underscores
  var processedName = name.replaceAll(RegExp('^_+'), '');
  if (processedName.isEmpty) return '';

  // If we need to preserve numbers and the name is just a number, return it
  if (preserveNumbers && RegExp(r'^\d+$').hasMatch(processedName)) {
    return processedName;
  }

  final parts = _splitIntoParts(processedName);
  processedName = _processPartsIntoName(parts);

  // If preserving numbers, ensure we don't lose them in the normalization
  if (preserveNumbers) {
    final originalNumber = RegExp(r'\d+$').firstMatch(name)?.group(0);
    final processedNumber = RegExp(r'\d+$').firstMatch(processedName)?.group(0);
    if (originalNumber != null && processedNumber != originalNumber) {
      // Remove any trailing numbers and append the original number
      final baseProcessed = processedName.replaceAll(RegExp(r'\d+$'), '');
      processedName = '$baseProcessed$originalNumber';
    }
  }

  // Ensure the name is not a Dart keyword
  return _ensureNotKeyword(processedName);
}

/// Ensures uniqueness in a list of normalized names
/// by appending numbers if needed.
List<({String normalizedName, T originalValue})> _ensureUniqueness<T>(
  List<({String normalizedName, T originalValue})> values, {
  String defaultPrefix = 'value',
}) {
  final result = <({String normalizedName, T originalValue})>[];
  final usedNames = <String>{}; // lowercase names for uniqueness check
  final baseNameTemplates =
      <String, String>{}; // lowercase base -> template with correct casing
  final baseNameCounters = <String, int>{}; // lowercase base -> counter

  for (final value in values) {
    var processedName = value.normalizedName;
    if (processedName.isEmpty) {
      processedName = defaultPrefix;
    }

    // Extract base name and any existing number
    final numberMatch = RegExp(r'^(.*?)(\d+)$').firstMatch(processedName);
    final baseName = numberMatch?.group(1) ?? processedName;
    final existingNumber = numberMatch?.group(2);

    // Get or create the counter for this base name
    final lowerBaseName = baseName.toLowerCase();

    // Store the first occurrence as the template for correct casing
    if (!baseNameTemplates.containsKey(lowerBaseName)) {
      baseNameTemplates[lowerBaseName] = baseName;
    }

    baseNameCounters.putIfAbsent(lowerBaseName, () => 2);
    var counter = baseNameCounters[lowerBaseName]!;

    // If the name is already used, append the counter
    var uniqueName = processedName;
    var lowerUniqueName = uniqueName.toLowerCase();

    while (usedNames.contains(lowerUniqueName)) {
      final template = baseNameTemplates[lowerBaseName]!;
      if (existingNumber != null) {
        // If the name already has a number, append the counter to that number
        uniqueName = '$template$existingNumber$counter';
      } else {
        // Otherwise, just append the counter
        uniqueName = '$template$counter';
      }
      lowerUniqueName = uniqueName.toLowerCase();
      counter++;
    }

    baseNameCounters[lowerBaseName] = counter;
    usedNames.add(lowerUniqueName);

    final item = (
      normalizedName: uniqueName,
      originalValue: value.originalValue,
    );
    result.add(item);
  }

  return result;
}
