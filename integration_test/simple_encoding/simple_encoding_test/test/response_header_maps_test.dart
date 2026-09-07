import 'package:simple_encoding_api/simple_encoding_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  test('204 exploded object response header decodes successfully', () async {
    final server = await RawRequestServer.start(
      responseHeaders: {'X-Meta': 'role=admin,firstName=Alex'},
    );
    final api = SimpleEncodingApi(
      CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
    );

    final result = await api.testResponseHeaderMaps();
    final success = requireSuccess(result);

    expect(success.response.statusCode, 204);
    expect(success.value.xMeta, {'role': 'admin', 'firstName': 'Alex'});
    expect(success.value.xCounts, isNull);
  });

  test('non-exploded alias map decodes integer values', () async {
    final server = await RawRequestServer.start(
      responseHeaders: {'X-Counts': 'count,42,remaining,7'},
    );
    final api = SimpleEncodingApi(
      CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
    );

    final result = await api.testResponseHeaderMaps();
    final success = requireSuccess(result);

    expect(success.value.xCounts, {'count': 42, 'remaining': 7});
    expect(success.value.xMeta, isNull);
  });

  test('exploded maps decode boolean and enum values', () async {
    final server = await RawRequestServer.start(
      responseHeaders: {
        'X-Flags': 'enabled=true,archived=false',
        'X-Status': 'primary=active,secondary=pending',
      },
    );
    final api = SimpleEncodingApi(
      CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
    );

    final result = await api.testResponseHeaderMaps();
    final success = requireSuccess(result);

    expect(success.value.xFlags, {'enabled': true, 'archived': false});
    expect(success.value.xStatus, {
      'primary': StatusEnum.active,
      'secondary': StatusEnum.pending,
    });
  });

  test('all absent optional map headers decode as null', () async {
    final server = await RawRequestServer.start();
    final api = SimpleEncodingApi(
      CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
    );

    final result = await api.testResponseHeaderMaps();
    final success = requireSuccess(result);

    expect(success.value.xMeta, isNull);
    expect(success.value.xCounts, isNull);
    expect(success.value.xFlags, isNull);
    expect(success.value.xStatus, isNull);
  });

  test('malformed non-exploded map produces a contextual error', () async {
    final server = await RawRequestServer.start(
      responseHeaders: {'X-Counts': 'count,42,remaining'},
    );
    final api = SimpleEncodingApi(
      CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
    );

    final result = await api.testResponseHeaderMaps();
    final error = requireError(result);

    expect(error.type, TonikErrorType.decoding);
    expect(error.response?.statusCode, 204);
    expect(
      error.error,
      isA<InvalidFormatException>().having(
        (error) => error.format,
        'format',
        'alternating key-value pairs in X-Counts',
      ),
    );
  });

  test('invalid typed map value produces a contextual error', () async {
    final server = await RawRequestServer.start(
      responseHeaders: {'X-Counts': 'count,oops'},
    );
    final api = SimpleEncodingApi(
      CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
    );

    final result = await api.testResponseHeaderMaps();
    final error = requireError(result);

    expect(error.type, TonikErrorType.decoding);
    expect(
      error.error,
      isA<InvalidTypeException>()
          .having((error) => error.context, 'context', 'X-Counts')
          .having((error) => error.value, 'value', 'oops'),
    );
  });
}
