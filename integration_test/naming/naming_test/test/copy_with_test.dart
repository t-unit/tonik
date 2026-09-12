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
}
