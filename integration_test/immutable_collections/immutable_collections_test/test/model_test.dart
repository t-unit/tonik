import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:immutable_collections_api/immutable_collections_api.dart';
import 'package:test/test.dart';

void main() {
  // -------------------------------------------------------------------
  // 1. Type checks — verify generated fields use IList / IMap
  // -------------------------------------------------------------------

  group('Item type checks', () {
    test('tags field is IList<String>', () {
      final item = Item(
        id: 1,
        name: 'Widget',
        tags: <String>['a', 'b'].lock,
        children: <ChildModel>[].lock,
        metadata: <String, String>{}.lock,
      );
      expect(item.tags, isA<IList<String>>());
      expect(item.tags.length, 2);
    });

    test('children field is IList<ChildModel>', () {
      final item = Item(
        id: 1,
        name: 'Widget',
        tags: <String>[].lock,
        children: <ChildModel>[
          const ChildModel(childName: 'bolt', value: 10),
        ].lock,
        metadata: <String, String>{}.lock,
      );
      expect(item.children, isA<IList<ChildModel>>());
      expect(item.children.length, 1);
      expect(item.children[0].childName, 'bolt');
    });

    test('metadata field is IMap<String, String>', () {
      final item = Item(
        id: 1,
        name: 'Widget',
        tags: <String>[].lock,
        children: <ChildModel>[].lock,
        metadata: IMap(const {'color': 'red', 'size': 'large'}),
      );
      expect(item.metadata, isA<IMap<String, String>>());
      expect(item.metadata['color'], 'red');
    });
  });

  group('NestedList type checks', () {
    test('matrix field is IList<IList<String>>', () {
      final model = NestedList(
        matrix: <IList<String>>[
          <String>['a', 'b'].lock,
          <String>['c', 'd'].lock,
        ].lock,
      );
      expect(model.matrix, isA<IList<IList<String>>>());
      expect(model.matrix[0], isA<IList<String>>());
      expect(model.matrix[0][0], 'a');
    });
  });

  group('TagGroups type check', () {
    test('is IMap<String, IList<String>>', () {
      final groups = IMap(<String, IList<String>>{
        'colors': <String>['red', 'blue'].lock,
      });
      expect(groups, isA<TagGroups>());
    });
  });

  group('StringMetadata type check', () {
    test('is IMap<String, String>', () {
      final meta = IMap(const <String, String>{'key': 'value'});
      expect(meta, isA<StringMetadata>());
    });
  });

  // -------------------------------------------------------------------
  // 1b. allOf with MapModel component — field types
  // -------------------------------------------------------------------

  group('Combined (allOf with MapModel) type checks', () {
    test('extraData field is ExtraData (IMap<String, String>)', () {
      final combined = Combined(
        extraData: IMap(const {'key': 'value'}),
        combinedModel: const CombinedModel(name: 'test'),
      );
      expect(combined.extraData, isA<IMap<String, String>>());
      expect(combined.extraData['key'], 'value');
    });
  });

  // -------------------------------------------------------------------
  // 2. Serialization round-trips — toJson → fromJson preserves types
  // -------------------------------------------------------------------

  group('Item serialization', () {
    test('toJson produces regular List/Map, fromJson restores IList/IMap', () {
      final original = Item(
        id: 42,
        name: 'Widget',
        tags: <String>['cool', 'useful'].lock,
        children: <ChildModel>[
          const ChildModel(childName: 'bolt', value: 10),
        ].lock,
        metadata: IMap(const {'color': 'red'}),
      );

      final json = original.toJson();
      expect(json, isA<Map<String, dynamic>>());

      // The JSON output should contain regular Dart lists/maps
      final jsonMap = json! as Map<String, dynamic>;
      expect(jsonMap['tags'], isA<List<dynamic>>());
      expect(jsonMap['metadata'], isA<Map<dynamic, dynamic>>());

      final restored = Item.fromJson(json);
      expect(restored.id, 42);
      expect(restored.name, 'Widget');
      expect(restored.tags, isA<IList<String>>());
      expect(restored.tags, original.tags);
      expect(restored.children, isA<IList<ChildModel>>());
      expect(restored.children.length, 1);
      expect(restored.children[0].childName, 'bolt');
      expect(restored.metadata, isA<IMap<String, String>>());
      expect(restored.metadata['color'], 'red');
    });
  });

  group('NestedList serialization', () {
    test('round-trip preserves nested IList<IList<String>>', () {
      final original = NestedList(
        matrix: <IList<String>>[
          <String>['a', 'b'].lock,
          <String>['c', 'd'].lock,
        ].lock,
      );

      final json = original.toJson();
      final restored = NestedList.fromJson(json);

      expect(restored.matrix, isA<IList<IList<String>>>());
      expect(restored.matrix[0], isA<IList<String>>());
      expect(restored.matrix[0][0], 'a');
      expect(restored.matrix[1][1], 'd');
      expect(restored.matrix, original.matrix);
    });
  });

  group('Combined (allOf with MapModel) serialization', () {
    test('round-trip preserves IMap in allOf with MapModel component', () {
      final original = Combined(
        extraData: IMap(const {'extra1': 'value1', 'extra2': 'value2'}),
        combinedModel: const CombinedModel(name: 'test'),
      );

      final json = original.toJson();
      expect(json, isA<Map<String, dynamic>>());

      final restored = Combined.fromJson(json);
      expect(restored.extraData, isA<IMap<String, String>>());
      expect(restored.extraData['extra1'], 'value1');
      expect(restored.extraData['extra2'], 'value2');
      expect(restored.combinedModel.name, 'test');
    });
  });

  // -------------------------------------------------------------------
  // 3. Equality — IList/IMap use native deep equality
  // -------------------------------------------------------------------

  group('equality', () {
    test('Item with same IList/IMap are equal', () {
      final a = Item(
        id: 1,
        name: 'W',
        tags: <String>['x'].lock,
        children: <ChildModel>[].lock,
        metadata: IMap(const <String, String>{'k': 'v'}),
      );
      final b = Item(
        id: 1,
        name: 'W',
        tags: <String>['x'].lock,
        children: <ChildModel>[].lock,
        metadata: IMap(const <String, String>{'k': 'v'}),
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('Item with different IList are not equal', () {
      final a = Item(
        id: 1,
        name: 'W',
        tags: <String>['x'].lock,
        children: <ChildModel>[].lock,
        metadata: <String, String>{}.lock,
      );
      final b = Item(
        id: 1,
        name: 'W',
        tags: <String>['y'].lock,
        children: <ChildModel>[].lock,
        metadata: <String, String>{}.lock,
      );
      expect(a, isNot(b));
    });

    test('NestedList equality works on nested ILists', () {
      final a = NestedList(
        matrix: <IList<String>>[
          <String>['a'].lock,
        ].lock,
      );
      final b = NestedList(
        matrix: <IList<String>>[
          <String>['a'].lock,
        ].lock,
      );
      expect(a, b);
    });
  });

  // -------------------------------------------------------------------
  // 3b. TaggedItem — class with properties + typed AP (list values)
  // -------------------------------------------------------------------

  group('TaggedItem (class with typed AP list values)', () {
    test('additionalProperties field is IMap<String, IList<String>>', () {
      final item = TaggedItem(
        name: 'item1',
        additionalProperties: IMap(<String, IList<String>>{
          'colors': <String>['red', 'blue'].lock,
        }),
      );
      expect(item.additionalProperties, isA<IMap<String, IList<String>>>());
      expect(item.additionalProperties['colors'], isA<IList<String>>());
    });

    test('fromJson round-trip preserves IMap<String, IList<String>>', () {
      final original = TaggedItem(
        name: 'item1',
        additionalProperties: IMap(<String, IList<String>>{
          'colors': <String>['red', 'blue'].lock,
          'sizes': <String>['small', 'large'].lock,
        }),
      );

      final json = original.toJson();
      final restored = TaggedItem.fromJson(json);

      expect(restored.name, 'item1');
      expect(
        restored.additionalProperties,
        isA<IMap<String, IList<String>>>(),
      );
      expect(restored.additionalProperties['colors'], isA<IList<String>>());
      expect(
        restored.additionalProperties['colors'],
        <String>['red', 'blue'].lock,
      );
      expect(
        restored.additionalProperties['sizes'],
        <String>['small', 'large'].lock,
      );
    });

    test('equality works with IMap<String, IList<String>> AP', () {
      final a = TaggedItem(
        name: 'x',
        additionalProperties: IMap(<String, IList<String>>{
          'tags': <String>['a'].lock,
        }),
      );
      final b = TaggedItem(
        name: 'x',
        additionalProperties: IMap(<String, IList<String>>{
          'tags': <String>['a'].lock,
        }),
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });

  // -------------------------------------------------------------------
  // 4. copyWith — verify it works with IList/IMap fields
  // -------------------------------------------------------------------

  group('copyWith', () {
    test('Item copyWith replaces IList field', () {
      final item = Item(
        id: 1,
        name: 'W',
        tags: <String>['old'].lock,
        children: <ChildModel>[].lock,
        metadata: <String, String>{}.lock,
      );
      final updated = item.copyWith(tags: <String>['new'].lock);
      expect(updated.tags, <String>['new'].lock);
      expect(updated.id, 1);
    });
  });
}
