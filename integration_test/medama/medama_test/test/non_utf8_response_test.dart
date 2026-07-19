import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:medama_api/medama_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  late ImposterServer imposterServer;
  late Directory fixtureDirectory;
  late String baseUrl;

  setUpAll(() async {
    fixtureDirectory = _writeFixtures();
    imposterServer = await setupImposterServer();
    baseUrl = 'http://localhost:${imposterServer.port}';
  });

  tearDownAll(() async {
    await imposterServer.stop();
    if (fixtureDirectory.existsSync()) {
      fixtureDirectory.deleteSync(recursive: true);
    }
  });

  EventApi buildEventApi(String responseCharsetCase) {
    return EventApi(
      CustomServer(
        baseUrl: baseUrl,
        serverConfig: ServerConfig(
          baseOptions: BaseOptions(
            headers: {'X-Response-Charset-Case': responseCharsetCase},
          ),
        ),
      ),
    );
  }

  group('successful response charsets', () {
    for (final testCase in _successfulCases) {
      test('decodes ${testCase.name}', () async {
        final response = await buildEventApi(testCase.id).getEventPing();

        final success = response as TonikSuccess<GetEventPingResponse>;
        final response200 = success.value as GetEventPingResponse200;
        expect(success.response.data, _fixtureBytes[testCase.fixture]);
        expect(response200.body.body, testCase.expected);
      });
    }
  });

  group('invalid response charsets', () {
    for (final testCase in _failureCases) {
      test('reports ${testCase.name} as a decoding error', () async {
        final response = await buildEventApi(testCase.id).getEventPing();

        final error = response as TonikError<GetEventPingResponse>;
        expect(error.type, TonikErrorType.decoding);
        expect(error.response?.data, _fixtureBytes[testCase.fixture]);
        expect(
          error.error,
          isA<ResponseDecodingException>().having(
            (exception) => exception.message,
            'message',
            contains(testCase.message),
          ),
        );
      });
    }
  });
}

Directory _writeFixtures() {
  final directory = Directory('imposter/charset-fixtures');
  if (directory.existsSync()) {
    directory.deleteSync(recursive: true);
  }
  directory.createSync();

  for (final entry in _fixtureBytes.entries) {
    File(
      '${directory.path}/${entry.key}',
    ).writeAsBytesSync(entry.value, flush: true);
  }
  return directory;
}

final _fixtureBytes = <String, List<int>>{
  'utf8.bin': utf8.encode('Grüße 👋'),
  'ascii.bin': const [
    0x70,
    0x6c,
    0x61,
    0x69,
    0x6e,
    0x20,
    0x41,
    0x53,
    0x43,
    0x49,
    0x49,
  ],
  'iso-8859-1.bin': const [
    0x63,
    0x61,
    0x66,
    0xe9,
    0x20,
    0x64,
    0xe9,
    0x6a,
    0xe0,
    0x20,
    0x76,
    0x75,
  ],
  'iso-8859-15.bin': const [
    0x50,
    0x72,
    0x69,
    0x63,
    0x65,
    0x3a,
    0x20,
    0x31,
    0x30,
    0x20,
    0xa4,
  ],
  'windows-1252.bin': const [
    0x93,
    0x54,
    0x6f,
    0x6e,
    0x69,
    0x6b,
    0x94,
    0x20,
    0x80,
  ],
  'windows-1251.bin': const [0xcf, 0xf0, 0xe8, 0xe2, 0xe5, 0xf2],
  'malformed-windows-1252.bin': const [0x81],
  'shift-jis.bin': const [0x93, 0xfa, 0x96, 0x7b],
  'euc-jp.bin': const [0xc6, 0xfc, 0xcb, 0xdc],
  'euc-kr.bin': const [0xc7, 0xd1, 0xb1, 0xb9],
  'gbk.bin': const [0xd6, 0xd0, 0xce, 0xc4],
  'utf-16.bin': const [
    0xfe,
    0xff,
    0x00,
    0x48,
    0x00,
    0x69,
    0x00,
    0x20,
    0x20,
    0xac,
  ],
  'utf-16le.bin': const [
    0x48,
    0x00,
    0x69,
    0x00,
    0x20,
    0x00,
    0xac,
    0x20,
  ],
  'utf-16be.bin': const [
    0x00,
    0x48,
    0x00,
    0x69,
    0x00,
    0x20,
    0x20,
    0xac,
  ],
  'utf-32.bin': const [
    0x00,
    0x00,
    0xfe,
    0xff,
    0x00,
    0x00,
    0x00,
    0x48,
    0x00,
    0x00,
    0x00,
    0x69,
    0x00,
    0x00,
    0x00,
    0x20,
    0x00,
    0x00,
    0x20,
    0xac,
  ],
  'utf-32le.bin': const [
    0x48,
    0x00,
    0x00,
    0x00,
    0x69,
    0x00,
    0x00,
    0x00,
    0x20,
    0x00,
    0x00,
    0x00,
    0xac,
    0x20,
    0x00,
    0x00,
  ],
  'utf-32be.bin': const [
    0x00,
    0x00,
    0x00,
    0x48,
    0x00,
    0x00,
    0x00,
    0x69,
    0x00,
    0x00,
    0x00,
    0x20,
    0x00,
    0x00,
    0x20,
    0xac,
  ],
};

