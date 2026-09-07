import 'dart:io';

import 'package:test/test.dart';
import 'package:test_helpers/src/imposter_server.dart';

void main() {
  test('start a private server for a direct test invocation', () async {
    expect(Platform.environment['TONIK_IMPOSTER_PORT'], isNull);
    final server = await setupImposterServer();
    expect(server.sharedPort, isNull);
    final socket = await Socket.connect('localhost', server.port);
    socket.destroy();
    await server.stop();
    await expectLater(
      Socket.connect('localhost', server.port),
      throwsA(isA<SocketException>()),
    );
  });
}
