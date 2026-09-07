import 'package:multipart_3_1_api/multipart_3_1_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

import 'multipart_wire.dart';

void main() {
  test(
    'contentEncoding base64 serializes a scalar with one transfer header',
    () async {
      final server = await RawRequestServer.start();
      final api = Multipart31Api(
        CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
      );

      final response = await api.postContentEncodedBase64(
        body: const ContentEncodedBase64Form(
          data: TonikFileBytes([0, 255, 128, 65], fileName: 'report.bin'),
        ),
      );
      expect(response, isTonikSuccess);

      final wire = MultipartWire(await server.takeRequest());
      expect(wire.parts, hasLength(1));
      final data = wire.single('data');
      expect(data.filename, 'report.bin');
      expect(data.bodyText, 'AP+AQQ==');
      expect(data.bodyBytes, [65, 80, 43, 65, 81, 81, 61, 61]);
      expect(data.header('content-transfer-encoding'), 'base64');
      expect(
        data.headers.toLowerCase().split('content-transfer-encoding'),
        hasLength(2),
      );
    },
  );

  test(
    'contentEncoding base64 arrays retain repeated names and image media type',
    () async {
      final server = await RawRequestServer.start();
      final api = Multipart31Api(
        CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
      );

      final response = await api.postContentEncodedBase64Array(
        body: const ContentEncodedBase64ArrayForm(
          files: [
            TonikFileBytes([0, 255, 128, 65], fileName: 'first.png'),
            TonikFileBytes([72, 105], fileName: 'second.png'),
          ],
        ),
      );
      expect(response, isTonikSuccess);

      final wire = MultipartWire(await server.takeRequest());
      expect(wire.parts, hasLength(2));
      final files = wire.named('files');
      expect(files, hasLength(2));
      expect(files[0].filename, 'first.png');
      expect(files[0].contentType, 'image/png');
      expect(files[0].bodyBytes, [65, 80, 43, 65, 81, 81, 61, 61]);
      expect(files[0].header('content-transfer-encoding'), 'base64');
      expect(
        files[0].headers.toLowerCase().split('content-transfer-encoding'),
        hasLength(2),
      );
      expect(files[1].filename, 'second.png');
      expect(files[1].contentType, 'image/png');
      expect(files[1].bodyBytes, [83, 71, 107, 61]);
      expect(files[1].header('content-transfer-encoding'), 'base64');
      expect(
        files[1].headers.toLowerCase().split('content-transfer-encoding'),
        hasLength(2),
      );
    },
  );
}
