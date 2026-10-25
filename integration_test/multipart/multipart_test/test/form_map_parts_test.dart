import 'dart:io';

import 'package:multipart_3_1_api/multipart_3_1_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  test('form-encodes map entries and omits null values', () async {
    final server = await RawRequestServer.start();
    final api = Multipart31Api(CustomServer(baseUrl: server.baseUrl));

    expect(
      await api.postUrlEncodedMap(
        body: const UrlEncodedMapForm(
          attrs: {'a b': 'x y', 'symbols': '+&=', 'count': 1, 'skip': null},
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

  test('sends an empty map as an empty form part', () async {
    final server = await RawRequestServer.start();
    final api = Multipart31Api(CustomServer(baseUrl: server.baseUrl));

    expect(
      await api.postUrlEncodedMap(body: const UrlEncodedMapForm(attrs: {})),
      isTonikSuccess,
    );

    final part = MultipartWire(await server.takeRequest()).single('attrs');
    expect(
      ContentType.parse(part.contentType!).mimeType,
      'application/x-www-form-urlencoded',
    );
    expect(part.bodyText, '');
  });

  test('rejects a nested map before sending the form part', () async {
    final server = await RawRequestServer.start();
    final api = Multipart31Api(CustomServer(baseUrl: server.baseUrl));

    final error = requireError(
      await api.postUrlEncodedMap(
        body: const UrlEncodedMapForm(
          attrs: {
            'nested': {'key': 'value'},
          },
        ),
      ),
    );

    expect(error.type, TonikErrorType.encoding);
    expect(error.error, isA<EncodingException>());
    expect(server.requestCount, 0);
  });

  test('rejects a nested list before sending the form part', () async {
    final server = await RawRequestServer.start();
    final api = Multipart31Api(CustomServer(baseUrl: server.baseUrl));

    final error = requireError(
      await api.postUrlEncodedMap(
        body: const UrlEncodedMapForm(
          attrs: {
            'nested': ['value'],
          },
        ),
      ),
    );

    expect(error.type, TonikErrorType.encoding);
    expect(error.error, isA<EncodingException>());
    expect(server.requestCount, 0);
  });
}
