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

      final requestData =
          (response as TonikSuccess<SimpleForm>).response.requestOptions.data;
      expect(requestData, 'name=Test+User&age=25');

      final data = response.value;
      expect(data.name, 'John Doe');
      expect(data.age, 30);
    });

    test('encodes spaces as + not %20 in request body', () async {
      const form = SimpleForm(name: 'First Last', age: 25);

      final response = await api.postSimpleForm(body: form);

      expect(response, isA<TonikSuccess<SimpleForm>>());

      final requestData =
          (response as TonikSuccess<SimpleForm>).response.requestOptions.data;
      expect(requestData, 'name=First+Last&age=25');

      final data = response.value;
      expect(data.name, 'John Doe');
      expect(data.age, 30);
    });
  });

  group('Special characters encoding', () {
    test('encodes ampersand and equals correctly', () async {
      const form = SpecialCharsForm(
        text: 'a&b=c+d',
        url: 'https://example.com',
      );

      final response = await api.postSpecialChars(body: form);

      expect(response, isA<TonikSuccess<SpecialCharsForm>>());

      final requestData = (response as TonikSuccess<SpecialCharsForm>)
          .response
          .requestOptions
          .data;
      expect(requestData, 'text=a%26b%3Dc%2Bd&url=https%3A%2F%2Fexample.com');

      final data = response.value;
      expect(data.text, 'a&b=c+d');
    });

    test('encodes percent, ampersand, space, and dollar signs', () async {
      const form = SpecialCharsForm(
        text: 'simple',
        url: r'50% off! Buy now & save $$$',
      );

      final response = await api.postSpecialChars(body: form);

      expect(response, isA<TonikSuccess<SpecialCharsForm>>());

      final requestData = (response as TonikSuccess<SpecialCharsForm>)
          .response
          .requestOptions
          .data;
      expect(
        requestData,
        'text=simple&url=50%25+off%21+Buy+now+%26+save+%24%24%24',
      );

      final data = response.value;
      expect(data.url, r'50% off! Buy now & save $$$');
    });
  });

  group('True roundtrip tests (echo endpoints)', () {
    test('roundtrip with ampersand, equals, and plus', () async {
      const form = SpecialCharsForm(text: 'a&b=c+d', url: 'test');

      final response = await api.postEchoSpecialChars(body: form);

      expect(response, isA<TonikSuccess<SpecialCharsForm>>());

      final data = (response as TonikSuccess<SpecialCharsForm>).value;
      // True roundtrip - what we send must equal what we receive
      expect(data.text, 'a&b=c+d');
      expect(data.url, 'test');
    });

    test('roundtrip with percent literal', () async {
      const form = SpecialCharsForm(text: '50% discount', url: '100% free');

      final response = await api.postEchoSpecialChars(body: form);

      expect(response, isA<TonikSuccess<SpecialCharsForm>>());

      final data = (response as TonikSuccess<SpecialCharsForm>).value;
      // Percent signs should survive encoding/decoding
      expect(data.text, '50% discount');
      expect(data.url, '100% free');
    });

    test('roundtrip with all special URL characters', () async {
      const form = SpecialCharsForm(
        text: 'foo%bar&baz=qux',
        url: r'50% off! Buy now & save $$$',
      );

      final response = await api.postEchoSpecialChars(body: form);

      expect(response, isA<TonikSuccess<SpecialCharsForm>>());

      final requestData = (response as TonikSuccess<SpecialCharsForm>)
          .response
          .requestOptions
          .data;
      // Verify the encoding in the request
      expect(
        requestData,
        '''text=foo%25bar%26baz%3Dqux&url=50%25+off%21+Buy+now+%26+save+%24%24%24''',
      );

      final data = response.value;
      // True roundtrip - should get back exactly what we sent
      expect(data.text, 'foo%bar&baz=qux');
      expect(data.url, r'50% off! Buy now & save $$$');
    });

    test('roundtrip with spaces', () async {
      const form = SpecialCharsForm(text: 'hello world', url: 'foo bar baz');

      final response = await api.postEchoSpecialChars(body: form);

      expect(response, isA<TonikSuccess<SpecialCharsForm>>());

      final requestData = (response as TonikSuccess<SpecialCharsForm>)
          .response
          .requestOptions
          .data;
      // Spaces should be encoded as + in form bodies
      expect(requestData, 'text=hello+world&url=foo+bar+baz');

      final data = response.value;
      expect(data.text, 'hello world');
      expect(data.url, 'foo bar baz');
    });

    test(
      'roundtrip with various types including special chars in string',
      () async {
        final dateTime = DateTime.utc(2024, 6, 20, 15, 45, 30);
        final form = TypesForm(
          stringValue: 'test & verify=true',
          intValue: 42,
          boolValue: true,
          doubleValue: 3.14,
          dateValue: dateTime,
        );

        final response = await api.postEchoTypes(body: form);

        expect(response, isA<TonikSuccess<TypesForm>>());

        final data = (response as TonikSuccess<TypesForm>).value;
        // All values should roundtrip correctly
        expect(data.stringValue, 'test & verify=true');
        expect(data.intValue, 42);
        expect(data.boolValue, true);
        expect(data.doubleValue, 3.14);
        expect(data.dateValue, dateTime);
      },
    );

    test('roundtrip with colons in datetime values', () async {
      final dateTime = DateTime.utc(2024, 12, 25, 10, 30, 45);
      final form = TypesForm(
        stringValue: 'test',
        intValue: 1,
        boolValue: false,
        dateValue: dateTime,
      );

      final response = await api.postEchoTypes(body: form);

      expect(response, isA<TonikSuccess<TypesForm>>());

      final requestData =
          (response as TonikSuccess<TypesForm>).response.requestOptions.data;
      // Verify colons in datetime are encoded
      expect(requestData, contains('%3A'));

      final data = response.value;
      // DateTime should roundtrip exactly
      expect(data.dateValue, dateTime);
    });
  });

  group('Array encoding with explode', () {
    test('encodes arrays with repeated keys (explode=true)', () async {
      const form = ArrayForm(
        colors: ['red', 'green', 'blue'],
        numbers: [1, 2, 3],
      );

      final response = await api.postArrayForm(body: form);

      expect(response, isA<TonikSuccess<ArrayForm>>());

      final requestData =
          (response as TonikSuccess<ArrayForm>).response.requestOptions.data;
      expect(
        requestData,
        'colors=red,green,blue&numbers=1,2,3',
      );

      final data = response.value;
      expect(data.colors, ['red', 'green', 'blue']);
      expect(data.numbers, [1, 2, 3]);
    });

    test('omits empty arrays from request body', () async {
      const form = ArrayForm(colors: []);

      final response = await api.postArrayForm(body: form);

      expect(response, isA<TonikSuccess<ArrayForm>>());

      final requestData =
          (response as TonikSuccess<ArrayForm>).response.requestOptions.data;
      expect(requestData, 'colors=&numbers=');

      final data = response.value;
      expect(data.colors, ['red', 'green', 'blue']);
    });

    test('encodes single-element arrays with single key', () async {
      const form = ArrayForm(colors: ['purple']);

      final response = await api.postArrayForm(body: form);

      expect(response, isA<TonikSuccess<ArrayForm>>());

      final requestData =
          (response as TonikSuccess<ArrayForm>).response.requestOptions.data;
      expect(requestData, 'colors=purple&numbers=');

      final data = response.value;
      expect(data.colors, ['red', 'green', 'blue']);
    });
  });

  group('Type conversions', () {
    test('encodes various types as strings', () async {
      final dateTime = DateTime.utc(2024, 6, 20, 15, 45, 30);
      final form = TypesForm(
        stringValue: 'hello world',
        intValue: 42,
        boolValue: true,
        doubleValue: 3.14,
        dateValue: dateTime,
      );

      final response = await api.postTypesForm(body: form);

      expect(response, isA<TonikSuccess<TypesForm>>());

      final requestData =
          (response as TonikSuccess<TypesForm>).response.requestOptions.data;
      expect(
        requestData,
        '''stringValue=hello+world&intValue=42&doubleValue=3.14&boolValue=true&dateValue=2024-06-20T15%3A45%3A30.000Z''',
      );

      final data = response.value;
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

      final requestData =
          (response as TonikSuccess<TypesForm>).response.requestOptions.data;
      expect(
        requestData,
        'stringValue=test&intValue=1&doubleValue=&boolValue=false&dateValue=',
      );

      final data = response.value;
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
    test('includes empty string as key with no value', () async {
      const form = EmptyNullForm(emptyString: '');

      final response = await api.postEmptyNull(body: form);

      expect(response, isA<TonikSuccess<EmptyNullForm>>());

      final requestData = (response as TonikSuccess<EmptyNullForm>)
          .response
          .requestOptions
          .data;
      expect(requestData, 'emptyString=&nullableString=');

      final data = response.value;
      expect(data.emptyString, isNull);
    });

    test('omits null optional fields from form body', () async {
      const form = EmptyNullForm(emptyString: 'test value');

      final response = await api.postEmptyNull(body: form);

      expect(response, isA<TonikSuccess<EmptyNullForm>>());

      final requestData = (response as TonikSuccess<EmptyNullForm>)
          .response
          .requestOptions
          .data;
      expect(requestData, 'emptyString=test+value&nullableString=');

      final data = response.value;
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

      final response = await api.postNestedForm(body: form);
      expect(response, isA<TonikError<NestedForm>>());
    });
  });

  group('Content-Type header', () {
    test('sends correct Content-Type header per OpenAPI spec', () async {
      const form = SimpleForm(name: 'Test', age: 20);

      final response = await api.postSimpleForm(body: form);

      expect(response, isA<TonikSuccess<SimpleForm>>());

      final contentType = (response as TonikSuccess<SimpleForm>)
          .response
          .requestOptions
          .headers['content-type'];
      expect(contentType, 'application/x-www-form-urlencoded');
    });
  });
}
