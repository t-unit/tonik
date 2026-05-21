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

  group('reserveHelperName', () {
    test('returns the natural name when no collision exists', () {
      final tree = MapModel(
        name: 'Tree',
        valueModel: AnyModel(context: context),
        context: context,
      );
      final ctx = InlineHelperContext(nameManager: nameManager);
      expect(ctx.reserveHelperName(tree, '_decode'), '_decodeTree');
    });

    test('returns same name when called twice for the same model+prefix', () {
      final tree = MapModel(
        name: 'Tree',
        valueModel: AnyModel(context: context),
        context: context,
      );
      final ctx = InlineHelperContext(nameManager: nameManager);
      final first = ctx.reserveHelperName(tree, '_decode');
      final second = ctx.reserveHelperName(tree, '_decode');
      expect(first, second);
    });

    test('different prefixes produce distinct reservations', () {
      final tree = MapModel(
        name: 'Tree',
        valueModel: AnyModel(context: context),
        context: context,
      );
      final ctx = InlineHelperContext(nameManager: nameManager);
      final decode = ctx.reserveHelperName(tree, '_decode');
      final encode = ctx.reserveHelperName(tree, '_encode');
      expect(decode, '_decodeTree');
      expect(encode, '_encodeTree');
    });

    test('suffixes a numeric counter on collision with reserved names', () {
      final tree = MapModel(
        name: 'Tree',
        valueModel: AnyModel(context: context),
        context: context,
      );
      final ctx = InlineHelperContext(
        nameManager: nameManager,
        reservedNames: {'_decodeTree', '_decodeTree2'},
      );
      expect(ctx.reserveHelperName(tree, '_decode'), '_decodeTree3');
    });

    test('emits distinct names for two different models', () {
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
      expect(ctx.reserveHelperName(tree, '_decode'), '_decodeTree');
      expect(ctx.reserveHelperName(forest, '_decode'), '_decodeForest');
    });

    test(
      'throws StateError when suffix collisions exceed the iteration cap',
      () {
        final tree = MapModel(
          name: 'Tree',
          valueModel: AnyModel(context: context),
          context: context,
        );
        // Pre-reserve `_decodeTree` plus every numeric suffix up to and
        // including the limit, leaving no candidate for `reserveHelperName`
        // to settle on before the cap fires.
        final reserved = <String>{'_decodeTree'};
        for (var i = 2; i <= 1001; i++) {
          reserved.add('_decodeTree$i');
        }
        final ctx = InlineHelperContext(
          nameManager: nameManager,
          reservedNames: reserved,
        );
        expect(
          () => ctx.reserveHelperName(tree, '_decode'),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('Tree'),
            ),
          ),
        );
      },
    );
  });

  group('emitted state tracking', () {
    test('isHelperEmitted starts false', () {
      final tree = MapModel(
        name: 'Tree',
        valueModel: AnyModel(context: context),
        context: context,
      );
      final ctx = InlineHelperContext(nameManager: nameManager);
      expect(ctx.isHelperEmitted(tree, '_decode'), isFalse);
    });

    test('markHelperEmitted flips isHelperEmitted to true', () {
      final tree = MapModel(
        name: 'Tree',
        valueModel: AnyModel(context: context),
        context: context,
      );
      final ctx = InlineHelperContext(nameManager: nameManager)
        ..markHelperEmitted(tree, '_decode');
      expect(ctx.isHelperEmitted(tree, '_decode'), isTrue);
      expect(ctx.isHelperEmitted(tree, '_encode'), isFalse);
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
