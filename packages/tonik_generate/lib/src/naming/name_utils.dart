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

const _specialCharReplacements = {
  '+': 'plus',
  '*': 'asterisk',
  '/': 'slash',
  '~': 'tilde',
  '>': 'greaterThan',
  '<': 'lessThan',
  '=': 'equals',
  '!': 'exclamation',
  '@': 'at',
  '#': 'hash',
  '%': 'percent',
  '^': 'caret',
  '&': 'ampersand',
  '|': 'pipe',
  r'\': 'backslash',
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

/// Names that conflict with members inherited by all Dart enums.
/// These are only reserved for enum values, not class properties.
const reservedEnumMemberNames = {
  'index', // Enum.index — ordinal position
  'values', // Enum.values — static list of all values
};

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

  // Replace dots with spaces so they act as word boundaries
  final withDotsSeparated = text.replaceAll('.', ' ');

  // Replace special characters with word equivalents
  var withSpecialCharsReplaced = withDotsSeparated;
  for (final entry in _specialCharReplacements.entries) {
    withSpecialCharsReplaced = withSpecialCharsReplaced.replaceAll(
      entry.key,
      ' ${entry.value} ',
    );
  }

  // Replace minus sign (not hyphen separator) with "minus"
  // Only when NOT preceded by a letter or digit (i.e., it's a sign,
  // not a separator like "my-name" or "2-beta")
  withSpecialCharsReplaced = withSpecialCharsReplaced.replaceAllMapped(
    RegExp('(?<![a-zA-Z0-9])-'),
    (m) => ' minus ',
  );

  // Clean invalid characters but preserve separators for splitting
  final cleaned = withSpecialCharsReplaced.replaceAll(
    RegExp(r'[^a-zA-Z0-9_\-\s$]'),
    '',
  );

  // Split on separators and case boundaries, but NOT on $
  final tokens = cleaned
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

  // Extract $ characters before case conversion (which strips them)
  final dollars = text.replaceAll(RegExp(r'[^$]'), '');
  final textWithoutDollars = text.replaceAll(r'$', '');

  if (textWithoutDollars.isEmpty) {
    return dollars; // Just return the $ characters
  }

  final isAllCaps =
      textWithoutDollars == textWithoutDollars.toUpperCase() &&
      textWithoutDollars != textWithoutDollars.toLowerCase();

  // Special handling for keywords - keep them lowercase for first part only
  if (isFirst && allKeywords.contains(textWithoutDollars.toLowerCase())) {
    return dollars + textWithoutDollars.toLowerCase();
  }

  String result;
  if (isFirst) {
    result = isAllCaps
        ? textWithoutDollars.toLowerCase()
        : textWithoutDollars.toCamelCase();
  } else {
    result = isAllCaps
        ? textWithoutDollars.toPascalCase()
        : textWithoutDollars.toPascalCase();
  }

  // Restore $ characters at the beginning
  return dollars + result;
}

/// Normalizes a single name to follow Dart guidelines.
String normalizeSingle(String name, {bool preserveNumbers = false}) {
  if (name.isEmpty || RegExp(r'^_+$').hasMatch(name)) {
    return '';
  }

  // Remove leading underscores
  var processedName = name.replaceAll(RegExp('^_+'), '');
  if (processedName.isEmpty) return '';

  // If it's just a number, spell it out (e.g. "600" -> "sixHundred")
  if (RegExp(r'^\d+$').hasMatch(processedName)) {
    final number = int.parse(processedName);
    final words = _numberToWords(number);
    return _normalizeText(words).toCamelCase();
  }

  processedName = _normalizeText(
    processedName,
    preserveNumbers: preserveNumbers,
  );

  // Safety net: if result starts with a digit, prefix with $
  if (processedName.isNotEmpty && RegExp(r'^\d').hasMatch(processedName)) {
    processedName = '\$$processedName';
  }

  return ensureNotKeyword(processedName);
}

/// Normalizes an enum value name, handling special cases like integers.
String normalizeEnumValueName(String value) {
  // Only spell out numbers if the entire value is just a number (no prefix)
  if (RegExp(r'^-?\d+$').hasMatch(value)) {
    final number = int.parse(value);
    final words = number < 0
        ? 'minus ${_numberToWords(number.abs())}'
        : _numberToWords(number);
    final normalized = normalizeSingle(words);
    return normalized.isEmpty ? defaultEnumPrefix : normalized.toCamelCase();
  }

  // Handle version-like strings (e.g., 1.0.2, 2.1.0, 1.0.2-beta)
  final versionMatch = RegExp(r'^(\d+(?:\.\d+)+)(.*)$').firstMatch(value);
  if (versionMatch != null) {
    final versionPart = versionMatch.group(1)!;
    final suffix = (versionMatch.group(2) ?? '').replaceFirst(RegExp('^-'), '');

    final segments = versionPart.split('.');
    final spelled = segments
        .map((s) => _numberToWords(int.parse(s)))
        .join(' dot ');

    final fullSpelled = suffix.isNotEmpty ? '$spelled $suffix' : spelled;
    final normalized = normalizeSingle(fullSpelled);

    if (normalized.isEmpty) return defaultEnumPrefix;
    if (normalized.startsWith(r'$')) return normalized;
    return normalized.toCamelCase();
  }

  // For values with prefixes (like ERROR_404), preserve numbers as-is
  final normalized = normalizeSingle(value, preserveNumbers: true);
  if (normalized.isEmpty) return defaultEnumPrefix;

  // Don't apply toCamelCase if the normalized value starts with $
  if (normalized.startsWith(r'$')) {
    return normalized;
  }

  final result = normalized.toCamelCase();

  // Safety net: if the result still starts with a digit, prefix with $
  if (RegExp(r'^\d').hasMatch(result)) {
    return '\$$result';
  }

  if (reservedEnumMemberNames.contains(result)) {
    return '\$$result';
  }

  return result;
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
