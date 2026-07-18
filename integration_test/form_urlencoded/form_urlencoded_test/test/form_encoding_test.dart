import 'package:form_urlencoded_api/form_urlencoded_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  late ImposterServer imposterServer;
  late String baseUrl;
  late FormApi api;

  setUpAll(() async {
    imposterServer = await setupImposterServer();
    baseUrl = 'http://localhost:${imposterServer.port}';

    api = FormApi(CustomServer(baseUrl: baseUrl));
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
        'colors=red&colors=green&colors=blue&numbers=1&numbers=2&numbers=3',
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
      expect(requestData, '');

      final data = response.value;
      expect(data.colors, ['red', 'green', 'blue']);
    });

    test('encodes single-element arrays with single key', () async {
      const form = ArrayForm(colors: ['purple']);

      final response = await api.postArrayForm(body: form);

      expect(response, isA<TonikSuccess<ArrayForm>>());

      final requestData =
          (response as TonikSuccess<ArrayForm>).response.requestOptions.data;
      expect(requestData, 'colors=purple');

      final data = response.value;
      expect(data.colors, ['red', 'green', 'blue']);
    });
  });

  group('Array body property explode', () {
    test('explodes an array property with no encoding into repeated keys '
        'beside a scalar', () async {
      const form = ArrayBodyForm(q: 'hello', tags: ['urgent', 'open']);

      final response = await api.postArrayBodyForm(body: form);

      expect(response, isA<TonikSuccess<ArrayBodyForm>>());

      final success = response as TonikSuccess<ArrayBodyForm>;
      final requestData = success.response.requestOptions.data;
      expect(requestData, 'q=hello&tags=urgent&tags=open');
    });

    test('omits an entire body of only empty exploded arrays', () async {
      const form = ArrayExplodeForm(tags: []);

      final response = await api.postArrayCommaElementForm(body: form);

      expect(response, isA<TonikSuccess<ArrayExplodeForm>>());

      final requestData = (response as TonikSuccess<ArrayExplodeForm>)
          .response
          .requestOptions
          .data;
      expect(requestData, '');
    });

    test('comma-joins an array property with explicit explode false', () async {
      const form = ArrayExplodeForm(tags: ['a', 'b']);

      final response = await api.postArrayExplodeFalseForm(body: form);

      expect(response, isA<TonikSuccess<ArrayExplodeForm>>());

      final requestData = (response as TonikSuccess<ArrayExplodeForm>)
          .response
          .requestOptions
          .data;
      expect(requestData, 'tags=a,b');
    });

    test('omits an empty array property with explicit explode false', () async {
      const form = ArrayExplodeForm(tags: []);

      final response = await api.postArrayExplodeFalseForm(body: form);

      expect(response, isA<TonikSuccess<ArrayExplodeForm>>());

      final requestData = (response as TonikSuccess<ArrayExplodeForm>)
          .response
          .requestOptions
          .data;
      expect(requestData, '');
    });

    test('comma-joins a spaceDelimited array property with explode omitted',
        () async {
      const form = ArrayExplodeForm(tags: ['a', 'b']);

      final response = await api.postArraySpaceDelimitedForm(body: form);

      expect(response, isA<TonikSuccess<ArrayExplodeForm>>());

      final requestData = (response as TonikSuccess<ArrayExplodeForm>)
          .response
          .requestOptions
          .data;
      expect(requestData, 'tags=a,b');
    });

    test('explodes an array property with explicit explode true into '
        'repeated keys', () async {
      const form = ArrayExplodeForm(tags: ['a', 'b']);

      final response = await api.postArrayExplodeTrueForm(body: form);

      expect(response, isA<TonikSuccess<ArrayExplodeForm>>());

      final requestData = (response as TonikSuccess<ArrayExplodeForm>)
          .response
          .requestOptions
          .data;
      expect(requestData, 'tags=a&tags=b');
    });

    test('percent-encodes a comma inside an exploded array element', () async {
      const form = ArrayExplodeForm(tags: ['a,b', 'c']);

      final response = await api.postArrayCommaElementForm(body: form);

      expect(response, isA<TonikSuccess<ArrayExplodeForm>>());

      final requestData = (response as TonikSuccess<ArrayExplodeForm>)
          .response
          .requestOptions
          .data;
      expect(requestData, 'tags=a%2Cb&tags=c');
    });

    test('explodes a member array property of an allOf body', () async {
      const form = ArrayCompositeForm(
        arrayCompositeBase: ArrayCompositeBase(label: 'hello'),
        arrayCompositeTags: ArrayCompositeTags(tags: ['x', 'y']),
      );

      final response = await api.postArrayCompositeForm(body: form);

      expect(response, isA<TonikSuccess<ArrayCompositeForm>>());

      final requestData = (response as TonikSuccess<ArrayCompositeForm>)
          .response
          .requestOptions
          .data;
      expect(requestData, 'label=hello&tags=x&tags=y');
    });

    test('omits an absent optional array property while a present scalar '
        'still serializes', () async {
      const form = OptionalArrayForm(q: 'hello');

      final response = await api.postOptionalArrayForm(body: form);

      expect(response, isA<TonikSuccess<OptionalArrayForm>>());

      final requestData = (response as TonikSuccess<OptionalArrayForm>)
          .response
          .requestOptions
          .data;
      expect(requestData, 'q=hello');
    });

    test('sends an empty entry for a single empty-string exploded element',
        () async {
      const form = ArrayExplodeForm(tags: ['']);

      final response = await api.postArrayCommaElementForm(body: form);

      expect(response, isA<TonikSuccess<ArrayExplodeForm>>());

      final requestData = (response as TonikSuccess<ArrayExplodeForm>)
          .response
          .requestOptions
          .data;
      expect(requestData, 'tags=');
    });

    test('single-encodes a reserved char in a composite array elem', () async {
      const form = CompositeListForm(
        tags: [
          CompositeListFormTagsArrayOneOfModelString('a,b'),
          CompositeListFormTagsArrayOneOfModelInt(7),
        ],
      );

      final response = await api.postCompositeListForm(body: form);

      expect(response, isA<TonikSuccess<CompositeListForm>>());

      final requestData = (response as TonikSuccess<CompositeListForm>)
          .response
          .requestOptions
          .data;
      expect(requestData, 'tags=a%2Cb&tags=7');
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

    test('reports decoding error for form-urlencoded map response', () async {
      final response = await api.getMapResponse();

      expect(response, isA<TonikError<Map<String, String>>>());
      final error = response as TonikError<Map<String, String>>;
      expect(error.type, TonikErrorType.decoding);
      expect(error.error, isA<FormDecodingException>());
    });

    test('percent-decodes untyped additional properties', () async {
      final response = await api.getUntypedExtrasResponse();

      expect(response, isA<TonikSuccess<UntypedExtrasForm>>());
      final data = (response as TonikSuccess<UntypedExtrasForm>).value;

      expect(data.userName, 'café');
      expect(data.additionalProperties['note'], 'café');
      expect(data.additionalProperties['city'], 'New York');
    });

    test('re-encodes untyped additional properties without double '
        'encoding', () async {
      final response = await api.getUntypedExtrasResponse();
      final data = (response as TonikSuccess<UntypedExtrasForm>).value;

      final entries = data.toForm(
        'item',
        explode: true,
        allowEmpty: true,
        useQueryComponent: true,
      );

      expect(
        entries.firstWhere((e) => e.name == 'note').value,
        'caf%C3%A9',
      );
      expect(
        entries.firstWhere((e) => e.name == 'city').value,
        'New+York',
      );
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

  group('Scalar body encoding', () {
    test('encodes a top-level string body as a bare value', () async {
      final response = await api.postScalarForm(body: 'hello world');

      expect(response, isA<TonikSuccess<String>>());

      final requestData =
          (response as TonikSuccess<String>).response.requestOptions.data;
      expect(requestData, 'hello+world');
      expect((requestData as String).startsWith('='), isFalse);
    });
  });

  group('Per-property allowReserved', () {
    test(
      'keeps reserved characters literal for the flagged property and fully '
      'percent-encodes the sibling',
      () async {
        const value = 'a/b:c?d&e=f+g;h,i@j#k[l]m ';
        const form = AllowReservedForm(reserved: value, notReserved: value);

        final response = await api.postAllowReservedForm(body: form);

        expect(response, isA<TonikSuccess<AllowReservedForm>>());

        final requestData = (response as TonikSuccess<AllowReservedForm>)
            .response
            .requestOptions
            .data;
        expect(
          requestData,
          'reserved=a/b:c?d%26e%3Df%2Bg;h,i@j#k[l]m+'
              '&notReserved=a%2Fb%3Ac%3Fd%26e%3Df%2Bg%3Bh%2Ci%40j%23k%5Bl%5Dm+',
        );
      },
    );

    test(
      'null-guards a write-only sibling and keeps it fully percent-encoded '
      'beside the flagged property',
      () async {
        const form = AllowReservedMixedForm(reserved: 'a/b:c', secret: 'a/b:c');

        final response = await api.postAllowReservedMixedForm(body: form);

        expect(response, isA<TonikSuccess<AllowReservedMixedForm>>());

        final requestData = (response as TonikSuccess<AllowReservedMixedForm>)
            .response
            .requestOptions
            .data;
        expect(requestData, 'reserved=a/b:c&secret=a%2Fb%3Ac');
      },
    );

    test(
      'sends a write property that a read-only sibling forces onto a suffixed '
      'field, keeping reserved characters literal',
      () async {
        const form = AllowReservedCollisionForm(userName2: 'a/b:c');

        final response = await api.postAllowReservedCollisionForm(body: form);

        expect(response, isA<TonikSuccess<AllowReservedCollisionForm>>());

        final requestData =
            (response as TonikSuccess<AllowReservedCollisionForm>)
                .response
                .requestOptions
                .data;
        expect(requestData, 'user_name=a/b:c');
      },
    );

    test(
      'explodes an array sibling into repeated keys beside the flagged scalar',
      () async {
        const form = AllowReservedArrayForm(
          reserved: 'a/b:c',
          tags: ['x', 'y', 'z'],
        );

        final response = await api.postAllowReservedArrayForm(body: form);

        expect(response, isA<TonikSuccess<AllowReservedArrayForm>>());

        final requestData = (response as TonikSuccess<AllowReservedArrayForm>)
            .response
            .requestOptions
            .data;
        expect(requestData, 'reserved=a/b:c&tags=x&tags=y&tags=z');
      },
    );

    test(
      'keeps reserved characters literal per exploded element of a flagged '
      'array property',
      () async {
        const form = AllowReservedArrayFlaggedForm(tags: ['a/b', 'c:d']);

        final response = await api.postAllowReservedArrayFlaggedForm(
          body: form,
        );

        expect(response, isA<TonikSuccess<AllowReservedArrayFlaggedForm>>());

        final requestData =
            (response as TonikSuccess<AllowReservedArrayFlaggedForm>)
                .response
                .requestOptions
                .data;
        expect(requestData, 'tags=a/b&tags=c:d');
      },
    );

    test(
      'keeps reserved characters literal for a flagged enum property through '
      'the shared form-entries path',
      () async {
        const form = AllowReservedEnumForm(
          choice: AllowReservedEnumFormChoiceModel.gAmpersandHEqualsIPlusJ,
        );

        final response = await api.postAllowReservedEnumForm(body: form);

        expect(response, isA<TonikSuccess<AllowReservedEnumForm>>());

        final requestData = (response as TonikSuccess<AllowReservedEnumForm>)
            .response
            .requestOptions
            .data;
        expect(requestData, 'choice=g%26h%3Di%2Bj');
      },
    );

    test(
      'sends the flagged declared property literal alongside encoded '
      'additionalProperties entries',
      () async {
        const form = AllowReservedAdditionalForm(
          reserved: 'a/b:c',
          additionalProperties: {'extra': 'x/y'},
        );

        final response = await api.postAllowReservedAdditionalForm(body: form);

        expect(response, isA<TonikSuccess<AllowReservedAdditionalForm>>());

        final requestData =
            (response as TonikSuccess<AllowReservedAdditionalForm>)
                .response
                .requestOptions
                .data;
        expect(requestData, 'reserved=a/b:c&extra=x%2Fy');
      },
    );

    test(
      'keeps reserved characters literal for a flagged allOf property',
      () async {
        const form = AllowReservedCompositeForm(
          reservedBase: ReservedBase(reserved: 'a/b:c'),
        );

        final response = await api.postAllowReservedCompositeForm(body: form);

        expect(response, isA<TonikSuccess<AllowReservedCompositeForm>>());

        final requestData =
            (response as TonikSuccess<AllowReservedCompositeForm>)
                .response
                .requestOptions
                .data;
        expect(requestData, 'reserved=a/b:c');
      },
    );
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
