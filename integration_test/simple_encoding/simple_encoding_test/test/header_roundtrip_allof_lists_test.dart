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
        serverConfig: testServerConfig(
          headers: {'X-Response-Status': responseStatus},
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

      expect(result, isTonikError);
      final error = requireError(result);
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

      expect(result, isTonikSuccess);
      final success = requireSuccess(result);

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

      expect(result, isTonikSuccess);
      final success = requireSuccess(result);

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

      expect(result, isTonikError);
      final error = requireError(result);
      expect(error.type, TonikErrorType.decoding);
    });

    group('null parameter', () {
      test(
        'null parameter results in no header sent and null response',
        () async {
          final result = await api.testHeaderRoundtripAllOfLists.call();

          expect(result, isTonikSuccess);
          final success = requireSuccess(result);
          final recordedRequest = await imposterServer.takeRequest();

          expect(
            recordedRequest.headers['x-list-composite'],
            isNull,
          );
          expect(success.value.xListComposite, isNull);
        },
      );
    });
  });
}
