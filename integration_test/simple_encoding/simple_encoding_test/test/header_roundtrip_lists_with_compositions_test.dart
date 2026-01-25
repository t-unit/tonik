import 'package:dio/dio.dart';
import 'package:simple_encoding_api/simple_encoding_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

typedef _R = HeadersRoundtripListsWithCompositionsGet200Response;

void main() {
  const port = 8085;
  const baseUrl = 'http://localhost:$port/v1';

  late ImposterServer imposterServer;

  setUpAll(() async {
    imposterServer = ImposterServer(port: port);
    await setupImposterServer(imposterServer);
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

  group('Lists with compositions header roundtrip', () {
    group('ObjectList (list of SimpleObject)', () {
      test('fails to encode list of complex objects in header', () async {
        // ObjectList is List<SimpleObject> which is complex content
        // The generated code throws EncodingException for this case
        final objectList = [
          const SimpleObject(name: 'item1', value: 10),
          const SimpleObject(name: 'item2', value: 20),
        ];

        final result = await api.testHeaderRoundtripListsWithCompositions(
          objectList: objectList,
        );

        // Should fail with encoding error since complex lists aren't
        // supported in simple encoding for headers
        expect(result, isA<TonikError<_R>>());
        final error = result as TonikError<_R>;
        expect(error.type, TonikErrorType.encoding);
      });

      test('encoding error for empty ObjectList still fails', () async {
        // Even an empty list triggers the encoding path check
        final objectList = <SimpleObject>[];

        final result = await api.testHeaderRoundtripListsWithCompositions(
          objectList: objectList,
        );

        // Empty list still causes encoding error due to type checking
        expect(result, isA<TonikError<_R>>());
        final error = result as TonikError<_R>;
        expect(error.type, TonikErrorType.encoding);
      });
    });

    group('AnyOfWithComplexList (anyOf with list or string)', () {
      test(
        'fails to decode AnyOfWithComplexList string variant from header',
        () async {
          // String variant encodes fine, but decoding anyOf from header fails
          const anyOfList = AnyOfWithComplexList(string: 'simple-string-value');

          final result = await api.testHeaderRoundtripListsWithCompositions(
            anyOfList: anyOfList,
          );

          expect(result, isA<TonikError<_R>>());
          final error = result as TonikError<_R>;
          expect(error.type, TonikErrorType.decoding);
        },
      );

      test('fails when AnyOfWithComplexList has Class1 list variant', () async {
        // The list variant with complex objects cannot be encoded
        const anyOfList = AnyOfWithComplexList(
          list: [Class1(name: 'class1-item')],
        );

        final result = await api.testHeaderRoundtripListsWithCompositions(
          anyOfList: anyOfList,
        );

        expect(result, isA<TonikError<_R>>());
        final error = result as TonikError<_R>;
        expect(error.type, TonikErrorType.encoding);
      });

      test('fails when AnyOfWithComplexList has Class2 list variant', () async {
        // The list2 variant with complex objects cannot be encoded
        const anyOfList = AnyOfWithComplexList(
          list2: [Class2(number: 42)],
        );

        final result = await api.testHeaderRoundtripListsWithCompositions(
          anyOfList: anyOfList,
        );

        expect(result, isA<TonikError<_R>>());
        final error = result as TonikError<_R>;
        expect(error.type, TonikErrorType.encoding);
      });

      test('fails when AnyOfWithComplexList has mixed variants', () async {
        // Setting both string and list variants should fail encoding
        const anyOfList = AnyOfWithComplexList(
          string: 'conflict',
          list: [Class1(name: 'conflict-item')],
        );

        final result = await api.testHeaderRoundtripListsWithCompositions(
          anyOfList: anyOfList,
        );

        expect(result, isA<TonikError<_R>>());
        final error = result as TonikError<_R>;
        expect(error.type, TonikErrorType.encoding);
      });
    });

    group('combined headers', () {
      test(
        'fails to decode anyOfList even when objectList is null',
        () async {
          // String variant encodes fine, but decoding anyOf from header fails
          const anyOfList = AnyOfWithComplexList(string: 'only-anyof-string');

          final result = await api.testHeaderRoundtripListsWithCompositions(
            anyOfList: anyOfList,
            // objectList is null, so no encoding error from that
          );

          expect(result, isA<TonikError<_R>>());
          final error = result as TonikError<_R>;
          expect(error.type, TonikErrorType.decoding);
        },
      );
    });
  });
}
