import 'package:defs_api/defs_api.dart';
import 'package:test/test.dart';

void main() {
  test('roundtrips recursive definition aliases', () {
    const root = RecursiveRoot(next: NodeAlias(next: Node()));

    expect(root.toJson(), {
      'next': {'next': <String, Object?>{}},
    });

    final decoded = RecursiveRoot.fromJson({
      'next': {'next': <String, Object?>{}},
    });

    expect(decoded, root);
    expect(decoded.next, isA<NodeAlias>());
    expect(decoded.next?.next, const Node());
  });

  test('keeps named aliases for bare definition cycles usable', () {
    const First first = 'value';
    const Second second = 42;
    const CycleRoot root = null;

    expect(first, 'value');
    expect(second, 42);
    expect(root, isNull);
  });
}
