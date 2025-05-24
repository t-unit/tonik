import 'package:dio/dio.dart';
import 'package:petstore_api/petstore_api.dart';
import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

import 'test_helper.dart';

void main() {
  late ImposterServer imposterServer;

  setUpAll(() async {
    imposterServer = ImposterServer(port: 8080);
    await setupImposterServer(imposterServer);
  });

  group('getInventory', () {
    test('200', () async {
      final storeApi = StoreApi(
        CustomServer(
          baseUrl: 'http://localhost:8080/api/v3',
          serverConfig: ServerConfig(
            baseOptions: BaseOptions(headers: {'X-Response-Status': '200'}),
          ),
        ),
      );

      final inventory = await storeApi.getInventory();
      final success = inventory as TonikSuccess<GetInventoryResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<GetInventoryResponse200>());
    });

    test('default', () async {
      final storeApi = StoreApi(
        CustomServer(
          baseUrl: 'http://localhost:8080/api/v3',
          serverConfig: ServerConfig(
            baseOptions: BaseOptions(headers: {'X-Response-Status': '422'}),
          ),
        ),
      );

      final inventory = await storeApi.getInventory();

      final success = inventory as TonikSuccess<GetInventoryResponse>;
      expect(success.response.statusCode, 422);
      expect(success.value, isA<GetInventoryResponseDefault>());
    });
  });

  group('placeOrder', () {
    test('200', () async {
      final storeApi = StoreApi(
        CustomServer(
          baseUrl: 'http://localhost:8080/api/v3',
          serverConfig: ServerConfig(
            baseOptions: BaseOptions(headers: {'X-Response-Status': '200'}),
          ),
        ),
      );

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
    });

    test('400', () {
      throw UnimplementedError();
    });

    test('422', () {
      throw UnimplementedError();
    });

    test('default', () {
      throw UnimplementedError();
    });
  });
}
