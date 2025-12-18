import 'package:dio/dio.dart';
import 'package:simple_encoding_api/simple_encoding_api.dart';
import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

import 'test_helper.dart';

typedef _R = HeadersRoundtripAllofListsGet200Response;

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

  group('AllOfWithSimpleList header roundtrip', () {
    test('fails to decode with both arrays set', () async {
      // Multiple lists become ambiguous when concatenated in header
      final result = await api.testHeaderRoundtripAllOfLists.call(
        listComposite: const AllOfWithSimpleList(
          allOfWithSimpleListModel: AllOfWithSimpleListModel(ids: [1, 2, 3]),
          allOfWithSimpleListModel2: AllOfWithSimpleListModel2(
            tags: ['tag1', 'tag2'],
          ),
        ),
      );

      expect(result, isA<TonikError<_R>>());
      final error = result as TonikError<_R>;
      expect(error.type, TonikErrorType.decoding);
    });

    test('round-trips with only tags set', () async {
      final result = await api.testHeaderRoundtripAllOfLists.call(
        listComposite: const AllOfWithSimpleList(
          allOfWithSimpleListModel: AllOfWithSimpleListModel(),
          allOfWithSimpleListModel2: AllOfWithSimpleListModel2(
            tags: ['alpha', 'beta', 'gamma'],
          ),
        ),
      );

      expect(result, isA<TonikSuccess<_R>>());
      final success = result as TonikSuccess<_R>;

      expect(success.value.xListComposite, isNotNull);
      expect(
        success.value.xListComposite!.allOfWithSimpleListModel2.tags,
        ['alpha', 'beta', 'gamma'],
      );
    });

    test('round-trips with only ids set', () async {
      final result = await api.testHeaderRoundtripAllOfLists.call(
        listComposite: const AllOfWithSimpleList(
          allOfWithSimpleListModel: AllOfWithSimpleListModel(ids: [100, 200]),
          allOfWithSimpleListModel2: AllOfWithSimpleListModel2(),
        ),
      );

      expect(result, isA<TonikSuccess<_R>>());
      final success = result as TonikSuccess<_R>;

      expect(success.value.xListComposite, isNotNull);
      expect(
        success.value.xListComposite!.allOfWithSimpleListModel.ids,
        [100, 200],
      );
    });

    test('fails to decode with single element arrays', () async {
      // Multiple lists become ambiguous when concatenated in header
      final result = await api.testHeaderRoundtripAllOfLists.call(
        listComposite: const AllOfWithSimpleList(
          allOfWithSimpleListModel: AllOfWithSimpleListModel(ids: [42]),
          allOfWithSimpleListModel2: AllOfWithSimpleListModel2(
            tags: ['single'],
          ),
        ),
      );

      expect(result, isA<TonikError<_R>>());
      final error = result as TonikError<_R>;
      expect(error.type, TonikErrorType.decoding);
    });

    group('null parameter', () {
      test(
        'null parameter results in no header sent and null response',
        () async {
          final result = await api.testHeaderRoundtripAllOfLists.call();

          expect(result, isA<TonikSuccess<_R>>());
          final success = result as TonikSuccess<_R>;

          expect(
            success.response.requestOptions.headers['X-List-Composite'],
            isNull,
          );

          // Verify response property is null
          expect(success.value.xListComposite, isNull);
        },
      );
    });
  });
}
