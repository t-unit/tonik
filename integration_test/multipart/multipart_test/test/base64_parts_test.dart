import 'dart:convert';
import 'dart:io';

import 'package:multipart_api/multipart_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

import 'multipart_wire.dart';

void main() {
  test('sends decoded format byte data as ASCII base64', () async {
    final server = await RawRequestServer.start(
      responseStatusCode: 200,
      responseHeaders: {'content-type': 'application/json'},
      responseBody: utf8.encode('{"success":true}'),
    );
    final api = MultipartApi(
      CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
    );
    final body = ByteForm.fromJson(const {
      'label': 'encoded',
      'data': 'AP+AQQ==',
    });
    expect(body.data.toBytes(), [0, 255, 128, 65]);
    expect(body.toJson(), {'label': 'encoded', 'data': 'AP+AQQ=='});

    final response = await api.postByteField(body: body);
    expect(response, isTonikSuccess);

    final wire = MultipartWire(await server.takeRequest());
    final data = wire.single('data');
    expect(data.bodyText, 'AP+AQQ==');
    expect(data.bodyBytes, [65, 80, 43, 65, 81, 81, 61, 61]);
    expect(data.contentType, 'application/octet-stream');
    expect(data.header('content-transfer-encoding'), 'base64');
    expect(data.filename, 'data');
    expect(wire.single('label').bodyText, 'encoded');
    expect(wire.single('label').header('content-transfer-encoding'), isNull);
  });

  test(
    'sends a Unicode filename when base64 adds the only custom part header',
    () async {
      final server = await RawRequestServer.start(
        responseStatusCode: 200,
        responseHeaders: {'content-type': 'application/json'},
        responseBody: utf8.encode('{"success":true}'),
      );
      final api = MultipartApi(
        CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
      );

      final response = await api.postByteField(
        body: const ByteForm(
          label: 'report',
          data: TonikFileBytes([0, 255, 128, 65], fileName: '報告.txt'),
        ),
      );
      expect(response, isTonikSuccess);

      final data = MultipartWire(await server.takeRequest()).single('data');
      expect(latin1.encode(data.filename!), [
        229,
        160,
        177,
        229,
        145,
        138,
        46,
        116,
        120,
        116,
      ]);
      expect(
        utf8.decode(latin1.encode(data.header('content-disposition')!)),
        'form-data; name="data"; filename="報告.txt"',
      );
      expect(data.bodyBytes, [65, 80, 43, 65, 81, 81, 61, 61]);
      expect(data.header('content-transfer-encoding'), 'base64');
      expect(data.contentType, 'application/octet-stream');
    },
  );

  test(
    'preserves Unicode filenames on base64 and sibling binary parts',
    () async {
      final server = await RawRequestServer.start();
      final api = MultipartApi(
        CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
      );

      final response = await api.postBase64Parts(
        body: const Base64PartsForm(
          files: [
            TonikFileBytes([0, 255, 128, 65], fileName: '報告.txt'),
          ],
          binary: TonikFileBytes([0, 255, 128, 65], fileName: '画像.png'),
        ),
        filesPartLabel: 'images',
      );
      expect(response, isTonikSuccess);

      final wire = MultipartWire(await server.takeRequest());
      expect(wire.parts, hasLength(2));
      final encoded = wire.single('files');
      expect(latin1.encode(encoded.filename!), [
        229,
        160,
        177,
        229,
        145,
        138,
        46,
        116,
        120,
        116,
      ]);
      expect(
        utf8.decode(latin1.encode(encoded.header('content-disposition')!)),
        'form-data; name="files"; filename="報告.txt"',
      );
      expect(encoded.bodyBytes, [65, 80, 43, 65, 81, 81, 61, 61]);
      expect(encoded.header('content-transfer-encoding'), 'base64');
      expect(encoded.header('x-part-label'), 'images');
      expect(encoded.contentType, 'image/png');
      final binary = wire.single('binary');
      expect(latin1.encode(binary.filename!), [
        231,
        148,
        187,
        229,
        131,
        143,
        46,
        112,
        110,
        103,
      ]);
      expect(
        utf8.decode(latin1.encode(binary.header('content-disposition')!)),
        'form-data; name="binary"; filename="画像.png"',
      );
      expect(binary.bodyBytes, [0, 255, 128, 65]);
      expect(binary.header('content-transfer-encoding'), isNull);
    },
  );

  test('base64 encodes file paths and preserves the filename', () async {
    final directory = await Directory.systemTemp.createTemp('multipart-byte-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/report.txt');
    await file.writeAsBytes([0, 255, 128, 65]);
    final server = await RawRequestServer.start(
      responseStatusCode: 200,
      responseHeaders: {'content-type': 'application/json'},
      responseBody: utf8.encode('{"success":true}'),
    );
    final api = MultipartApi(
      CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
    );

    final response = await api.postByteField(
      body: ByteForm(
        label: 'path',
        data: TonikFilePath(file.path, fileName: 'report.txt'),
      ),
    );

    expect(response, isTonikSuccess);

    final data = MultipartWire(await server.takeRequest()).single('data');
    expect(data.bodyText, 'AP+AQQ==');
    expect(data.contentType, 'application/octet-stream');
    expect(data.filename, 'report.txt');
    expect(data.header('content-transfer-encoding'), 'base64');
  });

  test(
    'repeats base64 array parts while preserving raw binary and headers',
    () async {
      final server = await RawRequestServer.start();
      final api = MultipartApi(
        CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
      );

      final response = await api.postBase64Parts(
        body: const Base64PartsForm(
          files: [
            TonikFileBytes([0, 255, 128, 65], fileName: 'first.png'),
            TonikFileBytes([72, 105], fileName: 'second.png'),
          ],
          binary: TonikFileBytes([0, 255, 128, 65], fileName: 'raw.bin'),
        ),
        filesPartLabel: 'images',
        filesCOnTeNtTrAnSfErEnCoDiNg: 'BASE64',
      );
      expect(response, isTonikSuccess);

      final wire = MultipartWire(await server.takeRequest());
      expect(wire.parts, hasLength(3));
      final files = wire.named('files');
      expect(files, hasLength(2));
      expect(files[0].bodyText, 'AP+AQQ==');
      expect(files[0].filename, 'first.png');
      expect(files[0].contentType, 'image/png');
      expect(files[0].header('content-transfer-encoding'), 'base64');
      expect(
        files[0].headers.toLowerCase().split('content-transfer-encoding'),
        hasLength(2),
      );
      expect(files[0].header('x-part-label'), 'images');
      expect(files[1].bodyText, 'SGk=');
      expect(files[1].filename, 'second.png');
      expect(files[1].contentType, 'image/png');
      expect(files[1].header('content-transfer-encoding'), 'base64');
      expect(files[1].header('x-part-label'), 'images');
      expect(wire.single('binary').bodyBytes, [0, 255, 128, 65]);
      expect(wire.single('binary').header('content-transfer-encoding'), isNull);
    },
  );

  test(
    'generates the transfer header when only a custom header is supplied',
    () async {
      final server = await RawRequestServer.start();
      final api = MultipartApi(
        CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
      );

      final response = await api.postBase64Parts(
        body: const Base64PartsForm(
          files: [
            TonikFileBytes([72, 105]),
          ],
        ),
        filesPartLabel: 'single',
      );
      expect(response, isTonikSuccess);

      final wire = MultipartWire(await server.takeRequest());
      expect(wire.parts, hasLength(1));
      expect(wire.single('files').bodyText, 'SGk=');
      expect(
        wire.single('files').header('content-transfer-encoding'),
        'base64',
      );
      expect(wire.single('files').header('x-part-label'), 'single');
    },
  );

  test('rejects empty custom multipart parts before sending', () async {
    final server = await RawRequestServer.start();
    final api = MultipartApi(
      CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
    );

    final response = await api.postBase64Parts(
      body: const Base64PartsForm(files: []),
      filesPartLabel: 'empty',
    );
    final error = requireError(response);
    expect(error.type, TonikErrorType.encoding);
    expect(error.error, isA<EncodingException>());
    expect(server.requestCount, 0);
  });

  test('omits empty base64 arrays when a binary part is present', () async {
    final server = await RawRequestServer.start();
    final api = MultipartApi(
      CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
    );

    final response = await api.postBase64Parts(
      body: const Base64PartsForm(
        files: [],
        binary: TonikFileBytes([0, 255, 128, 65], fileName: 'raw.bin'),
      ),
      filesPartLabel: 'empty',
    );
    expect(response, isTonikSuccess);

    final wire = MultipartWire(await server.takeRequest());
    expect(wire.parts, hasLength(1));
    expect(wire.named('files'), isEmpty);
    expect(wire.single('binary').filename, 'raw.bin');
    expect(wire.single('binary').bodyBytes, [0, 255, 128, 65]);
  });

  test(
    'rejects a transfer header that disagrees with base64 serialization',
    () async {
      final server = await RawRequestServer.start();
      final api = MultipartApi(
        CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
      );

      final response = await api.postBase64Parts(
        body: const Base64PartsForm(
          files: [
            TonikFileBytes([72, 105]),
          ],
        ),
        filesPartLabel: 'conflict',
        filesCOnTeNtTrAnSfErEnCoDiNg: 'binary',
      );

      expect(response, isTonikError);
      final error = requireError(response);
      expect(error.type, TonikErrorType.encoding);
      expect(error.error, isA<EncodingException>());
    },
  );
}
