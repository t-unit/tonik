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

  group('Query parameters - form style', () {
    test('getQueryAny with string value (explode=true)', () async {
      final api = buildApi();
      final result = await api.getQueryAny(anyValue: 'query-test');
      final success = result as TonikSuccess;
      expect(success.response.statusCode, 200);
    });

    test('getQueryAny with number value', () async {
      final api = buildApi();
      final result = await api.getQueryAny(anyValue: 42);
      final success = result as TonikSuccess;
      expect(success.response.statusCode, 200);
    });

    test('getQueryAny with boolean value', () async {
      final api = buildApi();
      final result = await api.getQueryAny(anyValue: false);
      final success = result as TonikSuccess;
      expect(success.response.statusCode, 200);
    });

    test('getQueryAnyNoExplode with string value (explode=false)', () async {
      final api = buildApi();
      final result = await api.getQueryAnyNoExplode(anyValue: 'no-explode');
      final success = result as TonikSuccess;
      expect(success.response.statusCode, 200);
    });

    test('getQueryAnyNoExplode with number value', () async {
      final api = buildApi();
      final result = await api.getQueryAnyNoExplode(anyValue: 999);
      final success = result as TonikSuccess;
      expect(success.response.statusCode, 200);
    });
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
          isA<TonikError<QuerySpaceDelimitedAnyGet200BodyModel>>(),
        );
        final error =
            result as TonikError<QuerySpaceDelimitedAnyGet200BodyModel>;
        expect(error.error, isA<EncodingException>());
      },
    );

    test(
      'getQuerySpaceDelimitedAny with list returns TonikError',
      () async {
        final api = buildApi();
        final result = await api.getQuerySpaceDelimitedAny(
          anyValue: ['a', 'b', 'c'],
        );
        expect(
          result,
          isA<TonikError<QuerySpaceDelimitedAnyGet200BodyModel>>(),
        );
        final error =
            result as TonikError<QuerySpaceDelimitedAnyGet200BodyModel>;
        expect(error.error, isA<EncodingException>());
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
          isA<TonikError<QuerySpaceDelimitedAnyExplodeGet200BodyModel>>(),
        );
        final error =
            result as TonikError<QuerySpaceDelimitedAnyExplodeGet200BodyModel>;
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
          isA<TonikError<QuerySpaceDelimitedAnyExplodeGet200BodyModel>>(),
        );
        final error =
            result as TonikError<QuerySpaceDelimitedAnyExplodeGet200BodyModel>;
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
        expect(result, isA<TonikError<QueryPipeDelimitedAnyGet200BodyModel>>());
        final error =
            result as TonikError<QueryPipeDelimitedAnyGet200BodyModel>;
        expect(error.error, isA<EncodingException>());
      },
    );

    test(
      'getQueryPipeDelimitedAny with list returns TonikError',
      () async {
        final api = buildApi();
        final result = await api.getQueryPipeDelimitedAny(
          anyValue: ['one', 'two', 'three'],
        );
        expect(result, isA<TonikError<QueryPipeDelimitedAnyGet200BodyModel>>());
        final error =
            result as TonikError<QueryPipeDelimitedAnyGet200BodyModel>;
        expect(error.error, isA<EncodingException>());
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
          isA<TonikError<QueryPipeDelimitedAnyExplodeGet200BodyModel>>(),
        );
        final error =
            result as TonikError<QueryPipeDelimitedAnyExplodeGet200BodyModel>;
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
          isA<TonikError<QueryPipeDelimitedAnyExplodeGet200BodyModel>>(),
        );
        final error =
            result as TonikError<QueryPipeDelimitedAnyExplodeGet200BodyModel>;
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
      final success = result as TonikSuccess;
      expect(success.response.statusCode, 200);
    });

    test(
      'getQueryDeepObjectAny with string returns TonikError',
      () async {
        final api = buildApi();
        final result = await api.getQueryDeepObjectAny(anyValue: 'deep-object');
        expect(result, isA<TonikError<QueryDeepObjectAnyGet200BodyModel>>());
        final error = result as TonikError<QueryDeepObjectAnyGet200BodyModel>;
        expect(error.error, isA<EncodingException>());
      },
    );
  });
}
