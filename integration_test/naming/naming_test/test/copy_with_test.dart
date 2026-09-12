import 'package:naming_api/naming_api.dart';
import 'package:test/test.dart';

void main() {
  test('response copyWith distinguishes the body from a normalized header', () {
    const original = ResponseBodyCollisionHeaderNormalizedGet200Response(
      body: 'header',
      body2: SimpleResult(id: 'body'),
    );

    final headerCopy = original.copyWith(body: 'updated-header');
    final bodyCopy = original.copyWith.call(
      body2: const SimpleResult(id: 'updated-body'),
    );

    expect(headerCopy.body, 'updated-header');
    expect(headerCopy.body2, const SimpleResult(id: 'body'));
    expect(bodyCopy.body, 'header');
    expect(bodyCopy.body2, const SimpleResult(id: 'updated-body'));
    expect(original.body, 'header');
    expect(original.body2, const SimpleResult(id: 'body'));
  });

  test(
    'response copyWith preserves nonnullable headers and bodies on null',
    () {
      const original = ResponseBodyCollisionHeaderNormalizedGet200Response(
        body: 'header',
        body2: SimpleResult(id: 'body'),
      );

      final copy = original.copyWith(body: null, body2: null);

      expect(copy.body, 'header');
      expect(copy.body2, const SimpleResult(id: 'body'));
      expect(copy, isNot(same(original)));
    },
  );

  test('copyWith preserves required values while clearing nullable values', () {
    const original = SimpleResult(id: 'body', message: 'message');

    final copy = original.copyWith(id: null, message: null);

    expect(copy.id, 'body');
    expect(copy.message, isNull);
    expect(original.message, 'message');
  });
}
