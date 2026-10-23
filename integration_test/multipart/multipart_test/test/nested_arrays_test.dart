import 'package:multipart_3_1_api/multipart_3_1_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  test('rejects exploded nested integer arrays before sending', () async {
    final server = await RawRequestServer.start();
    final api = Multipart31Api(CustomServer(baseUrl: server.baseUrl));

    final response = await api.postNestedArrays(
      body: const NestedArrayForm(
        labels: ['valid'],
        integers: [
          [1, 2],
          [3],
        ],
      ),
    );

    final error = requireError(response);
    expect(error.type, TonikErrorType.encoding);
    expect(error.error, isA<EncodingException>());
    expect(
      (error.error as EncodingException).message,
      'Arrays of arrays are not supported for multipart encoding '
      '(property: integers).',
    );
    expect(server.requestCount, 0);
  });

  test('rejects packed nested string arrays before sending', () async {
    final server = await RawRequestServer.start();
    final api = Multipart31Api(CustomServer(baseUrl: server.baseUrl));

    final response = await api.postNestedArrays(
      body: const NestedArrayForm(
        labels: ['valid'],
        strings: [
          ['a', 'b'],
        ],
      ),
    );

    final error = requireError(response);
    expect(error.type, TonikErrorType.encoding);
    expect(error.error, isA<EncodingException>());
    expect(
      (error.error as EncodingException).message,
      'Arrays of arrays are not supported for multipart encoding '
      '(property: strings).',
    );
    expect(server.requestCount, 0);
  });

  test(
    'allows ordinary arrays when optional nested arrays are absent',
    () async {
      final server = await RawRequestServer.start();
      final api = Multipart31Api(CustomServer(baseUrl: server.baseUrl));

      final response = await api.postNestedArrays(
        body: const NestedArrayForm(labels: ['alpha', 'beta']),
      );

      expect(response, isTonikSuccess);
      final wire = MultipartWire(await server.takeRequest());
      expect(wire.parts, hasLength(2));
      final labels = wire.named('labels');
      expect(labels, hasLength(2));
      expect(labels[0].bodyText, 'alpha');
      expect(labels[1].bodyText, 'beta');
      expect(wire.named('integers'), isEmpty);
      expect(wire.named('strings'), isEmpty);
    },
  );
}
