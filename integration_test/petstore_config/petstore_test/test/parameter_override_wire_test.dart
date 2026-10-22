import 'package:petstore_overrides_api/petstore_overrides_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';

void main() {
  test('inline parameter overrides change Dart names only', () async {
    final server = await RawRequestServer.start(responseStatusCode: 400);
    final petApi = CreatureApiApi(
      CustomServer(
        baseUrl: '${server.baseUrl}/api/v3',
        serverConfig: testServerConfig(),
      ),
    );

    await petApi.patchPetFromForm(id: 1, displayName: 'Fido');

    final request = await server.takeRequest();
    expect(request.uri.path, '/api/v3/pet/1');
    expect(request.uri.queryParameters['name'], 'Fido');
    expect(request.uri.queryParameters.containsKey('displayName'), isFalse);
  });
}
