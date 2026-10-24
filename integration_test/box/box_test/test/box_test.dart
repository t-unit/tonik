import 'package:box_api/box_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';

void main() {
  late ImposterServer imposterServer;
  late String baseUrl;

  setUpAll(() async {
    imposterServer = await setupImposterServer();
    baseUrl = 'http://localhost:${imposterServer.port}/2.0';
  });

  CustomServer buildServer({required String responseStatus}) => CustomServer(
    baseUrl: baseUrl,
    serverConfig: testServerConfig(
      headers: {'X-Response-Status': responseStatus},
    ),
  );

  test('gets file skill cards and decodes the keyword variant', () async {
    final api = SkillsApi(buildServer(responseStatus: '200'));

    final result = await api.getFilesIdMetadataGlobalBoxSkillsCards(
      fileId: 'file-42',
    );

    final response =
        requireSuccess(result).value
            as GetFilesIdMetadataGlobalBoxSkillsCardsResponse200;
    expect(response.body.$canEdit, isTrue);
    expect(response.body.$version, 1);
    final card = response.body.cards!.single as SkillCardKeywordSkillCard;
    expect(card.value.skill.id, 'image-recognition-service');
    expect(card.value.entries.single.text, 'keyword1');
    final request = await imposterServer.takeRequest();
    expect(request.method, 'GET');
    expect(
      request.uri.path,
      '/2.0/files/file-42/metadata/global/boxSkillsCards',
    );
  });

  test(
    'deletes a shield segment restriction without a response body',
    () async {
      final api = ShieldinformationbarriersegmentrestrictionsApi(
        buildServer(responseStatus: '204'),
      );

      final result = await api
          .deleteShieldInformationBarrierSegmentRestrictionsId(
            shieldInformationBarrierSegmentRestrictionId: 'restriction-42',
          );

      expect(
        requireSuccess(result).value,
        isA<DeleteShieldInformationBarrierSegmentRestrictionsIdResponse204>(),
      );
      final request = await imposterServer.takeRequest();
      expect(request.method, 'DELETE');
      expect(
        request.uri.path,
        '/2.0/shield_information_barrier_segment_restrictions/restriction-42',
      );
      expect(request.body, isNull);
    },
  );

  test('decodes a missing shield segment restriction response', () async {
    final api = ShieldinformationbarriersegmentrestrictionsApi(
      buildServer(responseStatus: '404'),
    );

    final result = await api
        .deleteShieldInformationBarrierSegmentRestrictionsId(
          shieldInformationBarrierSegmentRestrictionId: 'missing',
        );

    final response =
        requireSuccess(result).value
            as DeleteShieldInformationBarrierSegmentRestrictionsIdResponse404;
    expect(response.body.$type, ClientErrorTypeModel.error);
    expect(response.body.status, isA<int>());
    expect(response.body.code, isA<ClientErrorCodeModel>());
    expect(response.body.message, isA<String>());
    expect(response.body.requestId, isA<String>());
    expect(
      (await imposterServer.takeRequest()).uri.path,
      '/2.0/shield_information_barrier_segment_restrictions/missing',
    );
  });
}
