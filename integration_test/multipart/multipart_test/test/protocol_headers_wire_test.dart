import 'dart:convert';

import 'package:multipart_api/multipart_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  test(
    'effective media type and simple header accompany base64 bytes',
    () async {
      final server = await RawRequestServer.start();
      final api = MultipartApi(
        CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
      );

      final response = await api.postProtocolHeaders(
        body: const ByteForm(
          label: 'report',
          data: TonikFileBytes([0, 255, 128, 65], fileName: 'report.bin'),
        ),
        dataPartCount: 42,
      );
      expect(response, isTonikSuccess);

      final wire = MultipartWire(await server.takeRequest());
      expect(wire.parts, hasLength(2));
      final data = wire.single('data');
      expect(data.bodyBytes, ascii.encode('AP+AQQ=='));
      expect(data.contentType, 'application/octet-stream');
      expect(data.header('content-transfer-encoding'), 'base64');
      expect(data.header('x-part-count'), '42');
      expect(data.headers.toLowerCase().split('content-type:'), hasLength(2));
      expect(wire.single('label').bodyBytes, utf8.encode('report'));
    },
  );
}
