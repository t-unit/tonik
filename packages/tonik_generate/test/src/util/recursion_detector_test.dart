import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/recursion_detector.dart';

void main() {
  late Context context;

  setUp(() {
    context = Context.initial();
  });

  group('isRecursive', () {
    test('returns false for primitive types', () {
      expect(isRecursive(StringModel(context: context)), isFalse);
      expect(isRecursive(IntegerModel(context: context)), isFalse);
    });

    test('returns false for unnamed MapModel', () {
      final map = MapModel(
        valueModel: StringModel(context: context),
        context: context,
      );
      expect(isRecursive(map), isFalse);
    });

    test('returns false for non-recursive named MapModel', () {
      final map = MapModel(
        name: 'StringMap',
        valueModel: StringModel(context: context),
        context: context,
      );
      expect(isRecursive(map), isFalse);
    });

    test('detects direct self-referential MapModel', () {
      final treeSelfRef = MapModel(
        name: 'Tree',
        valueModel: AnyModel(context: context),
        context: context,
      );
      treeSelfRef.valueModel = treeSelfRef;

      expect(isRecursive(treeSelfRef), isTrue);
    });

    test('detects direct self-referential ListModel (Forest)', () {
      final forest = ListModel(
        name: 'Forest',
        content: AnyModel(context: context),
        context: context,
      );
      forest.content = forest;

      expect(isRecursive(forest), isTrue);
    });

    test('detects nested recursion through List inside Map', () {
      final tree = MapModel(
        name: 'Tree',
        valueModel: AnyModel(context: context),
        context: context,
      );
      tree.valueModel = ListModel(
        content: tree,
        context: context,
      );

      expect(isRecursive(tree), isTrue);
    });

    test('detects indirect cycle: A <-> B', () {
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

      expect(isRecursive(a), isTrue);
      expect(isRecursive(b), isTrue);
    });

    test('detects three-way indirect cycle: A -> B -> C -> A', () {
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
      final c = MapModel(
        name: 'C',
        valueModel: AnyModel(context: context),
        context: context,
      );
      a.valueModel = b;
      b.valueModel = c;
      c.valueModel = a;

      expect(isRecursive(a), isTrue);
      expect(isRecursive(b), isTrue);
      expect(isRecursive(c), isTrue);
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

      expect(isRecursive(tree), isTrue);
    });
  });
}
