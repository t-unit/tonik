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

  Future<OneOfScalarMix> decode(String responseBody) async {
    final api = buildApi(responseBody);
    final result = await api.echoOneOfScalarMix(
      body: const OneOfScalarMixInt(0),
    );
    return (result as TonikSuccess<OneOfScalarMix>).value;
  }

  Future<OneOfDateTimeOrString> decodeDateTimeOrString(
    String responseBody,
  ) async {
    final api = buildApi(responseBody);
    final result = await api.echoOneOfDateTimeOrString(
      body: const OneOfDateTimeOrStringString(''),
    );
    return (result as TonikSuccess<OneOfDateTimeOrString>).value;
  }

  Future<OneOfBase64OrString> decodeBase64OrString(String responseBody) async {
    final api = buildApi(responseBody);
    final result = await api.echoOneOfBase64OrString(
      body: const OneOfBase64OrStringString(''),
    );
    return (result as TonikSuccess<OneOfBase64OrString>).value;
  }

  group('OneOfScalarMix [integer, double, decimal, string] routes each JSON '
      'value to its typed variant', () {
    test('integer 42 decodes to the integer variant', () async {
      expect(await decode('42'), const OneOfScalarMixInt(42));
    });

    test('fractional double 42.5 decodes to the double variant', () async {
      expect(await decode('42.5'), const OneOfScalarMixDouble(42.5));
    });

    test('whole-number double 42.0 decodes to the double variant', () async {
      expect(await decode('42.0'), const OneOfScalarMixDouble(42));
    });

    test('decimal string "3.14" decodes to the decimal variant', () async {
      final value = await decode('"3.14"');

      expect(value, isA<OneOfScalarMixDecimal>());
      expect((value as OneOfScalarMixDecimal).value.toString(), '3.14');
    });

    test('high-precision decimal string decodes to the decimal variant '
        'without losing precision', () async {
      const digits = '3.14159265358979323846264338327950288';
      final value = await decode('"$digits"');

      expect(value, isA<OneOfScalarMixDecimal>());
      expect((value as OneOfScalarMixDecimal).value.toString(), digits);
    });

    test('non-numeric string "hello" decodes to the string variant', () async {
      expect(await decode('"hello"'), const OneOfScalarMixString('hello'));
    });

    test('decimal-shaped but invalid string "1.2.3" falls through to the '
        'string variant', () async {
      expect(await decode('"1.2.3"'), const OneOfScalarMixString('1.2.3'));
    });
  });

  group('OneOfDateTimeOrString [date-time, string]', () {
    test('a valid date-time string decodes to the date-time variant', () async {
      final value = await decodeDateTimeOrString('"2020-01-02T03:04:05Z"');

      expect(value, isA<OneOfDateTimeOrStringDateTime>());
      expect(
        (value as OneOfDateTimeOrStringDateTime).value,
        DateTime.utc(2020, 1, 2, 3, 4, 5),
      );
    });

    test('a non-date string decodes to the string variant', () async {
      expect(
        await decodeDateTimeOrString('"hello"'),
        const OneOfDateTimeOrStringString('hello'),
      );
    });
  });

  group('OneOfBase64OrString [base64, string]', () {
    test('a valid base64 string decodes to the base64 variant', () async {
      final value = await decodeBase64OrString('"aGVsbG8="');

      expect(value, isA<OneOfBase64OrStringBase64>());
      expect(
        (value as OneOfBase64OrStringBase64).value.toBytes(),
        'hello'.codeUnits,
      );
    });

    test('a non-base64 string decodes to the string variant', () async {
      expect(
        await decodeBase64OrString('"not base64!"'),
        const OneOfBase64OrStringString('not base64!'),
      );
    });
  });
}