const _successfulCases =
    <({String id, String name, String fixture, String expected})>[
      (
        id: 'utf8-default',
        name: 'UTF-8 by default',
        fixture: 'utf8.bin',
        expected: 'Grüße 👋',
      ),
      (
        id: 'utf8-alias',
        name: 'the utf8 alias',
        fixture: 'utf8.bin',
        expected: 'Grüße 👋',
      ),
      (
        id: 'quoted-uppercase-utf8',
        name: 'a quoted case-insensitive UTF-8 declaration',
        fixture: 'utf8.bin',
        expected: 'Grüße 👋',
      ),
      (
        id: 'us-ascii',
        name: 'US-ASCII',
        fixture: 'ascii.bin',
        expected: 'plain ASCII',
      ),
      (
        id: 'iso-8859-1',
        name: 'ISO-8859-1',
        fixture: 'iso-8859-1.bin',
        expected: 'café déjà vu',
      ),
      (
        id: 'iso-8859-15',
        name: 'ISO-8859-15',
        fixture: 'iso-8859-15.bin',
        expected: 'Price: 10 €',
      ),
      (
        id: 'windows-1252',
        name: 'Windows-1252',
        fixture: 'windows-1252.bin',
        expected: '“Tonik” €',
      ),
      (
        id: 'windows-1251',
        name: 'Windows-1251',
        fixture: 'windows-1251.bin',
        expected: 'Привет',
      ),
      (
        id: 'shift-jis',
        name: 'Shift_JIS',
        fixture: 'shift-jis.bin',
        expected: '日本',
      ),
      (
        id: 'windows-31j',
        name: 'the Windows-31J alias',
        fixture: 'shift-jis.bin',
        expected: '日本',
      ),
      (
        id: 'euc-jp',
        name: 'EUC-JP',
        fixture: 'euc-jp.bin',
        expected: '日本',
      ),
      (
        id: 'gbk',
        name: 'GBK',
        fixture: 'gbk.bin',
        expected: '中文',
      ),
      (
        id: 'x-gbk',
        name: 'the X-GBK alias',
        fixture: 'gbk.bin',
        expected: '中文',
      ),
      (
        id: 'utf-16',
        name: 'UTF-16 with a byte-order mark',
        fixture: 'utf-16.bin',
        expected: 'Hi €',
      ),
      (
        id: 'utf-16le',
        name: 'explicit UTF-16LE without a byte-order mark',
        fixture: 'utf-16le.bin',
        expected: 'Hi €',
      ),
      (
        id: 'utf-16be',
        name: 'explicit UTF-16BE without a byte-order mark',
        fixture: 'utf-16be.bin',
        expected: 'Hi €',
      ),
      (
        id: 'utf-32',
        name: 'UTF-32 with a byte-order mark',
        fixture: 'utf-32.bin',
        expected: 'Hi €',
      ),
      (
        id: 'utf-32le',
        name: 'explicit UTF-32LE without a byte-order mark',
        fixture: 'utf-32le.bin',
        expected: 'Hi €',
      ),
      (
        id: 'utf-32be',
        name: 'explicit UTF-32BE without a byte-order mark',
        fixture: 'utf-32be.bin',
        expected: 'Hi €',
      ),
    ];

const _failureCases =
    <({String id, String name, String fixture, String message})>[
      (
        id: 'unsupported',
        name: 'an unknown charset',
        fixture: 'ascii.bin',
        message: 'Unsupported response charset: "made-up"',
      ),
      (
        id: 'gb18030',
        name: 'GB18030 rather than treating it as GBK',
        fixture: 'ascii.bin',
        message: 'Unsupported response charset: "gb18030"',
      ),
      (
        id: 'euc-kr',
        name: 'EUC-KR rather than returning corrupt Unicode',
        fixture: 'euc-kr.bin',
        message: 'Unsupported response charset: "euc-kr"',
      ),
      (
        id: 'cp949',
        name: 'the CP949 alias rather than returning corrupt Unicode',
        fixture: 'euc-kr.bin',
        message: 'Unsupported response charset: "cp949"',
      ),
      (
        id: 'empty',
        name: 'an empty charset',
        fixture: 'ascii.bin',
        message: 'Response charset must not be empty',
      ),
      (
        id: 'malformed',
        name: 'a malformed Content-Type',
        fixture: 'ascii.bin',
        message: 'Invalid response Content-Type header',
      ),
      (
        id: 'malformed-bytes',
        name: 'malformed bytes for the declared charset',
        fixture: 'malformed-windows-1252.bin',
        message: 'Failed to decode response body using charset "windows-1252"',
      ),
    ];
