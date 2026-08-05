import 'package:composition_api/composition_api.dart';
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

  CompositionApi buildApi(String responseBody) {
    return CompositionApi(
      CustomServer(
        baseUrl: baseUrl,
        serverConfig: testServerConfig(
          headers: {'X-Response-Body': responseBody},
        ),
      ),
    );
  }

  group('getStandaloneNull', () {
    test('decodes a null response body to null', () async {
      final api = buildApi('null');
      final result = await api.getStandaloneNull();

      final success = requireSuccess(result);
      expect(success.value.body, isNull);
      expect(success.value.xNullHeader, isNull);
    });

    test('returns a decoding error for a non-null response body', () async {
      final api = buildApi('{}');
      final result = await api.getStandaloneNull();

      final error = requireError(result);
      expect(error.type, TonikErrorType.decoding);
    });
  });
}
