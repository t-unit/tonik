import 'package:change_case/change_case.dart';

const defaultEnumPrefix = 'value';

const defaultFieldPrefix = 'field';

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
  'fromJson',
  'toJson',
  'copyWith',
  'toString',
  'hashCode',
  'fromSimple',
  'fromForm',
  'toSimple',
  'toForm',
  'toLabel',
  'toMatrix',
  'toDeepObject',
  'currentEncodingShape',
  'parameterProperties',
  'uriEncode',
};

const Set<String> allKeywords = {...dartKeywords, ...generatedClassTokens};

/// Converts a number to its English word representation.
/// Supports numbers up to trillions.
String _numberToWords(int number) {
  if (number == 0) return 'zero';

  const ones = [
    '',
    'one',
    'two',
    'three',
    'four',
    'five',
    'six',
    'seven',
    'eight',
    'nine',
    'ten',
    'eleven',
    'twelve',
    'thirteen',
    'fourteen',
    'fifteen',
    'sixteen',
    'seventeen',
    'eighteen',
    'nineteen',
  ];

  const tens = [
    '',
    '',
    'twenty',
    'thirty',
    'forty',
    'fifty',
    'sixty',
    'seventy',
    'eighty',
    'ninety',
  ];

  final result = <String>[];
  var remaining = number;

  if (remaining >= 1000000000000) {
    result
      ..add(_numberToWords(remaining ~/ 1000000000000))
      ..add('trillion');
    remaining %= 1000000000000;
  }

  if (remaining >= 1000000000) {
    result
      ..add(_numberToWords(remaining ~/ 1000000000))
      ..add('billion');
    remaining %= 1000000000;
  }

  if (remaining >= 1000000) {
    result
      ..add(_numberToWords(remaining ~/ 1000000))
      ..add('million');
    remaining %= 1000000;
  }

  if (remaining >= 1000) {
    result
      ..add(_numberToWords(remaining ~/ 1000))
      ..add('thousand');
    remaining %= 1000;
  }

  if (remaining >= 100) {
    result
      ..add(ones[remaining ~/ 100])
      ..add('hundred');
    remaining %= 100;
  }

  if (remaining >= 20) {
    result.add(tens[remaining ~/ 10]);
    if (remaining % 10 != 0) {
      result.add(ones[remaining % 10]);
    }
  } else if (remaining > 0) {
    result.add(ones[remaining]);
  }

  return result.join(' ').trim();
}

/// Ensures a name is not a Dart keyword by adding a $ prefix if necessary.
String ensureNotKeyword(String name) {
  if (allKeywords.contains(name.toCamelCase()) ||
      allKeywords.contains(name.toLowerCase())) {
    return '\$$name';
  }
  return name;
}

/// Splits text into tokens and normalizes each one.
String _normalizeText(String text, {bool preserveNumbers = false}) {
  if (text.isEmpty) return '';

  // Clean invalid characters but preserve separators for splitting
  final cleaned = text.replaceAll(RegExp(r'[^a-zA-Z0-9_\-\s]'), '');

  // Split on separators and case boundaries
  final tokens =
      cleaned
          .split(
            RegExp(r'[_\-\s]+|(?<=[a-z])(?=[A-Z])|(?<=[A-Z])(?=[A-Z][a-z])'),
          )
          .where((token) => token.isNotEmpty)
          .toList();

  if (tokens.isEmpty) return '';

  final result = <String>[];
  final numbersToAppend = <String>[];

  for (var i = 0; i < tokens.length; i++) {
    final token = tokens[i];
    final isFirst = i == 0;

    // Extract numbers from token
    final numberMatch = RegExp(r'^(\d+)(.*)$|^(.+?)(\d+)$').firstMatch(token);

    String textPart;
    String? numberPart;

    if (numberMatch != null) {
      if (numberMatch.group(1) != null) {
        // Leading number: 123abc
        numberPart = numberMatch.group(1);
        textPart = numberMatch.group(2) ?? '';
      } else {
        // Trailing number: abc123
        textPart = numberMatch.group(3) ?? '';
        numberPart = numberMatch.group(4);
      }
    } else if (RegExp(r'^\d+$').hasMatch(token)) {
      // Pure number
      numberPart = token;
      textPart = '';
    } else {
      // No numbers
      textPart = token;
      numberPart = null;
    }

    // Process text part
    if (textPart.isNotEmpty) {
      final normalized = _normalizeCasing(textPart, isFirst: isFirst);
      result.add(normalized);
    }

    // Handle numbers
    if (numberPart != null) {
      if (isFirst && textPart.isNotEmpty && numberMatch?.group(1) != null) {
        // Move leading numbers from first token to end
        // (e.g., "1status" -> "status1")
        numbersToAppend.add(numberPart);
      } else {
        // Keep numbers in place for trailing numbers or non-first tokens
        result.add(numberPart);
      }
    }
  }

  // Append any numbers that were moved from the first token
  result.addAll(numbersToAppend);

  return result.join();
}

/// Normalizes the casing of a text token.
String _normalizeCasing(String text, {required bool isFirst}) {
  if (text.isEmpty) return text;

  final isAllCaps = text == text.toUpperCase() && text != text.toLowerCase();

  // Special handling for keywords - keep them lowercase for first part only
  if (isFirst && allKeywords.contains(text.toLowerCase())) {
    return text.toLowerCase();
  }

  if (isFirst) {
    return isAllCaps ? text.toLowerCase() : text.toCamelCase();
  } else {
    return isAllCaps ? text.toPascalCase() : text.toPascalCase();
  }
}

/// Normalizes a single name to follow Dart guidelines.
String normalizeSingle(String name, {bool preserveNumbers = false}) {
  if (name.isEmpty || RegExp(r'^_+$').hasMatch(name)) {
    return '';
  }

  // Remove leading underscores
  var processedName = name.replaceAll(RegExp('^_+'), '');
  if (processedName.isEmpty) return '';

  // If preserving numbers and it's just a number, return as-is
  if (preserveNumbers && RegExp(r'^\d+$').hasMatch(processedName)) {
    return processedName;
  }

  processedName = _normalizeText(
    processedName,
    preserveNumbers: preserveNumbers,
  );

  return ensureNotKeyword(processedName);
}

/// Normalizes an enum value name, handling special cases like integers.
String normalizeEnumValueName(String value) {
  // Only spell out numbers if the entire value is just a number (no prefix)
  if (RegExp(r'^-?\d+$').hasMatch(value)) {
    final number = int.parse(value);
    final words =
        number < 0
            ? 'minus ${_numberToWords(number.abs())}'
            : _numberToWords(number);
    final normalized = normalizeSingle(words);
    return normalized.isEmpty ? defaultEnumPrefix : normalized.toCamelCase();
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
