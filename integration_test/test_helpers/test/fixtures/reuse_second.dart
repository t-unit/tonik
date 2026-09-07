import 'dart:io';

import 'package:test/test.dart';
import 'package:test_helpers/src/imposter_server.dart';

void main() {
  late ImposterServer server;
  setUpAll(() async {
    expect(
      File(Platform.environment['TONIK_TEST_PORT_FILE']!).existsSync(),
      isTrue,
    );
    server = await setupImposterServer();
  });
  test('reuse the same server with no previous request', () async {
    expect(
      '${server.port}',
      await File(Platform.environment['TONIK_TEST_PORT_FILE']!).readAsString(),
    );
    final client = HttpClient();
    addTearDown(() => client.close(force: true));
    final request = await client.getUrl(
      Uri.parse('http://localhost:${server.port}/system/store/tonik/last'),
    );
    final response = await request.close();
    await response.drain<void>();
    expect(response.statusCode, 404);
  });
}
