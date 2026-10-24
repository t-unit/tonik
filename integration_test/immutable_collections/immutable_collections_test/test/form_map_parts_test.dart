import 'dart:io';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:immutable_collections_api/immutable_collections_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  test('form-encodes immutable map entries and omits null values', () async {
    final server = await RawRequestServer.start();
    final api = ItemsApi(CustomServer(baseUrl: server.baseUrl));

    expect(
      await api.postUrlEncodedMap(
        body: const UrlEncodedMapForm(
          attrs: IMapConst({
            'a b': 'x y',
            'symbols': '+&=',
            'count': 1,
            'skip': null,
          }),
        ),
      ),
      isTonikSuccess,
    );

    final part = MultipartWire(await server.takeRequest()).single('attrs');
    expect(
      ContentType.parse(part.contentType!).mimeType,
      'application/x-www-form-urlencoded',
    );
    expect(part.bodyText, 'a+b=x+y&symbols=%2B%26%3D&count=1');
  });

  test('rejects a nested immutable map before sending the form part', () async {
    final server = await RawRequestServer.start();
    final api = ItemsApi(CustomServer(baseUrl: server.baseUrl));

    final error = requireError(
      await api.postUrlEncodedMap(
        body: const UrlEncodedMapForm(
          attrs: IMapConst({
            'nested': IMapConst({'key': 'value'}),
          }),
        ),
      ),
    );

    expect(error.type, TonikErrorType.encoding);
    expect(error.error, isA<EncodingException>());
    expect(server.requestCount, 0);
  });

  test(
    'rejects a nested immutable list before sending the form part',
    () async {
      final server = await RawRequestServer.start();
      final api = ItemsApi(CustomServer(baseUrl: server.baseUrl));

      final error = requireError(
        await api.postUrlEncodedMap(
          body: const UrlEncodedMapForm(
            attrs: IMapConst({
              'nested': IListConst(['value']),
            }),
          ),
        ),
      );

      expect(error.type, TonikErrorType.encoding);
      expect(error.error, isA<EncodingException>());
      expect(server.requestCount, 0);
    },
  );
}
