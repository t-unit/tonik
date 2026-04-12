import 'package:dio/dio.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:immutable_collections_api/immutable_collections_api.dart';
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

  ItemsApi buildApi({required String responseStatus}) {
    return ItemsApi(
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

  group('GetItem', () {
    test('getItem 200', () async {
      final api = buildApi(responseStatus: '200');
      final result = await api.getItem(id: 1);

      expect(result, isA<TonikSuccess<GetItemResponse>>());
      final success = result as TonikSuccess<GetItemResponse>;
      expect(success.response.statusCode, 200);

      final value = success.value;
      expect(value, isA<GetItemResponse200>());

      final body = (value as GetItemResponse200).body;
      expect(body, isA<Item>());

      // Verify the returned fields are IList/IMap types
      expect(body.tags, isA<IList<String>>());
      expect(body.children, isA<IList<ChildModel>>());
      expect(body.metadata, isA<IMap<String, String>>());
    });

    test('getItem 404', () async {
      final api = buildApi(responseStatus: '404');
      final result = await api.getItem(id: 999);

      expect(result, isA<TonikSuccess<GetItemResponse>>());
      final success = result as TonikSuccess<GetItemResponse>;
      expect(success.response.statusCode, 404);
      expect(success.value, isA<GetItemResponse404>());
    });
  });

  group('CreateItem', () {
    test('createItem 201', () async {
      final api = buildApi(responseStatus: '201');

      final result = await api.createItem(
        body: Item(
          id: 1,
          name: 'Widget',
          tags: <String>['cool', 'useful'].lock,
          children: <ChildModel>[
            const ChildModel(childName: 'bolt', value: 10),
          ].lock,
          metadata: IMap(const {'color': 'red', 'size': 'large'}),
        ),
      );

      // createItem returns TonikResult<Item> directly (single response)
      expect(result, isA<TonikSuccess<Item>>());
      final success = result as TonikSuccess<Item>;
      expect(success.response.statusCode, 201);

      final body = success.value;
      expect(body, isA<Item>());

      // Verify deserialized response uses IList/IMap
      expect(body.tags, isA<IList<String>>());
      expect(body.children, isA<IList<ChildModel>>());
      expect(body.metadata, isA<IMap<String, String>>());
    });
  });

  group('CreateNested', () {
    test('createNested 200', () async {
      final api = buildApi(responseStatus: '200');

      final result = await api.createNested(
        body: NestedList(
          matrix: <IList<String>>[
            <String>['a', 'b'].lock,
            <String>['c', 'd'].lock,
          ].lock,
        ),
      );

      // createNested returns TonikResult<NestedList> directly
      expect(result, isA<TonikSuccess<NestedList>>());
      final success = result as TonikSuccess<NestedList>;
      expect(success.response.statusCode, 200);

      final body = success.value;
      expect(body, isA<NestedList>());

      // Verify nested collections are IList<IList<String>>
      expect(body.matrix, isA<IList<IList<String>>>());
      expect(body.matrix[0], isA<IList<String>>());
    });
  });
}
