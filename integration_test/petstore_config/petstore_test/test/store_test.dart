import 'package:dio/dio.dart';
import 'package:petstore_api/petstore_api.dart';
import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

import 'test_helper.dart';

void main() {
  const port = 8083;
  const baseUrl = 'http://localhost:$port/api/v3';

  late ImposterServer imposterServer;

  setUpAll(() async {
    imposterServer = ImposterServer(port: port);
    await setupImposterServer(imposterServer);
  });

  OrdersApi buildStoreApi({required String responseStatus}) {
    return OrdersApi(
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

      final inventory = await storeApi.fetchInventoryCounts();
      final success = inventory as TonikSuccess<FetchInventoryCountsResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<FetchInventoryCountsResponse200>());
    });

    test('default', () async {
      final storeApi = buildStoreApi(responseStatus: '422');

      final inventory = await storeApi.fetchInventoryCounts();

      final success = inventory as TonikSuccess<FetchInventoryCountsResponse>;
      expect(success.response.statusCode, 422);
      expect(success.value, isA<FetchInventoryCountsResponseDefault>());
    });
  });

  group('placeOrder', () {
    test('200', () async {
      final storeApi = buildStoreApi(responseStatus: '200');

      final body = PurchaseOrder(
        id: 1,
        animalId: 1,
        itemCount: 1,
        deliveryDate: DateTime.now(),
        status: OrderStatusModel.orderDelivered,
        complete: true,
      );

      // deprecation is defined by the OpenAPI spec and correct
      // ignore: deprecated_member_use
      final order = await storeApi.placeOrder(body: body);
      final success = order as TonikSuccess<PlaceOrderResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<PlaceOrderResponse200>());

      final responseBody = (success.value as PlaceOrderResponse200).body;
      expect(responseBody.id, isA<int?>());
      expect(responseBody.animalId, isA<int?>());
      expect(responseBody.itemCount, isA<int?>());
      // deprecation is defined by the OpenAPI spec and correct
      // ignore: deprecated_member_use
      expect(responseBody.deliveryDate, isA<DateTime?>());
      expect(responseBody.status, isA<OrderStatusModel?>());
      expect(responseBody.complete, isA<bool?>());
    });

    test('400', () async {
      final storeApi = buildStoreApi(responseStatus: '400');

      const body = PurchaseOrder();
      // deprecation is defined by the OpenAPI spec and correct
      // ignore: deprecated_member_use
      final order = await storeApi.placeOrder(body: body);
      final success = order as TonikSuccess<PlaceOrderResponse>;
      expect(success.response.statusCode, 400);
      expect(success.value, isA<PlaceOrderResponse400>());
    });

    test('422', () async {
      final storeApi = buildStoreApi(responseStatus: '422');

      final body = PurchaseOrder(
        id: -484848,
        deliveryDate: DateTime(10299, 12, 12, 1),
      );
      // deprecation is defined by the OpenAPI spec and correct
      // ignore: deprecated_member_use
      final order = await storeApi.placeOrder(body: body);
      final success = order as TonikSuccess<PlaceOrderResponse>;
      expect(success.response.statusCode, 422);
      expect(success.value, isA<PlaceOrderResponse422>());
    });

    test('default', () async {
      final storeApi = buildStoreApi(responseStatus: '499');

      const body = PurchaseOrder(status: OrderStatusModel.orderApproved);
      // deprecation is defined by the OpenAPI spec and correct
      // ignore: deprecated_member_use
      final order = await storeApi.placeOrder(body: body);
      final success = order as TonikSuccess<PlaceOrderResponse>;
      expect(success.value, isA<PlaceOrderResponseDefault>());
    });
  });

  group('getOrderById', () {
    test('200', () async {
      final storeApi = buildStoreApi(responseStatus: '200');

      final order = await storeApi.getOrderById(purchaseOrderId: 1);
      final success = order as TonikSuccess<GetOrderByIdResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<GetOrderByIdResponse200>());
    });

    test('400', () async {
      final storeApi = buildStoreApi(responseStatus: '400');

      final order = await storeApi.getOrderById(purchaseOrderId: -999);
      final success = order as TonikSuccess<GetOrderByIdResponse>;
      expect(success.response.statusCode, 400);
      expect(success.value, isA<GetOrderByIdResponse400>());
    });

    test('404', () async {
      final storeApi = buildStoreApi(responseStatus: '404');

      final order = await storeApi.getOrderById(purchaseOrderId: 1000000);
      final success = order as TonikSuccess<GetOrderByIdResponse>;
      expect(success.response.statusCode, 404);
      expect(success.value, isA<GetOrderByIdResponse404>());
    });

    test('default', () async {
      final storeApi = buildStoreApi(responseStatus: '503');

      final order = await storeApi.getOrderById(
        purchaseOrderId: 99999999999999,
      );
      final success = order as TonikSuccess<GetOrderByIdResponse>;
      expect(success.value, isA<GetOrderByIdResponseDefault>());
    });
  });

  group('deleteOrder', () {
    test('200', () async {
      final storeApi = buildStoreApi(responseStatus: '200');

      final order = await storeApi.cancelOrder(orderId: 1);
      final success = order as TonikSuccess<CancelOrderResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<CancelOrderResponse200>());
    });

    test('400', () async {
      final storeApi = buildStoreApi(responseStatus: '400');

      final order = await storeApi.cancelOrder(orderId: -999);
      final success = order as TonikSuccess<CancelOrderResponse>;
      expect(success.response.statusCode, 400);
      expect(success.value, isA<CancelOrderResponse400>());
    });

    test('404', () async {
      final storeApi = buildStoreApi(responseStatus: '404');

      final order = await storeApi.cancelOrder(orderId: 1000000);
      final success = order as TonikSuccess<CancelOrderResponse>;
      expect(success.response.statusCode, 404);
      expect(success.value, isA<CancelOrderResponse404>());
    });

    test('default', () async {
      final storeApi = buildStoreApi(responseStatus: '665');

      final order = await storeApi.cancelOrder(orderId: -9767);
      final success = order as TonikSuccess<CancelOrderResponse>;
      expect(success.value, isA<CancelOrderResponseDefault>());
    });
  });
}
