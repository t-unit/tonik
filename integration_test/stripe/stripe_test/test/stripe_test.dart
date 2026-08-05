import 'package:stripe_api/stripe_api.dart';
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

  // ── GetBalance ─────────────────────────────────────────────────────

  group('GetBalance', () {
    test('getBalance 200', () async {
      final api = buildDefaultApi(responseStatus: '200');

      final result = await api.getBalance();

      expect(
        result,
        isTonikSuccess,
      );
      final success = requireSuccess(result);
      expect(success.response.statusCode, 200);
      expect(success.value, isA<GetBalanceResponse200>());
      final recordedRequest = await imposterServer.takeRequest();

      final uri = recordedRequest.uri;
      expect(uri.path, '/v1/balance');
    });

    test('getBalance default error', () async {
      final api = buildDefaultApi(responseStatus: '401');

      final result = await api.getBalance();

      expect(
        result,
        isTonikSuccess,
      );
      final success = requireSuccess(result);
      expect(success.response.statusCode, 401);
      expect(success.value, isA<GetBalanceResponseDefault>());
    });
  });

  // ── GetCustomers ───────────────────────────────────────────────────

  group('GetCustomers', () {
    test('getCustomers 200', () async {
      final api = buildDefaultApi(responseStatus: '200');

      final result = await api.getCustomers(limit: 10);

      expect(
        result,
        isTonikSuccess,
      );
      final success = requireSuccess(result);
      expect(success.response.statusCode, 200);
      expect(success.value, isA<GetCustomersResponse200>());
      final recordedRequest = await imposterServer.takeRequest();

      final uri = recordedRequest.uri;
      expect(uri.path, '/v1/customers');
      expect(uri.queryParameters['limit'], '10');
    });

    test('getCustomers default error', () async {
      final api = buildDefaultApi(responseStatus: '400');

      final result = await api.getCustomers();

      expect(
        result,
        isTonikSuccess,
      );
      final success = requireSuccess(result);
      expect(success.response.statusCode, 400);
      expect(success.value, isA<GetCustomersResponseDefault>());
    });
  });

  // ── GetCustomersCustomer ───────────────────────────────────────────

  group('GetCustomersCustomer', () {
    test('getCustomersCustomer 200', () async {
      final api = buildDefaultApi(responseStatus: '200');

      final result = await api.getCustomersCustomer(customer: 'cus_abc123');

      expect(
        result,
        isTonikSuccess,
      );
      final success = requireSuccess(result);
      expect(success.response.statusCode, 200);
      expect(success.value, isA<GetCustomersCustomerResponse200>());
      final recordedRequest = await imposterServer.takeRequest();

      final uri = recordedRequest.uri;
      expect(uri.path, '/v1/customers/cus_abc123');
    });

    test('getCustomersCustomer default error', () async {
      final api = buildDefaultApi(responseStatus: '404');

      final result = await api.getCustomersCustomer(customer: 'nonexistent');

      expect(
        result,
        isTonikSuccess,
      );
      final success = requireSuccess(result);
      expect(success.response.statusCode, 404);
      expect(success.value, isA<GetCustomersCustomerResponseDefault>());
    });
  });

  // ── PostCustomers ──────────────────────────────────────────────────

  group('PostCustomers', () {
    test('postCustomers 200', () async {
      final api = buildDefaultApi(responseStatus: '200');

      final result = await api.postCustomers();

      expect(
        result,
        isTonikSuccess,
      );
      final success = requireSuccess(result);
      expect(success.response.statusCode, 200);
      expect(success.value, isA<PostCustomersResponse200>());
      final recordedRequest = await imposterServer.takeRequest();

      expect(recordedRequest.uri.path, '/v1/customers');
      expect(recordedRequest.method, 'POST');
    });

    test('postCustomers default error', () async {
      final api = buildDefaultApi(responseStatus: '400');

      final result = await api.postCustomers();

      expect(
        result,
        isTonikSuccess,
      );
      final success = requireSuccess(result);
      expect(success.response.statusCode, 400);
      expect(success.value, isA<PostCustomersResponseDefault>());
    });
  });

  // ── DeleteCustomersCustomer ────────────────────────────────────────

  group('DeleteCustomersCustomer', () {
    test('deleteCustomersCustomer 200', () async {
      final api = buildDefaultApi(responseStatus: '200');

      final result = await api.deleteCustomersCustomer(
        customer: 'cus_delete_me',
      );

      expect(
        result,
        isTonikSuccess,
      );
      final success = requireSuccess(result);
      expect(success.response.statusCode, 200);
      expect(success.value, isA<DeleteCustomersCustomerResponse200>());
      final recordedRequest = await imposterServer.takeRequest();

      final uri = recordedRequest.uri;
      expect(uri.path, '/v1/customers/cus_delete_me');
      expect(recordedRequest.method, 'DELETE');
    });

    test('deleteCustomersCustomer default error', () async {
      final api = buildDefaultApi(responseStatus: '404');

      final result = await api.deleteCustomersCustomer(
        customer: 'nonexistent',
      );

      expect(
        result,
        isTonikSuccess,
      );
      final success = requireSuccess(result);
      expect(success.response.statusCode, 404);
      expect(success.value, isA<DeleteCustomersCustomerResponseDefault>());
    });
  });

  // ── GetCharges ─────────────────────────────────────────────────────

  group('GetCharges', () {
    test('getCharges 200', () async {
      final api = buildDefaultApi(responseStatus: '200');

      final result = await api.getCharges(limit: 5);

      expect(
        result,
        isTonikSuccess,
      );
      final success = requireSuccess(result);
      expect(success.response.statusCode, 200);
      expect(success.value, isA<GetChargesResponse200>());
      final recordedRequest = await imposterServer.takeRequest();

      final uri = recordedRequest.uri;
      expect(uri.path, '/v1/charges');
      expect(uri.queryParameters['limit'], '5');
    });

    test('getCharges default error', () async {
      final api = buildDefaultApi(responseStatus: '401');

      final result = await api.getCharges();

      expect(
        result,
        isTonikSuccess,
      );
      final success = requireSuccess(result);
      expect(success.response.statusCode, 401);
      expect(success.value, isA<GetChargesResponseDefault>());
    });
  });

  // ── GetPaymentIntentsIntent ────────────────────────────────────────

  group('GetPaymentIntentsIntent', () {
    test('getPaymentIntentsIntent 200', () async {
      final api = buildDefaultApi(responseStatus: '200');

      final result = await api.getPaymentIntentsIntent(
        intent: 'pi_abc123',
      );

      expect(
        result,
        isTonikSuccess,
      );
      final success = requireSuccess(result);
      expect(success.response.statusCode, 200);
      expect(success.value, isA<GetPaymentIntentsIntentResponse200>());
      final recordedRequest = await imposterServer.takeRequest();

      final uri = recordedRequest.uri;
      expect(uri.path, '/v1/payment_intents/pi_abc123');
    });

    test('getPaymentIntentsIntent default error', () async {
      final api = buildDefaultApi(responseStatus: '404');

      final result = await api.getPaymentIntentsIntent(
        intent: 'nonexistent',
      );

      expect(
        result,
        isTonikSuccess,
      );
      final success = requireSuccess(result);
      expect(success.response.statusCode, 404);
      expect(success.value, isA<GetPaymentIntentsIntentResponseDefault>());
    });
  });

  // ── PostRefunds ────────────────────────────────────────────────────

  group('PostRefunds', () {
    test('postRefunds 200', () async {
      final api = buildDefaultApi(responseStatus: '200');

      final result = await api.postRefunds();

      expect(
        result,
        isTonikSuccess,
      );
      final success = requireSuccess(result);
      expect(success.response.statusCode, 200);
      expect(success.value, isA<PostRefundsResponse200>());
      final recordedRequest = await imposterServer.takeRequest();

      expect(recordedRequest.uri.path, '/v1/refunds');
      expect(recordedRequest.method, 'POST');
    });

    test('postRefunds default error', () async {
      final api = buildDefaultApi(responseStatus: '400');

      final result = await api.postRefunds();

      expect(
        result,
        isTonikSuccess,
      );
      final success = requireSuccess(result);
      expect(success.response.statusCode, 400);
      expect(success.value, isA<PostRefundsResponseDefault>());
    });
  });
}
