import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  group('media type parameters', () {
    test('normalizes names and charset while preserving other value case', () {
      expect(
        parseMediaTypeParameters(
          'Application/JSON; VERSION=Beta; Charset=UTF-8',
        ),
        {'version': 'Beta', 'charset': 'utf-8'},
      );
    });

    test('parses quoted parameter values and escaped quotes', () {
      expect(parseMediaTypeParameters(r'application/json; profile="a;b\"c"'), {
        'profile': 'a;b"c',
      });
    });

    test('matches a declared subset with extra parameters', () {
      expect(
        matchesMediaTypeParameters(
          'application/json; charset=utf-8; version=2',
          {'version': '2'},
        ),
        isTrue,
      );
    });

    test('matches names and charset without regard to case', () {
      expect(
        matchesMediaTypeParameters('application/json; CHARSET=UTF-8', {
          'Charset': 'utf-8',
        }),
        isTrue,
      );
    });

    test('requires other parameter values to match case', () {
      expect(
        matchesMediaTypeParameters('application/json; profile=Beta', {
          'profile': 'beta',
        }),
        isFalse,
      );
    });

    test('rejects a missing declared parameter', () {
      expect(
        matchesMediaTypeParameters('application/json; charset=utf-8', {
          'version': '2',
        }),
        isFalse,
      );
    });

    test('rejects a different parameter value', () {
      expect(
        matchesMediaTypeParameters('application/json; version=3', {
          'version': '2',
        }),
        isFalse,
      );
    });

    test('rejects missing and malformed headers', () {
      expect(matchesMediaTypeParameters(null, {'version': '2'}), isFalse);
      expect(
        matchesMediaTypeParameters('application/json; version="2', {
          'version': '2',
        }),
        isFalse,
      );
    });
  });

  group('extractMediaType', () {
    test('returns null for null header', () {
      expect(extractMediaType(null), isNull);
    });

    test('returns null for empty header', () {
      expect(extractMediaType(''), isNull);
    });

    test('returns null for whitespace-only header', () {
      expect(extractMediaType('   '), isNull);
    });

    test('returns bare media type unchanged', () {
      expect(extractMediaType('application/json'), 'application/json');
    });

    test('strips charset parameter with space after semicolon', () {
      expect(
        extractMediaType('application/json; charset=utf-8'),
        'application/json',
      );
    });

    test('strips charset parameter without space after semicolon', () {
      expect(
        extractMediaType('application/json;charset=utf-8'),
        'application/json',
      );
    });

    test('strips multiple parameters', () {
      expect(
        extractMediaType('application/json; charset=utf-8; profile="foo"'),
        'application/json',
      );
    });

    test('strips charset from vendor problem+json media type', () {
      expect(
        extractMediaType('application/problem+json; charset=utf-8'),
        'application/problem+json',
      );
    });

    test('strips version parameter from vendor +json media type', () {
      expect(
        extractMediaType('application/vnd.foo+json; version=1'),
        'application/vnd.foo+json',
      );
    });

    test('lowercases mixed-case media type', () {
      expect(extractMediaType('Application/JSON'), 'application/json');
    });

    test('trims surrounding whitespace', () {
      expect(extractMediaType('  application/json  '), 'application/json');
    });

    test('trims whitespace between type and parameter', () {
      expect(
        extractMediaType('application/json   ;   charset=utf-8'),
        'application/json',
      );
    });

    test('lowercases vendor media type with parameters', () {
      expect(
        extractMediaType('Application/Problem+JSON; Charset=UTF-8'),
        'application/problem+json',
      );
    });

    test('returns trimmed input verbatim when only a parameter is present', () {
      expect(extractMediaType(';charset=utf-8'), ';charset=utf-8');
    });

    test('returns trimmed input verbatim when value has no slash', () {
      expect(extractMediaType('garbage'), 'garbage');
    });

    test('strips parameters from no-slash input', () {
      expect(extractMediaType('garbage; foo=bar'), 'garbage');
    });
  });

  group('matchesMediaTypeRange', () {
    test('matches exact media types after normalizing parameters and case', () {
      expect(
        matchesMediaTypeRange(
          'Application/JSON; charset=utf-8',
          'application/json',
        ),
        isTrue,
      );
    });

    test('matches type wildcard media ranges', () {
      expect(
        matchesMediaTypeRange('application/json', 'application/*'),
        isTrue,
      );
      expect(
        matchesMediaTypeRange('application/problem+json', 'application/*'),
        isTrue,
      );
      expect(matchesMediaTypeRange('text/plain', 'application/*'), isFalse);
    });

    test('matches catch-all media range for concrete media types', () {
      expect(matchesMediaTypeRange('application/json', '*/*'), isTrue);
      expect(matchesMediaTypeRange('text/plain', '*/*'), isTrue);
    });

    test('does not match missing or malformed actual media types', () {
      expect(matchesMediaTypeRange(null, 'application/*'), isFalse);
      expect(matchesMediaTypeRange('garbage', 'application/*'), isFalse);
      expect(matchesMediaTypeRange('garbage', '*/*'), isFalse);
    });

    test('does not treat unsupported wildcard shapes as ranges', () {
      expect(matchesMediaTypeRange('application/json', '*/json'), isFalse);
      expect(
        matchesMediaTypeRange('application/json', 'application/j*'),
        isFalse,
      );
    });
  });
}
