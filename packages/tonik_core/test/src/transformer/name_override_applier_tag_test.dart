import 'package:test/test.dart';
import 'package:tonik_core/src/transformer/name_override_applier.dart';
import 'package:tonik_core/tonik_core.dart';

void main() {
  final applier = NameOverrideApplier();

  group('Multiple tags', () {
    test('isolated overrides', () {
      final tagA = Tag(name: 'pet', description: 'Pet tag');
      final tagB = Tag(
        name: 'color',
        description: 'Color tag',
      );

      applier.applyTagOverrides(
        {tagA, tagB},
        {
          'pet': 'animal',
          'color': 'hue',
        },
      );
      expect(tagA.nameOverride, 'animal');
      expect(tagB.nameOverride, 'hue');
    });

    test('multiple tags', () {
      final tagA = Tag(name: 'pet', description: 'Pet tag');
      final tagB = Tag(
        name: 'color',
        description: 'Color tag',
      );
      final tagC = Tag(
        name: 'size',
        description: 'Size tag',
      );

      applier.applyTagOverrides(
        {tagA, tagB, tagC},
        {
          'pet': 'animal',
          'color': 'hue',
        },
      );
      expect(tagA.nameOverride, 'animal');
      expect(tagB.nameOverride, 'hue');
      expect(tagC.nameOverride, isNull);
    });
  });

  group('Single tag', () {
    test('object is not replaced, only nameOverride is set', () {
      final tag = Tag(name: 'pet', description: 'Pet tag');

      applier.applyTagOverrides({tag}, {'pet': 'animal'});
      expect(tag.nameOverride, 'animal');
    });

    test('untouched tags remain unchanged', () {
      final tagA = Tag(name: 'pet', description: 'Pet tag');
      final tagB = Tag(
        name: 'color',
        description: 'Color tag',
      );

      applier.applyTagOverrides({tagA, tagB}, {'pet': 'animal'});
      expect(tagA.nameOverride, 'animal');
      expect(tagB.nameOverride, isNull);
    });

    test('wrong data (nonexistent tag)', () {
      final tagA = Tag(name: 'pet', description: 'Pet tag');
      final tagB = Tag(
        name: 'color',
        description: 'Color tag',
      );

      applier.applyTagOverrides(
        {tagA, tagB},
        {'size': 'dimension'},
      ); // 'size' does not exist
      expect(tagA.nameOverride, isNull);
      expect(tagB.nameOverride, isNull);
    });

    test('preserves existing nameOverride if not overridden', () {
      final tagA = Tag(name: 'pet', description: 'Pet tag');
      final tagB = Tag(
        name: 'color',
        nameOverride: 'hue',
        description: 'Color tag',
      );

      applier.applyTagOverrides({tagA, tagB}, {'pet': 'animal'});
      expect(tagA.nameOverride, 'animal');
      expect(
        tagB.nameOverride,
        'hue',
        reason: 'Existing nameOverride should be preserved if not overridden',
      );
    });

    test('CLI override takes precedence over existing nameOverride', () {
      final tagA = Tag(
        name: 'pet',
        nameOverride: 'creature',
        description: 'Pet tag',
      );

      applier.applyTagOverrides({tagA}, {'pet': 'animal'});
      expect(
        tagA.nameOverride,
        'animal',
        reason:
            'CLI override should take precedence over existing nameOverride',
      );
    });
  });
}
