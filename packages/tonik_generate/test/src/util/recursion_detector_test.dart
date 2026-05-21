import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/recursion_detector.dart';

void main() {
  late Context context;

  setUp(() {
    context = Context.initial();
  });

  group('findRecursionTarget', () {
    test('returns null for primitive types', () {
      expect(findRecursionTarget(StringModel(context: context)), isNull);
      expect(findRecursionTarget(IntegerModel(context: context)), isNull);
    });

    test('returns null for unnamed MapModel', () {
      final map = MapModel(
        valueModel: StringModel(context: context),
        context: context,
      );
      expect(findRecursionTarget(map), isNull);
    });

    test('returns null for non-recursive named MapModel', () {
      final map = MapModel(
        name: 'StringMap',
        valueModel: StringModel(context: context),
        context: context,
      );
      expect(findRecursionTarget(map), isNull);
    });

    test('detects direct self-referential MapModel', () {
      final treeSelfRef = MapModel(
        name: 'Tree',
        valueModel: AnyModel(context: context),
        context: context,
      );
      treeSelfRef.valueModel = treeSelfRef;

      expect(findRecursionTarget(treeSelfRef), same(treeSelfRef));
    });

    test('detects direct self-referential ListModel (Forest)', () {
      final forest = ListModel(
        name: 'Forest',
        content: AnyModel(context: context),
        context: context,
      );
      forest.content = forest;

      expect(findRecursionTarget(forest), same(forest));
    });

    test('detects nested recursion through List inside Map', () {
      // Tree → Map<String, List<Tree>>
      final tree = MapModel(
        name: 'Tree',
        valueModel: AnyModel(context: context),
        context: context,
      );
      tree.valueModel = ListModel(
        content: tree,
        context: context,
      );

      expect(findRecursionTarget(tree), same(tree));
    });

    test('detects indirect cycle: A ↔ B', () {
      final a = MapModel(
        name: 'A',
        valueModel: AnyModel(context: context),
        context: context,
      );
      final b = MapModel(
        name: 'B',
        valueModel: AnyModel(context: context),
        context: context,
      );
      a.valueModel = b;
      b.valueModel = a;

      expect(findRecursionTarget(a), same(a));
      expect(findRecursionTarget(b), same(b));
    });

    test('detects recursion through AliasModel chain', () {
      final tree = MapModel(
        name: 'Tree',
        valueModel: AnyModel(context: context),
        context: context,
      );
      final alias = AliasModel(
        name: 'TreeAlias',
        model: tree,
        context: context,
      );
      tree.valueModel = alias;

      expect(findRecursionTarget(tree), same(tree));
    });
  });
}
