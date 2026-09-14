import 'dart:convert';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:immutable_collections_api/immutable_collections_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';

void main() {
  test(
    'packs merged immutable URI lists with nulls through the JSON codec',
    () async {
      final server = await RawRequestServer.start();
      final api = ItemsApi(CustomServer(baseUrl: server.baseUrl));
      expect(
        await api.postPackedMerged(
          body: PackedMerged(
            packedFirst: PackedFirst(
              values: IList([null, Uri.parse('https://first.test/')]),
            ),
            packedSecond: PackedSecond(
              values: IList([Uri.parse('https://second.test/'), null]),
            ),
          ),
        ),
        isTonikSuccess,
      );
      final wire = MultipartWire(await server.takeRequest());
      expect(wire.parts.single.name, 'values');
      expect(wire.parts.single.contentType, startsWith('application/json'));
      expect(
        wire.parts.single.bodyText,
        '[null,"https://first.test/","https://second.test/",null]',
      );
    },
  );

  test('sends an inline immutable map through the public API', () async {
    final server = await RawRequestServer.start();
    final api = ItemsApi(CustomServer(baseUrl: server.baseUrl));
    expect(
      await api.postDynamicInlineMap(
        body: const IMapConst({'second': 'beta', 'first': 'alpha'}),
      ),
      isTonikSuccess,
    );
    final wire = MultipartWire(await server.takeRequest());
    expect(wire.parts.map((part) => part.name), ['second', 'first']);
    expect(wire.parts.map((part) => part.bodyText), ['beta', 'alpha']);
    expect(wire.parts[0].contentType, startsWith('text/plain'));
  });

  test(
    'sends an immutable map typedef with nested immutable arrays in order',
    () async {
      final server = await RawRequestServer.start();
      final api = ItemsApi(CustomServer(baseUrl: server.baseUrl));
      const DynamicMap body = IMapConst({
        'first': IListConst([3, 1]),
        'later': IListConst([2]),
      });
      expect(await api.postDynamicMap(body: body), isTonikSuccess);
      final wire = MultipartWire(await server.takeRequest());
      expect(wire.parts.map((p) => p.name), ['first', 'first', 'later']);
      expect(wire.parts.map((p) => p.bodyText), ['3', '1', '2']);
      expect(wire.parts.first.contentType, startsWith('text/plain'));
    },
  );

  test('keeps immutable mixed API and nested map JSON encoding', () async {
    final server = await RawRequestServer.start();
    final api = ItemsApi(CustomServer(baseUrl: server.baseUrl));
    const original = DynamicMixed(label: 'named');
    expect(
      original.additionalProperties,
      const IMapConst<String, IMap<String, IList<int>>>({}),
    );
    // The function type checks the public copyWith API at compile time.
    // ignore: omit_local_variable_types
    final DynamicMixed Function({
      String? label,
      IMap<String, IMap<String, IList<int>>>? additionalProperties,
    })
    copy = original.copyWith;
    final body = copy(
      additionalProperties: const IMapConst({
        'extra': IMapConst({
          'numbers': IListConst([2, 1]),
        }),
      }),
    );
    expect(
      body,
      const DynamicMixed(
        label: 'named',
        additionalProperties: IMapConst({
          'extra': IMapConst({
            'numbers': IListConst([2, 1]),
          }),
        }),
      ),
    );
    expect(await api.postDynamicMixed(body: body), isTonikSuccess);
    final wire = MultipartWire(await server.takeRequest());
    expect(wire.parts.map((p) => p.name), ['label', 'extra']);
    expect(wire.parts[0].bodyText, 'named');
    expect(jsonDecode(wire.parts[1].bodyText), {
      'numbers': [2, 1],
    });
    expect(wire.parts[1].contentType, startsWith('application/json'));
  });
  test('accepts mutable inline headers with an immutable mixed body', () async {
    final server = await RawRequestServer.start();
    final api = ItemsApi(CustomServer(baseUrl: server.baseUrl));
    expect(
      await api.postDynamicHeaders(
        body: const DynamicMixed(
          label: 'named',
          additionalProperties: IMapConst({
            'extra': IMapConst({
              'numbers': IListConst([2, 1]),
            }),
          }),
        ),
        labelTags: ['first', 'second'],
      ),
      isTonikSuccess,
    );
    final wire = MultipartWire(await server.takeRequest());
    expect(wire.parts.map((part) => part.name), ['label', 'extra']);
    expect(wire.parts[0].bodyText, 'named');
    expect(wire.parts[0].header('x-tags'), 'first,second');
    expect(jsonDecode(wire.parts[1].bodyText), {
      'numbers': [2, 1],
    });
    expect(wire.parts[1].header('x-tags'), isNull);
  });

  test(
    'keeps inline header types compatible in multi-content operations',
    () async {
      final server = await RawRequestServer.start();
      final api = ItemsApi(CustomServer(baseUrl: server.baseUrl));
      expect(
        await api.postDynamicHeadersMulti(
          body: const DynamicHeadersMultiPostBodyRequestBodyFormData(
            DynamicMixed(
              label: 'named',
              additionalProperties: IMapConst({
                'extra': IMapConst({
                  'numbers': IListConst([2, 1]),
                }),
              }),
            ),
          ),
          labelTags: ['first', 'second'],
        ),
        isTonikSuccess,
      );
      final wire = MultipartWire(await server.takeRequest());
      expect(wire.parts.map((part) => part.name), ['label', 'extra']);
      expect(wire.parts[0].bodyText, 'named');
      expect(wire.parts[0].header('x-tags'), 'first,second');
      expect(jsonDecode(wire.parts[1].bodyText), {
        'numbers': [2, 1],
      });
      expect(wire.parts[1].header('x-tags'), isNull);
    },
  );
}
