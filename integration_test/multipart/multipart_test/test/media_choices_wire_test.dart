// Generated public choice names exceed the line limit.
// ignore_for_file: lines_longer_than_80_chars

import 'package:multipart_api/multipart_api.dart' as api;
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

typedef _Body = api.MultipartMediaChoicesPostBodyBodyMultipartModel;
typedef _Payload = api.MultipartMediaChoicesPostBodyBodyPayloadModel;
typedef _Item = api.MultipartMediaChoicesPostBodyBodyItemsArrayModel;
typedef _PayloadJson =
    api.MultipartMediaChoicesPostBodyBodyPayloadMultipartChoicesPayloadOneOfModelApplicationJsonChoice1;
typedef _PayloadXml =
    api.MultipartMediaChoicesPostBodyBodyPayloadMultipartChoicesPayloadOneOfModelApplicationXmlChoice2;
typedef _ItemJson =
    api.MultipartMediaChoicesPostBodyBodyItemsArrayMultipartChoicesItemsOneOfModelApplicationJsonChoice1;
typedef _ItemXml =
    api.MultipartMediaChoicesPostBodyBodyItemsArrayMultipartChoicesItemsOneOfModelApplicationXmlChoice2;
typedef _LeftJson =
    api.MediaChoicesLeftPayloadMultipartChoicesPayloadOneOfModelApplicationJsonChoice1;
typedef _LeftItemJson =
    api.MediaChoicesLeftItemsArrayMultipartChoicesItemsOneOfModelApplicationJsonChoice1;
typedef _RightJson =
    api.MediaChoicesRightPayloadMultipartChoicesPayloadOneOfModelApplicationJsonChoice1;
typedef _RightXml =
    api.MediaChoicesRightPayloadMultipartChoicesPayloadOneOfModelApplicationXmlChoice2;
typedef _RightItemXml =
    api.MediaChoicesRightItemsArrayMultipartChoicesItemsOneOfModelApplicationXmlChoice2;
typedef _DateTimeLeftJson =
    api.MediaChoicesDateTimeLeftMomentMultipartChoicesMomentOneOfModelApplicationJsonChoice1;
typedef _DateTimeRightJson =
    api.MediaChoicesDateTimeRightMomentMultipartChoicesMomentOneOfModelApplicationJsonChoice1;
typedef _EnumLeftJson =
    api.MediaChoicesEnumLeftStateMultipartChoicesStateOneOfModelApplicationJsonChoice1;
typedef _EnumRightJson =
    api.MediaChoicesEnumRightStateMultipartChoicesStateOneOfModelApplicationJsonChoice1;
typedef _FormLeft =
    api.MediaChoicesFormLeftPayloadMultipartChoicesPayloadOneOfModelApplicationXWwwFormUrlencodedChoice2;
typedef _FormRight =
    api.MediaChoicesFormRightPayloadMultipartChoicesPayloadOneOfModelApplicationXWwwFormUrlencodedChoice2;
typedef _FormRightJson =
    api.MediaChoicesFormRightPayloadMultipartChoicesPayloadOneOfModelApplicationJsonChoice1;
typedef _MapLeftJson =
    api.MediaChoicesMapLeftUpdatesMultipartChoicesUpdatesOneOfModelApplicationJsonChoice1;
typedef _MapRightJson =
    api.MediaChoicesMapRightUpdatesMultipartChoicesUpdatesOneOfModelApplicationJsonChoice1;
typedef _MapRightXml =
    api.MediaChoicesMapRightUpdatesMultipartChoicesUpdatesOneOfModelApplicationXmlChoice2;
typedef _MixedLeftJson =
    api.MediaChoicesMixedScalarLeftMomentMultipartChoicesMomentOneOfModelApplicationJsonChoice1;
typedef _MixedRightJson =
    api.MediaChoicesMixedScalarRightMomentMultipartChoicesMomentOneOfModelApplicationJsonChoice1;
typedef _MixedLeftText =
    api.MediaChoicesMixedScalarLeftMomentMultipartChoicesMomentOneOfModel2TextPlainChoice1;
