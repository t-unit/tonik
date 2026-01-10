import 'package:boolean_schemas_api/boolean_schemas_api.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

import 'test_helper.dart';

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

  group('Path parameters - simple style', () {
    test('getPathAny with string value', () async {
      final api = buildApi();
      final result = await api.getPathAny(anyValue: 'test-value');
      final success = result as TonikSuccess<PathAnyAnyValueGet200BodyModel>;
      expect(success.response.statusCode, 200);
    });

    test('getPathAny with number value', () async {
      final api = buildApi();
      final result = await api.getPathAny(anyValue: 42);
      final success = result as TonikSuccess<PathAnyAnyValueGet200BodyModel>;
      expect(success.response.statusCode, 200);
    });

    test('getPathAny with boolean value', () async {
      final api = buildApi();
      final result = await api.getPathAny(anyValue: true);
      final success = result as TonikSuccess<PathAnyAnyValueGet200BodyModel>;
      expect(success.response.statusCode, 200);
    });

    test('getPathAnyExplode with simple style and explode', () async {
      final api = buildApi();
      final result = await api.getPathAnyExplode(anyValue: 'explode-test');
      final success =
          result as TonikSuccess<PathAnyExplodeAnyValueGet200BodyModel>;
      expect(success.response.statusCode, 200);
    });

    test('getPathAnyExplode with object value', () async {
      final api = buildApi();
      final result = await api.getPathAnyExplode(anyValue: {'key': 'value'});
      final success =
          result as TonikSuccess<PathAnyExplodeAnyValueGet200BodyModel>;
      expect(success.response.statusCode, 200);
    });

    test('getPathAnyExplode with array value', () async {
      final api = buildApi();
      final result = await api.getPathAnyExplode(anyValue: [1, 2, 3]);
      final success =
          result as TonikSuccess<PathAnyExplodeAnyValueGet200BodyModel>;
      expect(success.response.statusCode, 200);
    });
  });

  group('Path parameters - label style', () {
    test('getPathLabelAny with string value', () async {
      final api = buildApi();
      final result = await api.getPathLabelAny(anyValue: 'label-test');
      final success =
          result as TonikSuccess<PathLabelAnyAnyValueGet200BodyModel>;
      expect(success.response.statusCode, 200);
    });

    test('getPathLabelAny with number value', () async {
      final api = buildApi();
      final result = await api.getPathLabelAny(anyValue: 123);
      final success =
          result as TonikSuccess<PathLabelAnyAnyValueGet200BodyModel>;
      expect(success.response.statusCode, 200);
    });

    test('getPathLabelAnyExplode with object value should fail', () async {
      final api = buildApi();
      final result = await api.getPathLabelAnyExplode(
        anyValue: {'key': 'value'},
      );
      // Complex objects cannot be encoded for path parameters due to lack
      // of reflection in Dart
      expect(
        result,
        isA<TonikError<PathLabelAnyExplodeAnyValueGet200BodyModel>>(),
      );
      final error =
          result as TonikError<PathLabelAnyExplodeAnyValueGet200BodyModel>;
      expect(error.type, TonikErrorType.encoding);
    });

    test('getPathLabelAnyExplode with array value should fail', () async {
      final api = buildApi();
      final result = await api.getPathLabelAnyExplode(anyValue: ['a', 'b']);
      // Complex arrays cannot be encoded for path parameters due to lack
      // of reflection in Dart
      expect(
        result,
        isA<TonikError<PathLabelAnyExplodeAnyValueGet200BodyModel>>(),
      );
      final error =
          result as TonikError<PathLabelAnyExplodeAnyValueGet200BodyModel>;
      expect(error.type, TonikErrorType.encoding);
    });
  });

  group('Path parameters - matrix style', () {
    test('getPathMatrixAny with string value', () async {
      final api = buildApi();
      final result = await api.getPathMatrixAny(anyValue: 'matrix-test');
      final success =
          result as TonikSuccess<PathMatrixAnyAnyValueGet200BodyModel>;
      expect(success.response.statusCode, 200);
    });

    test('getPathMatrixAny with number value', () async {
      final api = buildApi();
      final result = await api.getPathMatrixAny(anyValue: 999);
      final success =
          result as TonikSuccess<PathMatrixAnyAnyValueGet200BodyModel>;
      expect(success.response.statusCode, 200);
    });
  });

  group('Combined path, query, and header parameters', () {
    test('getCombinedAny with all parameter types', () async {
      final api = buildApi();
      final result = await api.getCombinedAny(
        pathAny: 'path-value',
        queryAny: 'query-value',
        headerAny: 'header-value',
      );
      final success = result as TonikSuccess<CombinedResponse>;
      expect(success.response.statusCode, 200);

      final body = success.value;
      expect(body.pathValue, isNotNull);
      expect(body.queryValue, isNotNull);
      expect(body.headerValue, isNotNull);
    });

    test('getCombinedAny with numeric values', () async {
      final api = buildApi();
      final result = await api.getCombinedAny(
        pathAny: 123,
        queryAny: 456,
        headerAny: 789,
      );
      final success = result as TonikSuccess<CombinedResponse>;
      expect(success.response.statusCode, 200);
    });

    test('getCombinedAny with mixed types', () async {
      final api = buildApi();
      final result = await api.getCombinedAny(
        pathAny: 'string',
        queryAny: 42,
        headerAny: true,
      );
      final success = result as TonikSuccess<CombinedResponse>;
      expect(success.response.statusCode, 200);
    });
  });
}
