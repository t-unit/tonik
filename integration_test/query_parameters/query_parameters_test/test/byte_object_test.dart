import 'package:dio/dio.dart';
import 'package:query_parameters_api/query_parameters_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  late ImposterServer imposterServer;
  late String baseUrl;

  setUpAll(() async {
    imposterServer = await setupImposterServer();
    baseUrl = 'http://localhost:${imposterServer.port}/v1';
  });

  QueryApi buildQueryApi({required String responseStatus}) {
    return QueryApi(
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

  group('form object with byte property', () {
    test('base64-encodes byte property then percent-encodes on the wire',
        () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testFormByteObject(
        filter: const Filter(
          signature: TonikFileBytes([0xDE, 0xAD, 0xBE, 0xEF]),
        ),
      );

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(
        success.response.requestOptions.uri.query,
        'signature=3q2%2B7w%3D%3D',
      );
    });

    test('decoder round-trips the encoder output for a byte property', () {
      const filter = Filter(
        signature: TonikFileBytes([0xDE, 0xAD, 0xBE, 0xEF]),
        label: 'release',
      );

      final encoded = filter.parameterProperties();
      final wire = [
        for (final entry in encoded.entries)
          '${entry.key}=${entry.value}',
      ].join('&');

      final decoded = Filter.fromForm(wire, explode: true);
      expect(decoded.signature.toBytes(), [0xDE, 0xAD, 0xBE, 0xEF]);
      expect(decoded.label, 'release');
    });
  });
}
