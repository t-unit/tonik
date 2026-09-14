import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:immutable_collections_api/immutable_collections_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';

void main() {
  test('serializes a required nullable immutable JSON list', () async {
    final server = await RawRequestServer.start();
    final api = ItemsApi(CustomServer(baseUrl: server.baseUrl));
    expect(
      await api.postJsonNullableList(body: const IListConst([2, 1])),
      isTonikSuccess,
    );
    final request = await server.takeRequest();
    expect(request.bodyText, '[2,1]');
    expect(request.header('content-type'), startsWith('application/json'));
  });

  test('serializes a nullable immutable list inside a JSON variant', () async {
    final server = await RawRequestServer.start();
    final api = ItemsApi(CustomServer(baseUrl: server.baseUrl));
    expect(
      await api.postJsonNullableListVariant(
        body: const JsonNullableListVariantPostBodyRequestBodyJson(
          IListConst([3, 2]),
        ),
      ),
      isTonikSuccess,
    );
    final request = await server.takeRequest();
    expect(request.bodyText, '[3,2]');
    expect(request.header('content-type'), startsWith('application/json'));
  });

  test('serializes an inline immutable JSON map', () async {
    final server = await RawRequestServer.start();
    final api = ItemsApi(CustomServer(baseUrl: server.baseUrl));
    expect(
      await api.postJsonInlineMap(body: const IMapConst({'key': 'value'})),
      isTonikSuccess,
    );
    final request = await server.takeRequest();
    expect(request.bodyText, '{"key":"value"}');
    expect(request.header('content-type'), startsWith('application/json'));
  });

  test('serializes nested immutable collections in a JSON variant', () async {
    final server = await RawRequestServer.start();
    final api = ItemsApi(CustomServer(baseUrl: server.baseUrl));
    expect(
      await api.postJsonInlineNested(
        body: const JsonInlineNestedPostBodyRequestBodyJson(
          IListConst([
            IMapConst({
              'numbers': IListConst([2, 1]),
            }),
          ]),
        ),
      ),
      isTonikSuccess,
    );
    final request = await server.takeRequest();
    expect(request.bodyText, '[{"numbers":[2,1]}]');
    expect(request.header('content-type'), startsWith('application/json'));
  });
}
