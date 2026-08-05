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

  group('Query parameters - list of any values (form style)', () {
    test('getQueryListAny with string values (explode=true)', () async {
      final api = buildApi();
      final result = await api.getQueryListAny(anyValues: ['a', 'b', 'c']);
      final success = requireSuccess(result);
      expect(success.response.statusCode, 200);
      final recordedRequest = await imposterServer.takeRequest();
      expect(
        recordedRequest.uri.query,
        'anyValues=a&anyValues=b&anyValues=c',
      );
    });

    test('getQueryListAny with numeric values', () async {
      final api = buildApi();
      final result = await api.getQueryListAny(anyValues: [1, 2, 3]);
      final success = requireSuccess(result);
      expect(success.response.statusCode, 200);
      final recordedRequest = await imposterServer.takeRequest();
      expect(
        recordedRequest.uri.query,
        'anyValues=1&anyValues=2&anyValues=3',
      );
    });

    test('getQueryListAny with mixed primitive types', () async {
      final api = buildApi();
      final result = await api.getQueryListAny(
        anyValues: ['string', 42, true],
      );
      final success = requireSuccess(result);
      expect(success.response.statusCode, 200);
      final recordedRequest = await imposterServer.takeRequest();
      expect(
        recordedRequest.uri.query,
        'anyValues=string&anyValues=42&anyValues=true',
      );
    });

    test(
      'getQueryListAnyNoExplode with string values (explode=false)',
      () async {
        final api = buildApi();
        final result = await api.getQueryListAnyNoExplode(
          anyValues: ['x', 'y', 'z'],
        );
        final success = requireSuccess(result);
        expect(success.response.statusCode, 200);
        final recordedRequest = await imposterServer.takeRequest();
        expect(
          recordedRequest.uri.query,
          'anyValues=x,y,z',
        );
      },
    );

    test(
      'getQueryListAny with nested list returns EncodingException',
      () async {
        final api = buildApi();
        // Nested lists cannot be encoded to URI
        final result = await api.getQueryListAny(
          anyValues: [
            ['nested', 'list'],
          ],
        );
        expect(
          result,
          isTonikError,
        );
        final error = requireError(result);
        expect(error.error, isA<EncodingException>());
        expect(error.type, TonikErrorType.encoding);
      },
    );

    test(
      'getQueryListAny with map element returns EncodingException',
      () async {
        final api = buildApi();
        final result = await api.getQueryListAny(
          anyValues: [
            {'key': 'value'},
          ],
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

  group('Query parameters - list of any values (spaceDelimited style)', () {
    test(
      'getQuerySpaceDelimitedListAny returns EncodingException',
      () async {
        final api = buildApi();
        final result = await api.getQuerySpaceDelimitedListAny(
          anyValues: ['a', 'b'],
        );
        // spaceDelimited style is not supported for arrays of AnyModel
        expect(
          result,
          isTonikError,
        );
        final error = requireError(result);
        expect(error.error, isA<EncodingException>());
      },
    );
  });

  group('Query parameters - list of any values (pipeDelimited style)', () {
    test(
      'getQueryPipeDelimitedListAny returns EncodingException',
      () async {
        final api = buildApi();
        final result = await api.getQueryPipeDelimitedListAny(
          anyValues: ['one', 'two'],
        );
        // pipeDelimited style is not supported for arrays of AnyModel
        expect(
          result,
          isTonikError,
        );
        final error = requireError(result);
        expect(error.error, isA<EncodingException>());
      },
    );
  });

  group('Path parameters - list of any values (simple style)', () {
    test('getPathListAny returns EncodingException', () async {
      final api = buildApi();
      final result = await api.getPathListAny(anyValues: ['a', 'b', 'c']);
      expect(
        result,
        isTonikError,
      );
      final error = requireError(result);
      expect(error.error, isA<EncodingException>());
      expect(error.type, TonikErrorType.encoding);
    });

    test('getPathListAnyExplode returns EncodingException', () async {
      final api = buildApi();
      final result = await api.getPathListAnyExplode(anyValues: ['x', 'y']);
      expect(
        result,
        isTonikError,
      );
      final error = requireError(result);
      expect(error.error, isA<EncodingException>());
      expect(error.type, TonikErrorType.encoding);
    });
  });

  group('Path parameters - list of any values (label style)', () {
    test('getPathLabelListAny with string values', () async {
      final api = buildApi();
      final result = await api.getPathLabelListAny(anyValues: ['a', 'b', 'c']);
      final success = requireSuccess(result);
      expect(success.response.statusCode, 200);
      final recordedRequest = await imposterServer.takeRequest();
      expect(
        recordedRequest.uri.path,
        '/path/label/list-any/.a,b,c',
      );
    });

    test('getPathLabelListAny with numeric values', () async {
      final api = buildApi();
      final result = await api.getPathLabelListAny(anyValues: [10, 20]);
      final success = requireSuccess(result);
      expect(success.response.statusCode, 200);
      final recordedRequest = await imposterServer.takeRequest();
      expect(
        recordedRequest.uri.path,
        '/path/label/list-any/.10,20',
      );
    });

    test('getPathLabelListAnyExplode with values', () async {
      final api = buildApi();
      final result = await api.getPathLabelListAnyExplode(
        anyValues: ['foo', 'bar'],
      );
      final success = requireSuccess(result);
      expect(success.response.statusCode, 200);
      final recordedRequest = await imposterServer.takeRequest();
      expect(
        recordedRequest.uri.path,
        '/path/label/list-any-explode/.foo.bar',
      );
    });

    test(
      'getPathLabelListAny with nested list returns EncodingException',
      () async {
        final api = buildApi();
        final result = await api.getPathLabelListAny(
          anyValues: [
            ['nested'],
          ],
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

  group('Path parameters - list of any values (matrix style)', () {
    test('getPathMatrixListAny with string values', () async {
      final api = buildApi();
      final result = await api.getPathMatrixListAny(anyValues: ['a', 'b']);
      final success = requireSuccess(result);
      expect(success.response.statusCode, 200);
      final recordedRequest = await imposterServer.takeRequest();
      expect(
        recordedRequest.uri.path,
        '/path/matrix/list-any/;anyValues=a,b',
      );
    });

    test('getPathMatrixListAny with numeric values', () async {
      final api = buildApi();
      final result = await api.getPathMatrixListAny(anyValues: [1, 2, 3]);
      final success = requireSuccess(result);
      expect(success.response.statusCode, 200);
      final recordedRequest = await imposterServer.takeRequest();
      expect(
        recordedRequest.uri.path,
        '/path/matrix/list-any/;anyValues=1,2,3',
      );
    });

    test('getPathMatrixListAnyExplode with values', () async {
      final api = buildApi();
      final result = await api.getPathMatrixListAnyExplode(
        anyValues: ['x', 'y'],
      );
      final success = requireSuccess(result);
      expect(success.response.statusCode, 200);
      final recordedRequest = await imposterServer.takeRequest();
      expect(
        recordedRequest.uri.path,
        '/path/matrix/list-any-explode/;anyValues=x;anyValues=y',
      );
    });

    test(
      'getPathMatrixListAny with nested list returns EncodingException',
      () async {
        final api = buildApi();
        final result = await api.getPathMatrixListAny(
          anyValues: [
            ['nested'],
          ],
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

  group('Header parameters - list of any values', () {
    test('getHeaderListAny returns EncodingException', () async {
      final api = buildApi();
      final result = await api.getHeaderListAny(anyValues: ['a', 'b', 'c']);
      expect(
        result,
        isTonikError,
      );
      final error = requireError(result);
      expect(error.error, isA<EncodingException>());
      expect(error.type, TonikErrorType.encoding);
    });

    test('getHeaderListAnyExplode returns EncodingException', () async {
      final api = buildApi();
      final result = await api.getHeaderListAnyExplode(
        anyValues: ['foo', 'bar'],
      );
      expect(
        result,
        isTonikError,
      );
      final error = requireError(result);
      expect(error.error, isA<EncodingException>());
      expect(error.type, TonikErrorType.encoding);
    });
  });

  group('Query parameters - object with list of any values', () {
    test(
      'getQueryObjectWithListAny returns EncodingException (complex type)',
      () async {
        final api = buildApi();
        const filter = ObjectWithListAny(
          name: 'test-filter',
          anyItems: ['item1', 'item2'],
        );
        final result = await api.getQueryObjectWithListAny(filter: filter);
        expect(
          result,
          isTonikError,
        );
        final error = requireError(result);
        expect(error.error, isA<EncodingException>());
      },
    );

    test(
      'getQueryDeepObjectWithListAny returns EncodingException',
      () async {
        final api = buildApi();
        const filter = ObjectWithListAny(
          name: 'deep-test',
          anyItems: ['a', 'b'],
        );
        final result = await api.getQueryDeepObjectWithListAny(filter: filter);
        expect(
          result,
          isTonikError,
        );
        final error = requireError(result);
        expect(error.error, isA<EncodingException>());
      },
    );
  });

  group('Form body - list of any values', () {
    test(
      'postFormListAny returns EncodingException (complex type)',
      () async {
        final api = buildApi();
        const body = FormWithListAny(
          name: 'form-test',
          anyItems: ['a', 'b', 'c'],
          count: 3,
        );
        final result = await api.postFormListAny(body: body);
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
