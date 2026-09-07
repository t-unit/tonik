import 'dart:convert';

import 'package:multipart_api/multipart_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';

import 'multipart_wire.dart';

void main() {
  test('sends ordered JSON object parts with the same field name', () async {
    final server = await RawRequestServer.start();
    final api = MultipartApi(CustomServer(baseUrl: server.baseUrl));

    final response = await api.postObjectArrays(
      body: const ObjectArrayForm(
        items: [
          ObjectArrayItem(name: 'alpha'),
          ObjectArrayItem(name: 'beta'),
        ],
      ),
    );

    expect(response, isTonikSuccess);
    final wire = MultipartWire(await server.takeRequest());
    expect(wire.parts, hasLength(2));
    final items = wire.named('items');
    expect(items, hasLength(2));
    expect(items[0].contentType, startsWith('application/json'));
    expect(jsonDecode(items[0].bodyText), {'name': 'alpha'});
    expect(items[1].contentType, startsWith('application/json'));
    expect(jsonDecode(items[1].bodyText), {'name': 'beta'});
    expect(wire.named('optionalItems'), isEmpty);
  });

  test('an empty object array emits no parts', () async {
    final server = await RawRequestServer.start();
    final api = MultipartApi(CustomServer(baseUrl: server.baseUrl));

    final response = await api.postObjectArrays(
      body: const ObjectArrayForm(items: []),
    );

    expect(response, isTonikSuccess);
    final wire = MultipartWire(await server.takeRequest());
    expect(wire.parts, isEmpty);
  });

  test('a single object emits one object part', () async {
    final server = await RawRequestServer.start();
    final api = MultipartApi(CustomServer(baseUrl: server.baseUrl));

    final response = await api.postObjectArrays(
      body: const ObjectArrayForm(items: [ObjectArrayItem(name: 'alpha')]),
    );

    expect(response, isTonikSuccess);
    final wire = MultipartWire(await server.takeRequest());
    expect(wire.parts, hasLength(1));
    expect(jsonDecode(wire.single('items').bodyText), {'name': 'alpha'});
  });

  test('applies the content-type override to each object part', () async {
    final server = await RawRequestServer.start();
    final api = MultipartApi(CustomServer(baseUrl: server.baseUrl));

    final response = await api.postObjectArraysOverride(
      body: const ObjectArrayForm(
        items: [
          ObjectArrayItem(name: 'alpha'),
          ObjectArrayItem(name: 'beta'),
        ],
      ),
    );

    expect(response, isTonikSuccess);
    final wire = MultipartWire(await server.takeRequest());
    final items = wire.named('items');
    expect(items, hasLength(2));
    expect(
      items[0].contentType,
      startsWith('application/vnd.items+json; profile=v2'),
    );
    expect(jsonDecode(items[0].bodyText), {'name': 'alpha'});
    expect(
      items[1].contentType,
      startsWith('application/vnd.items+json; profile=v2'),
    );
    expect(jsonDecode(items[1].bodyText), {'name': 'beta'});
  });

  test('a present optional object array also emits repeated parts', () async {
    final server = await RawRequestServer.start();
    final api = MultipartApi(CustomServer(baseUrl: server.baseUrl));

    final response = await api.postObjectArrays(
      body: const ObjectArrayForm(
        items: [],
        optionalItems: [
          ObjectArrayItem(name: 'alpha'),
          ObjectArrayItem(name: 'beta'),
        ],
      ),
    );

    expect(response, isTonikSuccess);
    final wire = MultipartWire(await server.takeRequest());
    expect(wire.named('items'), isEmpty);
    final optionalItems = wire.named('optionalItems');
    expect(optionalItems, hasLength(2));
    expect(jsonDecode(optionalItems[0].bodyText), {'name': 'alpha'});
    expect(jsonDecode(optionalItems[1].bodyText), {'name': 'beta'});
  });
}
