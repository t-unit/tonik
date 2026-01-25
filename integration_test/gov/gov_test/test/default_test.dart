import 'package:dio/dio.dart';
import 'package:gov_api/gov_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  const port = 8280;
  const baseUrl = 'http://localhost:$port';

  late ImposterServer imposterServer;

  setUpAll(() async {
    imposterServer = ImposterServer(port: port);
    await setupImposterServer(imposterServer);
  });

  DefaultApi buildAlbumsApi({required String responseStatus}) {
    return DefaultApi(
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

  group('findForms', () {
    test('200', () async {
      final defaultApi = buildAlbumsApi(responseStatus: '200');

      final response = await defaultApi.findForms(query: '10-10EZ');

      expect(response, isA<TonikSuccess<FindFormsResponse>>());
      final success = response as TonikSuccess<FindFormsResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<FindFormsResponse200>());

      final value = success.value as FindFormsResponse200;
      expect(value.body, isA<FormsGet200BodyModel>());

      final body = value.body;
      expect(body.data, isA<List<FormsIndex>>());

      final formIndex = body.data.first;
      expect(
        formIndex.attributes?.benefitCategories,
        isA<List<FormsIndexAttributesBenefitCategoriesArrayModel>>(),
      );
      expect(formIndex.id, isA<String?>());
      expect(formIndex.$type, isA<String?>());

      final attributes = formIndex.attributes;
      final benefitCategory = attributes?.benefitCategories?.first;
      expect(benefitCategory?.name, isA<String?>());
      expect(benefitCategory?.description, isA<String?>());

      expect(attributes?.deletedAt, isA<DateTime?>());
      expect(attributes?.firstIssuedOn, isA<Date?>());
      expect(attributes?.formDetailsUrl, isA<String?>());
      expect(attributes?.formName, isA<String?>());
      expect(attributes?.formToolIntro, isA<String?>());
      expect(attributes?.formToolUrl, isA<String?>());
      expect(attributes?.formType, isA<String?>());
      expect(attributes?.formUsage, isA<String?>());
      expect(attributes?.language, isA<String?>());
      expect(attributes?.lastRevisionOn, isA<Date?>());
      expect(attributes?.lastSha256Change, isA<Date?>());
      expect(attributes?.pages, isA<int?>());
      expect(attributes?.relatedForms, isA<List<String>?>());
      expect(attributes?.sha256, isA<String?>());
      expect(attributes?.title, isA<String?>());
      expect(attributes?.url, isA<String?>());
      expect(attributes?.vaFormAdministration, isA<String?>());
      expect(attributes?.validPdf, isA<bool?>());
    });

    test('401', () async {
      final defaultApi = buildAlbumsApi(responseStatus: '401');

      final response = await defaultApi.findForms();

      expect(response, isA<TonikSuccess<FindFormsResponse>>());
      final success = response as TonikSuccess<FindFormsResponse>;

      expect(success.response.statusCode, 401);
      expect(success.value, isA<FindFormsResponse401>());

      final value = success.value as FindFormsResponse401;
      expect(value.body, isA<FormsGet401BodyModel>());

      final body = value.body;
      expect(body.message, isA<String?>());
    });

    test('429', () async {
      final defaultApi = buildAlbumsApi(responseStatus: '429');

      final response = await defaultApi.findForms();

      expect(response, isA<TonikSuccess<FindFormsResponse>>());
      final success = response as TonikSuccess<FindFormsResponse>;

      expect(success.response.statusCode, 429);
      expect(success.value, isA<FindFormsResponse429>());

      final value = success.value as FindFormsResponse429;
      expect(value.body, isA<FormsGet429BodyModel>());
    });

    test('unexpected status code', () async {
      final defaultApi = buildAlbumsApi(responseStatus: '500');

      final response = await defaultApi.findForms();

      expect(response, isA<TonikError<FindFormsResponse>>());
    });
  });
}
