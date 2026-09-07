import 'dart:async';
import 'dart:io';

import 'package:test/test.dart';
import 'package:test_helpers/src/imposter_server.dart';

void main() {
  test('hold the shared server until cancellation', () async {
    final server = await setupImposterServer();
    await File(Platform.environment['TONIK_TEST_PORT_FILE']!)
        .writeAsString('${server.port}');
    print('READY TO CANCEL');
    await Completer<void>().future;
  });
}
