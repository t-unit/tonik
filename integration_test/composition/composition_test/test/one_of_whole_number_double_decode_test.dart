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

  group('OneOfPrimitive decodes JSON number to the integer variant', () {
    test('whole-number double 42.0 decodes to OneOfPrimitiveInt(42)', () async {
      final api = buildApi('42.0');
      final result = await api.echoOneOfPrimitive(
        body: const OneOfPrimitiveInt(0),
      );
      final success = result as TonikSuccess<OneOfPrimitive>;

      expect(success.value, const OneOfPrimitiveInt(42));
    });

    test('exponent double 4e1 decodes to OneOfPrimitiveInt(40)', () async {
      final api = buildApi('4e1');
      final result = await api.echoOneOfPrimitive(
        body: const OneOfPrimitiveInt(0),
      );
      final success = result as TonikSuccess<OneOfPrimitive>;

      expect(success.value, const OneOfPrimitiveInt(40));
    });

    test('integer 42 decodes to OneOfPrimitiveInt(42)', () async {
      final api = buildApi('42');
      final result = await api.echoOneOfPrimitive(
        body: const OneOfPrimitiveInt(0),
      );
      final success = result as TonikSuccess<OneOfPrimitive>;

      expect(success.value, const OneOfPrimitiveInt(42));
    });

    test('string "hello" decodes to OneOfPrimitiveString', () async {
      final api = buildApi('"hello"');
      final result = await api.echoOneOfPrimitive(
        body: const OneOfPrimitiveInt(0),
      );
      final success = result as TonikSuccess<OneOfPrimitive>;

      expect(success.value, const OneOfPrimitiveString('hello'));
    });

    test('fractional double 42.5 surfaces a decoding TonikError', () async {
      final api = buildApi('42.5');
      final result = await api.echoOneOfPrimitive(
        body: const OneOfPrimitiveInt(0),
      );
      final error = result as TonikError<OneOfPrimitive>;

      expect(error.type, TonikErrorType.decoding);
      expect(error.error, isA<InvalidTypeException>());
    });
  });

  group('OneOfIntegerOrNumber decodes JSON number to the number variant', () {
    test('whole-number double 42.0 decodes to the number variant', () async {
      final api = buildApi('42.0');
      final result = await api.echoOneOfIntegerOrNumber(
        body: const OneOfIntegerOrNumberInt(0),
      );
      final success = result as TonikSuccess<OneOfIntegerOrNumber>;

      expect(success.value, const OneOfIntegerOrNumberNumber(42.0));
    });
  });

  group('OneOfIntegerOrClass1 decodes JSON number to the integer variant', () {
    test('whole-number double 42.0 decodes to the integer variant', () async {
      final api = buildApi('42.0');
      final result = await api.echoOneOfIntegerOrClass1(
        body: const OneOfIntegerOrClass1Int(0),
      );
      final success = result as TonikSuccess<OneOfIntegerOrClass1>;

      expect(success.value, const OneOfIntegerOrClass1Int(42));
    });

    test('integer 42 decodes to the integer variant', () async {
      final api = buildApi('42');
      final result = await api.echoOneOfIntegerOrClass1(
        body: const OneOfIntegerOrClass1Int(0),
      );
      final success = result as TonikSuccess<OneOfIntegerOrClass1>;

      expect(success.value, const OneOfIntegerOrClass1Int(42));
    });

    test('object body decodes to the Class1 variant', () async {
      final api = buildApi('{"name": "widget"}');
      final result = await api.echoOneOfIntegerOrClass1(
        body: const OneOfIntegerOrClass1Int(0),
      );
      final success = result as TonikSuccess<OneOfIntegerOrClass1>;

      expect(
        success.value,
        const OneOfIntegerOrClass1Class1(Class1(name: 'widget')),
      );
    });

    test('fractional double 42.5 surfaces a decoding TonikError', () async {
      final api = buildApi('42.5');
      final result = await api.echoOneOfIntegerOrClass1(
        body: const OneOfIntegerOrClass1Int(0),
      );
      final error = result as TonikError<OneOfIntegerOrClass1>;

      expect(error.type, TonikErrorType.decoding);
      expect(error.error, isA<JsonDecodingException>());
    });
  });
}
