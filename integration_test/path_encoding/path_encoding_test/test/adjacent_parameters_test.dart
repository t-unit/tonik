import 'package:path_encoding_api/path_encoding_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  late ImposterServer imposterServer;
  late String baseUrl;

  setUpAll(() async {
    imposterServer = await setupImposterServer();
    baseUrl = 'http://localhost:${imposterServer.port}/v1';
  });

  test('label array stays attached to its literal prefix', () async {
    final api = LabelApi(
      CustomServer(baseUrl: baseUrl, serverConfig: testServerConfig()),
    );

    final response = await api.testLabelLiteralPrefix(labels: ['daily']);

    expect(response, isTonikSuccess);
    final request = await imposterServer.takeRequest();
    expect(request.uri.path, '/v1/reports.daily');
  });

  test(
    'exploded label array keeps its suffix and escapes values once',
    () async {
      final api = LabelApi(
        CustomServer(baseUrl: baseUrl, serverConfig: testServerConfig()),
      );

      final response = await api.testLabelLiteralSuffix(
        labels: ['a/b', 'daily'],
      );

      expect(response, isTonikSuccess);
      final request = await imposterServer.takeRequest();
      expect(request.uri.path, '/v1/reports/.a%2Fb.daily.json');
    },
  );

  test('adjacent styles preserve the segment and trailing slash', () async {
    final api = LabelApi(
      CustomServer(baseUrl: baseUrl, serverConfig: testServerConfig()),
    );

    final response = await api.testAdjacentPathStyles(
      name: 'sales',
      labels: 'daily',
      revision: 2,
    );

    expect(response, isTonikSuccess);
    final request = await imposterServer.takeRequest();
    expect(request.uri.path, '/v1/reports/sales.daily;revision=2.json/');
  });

  test('null required path values retain empty style markers', () async {
    final api = LabelApi(
      CustomServer(baseUrl: baseUrl, serverConfig: testServerConfig()),
    );

    final response = await api.testNullablePathValues(
      simple: null,
      label: null,
      matrix: null,
    );

    expect(response, isTonikSuccess);
    final request = await imposterServer.takeRequest();
    expect(request.uri.path, '/v1/nullable/.;matrix.json');
  });

  test('non-null required path values retain their styles', () async {
    final api = LabelApi(
      CustomServer(baseUrl: baseUrl, serverConfig: testServerConfig()),
    );

    final response = await api.testNullablePathValues(
      simple: 'x',
      label: 'y',
      matrix: 'z',
    );

    expect(response, isTonikSuccess);
    final request = await imposterServer.takeRequest();
    expect(request.uri.path, '/v1/nullable/x.y;matrix=z.json');
  });

  test('null arbitrary path values retain empty style markers', () async {
    final api = LabelApi(
      CustomServer(baseUrl: baseUrl, serverConfig: testServerConfig()),
    );

    final response = await api.testNullableAnyPathValues(
      simple: null,
      label: null,
      matrix: null,
    );

    expect(response, isTonikSuccess);
    final request = await imposterServer.takeRequest();
    expect(request.uri.path, '/v1/nullable-any/.;matrix.json');
  });

  test('referenced arbitrary label retains its style', () async {
    final api = LabelApi(
      CustomServer(baseUrl: baseUrl, serverConfig: testServerConfig()),
    );

    final response = await api.testNullableAnyPathValues(
      simple: 'x',
      label: 'y',
      matrix: 'z',
    );

    expect(response, isTonikSuccess);
    final request = await imposterServer.takeRequest();
    expect(request.uri.path, '/v1/nullable-any/x.y;matrix=z.json');
  });

  test('non-null binary path value returns an encoding error', () async {
    final api = SimpleApi(
      CustomServer(baseUrl: baseUrl, serverConfig: testServerConfig()),
    );

    final response = await api.testNullableBinaryPathValue(
      value: const TonikFileBytes([1, 2, 3]),
      suffix: 'x',
    );

    expect(response, isTonikError);
    expect(requireError(response).type, TonikErrorType.encoding);
  });

  test(
    'binary label with surrounding literals returns an encoding error',
    () async {
      final api = LabelApi(
        CustomServer(baseUrl: baseUrl, serverConfig: testServerConfig()),
      );

      final response = await api.testLabelBinaryWithSuffix(
        value: const TonikFileBytes([1, 2, 3]),
      );

      expect(response, isTonikError);
      final error = requireError(response);
      expect(error.type, TonikErrorType.encoding);
      expect(error.error, isA<EncodingException>());
    },
  );

  test(
    'matrix object array with surrounding literals returns an encoding error',
    () async {
      final api = MatrixApi(
        CustomServer(baseUrl: baseUrl, serverConfig: testServerConfig()),
      );

      final response = await api.testMatrixObjectArrayWithSuffix(
        value: const [SimpleObject(name: 'daily', count: 1)],
      );

      expect(response, isTonikError);
      final error = requireError(response);
      expect(error.type, TonikErrorType.encoding);
      expect(error.error, isA<EncodingException>());
    },
  );
}
