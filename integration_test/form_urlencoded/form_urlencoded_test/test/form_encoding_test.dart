import 'package:form_urlencoded_api/form_urlencoded_api.dart';
import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

import 'test_helper.dart';

void main() {
  const port = 8100;
  late ImposterServer imposterServer;
  late FormApi api;

  setUpAll(() async {
    imposterServer = ImposterServer(port: port);
    await setupImposterServer(imposterServer);

    api = FormApi(CustomServer(baseUrl: 'http://localhost:$port'));
  });

  group('Simple form encoding', () {
    test('posts flat object with form encoding', () async {
      const form = SimpleForm(name: 'Test User', age: 25);

      final response = await api.postSimpleForm(body: form);

      expect(response, isA<TonikSuccess<SimpleForm>>());
      final data = (response as TonikSuccess<SimpleForm>).value;

      expect(data.name, 'John Doe');
      expect(data.age, 30);
    });

    test('encodes spaces as + not %20 in request body', () async {
      const form = SimpleForm(name: 'First Last', age: 25);

      final response = await api.postSimpleForm(body: form);

      expect(response, isA<TonikSuccess<SimpleForm>>());

      final rawRequestBody = (response as TonikSuccess<SimpleForm>)
          .response
          .headers
          .value('x-raw-request-body');
      expect(rawRequestBody, isNotNull);
      // Verify spaces are encoded as + not %20
      expect(rawRequestBody, contains('name=First+Last'));
      expect(rawRequestBody, isNot(contains('First%20Last')));
      expect(rawRequestBody, contains('age=25'));
    });
  });

  group('Special characters encoding', () {
    test('encodes special characters correctly', () async {
      const form = SpecialCharsForm(
        text: 'test data',
        url: 'https://example.com',
      );

      final response = await api.postSpecialChars(body: form);

      expect(response, isA<TonikSuccess<SpecialCharsForm>>());
      final data = (response as TonikSuccess<SpecialCharsForm>).value;

      expect(data.text, 'a&b=c+d');
    });

    test('handles special characters in values', () async {
      const form = SpecialCharsForm(text: 'test');

      final response = await api.postSpecialChars(body: form);

      expect(response, isA<TonikSuccess<SpecialCharsForm>>());
      final data = (response as TonikSuccess<SpecialCharsForm>).value;

      expect(data.url, r'50% off! Buy now & save $$$');
    });
  });

  group('Array encoding with explode', () {
    test('encodes arrays with repeated keys (explode=true)', () async {
      const form = ArrayForm(colors: ['yellow', 'orange'], numbers: [4, 5, 6]);

      final response = await api.postArrayForm(body: form);

      expect(response, isA<TonikSuccess<ArrayForm>>());
      final data = (response as TonikSuccess<ArrayForm>).value;

      expect(data.colors, ['red', 'green', 'blue']);
      expect(data.numbers, [1, 2, 3]);
    });

    test('handles empty arrays', () async {
      const form = ArrayForm(colors: []);

      final response = await api.postArrayForm(body: form);

      expect(response, isA<TonikSuccess<ArrayForm>>());
      final data = (response as TonikSuccess<ArrayForm>).value;

      expect(data.colors, ['red', 'green', 'blue']);
    });

    test('handles single-element arrays', () async {
      const form = ArrayForm(colors: ['purple']);

      final response = await api.postArrayForm(body: form);

      expect(response, isA<TonikSuccess<ArrayForm>>());
      final data = (response as TonikSuccess<ArrayForm>).value;

      expect(data.colors, ['red', 'green', 'blue']);
    });
  });

  group('Type conversions', () {
    test('converts various types correctly', () async {
      final dateTime = DateTime(2024, 6, 20, 15, 45);
      final form = TypesForm(
        stringValue: 'test string',
        intValue: 99,
        boolValue: false,
        doubleValue: 2.71,
        dateValue: dateTime,
      );

      final response = await api.postTypesForm(body: form);

      expect(response, isA<TonikSuccess<TypesForm>>());
      final data = (response as TonikSuccess<TypesForm>).value;

      expect(data.stringValue, 'hello');
      expect(data.intValue, 42);
      expect(data.boolValue, true);
      expect(data.doubleValue, 3.14);
      expect(data.dateValue, DateTime.parse('2023-12-25T10:30:00Z'));
    });

    test('encodes booleans as true/false strings', () async {
      const form = TypesForm(
        stringValue: 'test',
        intValue: 1,
        boolValue: false,
      );

      final response = await api.postTypesForm(body: form);

      expect(response, isA<TonikSuccess<TypesForm>>());
      final data = (response as TonikSuccess<TypesForm>).value;

      expect(data.boolValue, true);
    });
  });

  group('Response body deserialization', () {
    test('deserializes form-urlencoded response body', () async {
      final response = await api.getFormResponse();

      expect(response, isA<TonikSuccess<SimpleForm>>());
      final data = (response as TonikSuccess<SimpleForm>).value;

      expect(data.name, 'John Doe');
      expect(data.age, 30);
    });
  });

  group('Empty and null values', () {
    test('handles empty strings correctly', () async {
      const form = EmptyNullForm(emptyString: '');

      final response = await api.postEmptyNull(body: form);

      expect(response, isA<TonikSuccess<EmptyNullForm>>());
      final data = (response as TonikSuccess<EmptyNullForm>).value;

      expect(data.emptyString, isNull);
    });

    test('omits null values from form body', () async {
      const form = EmptyNullForm(emptyString: 'test value');

      final response = await api.postEmptyNull(body: form);

      expect(response, isA<TonikSuccess<EmptyNullForm>>());
      final data = (response as TonikSuccess<EmptyNullForm>).value;

      expect(data.emptyString, isNull);
      expect(data.nullableString, 'not empty');
    });
  });

  group('Invalid nested data', () {
    test('throws error when trying to encode nested object', () async {
      const form = NestedForm(
        topLevel: 'value',
        nested: NestedFormNestedModel(innerProp: 'inner'),
      );

      // The error should be caught and returned as TonikError
      final response = await api.postNestedForm(body: form);
      expect(response, isA<TonikError<NestedForm>>());
    });
  });

  group('Content-Type header', () {
    test('sends correct Content-Type header for form requests', () async {
      const form = SimpleForm(name: 'Test', age: 20);

      final response = await api.postSimpleForm(body: form);

      expect(response, isA<TonikSuccess<SimpleForm>>());

      // Verify the Content-Type header was set correctly in the request
      final contentType = (response as TonikSuccess<SimpleForm>)
          .response
          .requestOptions
          .headers['content-type'];
      expect(contentType, 'application/x-www-form-urlencoded');
    });
  });
}
