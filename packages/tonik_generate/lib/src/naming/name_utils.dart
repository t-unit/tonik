import 'package:change_case/change_case.dart';
import 'package:number_to_words_english/number_to_words_english.dart';

/// Default prefix used for empty or invalid enum values.
const defaultEnumPrefix = 'value';

/// Default prefix used for empty or invalid field names.
const defaultFieldPrefix = 'field';

/// Reserved Dart keywords that cannot be used as identifiers.
const dartKeywords = {
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

const generatedClassTokens = {
  'fromjson',
  'toJson',
  'copyWith',
  'toString',
  'hashCode',
};

const Set<String> allKeywords = {...dartKeywords, ...generatedClassTokens};

/// Ensures a name is not a Dart keyword by adding a $ prefix if necessary.
String ensureNotKeyword(String name) {
  if (allKeywords.contains(name.toCamelCase()) ||
      allKeywords.contains(name.toLowerCase())) {
    return '\$$name';
  }
  return name;
}

/// Processes a part of a name, handling numbers and casing.
/// If [isFirstPart] is true, numbers at the start will be moved to the end.
({String processed, String? number}) processPart(
  String part, {
  required bool isFirstPart,
}) {
  final processedPart = part.replaceAll(RegExp('[^a-zA-Z0-9]'), '');
  if (processedPart.isEmpty) return (processed: '', number: null);

  /// Helper function to normalize case: only convert to lowercase if all caps
  String normalizeCase(String text, {required bool isFirst}) {
    if (text.isEmpty) return text;
    
    final isAllCaps = 
        text == text.toUpperCase() && text != text.toLowerCase();
    
    // Special handling for Dart keywords: keep them lowercase for first part
    if (isFirst && allKeywords.contains(text.toLowerCase())) {
      return text.toLowerCase();
    }
    
    if (isFirst) {
      // For first part, convert to lowercase if all caps, otherwise camelCase
      if (isAllCaps) {
        return text.toLowerCase();
      } else {
        // For mixed case, convert to proper camelCase (first letter lowercase)
        return text.length == 1 
            ? text.toLowerCase() 
            : text.substring(0, 1).toLowerCase() + text.substring(1);
      }
    } else {
      // For subsequent parts, convert to PascalCase if all caps, otherwise 
      // ensure PascalCase
      if (isAllCaps) {
        return text.toPascalCase();
      } else {
        // For mixed case, ensure it starts with uppercase
        return text.length == 1 
            ? text.toUpperCase() 
            : text.substring(0, 1).toUpperCase() + text.substring(1);
      }
    }
  }

  // Handle numbers differently for first part vs subsequent parts
  if (isFirstPart) {
    final numberMatch = RegExp(r'^(\d+)(.+)$').firstMatch(processedPart);
    if (numberMatch != null) {
      final number = numberMatch.group(1)!;
      final rest = numberMatch.group(2)!;
      return (
        processed: normalizeCase(rest, isFirst: true), 
        number: number,
      );
    }
    return (
      processed: normalizeCase(processedPart, isFirst: true), 
      number: null,
    );
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
        return (
          processed: normalizeCase(leadingRest, isFirst: false), 
          number: leadingNumber,
        );
      } else if (trailingBase != null && trailingNumber != null) {
        return (
          processed: normalizeCase(trailingBase, isFirst: false), 
          number: trailingNumber,
        );
      }
    }
    return (
      processed: normalizeCase(processedPart, isFirst: false), 
      number: null,
    );
  }
}

/// Splits a string into parts based on common separators and case boundaries.
List<String> splitIntoParts(String value) {
  // Split on explicit separators and case boundaries
  final parts = value.split(
    RegExp(r'[_\- ]|(?<=[a-z])(?=[A-Z])|(?<=[A-Z])(?=[A-Z][a-z])'),
  );
  
  return parts.where((part) => part.isNotEmpty).toList();
}

/// Processes parts into a normalized name.
String processPartsIntoName(List<String> parts) {
  if (parts.isEmpty) return '';

  final processedParts = <String>[];

  // Process first part
  final firstResult = processPart(parts.first, isFirstPart: true);
  if (firstResult.processed.isNotEmpty) {
    processedParts.add(firstResult.processed);
    if (firstResult.number != null) {
      processedParts.add(firstResult.number!);
    }
  }

  // Process remaining parts
  for (var i = 1; i < parts.length; i++) {
    final result = processPart(parts[i], isFirstPart: false);
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
String normalizeSingle(String name, {bool preserveNumbers = false}) {
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

  final parts = splitIntoParts(processedName);
  processedName = processPartsIntoName(parts);

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

  return ensureNotKeyword(processedName);
}

/// Normalizes an enum value name, handling special cases like integers.
String normalizeEnumValueName(String value) {
  // Only spell out numbers if the entire value is just a number (no prefix)
  if (RegExp(r'^-?\d+$').hasMatch(value)) {
    final number = int.parse(value);
    final words = number < 0 
        ? 'minus ${NumberToWordsEnglish.convert(number.abs())}'
        : NumberToWordsEnglish.convert(number);
    final normalized = normalizeSingle(words);
    return normalized.isEmpty 
        ? defaultEnumPrefix 
        : normalized.toCamelCase();
  }

  // For values with prefixes (like ERROR_404), preserve numbers as-is
  final normalized = normalizeSingle(value, preserveNumbers: true);
  if (normalized.isEmpty) return defaultEnumPrefix;
  
  // Don't apply toCamelCase if the normalized value starts with $
  if (normalized.startsWith(r'$')) {
    return normalized;
  }
  
  return normalized.toCamelCase();
}

/// Ensures uniqueness in a list of normalized names
/// by appending numbers if needed.
List<({String normalizedName, T originalValue})> ensureUniqueness<T>(
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
        uniqueName = '$template$existingNumber$counter';
      } else {
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
