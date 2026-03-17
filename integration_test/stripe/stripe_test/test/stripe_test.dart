import 'package:dio/dio.dart';
import 'package:stripe_api/stripe_api.dart';
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

  // ── GetBalance ─────────────────────────────────────────────────────

  group('GetBalance', () {
    test('getBalance 200', () async {
      final api = buildDefaultApi(responseStatus: '200');

      final result = await api.getBalance();

      expect(result, isA<TonikSuccess<GetBalanceResponse>>());
      final success = result as TonikSuccess<GetBalanceResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<GetBalanceResponse200>());

      final uri = success.response.requestOptions.uri;
      expect(uri.path, '/v1/balance');
    });

    test('getBalance default error', () async {
      final api = buildDefaultApi(responseStatus: '401');

      final result = await api.getBalance();

      expect(result, isA<TonikSuccess<GetBalanceResponse>>());
      final success = result as TonikSuccess<GetBalanceResponse>;
      expect(success.response.statusCode, 401);
      expect(success.value, isA<GetBalanceResponseDefault>());
    });
  });

  // ── GetCustomers ───────────────────────────────────────────────────

  group('GetCustomers', () {
    test('getCustomers 200', () async {
      final api = buildDefaultApi(responseStatus: '200');

      final result = await api.getCustomers(limit: 10);

      expect(result, isA<TonikSuccess<GetCustomersResponse>>());
      final success = result as TonikSuccess<GetCustomersResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<GetCustomersResponse200>());

      final uri = success.response.requestOptions.uri;
      expect(uri.path, '/v1/customers');
      expect(uri.queryParameters['limit'], '10');
    });

    test('getCustomers default error', () async {
      final api = buildDefaultApi(responseStatus: '400');

      final result = await api.getCustomers();

      expect(result, isA<TonikSuccess<GetCustomersResponse>>());
      final success = result as TonikSuccess<GetCustomersResponse>;
      expect(success.response.statusCode, 400);
      expect(success.value, isA<GetCustomersResponseDefault>());
    });
  });

  // ── GetCustomersCustomer ───────────────────────────────────────────

  group('GetCustomersCustomer', () {
    test('getCustomersCustomer 200', () async {
      final api = buildDefaultApi(responseStatus: '200');

      final result = await api.getCustomersCustomer(customer: 'cus_abc123');

      expect(result, isA<TonikSuccess<GetCustomersCustomerResponse>>());
      final success = result as TonikSuccess<GetCustomersCustomerResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<GetCustomersCustomerResponse200>());

      final uri = success.response.requestOptions.uri;
      expect(uri.path, '/v1/customers/cus_abc123');
    });

    test('getCustomersCustomer default error', () async {
      final api = buildDefaultApi(responseStatus: '404');

      final result = await api.getCustomersCustomer(customer: 'nonexistent');

      expect(result, isA<TonikSuccess<GetCustomersCustomerResponse>>());
      final success = result as TonikSuccess<GetCustomersCustomerResponse>;
      expect(success.response.statusCode, 404);
      expect(success.value, isA<GetCustomersCustomerResponseDefault>());
    });
  });

  // ── PostCustomers ──────────────────────────────────────────────────

  group('PostCustomers', () {
    test('postCustomers 200', () async {
      final api = buildDefaultApi(responseStatus: '200');

      final result = await api.postCustomers();

      expect(result, isA<TonikSuccess<PostCustomersResponse>>());
      final success = result as TonikSuccess<PostCustomersResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<PostCustomersResponse200>());

      expect(success.response.requestOptions.uri.path, '/v1/customers');
      expect(success.response.requestOptions.method, 'POST');
    });

    test('postCustomers default error', () async {
      final api = buildDefaultApi(responseStatus: '400');

      final result = await api.postCustomers();

      expect(result, isA<TonikSuccess<PostCustomersResponse>>());
      final success = result as TonikSuccess<PostCustomersResponse>;
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

      expect(result, isA<TonikSuccess<DeleteCustomersCustomerResponse>>());
      final success = result as TonikSuccess<DeleteCustomersCustomerResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<DeleteCustomersCustomerResponse200>());

      final uri = success.response.requestOptions.uri;
      expect(uri.path, '/v1/customers/cus_delete_me');
      expect(success.response.requestOptions.method, 'DELETE');
    });

    test('deleteCustomersCustomer default error', () async {
      final api = buildDefaultApi(responseStatus: '404');

      final result = await api.deleteCustomersCustomer(
        customer: 'nonexistent',
      );

      expect(result, isA<TonikSuccess<DeleteCustomersCustomerResponse>>());
      final success = result as TonikSuccess<DeleteCustomersCustomerResponse>;
      expect(success.response.statusCode, 404);
      expect(success.value, isA<DeleteCustomersCustomerResponseDefault>());
    });
  });

  // ── GetCharges ─────────────────────────────────────────────────────

  group('GetCharges', () {
    test('getCharges 200', () async {
      final api = buildDefaultApi(responseStatus: '200');

      final result = await api.getCharges(limit: 5);

      expect(result, isA<TonikSuccess<GetChargesResponse>>());
      final success = result as TonikSuccess<GetChargesResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<GetChargesResponse200>());

      final uri = success.response.requestOptions.uri;
      expect(uri.path, '/v1/charges');
      expect(uri.queryParameters['limit'], '5');
    });

    test('getCharges default error', () async {
      final api = buildDefaultApi(responseStatus: '401');

      final result = await api.getCharges();

      expect(result, isA<TonikSuccess<GetChargesResponse>>());
      final success = result as TonikSuccess<GetChargesResponse>;
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

      expect(result, isA<TonikSuccess<GetPaymentIntentsIntentResponse>>());
      final success = result as TonikSuccess<GetPaymentIntentsIntentResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<GetPaymentIntentsIntentResponse200>());

      final uri = success.response.requestOptions.uri;
      expect(uri.path, '/v1/payment_intents/pi_abc123');
    });

    test('getPaymentIntentsIntent default error', () async {
      final api = buildDefaultApi(responseStatus: '404');

      final result = await api.getPaymentIntentsIntent(
        intent: 'nonexistent',
      );

      expect(result, isA<TonikSuccess<GetPaymentIntentsIntentResponse>>());
      final success = result as TonikSuccess<GetPaymentIntentsIntentResponse>;
      expect(success.response.statusCode, 404);
      expect(success.value, isA<GetPaymentIntentsIntentResponseDefault>());
    });
  });

  // ── PostRefunds ────────────────────────────────────────────────────

  group('PostRefunds', () {
    test('postRefunds 200', () async {
      final api = buildDefaultApi(responseStatus: '200');

      final result = await api.postRefunds();

      expect(result, isA<TonikSuccess<PostRefundsResponse>>());
      final success = result as TonikSuccess<PostRefundsResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<PostRefundsResponse200>());

      expect(success.response.requestOptions.uri.path, '/v1/refunds');
      expect(success.response.requestOptions.method, 'POST');
    });

    test('postRefunds default error', () async {
      final api = buildDefaultApi(responseStatus: '400');

      final result = await api.postRefunds();

      expect(result, isA<TonikSuccess<PostRefundsResponse>>());
      final success = result as TonikSuccess<PostRefundsResponse>;
      expect(success.response.statusCode, 400);
      expect(success.value, isA<PostRefundsResponseDefault>());
    });
  });
}
