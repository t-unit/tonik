import 'dart:convert';

import 'package:dio/dio.dart' as dio;
import 'package:http/http.dart' as http;
import 'package:streaming_response_api/streaming_response_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  late ImposterServer imposterServer;
  late String baseUrl;

  setUpAll(() async {
    imposterServer = await setupImposterServer();
    baseUrl = 'http://localhost:${imposterServer.port}';
  });

  test('typed NDJSON preserves request and response metadata', () async {
    final server = CustomServer(
      baseUrl: baseUrl,
      serverConfig: testServerConfig(headers: {'X-Configured': 'kept'}),
    );
    addTearDown(server.close);
    final result = await StreamingApi(server)
        .getItems(cursor: 7, request: 'user');
    final success = requireSuccess(result);
    expect(success.response.statusCode, 200);
    expect(success.response.headers.value('x-stream'), 'imposter');
    expect(
      await success.value.map((item) => requireSuccess(item).value).toList(),
      [
        const ItemsGet200BodyModel(value: 1),
        const ItemsGet200BodyModel(value: 2),
      ],
    );
    final request = await imposterServer.takeRequest();
    expect(request.method, 'GET');
    expect(request.uri.path, '/items');
    expect(request.uri.queryParameters, {'cursor': '7'});
    expect(request.headers['x-request'], 'user');
    expect(request.headers['x-configured'], 'kept');
  });

  test('malformed NDJSON yields one decoding error', () async {
    final server = CustomServer(
      baseUrl: baseUrl,
      serverConfig: testServerConfig(headers: {'X-Response-Case': 'malformed'}),
    );
    addTearDown(server.close);
    final result = await StreamingApi(server).getItems();
    final items = await requireSuccess(result).value.toList();
    final error = items.single as TonikError<ItemsGet200BodyModel, Object>;
    expect(error.error, isA<FormatException>());
    expect(error.type, TonikErrorType.decoding);
  });

  test(
    'SSE optional fields reach item conversion without inherited values',
    () async {
      final server = CustomServer(baseUrl: baseUrl);
      addTearDown(server.close);
      final result = await StreamingApi(server).getSseFields();
      final values = requireSuccess(result).value
          .map((item) => requireSuccess(item).value)
          .toList();
      expect(await values, [
        const SseFields(data: 'one\ntwo', event: 'update', id: '7', retry: 10),
        const SseFields(data: '', event: '', id: ''),
        const SseFields(data: 'last'),
      ]);
    },
  );

  test('SSE item conversion failure terminates the stream', () async {
    final server = CustomServer(baseUrl: baseUrl);
    addTearDown(server.close);
    final result = await StreamingApi(server).getSseRequiredEvent();
    final events = await requireSuccess(result).value.toList();
    expect(events, hasLength(2));
    expect(
      requireSuccess(events.first as TonikResult<SseRequiredEvent, Object>)
          .value,
      const SseRequiredEvent(data: 'first', event: 'ready'),
    );
    final failure = events.last as TonikError<SseRequiredEvent, Object>;
    expect(failure.error, isA<InvalidTypeException>());
    expect(failure.type, TonikErrorType.decoding);
  });

  test('finite JSONL permits raw CR whitespace', () async {
    final server = CustomServer(baseUrl: baseUrl);
    addTearDown(server.close);
    final result = await StreamingApi(server).getJsonLines();
    final items = requireSuccess(result).value
        .map((item) => requireSuccess(item).value)
        .toList();
    expect(await items, [
      const JsonlGet200BodyModel(value: 3),
      const JsonlGet200BodyModel(value: 4),
    ]);
  });

  test('ordinary JSON retains its completed response', () async {
    final server = CustomServer(baseUrl: baseUrl);
    addTearDown(server.close);
    final result = await StreamingApi(server).getOrdinary();
    expect(
      requireSuccess(result).value,
      const OrdinaryGet200BodyModel(value: 9),
    );
    final native = (result as TonikSuccess).response;
    if (native is http.BaseResponse) {
      expect(native, isA<http.Response>());
      expect(
        result,
        isA<TonikResult<OrdinaryGet200BodyModel, http.Response>>(),
      );
    } else {
      expect(native, isA<dio.Response<Object?>>());
    }
  });

  test('model conversion failure terminates the stream', () async {
    final server = CustomServer(
      baseUrl: baseUrl,
      serverConfig: testServerConfig(
        headers: {'X-Response-Case': 'invalid-model'},
      ),
    );
    addTearDown(server.close);
    final result = await StreamingApi(server).getItems();
    final events = await requireSuccess(result).value.toList();
    expect(events, hasLength(1));
    final failure = events.single as TonikError<ItemsGet200BodyModel, Object>;
    expect(failure.error, isA<InvalidTypeException>());
    expect(failure.type, TonikErrorType.decoding);
  });

  test(
    'mixed stream preserves headers, variants, copyWith and metadata',
    () async {
      final server = CustomServer(baseUrl: baseUrl);
      addTearDown(server.close);
      final result = await StreamingApi(server).getMixed();
      final status = requireSuccess(result).value as GetMixedResponse200;
      final response = status.body as MixedGet200ResponseXNdjson;
      expect(response.xCount, 2);
      final replacement = response.body.map((item) => item);
      final copied = response.copyWith(xCount: 3, body: replacement);
      expect(copied.xCount, 3);
      expect(copied.body, same(replacement));
      expect(response.copyWith().body, same(response.body));
      final native = (result as TonikSuccess).response;
      if (native is http.BaseResponse) {
        expect(result, isA<TonikResult<GetMixedResponse, http.BaseResponse>>());
        expect(native, isA<http.StreamedResponse>());
        expect(native.headers['x-count'], '2');
      } else {
        expect(
          result,
          isA<TonikResult<GetMixedResponse, dio.Response<Object?>>>(),
        );
        expect(native, isA<dio.Response<Object?>>());
      }
      final items = response.body
          .map((item) => requireSuccess(item).value)
          .toList();
      expect(await items, [
        const StreamItem(value: 1),
        const StreamItem(value: 2),
      ]);
    },
  );

  test('mixed complete JSON exposes completed metadata', () async {
    final server = CustomServer(
      baseUrl: baseUrl,
      serverConfig: testServerConfig(headers: {'X-Response-Case': 'json'}),
    );
    addTearDown(server.close);
    final result = await StreamingApi(server).getMixed();
    final status = requireSuccess(result).value as GetMixedResponse200;
    final response = status.body as MixedGet200ResponseJson;
    expect(response.xCount, 1);
    expect(response.body, const StreamItem(value: 9));
    expect(response.copyWith(xCount: 2).xCount, 2);
    final native = (result as TonikSuccess).response;
    if (native is http.BaseResponse) {
      expect(native, isA<http.Response>());
      expect((native as http.Response).body, '{"value":9}');
      expect(result, isA<TonikResult<GetMixedResponse, http.BaseResponse>>());
    } else {
      expect(
        (native as dio.Response<Object?>).data,
        utf8.encode('{"value":9}'),
      );
    }
  });

  test(
    'component response aliases retain the stream and modeled header',
    () async {
      final server = CustomServer(baseUrl: baseUrl);
      addTearDown(server.close);
      final result = await StreamingApi(server).getAliasedStream();
      // The explicit type checks the exported response alias at compile time.
      // ignore: omit_local_variable_types
      final AliasedStream response = requireSuccess(result).value;
      expect(response, isA<StreamWithHeaders>());
      expect(response.xCount, 1);
      final replacement = response.body.map((item) => item);
      final copied = response.copyWith(body: replacement);
      expect(copied, AliasedStream(xCount: 1, body: replacement));
      expect(
        copied.hashCode,
        AliasedStream(xCount: 1, body: replacement).hashCode,
      );
      final items = response.body
          .map((item) => requireSuccess(item).value)
          .toList();
      expect(await items, [const StreamItem(value: 6)]);
    },
  );

  test(
    'parameter-specific item stream overrides multipart content mapping',
    () async {
      final server = CustomServer(baseUrl: baseUrl);
      addTearDown(server.close);
      final result = await StreamingApi(server).getProfiles();
      final response =
          requireSuccess(result).value
              as ProfilesGet200ResponseXNdjsonProfileDetail;
      final items = response.body
          .map((item) => requireSuccess(item).value)
          .toList();
      expect(await items, [const StreamItem(value: 4)]);
    },
  );

  test(
    'unmatched media parameters select the generic complete variant',
    () async {
      final server = CustomServer(
        baseUrl: baseUrl,
        serverConfig: testServerConfig(
          headers: {'X-Response-Case': 'other-profile'},
        ),
      );
      addTearDown(server.close);
      final result = await StreamingApi(server).getProfiles();
      final response =
          requireSuccess(result).value as ProfilesGet200ResponseXNdjson;
      expect((response.body as TonikFileBytes).bytes, [49, 10]);
      final native = (result as TonikSuccess).response;
      if (native is http.BaseResponse) expect(native, isA<http.Response>());
    },
  );

  test('explicit empty status wins over range', () async {
    final server = CustomServer(
      baseUrl: baseUrl,
      serverConfig: testServerConfig(headers: {'X-Response-Case': 'empty'}),
    );
    addTearDown(server.close);
    final result = await StreamingApi(server).getMixed();
    expect(requireSuccess(result).value, const GetMixedResponse204());
    expect(requireSuccess(result).response.statusCode, 204);
  });

  test('bad modeled header returns an operation error', () async {
    final server = CustomServer(
      baseUrl: baseUrl,
      serverConfig: testServerConfig(
        headers: {'X-Response-Case': 'invalid-header'},
      ),
    );
    addTearDown(server.close);
    final result = await StreamingApi(server).getAliasedStream();
    final error = requireError(result);
    expect(error.type, TonikErrorType.decoding);
    expect(error.error, isA<InvalidTypeException>());
    expect(error.response!.headers.value('x-count'), 'invalid');
  });

  test(
    'ordinary modeled HTTP error keeps its explicit status variant',
    () async {
      final server = CustomServer(
        baseUrl: baseUrl,
        serverConfig: testServerConfig(
          headers: {'X-Response-Case': 'bad-request'},
        ),
      );
      addTearDown(server.close);
      final result = await StreamingApi(server).getMixed();
      expect(
        requireSuccess(result).value,
        const GetMixedResponse400(body: 'invalid request'),
      );
      expect(requireSuccess(result).response.statusCode, 400);
      final native = (result as TonikSuccess).response;
      if (native is http.BaseResponse) expect(native, isA<http.Response>());
    },
  );

  test('range status returns its own typed stream variant', () async {
    final server = CustomServer(
      baseUrl: baseUrl,
      serverConfig: testServerConfig(headers: {'X-Response-Case': 'range'}),
    );
    addTearDown(server.close);
    final result = await StreamingApi(server).getMixed();
    final response = requireSuccess(result).value as GetMixedResponse2XX;
    final items = response.body
        .map((item) => requireSuccess(item).value)
        .toList();
    expect(await items, [const StreamItem(value: 2)]);
  });

  test('unmatched status selects the complete default variant', () async {
    final server = CustomServer(
      baseUrl: baseUrl,
      serverConfig: testServerConfig(headers: {'X-Response-Case': 'default'}),
    );
    addTearDown(server.close);
    final result = await StreamingApi(server).getMixed();
    expect(
      requireSuccess(result).value,
      const GetMixedResponseDefault(body: 'teapot'),
    );
  });

  test(
    'malformed mixed stream terminates without selecting complete JSON',
    () async {
      final server = CustomServer(
        baseUrl: baseUrl,
        serverConfig: testServerConfig(
          headers: {'X-Response-Case': 'malformed'},
        ),
      );
      addTearDown(server.close);
      final result = await StreamingApi(server).getMixed();
      final status = requireSuccess(result).value as GetMixedResponse200;
      final response = status.body as MixedGet200ResponseXNdjson;
      final events = await response.body.toList();
      expect(events, hasLength(1));
      final failure = events.single as TonikError<Object?, Object>;
      expect(failure.error, isA<FormatException>());
      expect(failure.type, TonikErrorType.decoding);
    },
  );

  test('referenced media chain returns typed items', () async {
    final server = CustomServer(baseUrl: baseUrl);
    addTearDown(server.close);
    final result = await StreamingApi(server).getReferencedStream();
    final items = requireSuccess(result).value
        .map((item) => requireSuccess(item).value)
        .toList();
    expect(await items, [
      const StreamItem(value: 11),
      const StreamItem(value: 12),
    ]);
  });

  test('referenced mixed content selects its item stream', () async {
    final server = CustomServer(baseUrl: baseUrl);
    addTearDown(server.close);
    final result = await StreamingApi(server).getReferencedMixed();
    final response =
        requireSuccess(result).value as ReferencedMixedGet200ResponseXNdjson;
    final items = response.body
        .map((item) => requireSuccess(item).value)
        .toList();
    expect(await items, [const StreamItem(value: 13)]);
  });

  test('referenced mixed content selects its complete JSON', () async {
    final server = CustomServer(
      baseUrl: baseUrl,
      serverConfig: testServerConfig(headers: {'X-Response-Case': 'json'}),
    );
    addTearDown(server.close);
    final result = await StreamingApi(server).getReferencedMixed();
    final response =
        requireSuccess(result).value as ReferencedMixedGet200ResponseJson;
    expect(response.body, const StreamItem(value: 14));
    final native = (result as TonikSuccess).response;
    if (native is http.BaseResponse) expect(native, isA<http.Response>());
  });

  test('external media alternative keeps complete byte fallback', () async {
    final server = CustomServer(
      baseUrl: baseUrl,
      serverConfig: testServerConfig(headers: {'X-Response-Case': 'external'}),
    );
    addTearDown(server.close);
    final result = await StreamingApi(server).getReferencedMixed();
    final response =
        requireSuccess(result).value as ReferencedMixedGet200ResponseJsonl;
    expect((response.body as TonikFileBytes).bytes, [49, 10, 50, 10]);
    final native = (result as TonikSuccess).response;
    if (native is http.BaseResponse) expect(native, isA<http.Response>());
  });

  test('finite schema-only NDJSON retains byte decoding', () async {
    final server = CustomServer(baseUrl: baseUrl);
    addTearDown(server.close);
    final result = await StreamingApi(server).getSchemaOnly();
    expect((requireSuccess(result).value as TonikFileBytes).bytes, [
      49,
      10,
      50,
      10,
    ]);
  });

  test(
    'referenced request media keeps ordinary complete JSON encoding',
    () async {
      final server = CustomServer(baseUrl: baseUrl);
      addTearDown(server.close);
      final result = await StreamingApi(server)
          .postReferencedRequest(body: const StreamItem(value: 15));
      expect(requireSuccess(result).value, const StreamItem(value: 15));
      final request = await imposterServer.takeRequest();
      expect(request.method, 'POST');
      expect(request.uri.path, '/referenced-request');
      expect(
        request.headers['content-type']!.split(';').first.trim(),
        'application/json',
      );
      expect(jsonDecode(request.body!), {'value': 15});
    },
  );

  test('nullable scalar items keep nullability inside the stream', () async {
    final server = CustomServer(baseUrl: baseUrl);
    addTearDown(server.close);
    final result = await StreamingApi(server).getNullableItems();
    // The explicit type checks the generated public item type at compile time.
    final Stream<TonikResult<int?, Object>> items = requireSuccess(result)
        .value;
    final values = items.map((item) => requireSuccess(item).value).toList();
    expect(await values, [1, null, 2]);
  });

  test('unconstrained items preserve all JSON value shapes', () async {
    final server = CustomServer(baseUrl: baseUrl);
    addTearDown(server.close);
    final result = await StreamingApi(server).getAnyItems();
    // The explicit type checks the generated public item type at compile time.
    final Stream<TonikResult<Object?, Object>> items = requireSuccess(result)
        .value;
    final values = items.map((item) => requireSuccess(item).value).toList();
    expect(await values, [
      null,
      3,
      'text',
      true,
      [1],
      {'key': 2},
    ]);
  });

  test('an impossible item schema permits an empty stream', () async {
    final server = CustomServer(
      baseUrl: baseUrl,
      serverConfig: testServerConfig(headers: {'X-Response-Case': 'empty'}),
    );
    addTearDown(server.close);
    final result = await StreamingApi(server).getNeverItems();
    // The explicit type checks the generated public item type at compile time.
    final Stream<TonikResult<Never, Object>> items = requireSuccess(result)
        .value;
    final values = items.toList();
    expect(await values, isEmpty);
  });

  test('an impossible item terminates conversion', () async {
    final server = CustomServer(
      baseUrl: baseUrl,
      serverConfig: testServerConfig(
        headers: {'X-Response-Case': 'invalid-item'},
      ),
    );
    addTearDown(server.close);
    final result = await StreamingApi(server).getNeverItems();
    final events = await requireSuccess(result).value.toList();
    expect(events, hasLength(1));
    final failure = events.single as TonikError<Never, Object>;
    expect(failure.error, isA<JsonDecodingException>());
    expect(failure.type, TonikErrorType.decoding);
  });

  test('referenced item aliases preserve nested normalized models', () async {
    final server = CustomServer(baseUrl: baseUrl);
    addTearDown(server.close);
    final result = await StreamingApi(server).getNestedItems();
    // The explicit type checks the generated public item type at compile time.
    final Stream<TonikResult<StreamBatchAlias, Object>> items = requireSuccess(
      result,
    ).value;
    final values = items.map((item) => requireSuccess(item).value).toList();
    expect(await values, [
      [
        const NestedStreamItem(
          streamItem: StreamItem(value: 4),
          nestedStreamItemModel: NestedStreamItemModel(
            metrics: {
              'scores': [2, 3],
            },
          ),
        ),
      ],
      <NestedStreamItem>[],
    ]);
  });

  test('application-error union members are ordinary stream items', () async {
    final server = CustomServer(baseUrl: baseUrl);
    addTearDown(server.close);
    final cancellation = TonikCancellation();
    final result = await StreamingApi(server)
        .getEvents(cancellation: cancellation);
    final response =
        requireSuccess(result).value as EventsGet200ResponseXNdjson;
    // The explicit type checks the generated public item type at compile time.
    final Stream<TonikResult<StreamEvent, Object>> items = response.body;
    final values = items.map((item) => requireSuccess(item).value).toList();
    expect(await values, [
      const StreamEventStateEvent(
        StateEvent(kind: StateEventKindModel.state, progress: 25),
      ),
      const StreamEventApplicationErrorEvent(
        ApplicationErrorEvent(
          kind: ApplicationErrorEventKindModel.error,
          message: 'try again',
        ),
      ),
      const StreamEventResultEvent(
        ResultEvent(kind: ResultEventKindModel.result, result: 'finished'),
      ),
    ]);
    expect(cancellation.isCancelled, isFalse);
  });

  test('a real union conversion failure ends consumption', () async {
    final server = CustomServer(
      baseUrl: baseUrl,
      serverConfig: testServerConfig(
        headers: {'X-Response-Case': 'invalid-union'},
      ),
    );
    addTearDown(server.close);
    final result = await StreamingApi(server).getEvents();
    final response =
        requireSuccess(result).value as EventsGet200ResponseXNdjson;
    final events = await response.body.toList();
    expect(events, hasLength(2));
    expect(
      requireSuccess(events.first as TonikResult<StreamEvent, Object>).value,
      const StreamEventStateEvent(
        StateEvent(kind: StateEventKindModel.state, progress: 25),
      ),
    );
    final failure = events.last as TonikError<StreamEvent, Object>;
    expect(failure.error, isA<InvalidTypeException>());
    expect(failure.type, TonikErrorType.decoding);
  });

  test('the event operation retains its complete JSON model', () async {
    final server = CustomServer(
      baseUrl: baseUrl,
      serverConfig: testServerConfig(headers: {'X-Response-Case': 'json'}),
    );
    addTearDown(server.close);
    final result = await StreamingApi(server).getEvents();
    final response = requireSuccess(result).value as EventsGet200ResponseJson;
    expect(response.body, const StreamSummary(total: 3));
  });

  test('NDJSON media retains its distinct inline item model', () async {
    final server = CustomServer(baseUrl: baseUrl);
    addTearDown(server.close);
    final result = await StreamingApi(server).getAlternativeItems();
    final status =
        requireSuccess(result).value as GetAlternativeItemsResponse200;
    final response = status.body as AlternativeItemsGet200ResponseXNdjson;
    final values = response.body
        .map((item) => requireSuccess(item).value)
        .toList();
    expect(await values, [const AlternativeItemsGet200BodyModel(count: 5)]);
  });

  test('JSONL media retains its distinct inline item model', () async {
    final server = CustomServer(
      baseUrl: baseUrl,
      serverConfig: testServerConfig(headers: {'X-Response-Case': 'jsonl'}),
    );
    addTearDown(server.close);
    final result = await StreamingApi(server).getAlternativeItems();
    final status =
        requireSuccess(result).value as GetAlternativeItemsResponse200;
    final response = status.body as AlternativeItemsGet200ResponseJsonl;
    final values = response.body
        .map((item) => requireSuccess(item).value)
        .toList();
    expect(await values, [
      const AlternativeItemsGet200BodyModel2(label: 'named'),
    ]);
  });

  test('another status retains its distinct inline item model', () async {
    final server = CustomServer(
      baseUrl: baseUrl,
      serverConfig: testServerConfig(headers: {'X-Response-Case': 'accepted'}),
    );
    addTearDown(server.close);
    final result = await StreamingApi(server).getAlternativeItems();
    final response =
        requireSuccess(result).value as GetAlternativeItemsResponse202;
    final values = response.body
        .map((item) => requireSuccess(item).value)
        .toList();
    expect(await values, [const AlternativeItemsGet202BodyModel(ready: true)]);
  });
}
