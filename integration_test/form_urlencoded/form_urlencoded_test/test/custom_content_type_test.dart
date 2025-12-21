import 'package:form_urlencoded_api/form_urlencoded_api.dart';
import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

import 'test_helper.dart';

void main() {
  const port = 8380;
  late ImposterServer imposterServer;
  late CustomApi api;

  setUpAll(() async {
    imposterServer = ImposterServer(port: port);
    await setupImposterServer(imposterServer);

    api = CustomApi(CustomServer(baseUrl: 'http://localhost:$port'));
  });

  group('Custom content type override', () {
    test('uses form encoding for custom content type', () async {
      const form = CustomForm(field1: 'test data', field2: 999);

      final response = await api.postCustomForm(body: form);

      expect(response, isA<TonikSuccess<CustomForm>>());
      final data = (response as TonikSuccess<CustomForm>).value;

      expect(data.field1, 'custom value');
      expect(data.field2, 100);
    });

    test('encodes spaces as + for custom content type', () async {
      const form = CustomForm(field1: 'first second third', field2: 50);

      final response = await api.postCustomForm(body: form);

      expect(response, isA<TonikSuccess<CustomForm>>());
      final data = (response as TonikSuccess<CustomForm>).value;

      expect(data.field1, 'custom value');
    });
  });
}
