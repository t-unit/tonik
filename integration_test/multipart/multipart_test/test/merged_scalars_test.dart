import 'package:big_decimal/big_decimal.dart';
import 'package:multipart_api/multipart_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  test('encodes repeated date-time and decimal parts once', () async {
    final server = await RawRequestServer.start();
    final api = MultipartApi(
      CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
    );

    final response = await api.postMergedScalars(
      body: MergedScalarsUpload(
        mergedScalarsBase: MergedScalarsBase(
          $when: DateTime.utc(2026, 10, 23, 12, 34, 56),
          amount: BigDecimal.parse('0.00000001'),
        ),
        mergedScalarsExtension: MergedScalarsExtension(
          $when: DateTime.utc(2026, 10, 23, 12, 34, 56),
          amount: BigDecimal.parse('0.00000001'),
        ),
      ),
    );

    expect(response, isTonikSuccess);
    final wire = MultipartWire(await server.takeRequest());
    expect(wire.parts.map((part) => part.name), ['when', 'amount']);
    expect(wire.single('when').bodyText, '2026-10-23T12:34:56.000Z');
    expect(wire.single('amount').bodyText, '0.00000001');
  });

  test('encodes merged timestamps supplied by only one member', () async {
    final server = await RawRequestServer.start();
    final api = MultipartApi(
      CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
    );

    final response = await api.postMergedScalars(
      body: MergedScalarsUpload(
        mergedScalarsBase: const MergedScalarsBase($when: null),
        mergedScalarsExtension: MergedScalarsExtension(
          $when: DateTime.utc(2026, 10, 23, 12, 34, 56),
          optionalWhen: DateTime.utc(2026, 10, 24),
        ),
      ),
    );

    expect(response, isTonikSuccess);
    final wire = MultipartWire(await server.takeRequest());
    expect(wire.parts.map((part) => part.name), ['when', 'optionalWhen']);
    expect(wire.single('when').bodyText, '2026-10-23T12:34:56.000Z');
    expect(wire.single('optionalWhen').bodyText, '2026-10-24T00:00:00.000Z');
  });

  test('rejects conflicting timestamps before sending', () async {
    final server = await RawRequestServer.start();
    final api = MultipartApi(
      CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
    );

    final error = requireError(
      await api.postMergedScalars(
        body: MergedScalarsUpload(
          mergedScalarsBase: MergedScalarsBase(
            $when: DateTime.utc(2026, 10, 23),
          ),
          mergedScalarsExtension: MergedScalarsExtension(
            $when: DateTime.utc(2026, 10, 24),
          ),
        ),
      ),
    );

    expect(error.type, TonikErrorType.encoding);
    expect(error.error, isA<EncodingException>());
    expect(
      (error.error as EncodingException).message,
      'Conflicting values for multipart property "when".',
    );
    expect(server.requestCount, 0);
  });

  test(
    'rejects a required merged timestamp when both members are null',
    () async {
      final server = await RawRequestServer.start();
      final api = MultipartApi(
        CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
      );

      final error = requireError(
        await api.postMergedScalars(
          body: const MergedScalarsUpload(
            mergedScalarsBase: MergedScalarsBase($when: null),
            mergedScalarsExtension: MergedScalarsExtension($when: null),
          ),
        ),
      );

      expect(error.type, TonikErrorType.encoding);
      expect(error.error, isA<EncodingException>());
      expect(
        (error.error as EncodingException).message,
        'Required multipart property "when" is null.',
      );
      expect(server.requestCount, 0);
    },
  );
}
