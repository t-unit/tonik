import 'package:test/test.dart';
import 'package:tonik_parse/src/local_json_pointer.dart';

void main() {
  test('decodes the URI fragment before splitting pointer tokens', () {
    final pointer = LocalJsonPointer.parse('#%2Fvalues%2Fa~1b');

    expect(pointer.tokens, ['values', 'a/b']);
    expect(
      pointer.resolve({
        'values': {'a/b': 42},
      }),
      42,
    );
  });

  test('unescapes slash before tilde and preserves empty tokens', () {
    final pointer = LocalJsonPointer.parse('#/values/~01/');

    expect(pointer.tokens, ['values', '~1', '']);
    expect(
      pointer.resolve({
        'values': {
          '~1': {'': 'found'},
        },
      }),
      'found',
    );
  });

  test('preserves encoded percent signs and plus signs in tokens', () {
    final pointer = LocalJsonPointer.parse('#/values/%252F+a');

    expect(pointer.tokens, ['values', '%2F+a']);
    expect(
      pointer.resolve({
        'values': {'%2F+a': true},
      }),
      isTrue,
    );
    expect(LocalJsonPointer.parse(pointer.reference).tokens, [
      'values',
      '%2F+a',
    ]);
  });

  test('canonicalizes equivalent pointer encodings', () {
    final encoded = LocalJsonPointer.parse('#%2Fpaths%2F~1pets');
    final plain = LocalJsonPointer.parse('#/paths/~1pets');

    expect(encoded.reference, plain.reference);
  });

  test('resolves array indices and the empty root pointer', () {
    final pointer = LocalJsonPointer.parse('#/values/1');

    expect(
      pointer.resolve({
        'values': ['first', 'second'],
      }),
      'second',
    );
    expect(LocalJsonPointer.parse('#').tokens, isEmpty);
    expect(LocalJsonPointer.parse('#').resolve({'value': 1}), {'value': 1});
  });

  test('rejects invalid array indices and missing targets', () {
    expect(
      () => LocalJsonPointer.parse('#/values/01').resolve({
        'values': [1, 2],
      }),
      throwsArgumentError,
    );
    expect(
      () => LocalJsonPointer.parse('#/values/-').resolve({
        'values': [1, 2],
      }),
      throwsArgumentError,
    );
    expect(
      () => LocalJsonPointer.parse('#/values/2').resolve({
        'values': [1, 2],
      }),
      throwsArgumentError,
    );
    expect(
      () => LocalJsonPointer.parse('#/missing').resolve({'value': 1}),
      throwsArgumentError,
    );
  });

  test(
    'rejects malformed escapes and preserves unsupported reference policy',
    () {
      expect(
        () => LocalJsonPointer.parse('#/bad~2escape'),
        throwsFormatException,
      );
      expect(() => LocalJsonPointer.parse('#/bad~'), throwsFormatException);
      expect(() => LocalJsonPointer.parse('#/bad%'), throwsArgumentError);
      expect(
        () => LocalJsonPointer.parse('other.yaml#/value'),
        throwsA(isA<UnimplementedError>()),
      );
      expect(
        () => LocalJsonPointer.parse('#anchor'),
        throwsA(isA<UnimplementedError>()),
      );
    },
  );

  test(
    'accepts only exact component pointers for component-only resolvers',
    () {
      expect(
        LocalJsonPointer.parse('#%2Fcomponents%2Fparameters%2FSort')
            .componentName('parameters'),
        'Sort',
      );
      expect(
        LocalJsonPointer.parse('#/components/parameters/Owner/value/Sort')
            .componentName('parameters'),
        isNull,
      );
    },
  );
}