typedef _MixedRightText =
    api.MediaChoicesMixedScalarRightMomentMultipartChoicesMomentOneOfModel2TextPlainChoice1;

void main() {
  test('omits a root media range and sends its concrete sibling', () async {
    final server = await RawRequestServer.start();
    final client = api.MultipartApi(
      api.CustomServer(
        baseUrl: server.baseUrl,
        serverConfig: testServerConfig(),
      ),
    );

    final response = await client.postRequestRangeWithConcrete(
      body: const api.MultipartRequestRangeWithConcretePostBodyBodyModel(
        message: 'concrete',
      ),
    );

    expect(response, isTonikSuccess);
    final request = await server.takeRequest();
    expect(request.header('content-type'), startsWith('application/json'));
    expect(request.bodyText, '{"message":"concrete"}');
  });

  test('allOf sends a later string choice as plain text', () async {
    final server = await RawRequestServer.start();
    final client = api.MultipartApi(
      api.CustomServer(
        baseUrl: server.baseUrl,
        serverConfig: testServerConfig(),
      ),
    );

    final response = await client.postMediaChoicesMixedTextAllOf(
      body: const api.MediaChoicesMixedScalarAllOfMultipartModel(
        mediaChoicesMixedScalarLeftMultipartModel:
            api.MediaChoicesMixedScalarLeftMultipartModel(),
        mediaChoicesMixedScalarRightMultipartModel:
            api.MediaChoicesMixedScalarRightMultipartModel(
              moment: _MixedRightText('2024-01-02T03:04:05.000Z'),
            ),
      ),
    );

    expect(response, isTonikSuccess);
    final wire = MultipartWire(await server.takeRequest());
    expect(wire.named('moment'), hasLength(1));
    expect(wire.single('moment').bodyText, '2024-01-02T03:04:05.000Z');
    expect(wire.single('moment').contentType, startsWith('text/plain'));
  });

  test('allOf merges equivalent date-time and string text choices', () async {
    final server = await RawRequestServer.start();
    final client = api.MultipartApi(
      api.CustomServer(
        baseUrl: server.baseUrl,
        serverConfig: testServerConfig(),
      ),
    );

    final response = await client.postMediaChoicesMixedTextAllOf(
      body: api.MediaChoicesMixedScalarAllOfMultipartModel(
        mediaChoicesMixedScalarLeftMultipartModel:
            api.MediaChoicesMixedScalarLeftMultipartModel(
              moment: _MixedLeftText(DateTime.utc(2024, 1, 2, 3, 4, 5)),
            ),
        mediaChoicesMixedScalarRightMultipartModel:
            const api.MediaChoicesMixedScalarRightMultipartModel(
              moment: _MixedRightText('2024-01-02T03:04:05.000Z'),
            ),
      ),
    );

    expect(response, isTonikSuccess);
    final wire = MultipartWire(await server.takeRequest());
    expect(wire.named('moment'), hasLength(1));
    expect(wire.single('moment').bodyText, '2024-01-02T03:04:05.000Z');
    expect(wire.single('moment').contentType, startsWith('text/plain'));
  });

  test('allOf rejects conflicting plain text choices before sending', () async {
    final server = await RawRequestServer.start();
    final client = api.MultipartApi(
      api.CustomServer(
        baseUrl: server.baseUrl,
        serverConfig: testServerConfig(),
      ),
    );

    final response = await client.postMediaChoicesMixedTextAllOf(
      body: api.MediaChoicesMixedScalarAllOfMultipartModel(
        mediaChoicesMixedScalarLeftMultipartModel:
            api.MediaChoicesMixedScalarLeftMultipartModel(
              moment: _MixedLeftText(DateTime.utc(2024, 1, 2, 3, 4, 5)),
            ),
        mediaChoicesMixedScalarRightMultipartModel:
            const api.MediaChoicesMixedScalarRightMultipartModel(
              moment: _MixedRightText('different'),
            ),
      ),
    );

    final error = requireError(response);
    expect(error.type, TonikErrorType.encoding);
    expect(server.requestCount, 0);
  });

  test('allOf sends a later string choice as quoted JSON', () async {
    final server = await RawRequestServer.start();
    final client = api.MultipartApi(
      api.CustomServer(
        baseUrl: server.baseUrl,
        serverConfig: testServerConfig(),
      ),
    );

    final response = await client.postMediaChoicesMixedScalarAllOf(
      body: const api.MediaChoicesMixedScalarAllOfMultipart(
        mediaChoicesMixedScalarLeftMultipart:
            api.MediaChoicesMixedScalarLeftMultipart(),
        mediaChoicesMixedScalarRightMultipart:
            api.MediaChoicesMixedScalarRightMultipart(
              moment: _MixedRightJson('2024-01-02T03:04:05.000Z'),
            ),
      ),
    );

    expect(response, isTonikSuccess);
    final wire = MultipartWire(await server.takeRequest());
    expect(wire.named('moment'), hasLength(1));
    expect(wire.single('moment').bodyText, '"2024-01-02T03:04:05.000Z"');
    expect(wire.single('moment').contentType, startsWith('application/json'));
  });

  test('allOf merges matching date-time and string JSON choices', () async {
    final server = await RawRequestServer.start();
    final client = api.MultipartApi(
      api.CustomServer(
        baseUrl: server.baseUrl,
        serverConfig: testServerConfig(),
      ),
    );

    final response = await client.postMediaChoicesMixedScalarAllOf(
      body: api.MediaChoicesMixedScalarAllOfMultipart(
        mediaChoicesMixedScalarLeftMultipart:
            api.MediaChoicesMixedScalarLeftMultipart(
              moment: _MixedLeftJson(DateTime.utc(2024, 1, 2, 3, 4, 5)),
            ),
        mediaChoicesMixedScalarRightMultipart:
            const api.MediaChoicesMixedScalarRightMultipart(
              moment: _MixedRightJson('2024-01-02T03:04:05.000Z'),
            ),
      ),
    );

    expect(response, isTonikSuccess);
    final wire = MultipartWire(await server.takeRequest());
    expect(wire.named('moment'), hasLength(1));
    expect(wire.single('moment').bodyText, '"2024-01-02T03:04:05.000Z"');
    expect(wire.single('moment').contentType, startsWith('application/json'));
  });

  test('allOf merges typed date-time maps into one JSON part', () async {
    final server = await RawRequestServer.start();
    final client = api.MultipartApi(
      api.CustomServer(
        baseUrl: server.baseUrl,
        serverConfig: testServerConfig(),
      ),
    );

    final response = await client.postMediaChoicesMapAllOf(
      body: api.MediaChoicesMapAllOfMultipart(
        mediaChoicesMapLeftMultipart: api.MediaChoicesMapLeftMultipart(
          updates: _MapLeftJson({'left': DateTime.utc(2024, 1, 2, 3, 4, 5)}),
        ),
        mediaChoicesMapRightMultipart: api.MediaChoicesMapRightMultipart(
          updates: _MapRightJson({'right': DateTime.utc(2024, 1, 3, 6, 7, 8)}),
        ),
      ),
    );

    expect(response, isTonikSuccess);
    final wire = MultipartWire(await server.takeRequest());
    expect(wire.named('updates'), hasLength(1));
    expect(
      wire.single('updates').bodyText,
      '{"left":"2024-01-02T03:04:05.000Z",'
      '"right":"2024-01-03T06:07:08.000Z"}',
    );
    expect(wire.single('updates').contentType, startsWith('application/json'));
  });

  test('allOf sends a typed map supplied only by a later source', () async {
    final server = await RawRequestServer.start();
    final client = api.MultipartApi(
      api.CustomServer(
        baseUrl: server.baseUrl,
        serverConfig: testServerConfig(),
      ),
    );

    final response = await client.postMediaChoicesMapAllOf(
      body: api.MediaChoicesMapAllOfMultipart(
        mediaChoicesMapLeftMultipart: const api.MediaChoicesMapLeftMultipart(),
        mediaChoicesMapRightMultipart: api.MediaChoicesMapRightMultipart(
          updates: _MapRightJson({
            'later': DateTime.utc(2024, 1, 4, 9, 10, 11),
          }),
        ),
      ),
    );

    expect(response, isTonikSuccess);
    final wire = MultipartWire(await server.takeRequest());
    expect(wire.named('updates'), hasLength(1));
    expect(
      wire.single('updates').bodyText,
      '{"later":"2024-01-04T09:10:11.000Z"}',
    );
    expect(wire.single('updates').contentType, startsWith('application/json'));
  });

  test('allOf rejects different map media choices before sending', () async {
    final server = await RawRequestServer.start();
    final client = api.MultipartApi(
      api.CustomServer(
        baseUrl: server.baseUrl,
        serverConfig: testServerConfig(),
      ),
    );

    final response = await client.postMediaChoicesMapAllOf(
      body: api.MediaChoicesMapAllOfMultipart(
        mediaChoicesMapLeftMultipart: api.MediaChoicesMapLeftMultipart(
          updates: _MapLeftJson({'left': DateTime.utc(2024, 1, 2)}),
        ),
        mediaChoicesMapRightMultipart: const api.MediaChoicesMapRightMultipart(
          updates: _MapRightXml(TonikFileBytes([60, 120, 47, 62])),
        ),
      ),
    );

    final error = requireError(response);
    expect(error.type, TonikErrorType.encoding);
    expect(
      (error.error as EncodingException).message,
      'Conflicting media choices for multipart property "updates".',
    );
    expect(server.requestCount, 0);
  });

  test('allOf merges matching form choices into one encoded part', () async {
    final server = await RawRequestServer.start();
    final client = api.MultipartApi(
      api.CustomServer(
        baseUrl: server.baseUrl,
        serverConfig: testServerConfig(),
      ),
    );

    final response = await client.postMediaChoicesFormAllOf(
      body: const api.MediaChoicesFormAllOfMultipart(
        mediaChoicesFormLeftMultipart: api.MediaChoicesFormLeftMultipart(
          payload: _FormLeft(api.MediaChoicesFormLeftPayloadModel(left: 'A B')),
        ),
        mediaChoicesFormRightMultipart: api.MediaChoicesFormRightMultipart(
          payload: _FormRight(
            api.MediaChoicesFormRightPayloadModel(right: 'x&y'),
          ),
        ),
      ),
    );

    expect(response, isTonikSuccess);
    final wire = MultipartWire(await server.takeRequest());
    expect(wire.named('payload'), hasLength(1));
    expect(wire.single('payload').bodyText, 'left=A+B&right=x%26y');
    expect(
      wire.single('payload').contentType,
      startsWith('application/x-www-form-urlencoded'),
    );
  });

  test('allOf form and JSON choices disagree before sending', () async {
    final server = await RawRequestServer.start();
    final client = api.MultipartApi(
      api.CustomServer(
        baseUrl: server.baseUrl,
        serverConfig: testServerConfig(),
      ),
    );

    final response = await client.postMediaChoicesFormAllOf(
      body: const api.MediaChoicesFormAllOfMultipart(
        mediaChoicesFormLeftMultipart: api.MediaChoicesFormLeftMultipart(
          payload: _FormLeft(api.MediaChoicesFormLeftPayloadModel(left: 'A')),
        ),
        mediaChoicesFormRightMultipart: api.MediaChoicesFormRightMultipart(
          payload: _FormRightJson(
            api.MediaChoicesFormRightPayloadModel(right: 'B'),
          ),
        ),
      ),
    );

    final error = requireError(response);
    expect(error.type, TonikErrorType.encoding);
    expect(
      (error.error as EncodingException).message,
      'Conflicting media choices for multipart property "payload".',
    );
    expect(server.requestCount, 0);
  });

  test('allOf merges matching enum JSON choices as one scalar part', () async {
    final server = await RawRequestServer.start();
    final client = api.MultipartApi(
      api.CustomServer(
        baseUrl: server.baseUrl,
        serverConfig: testServerConfig(),
      ),
    );

    final response = await client.postMediaChoicesEnumAllOf(
      body: const api.MediaChoicesEnumAllOfMultipart(
        mediaChoicesEnumLeftMultipart: api.MediaChoicesEnumLeftMultipart(
          state: _EnumLeftJson(api.MediaChoicesEnumLeftStateModel.ready),
        ),
        mediaChoicesEnumRightMultipart: api.MediaChoicesEnumRightMultipart(
          state: _EnumRightJson(api.MediaChoicesEnumRightStateModel.ready),
        ),
      ),
    );

    expect(response, isTonikSuccess);
    final wire = MultipartWire(await server.takeRequest());
    expect(wire.named('state'), hasLength(1));
    expect(wire.single('state').bodyText, '"ready"');
    expect(wire.single('state').contentType, startsWith('application/json'));
  });

  test('allOf rejects disagreeing enum JSON choices before sending', () async {
    final server = await RawRequestServer.start();
    final client = api.MultipartApi(
      api.CustomServer(
        baseUrl: server.baseUrl,
        serverConfig: testServerConfig(),
      ),
    );

    final response = await client.postMediaChoicesEnumAllOf(
      body: const api.MediaChoicesEnumAllOfMultipart(
        mediaChoicesEnumLeftMultipart: api.MediaChoicesEnumLeftMultipart(
          state: _EnumLeftJson(api.MediaChoicesEnumLeftStateModel.ready),
        ),
        mediaChoicesEnumRightMultipart: api.MediaChoicesEnumRightMultipart(
          state: _EnumRightJson(api.MediaChoicesEnumRightStateModel.blocked),
        ),
      ),
    );

    final error = requireError(response);
    expect(error.type, TonikErrorType.encoding);
    expect(
      (error.error as EncodingException).message,
      'Conflicting values for multipart property "state".',
    );
    expect(server.requestCount, 0);
  });

  test('allOf merges matching date-time JSON choices as one part', () async {
    final server = await RawRequestServer.start();
    final client = api.MultipartApi(
      api.CustomServer(
        baseUrl: server.baseUrl,
        serverConfig: testServerConfig(),
      ),
    );
    final moment = DateTime.utc(2024, 1, 2, 3, 4, 5);

    final response = await client.postMediaChoicesDateTimeAllOf(
      body: api.MediaChoicesDateTimeAllOfMultipart(
        mediaChoicesDateTimeLeftMultipart:
            api.MediaChoicesDateTimeLeftMultipart(
              moment: _DateTimeLeftJson(moment),
            ),
        mediaChoicesDateTimeRightMultipart:
            api.MediaChoicesDateTimeRightMultipart(
              moment: _DateTimeRightJson(moment),
            ),
      ),
    );

    expect(response, isTonikSuccess);
    final wire = MultipartWire(await server.takeRequest());
    expect(wire.named('moment'), hasLength(1));
    expect(wire.single('moment').bodyText, '"2024-01-02T03:04:05.000Z"');
    expect(wire.single('moment').contentType, startsWith('application/json'));
  });

  test('allOf merges matching object choices and later array items', () async {
    final server = await RawRequestServer.start();
    final client = api.MultipartApi(
      api.CustomServer(
        baseUrl: server.baseUrl,
        serverConfig: testServerConfig(),
      ),
    );

    final response = await client.postMediaChoicesAllOf(
      body: const api.MediaChoicesAllOfMultipart(
        mediaChoicesLeftMultipart: api.MediaChoicesLeftMultipart(
          payload: _LeftJson(api.MediaChoicesLeftPayloadModel(left: 'L')),
          items: [
            _LeftItemJson(api.MediaChoicesLeftItemsArrayModel(left: 'first')),
          ],
        ),
        mediaChoicesRightMultipart: api.MediaChoicesRightMultipart(
          payload: _RightJson(api.MediaChoicesRightPayloadModel(right: 'R')),
          items: [
            _RightItemXml(TonikFileBytes([60, 114, 47, 62])),
          ],
        ),
      ),
    );

    expect(response, isTonikSuccess);
    final wire = MultipartWire(await server.takeRequest());
    expect(wire.parts.map((part) => part.name), ['payload', 'items', 'items']);
    expect(wire.single('payload').bodyText, '{"left":"L","right":"R"}');
    expect(wire.single('payload').contentType, startsWith('application/json'));
    final items = wire.named('items');
    expect(items[0].bodyText, '{"left":"first"}');
    expect(items[0].contentType, startsWith('application/json'));
    expect(items[1].bodyBytes, [60, 114, 47, 62]);
    expect(items[1].contentType, 'application/xml');
  });

  test('allOf sends a choice supplied only by a later source', () async {
    final server = await RawRequestServer.start();
    final client = api.MultipartApi(
      api.CustomServer(
        baseUrl: server.baseUrl,
        serverConfig: testServerConfig(),
      ),
    );

    final response = await client.postMediaChoicesAllOf(
      body: const api.MediaChoicesAllOfMultipart(
        mediaChoicesLeftMultipart: api.MediaChoicesLeftMultipart(),
        mediaChoicesRightMultipart: api.MediaChoicesRightMultipart(
          payload: _RightXml(TonikFileBytes([60, 120, 47, 62])),
        ),
      ),
    );

    expect(response, isTonikSuccess);
    final wire = MultipartWire(await server.takeRequest());
    expect(wire.parts.map((part) => part.name), ['payload']);
    expect(wire.single('payload').bodyBytes, [60, 120, 47, 62]);
    expect(wire.single('payload').contentType, 'application/xml');
  });

  test('allOf rejects conflicting media choices before sending', () async {
    final server = await RawRequestServer.start();
    final client = api.MultipartApi(
      api.CustomServer(
        baseUrl: server.baseUrl,
        serverConfig: testServerConfig(),
      ),
    );

    final response = await client.postMediaChoicesAllOf(
      body: const api.MediaChoicesAllOfMultipart(
        mediaChoicesLeftMultipart: api.MediaChoicesLeftMultipart(
          payload: _LeftJson(api.MediaChoicesLeftPayloadModel(left: 'L')),
        ),
        mediaChoicesRightMultipart: api.MediaChoicesRightMultipart(
          payload: _RightXml(TonikFileBytes([60, 120, 47, 62])),
        ),
      ),
    );

    final error = requireError(response);
    expect(error.type, TonikErrorType.encoding);
    expect(error.error, isA<EncodingException>());
    expect(
      (error.error as EncodingException).message,
      'Conflicting media choices for multipart property "payload".',
    );
    expect(server.requestCount, 0);
  });

  test(
    'each named item selects its own bytes and concrete media type',
    () async {
      final server = await RawRequestServer.start();
      final client = api.MultipartApi(
        api.CustomServer(
          baseUrl: server.baseUrl,
          serverConfig: testServerConfig(),
        ),
      );

      final response = await client.postMediaChoices(
        body: const _Body(
          payload: _PayloadJson(_Payload(message: 'root')),
          items: [
            _ItemJson(_Item(message: 'first')),
            _ItemXml(TonikFileBytes([60, 97, 47, 62], fileName: 'second.xml')),
          ],
        ),
      );

      expect(response, isTonikSuccess);
      final wire = MultipartWire(await server.takeRequest());
      expect(wire.parts.map((part) => part.name), [
        'payload',
        'items',
        'items',
      ]);
      expect(wire.single('payload').bodyText, '{"message":"root"}');
      expect(
        wire.single('payload').contentType,
        startsWith('application/json'),
      );
      final items = wire.named('items');
      expect(items[0].bodyText, '{"message":"first"}');
      expect(items[0].contentType, startsWith('application/json'));
      expect(items[1].bodyBytes, [60, 97, 47, 62]);
      expect(items[1].contentType, 'application/xml; profile="one,two"');
    },
  );

  test('opaque choice can be selected for a single named part', () async {
    final server = await RawRequestServer.start();
    final client = api.MultipartApi(
      api.CustomServer(
        baseUrl: server.baseUrl,
        serverConfig: testServerConfig(),
      ),
    );

    final response = await client.postMediaChoices(
      body: const _Body(
        payload: _PayloadXml(TonikFileBytes([60, 120, 47, 62])),
        items: [],
      ),
    );

    expect(response, isTonikSuccess);
    final payload = MultipartWire(await server.takeRequest()).single('payload');
    expect(payload.bodyBytes, [60, 120, 47, 62]);
    expect(payload.contentType, 'application/xml; profile="one,two"');
  });
}
