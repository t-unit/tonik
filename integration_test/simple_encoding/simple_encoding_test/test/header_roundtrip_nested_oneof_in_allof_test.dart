import 'package:dio/dio.dart';
import 'package:simple_encoding_api/simple_encoding_api.dart';
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

  SimpleEncodingApi buildApi({required String responseStatus}) {
    return SimpleEncodingApi(
      CustomServer(
        baseUrl: baseUrl,
        serverConfig: ServerConfig(
          baseOptions: BaseOptions(
            headers: {'X-Response-Status': responseStatus},
          ),
        ),
      ),
    );
  }

  late SimpleEncodingApi api;

  setUp(() {
    api = buildApi(responseStatus: '200');
  });

  group('NestedOneOfInAllOf header roundtrip', () {
    // Note: NestedOneOfInAllOf has EncodingShape.mixed because it combines
    // a OneOfPrimitive (simple) with an object (complex). This means simple
    // encoding is not supported and should fail.

    group('encoding fails for mixed shapes', () {
      test('string variant with metadata fails at encoding', () async {
        final result = await api.testHeaderRoundtripNestedOneOfInAllOf.call(
          nestedValue: const NestedOneOfInAllOf(
            oneOfPrimitive: OneOfPrimitiveString('test'),
            nestedOneOfInAllOfModel: NestedOneOfInAllOfModel(metadata: 'meta'),
          ),
        );

        // Mixed encoding shapes cannot be encoded in simple style
        expect(
          result,
          isA<TonikError<HeadersRoundtripNestedOneofInAllofGet200Response>>(),
        );
        final error =
            result
                as TonikError<HeadersRoundtripNestedOneofInAllofGet200Response>;

        expect(error.type, TonikErrorType.encoding);
        expect(error.response, isNull);
      });

      test('integer variant with metadata fails at encoding', () async {
        final result = await api.testHeaderRoundtripNestedOneOfInAllOf.call(
          nestedValue: const NestedOneOfInAllOf(
            oneOfPrimitive: OneOfPrimitiveInt(42),
            nestedOneOfInAllOfModel: NestedOneOfInAllOfModel(metadata: 'info'),
          ),
        );

        // Mixed encoding shapes cannot be encoded in simple style
        expect(
          result,
          isA<TonikError<HeadersRoundtripNestedOneofInAllofGet200Response>>(),
        );
        final error =
            result
                as TonikError<HeadersRoundtripNestedOneofInAllofGet200Response>;

        expect(error.type, TonikErrorType.encoding);
        expect(error.response, isNull);
      });

      test('without metadata still fails at encoding', () async {
        final result = await api.testHeaderRoundtripNestedOneOfInAllOf.call(
          nestedValue: const NestedOneOfInAllOf(
            oneOfPrimitive: OneOfPrimitiveString('value'),
            nestedOneOfInAllOfModel: NestedOneOfInAllOfModel(),
          ),
        );

        // Even without metadata, the mixed shape prevents simple encoding
        expect(
          result,
          isA<TonikError<HeadersRoundtripNestedOneofInAllofGet200Response>>(),
        );
        final error =
            result
                as TonikError<HeadersRoundtripNestedOneofInAllofGet200Response>;

        expect(error.type, TonikErrorType.encoding);
      });
    });

    group('null parameter', () {
      test(
        'null parameter results in no header sent and null response',
        () async {
          final result = await api.testHeaderRoundtripNestedOneOfInAllOf.call();

          expect(
            result,
            isA<
              TonikSuccess<HeadersRoundtripNestedOneofInAllofGet200Response>
            >(),
          );
          final success =
              result
                  as TonikSuccess<
                    HeadersRoundtripNestedOneofInAllofGet200Response
                  >;

          // Verify no header was sent
          expect(
            success.response.requestOptions.headers['X-Nested-Value'],
            isNull,
          );

          // Verify response property is null
          expect(success.value.xNestedValue, isNull);
        },
      );
    });
  });
}
