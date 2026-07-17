import 'package:composition_api/composition_api.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  late ImposterServer imposterServer;
  late String baseUrl;

  setUpAll(() async {
    imposterServer = await setupImposterServer();
    baseUrl = 'http://localhost:${imposterServer.port}/v1';
  });

  CompositionApi buildApi(String responseBody) {
    return CompositionApi(
      CustomServer(
        baseUrl: baseUrl,
        serverConfig: ServerConfig(
          baseOptions: BaseOptions(
            headers: {'X-Response-Body': responseBody},
          ),
        ),
      ),
    );
  }

  Future<AnyOfDateTimeOrString> decode(String responseBody) async {
    final api = buildApi(responseBody);
    final result = await api.echoAnyOfDateTimeOrString(
      body: const AnyOfDateTimeOrString(string: ''),
    );
    return (result as TonikSuccess<AnyOfDateTimeOrString>).value;
  }

  group('AnyOfDateTimeOrString [date-time, string]', () {
    test('a canonical timestamp decodes into both matching members', () async {
      final value = await decode('"2024-01-15T10:00:00Z"');

      expect(value.dateTime, DateTime.utc(2024, 1, 15, 10));
      expect(value.string, '2024-01-15T10:00:00Z');
    });

    test('a canonical timestamp re-encodes to the date-time member rendering',
        () async {
      final value = await decode('"2024-01-15T10:00:00Z"');

      expect(value.toJson(), '2024-01-15T10:00:00.000Z');
    });

    test('a fractional-seconds timestamp re-encodes to the same rendering',
        () async {
      final value = await decode('"2024-01-15T10:00:00.000Z"');

      expect(value.toJson(), '2024-01-15T10:00:00.000Z');
    });

    test('a non-date string decodes to the string member and re-encodes '
        'verbatim', () async {
      final value = await decode('"next tuesday"');

      expect(value.dateTime, isNull);
      expect(value.string, 'next tuesday');
      expect(value.toJson(), 'next tuesday');
    });
  });
}
