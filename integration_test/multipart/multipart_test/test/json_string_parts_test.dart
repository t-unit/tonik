import 'dart:io';

import 'package:multipart_api/multipart_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';

void main() {
  test(
    'JSON string and enum parts are quoted and plain parts are not',
    () async {
      final server = await RawRequestServer.start();
      final api = MultipartApi(
        CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
      );

      final response = await api.postJsonStrings(
        body: const JsonStringsForm(
          label: 'hello',
          color: JsonStringColor.red,
          plainLabel: 'hello',
          plainColor: JsonStringColor.red,
        ),
      );

      expect(response, isTonikSuccess);
      final wire = MultipartWire(await server.takeRequest());
      expect(wire.parts, hasLength(4));
      expect(wire.single('label').bodyText, '"hello"');
      expect(
        ContentType.parse(wire.single('label').contentType!).mimeType,
        'application/json',
      );
      expect(wire.single('color').bodyText, '"red"');
      expect(
        ContentType.parse(wire.single('color').contentType!).mimeType,
        'application/json',
      );
      expect(wire.single('plainLabel').bodyText, 'hello');
      expect(wire.single('plainLabel').contentType, startsWith('text/plain'));
      expect(wire.single('plainColor').bodyText, 'red');
      expect(wire.single('plainColor').contentType, startsWith('text/plain'));
    },
  );

  test(
    'JSON string parts escape quotes, backslashes, and newlines once',
    () async {
      final server = await RawRequestServer.start();
      final api = MultipartApi(
        CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
      );

      final response = await api.postJsonStrings(
        body: const JsonStringsForm(
          label: 'say "hello"\\world\nnext',
          color: JsonStringColor.red,
          plainLabel: 'say "hello"\\world\nnext',
          plainColor: JsonStringColor.red,
        ),
      );

      expect(response, isTonikSuccess);
      final wire = MultipartWire(await server.takeRequest());
      expect(wire.single('label').bodyText, r'"say \"hello\"\\world\nnext"');
      expect(
        ContentType.parse(wire.single('label').contentType!).mimeType,
        'application/json',
      );
      expect(wire.single('plainLabel').bodyText, 'say "hello"\\world\nnext');
    },
  );

  test('empty JSON string parts retain their quotation marks', () async {
    final server = await RawRequestServer.start();
    final api = MultipartApi(
      CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
    );

    final response = await api.postJsonStrings(
      body: const JsonStringsForm(
        label: '',
        color: JsonStringColor.red,
        plainLabel: '',
        plainColor: JsonStringColor.red,
      ),
    );

    expect(response, isTonikSuccess);
    final wire = MultipartWire(await server.takeRequest());
    expect(wire.single('label').bodyText, '""');
    expect(
      ContentType.parse(wire.single('label').contentType!).mimeType,
      'application/json',
    );
    expect(wire.single('plainLabel').bodyText, '');
  });
}
