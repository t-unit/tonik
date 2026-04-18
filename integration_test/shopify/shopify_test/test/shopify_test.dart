import 'package:dio/dio.dart';
import 'package:shopify_api/shopify_api.dart';
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

  // ── GetProducts ──────────────────────────────────────────────────────

  group('GetProducts', () {
    test('getProducts 200', () async {
      final api = buildDefaultApi(responseStatus: '200');

      final result = await api.getProducts();

      expect(result, isA<TonikSuccess<void>>());
      final success = result as TonikSuccess<void>;
      expect(success.response.statusCode, 200);

      final uri = success.response.requestOptions.uri;
      expect(uri.path, '/admin/api/2020-10/products.json');
    });

    test('getProducts error returns TonikError', () async {
      final api = buildDefaultApi(responseStatus: '401');

      final result = await api.getProducts();

      expect(result, isA<TonikError<void>>());
      final error = result as TonikError<void>;
      expect(error.type, TonikErrorType.decoding);
    });
  });

  // ── GetCustomers ─────────────────────────────────────────────────────

  group('GetCustomers', () {
    test('getCustomers 200', () async {
      final api = buildDefaultApi(responseStatus: '200');

      final result = await api.getCustomers();

      expect(result, isA<TonikSuccess<void>>());
      final success = result as TonikSuccess<void>;
      expect(success.response.statusCode, 200);

      final uri = success.response.requestOptions.uri;
      expect(uri.path, '/admin/api/2020-10/customers.json');
    });
  });

  // ── CreateProducts ───────────────────────────────────────────────────

  group('CreateProducts', () {
    test('createProducts 200', () async {
      final api = buildDefaultApi(responseStatus: '200');

      final result = await api.createProducts();

      expect(result, isA<TonikSuccess<void>>());
      final success = result as TonikSuccess<void>;
      expect(success.response.statusCode, 200);

      expect(
        success.response.requestOptions.uri.path,
        '/admin/api/2020-10/products.json',
      );
      expect(success.response.requestOptions.method, 'POST');
    });
  });

  // ── DeleteProducts ───────────────────────────────────────────────────

  group('DeleteProducts', () {
    test('deleteProducts 200', () async {
      final api = buildDefaultApi(responseStatus: '200');

      final result = await api.deleteProductsParamProductId(productId: '123');

      expect(result, isA<TonikSuccess<void>>());
      final success = result as TonikSuccess<void>;
      expect(success.response.statusCode, 200);

      expect(success.response.requestOptions.method, 'DELETE');
      expect(
        success.response.requestOptions.uri.path,
        '/admin/api/2020-10/products/123.json',
      );
    });
  });
}
