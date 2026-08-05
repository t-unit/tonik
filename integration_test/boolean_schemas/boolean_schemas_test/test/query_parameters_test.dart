import 'package:boolean_schemas_api/boolean_schemas_api.dart';
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

  BooleanSchemasApi buildApi({String responseStatus = '200'}) {
    return BooleanSchemasApi(
      CustomServer(
        baseUrl: baseUrl,
        serverConfig: testServerConfig(
          headers: {'X-Response-Status': responseStatus},
        ),
      ),
    );
  }

  group('Query parameters - form style', () {
    test('getQueryAny with string value (explode=true)', () async {
      final api = buildApi();
      final result = await api.getQueryAny(anyValue: 'query-test');
      final success = requireSuccess(result);
      expect(success.response.statusCode, 200);
    });

    test('getQueryAny with number value', () async {
      final api = buildApi();
      final result = await api.getQueryAny(anyValue: 42);
      final success = requireSuccess(result);
      expect(success.response.statusCode, 200);
    });

    test('getQueryAny with boolean value', () async {
      final api = buildApi();
      final result = await api.getQueryAny(anyValue: false);
      final success = requireSuccess(result);
      expect(success.response.statusCode, 200);
    });

    test('getQueryAnyNoExplode with string value (explode=false)', () async {
      final api = buildApi();
      final result = await api.getQueryAnyNoExplode(anyValue: 'no-explode');
      final success = requireSuccess(result);
      expect(success.response.statusCode, 200);
    });

    test('getQueryAnyNoExplode with number value', () async {
      final api = buildApi();
      final result = await api.getQueryAnyNoExplode(anyValue: 999);
      final success = requireSuccess(result);
      expect(success.response.statusCode, 200);
    });

    test(
      'getQueryAnyNoExplode percent-encodes object keys, commas literal',
      () async {
        final api = buildApi();
        final result = await api.getQueryAnyNoExplode(
          anyValue: <String, dynamic>{
            'first name': 'Jane',
            'a,b': 'v1',
            'c&d': 'v2',
          },
        );
        requireSuccess(result);
        final recordedRequest = await imposterServer.takeRequest();
        expect(
          recordedRequest.uri.query,
          'anyValue=first%20name,Jane,a%2Cb,v1,c%26d,v2',
        );
      },
    );

    test('getQueryAny with empty list value omits the parameter', () async {
      final api = buildApi();
      final result = await api.getQueryAny(anyValue: const <dynamic>[]);
      requireSuccess(result);
      final recordedRequest = await imposterServer.takeRequest();
      expect(recordedRequest.uri.query, '');
    });

    test(
      'getQueryAnyNoExplode with empty list value omits the parameter',
      () async {
        final api = buildApi();
        final result = await api.getQueryAnyNoExplode(
          anyValue: const <dynamic>[],
        );
        requireSuccess(result);
        final recordedRequest = await imposterServer.takeRequest();
        expect(recordedRequest.uri.query, '');
      },
    );

    test(
      'getQueryAny with non-empty list serializes comma-separated',
      () async {
        final api = buildApi();
        final result = await api.getQueryAny(
          anyValue: <dynamic>['a', 'b', 'c'],
        );
        requireSuccess(result);
        final recordedRequest = await imposterServer.takeRequest();
        expect(recordedRequest.uri.query, 'anyValue=a,b,c');
      },
    );
  });

  group('Query parameters - spaceDelimited style', () {
    test(
      'getQuerySpaceDelimitedAny with string returns TonikError',
      () async {
        final api = buildApi();
        final result = await api.getQuerySpaceDelimitedAny(
          anyValue: 'space-delimited',
        );
        expect(
          result,
          isTonikError,
        );
        final error = requireError(result);
        expect(error.error, isA<EncodingException>());
      },
    );

    test(
      'getQuerySpaceDelimitedAny with list encodes as space-delimited',
      () async {
        final api = buildApi();
        final result = await api.getQuerySpaceDelimitedAny(
          anyValue: ['a', 'b', 'c'],
        );
        expect(
          result,
          isTonikSuccess,
        );
        requireSuccess(result);
        final recordedRequest = await imposterServer.takeRequest();
        expect(
          recordedRequest.uri.query,
          'anyValue=a%20b%20c',
        );
      },
    );

    test(
      'getQuerySpaceDelimitedAny with map encodes as space-delimited',
      () async {
        final api = buildApi();
        final result = await api.getQuerySpaceDelimitedAny(
          anyValue: <String, dynamic>{'a': 1, 'b': 2},
        );
        expect(
          result,
          isTonikSuccess,
        );
        requireSuccess(result);
        final recordedRequest = await imposterServer.takeRequest();
        expect(
          recordedRequest.uri.query,
          'anyValue=a%201%20b%202',
        );
      },
    );

    test(
      'getQuerySpaceDelimitedAnyExplode with string returns TonikError',
      () async {
        final api = buildApi();
        final result = await api.getQuerySpaceDelimitedAnyExplode(
          anyValue: 'space-explode',
        );
        expect(
          result,
          isTonikError,
        );
        final error = requireError(result);
        expect(error.error, isA<EncodingException>());
      },
    );

    test(
      'getQuerySpaceDelimitedAnyExplode with list returns TonikError',
      () async {
        final api = buildApi();
        final result = await api.getQuerySpaceDelimitedAnyExplode(
          anyValue: ['x', 'y', 'z'],
        );
        expect(
          result,
          isTonikError,
        );
        final error = requireError(result);
        expect(error.error, isA<EncodingException>());
      },
    );
  });

  group('Query parameters - pipeDelimited style', () {
    test(
      'getQueryPipeDelimitedAny with string returns TonikError',
      () async {
        final api = buildApi();
        final result = await api.getQueryPipeDelimitedAny(
          anyValue: 'pipe-delimited',
        );
        expect(
          result,
          isTonikError,
        );
        final error = requireError(result);
        expect(error.error, isA<EncodingException>());
      },
    );

    test(
      'getQueryPipeDelimitedAny with list encodes as pipe-delimited',
      () async {
        final api = buildApi();
        final result = await api.getQueryPipeDelimitedAny(
          anyValue: ['one', 'two', 'three'],
        );
        expect(
          result,
          isTonikSuccess,
        );
        requireSuccess(result);
        final recordedRequest = await imposterServer.takeRequest();
        expect(
          recordedRequest.uri.query,
          'anyValue=one%7Ctwo%7Cthree',
        );
      },
    );

    test(
      'getQueryPipeDelimitedAny with map encodes as pipe-delimited',
      () async {
        final api = buildApi();
        final result = await api.getQueryPipeDelimitedAny(
          anyValue: <String, dynamic>{'a': 1, 'b': 2},
        );
        expect(
          result,
          isTonikSuccess,
        );
        requireSuccess(result);
        final recordedRequest = await imposterServer.takeRequest();
        expect(
          recordedRequest.uri.query,
          'anyValue=a%7C1%7Cb%7C2',
        );
      },
    );

    test(
      'getQueryPipeDelimitedAnyExplode with string returns TonikError',
      () async {
        final api = buildApi();
        final result = await api.getQueryPipeDelimitedAnyExplode(
          anyValue: 'pipe-explode',
        );
        expect(
          result,
          isTonikError,
        );
        final error = requireError(result);
        expect(error.error, isA<EncodingException>());
      },
    );

    test(
      'getQueryPipeDelimitedAnyExplode with list returns TonikError',
      () async {
        final api = buildApi();
        final result = await api.getQueryPipeDelimitedAnyExplode(
          anyValue: ['foo', 'bar', 'baz'],
        );
        expect(
          result,
          isTonikError,
        );
        final error = requireError(result);
        expect(error.error, isA<EncodingException>());
      },
    );
  });

  group('Query parameters - deepObject style', () {
    test('getQueryDeepObjectAny with object value', () async {
      final api = buildApi();
      final result = await api.getQueryDeepObjectAny(
        anyValue: {'nested': 'value'},
      );
      final success = requireSuccess(result);
      expect(success.response.statusCode, 200);
    });

    test(
      'getQueryDeepObjectAny with string returns TonikError',
      () async {
        final api = buildApi();
        final result = await api.getQueryDeepObjectAny(anyValue: 'deep-object');
        expect(
          result,
          isTonikError,
        );
        final error = requireError(result);
        expect(error.error, isA<EncodingException>());
      },
    );
  });
}
