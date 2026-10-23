import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  test('deepObject string maps encode the declared name before brackets', () {
    final entries = {'k': 'a/b'}.toDeepObject(
      'a&b=c+d',
      explode: true,
      allowEmpty: true,
      allowReserved: true,
    );

    expect(entries, [(name: 'a%26b%3Dc%2Bd[k]', value: 'a/b')]);
    final uri = Uri(query: '${entries.single.name}=${entries.single.value}');
    expect(uri.query, 'a%26b%3Dc%2Bd%5Bk%5D=a/b');
    expect(uri.queryParameters, {'a&b=c+d[k]': 'a/b'});
  });

  test(
    'pipe-delimited string maps encode literal percent and Unicode names',
    () {
      final entries = {'k': 'v'}.toPipeDelimited('a%26b é', allowEmpty: true);

      expect(entries, [(name: 'a%2526b%20%C3%A9', value: 'k|v')]);
      final uri = Uri(query: '${entries.single.name}=${entries.single.value}');
      expect(uri.queryParameters, {'a%26b é': 'k|v'});
    },
  );

  test('space-delimited string maps encode names despite allowReserved', () {
    final entries = {'k': 'a/b'}
        .toSpaceDelimited('a&b=c+d', allowEmpty: true, allowReserved: true);

    expect(entries, [(name: 'a%26b%3Dc%2Bd', value: 'k%20a/b')]);
  });

  test('deepObject typed properties encode name and member separately', () {
    final entries = {'k&x': const PropertyValue.scalar('a/b')}.toDeepObject(
      'a&b=c+d%20',
      explode: true,
      allowEmpty: true,
      allowReserved: true,
    );

    expect(entries, [(name: 'a%26b%3Dc%2Bd%2520[k%26x]', value: 'a/b')]);
    final uri = Uri(query: '${entries.single.name}=${entries.single.value}');
    expect(uri.queryParameters, {'a&b=c+d%20[k&x]': 'a/b'});
  });

  test(
    'pipe-delimited typed properties encode names despite allowReserved',
    () {
      final entries = {'k': const PropertyValue.scalar('a/b')}
          .toPipeDelimited('a&b=c+d', allowEmpty: true, allowReserved: true);

      expect(entries, [(name: 'a%26b%3Dc%2Bd', value: 'k|a/b')]);
    },
  );

  test('space-delimited typed properties encode the declared name', () {
    final entries = {'k': const PropertyValue.scalar('v')}
        .toSpaceDelimited('a&b=c+d', allowEmpty: true);

    expect(entries, [(name: 'a%26b%3Dc%2Bd', value: 'k%20v')]);
  });

  test('dynamic pipe-delimited arrays encode names despite allowReserved', () {
    final entries = encodeAnyToPipeDelimited(
      ['a/b', 2],
      'a&b=c+d',
      allowEmpty: true,
      allowReserved: true,
    );

    expect(entries, [(name: 'a%26b%3Dc%2Bd', value: 'a/b|2')]);
  });

  test('dynamic space-delimited arrays encode literal percent in names', () {
    final entries = encodeAnyToSpaceDelimited(
      ['v', 2],
      'a&b=c+d%20',
      allowEmpty: true,
    );

    expect(entries, [(name: 'a%26b%3Dc%2Bd%2520', value: 'v%202')]);
  });
}
