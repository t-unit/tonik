// Generated public choice names exceed the line limit.
// ignore_for_file: lines_longer_than_80_chars

import 'package:multipart_api/multipart_api.dart' as api;
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

typedef _NestedTextJson =
    api.NestedArrayFormValuesArrayMultipartChoicesValuesOneOfModelApplicationJsonChoice2;
typedef _NestedTextPlain =
    api.NestedArrayFormValuesArrayMultipartChoicesValuesOneOfModelTextPlainChoice1;
typedef _WildcardBody = api.MultipartWildcardTextCharsetPostBodyBodyModel;
typedef _OpaqueBody =
    api.MultipartOpaqueNestedMultipartPostBodyBodyMultipartModel;
typedef _OpaqueJson =
    api.MultipartOpaqueNestedMultipartPostBodyBodyPayloadMultipartChoicesPayloadOneOfModelApplicationJsonChoice1;
typedef _OpaqueMultipart =
    api.MultipartOpaqueNestedMultipartPostBodyBodyPayloadMultipartChoicesPayloadOneOfModelMultipartFormDataChoice2;
typedef _UnboundBody =
    api.MultipartOpaqueNestedMultipartUnboundPostBodyBodyMultipartModel;
typedef _UnboundJson =
    api.MultipartOpaqueNestedMultipartUnboundPostBodyBodyPayloadMultipartChoicesPayloadOneOfModelApplicationJsonChoice1;
typedef _UnboundMultipart =
    api.MultipartOpaqueNestedMultipartUnboundPostBodyBodyPayloadMultipartChoicesPayloadOneOfModelMultipartFormDataChoice2;
typedef _QuotedBody =
    api.MultipartOpaqueNestedMultipartQuotedProfilePostBodyBodyMultipartModel;
typedef _QuotedMultipart =
    api.MultipartOpaqueNestedMultipartQuotedProfilePostBodyBodyPayloadMultipartChoicesPayloadOneOfModelMultipartFormDataChoice2;
typedef _SubtypeBody =
    api.MultipartOpaqueMultipartSubtypeChoicesPostBodyBodyMultipartModel;
typedef _SubtypeMixed =
    api.MultipartOpaqueMultipartSubtypeChoicesPostBodyBodyMixedMultipartChoicesMixedOneOfModelMultipartMixedChoice2;
typedef _SubtypeRelated =
    api.MultipartOpaqueMultipartSubtypeChoicesPostBodyBodyRelatedMultipartChoicesRelatedOneOfModelMultipartRelatedChoice2;
typedef _SubtypeDeclared =
    api.MultipartOpaqueMultipartSubtypeChoicesPostBodyBodyDeclaredMultipartChoicesDeclaredOneOfModelMultipartMixedChoice2;

