import 'dart:convert';
import 'dart:io';

import 'package:multipart_api/multipart_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  test(
    'XML part sends supplied bytes, filename, and media parameters',
    () async {
      final server = await RawRequestServer.start();
      final api = MultipartApi(
        CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
      );

      final response = await api.postOpaqueShared(
        body: const RenamedOpaqueSharedFormMultipart(
          data: TonikFileBytes([60, 255, 62], fileName: 'raw.xml'),
          label: 'record',
          additionalProperties: {'extra': 'value'},
        ),
      );

      expect(response, isTonikSuccess);
      final wire = MultipartWire(await server.takeRequest());
      expect(wire.parts.map((part) => part.name), [
        'payload',
        'label',
        'extra',
      ]);
      final payload = wire.single('payload');
      expect(payload.bodyBytes, [60, 255, 62]);
      expect(payload.filename, 'raw.xml');
      expect(payload.contentType, 'application/xml; profile="urn:example:v1"');
      expect(
        payload.header('content-disposition'),
        'form-data; name="payload"; filename="raw.xml"',
      );
      expect(wire.single('label').bodyText, 'record');
      expect(wire.single('extra').bodyText, 'value');
      expect(wire.named('internal'), isEmpty);
    },
  );

  test('XML part accepts a file path and sends the file bytes', () async {
    final directory = await Directory.systemTemp.createTemp('opaque-part-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/source.xml');
    await file.writeAsBytes([0, 1, 2, 255]);
    final server = await RawRequestServer.start();
    final api = MultipartApi(
      CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
    );

    final response = await api.postOpaqueShared(
      body: RenamedOpaqueSharedFormMultipart(
        data: TonikFilePath(file.path, fileName: 'chosen.xml'),
        label: 'record',
      ),
    );

    expect(response, isTonikSuccess);
    final payload = MultipartWire(await server.takeRequest()).single('payload');
    expect(payload.bodyBytes, [0, 1, 2, 255]);
    expect(payload.filename, 'chosen.xml');
    expect(payload.contentType, 'application/xml; profile="urn:example:v1"');
  });

  test('absent schema type uses the normal file input', () async {
    final server = await RawRequestServer.start();
    final api = MultipartApi(
      CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
    );

    final response = await api.postOpaqueAbsent(
      body: const OpaqueAbsentFormMultipart(
        payload: TonikFileBytes([0, 128, 255], fileName: 'opaque.bin'),
        note: 'present',
      ),
    );

    expect(response, isTonikSuccess);
    final payload = MultipartWire(await server.takeRequest()).single('payload');
    expect(payload.bodyBytes, [0, 128, 255]);
    expect(payload.filename, 'opaque.bin');
    expect(payload.contentType, 'application/octet-stream');
  });

  test('configured bytes override keeps its declared media type', () async {
    final server = await RawRequestServer.start();
    final api = MultipartApi(
      CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
    );

    final response = await api.postOpaqueConfigured(
      body: const RenamedOpaqueSharedFormMultipartModel(
        data: TonikFileBytes([1, 2, 3], fileName: 'custom.bin'),
        label: 'record',
      ),
    );

    expect(response, isTonikSuccess);
    final payload = MultipartWire(await server.takeRequest()).single('payload');
    expect(payload.bodyBytes, [1, 2, 3]);
    expect(payload.filename, 'custom.bin');
    expect(
      payload.contentType,
      'application/vnd.custom-opaque+json; version=1',
    );
  });

  test('opaque bytes keep their declared charset on the wire', () async {
    final server = await RawRequestServer.start();
    final api = MultipartApi(
      CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
    );

    final response = await api.postOpaqueCharset(
      body: const RenamedOpaqueSharedFormMultipartModel2(
        data: TonikFileBytes([0, 129, 255], fileName: 'legacy.xml'),
        label: 'record',
      ),
    );

    expect(response, isTonikSuccess);
    final payload = MultipartWire(await server.takeRequest()).single('payload');
    expect(payload.bodyBytes, [0, 129, 255]);
    expect(payload.filename, 'legacy.xml');
    expect(
      payload.contentType,
      'application/xml; charset=shift_jis; profile=v1',
    );
  });

  test('untyped extra field sends supplied file bytes', () async {
    final server = await RawRequestServer.start();
    final api = MultipartApi(
      CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
    );

    final response = await api.postOpaqueDynamic(
      body: const OpaqueDynamicFormMultipart(
        payload: TonikFileBytes([60, 112, 62]),
        additionalProperties: {
          'attachment': TonikFileBytes([0, 255, 1], fileName: 'extra.bin'),
        },
      ),
    );

    expect(response, isTonikSuccess);
    final wire = MultipartWire(await server.takeRequest());
    expect(wire.parts.map((part) => part.name), ['payload', 'attachment']);
    expect(wire.single('payload').bodyBytes, [60, 112, 62]);
    expect(wire.single('payload').contentType, 'application/xml');
    final attachment = wire.single('attachment');
    expect(attachment.bodyBytes, [0, 255, 1]);
    expect(attachment.filename, 'extra.bin');
    expect(attachment.contentType, 'application/octet-stream');
  });

  test('empty untyped extras still send the named XML part', () async {
    final server = await RawRequestServer.start();
    final api = MultipartApi(
      CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
    );

    final response = await api.postOpaqueDynamic(
      body: const OpaqueDynamicFormMultipart(
        payload: TonikFileBytes([5, 6], fileName: 'only.xml'),
      ),
    );

    expect(response, isTonikSuccess);
    final wire = MultipartWire(await server.takeRequest());
    expect(wire.parts.map((part) => part.name), ['payload']);
    expect(wire.single('payload').bodyBytes, [5, 6]);
    expect(wire.single('payload').filename, 'only.xml');
    expect(wire.single('payload').contentType, 'application/xml');
  });

  test('the dynamic shared JSON request retains its object type', () async {
    final server = await RawRequestServer.start();
    final api = MultipartApi(
      CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
    );

    final response = await api.postOpaqueDynamicJson(
      body: const OpaqueDynamicForm(
        payload: OpaqueDynamicFormPayloadModel(value: 'typed'),
        additionalProperties: {'extra': 123},
      ),
    );

    expect(response, isTonikSuccess);
    final request = await server.takeRequest();
    expect(request.header('content-type'), contains('application/json'));
    expect(jsonDecode(request.bodyText), {
      'payload': {'value': 'typed'},
      'extra': 123,
    });
  });

  test('untyped extras cannot replace the named XML part', () async {
    final server = await RawRequestServer.start();
    final api = MultipartApi(
      CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
    );

    final response = await api.postOpaqueDynamic(
      body: const OpaqueDynamicFormMultipart(
        payload: TonikFileBytes([1]),
        additionalProperties: {
          'payload': TonikFileBytes([2]),
        },
      ),
    );

    expect(requireError(response).type, TonikErrorType.encoding);
    expect(server.requestCount, 0);
  });

  test('an untyped root map sends file bytes and a file path', () async {
    final directory = await Directory.systemTemp.createTemp('opaque-root-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/source.bin');
    await file.writeAsBytes([1, 2, 255]);
    final server = await RawRequestServer.start();
    final api = MultipartApi(
      CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
    );

    final response = await api.postOpaqueRoot(
      body: {
        'bytes': const TonikFileBytes([0, 128], fileName: 'bytes.bin'),
        'path': TonikFilePath(file.path, fileName: 'chosen.bin'),
      },
    );

    expect(response, isTonikSuccess);
    final wire = MultipartWire(await server.takeRequest());
    expect(wire.parts.map((part) => part.name), ['bytes', 'path']);
    expect(wire.single('bytes').bodyBytes, [0, 128]);
    expect(wire.single('bytes').filename, 'bytes.bin');
    expect(wire.single('bytes').contentType, 'application/octet-stream');
    expect(wire.single('path').bodyBytes, [1, 2, 255]);
    expect(wire.single('path').filename, 'chosen.bin');
    expect(wire.single('path').contentType, 'application/octet-stream');
  });

  test('the untyped root map remains reusable for JSON', () async {
    final server = await RawRequestServer.start();
    final api = MultipartApi(
      CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
    );

    final response = await api.postOpaqueRootJson(
      body: {'label': 'typed', 'count': 3},
    );

    expect(response, isTonikSuccess);
    final request = await server.takeRequest();
    expect(request.header('content-type'), contains('application/json'));
    expect(jsonDecode(request.bodyText), {'label': 'typed', 'count': 3});
  });

  test('untyped extra arrays repeat one multipart field name', () async {
    final server = await RawRequestServer.start();
    final api = MultipartApi(
      CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
    );

    final response = await api.postOpaqueArrayExtras(
      body: const OpaqueArrayExtrasMultipart(
        payload: TonikFileBytes([60, 112, 62]),
        additionalProperties: {
          'files': [
            TonikFileBytes([1], fileName: 'first.bin'),
            TonikFileBytes([2], fileName: 'second.bin'),
          ],
        },
      ),
    );

    expect(response, isTonikSuccess);
    final wire = MultipartWire(await server.takeRequest());
    expect(wire.parts.map((part) => part.name), ['payload', 'files', 'files']);
    expect(wire.single('payload').bodyBytes, [60, 112, 62]);
    expect(wire.named('files').map((part) => part.bodyBytes), [
      [1],
      [2],
    ]);
    expect(wire.named('files').map((part) => part.filename), [
      'first.bin',
      'second.bin',
    ]);
    expect(wire.named('files').map((part) => part.contentType), [
      'application/octet-stream',
      'application/octet-stream',
    ]);
  });

  test('untyped root arrays repeat file parts from bytes and path', () async {
    final directory = await Directory.systemTemp.createTemp('opaque-array-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/source.bin');
    await file.writeAsBytes([2, 255]);
    final server = await RawRequestServer.start();
    final api = MultipartApi(
      CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
    );

    final response = await api.postOpaqueArrayRoot(
      body: {
        'files': [
          const TonikFileBytes([1], fileName: 'first.bin'),
          TonikFilePath(file.path, fileName: 'second.bin'),
        ],
      },
    );

    expect(response, isTonikSuccess);
    final wire = MultipartWire(await server.takeRequest());
    expect(wire.parts.map((part) => part.name), ['files', 'files']);
    expect(wire.named('files').map((part) => part.bodyBytes), [
      [1],
      [2, 255],
    ]);
    expect(wire.named('files').map((part) => part.filename), [
      'first.bin',
      'second.bin',
    ]);
  });

  test('untyped extra arrays keep their shared JSON value types', () async {
    final server = await RawRequestServer.start();
    final api = MultipartApi(
      CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
    );

    final response = await api.postOpaqueArrayExtrasJson(
      body: const OpaqueArrayExtras(
        payload: OpaqueArrayExtrasPayloadModel(value: 'typed'),
        additionalProperties: {
          'values': [1, 'two'],
        },
      ),
    );

    expect(response, isTonikSuccess);
    final request = await server.takeRequest();
    expect(jsonDecode(request.bodyText), {
      'payload': {'value': 'typed'},
      'values': [1, 'two'],
    });
  });

  test('untyped root arrays keep their shared JSON values', () async {
    final server = await RawRequestServer.start();
    final api = MultipartApi(
      CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
    );

    final response = await api.postOpaqueArrayRootJson(
      body: {
        'values': [1, 'two'],
      },
    );

    expect(response, isTonikSuccess);
    final request = await server.takeRequest();
    expect(jsonDecode(request.bodyText), {
      'values': [1, 'two'],
    });
  });

  test('allOf projection reads the binary member and its sibling', () async {
    final server = await RawRequestServer.start();
    final api = MultipartApi(
      CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
    );

    final response = await api.postOpaqueAllOf(
      body: const OpaqueAllOfMultipart(
        opaquePayloadMultipart: OpaquePayloadMultipart(
          payload: TonikFileBytes([9, 8, 7], fileName: 'part.xml'),
        ),
        opaqueNote: OpaqueNote(note: 'retained'),
      ),
    );

    expect(response, isTonikSuccess);
    final wire = MultipartWire(await server.takeRequest());
    expect(wire.parts.map((part) => part.name), ['payload', 'note']);
    expect(wire.single('payload').bodyBytes, [9, 8, 7]);
    expect(wire.single('payload').contentType, 'application/xml');
    expect(wire.single('note').bodyText, 'retained');
  });

  test('conflicting projected allOf values fail before sending', () async {
    final server = await RawRequestServer.start();
    final api = MultipartApi(
      CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
    );

    final response = await api.postOpaqueDuplicate(
      body: const OpaqueDuplicateMultipart(
        opaqueDuplicateLeftMultipart: OpaqueDuplicateLeftMultipart(
          payload: TonikFileBytes([1]),
        ),
        opaqueDuplicateRightMultipart: OpaqueDuplicateRightMultipart(
          payload: TonikFileBytes([2]),
        ),
      ),
    );

    expect(requireError(response).type, TonikErrorType.encoding);
    expect(server.requestCount, 0);
  });

  test('the shared JSON request keeps its typed object', () async {
    final server = await RawRequestServer.start();
    final api = MultipartApi(
      CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
    );

    final response = await api.postOpaqueSharedJson(
      body: const RenamedOpaqueSharedForm(
        data: OpaqueSharedFormPayloadModel(value: 'typed'),
        label: 'record',
      ),
    );

    expect(response, isTonikSuccess);
    final request = await server.takeRequest();
    expect(request.header('content-type'), contains('application/json'));
    expect(jsonDecode(request.bodyText), {
      'payload': {'value': 'typed'},
      'label': 'record',
    });
  });

  test('additional keys cannot replace a projected named part', () async {
    final server = await RawRequestServer.start();
    final api = MultipartApi(
      CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
    );

    final response = await api.postOpaqueShared(
      body: const RenamedOpaqueSharedFormMultipart(
        data: TonikFileBytes([1]),
        label: 'record',
        additionalProperties: {'payload': 'collision'},
      ),
    );

    expect(requireError(response).type, TonikErrorType.encoding);
    expect(server.requestCount, 0);
  });
}
