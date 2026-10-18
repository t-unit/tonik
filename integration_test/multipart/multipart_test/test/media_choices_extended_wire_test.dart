// Generated public choice names exceed the line limit.
// ignore_for_file: lines_longer_than_80_chars

import 'package:multipart_api/multipart_api.dart' as api;
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

typedef _NestedBody = api.MultipartNestedMediaChoicesPostBodyBodyMultipartModel;
typedef _NestedJson =
    api.MultipartNestedMediaChoicesPostBodyBodyValuesArrayMultipartChoicesValuesOneOfModelApplicationJsonChoice1;
typedef _NestedXml =
    api.MultipartNestedMediaChoicesPostBodyBodyValuesArrayMultipartChoicesValuesOneOfModelApplicationXmlChoice2;
typedef _Base64Body = api.MultipartBase64MediaChoicesPostBodyBodyMultipartModel;
typedef _DataPdf =
    api.MultipartBase64MediaChoicesPostBodyBodyDataMultipartChoicesDataOneOfModelApplicationPdfChoice2;
typedef _FileOctet =
    api.MultipartBase64MediaChoicesPostBodyBodyFilesArrayMultipartChoicesFilesOneOfModelApplicationOctetStreamChoice1;
typedef _FilePdf =
    api.MultipartBase64MediaChoicesPostBodyBodyFilesArrayMultipartChoicesFilesOneOfModelApplicationPdfChoice2;
typedef _PlainJson =
    api.MultipartBase64MediaChoicesPostBodyBodyPlainMultipartChoicesPlainOneOfModelApplicationJsonChoice1;
typedef _MapBody = api.MultipartMapMediaChoicesPostBodyBodyMultipartModel;
typedef _MapJson =
    api.MultipartMapMediaChoicesPostBodyBodyMetadataMultipartChoicesMetadataOneOfModelApplicationJsonChoice1;
typedef _MapForm =
    api.MultipartMapMediaChoicesPostBodyBodyMetadataMultipartChoicesMetadataOneOfModelApplicationXWwwFormUrlencodedChoice2;
typedef _Base64JsonBody =
    api.MultipartBase64JsonChoicesPostBodyBodyMultipartModel;
typedef _ByteJson =
    api.MultipartBase64JsonChoicesPostBodyBodyDataMultipartChoicesDataOneOfModelApplicationJsonChoice1;
typedef _ByteXml =
    api.MultipartBase64JsonChoicesPostBodyBodyDataMultipartChoicesDataOneOfModelApplicationXmlChoice2;
typedef _EncodedJson =
    api.MultipartBase64JsonChoicesPostBodyBodyEncodedMultipartChoicesEncodedOneOfModelApplicationJsonChoice1;
typedef _EncodedXml =
    api.MultipartBase64JsonChoicesPostBodyBodyEncodedMultipartChoicesEncodedOneOfModelApplicationXmlChoice2;

