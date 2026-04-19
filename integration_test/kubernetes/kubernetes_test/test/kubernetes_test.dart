import 'package:dio/dio.dart';
import 'package:kubernetes_api/kubernetes_api.dart';
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

  // ── Helper ───────────────────────────────────────────────────────────

  DefaultApi buildDefaultApi({required String responseStatus}) {
    return DefaultApi(
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

  // ── ListCoreV1Namespace ──────────────────────────────────────────────

  group('ListCoreV1Namespace', () {
    test('listCoreV1Namespace 200', () async {
      final api = buildDefaultApi(responseStatus: '200');

      final result = await api.listCoreV1Namespace();

      expect(result, isA<TonikSuccess<ListCoreV1NamespaceResponse>>());
      final success = result as TonikSuccess<ListCoreV1NamespaceResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<ListCoreV1NamespaceResponse200>());

      final uri = success.response.requestOptions.uri;
      expect(uri.path, '/api/v1/namespaces');
    });

    test('listCoreV1Namespace 401', () async {
      final api = buildDefaultApi(responseStatus: '401');

      final result = await api.listCoreV1Namespace();

      expect(result, isA<TonikSuccess<ListCoreV1NamespaceResponse>>());
      final success = result as TonikSuccess<ListCoreV1NamespaceResponse>;
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
        isA<TonikSuccess<ListCoreV1ConfigMapForAllNamespacesResponse>>(),
      );
      final success =
          result as TonikSuccess<ListCoreV1ConfigMapForAllNamespacesResponse>;
      expect(success.response.statusCode, 200);

      final uri = success.response.requestOptions.uri;
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
        isA<TonikSuccess<ListCoreV1PodForAllNamespacesResponse>>(),
      );
      final success =
          result as TonikSuccess<ListCoreV1PodForAllNamespacesResponse>;
      expect(success.response.statusCode, 200);

      final uri = success.response.requestOptions.uri;
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
        isA<TonikSuccess<ListCoreV1ServiceForAllNamespacesResponse>>(),
      );
      final success =
          result as TonikSuccess<ListCoreV1ServiceForAllNamespacesResponse>;
      expect(success.response.statusCode, 200);

      final uri = success.response.requestOptions.uri;
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
        isA<TonikSuccess<ListCoreV1NamespacedConfigMapResponse>>(),
      );
      final success =
          result as TonikSuccess<ListCoreV1NamespacedConfigMapResponse>;
      expect(success.response.statusCode, 200);

      final uri = success.response.requestOptions.uri;
      expect(uri.path, '/api/v1/namespaces/default/configmaps');
    });

    test('listCoreV1NamespacedConfigMap 401', () async {
      final api = buildDefaultApi(responseStatus: '401');

      final result = await api.listCoreV1NamespacedConfigMap(
        namespace: 'default',
      );

      expect(
        result,
        isA<TonikSuccess<ListCoreV1NamespacedConfigMapResponse>>(),
      );
      final success =
          result as TonikSuccess<ListCoreV1NamespacedConfigMapResponse>;
      expect(success.response.statusCode, 401);
    });
  });
}
