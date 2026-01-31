import 'package:form_urlencoded_api/form_urlencoded_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  late ImposterServer imposterServer;
  late String baseUrl;
  late CustomApi api;

  setUpAll(() async {
    imposterServer = await setupImposterServer();
    baseUrl = 'http://localhost:${imposterServer.port}';

    api = CustomApi(CustomServer(baseUrl: baseUrl));
  });

  group('Custom content type override', () {
    test('uses form encoding for custom content type', () async {
      const form = CustomForm(field1: 'test data', field2: 999);

      final response = await api.postCustomForm(body: form);

      expect(response, isA<TonikSuccess<CustomForm>>());

      final requestOptions =
          (response as TonikSuccess<CustomForm>).response.requestOptions;
      final contentType = requestOptions.headers['content-type'];
      expect(contentType, 'application/vnd.custom-form');

      final requestData = response.response.requestOptions.data;
      expect(requestData, 'field1=test+data&field2=999');

      final data = response.value;
      expect(data.field1, 'custom value');
      expect(data.field2, 100);
    });

    test('encodes spaces as + for custom content type', () async {
      const form = CustomForm(field1: 'first second third', field2: 50);

      final response = await api.postCustomForm(body: form);

      expect(response, isA<TonikSuccess<CustomForm>>());

      final requestData =
          (response as TonikSuccess<CustomForm>).response.requestOptions.data;
      expect(requestData, 'field1=first+second+third&field2=50');

      final data = response.value;
      expect(data.field1, 'custom value');
    });
  });
}