void main() {
  test('nested arrays select one media type per inner array', () async {
    final server = await RawRequestServer.start();
    final client = api.MultipartApi(
      api.CustomServer(
        baseUrl: server.baseUrl,
        serverConfig: testServerConfig(),
      ),
    );

    final response = await client.postNestedMediaChoices(
      body: const _NestedBody(
        values: [
          _NestedJson([1, 2]),
          _NestedXml(TonikFileBytes([60, 120, 47, 62])),
          _NestedJson([3]),
        ],
      ),
    );

    expect(response, isTonikSuccess);
    final parts = MultipartWire(await server.takeRequest()).named('values');
    expect(parts, hasLength(3));
    expect(parts[0].bodyText, '[1,2]');
    expect(parts[0].contentType, startsWith('application/json'));
    expect(parts[1].bodyBytes, [60, 120, 47, 62]);
    expect(parts[1].contentType, 'application/xml');
    expect(parts[2].bodyText, '[3]');
    expect(parts[2].contentType, startsWith('application/json'));
  });

  test('base64 choices set transfer encoding on selected parts', () async {
    final server = await RawRequestServer.start();
    final client = api.MultipartApi(
      api.CustomServer(
        baseUrl: server.baseUrl,
        serverConfig: testServerConfig(),
      ),
    );

    final response = await client.postBase64MediaChoices(
      body: const _Base64Body(
        data: _DataPdf(TonikFileBytes([0, 255, 128, 65])),
        files: [
          _FileOctet(TonikFileBytes([1, 2])),
          _FilePdf(TonikFileBytes([3, 4])),
        ],
        plain: _PlainJson('ok'),
      ),
    );

    expect(response, isTonikSuccess);
    final wire = MultipartWire(await server.takeRequest());
    final data = wire.single('data');
    expect(data.bodyText, 'AP+AQQ==');
    expect(data.contentType, 'application/pdf');
    expect(data.header('content-transfer-encoding'), 'base64');
    final files = wire.named('files');
    expect(files, hasLength(2));
    expect(files[0].bodyText, 'AQI=');
    expect(files[0].contentType, 'application/octet-stream');
    expect(files[0].header('content-transfer-encoding'), 'base64');
    expect(files[1].bodyText, 'AwQ=');
    expect(files[1].contentType, 'application/pdf');
    expect(files[1].header('content-transfer-encoding'), 'base64');
    final plain = wire.single('plain');
    expect(plain.bodyText, '"ok"');
    expect(plain.header('content-transfer-encoding'), isNull);
  });

  test('JSON opaque bytes avoid a false base64 transfer claim', () async {
    final server = await RawRequestServer.start();
    final client = api.MultipartApi(
      api.CustomServer(
        baseUrl: server.baseUrl,
        serverConfig: testServerConfig(),
      ),
    );

    final response = await client.postBase64JsonChoices(
      body: const _Base64JsonBody(
        data: _ByteJson(TonikFileBytes([123, 125])),
        encoded: _EncodedXml(TonikFileBytes([60, 120, 47, 62])),
      ),
    );

    expect(response, isTonikSuccess);
    final wire = MultipartWire(await server.takeRequest());
    final data = wire.single('data');
    expect(data.bodyText, '{}');
    expect(data.contentType, 'application/json');
    expect(data.header('content-transfer-encoding'), isNull);
    final encoded = wire.single('encoded');
    expect(encoded.bodyText, 'PHgvPg==');
    expect(encoded.contentType, 'application/xml');
    expect(encoded.header('content-transfer-encoding'), 'base64');
  });

  test('contentEncoding base64 also permits opaque JSON bytes', () async {
    final server = await RawRequestServer.start();
    final client = api.MultipartApi(
      api.CustomServer(
        baseUrl: server.baseUrl,
        serverConfig: testServerConfig(),
      ),
    );

    final response = await client.postBase64JsonChoices(
      body: const _Base64JsonBody(
        data: _ByteXml(TonikFileBytes([1, 2])),
        encoded: _EncodedJson(TonikFileBytes([123, 34, 120, 34, 58, 49, 125])),
      ),
    );

    expect(response, isTonikSuccess);
    final wire = MultipartWire(await server.takeRequest());
    final data = wire.single('data');
    expect(data.bodyText, 'AQI=');
    expect(data.contentType, 'application/xml');
    expect(data.header('content-transfer-encoding'), 'base64');
    final encoded = wire.single('encoded');
    expect(encoded.bodyText, '{"x":1}');
    expect(encoded.contentType, 'application/json');
    expect(encoded.header('content-transfer-encoding'), isNull);
  });

  test('map form choice writes encoded fields', () async {
    final server = await RawRequestServer.start();
    final client = api.MultipartApi(
      api.CustomServer(
        baseUrl: server.baseUrl,
        serverConfig: testServerConfig(),
      ),
    );

    final response = await client.postMapMediaChoices(
      body: const _MapBody(metadata: _MapForm({'a': '1', 'b': '2'})),
    );

    expect(response, isTonikSuccess);
    final metadata = MultipartWire(await server.takeRequest())
        .single('metadata');
    expect(metadata.bodyText, 'a=1&b=2');
    expect(
      metadata.contentType,
      startsWith('application/x-www-form-urlencoded'),
    );
  });

  test('map JSON choice keeps JSON bytes and media type', () async {
    final server = await RawRequestServer.start();
    final client = api.MultipartApi(
      api.CustomServer(
        baseUrl: server.baseUrl,
        serverConfig: testServerConfig(),
      ),
    );

    final response = await client.postMapMediaChoices(
      body: const _MapBody(metadata: _MapJson({'a': '1'})),
    );

    expect(response, isTonikSuccess);
    final metadata = MultipartWire(await server.takeRequest())
        .single('metadata');
    expect(metadata.bodyText, '{"a":"1"}');
    expect(metadata.contentType, startsWith('application/json'));
  });
}
