import 'package:dio/dio.dart';
import 'package:nullable_bodies_api/nullable_bodies_api.dart';
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

  NullableBodiesApi buildApi({required bool nullBody}) {
    return NullableBodiesApi(
      CustomServer(
        baseUrl: baseUrl,
        serverConfig: ServerConfig(
          baseOptions: BaseOptions(
            headers: {'X-Winner': nullBody ? 'null' : 'alice'},
          ),
        ),
      ),
    );
  }

  group('inline nullable string body', () {
    test('null body decodes to null', () async {
      final api = buildApi(nullBody: true);

      final response = await api.getWinnerInline();

      final success = response as TonikSuccess<String?>;
      expect(success.value, isNull);
    });

    test('non-null body decodes to the string', () async {
      final api = buildApi(nullBody: false);

      final response = await api.getWinnerInline();

      final success = response as TonikSuccess<String?>;
      expect(success.value, 'alice');
    });
  });

  group('referenced nullable string body', () {
    test('null body decodes to null', () async {
      final api = buildApi(nullBody: true);

      final response = await api.getWinnerRef();

      final success = response as TonikSuccess<String?>;
      expect(success.value, isNull);
    });

    test('non-null body decodes to the string', () async {
      final api = buildApi(nullBody: false);

      final response = await api.getWinnerRef();

      final success = response as TonikSuccess<String?>;
      expect(success.value, 'alice');
    });
  });
}