void main() {
  test('nullable referenced choices remain nullable in public input', () {
    const body = api.MultipartNullableMediaChoicesPostBodyBodyMultipartModel(
      value: null,
      values: null,
      marker: 'present',
    );

    expect(body.value, isNull);
    expect(body.values, isNull);
  });

  test('selected null text choice fails before a request is sent', () async {
    final server = await RawRequestServer.start();
    final client = api.MultipartApi(
      api.CustomServer(
        baseUrl: server.baseUrl,
        serverConfig: testServerConfig(),
      ),
    );

    final response = await client.postNullableMediaChoices(
      body: const api.MultipartNullableMediaChoicesPostBodyBodyMultipartModel(
        value: api.MultipartChoicesValueOneOfModel3MaybeText(null),
        values: null,
        marker: 'present',
      ),
    );

    final error = requireError(response);
    expect(error.type, TonikErrorType.encoding);
    expect(server.requestCount, 0);
  });

  test('merged null text choice fails before a request is sent', () async {
    final server = await RawRequestServer.start();
    final client = api.MultipartApi(
      api.CustomServer(
        baseUrl: server.baseUrl,
        serverConfig: testServerConfig(),
      ),
    );

    final response = await client.postNullableMergedMediaChoices(
      body: const api.NullableMediaChoicesAllOfMultipart(
        nullableMediaChoicesLeftMultipart:
            api.NullableMediaChoicesLeftMultipart(
              value: api.MultipartChoicesValueOneOfModelMaybeText(null),
            ),
        nullableMediaChoicesRightMultipart:
            api.NullableMediaChoicesRightMultipart(),
      ),
    );

    final error = requireError(response);
    expect(error.type, TonikErrorType.encoding);
    expect(
      (error.error as EncodingException).message,
      'Selected media choice for multipart property "value" is null.',
    );
    expect(server.requestCount, 0);
  });

  test('merged null JSON object choice fails before conversion', () async {
    final server = await RawRequestServer.start();
    final client = api.MultipartApi(
      api.CustomServer(
        baseUrl: server.baseUrl,
        serverConfig: testServerConfig(),
      ),
    );

    final response = await client.postNullableMergedMediaChoices(
      body: const api.NullableMediaChoicesAllOfMultipart(
        nullableMediaChoicesLeftMultipart:
            api.NullableMediaChoicesLeftMultipart(
              payload: api.MultipartChoicesPayloadOneOfModelMaybePayload(null),
            ),
        nullableMediaChoicesRightMultipart:
            api.NullableMediaChoicesRightMultipart(),
      ),
    );

    final error = requireError(response);
    expect(error.type, TonikErrorType.encoding);
    expect(
      (error.error as EncodingException).message,
      'Selected media choice for multipart property "payload" is null.',
    );
    expect(server.requestCount, 0);
  });

  test('OAS 3.0 explicit style takes precedence over media choices', () async {
    final server = await RawRequestServer.start();
    final client = api.MultipartApi(
      api.CustomServer(
        baseUrl: server.baseUrl,
        serverConfig: testServerConfig(),
      ),
    );

    final response = await client.postStyleOverMediaChoices(
      body: const api.MultipartStyleOverMediaChoicesPostBodyBodyModel(
        value: 'hello',
      ),
    );

    expect(response, isTonikSuccess);
    final part = MultipartWire(await server.takeRequest()).single('value');
    expect(part.bodyText, 'hello');
    expect(part.contentType, startsWith('text/plain'));
  });

  test('nested JSON choices keep one part per inner array', () async {
    final server = await RawRequestServer.start();
    final client = api.MultipartApi(
      api.CustomServer(
        baseUrl: server.baseUrl,
        serverConfig: testServerConfig(),
      ),
    );

    final response = await client.postNestedMediaTextChoices(
      body: const api.NestedArrayFormMultipart(
        values: [
          _NestedTextJson([1, 2]),
          _NestedTextJson([3]),
        ],
      ),
    );

    expect(response, isTonikSuccess);
    final parts = MultipartWire(await server.takeRequest()).named('values');
    expect(parts, hasLength(2));
    expect(parts[0].bodyText, '[1,2]');
    expect(parts[0].contentType, startsWith('application/json'));
    expect(parts[1].bodyText, '[3]');
    expect(parts[1].contentType, startsWith('application/json'));
  });

  test('nested text choice fails before a request is sent', () async {
    final server = await RawRequestServer.start();
    final client = api.MultipartApi(
      api.CustomServer(
        baseUrl: server.baseUrl,
        serverConfig: testServerConfig(),
      ),
    );

    final response = await client.postNestedMediaTextChoices(
      body: const api.NestedArrayFormMultipart(
        values: [
          _NestedTextPlain([1, 2]),
        ],
      ),
    );

    final error = requireError(response);
    expect(error.type, TonikErrorType.encoding);
    expect(
      (error.error as EncodingException).message,
      'Multipart property "values" cannot encode a nested array as text/plain.',
    );
    expect(server.requestCount, 0);
  });

  test('wildcard-only text encoding uses a concrete default', () async {
    final server = await RawRequestServer.start();
    final client = api.MultipartApi(
      api.CustomServer(
        baseUrl: server.baseUrl,
        serverConfig: testServerConfig(),
      ),
    );

    final response = await client.postWildcardTextCharset(
      body: const _WildcardBody(message: 'über'),
    );

    expect(response, isTonikSuccess);
    final part = MultipartWire(await server.takeRequest()).single('message');
    expect(part.bodyBytes, [195, 188, 98, 101, 114]);
    expect(part.contentType, startsWith('text/plain'));
  });

  test(
    'nested multipart alternative carries opaque bytes and boundary',
    () async {
      final server = await RawRequestServer.start();
      final client = api.MultipartApi(
        api.CustomServer(
          baseUrl: server.baseUrl,
          serverConfig: testServerConfig(),
        ),
      );

      final response = await client.postOpaqueNestedMultipart(
        body: const _OpaqueBody(
          payload: _OpaqueMultipart(TonikFileBytes([0, 255, 1])),
        ),
      );

      expect(response, isTonikSuccess);
      final part = MultipartWire(await server.takeRequest()).single('payload');
      expect(part.bodyBytes, [0, 255, 1]);
      expect(part.contentType, 'multipart/form-data; boundary=inner');
    },
  );

  test('nested multipart choice keeps its JSON alternative', () async {
    final server = await RawRequestServer.start();
    final client = api.MultipartApi(
      api.CustomServer(
        baseUrl: server.baseUrl,
        serverConfig: testServerConfig(),
      ),
    );

    final response = await client.postOpaqueNestedMultipart(
      body: const _OpaqueBody(
        payload: _OpaqueJson(
          api.MultipartOpaqueNestedMultipartPostBodyBodyPayloadModel(
            message: 'hello',
          ),
        ),
      ),
    );

    expect(response, isTonikSuccess);
    final part = MultipartWire(await server.takeRequest()).single('payload');
    expect(part.bodyText, '{"message":"hello"}');
    expect(part.contentType, startsWith('application/json'));
  });

  test(
    'unbound nested multipart uses caller boundary and opaque bytes',
    () async {
      final server = await RawRequestServer.start();
      final client = api.MultipartApi(
        api.CustomServer(
          baseUrl: server.baseUrl,
          serverConfig: testServerConfig(),
        ),
      );

      final response = await client.postOpaqueNestedMultipartUnbound(
        body: const _UnboundBody(
          payload: _UnboundMultipart(
            TonikFileBytes([0, 255, 1]),
            'multipart/form-data; boundary=caller',
          ),
        ),
      );

      expect(response, isTonikSuccess);
      final part = MultipartWire(await server.takeRequest()).single('payload');
      expect(part.bodyBytes, [0, 255, 1]);
      expect(part.contentType, 'multipart/form-data; boundary=caller');
    },
  );

  test(
    'unbound nested multipart rejects missing boundary before sending',
    () async {
      final server = await RawRequestServer.start();
      final client = api.MultipartApi(
        api.CustomServer(
          baseUrl: server.baseUrl,
          serverConfig: testServerConfig(),
        ),
      );

      final response = await client.postOpaqueNestedMultipartUnbound(
        body: const _UnboundBody(
          payload: _UnboundMultipart(
            TonikFileBytes([1]),
            'multipart/form-data',
          ),
        ),
      );

      final error = requireError(response);
      expect(error.type, TonikErrorType.encoding);
      expect(error.error, isA<EncodingException>());
      expect(server.requestCount, 0);
    },
  );

  test('unbound nested multipart keeps its JSON alternative', () async {
    final server = await RawRequestServer.start();
    final client = api.MultipartApi(
      api.CustomServer(
        baseUrl: server.baseUrl,
        serverConfig: testServerConfig(),
      ),
    );

    final response = await client.postOpaqueNestedMultipartUnbound(
      body: const _UnboundBody(
        payload: _UnboundJson(
          api.MultipartOpaqueNestedMultipartUnboundPostBodyBodyPayloadModel(
            message: 'hello',
          ),
        ),
      ),
    );

    expect(response, isTonikSuccess);
    final part = MultipartWire(await server.takeRequest()).single('payload');
    expect(part.bodyText, '{"message":"hello"}');
    expect(part.contentType, startsWith('application/json'));
  });

  test('quoted boundary text still requires a caller boundary', () async {
    final server = await RawRequestServer.start();
    final client = api.MultipartApi(
      api.CustomServer(
        baseUrl: server.baseUrl,
        serverConfig: testServerConfig(),
      ),
    );

    final response = await client.postOpaqueNestedMultipartQuotedProfile(
      body: const _QuotedBody(
        payload: _QuotedMultipart(
          TonikFileBytes([0, 255, 1]),
          'multipart/form-data; profile="x;boundary=inner"; boundary=caller',
        ),
      ),
    );

    expect(response, isTonikSuccess);
    final part = MultipartWire(await server.takeRequest()).single('payload');
    expect(part.bodyBytes, [0, 255, 1]);
    expect(extractMediaType(part.contentType), 'multipart/form-data');
    expect(parseMediaTypeParameters(part.contentType), {
      'profile': 'x;boundary=inner',
      'boundary': 'caller',
    });
  });

  test('quoted boundary text alone fails before sending', () async {
    final server = await RawRequestServer.start();
    final client = api.MultipartApi(
      api.CustomServer(
        baseUrl: server.baseUrl,
        serverConfig: testServerConfig(),
      ),
    );

    final response = await client.postOpaqueNestedMultipartQuotedProfile(
      body: const _QuotedBody(
        payload: _QuotedMultipart(
          TonikFileBytes([1]),
          'multipart/form-data; profile="x;boundary=inner"',
        ),
      ),
    );

    final error = requireError(response);
    expect(error.type, TonikErrorType.encoding);
    expect(error.error, isA<EncodingException>());
    expect(server.requestCount, 0);
  });

  test('opaque multipart subtypes use concrete boundaries', () async {
    final server = await RawRequestServer.start();
    final client = api.MultipartApi(
      api.CustomServer(
        baseUrl: server.baseUrl,
        serverConfig: testServerConfig(),
      ),
    );

    final response = await client.postOpaqueMultipartSubtypeChoices(
      body: const _SubtypeBody(
        mixed: _SubtypeMixed(
          TonikFileBytes([1]),
          'multipart/mixed; boundary=mixed',
        ),
        related: _SubtypeRelated(
          TonikFileBytes([2]),
          'multipart/related; boundary=related',
        ),
        range: 'fallback',
        declared: _SubtypeDeclared(TonikFileBytes([4])),
      ),
    );

    expect(response, isTonikSuccess);
    final wire = MultipartWire(await server.takeRequest());
    expect(wire.single('mixed').bodyBytes, [1]);
    expect(wire.single('mixed').contentType, 'multipart/mixed; boundary=mixed');
    expect(wire.single('related').bodyBytes, [2]);
    expect(
      wire.single('related').contentType,
      'multipart/related; boundary=related',
    );
    expect(wire.single('range').bodyText, '"fallback"');
    expect(wire.single('range').contentType, startsWith('application/json'));
    expect(wire.single('declared').bodyBytes, [4]);
    expect(
      wire.single('declared').contentType,
      'multipart/mixed; boundary=inner',
    );
  });

  test('opaque mixed rejects a missing boundary before sending', () async {
    final server = await RawRequestServer.start();
    final client = api.MultipartApi(
      api.CustomServer(
        baseUrl: server.baseUrl,
        serverConfig: testServerConfig(),
      ),
    );

    final response = await client.postOpaqueMultipartSubtypeChoices(
      body: const _SubtypeBody(
        mixed: _SubtypeMixed(TonikFileBytes([1]), 'multipart/mixed'),
      ),
    );

    final error = requireError(response);
    expect(error.type, TonikErrorType.encoding);
    expect(server.requestCount, 0);
  });

  test('opaque related rejects a missing boundary before sending', () async {
    final server = await RawRequestServer.start();
    final client = api.MultipartApi(
      api.CustomServer(
        baseUrl: server.baseUrl,
        serverConfig: testServerConfig(),
      ),
    );

    final response = await client.postOpaqueMultipartSubtypeChoices(
      body: const _SubtypeBody(
        related: _SubtypeRelated(TonikFileBytes([2]), 'multipart/related'),
      ),
    );

    final error = requireError(response);
    expect(error.type, TonikErrorType.encoding);
    expect(server.requestCount, 0);
  });
}
