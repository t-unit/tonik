import 'dart:io';

import 'package:multipart_3_1_api/multipart_3_1_api.dart' as oas31;
import 'package:multipart_api/multipart_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

import 'multipart_wire.dart';

void main() {
  test('preserves backslashes in native fields and file part names', () async {
    final server = await RawRequestServer.start();
    final api = MultipartApi(
      CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
    );
    final body = QuotedNamesForm.fromJson(const {
      r'profile\name': 'Ada',
      r'aliases\': ['Grace', 'Linus'],
      r'file\\path': 'Hi',
    });
    expect(body.toJson(), {
      r'profile\name': 'Ada',
      r'aliases\': ['Grace', 'Linus'],
      r'file\\path': 'Hi',
    });

    final response = await api.postQuotedNames(body: body);
    expect(response, isTonikSuccess);

    final wire = MultipartWire(await server.takeRequest());
    expect(wire.parts, hasLength(4));
    final profile = wire.parts.singleWhere((part) => part.bodyText == 'Ada');
    expect(
      profile.header('content-disposition'),
      r'form-data; name="profile\\name"',
    );
    expect(
      HeaderValue.parse(profile.header('content-disposition')!)
          .parameters['name'],
      r'profile\name',
    );
    final firstAlias = wire.parts.singleWhere(
      (part) => part.bodyText == 'Grace',
    );
    expect(
      firstAlias.header('content-disposition'),
      r'form-data; name="aliases\\"',
    );
    expect(
      HeaderValue.parse(firstAlias.header('content-disposition')!)
          .parameters['name'],
      r'aliases\',
    );
    final secondAlias = wire.parts.singleWhere(
      (part) => part.bodyText == 'Linus',
    );
    expect(
      HeaderValue.parse(secondAlias.header('content-disposition')!)
          .parameters['name'],
      r'aliases\',
    );
    final file = wire.parts.singleWhere((part) => part.bodyText == 'Hi');
    expect(
      file.header('content-disposition'),
      r'form-data; name="file\\\\path"; filename="file\\\\path"',
    );
    final disposition = HeaderValue.parse(file.header('content-disposition')!);
    expect(disposition.parameters['name'], r'file\\path');
    expect(disposition.parameters['filename'], r'file\\path');
    expect(file.bodyBytes, [72, 105]);
  });

  test('quotes explicit filenames for file path sources', () async {
    final directory = await Directory.systemTemp.createTemp('multipart-name-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/file.bin');
    await file.writeAsBytes([72, 105]);
    final server = await RawRequestServer.start();
    final api = MultipartApi(
      CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
    );

    final response = await api.postQuotedNames(
      body: QuotedNamesForm(
        profileBackslashName: 'Ada',
        aliasesBackslash: const [],
        fileBackslashBackslashPath: TonikFilePath(
          file.path,
          fileName: r'directory\file.bin',
        ),
      ),
    );
    expect(response, isTonikSuccess);

    final wire = MultipartWire(await server.takeRequest());
    expect(wire.parts, hasLength(2));
    final uploaded = wire.parts.singleWhere((part) => part.bodyText == 'Hi');
    expect(
      uploaded.header('content-disposition'),
      r'form-data; name="file\\\\path"; filename="directory\\file.bin"',
    );
    final disposition = HeaderValue.parse(
      uploaded.header('content-disposition')!,
    );
    expect(disposition.parameters['name'], r'file\\path');
    expect(disposition.parameters['filename'], r'directory\file.bin');
    expect(uploaded.bodyBytes, [72, 105]);
  });

  test('quotes custom-header multipart parts exactly once', () async {
    final server = await RawRequestServer.start();
    final api = MultipartApi(
      CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
    );

    final response = await api.postQuotedNamesWithHeaders(
      body: const QuotedNamesForm(
        profileBackslashName: 'Ada',
        aliasesBackslash: ['Grace'],
        fileBackslashBackslashPath: TonikFileBytes([
          72,
          105,
        ], fileName: r'directory\file.bin'),
      ),
      profileBackslashNamePartMeta: r'keep\value',
    );
    expect(response, isTonikSuccess);

    final wire = MultipartWire(await server.takeRequest());
    expect(wire.parts, hasLength(3));
    final profile = wire.parts.singleWhere((part) => part.bodyText == 'Ada');
    expect(
      profile.header('content-disposition'),
      r'form-data; name="profile\\name"',
    );
    expect(
      HeaderValue.parse(profile.header('content-disposition')!)
          .parameters['name'],
      r'profile\name',
    );
    expect(profile.header('x-part-meta'), 'keep%5Cvalue');
    final alias = wire.parts.singleWhere((part) => part.bodyText == 'Grace');
    expect(
      HeaderValue.parse(alias.header('content-disposition')!)
          .parameters['name'],
      r'aliases\',
    );
    final file = wire.parts.singleWhere((part) => part.bodyText == 'Hi');
    expect(
      file.header('content-disposition'),
      r'form-data; name="file\\\\path"; filename="directory\\file.bin"',
    );
    final disposition = HeaderValue.parse(file.header('content-disposition')!);
    expect(disposition.parameters['name'], r'file\\path');
    expect(disposition.parameters['filename'], r'directory\file.bin');
  });

  test('quotes names produced by exploded object properties', () async {
    final server = await RawRequestServer.start();
    final api = oas31.MultipartApi(
      oas31.CustomServer(
        baseUrl: server.baseUrl,
        serverConfig: testServerConfig(),
      ),
    );

    final response = await api.postQuotedDynamicNames(
      body: const oas31.QuotedObjectForm(
        details: oas31.QuotedNameDetails(nestedBackslashField: 'Ada'),
      ),
    );
    expect(response, isTonikSuccess);

    final part = MultipartWire(await server.takeRequest()).parts.single;
    expect(
      part.header('content-disposition'),
      r'form-data; name="nested\\field"',
    );
    expect(
      HeaderValue.parse(part.header('content-disposition')!).parameters['name'],
      r'nested\field',
    );
    expect(part.bodyText, 'Ada');
  });
}
