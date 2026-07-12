import 'package:big_decimal/big_decimal.dart';
import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

class _TestEncodable implements JsonEncodable {
  const _TestEncodable(this.name);

  final String name;

  @override
  Object? toJson() => {'name': name};
}

Matcher _throwsEncodingExceptionMentioning(String fragment) => throwsA(
  isA<EncodingException>().having(
    (e) => e.message,
    'message',
    contains(fragment),
  ),
);

void main() {
  group('encodeUnknownJson', () {
    test('passes through JSON primitives', () {
      expect(encodeUnknownJson(null, context: 'v'), isNull);
      expect(encodeUnknownJson('hello', context: 'v'), 'hello');
      expect(encodeUnknownJson(42, context: 'v'), 42);
      expect(encodeUnknownJson(3.14, context: 'v'), 3.14);
      expect(encodeUnknownJson(true, context: 'v'), isTrue);
    });

    test('converts DateTime to ISO 8601', () {
      expect(
        encodeUnknownJson(DateTime.utc(2024, 1, 15, 10, 30), context: 'v'),
        '2024-01-15T10:30:00.000Z',
      );
    });

    test('invokes toJson on JsonEncodable values', () {
      expect(
        encodeUnknownJson(const _TestEncodable('a'), context: 'v'),
        {'name': 'a'},
      );
    });

    test('recursively encodes maps and lists', () {
      expect(
        encodeUnknownJson({
          'items': [
            1,
            const _TestEncodable('a'),
            DateTime.utc(2024, 1, 15, 10, 30),
          ],
          'meta': {'level': 1},
        }, context: 'v'),
        {
          'items': [
            1,
            {'name': 'a'},
            '2024-01-15T10:30:00.000Z',
          ],
          'meta': {'level': 1},
        },
      );
    });

    test('throws for non-string map keys naming the map location', () {
      expect(
        () => encodeUnknownJson({
          'outer': {1: 'a'},
        }, context: 'body'),
        _throwsEncodingExceptionMentioning('body.outer'),
      );
    });

    test('throws for unsupported values naming the nested key path', () {
      expect(
        () => encodeUnknownJson({
          'meta': {'inner': Object()},
        }, context: 'body'),
        _throwsEncodingExceptionMentioning('body.meta.inner'),
      );
    });

    test('throws for unsupported values naming the list index path', () {
      expect(
        () => encodeUnknownJson({
          'items': [1, Object()],
        }, context: 'body'),
        _throwsEncodingExceptionMentioning('body.items[1]'),
      );
    });

    test('throws for unsupported top-level values naming the context', () {
      expect(
        () => encodeUnknownJson(Object(), context: 'body'),
        _throwsEncodingExceptionMentioning('body'),
      );
    });
  });

  group('encodeUnknownFlatScalar', () {
    test('converts supported scalar runtime types', () {
      expect(encodeUnknownFlatScalar('hi', context: 'v'), 'hi');
      expect(encodeUnknownFlatScalar('', context: 'v'), '');
      expect(encodeUnknownFlatScalar(42, context: 'v'), '42');
      expect(encodeUnknownFlatScalar(3.14, context: 'v'), '3.14');
      expect(encodeUnknownFlatScalar(true, context: 'v'), 'true');
      expect(encodeUnknownFlatScalar(false, context: 'v'), 'false');
    });

    test('converts DateTime to ISO 8601', () {
      expect(
        encodeUnknownFlatScalar(
          DateTime.utc(2024, 1, 15, 10, 30),
          context: 'v',
        ),
        '2024-01-15T10:30:00.000Z',
      );
    });

    test('converts Date', () {
      expect(
        encodeUnknownFlatScalar(Date(2024, 1, 15), context: 'v'),
        '2024-01-15',
      );
    });

    test('converts Uri', () {
      expect(
        encodeUnknownFlatScalar(
          Uri.parse('https://example.com/a b'),
          context: 'v',
        ),
        'https://example.com/a%20b',
      );
    });

    test('converts BigDecimal', () {
      expect(
        encodeUnknownFlatScalar(BigDecimal.parse('1.50'), context: 'v'),
        '1.50',
      );
    });

    test('throws for lists naming the context', () {
      expect(
        () => encodeUnknownFlatScalar([1, 2], context: 'body.tags'),
        _throwsEncodingExceptionMentioning('body.tags'),
      );
    });

    test('throws for maps naming the context', () {
      expect(
        () => encodeUnknownFlatScalar({'a': 1}, context: 'body.meta'),
        _throwsEncodingExceptionMentioning('body.meta'),
      );
    });

    test('throws for generated values naming the context', () {
      expect(
        () => encodeUnknownFlatScalar(
          const _TestEncodable('a'),
          context: 'body.obj',
        ),
        _throwsEncodingExceptionMentioning('body.obj'),
      );
    });

    test('throws for custom objects naming the context', () {
      expect(
        () => encodeUnknownFlatScalar(Object(), context: 'body.obj'),
        _throwsEncodingExceptionMentioning('body.obj'),
      );
    });
  });
}
