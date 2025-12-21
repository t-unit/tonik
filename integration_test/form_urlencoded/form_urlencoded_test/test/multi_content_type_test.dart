import 'package:form_urlencoded_api/form_urlencoded_api.dart';
import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

import 'test_helper.dart';

void main() {
  const port = 8480;
  late ImposterServer imposterServer;
  late FormApi api;

  setUpAll(() async {
    imposterServer = ImposterServer(port: port);
    await setupImposterServer(imposterServer);

    api = FormApi(CustomServer(baseUrl: 'http://localhost:$port'));
  });

  group('Multiple content types - request', () {
    test('sends request as form-urlencoded', () async {
      const form = SimpleForm(name: 'Test User', age: 25);

      final response = await api.postMultiContentRequest(
        body:
            const FormMultiContentRequestPostBodyRequestBodyXWwwFormUrlencoded(
              form,
            ),
      );

      expect(
        response,
        isA<TonikSuccess<FormMultiContentRequestPost200Response>>(),
      );
      final data =
          (response as TonikSuccess<FormMultiContentRequestPost200Response>)
              .value;
      expect(
        data,
        isA<FormMultiContentRequestPost200ResponseXWwwFormUrlencoded>(),
      );
      final formData =
          (data as FormMultiContentRequestPost200ResponseXWwwFormUrlencoded)
              .body;

      expect(formData.name, 'John Doe');
      expect(formData.age, 30);
    });

    test('sends request as JSON', () async {
      const form = SimpleForm(name: 'JSON User', age: 35);

      final response = await api.postMultiContentRequest(
        body: const FormMultiContentRequestPostBodyRequestBodyJson(form),
      );

      expect(
        response,
        isA<TonikSuccess<FormMultiContentRequestPost200Response>>(),
      );
      final data =
          (response as TonikSuccess<FormMultiContentRequestPost200Response>)
              .value;
      expect(
        data,
        isA<FormMultiContentRequestPost200ResponseXWwwFormUrlencoded>(),
      );
      final formData =
          (data as FormMultiContentRequestPost200ResponseXWwwFormUrlencoded)
              .body;

      expect(formData.name, 'John Doe');
      expect(formData.age, 30);
    });
  });

  group('Multiple content types - response', () {
    test('receives response as form-urlencoded', () async {
      final response = await api.getMultiContentResponse();

      expect(
        response,
        isA<TonikSuccess<FormMultiContentResponseGet200Response>>(),
      );
      final data =
          (response as TonikSuccess<FormMultiContentResponseGet200Response>)
              .value;
      expect(
        data,
        isA<FormMultiContentResponseGet200ResponseXWwwFormUrlencoded>(),
      );
      final formData =
          (data as FormMultiContentResponseGet200ResponseXWwwFormUrlencoded)
              .body;

      expect(formData.name, 'John Doe');
      expect(formData.age, 30);
    });
  });

  group('Multiple content types - both request and response', () {
    test('sends form and receives form', () async {
      final dateTime = DateTime(2024, 6, 15, 14, 30);
      final form = TypesForm(
        stringValue: 'form to form',
        intValue: 100,
        boolValue: false,
        doubleValue: 2.71,
        dateValue: dateTime,
      );

      final response = await api.postMultiContentBoth(
        body: FormMultiContentBothPostBodyRequestBodyXWwwFormUrlencoded(form),
      );

      expect(
        response,
        isA<TonikSuccess<FormMultiContentBothPost200Response>>(),
      );
      final data =
          (response as TonikSuccess<FormMultiContentBothPost200Response>).value;
      expect(
        data,
        isA<FormMultiContentBothPost200ResponseXWwwFormUrlencoded>(),
      );
      final formData =
          (data as FormMultiContentBothPost200ResponseXWwwFormUrlencoded).body;

      expect(formData.stringValue, 'hello');
      expect(formData.intValue, 42);
      expect(formData.boolValue, true);
      expect(formData.doubleValue, 3.14);
      expect(formData.dateValue, DateTime.parse('2023-12-25T10:30:00Z'));
    });

    test('sends JSON and receives form', () async {
      final dateTime = DateTime(2024, 12, 1, 9);
      final form = TypesForm(
        stringValue: 'json to form',
        intValue: 200,
        boolValue: false,
        doubleValue: 1.41,
        dateValue: dateTime,
      );

      final response = await api.postMultiContentBoth(
        body: FormMultiContentBothPostBodyRequestBodyJson(form),
      );

      expect(
        response,
        isA<TonikSuccess<FormMultiContentBothPost200Response>>(),
      );
      final data =
          (response as TonikSuccess<FormMultiContentBothPost200Response>).value;
      expect(
        data,
        isA<FormMultiContentBothPost200ResponseXWwwFormUrlencoded>(),
      );
      final formData =
          (data as FormMultiContentBothPost200ResponseXWwwFormUrlencoded).body;

      expect(formData.stringValue, 'hello');
      expect(formData.intValue, 42);
      expect(formData.boolValue, true);
      expect(formData.doubleValue, 3.14);
      expect(formData.dateValue, DateTime.parse('2023-12-25T10:30:00Z'));
    });
  });
}
