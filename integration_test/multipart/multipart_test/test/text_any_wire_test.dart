import 'dart:convert';

import 'package:multipart_api/multipart_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  test('default scalar parts send plain text bytes', () async {
    final server = await RawRequestServer.start();
    final api = MultipartApi(CustomServer(baseUrl: server.baseUrl));

    await api.postSimpleFields(
      body: const SimpleFields(name: 'Ada', age: 42, active: true),
    );

    final wire = MultipartWire(await server.takeRequest());
    expect(wire.single('name').contentType, startsWith('text/plain'));
    expect(wire.single('name').bodyBytes, utf8.encode('Ada'));
    expect(wire.single('age').contentType, startsWith('text/plain'));
    expect(wire.single('age').bodyBytes, utf8.encode('42'));
    expect(wire.single('active').contentType, startsWith('text/plain'));
    expect(wire.single('active').bodyBytes, utf8.encode('true'));
  });

  test('default object parts send JSON bytes', () async {
    final server = await RawRequestServer.start();
    final api = MultipartApi(CustomServer(baseUrl: server.baseUrl));

    await api.postComplexObject(
      body: const ComplexForm(
        label: 'person',
        profile: Profile(firstName: 'Ada', lastName: 'Lovelace'),
      ),
    );

    final part = MultipartWire(await server.takeRequest()).single('profile');
    expect(part.contentType, startsWith('application/json'));
    expect(jsonDecode(part.bodyText), {
      'firstName': 'Ada',
      'lastName': 'Lovelace',
    });
  });

  test('object parts reject nested multipart media before sending', () async {
    final server = await RawRequestServer.start();
    final api = MultipartApi(CustomServer(baseUrl: server.baseUrl));

    final response = await api.postNestedMultipartMedia(
      body: const ComplexForm(
        label: 'person',
        profile: Profile(firstName: 'Ada', lastName: 'Lovelace'),
      ),
    );

    final error = requireError(response);
    expect(error.type, TonikErrorType.encoding);
    expect(error.error, isA<EncodingException>());
    expect(server.requestCount, 0);
  });

  test('default array items are repeated named text parts', () async {
    final server = await RawRequestServer.start();
    final api = MultipartApi(CustomServer(baseUrl: server.baseUrl));

    await api.postArrayFields(
      body: const ArrayForm(tags: ['alpha', 'beta'], priorities: []),
    );

    final parts = MultipartWire(await server.takeRequest()).named('tags');
    expect(parts, hasLength(2));
    expect(parts[0].contentType, startsWith('text/plain'));
    expect(parts[0].bodyBytes, utf8.encode('alpha'));
    expect(parts[1].contentType, startsWith('text/plain'));
    expect(parts[1].bodyBytes, utf8.encode('beta'));
  });

  test('explicit JSON encoding applies to each repeated item', () async {
    final server = await RawRequestServer.start();
    final api = MultipartApi(CustomServer(baseUrl: server.baseUrl));

    await api.postCategoryArrayFields(
      body: const CategoryArrayForm(
        categories: [
          Category.scienceAmpersandTech,
          Category.artsAmpersandCrafts,
        ],
      ),
    );

    final parts = MultipartWire(await server.takeRequest()).named('categories');
    expect(parts, hasLength(2));
    expect(parts[0].contentType, startsWith('application/json'));
    expect(parts[0].bodyBytes, utf8.encode('"science & tech"'));
    expect(parts[1].contentType, startsWith('application/json'));
    expect(parts[1].bodyBytes, utf8.encode('"arts & crafts"'));
  });

  test(
    'text parts preserve parameters and encode with matching charsets',
    () async {
      final server = await RawRequestServer.start();
      final api = MultipartApi(CustomServer(baseUrl: server.baseUrl));

      await api.postTextAny(
        body: const TextAnyForm(value: 'café', message: '✓', quoted: 'café'),
      );

      final wire = MultipartWire(await server.takeRequest());
      final value = wire.single('value');
      expect(
        value.contentType,
        'text/plain; charset=iso-8859-1; profile=plain',
      );
      expect(value.bodyBytes, latin1.encode('café'));
      final message = wire.single('message');
      expect(message.contentType, 'text/plain; charset=utf-8; profile=message');
      expect(message.bodyBytes, utf8.encode('✓'));
      final quoted = wire.single('quoted');
      expect(
        quoted.contentType,
        'text/plain; profile="x;charset=iso-8859-1"; charset=utf-8',
      );
      expect(quoted.bodyBytes, utf8.encode('café'));
    },
  );

  test('complex AnyModel text value fails before sending', () async {
    final server = await RawRequestServer.start();
    final api = MultipartApi(CustomServer(baseUrl: server.baseUrl));

    final response = await api.postTextAny(
      body: const TextAnyForm(
        value: {'x': 1},
        message: 'valid',
        quoted: 'valid',
      ),
    );

    final error = requireError(response);
    expect(error.type, TonikErrorType.encoding);
    expect(error.error, isA<EncodingException>());
    expect(server.requestCount, 0);
  });

  test('form media type rejects an untyped value before sending', () async {
    final server = await RawRequestServer.start();
    final api = MultipartApi(CustomServer(baseUrl: server.baseUrl));

    final response = await api.postFormAny(
      body: const FormAnyForm(value: {'x': 1}, label: 'valid'),
    );

    final error = requireError(response);
    expect(error.type, TonikErrorType.encoding);
    expect(error.error, isA<EncodingException>());
    expect(server.requestCount, 0);
  });

  test('form media type rejects scalar text before sending', () async {
    final server = await RawRequestServer.start();
    final api = MultipartApi(CustomServer(baseUrl: server.baseUrl));

    final response = await api.postFormScalar(
      body: const FormScalarForm(value: 'a&b', label: 'valid'),
    );

    final error = requireError(response);
    expect(error.type, TonikErrorType.encoding);
    expect(error.error, isA<EncodingException>());
    expect(server.requestCount, 0);
  });

  test('base64 file cannot claim JSON media type', () async {
    final server = await RawRequestServer.start();
    final api = MultipartApi(CustomServer(baseUrl: server.baseUrl));

    final response = await api.postJsonBase64(
      body: const JsonBase64Form(
        file: TonikFileBytes([1, 2, 3]),
        label: 'valid',
      ),
    );

    final error = requireError(response);
    expect(error.type, TonikErrorType.encoding);
    expect(error.error, isA<EncodingException>());
    expect(server.requestCount, 0);
  });

  test('read-only allOf member is omitted beside a writable part', () async {
    final server = await RawRequestServer.start();
    final api = MultipartApi(CustomServer(baseUrl: server.baseUrl));

    await api.postReadOnlyAllOf(
      body: const ReadOnlyAllOfForm(
        readOnlyAllOfServer: ReadOnlyAllOfServer(serverId: 'server-only'),
        readOnlyAllOfClient: ReadOnlyAllOfClient(name: 'Ada'),
      ),
    );

    final wire = MultipartWire(await server.takeRequest());
    expect(wire.parts.map((part) => part.name), ['name']);
    expect(wire.single('name').contentType, startsWith('text/plain'));
    expect(wire.single('name').bodyBytes, utf8.encode('Ada'));
  });

  test('unmatched encoding leaves the named part usable', () async {
    final server = await RawRequestServer.start();
    final api = MultipartApi(CustomServer(baseUrl: server.baseUrl));

    await api.postUnmatchedEncoding(
      body: const UnmatchedEncodingForm(name: 'Ada'),
    );

    final wire = MultipartWire(await server.takeRequest());
    expect(wire.parts.map((part) => part.name), ['name']);
    expect(wire.single('name').contentType, startsWith('text/plain'));
    expect(wire.single('name').bodyBytes, utf8.encode('Ada'));
  });

  test('nested arrays send one JSON part per inner array', () async {
    final server = await RawRequestServer.start();
    final api = MultipartApi(CustomServer(baseUrl: server.baseUrl));

    await api.postNestedArray(
      body: const NestedArrayForm(
        values: [
          [1, 2],
          [3],
        ],
      ),
    );

    final parts = MultipartWire(await server.takeRequest()).named('values');
    expect(parts, hasLength(2));
    expect(parts[0].contentType, startsWith('application/json'));
    expect(parts[0].bodyBytes, utf8.encode('[1,2]'));
    expect(parts[1].contentType, startsWith('application/json'));
    expect(parts[1].bodyBytes, utf8.encode('[3]'));
  });

  test('nested date-time arrays use model JSON conversion', () async {
    final server = await RawRequestServer.start();
    final api = MultipartApi(CustomServer(baseUrl: server.baseUrl));

    await api.postNestedDates(
      body: NestedDatesForm(
        values: [
          [DateTime.utc(2026, 9, 14, 1, 2, 3)],
        ],
      ),
    );

    final part = MultipartWire(await server.takeRequest()).single('values');
    expect(part.contentType, startsWith('application/json'));
    expect(part.bodyBytes, utf8.encode('["2026-09-14T01:02:03.000Z"]'));
  });

  test('nested arrays reject text media before sending', () async {
    final server = await RawRequestServer.start();
    final api = MultipartApi(CustomServer(baseUrl: server.baseUrl));

    final response = await api.postNestedArrayText(
      body: const NestedArrayForm(
        values: [
          [1, 2],
        ],
      ),
    );

    final error = requireError(response);
    expect(error.type, TonikErrorType.encoding);
    expect(error.error, isA<EncodingException>());
    expect(server.requestCount, 0);
  });
}
