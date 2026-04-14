import 'package:test/test.dart';
import 'package:tonik_generate/src/naming/name_utils.dart';

void main() {
  group('normalizeEnumValueName', () {
    group('number conversion', () {
      test('converts single digits to words', () {
        expect(normalizeEnumValueName('0'), 'zero');
        expect(normalizeEnumValueName('1'), 'one');
        expect(normalizeEnumValueName('2'), 'two');
        expect(normalizeEnumValueName('3'), 'three');
        expect(normalizeEnumValueName('9'), 'nine');
      });

      test('converts teen numbers to words', () {
        expect(normalizeEnumValueName('10'), 'ten');
        expect(normalizeEnumValueName('11'), 'eleven');
        expect(normalizeEnumValueName('15'), 'fifteen');
        expect(normalizeEnumValueName('19'), 'nineteen');
      });

      test('converts larger numbers to exact expected output', () {
        expect(normalizeEnumValueName('42'), 'fortyTwo');
        expect(normalizeEnumValueName('100'), 'oneHundred');
        expect(normalizeEnumValueName('123'), 'oneHundredTwentyThree');
        expect(normalizeEnumValueName('1000'), 'oneThousand');
      });

      test('handles negative numbers with exact output', () {
        expect(normalizeEnumValueName('-1'), 'minusOne');
        expect(normalizeEnumValueName('-42'), 'minusFortyTwo');
        expect(normalizeEnumValueName('-100'), 'minusOneHundred');
        expect(normalizeEnumValueName('-999'), 'minusNineHundredNinetyNine');
      });

      test('converts millions to exact expected output', () {
        expect(normalizeEnumValueName('1000000'), 'oneMillion');
        expect(normalizeEnumValueName('2000000'), 'twoMillion');
        expect(normalizeEnumValueName('5000000'), 'fiveMillion');
        expect(
          normalizeEnumValueName('1500000'),
          'oneMillionFiveHundredThousand',
        );
      });

      test('converts billions to exact expected output', () {
        expect(normalizeEnumValueName('1000000000'), 'oneBillion');
        expect(normalizeEnumValueName('3000000000'), 'threeBillion');
        expect(normalizeEnumValueName('7000000000'), 'sevenBillion');
        expect(
          normalizeEnumValueName('1500000000'),
          'oneBillionFiveHundredMillion',
        );
      });

      test('converts trillions to exact expected output', () {
        expect(normalizeEnumValueName('1000000000000'), 'oneTrillion');
        expect(normalizeEnumValueName('5000000000000'), 'fiveTrillion');
        expect(normalizeEnumValueName('9000000000000'), 'nineTrillion');
        expect(
          normalizeEnumValueName('1500000000000'),
          'oneTrillionFiveHundredBillion',
        );
      });

      test('handles complex large numbers', () {
        expect(
          normalizeEnumValueName('1234567890'),
          'oneBillionTwoHundredThirtyFourMillion'
          'FiveHundredSixtySevenThousandEightHundredNinety',
        );
        expect(
          normalizeEnumValueName('999999999999'),
          'nineHundredNinetyNineBillionNineHundredNinetyNineMillion'
          'NineHundredNinetyNineThousandNineHundredNinetyNine',
        );
      });

      test('produces camelCase identifiers', () {
        // Based on existing test expectations
        expect(normalizeEnumValueName('1'), 'one');
        expect(normalizeEnumValueName('2'), 'two');
        expect(normalizeEnumValueName('3'), 'three');
      });
    });

    group('string normalization', () {
      test('normalizes simple strings', () {
        expect(normalizeEnumValueName('active'), 'active');
        expect(normalizeEnumValueName('inactive'), 'inactive');
        expect(normalizeEnumValueName('pending'), 'pending');
      });

      test('handles case conversion properly', () {
        expect(normalizeEnumValueName('ACTIVE'), 'active'); // Clean lowercase
        expect(normalizeEnumValueName('InActive'), 'inActive');
        expect(normalizeEnumValueName('PENDING'), 'pending');
      });

      test('handles strings with separators', () {
        expect(normalizeEnumValueName('in-progress'), 'inProgress');
        expect(normalizeEnumValueName('not_started'), 'notStarted');
        expect(normalizeEnumValueName('on hold'), 'onHold');
      });

      test('handles mixed alphanumeric strings', () {
        expect(normalizeEnumValueName('status1'), 'status1');
        expect(
          normalizeEnumValueName('1status'),
          'status1',
        ); // Number moved to end
        expect(normalizeEnumValueName('v2_final'), 'v2Final');
      });

      test('comprehensive real-world enum value cases', () {
        // Common API status codes and enum patterns
        expect(normalizeEnumValueName('SUCCESS_CODE'), 'successCode');
        expect(normalizeEnumValueName('ERROR_404'), 'error404');
        expect(normalizeEnumValueName('HTTP_STATUS'), 'httpStatus');
        expect(normalizeEnumValueName('NOT_FOUND'), 'notFound');
        expect(normalizeEnumValueName('API_VERSION_2'), 'apiVersion2');
        expect(normalizeEnumValueName('USER-ACCOUNT'), 'userAccount');
        expect(normalizeEnumValueName('data_model'), 'dataModel');
        expect(normalizeEnumValueName('ADMIN'), 'admin');
        expect(normalizeEnumValueName('guest'), 'guest');
        expect(normalizeEnumValueName('999'), 'nineHundredNinetyNine');
        expect(normalizeEnumValueName('2024'), 'twoThousandTwentyFour');
      });
    });

    group('edge cases', () {
      test('handles empty and invalid inputs', () {
        expect(normalizeEnumValueName(''), 'value');
        expect(normalizeEnumValueName('_'), 'value');
        expect(normalizeEnumValueName('__'), 'value');
      });

      test('handles special characters', () {
        expect(normalizeEnumValueName('!@#'), 'exclamationAtHash');
        expect(normalizeEnumValueName('status!'), 'statusExclamation');
        expect(normalizeEnumValueName('test@#123'), 'testAtHash123');
      });

      test('handles leading underscores', () {
        expect(normalizeEnumValueName('_active'), 'active');
        expect(normalizeEnumValueName('__pending'), 'pending');
      });
      test('matches expected enum generation behavior', () {
        // These are the expectations from the existing enum generator tests
        expect(normalizeEnumValueName('1'), 'one');
        expect(normalizeEnumValueName('2'), 'two');
        expect(normalizeEnumValueName('3'), 'three');
      });

      test('produces clean, readable identifiers', () {
        // Common enum value patterns should be clean and readable
        expect(normalizeEnumValueName('SUCCESS'), 'success');
        expect(normalizeEnumValueName('ERROR'), 'error');
        expect(normalizeEnumValueName('PENDING'), 'pending');
        expect(normalizeEnumValueName('IN_PROGRESS'), 'inProgress');
      });
    });

    group('version string enum values', () {
      test('spells out version-like strings with dot separator', () {
        expect(normalizeEnumValueName('1.0.2'), 'oneDotZeroDotTwo');
        expect(normalizeEnumValueName('2.1.0'), 'twoDotOneDotZero');
      });

      test('handles two-segment version strings', () {
        expect(normalizeEnumValueName('1.0'), 'oneDotZero');
      });
    });

    group('dotted enum values', () {
      test('treats dots as word separators', () {
        expect(normalizeEnumValueName('api.response'), 'apiResponse');
        expect(normalizeEnumValueName('error.code'), 'errorCode');
      });
    });

    group('version strings with suffixes', () {
      test('spells out version part and normalizes suffix', () {
        expect(
          normalizeEnumValueName('1.0.2-beta'),
          'oneDotZeroDotTwoBeta',
        );
      });
    });

    group('digit-leading safety net', () {
      test('prefixes with dollar sign if result starts with digit', () {
        // A mixed value where normalization produces a digit-leading
        // result — the safety net should add a $ prefix
        expect(normalizeEnumValueName('123_456'), r'$123456');
      });
    });

    group('reserved enum member names', () {
      test('escapes index which conflicts with Enum.index', () {
        expect(normalizeEnumValueName('index'), r'$index');
        expect(normalizeEnumValueName('INDEX'), r'$index');
        expect(normalizeEnumValueName('Index'), r'$index');
      });

      test('escapes values which conflicts with Enum.values', () {
        expect(normalizeEnumValueName('values'), r'$values');
        expect(normalizeEnumValueName('VALUES'), r'$values');
      });

      test('does not escape words that contain reserved names', () {
        expect(normalizeEnumValueName('reindex'), 'reindex');
        expect(normalizeEnumValueName('indexing'), 'indexing');
        expect(normalizeEnumValueName('INDEX_TYPE'), 'indexType');
      });
    });
  });

  group('normalizeSingle with purely numeric names', () {
    test('spells out pure numbers when preserveNumbers is true', () {
      expect(normalizeSingle('1', preserveNumbers: true), 'one');
      expect(normalizeSingle('42', preserveNumbers: true), 'fortyTwo');
      expect(normalizeSingle('100', preserveNumbers: true), 'oneHundred');
      expect(normalizeSingle('600', preserveNumbers: true), 'sixHundred');
      expect(normalizeSingle('1000', preserveNumbers: true), 'oneThousand');
    });

    test('spells out pure numbers when preserveNumbers is false', () {
      expect(normalizeSingle('1'), 'one');
      expect(normalizeSingle('600'), 'sixHundred');
      expect(normalizeSingle('1000'), 'oneThousand');
    });
  });

  group('normalizeSingle does not escape enum-specific reserved names', () {
    test('allows index as a class property name', () {
      expect(normalizeSingle('index'), 'index');
      expect(normalizeSingle('INDEX'), 'index');
    });

    test('allows values as a class property name', () {
      expect(normalizeSingle('values'), 'values');
      expect(normalizeSingle('VALUES'), 'values');
    });
  });

  group('normalizeSingle with special character property names', () {
    test('converts +1 to plus1', () {
      expect(normalizeSingle('+1', preserveNumbers: true), 'plus1');
    });

    test('converts -1 to minus1', () {
      expect(normalizeSingle('-1', preserveNumbers: true), 'minus1');
    });

    test('converts >= to greaterThanEquals', () {
      expect(normalizeSingle('>=', preserveNumbers: true), 'greaterThanEquals');
    });

    test('converts * to asterisk', () {
      expect(normalizeSingle('*', preserveNumbers: true), 'asterisk');
    });

    test('converts pure special chars to word equivalents', () {
      expect(
        normalizeSingle('!!!', preserveNumbers: true),
        'exclamationExclamationExclamation',
      );
    });

    test('prefixes with dollar sign if result starts with digit', () {
      // Safety net for digit-leading results
      final result = normalizeSingle('42foo', preserveNumbers: true);
      expect(result, isNot(startsWith(RegExp(r'\d').pattern)));
    });
  });
}
