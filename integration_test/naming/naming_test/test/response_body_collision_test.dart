import 'package:naming_api/src/api_client/default_api2.dart';
import 'package:naming_api/src/server/server.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';

void main() {
  test('keeps the decoded body and the raw body_ header', () async {
    final imposterServer = await setupImposterServer();
    final api = DefaultApi2(
      CustomServer(
        baseUrl: 'http://localhost:${imposterServer.port}',
        serverConfig: testServerConfig(),
      ),
    );

    final result = await api.getResponseWithNormalizedBodyHeader();

    expect(
      result,
      isTonikSuccess,
    );
    final value = requireSuccess(result).value;
    expect(value.body, 'header-value');
    expect(value.body2.id, 'body-value');
  });
}
