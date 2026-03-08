import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:multipart_3_1_api/multipart_3_1_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  late ImposterServer imposterServer;
  late String baseUrl;
  late Multipart31Api api;

  setUpAll(() async {
    imposterServer = await setupImposterServer();
    baseUrl = 'http://localhost:${imposterServer.port}';

    api = Multipart31Api(CustomServer(baseUrl: baseUrl));
  });

  group('OAS 3.1 pipe-delimited encoding', () {
    test('serializes array as single pipe-delimited value', () async {
      const form = PipeDelimitedForm(items: ['alpha', 'beta', 'gamma']);

      final response = await api.postPipeDelimited(body: form);

      expect(response, isA<TonikSuccess<GenericResponse>>());

      final success = response as TonikSuccess<GenericResponse>;
      final formData = success.response.requestOptions.data as FormData;

      // With style: pipeDelimited and explode: false, the array should be
      // serialized as a single field with pipe-separated values.
      final itemEntries = formData.fields
          .where((e) => e.key == 'items')
          .toList();
      expect(itemEntries, hasLength(1));
      expect(itemEntries.first.value, 'alpha|beta|gamma');

      // Server received the items field.
      expect(success.response.headers['x-has-items']?.first, 'true');
    });
  });

  group('OAS 3.1 content-based array (no encoding specified)', () {
    test(
      'serializes array as single JSON-encoded part when no encoding is set',
      () async {
        const form = DefaultExplodeForm(values: ['one', 'two', 'three']);

        final response = await api.postDefaultExplode(body: form);

        expect(response, isA<TonikSuccess<GenericResponse>>());

        final success = response as TonikSuccess<GenericResponse>;

        // In OAS 3.1, when no style/explode/allowReserved are set on an array
        // property, the spec defines content-based mode: the array is
        // JSON-encoded into a single part, NOT sent as multiple exploded
        // fields.
        // The server receives one JSON string, not three separate values.
        expect(success.response.headers['x-has-values']?.first, 'true');
        expect(
          success.response.headers['x-param-values']?.first,
          '["one","two","three"]',
        );
      },
    );
  });

  group('OAS 3.1 deepObject style encoding', () {
    test(
      'serializes required object as bracket-notation with '
      'application/x-www-form-urlencoded content type',
      () async {
        const address = DeepObjectAddress(city: 'Berlin', zip: '10115');
        const form = DeepObjectForm(address: address);

        final response = await api.postDeepObject(body: form);

        expect(response, isA<TonikSuccess<GenericResponse>>());

        final success = response as TonikSuccess<GenericResponse>;
        final formData = success.response.requestOptions.data as FormData;

        // deepObject sends separate form fields with bracket-notation names.
        expect(formData.fields.any((e) => e.key == 'address[city]'), isTrue);
        expect(formData.fields.any((e) => e.key == 'address[zip]'), isTrue);

        // Server received the address as separate deepObject-encoded fields.
        expect(success.response.headers['x-has-address']?.first, 'true');
        expect(
          success.response.headers['x-address-has-city']?.first,
          'true',
        );
        expect(
          success.response.headers['x-address-has-zip']?.first,
          'true',
        );

        // Verify the actual bracket-notation values.
        final addressValue =
            success.response.headers['x-address-value']?.first ?? '';
        expect(addressValue, contains('address[city]=Berlin'));
        expect(addressValue, contains('address[zip]=10115'));
        expect(addressValue, contains('&'));
      },
    );

    test(
      'encodes string, integer, and boolean property types correctly',
      () async {
        const profile = DeepObjectProfile(
          name: 'Alice',
          age: 30,
          active: true,
        );
        const form = DeepObjectTypesForm(profile: profile);

        final response = await api.postDeepObjectTypes(body: form);

        expect(response, isA<TonikSuccess<GenericResponse>>());

        final success = response as TonikSuccess<GenericResponse>;
        final formData = success.response.requestOptions.data as FormData;

        expect(formData.fields.any((e) => e.key == 'profile[name]'), isTrue);
        expect(formData.fields.any((e) => e.key == 'profile[age]'), isTrue);
        expect(formData.fields.any((e) => e.key == 'profile[active]'), isTrue);
        expect(success.response.headers['x-has-profile']?.first, 'true');
        expect(
          success.response.headers['x-profile-has-name']?.first,
          'true',
        );
        expect(
          success.response.headers['x-profile-has-age']?.first,
          'true',
        );
        expect(
          success.response.headers['x-profile-has-active']?.first,
          'true',
        );

        final profileValue =
            success.response.headers['x-profile-value']?.first ?? '';
        expect(profileValue, contains('profile[name]=Alice'));
        expect(profileValue, contains('profile[age]=30'));
        expect(profileValue, contains('profile[active]=true'));
      },
    );

    test('URL-encodes special characters in property values', () async {
      const profile = DeepObjectProfile(
        name: 'New York',
        age: 10,
        active: false,
      );
      const form = DeepObjectTypesForm(profile: profile);

      final response = await api.postDeepObjectTypes(body: form);

      expect(response, isA<TonikSuccess<GenericResponse>>());

      final success = response as TonikSuccess<GenericResponse>;
      final profileValue =
          success.response.headers['x-profile-value']?.first ?? '';

      // Space in "New York" must be URI-encoded to %20.
      expect(profileValue, contains('profile[name]=New%20York'));
      expect(profileValue, contains('profile[active]=false'));
    });

    test('omits optional deepObject field when null', () async {
      const shipping = DeepObjectAddress(city: 'Berlin', zip: '10115');
      const form = DeepObjectOptionalForm(shipping: shipping);

      final response = await api.postDeepObjectOptional(body: form);

      expect(response, isA<TonikSuccess<GenericResponse>>());

      final success = response as TonikSuccess<GenericResponse>;
      final formData = success.response.requestOptions.data as FormData;

      expect(formData.fields.any((e) => e.key == 'shipping[city]'), isTrue);
      expect(formData.fields.any((e) => e.key == 'billing[city]'), isFalse);

      expect(success.response.headers['x-has-shipping']?.first, 'true');
      expect(success.response.headers['x-has-billing']?.first, 'false');
    });

    test('includes optional deepObject field when provided', () async {
      const shipping = DeepObjectAddress(city: 'Berlin', zip: '10115');
      const billing = DeepObjectAddress(city: 'Paris', zip: '75001');
      const form = DeepObjectOptionalForm(
        shipping: shipping,
        billing: billing,
      );

      final response = await api.postDeepObjectOptional(body: form);

      expect(response, isA<TonikSuccess<GenericResponse>>());

      final success = response as TonikSuccess<GenericResponse>;
      final formData = success.response.requestOptions.data as FormData;

      expect(formData.fields.any((e) => e.key == 'shipping[city]'), isTrue);
      expect(formData.fields.any((e) => e.key == 'billing[city]'), isTrue);

      expect(success.response.headers['x-has-shipping']?.first, 'true');
      expect(success.response.headers['x-has-billing']?.first, 'true');

      final shippingValue =
          success.response.headers['x-shipping-value']?.first ?? '';
      expect(shippingValue, contains('shipping[city]=Berlin'));
      expect(shippingValue, contains('shipping[zip]=10115'));
    });
  });

  group('OAS 3.1 URL-encoded object (content-based mode)', () {
    test(
      'serializes object properties as URL-encoded key-value pairs',
      () async {
        const address = Address31(firstName: 'John', lastName: 'Doe');
        const form = UrlEncodedAddressForm(address: address);

        final response = await api.postUrlEncodedObject(body: form);

        expect(response, isA<TonikSuccess<GenericResponse>>());

        final success = response as TonikSuccess<GenericResponse>;
        final formData = success.response.requestOptions.data as FormData;

        // The address field is a file part (not a plain field) because it
        // carries a Content-Type of application/x-www-form-urlencoded.
        expect(formData.files.any((e) => e.key == 'address'), isTrue);

        // Server received the address as a URL-encoded string.
        expect(success.response.headers['x-has-address']?.first, 'true');
        expect(
          success.response.headers['x-address-has-first-name']?.first,
          'true',
        );
        expect(
          success.response.headers['x-address-has-last-name']?.first,
          'true',
        );

        // Verify the actual URL-encoded string value.
        final addressValue =
            success.response.headers['x-address-value']?.first ?? '';
        expect(addressValue, contains('firstName=John'));
        expect(addressValue, contains('lastName=Doe'));
        expect(addressValue, contains('&'));
      },
    );
  });

  group('OAS 3.1 basic multipart', () {
    test('sends string and binary fields', () async {
      final fileBytes = Uint8List.fromList([0xDE, 0xAD, 0xBE, 0xEF]);
      final form = BasicForm(name: 'test-31', file: TonikFileBytes(fileBytes));

      final response = await api.postBasic31(body: form);

      expect(response, isA<TonikSuccess<GenericResponse>>());

      final success = response as TonikSuccess<GenericResponse>;
      final formData = success.response.requestOptions.data as FormData;

      // Scalar fields go to files with explicit Content-Type.
      expect(formData.files.any((e) => e.key == 'name'), isTrue);
      expect(formData.files.any((e) => e.key == 'file'), isTrue);

      // Server received the name text field.
      expect(success.response.headers['x-has-name']?.first, 'true');
      expect(success.response.headers['x-param-name']?.first, 'test-31');
    });
  });
}
