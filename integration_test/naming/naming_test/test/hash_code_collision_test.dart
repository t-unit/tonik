import 'package:naming_api/naming_api.dart'
    show
        CollectionHashCollision,
        ScalarHashCollision,
        SingleCollectionHashCollision;
import 'package:test/test.dart';

void main() {
  test('single collection named deepEquals contributes to hashCode', () {
    final first = SingleCollectionHashCollision(
      deepEquals: List<int>.of(const [1, 2]),
    );
    final equal = SingleCollectionHashCollision(
      deepEquals: List<int>.of(const [1, 2]),
    );
    final different = SingleCollectionHashCollision(
      deepEquals: List<int>.of(const [3, 4]),
    );

    expect(first, equal);
    expect(first.hashCode, equal.hashCode);
    expect(first, isNot(different));
    expect(first.hashCode, isNot(different.hashCode));
    expect(first.deepEquals, [1, 2]);
    expect(first.toJson(), {
      'deepEquals': [1, 2],
    });
    expect(
      SingleCollectionHashCollision.fromJson(const {
        'deepEquals': [1, 2],
      }),
      first,
    );
  });

  test('scalar named deepEquals contributes alongside a collection', () {
    final first = ScalarHashCollision(
      deepEquals: 1,
      items: List<int>.of(const [10, 20]),
    );
    final equal = ScalarHashCollision(
      deepEquals: 1,
      items: List<int>.of(const [10, 20]),
    );
    final different = ScalarHashCollision(
      deepEquals: 2,
      items: List<int>.of(const [10, 20]),
    );

    expect(first, equal);
    expect(first.hashCode, equal.hashCode);
    expect(first, isNot(different));
    expect(first.hashCode, isNot(different.hashCode));
    expect(first.deepEquals, 1);
    expect(first.toJson(), {
      'deepEquals': 1,
      'items': [10, 20],
    });
    expect(
      ScalarHashCollision.fromJson(const {
        'deepEquals': 1,
        'items': [10, 20],
      }),
      first,
    );
  });

  test('collection named deepEquals contributes alongside a scalar', () {
    final first = CollectionHashCollision(
      deepEquals: List<int>.of(const [1, 2]),
      name: 'same',
    );
    final equal = CollectionHashCollision(
      deepEquals: List<int>.of(const [1, 2]),
      name: 'same',
    );
    final different = CollectionHashCollision(
      deepEquals: List<int>.of(const [3, 4]),
      name: 'same',
    );

    expect(first, equal);
    expect(first.hashCode, equal.hashCode);
    expect(first, isNot(different));
    expect(first.hashCode, isNot(different.hashCode));
    expect(first.deepEquals, [1, 2]);
    expect(first.toJson(), {
      'deepEquals': [1, 2],
      'name': 'same',
    });
    expect(
      CollectionHashCollision.fromJson(const {
        'deepEquals': [1, 2],
        'name': 'same',
      }),
      first,
    );
  });
}
