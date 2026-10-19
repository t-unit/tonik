import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  test('exploded map style uses literal names and text values', () {
    final parts = multipartMapStyleParts(
      {'topic': 'a/b', 'note': 'x y'},
      'metadata',
      explode: true,
      deepObject: false,
    );

    expect(parts, [
      (name: 'topic', value: 'a/b'),
      (name: 'note', value: 'x y'),
    ]);
  });

  test('collapsed map style sends one literal value', () {
    final parts = multipartMapStyleParts(
      {'topic': 'a/b', 'note': 'x y'},
      'metadata',
      explode: false,
      deepObject: false,
    );

    expect(parts, [(name: 'metadata', value: 'topic,a/b,note,x y')]);
  });

  test('typed array map values retain raw element boundaries', () {
    final parts = multipartMapStyleParts(
      {
        'tags': ['a/b', 'x y'],
      },
      'metadata',
      explode: false,
      deepObject: false,
      encodeValue: (value) => PropertyValue.array(value as List<String>),
    );

    expect(parts, [(name: 'metadata', value: 'tags,a/b,x y')]);
  });

  test('map style rejects a complex value before a part is appended', () {
    expect(
      () => multipartMapStyleParts(
        {
          'nested': ['a', 'b'],
        },
        'metadata',
        explode: true,
        deepObject: false,
      ),
      throwsA(isA<EncodingException>()),
    );
  });
}
