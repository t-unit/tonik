import 'dart:convert';
import 'dart:typed_data';

import 'package:multipart_3_1_api/multipart_3_1_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

import 'multipart_wire.dart';

void main() {
  group(
    'OAS 3.1 style-based primitive encoding (null rawContentType fallback)',
    () {
      test(
        'serializes string, integer and boolean as text/plain when only style is set',
        () async {
          final server = await _jsonServer();

          final response = await _api(server).postStylePrimitives(
            body: const StylePrimitivesForm(
              name: 'hello',
              count: 42,
              active: true,
            ),
          );

          expect(response, isTonikSuccess);
          final wire = MultipartWire(await server.takeRequest());
          expect(wire.parts.map((part) => part.name), [
            'name',
            'count',
            'active',
          ]);
          expect(wire.parts.map((part) => part.bodyText), [
            'hello',
            '42',
            'true',
          ]);
          expect(
            wire.parts.map((part) => part.contentType),
            everyElement(startsWith('text/plain')),
          );
        },
      );
    },
  );

  group('OAS 3.1 pipe-delimited encoding', () {
    test('serializes array as single pipe-delimited value', () async {
      final server = await _jsonServer();

      final response = await _api(server).postPipeDelimited(
        body: const PipeDelimitedForm(items: ['alpha', 'beta', 'gamma']),
      );

      expect(response, isTonikSuccess);
      final parts = MultipartWire(await server.takeRequest()).named('items');
      expect(parts, hasLength(1));
      expect(parts.single.bodyText, 'alpha|beta|gamma');
    });
  });

  group('OAS 3.1 form encoding with explode=false', () {
    test('serializes an array as one comma-joined multipart field', () async {
      final server = await _jsonServer();

      final response = await _api(server).postFormNonExploded(
        body: const FormNonExplodedForm(tags: ['a', 'b', 'c']),
      );

      expect(response, isTonikSuccess);
      final parts = MultipartWire(await server.takeRequest()).named('tags');
      expect(parts, hasLength(1));
      expect(parts.single.bodyText, 'a,b,c');
    });

    test('omits the optional array when it is null', () async {
      final server = await _jsonServer();

      final response = await _api(server).postFormNonExploded(
        body: const FormNonExplodedForm(),
      );

      expect(response, isTonikSuccess);
      expect(
        MultipartWire(await server.takeRequest()).named('tags'),
        isEmpty,
      );
    });

    test('serializes an empty array as one empty multipart field', () async {
      final server = await _jsonServer();

      final response = await _api(server).postFormNonExploded(
        body: const FormNonExplodedForm(tags: []),
      );

      expect(response, isTonikSuccess);
      final parts = MultipartWire(await server.takeRequest()).named('tags');
      expect(parts, hasLength(1));
      expect(parts.single.bodyText, isEmpty);
    });
  });

  group('OAS 3.1 array with no encoding specified', () {
    test(
      'serializes array as repeated form fields when no encoding is set',
      () async {
        final server = await _jsonServer();

        final response = await _api(server).postDefaultExplode(
          body: const DefaultExplodeForm(values: ['one', 'two', 'three']),
        );

        expect(response, isTonikSuccess);
        expect(
          MultipartWire(
            await server.takeRequest(),
          ).named('values').map((part) => part.bodyText),
          ['one', 'two', 'three'],
        );
      },
    );
  });

  group('OAS 3.1 deepObject style encoding', () {
    test(
      'serializes required object as bracket-notation with '
      'application/x-www-form-urlencoded content type',
      () async {
        final server = await _jsonServer();

        final response = await _api(server).postDeepObject(
          body: const DeepObjectForm(
            address: DeepObjectAddress(city: 'Berlin', zip: '10115'),
          ),
        );

        expect(response, isTonikSuccess);
        final wire = MultipartWire(await server.takeRequest());
        expect(wire.parts.map((part) => part.name), [
          'address[city]',
          'address[zip]',
        ]);
        expect(wire.single('address[city]').bodyText, 'Berlin');
        expect(wire.single('address[zip]').bodyText, '10115');
      },
    );

    test(
      'encodes string, integer, and boolean property types correctly',
      () async {
        final server = await _jsonServer();

        final response = await _api(server).postDeepObjectTypes(
          body: const DeepObjectTypesForm(
            profile: DeepObjectProfile(name: 'Alice', age: 30, active: true),
          ),
        );

        expect(response, isTonikSuccess);
        final wire = MultipartWire(await server.takeRequest());
        expect(wire.parts.map((part) => part.name), [
          'profile[name]',
          'profile[age]',
          'profile[active]',
        ]);
        expect(wire.single('profile[name]').bodyText, 'Alice');
        expect(wire.single('profile[age]').bodyText, '30');
        expect(wire.single('profile[active]').bodyText, 'true');
      },
    );

    test('URL-encodes special characters in property values', () async {
      final server = await _jsonServer();

      final response = await _api(server).postDeepObjectTypes(
        body: const DeepObjectTypesForm(
          profile: DeepObjectProfile(
            name: 'New York',
            age: 10,
            active: false,
          ),
        ),
      );

      expect(response, isTonikSuccess);
      final wire = MultipartWire(await server.takeRequest());
      expect(wire.single('profile[name]').bodyText, 'New%20York');
      expect(wire.single('profile[active]').bodyText, 'false');
    });

    test('omits optional deepObject field when null', () async {
      final server = await _jsonServer();

      final response = await _api(server).postDeepObjectOptional(
        body: const DeepObjectOptionalForm(
          shipping: DeepObjectAddress(city: 'Berlin', zip: '10115'),
        ),
      );

      expect(response, isTonikSuccess);
      final wire = MultipartWire(await server.takeRequest());
      expect(wire.single('shipping[city]').bodyText, 'Berlin');
      expect(wire.single('shipping[zip]').bodyText, '10115');
      expect(wire.named('billing[city]'), isEmpty);
      expect(wire.named('billing[zip]'), isEmpty);
    });

    test('includes optional deepObject field when provided', () async {
      final server = await _jsonServer();

      final response = await _api(server).postDeepObjectOptional(
        body: const DeepObjectOptionalForm(
          shipping: DeepObjectAddress(city: 'Berlin', zip: '10115'),
          billing: DeepObjectAddress(city: 'Paris', zip: '75001'),
        ),
      );

      expect(response, isTonikSuccess);
      final wire = MultipartWire(await server.takeRequest());
      expect(wire.single('shipping[city]').bodyText, 'Berlin');
      expect(wire.single('shipping[zip]').bodyText, '10115');
      expect(wire.single('billing[city]').bodyText, 'Paris');
      expect(wire.single('billing[zip]').bodyText, '75001');
    });
  });

  group('OAS 3.1 URL-encoded object (content-based mode)', () {
    test(
      'serializes object properties as URL-encoded key-value pairs',
      () async {
        final server = await _jsonServer();

        final response = await _api(server).postUrlEncodedObject(
          body: const UrlEncodedAddressForm(
            address: Address31(firstName: 'John', lastName: 'Doe'),
          ),
        );

        expect(response, isTonikSuccess);
        final part = MultipartWire(
          await server.takeRequest(),
        ).single('address');
        expect(
          part.contentType,
          startsWith('application/x-www-form-urlencoded'),
        );
        expect(part.bodyText, 'firstName=John&lastName=Doe');
      },
    );
  });

  group('OAS 3.1 basic multipart', () {
    test('sends string and binary fields', () async {
      final server = await _jsonServer();
      final fileBytes = Uint8List.fromList([0xDE, 0xAD, 0xBE, 0xEF]);

      final response = await _api(server).postBasic31(
        body: BasicForm(
          name: 'test-31',
          file: TonikFileBytes(fileBytes, fileName: 'payload.bin'),
        ),
      );

      expect(response, isTonikSuccess);
      final wire = MultipartWire(await server.takeRequest());
      expect(wire.single('name').bodyText, 'test-31');
      expect(wire.single('name').contentType, startsWith('text/plain'));
      expect(wire.single('file').filename, 'payload.bin');
      expect(wire.single('file').contentType, 'application/octet-stream');
      expect(wire.single('file').bodyBytes, fileBytes);
    });
  });

  group('OAS 3.1 format:byte field', () {
    test(
      'sends format:byte as binary part, not a readable text field',
      () async {
        final server = await _jsonServer();
        final fileBytes = Uint8List.fromList([0xDE, 0xAD, 0xBE, 0xEF]);

        final response = await _api(server).postByteField31(
          body: ByteForm(label: 'test-label', data: TonikFileBytes(fileBytes)),
        );

        expect(response, isTonikSuccess);
        final wire = MultipartWire(await server.takeRequest());
        expect(wire.single('label').bodyText, 'test-label');
        expect(wire.single('label').contentType, startsWith('text/plain'));
        expect(wire.single('data').contentType, 'application/octet-stream');
        expect(wire.single('data').bodyBytes, fileBytes);
      },
    );
  });

  group('OAS 3.1 AnyModel multipart JSON encoding', () {
    test('serializes Map object as valid JSON, not Dart toString()', () async {
      final server = await _jsonServer();

      final response = await _api(server).postAnyModel(
        body: const AnyModelForm(
          data: {'firstName': 'John', 'lastName': 'Doe'},
        ),
      );

      expect(response, isTonikSuccess);
      final part = MultipartWire(await server.takeRequest()).single('data');
      expect(part.contentType, startsWith('application/json'));
      expect(jsonDecode(part.bodyText), {
        'firstName': 'John',
        'lastName': 'Doe',
      });
    });

    test('serializes primitive integer as JSON number', () async {
      final server = await _jsonServer();

      final response = await _api(server).postAnyModel(
        body: const AnyModelForm(data: 42),
      );

      expect(response, isTonikSuccess);
      final part = MultipartWire(await server.takeRequest()).single('data');
      expect(part.contentType, startsWith('application/json'));
      expect(part.bodyBytes, utf8.encode('42'));
    });
  });
}

Multipart31Api _api(RawRequestServer server) => Multipart31Api(
  CustomServer(
    baseUrl: server.baseUrl,
    serverConfig: testServerConfig(),
  ),
);

Future<RawRequestServer> _jsonServer() => RawRequestServer.start(
  responseStatusCode: 200,
  responseHeaders: const {'content-type': 'application/json'},
  responseBody: utf8.encode('{"success":true,"message":"ok"}'),
);
