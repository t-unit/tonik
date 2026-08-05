import 'package:kubernetes_api/kubernetes_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';

void main() {
  late ImposterServer imposterServer;
  late String baseUrl;

  setUpAll(() async {
    imposterServer = await setupImposterServer();
    baseUrl = 'http://localhost:${imposterServer.port}';
  });

  // ── Helper ───────────────────────────────────────────────────────────

  DefaultApi buildDefaultApi({required String responseStatus}) {
    return DefaultApi(
      CustomServer(
        baseUrl: baseUrl,
        serverConfig: testServerConfig(
          headers: {'X-Response-Status': responseStatus},
        ),
      ),
    );
  }

  // ── ListCoreV1Namespace ──────────────────────────────────────────────

  group('ListCoreV1Namespace', () {
    test('listCoreV1Namespace 200', () async {
      final api = buildDefaultApi(responseStatus: '200');

      final result = await api.listCoreV1Namespace();

      expect(
        result,
        isTonikSuccess,
      );
      final success = requireSuccess(result);
      expect(success.response.statusCode, 200);
      expect(success.value, isA<ListCoreV1NamespaceResponse200>());
      final recordedRequest = await imposterServer.takeRequest();

      final uri = recordedRequest.uri;
      expect(uri.path, '/api/v1/namespaces');
    });

    test('listCoreV1Namespace 401', () async {
      final api = buildDefaultApi(responseStatus: '401');

      final result = await api.listCoreV1Namespace();

      expect(
        result,
        isTonikSuccess,
      );
      final success = requireSuccess(result);
      expect(success.response.statusCode, 401);
      expect(success.value, isA<ListCoreV1NamespaceResponse401>());
    });
  });

  // ── ListCoreV1ConfigMapForAllNamespaces ───────────────────────────────

  group('ListCoreV1ConfigMapForAllNamespaces', () {
    test('listCoreV1ConfigMapForAllNamespaces 200', () async {
      final api = buildDefaultApi(responseStatus: '200');

      final result = await api.listCoreV1ConfigMapForAllNamespaces();

      expect(
        result,
        isTonikSuccess,
      );
      final success = requireSuccess(result);
      expect(success.response.statusCode, 200);
      final recordedRequest = await imposterServer.takeRequest();

      final uri = recordedRequest.uri;
      expect(uri.path, '/api/v1/configmaps');
    });
  });

  // ── ListCoreV1PodForAllNamespaces ────────────────────────────────────

  group('ListCoreV1PodForAllNamespaces', () {
    test('listCoreV1PodForAllNamespaces 200', () async {
      final api = buildDefaultApi(responseStatus: '200');

      final result = await api.listCoreV1PodForAllNamespaces();

      expect(
        result,
        isTonikSuccess,
      );
      final success = requireSuccess(result);
      expect(success.response.statusCode, 200);
      final recordedRequest = await imposterServer.takeRequest();

      final uri = recordedRequest.uri;
      expect(uri.path, '/api/v1/pods');
    });
  });

  // ── ListCoreV1ServiceForAllNamespaces ────────────────────────────────

  group('ListCoreV1ServiceForAllNamespaces', () {
    test('listCoreV1ServiceForAllNamespaces 200', () async {
      final api = buildDefaultApi(responseStatus: '200');

      final result = await api.listCoreV1ServiceForAllNamespaces();

      expect(
        result,
        isTonikSuccess,
      );
      final success = requireSuccess(result);
      expect(success.response.statusCode, 200);
      final recordedRequest = await imposterServer.takeRequest();

      final uri = recordedRequest.uri;
      expect(uri.path, '/api/v1/services');
    });
  });

  // ── ListCoreV1NamespacedConfigMap ────────────────────────────────────

  group('ListCoreV1NamespacedConfigMap', () {
    test('listCoreV1NamespacedConfigMap 200', () async {
      final api = buildDefaultApi(responseStatus: '200');

      final result = await api.listCoreV1NamespacedConfigMap(
        namespace: 'default',
      );

      expect(
        result,
        isTonikSuccess,
      );
      final success = requireSuccess(result);
      expect(success.response.statusCode, 200);
      final recordedRequest = await imposterServer.takeRequest();

      final uri = recordedRequest.uri;
      expect(uri.path, '/api/v1/namespaces/default/configmaps');
    });

    test('listCoreV1NamespacedConfigMap 401', () async {
      final api = buildDefaultApi(responseStatus: '401');

      final result = await api.listCoreV1NamespacedConfigMap(
        namespace: 'default',
      );

      expect(
        result,
        isTonikSuccess,
      );
      final success = requireSuccess(result);
      expect(success.response.statusCode, 401);
    });
  });
}
