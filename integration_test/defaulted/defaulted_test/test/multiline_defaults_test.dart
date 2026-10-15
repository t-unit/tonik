import 'package:defaulted_api/defaulted_api.dart';
import 'package:defaulted_api/src/operation/get_multiline_defaults.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';

void main() {
  test('property constants preserve leading whitespace and newlines', () {
    expect(MultilineDefaults.lineDefault.codeUnits, [10]);
    expect(MultilineDefaults.paddedDefault.codeUnits, [32, 32, 10, 97, 98, 99]);
    expect(MultilineDefaults.tabbedDefault.codeUnits, [9, 10, 97, 98, 99]);
    expect(MultilineDefaults.blankLinesDefault.codeUnits, [10, 10, 97, 98, 99]);
    expect(MultilineDefaults.mixedDefault, '\n\$5\\it\'s "here"\r\n');
  });

  test('constructor defaults preserve leading whitespace and newlines', () {
    const value = MultilineDefaults();

    expect(value.line.codeUnits, [10]);
    expect(value.padded.codeUnits, [32, 32, 10, 97, 98, 99]);
    expect(value.tabbed.codeUnits, [9, 10, 97, 98, 99]);
    expect(value.blankLines.codeUnits, [10, 10, 97, 98, 99]);
    expect(value.mixed, '\n\$5\\it\'s "here"\r\n');
  });

  test('missing properties decode to exact multiline defaults', () {
    final value = MultilineDefaults.fromJson(const <String, Object?>{});

    expect(value.line.codeUnits, [10]);
    expect(value.padded.codeUnits, [32, 32, 10, 97, 98, 99]);
    expect(value.tabbed.codeUnits, [9, 10, 97, 98, 99]);
    expect(value.blankLines.codeUnits, [10, 10, 97, 98, 99]);
    expect(value.mixed, '\n\$5\\it\'s "here"\r\n');
  });

  test('typed-map defaults preserve keys and values', () {
    const value = MultilineDefaults();
    final decoded = MultilineDefaults.fromJson(const <String, Object?>{});

    expect(MultilineDefaults.typedDefault, {'\nk': '  \nabc'});
    expect(value.typed, {'\nk': '  \nabc'});
    expect(decoded.typed, {'\nk': '  \nabc'});
  });

  test('untyped defaults preserve keys and values', () {
    const value = MultilineDefaults();
    final decoded = MultilineDefaults.fromJson(const <String, Object?>{});

    expect(MultilineDefaults.rawDefault, {'\nk': '\n'});
    expect(value.raw, {'\nk': '\n'});
    expect(decoded.raw, {'\nk': '\n'});
  });

  test('runtime property defaults preserve object keys and values', () {
    final defaultValue = MultilineDefaults.objectDefault;
    final decoded = MultilineDefaults.fromJson(const <String, Object?>{});

    expect(defaultValue.value.codeUnits, [10]);
    expect(defaultValue.additionalProperties, {'\nk': '  \nabc'});
    expect(decoded.object?.toJson(), {'value': '\n', '\nk': '  \nabc'});
  });

  test(
    'parameter constants and runtime defaults preserve multiline values',
    () {
      expect(GetMultilineDefaults.lineDefault.codeUnits, [10]);
      expect(GetMultilineDefaults.paddedDefault.codeUnits, [
        32,
        32,
        10,
        97,
        98,
        99,
      ]);
      expect(GetMultilineDefaults.objectDefault.toJson(), {
        'value': '\n',
        '\nk': '  \nabc',
      });
    },
  );

  group('defaulted requests', () {
    late ImposterServer imposterServer;
    late String baseUrl;

    setUpAll(() async {
      imposterServer = await setupImposterServer();
      baseUrl = 'http://localhost:${imposterServer.port}/v1';
    });

    test(
      'sends omitted const defaults and an explicit runtime default',
      () async {
        final api = DefaultApi(
          CustomServer(baseUrl: baseUrl, serverConfig: testServerConfig()),
        );
        final result = await api.getMultilineDefaults(
          object: GetMultilineDefaults.objectDefault,
        );

        expect(result, isTonikSuccess);
        final request = await imposterServer.takeRequest();
        expect(request.uri.queryParameters, {
          'line': '\n',
          'padded': '  \nabc',
          'value': '\n',
          '\nk': '  \nabc',
        });
      },
    );
  });
}
