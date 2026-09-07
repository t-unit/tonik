import 'dart:io';

import 'package:test/test.dart';
import 'package:test_helpers/src/imposter_server.dart';

void main() {
  late ImposterServer server;
  setUpAll(() async {
    server = await setupImposterServer();
  });
  tearDownAll(() async {
    await File(Platform.environment['TONIK_TEST_PORT_FILE']!)
        .writeAsString('${server.port}');
  });
  test('leave a request record for the next file', () async {
    final client = HttpClient();
    addTearDown(() => client.close(force: true));
    final request = await client.putUrl(
      Uri.parse('http://localhost:${server.port}/system/store/tonik/last'),
    );
    request.headers.contentType = ContentType.json;
    request.write('{"leftBy":"first file"}');
    final response = await request.close();
    await response.drain<void>();
    expect(response.statusCode, 201);
    // Keep this file active long enough to expose accidental parallel startup.
    await Future<void>.delayed(const Duration(milliseconds: 200));
  });
}
