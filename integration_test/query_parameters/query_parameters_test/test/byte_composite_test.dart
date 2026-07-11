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

  group('anyOf byte member', () {
    test('base64-encodes byte member then percent-encodes on the wire',
        () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testFormByteComposite(
        anyOfByte: const [
          AnyOfByte(tonikFile: TonikFileBytes([0xDE, 0xAD, 0xBE, 0xEF])),
        ],
      );

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(
        success.response.requestOptions.uri.query,
        'anyOfByte=3q2%2B7w%3D%3D',
      );
    });

    test('decoder round-trips the encoder output', () {
      const value = AnyOfByte(
        tonikFile: TonikFileBytes([0xDE, 0xAD, 0xBE, 0xEF]),
      );

      final wire = value.toSimple(
        explode: true,
        allowEmpty: false,
        literal: true,
      );
      final decoded = AnyOfByte.fromSimple(wire, explode: true);

      expect(decoded.tonikFile?.toBytes(), [0xDE, 0xAD, 0xBE, 0xEF]);
    });
  });

  group('oneOf byte member', () {
    test('base64-encodes byte member then percent-encodes on the wire',
        () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testFormByteComposite(
        oneOfByte: const <OneOfByte>[
          OneOfByteBase64(TonikFileBytes([0xDE, 0xAD, 0xBE, 0xEF])),
        ],
      );

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(
        success.response.requestOptions.uri.query,
        'oneOfByte=3q2%2B7w%3D%3D',
      );
    });

    test('decoder round-trips the encoder output', () {
      const value = OneOfByteBase64(TonikFileBytes([0xDE, 0xAD, 0xBE, 0xEF]));

      final wire = value.toSimple(
        explode: true,
        allowEmpty: false,
        literal: true,
      );
      final decoded = OneOfByte.fromSimple(wire, explode: true);

      expect(decoded, isA<OneOfByteBase64>());
      expect(
        (decoded as OneOfByteBase64).value.toBytes(),
        [0xDE, 0xAD, 0xBE, 0xEF],
      );
    });
  });

  group('allOf byte member', () {
    test('base64-encodes byte member then percent-encodes on the wire',
        () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testFormByteComposite(
        allOfByte: const [
          AllOfByte(tonikFile: TonikFileBytes([0xDE, 0xAD, 0xBE, 0xEF])),
        ],
      );

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(
        success.response.requestOptions.uri.query,
        'allOfByte=3q2%2B7w%3D%3D',
      );
    });

    test('decoder round-trips the encoder output', () {
      const value = AllOfByte(
        tonikFile: TonikFileBytes([0xDE, 0xAD, 0xBE, 0xEF]),
      );

      final wire = value.toSimple(
        explode: true,
        allowEmpty: false,
        literal: true,
      );
      final decoded = AllOfByte.fromSimple(wire, explode: true);

      expect(decoded.tonikFile.toBytes(), [0xDE, 0xAD, 0xBE, 0xEF]);
    });
  });
}
