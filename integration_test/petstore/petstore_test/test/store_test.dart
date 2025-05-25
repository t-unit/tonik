import 'package:dio/dio.dart';
import 'package:petstore_api/petstore_api.dart';
import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

import 'test_helper.dart';

void main() {
  const port = 8080;
  const baseUrl = 'http://localhost:$port/api/v3';

  late ImposterServer imposterServer;

  setUpAll(() async {
    imposterServer = ImposterServer(port: port);
    await setupImposterServer(imposterServer);
  });

   StoreApi buildStoreApi({required String responseStatus}) {
    return StoreApi(
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

  group('getInventory', () {
    test('200', () async {
      final storeApi = buildStoreApi(responseStatus: '200');

      final inventory = await storeApi.getInventory();
      final success = inventory as TonikSuccess<GetInventoryResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<GetInventoryResponse200>());
    });

    test('default', () async {
      final storeApi = buildStoreApi(responseStatus: '422');

      final inventory = await storeApi.getInventory();

      final success = inventory as TonikSuccess<GetInventoryResponse>;
      expect(success.response.statusCode, 422);
      expect(success.value, isA<GetInventoryResponseDefault>());
    });
  });

  group('placeOrder', () {
    test('200', () async {
      final storeApi = buildStoreApi(responseStatus: '200');

      final body = Order(
        id: 1,
        petId: 1,
        quantity: 1,
        shipDate: DateTime.now(),
        status: OrderStatus.placed,
        complete: true,
      );

      final order = await storeApi.placeOrder(body: body);
      final success = order as TonikSuccess<PlaceOrderResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<PlaceOrderResponse200>());

      final responseBody = (success.value as PlaceOrderResponse200).body;
      expect(responseBody.id, isA<int?>());
      expect(responseBody.petId, isA<int?>());
      expect(responseBody.quantity, isA<int?>());
      expect(responseBody.shipDate, isA<DateTime?>());
      expect(responseBody.status, isA<OrderStatus?>());
      expect(responseBody.complete, isA<bool?>());
    });

    test('400', () async {
      final storeApi = buildStoreApi(responseStatus: '400');

      const body = Order();
      final order = await storeApi.placeOrder(body: body);
      final success = order as TonikSuccess<PlaceOrderResponse>;
      expect(success.response.statusCode, 400);
      expect(success.value, isA<PlaceOrderResponse400>());
    });

    test('422', () async {
      final storeApi = buildStoreApi(responseStatus: '422');

      final body = Order(id: -484848, shipDate: DateTime(10299, 12, 12, 1));
      final order = await storeApi.placeOrder(body: body);
      final success = order as TonikSuccess<PlaceOrderResponse>;
      expect(success.response.statusCode, 422);
      expect(success.value, isA<PlaceOrderResponse422>());
    });

    test('default', () async {
      final storeApi = buildStoreApi(responseStatus: '499');

      const body = Order(status: OrderStatus.approved);
      final order = await storeApi.placeOrder(body: body);
      final success = order as TonikSuccess<PlaceOrderResponse>;
      expect(success.value, isA<PlaceOrderResponseDefault>());
    });
  });

  group('getOrderById', () {
    test('200', () async {
      final storeApi = buildStoreApi(responseStatus: '200');

      final order = await storeApi.getOrderById(orderId: 1);
      final success = order as TonikSuccess<GetOrderByIdResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<GetOrderByIdResponse200>());
    });

    test('400', () async {
      final storeApi = buildStoreApi(responseStatus: '400');

      final order = await storeApi.getOrderById(orderId: -999);
      final success = order as TonikSuccess<GetOrderByIdResponse>;
      expect(success.response.statusCode, 400);
      expect(success.value, isA<GetOrderByIdResponse400>());
    });

    test('404', () async {
      final storeApi = buildStoreApi(responseStatus: '404');

      final order = await storeApi.getOrderById(orderId: 1000000);
      final success = order as TonikSuccess<GetOrderByIdResponse>;
      expect(success.response.statusCode, 404);
      expect(success.value, isA<GetOrderByIdResponse404>());
    });

    test('default', () async {
      final storeApi = buildStoreApi(responseStatus: '503');

      final order = await storeApi.getOrderById(orderId: 99999999999999);
      final success = order as TonikSuccess<GetOrderByIdResponse>;
      expect(success.value, isA<GetOrderByIdResponseDefault>());
    });
  });

  group('deleteOrder', () {
    test('200', () async {
      final storeApi = buildStoreApi(responseStatus: '200');

      final order = await storeApi.deleteOrder(orderId: 1);
      final success = order as TonikSuccess<DeleteOrderResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<DeleteOrderResponse200>());
    });

    test('400', () async {
      final storeApi = buildStoreApi(responseStatus: '400');

      final order = await storeApi.deleteOrder(orderId: -999);
      final success = order as TonikSuccess<DeleteOrderResponse>;
      expect(success.response.statusCode, 400);
      expect(success.value, isA<DeleteOrderResponse400>());
    });

    test('404', () async {
      final storeApi = buildStoreApi(responseStatus: '404');

      final order = await storeApi.deleteOrder(orderId: 1000000);
      final success = order as TonikSuccess<DeleteOrderResponse>;
      expect(success.response.statusCode, 404);
      expect(success.value, isA<DeleteOrderResponse404>());
    });

    test('default', () async {
      final storeApi = buildStoreApi(responseStatus: '665');

      final order = await storeApi.deleteOrder(orderId: -9767);
      final success = order as TonikSuccess<DeleteOrderResponse>;
      expect(success.value, isA<DeleteOrderResponseDefault>());
    });
  });
}
