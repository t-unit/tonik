import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
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
}
