import 'dart:convert';

import 'package:multipart_3_1_api/multipart_3_1_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  late RawRequestServer server;
  late Multipart31Api api;
  setUp(() async {
    server = await RawRequestServer.start();
    api = Multipart31Api(CustomServer(baseUrl: server.baseUrl));
  });

  test(
    'omits nullable aliased primitive items and keeps map and item order',
    () async {
      expect(
        await api.postDynamicNullableArrays(
          body: {
            'first': [null, 'alpha', null, 'beta'],
            'second': [null, 'gamma'],
          },
        ),
        isTonikSuccess,
      );
      final wire = MultipartWire(await server.takeRequest());
      expect(wire.parts.map((part) => part.name), ['first', 'first', 'second']);
      expect(wire.parts.map((part) => part.bodyText), [
        'alpha',
        'beta',
        'gamma',
      ]);
      expect(wire.parts[0].contentType, startsWith('text/plain'));
    },
  );

  test('rejects an all-null repeated array body before sending', () async {
    final error = requireError(
      await api.postDynamicNullableArrays(
        body: {
          'first': [null, null],
          'second': [],
        },
      ),
    );
    expect(error.type, TonikErrorType.encoding);
    expect(error.error, isA<EncodingException>());
    expect(server.requestCount, 0);
  });

  test('omits nullable object items before per-object JSON encoding', () async {
    expect(
      await api.postDynamicNullableObjects(
        body: {
          'items': [
            null,
            const DynamicNullableObject(name: 'alpha'),
            null,
            const DynamicNullableObject(name: 'beta'),
          ],
        },
      ),
      isTonikSuccess,
    );
    final wire = MultipartWire(await server.takeRequest());
    expect(wire.parts.map((part) => part.name), ['items', 'items']);
    expect(jsonDecode(wire.parts[0].bodyText), {'name': 'alpha'});
    expect(jsonDecode(wire.parts[1].bodyText), {'name': 'beta'});
    expect(wire.parts[0].contentType, startsWith('application/json'));
  });

  test(
    'omits nullable aliased files and retains filenames and empty bytes',
    () async {
      expect(
        await api.postDynamicNullableFiles(
          body: {
            'files': [
              null,
              const TonikFileBytes([0, 255], fileName: 'first.bin'),
              null,
              const TonikFileBytes([]),
            ],
          },
        ),
        isTonikSuccess,
      );
      final wire = MultipartWire(await server.takeRequest());
      expect(wire.parts.map((part) => part.name), ['files', 'files']);
      expect(wire.parts[0].bodyBytes, [0, 255]);
      expect(wire.parts[0].filename, 'first.bin');
      expect(wire.parts[1].bodyBytes, isEmpty);
      expect(wire.parts[1].filename, 'files');
      expect(wire.parts[1].contentType, 'application/octet-stream');
    },
  );

  test(
    'omits nullable base64 items before custom part serialization',
    () async {
      expect(
        await api.postDynamicNullableBase64(
          body: {
            'files': [
              null,
              const TonikFileBytes([0, 255]),
              null,
              const TonikFileBytes([1], fileName: 'one.bin'),
            ],
          },
        ),
        isTonikSuccess,
      );
      final wire = MultipartWire(await server.takeRequest());
      expect(wire.parts.map((part) => part.name), ['files', 'files']);
      expect(wire.parts.map((part) => part.bodyText), ['AP8=', 'AQ==']);
      expect(wire.parts.map((part) => part.filename), ['files', 'one.bin']);
      expect(
        wire.parts.map((part) => part.header('content-transfer-encoding')),
        ['base64', 'base64'],
      );
    },
  );

  test(
    'shared named repeated arrays omit primitive file and object nulls',
    () async {
      expect(
        await api.postNamedNullableArrays(
          body: const NamedNullableArrays(
            values: [null, 'alpha', null],
            files: [
              null,
              TonikFileBytes([7]),
            ],
            objects: [
              null,
              DynamicNullableObject(name: 'meta'),
            ],
          ),
        ),
        isTonikSuccess,
      );
      final wire = MultipartWire(await server.takeRequest());
      expect(wire.parts.map((part) => part.name), [
        'values',
        'files',
        'objects',
      ]);
      expect(wire.parts[0].bodyText, 'alpha');
      expect(wire.parts[1].bodyBytes, [7]);
      expect(wire.parts[1].filename, 'files');
      expect(jsonDecode(wire.parts[2].bodyText), {'name': 'meta'});
    },
  );

  test(
    'packed JSON arrays retain nulls around transformed date aliases',
    () async {
      expect(
        await api.postNamedNullableJsonArray(
          body: NamedNullableJsonArray(
            dates: [null, DateTime.utc(2026, 9, 14, 1, 2, 3), null],
          ),
        ),
        isTonikSuccess,
      );
      final wire = MultipartWire(await server.takeRequest());
      expect(wire.parts.single.name, 'dates');
      expect(wire.parts.single.contentType, startsWith('application/json'));
      expect(jsonDecode(wire.parts.single.bodyText), [
        null,
        '2026-09-14T01:02:03.000Z',
        null,
      ]);
    },
  );
  test(
    'keeps empty positions for nulls in named delimiter-packed arrays',
    () async {
      expect(
        await api.postNamedNullablePacked(
          body: const Multipart31NamedNullablePackedPostBodyBodyModel(
            values: ['a', null, 'b'],
          ),
        ),
        isTonikSuccess,
      );
      final wire = MultipartWire(await server.takeRequest());
      expect(wire.parts.single.name, 'values');
      expect(wire.parts.single.bodyText, 'a,,b');
    },
  );
}
