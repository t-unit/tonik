import 'package:boolean_schemas_api/boolean_schemas_api.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  const port = 8087;
  const baseUrl = 'http://localhost:$port';

  late ImposterServer imposterServer;

  setUpAll(() async {
    imposterServer = ImposterServer(port: port);
    await setupImposterServer(imposterServer);
  });

  BooleanSchemasApi buildApi({String responseStatus = '200'}) {
    return BooleanSchemasApi(
      CustomServer(
        baseUrl: baseUrl,
        serverConfig: ServerConfig(
          baseOptions: BaseOptions(
            headers: {'X-Response-Status': responseStatus},
          ),
        ),
      ),
    );
  }

  group('Query parameters - list of any values (form style)', () {
    test('getQueryListAny with string values (explode=true)', () async {
      final api = buildApi();
      final result = await api.getQueryListAny(anyValues: ['a', 'b', 'c']);
      final success = result as TonikSuccess<QueryListAnyGet200BodyModel>;
      expect(success.response.statusCode, 200);
      expect(
        success.response.requestOptions.uri.query,
        'anyValues=a&anyValues=b&anyValues=c',
      );
    });

    test('getQueryListAny with numeric values', () async {
      final api = buildApi();
      final result = await api.getQueryListAny(anyValues: [1, 2, 3]);
      final success = result as TonikSuccess<QueryListAnyGet200BodyModel>;
      expect(success.response.statusCode, 200);
      expect(
        success.response.requestOptions.uri.query,
        'anyValues=1&anyValues=2&anyValues=3',
      );
    });

    test('getQueryListAny with mixed primitive types', () async {
      final api = buildApi();
      final result = await api.getQueryListAny(
        anyValues: ['string', 42, true],
      );
      final success = result as TonikSuccess<QueryListAnyGet200BodyModel>;
      expect(success.response.statusCode, 200);
      expect(
        success.response.requestOptions.uri.query,
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
        final success =
            result as TonikSuccess<QueryListAnyNoExplodeGet200BodyModel>;
        expect(success.response.statusCode, 200);
        expect(
          success.response.requestOptions.uri.query,
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
        expect(result, isA<TonikError<QueryListAnyGet200BodyModel>>());
        final error = result as TonikError<QueryListAnyGet200BodyModel>;
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
        expect(result, isA<TonikError<QueryListAnyGet200BodyModel>>());
        final error = result as TonikError<QueryListAnyGet200BodyModel>;
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
          isA<TonikError<QuerySpaceDelimitedListAnyGet200BodyModel>>(),
        );
        final error =
            result as TonikError<QuerySpaceDelimitedListAnyGet200BodyModel>;
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
          isA<TonikError<QueryPipeDelimitedListAnyGet200BodyModel>>(),
        );
        final error =
            result as TonikError<QueryPipeDelimitedListAnyGet200BodyModel>;
        expect(error.error, isA<EncodingException>());
      },
    );
  });

  group('Path parameters - list of any values (simple style)', () {
    test('getPathListAny returns EncodingException', () async {
      final api = buildApi();
      final result = await api.getPathListAny(anyValues: ['a', 'b', 'c']);
      expect(result, isA<TonikError<PathListAnyAnyValuesGet200BodyModel>>());
      final error = result as TonikError<PathListAnyAnyValuesGet200BodyModel>;
      expect(error.error, isA<EncodingException>());
      expect(error.type, TonikErrorType.encoding);
    });

    test('getPathListAnyExplode returns EncodingException', () async {
      final api = buildApi();
      final result = await api.getPathListAnyExplode(anyValues: ['x', 'y']);
      expect(
        result,
        isA<TonikError<PathListAnyExplodeAnyValuesGet200BodyModel>>(),
      );
      final error =
          result as TonikError<PathListAnyExplodeAnyValuesGet200BodyModel>;
      expect(error.error, isA<EncodingException>());
      expect(error.type, TonikErrorType.encoding);
    });
  });

  group('Path parameters - list of any values (label style)', () {
    test('getPathLabelListAny with string values', () async {
      final api = buildApi();
      final result = await api.getPathLabelListAny(anyValues: ['a', 'b', 'c']);
      final success =
          result as TonikSuccess<PathLabelListAnyAnyValuesGet200BodyModel>;
      expect(success.response.statusCode, 200);
      expect(
        success.response.requestOptions.uri.path,
        '/path/label/list-any/.a,b,c',
      );
    });

    test('getPathLabelListAny with numeric values', () async {
      final api = buildApi();
      final result = await api.getPathLabelListAny(anyValues: [10, 20]);
      final success =
          result as TonikSuccess<PathLabelListAnyAnyValuesGet200BodyModel>;
      expect(success.response.statusCode, 200);
      expect(
        success.response.requestOptions.uri.path,
        '/path/label/list-any/.10,20',
      );
    });

    test('getPathLabelListAnyExplode with values', () async {
      final api = buildApi();
      final result = await api.getPathLabelListAnyExplode(
        anyValues: ['foo', 'bar'],
      );
      final success =
          result
              as TonikSuccess<PathLabelListAnyExplodeAnyValuesGet200BodyModel>;
      expect(success.response.statusCode, 200);
      expect(
        success.response.requestOptions.uri.path,
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
          isA<TonikError<PathLabelListAnyAnyValuesGet200BodyModel>>(),
        );
        final error =
            result as TonikError<PathLabelListAnyAnyValuesGet200BodyModel>;
        expect(error.error, isA<EncodingException>());
      },
    );
  });

  group('Path parameters - list of any values (matrix style)', () {
    test('getPathMatrixListAny with string values', () async {
      final api = buildApi();
      final result = await api.getPathMatrixListAny(anyValues: ['a', 'b']);
      final success =
          result as TonikSuccess<PathMatrixListAnyAnyValuesGet200BodyModel>;
      expect(success.response.statusCode, 200);
      expect(
        success.response.requestOptions.uri.path,
        '/path/matrix/list-any/;anyValues=a,b',
      );
    });

    test('getPathMatrixListAny with numeric values', () async {
      final api = buildApi();
      final result = await api.getPathMatrixListAny(anyValues: [1, 2, 3]);
      final success =
          result as TonikSuccess<PathMatrixListAnyAnyValuesGet200BodyModel>;
      expect(success.response.statusCode, 200);
      expect(
        success.response.requestOptions.uri.path,
        '/path/matrix/list-any/;anyValues=1,2,3',
      );
    });

    test('getPathMatrixListAnyExplode with values', () async {
      final api = buildApi();
      final result = await api.getPathMatrixListAnyExplode(
        anyValues: ['x', 'y'],
      );
      final success =
          result
              as TonikSuccess<PathMatrixListAnyExplodeAnyValuesGet200BodyModel>;
      expect(success.response.statusCode, 200);
      expect(
        success.response.requestOptions.uri.path,
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
          isA<TonikError<PathMatrixListAnyAnyValuesGet200BodyModel>>(),
        );
        final error =
            result as TonikError<PathMatrixListAnyAnyValuesGet200BodyModel>;
        expect(error.error, isA<EncodingException>());
      },
    );
  });

  group('Header parameters - list of any values', () {
    test('getHeaderListAny returns EncodingException', () async {
      final api = buildApi();
      final result = await api.getHeaderListAny(anyValues: ['a', 'b', 'c']);
      expect(result, isA<TonikError<HeaderListAnyGet200BodyModel>>());
      final error = result as TonikError<HeaderListAnyGet200BodyModel>;
      expect(error.error, isA<EncodingException>());
      expect(error.type, TonikErrorType.encoding);
    });

    test('getHeaderListAnyExplode returns EncodingException', () async {
      final api = buildApi();
      final result = await api.getHeaderListAnyExplode(
        anyValues: ['foo', 'bar'],
      );
      expect(result, isA<TonikError<HeaderListAnyExplodeGet200BodyModel>>());
      final error = result as TonikError<HeaderListAnyExplodeGet200BodyModel>;
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
          isA<TonikError<QueryObjectWithListAnyGet200BodyModel>>(),
        );
        final error =
            result as TonikError<QueryObjectWithListAnyGet200BodyModel>;
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
          isA<TonikError<QueryDeepObjectObjectWithListAnyGet200BodyModel>>(),
        );
        final error =
            result
                as TonikError<QueryDeepObjectObjectWithListAnyGet200BodyModel>;
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
        expect(result, isA<TonikError<FormListAnyPost200BodyModel>>());
        final error = result as TonikError<FormListAnyPost200BodyModel>;
        expect(error.error, isA<EncodingException>());
      },
    );
  });
}
