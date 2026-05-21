import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/util/inline_helper_context.dart';

void main() {
  late Context context;
  late NameManager nameManager;

  setUp(() {
    context = Context.initial();
    nameManager = NameManager(
      generator: NameGenerator(),
      stableModelSorter: StableModelSorter(),
    );
  });

  group('helperName', () {
    test('returns prefix + modelName', () {
      final tree = MapModel(
        name: 'Tree',
        valueModel: AnyModel(context: context),
        context: context,
      );
      final ctx = InlineHelperContext(nameManager: nameManager);
      expect(ctx.helperName(tree, r'_$decode'), r'_$decodeTree');
      expect(ctx.helperName(tree, r'_$encode'), r'_$encodeTree');
    });

    test('different models produce distinct names', () {
      final tree = MapModel(
        name: 'Tree',
        valueModel: AnyModel(context: context),
        context: context,
      );
      final forest = ListModel(
        name: 'Forest',
        content: AnyModel(context: context),
        context: context,
      );
      final ctx = InlineHelperContext(nameManager: nameManager);
      expect(ctx.helperName(tree, r'_$decode'), r'_$decodeTree');
      expect(ctx.helperName(forest, r'_$decode'), r'_$decodeForest');
    });
  });

  group('emitted state tracking', () {
    test('isHelperEmitted starts false', () {
      final tree = MapModel(
        name: 'Tree',
        valueModel: AnyModel(context: context),
        context: context,
      );
      final ctx = InlineHelperContext(nameManager: nameManager);
      expect(ctx.isHelperEmitted(tree, r'_$decode'), isFalse);
    });

    test('markHelperEmitted flips isHelperEmitted to true', () {
      final tree = MapModel(
        name: 'Tree',
        valueModel: AnyModel(context: context),
        context: context,
      );
      final ctx = InlineHelperContext(nameManager: nameManager)
        ..markHelperEmitted(tree, r'_$decode');
      expect(ctx.isHelperEmitted(tree, r'_$decode'), isTrue);
      expect(ctx.isHelperEmitted(tree, r'_$encode'), isFalse);
    });
  });

  group('recursion stack', () {
    test('isOnStack is false by default', () {
      final tree = MapModel(
        name: 'Tree',
        valueModel: AnyModel(context: context),
        context: context,
      );
      final ctx = InlineHelperContext(nameManager: nameManager);
      expect(ctx.isOnStack(tree), isFalse);
    });

    test('withRecursion makes the model visible to isOnStack', () {
      final tree = MapModel(
        name: 'Tree',
        valueModel: AnyModel(context: context),
        context: context,
      );
      final ctx = InlineHelperContext(nameManager: nameManager);

      var wasOnStack = false;
      ctx.withRecursion(tree, () {
        wasOnStack = ctx.isOnStack(tree);
      });

      expect(wasOnStack, isTrue);
      expect(ctx.isOnStack(tree), isFalse);
    });

    test('withRecursion supports nested entries', () {
      final tree = MapModel(
        name: 'Tree',
        valueModel: AnyModel(context: context),
        context: context,
      );
      final forest = ListModel(
        name: 'Forest',
        content: AnyModel(context: context),
        context: context,
      );
      final ctx = InlineHelperContext(nameManager: nameManager);

      ctx.withRecursion(tree, () {
        ctx.withRecursion(forest, () {
          expect(ctx.isOnStack(tree), isTrue);
          expect(ctx.isOnStack(forest), isTrue);
        });
        expect(ctx.isOnStack(tree), isTrue);
        expect(ctx.isOnStack(forest), isFalse);
      });
      expect(ctx.isOnStack(tree), isFalse);
    });
  });
}
