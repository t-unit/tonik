import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:immutable_collections_api/immutable_collections_api.dart';
import 'package:test/test.dart';

void main() {
  test('immutable list response wrappers retain value equality', () {
    final first = GetCollectionBodiesResponse200(body: IList(const ['a']));
    final second = GetCollectionBodiesResponse200(body: IList(const ['a']));
    final different = GetCollectionBodiesResponse200(body: IList(const ['b']));

    expect(first == second, isTrue);
    expect(first.hashCode, second.hashCode);
    expect(first == different, isFalse);
    expect({first, second, different}.length, 2);
  });

  test('immutable map response wrappers retain nested value equality', () {
    final first = GetCollectionBodiesResponse201(
      body: IMap({
        'letters': IList(const ['a']),
      }),
    );
    final second = GetCollectionBodiesResponse201(
      body: IMap({
        'letters': IList(const ['a']),
      }),
    );
    final different = GetCollectionBodiesResponse201(
      body: IMap({
        'letters': IList(const ['b']),
      }),
    );

    expect(first == second, isTrue);
    expect(first.hashCode, second.hashCode);
    expect(first == different, isFalse);
    expect({first, second, different}.length, 2);
  });
}
