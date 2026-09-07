import 'dart:convert';
import 'dart:io';

import 'package:ruby_rails_api/ruby_rails_api.dart';
import 'package:ruby_rails_example/live.dart';
import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  late CustomServer server;
  late CatalogApi api;
  setUpAll(() {
    server = liveServer();
    api = CatalogApi(server);
  });
  tearDownAll(() => server.close());

  test('nested JSON, enum, map, date, offset and explicit null', () async {
    final product = success(await api.jsonProduct());
    expect(product.id, 42);
    expect(product.name, 'Tea & café');
    expect(product.customer.name, 'Ada Example');
    expect(product.customer.id, '123e4567-e89b-12d3-a456-426614174000');
    expect(product.status.toJson(), 'available');
    expect(product.tags, ['tea', '東京']);
    expect(product.attributes, {'stock': 7});
    expect(product.released, Date(2025, 1, 2));
    expect(product.updated.timeZoneOffset, const Duration(hours: 2));
    expect(product.updated.toUtc(), DateTime.utc(2025, 1, 2, 1, 4, 5));
    expect(product.note, isNull);
    final echoed = success(await api.echoProduct(body: product));
    expect(echoed, product);
    expect(echoed.updated.timeZoneOffset, const Duration(hours: 2));
  });

  test(
    'escaped path, repeated query, integer, boolean, header and cookie',
    () async {
      final response = success(
        await api.inspect(
          key: 'café + tea & milk 100%',
          count: 2,
          enabled: false,
          tags: ['a,b', '東京 space'],
          trace: 'trace-42',
          session: 'session-42',
        ),
      );
      expect(response.text, 'café + tea & milk 100%');
      expect(response.count, 2);
      expect(response.enabled, false);
      expect(response.tags, ['a,b', '東京 space']);
      expect(response.contentType, 'trace-42');
      expect(response.fileName, 'session-42');
      expect(response.raw, contains('tags%5B%5D=a%2Cb'));
    },
  );

  test(
    'URL-encoded plus, space, ampersand and repeated array fields',
    () async {
      final response = success(
        await api.form(
          body: const FormFields(
            text: 'café + tea & milk=x',
            count: 2,
            enabled: false,
            tags: ['a,b', '東京 space'],
          ),
        ),
      );
      expect(response.text, 'café + tea & milk=x');
      expect(response.count, 2);
      expect(response.enabled, false);
      expect(response.tags, ['a,b', '東京 space']);
      expect(
        response.contentType,
        startsWith('application/x-www-form-urlencoded'),
      );
      expect(response.raw, contains('%2B'));
      expect(response.raw, contains('%26'));
    },
  );

  test('multipart memory file and parsed scalar fields', () async {
    final response = success(
      await api.upload(
        body: UploadFields(
          file: TonikFileBytes([0, 1, 127, 128, 255], fileName: 'sample.bin'),
          text: 'café + tea & milk',
          count: 2,
          enabled: false,
        ),
      ),
    );
    expect(response.fileName, 'sample.bin');
    expect(response.contentType, 'application/octet-stream');
    expect(response.bytes, [0, 1, 127, 128, 255]);
    expect(response.text, 'café + tea & milk');
    expect(response.count, 2);
    expect(response.enabled, false);
  });

  test('multipart path-backed empty file', () async {
    final directory = Directory.systemTemp.createTempSync('tonik-upload-');
    try {
      final file = File('${directory.path}/empty.bin')..writeAsBytesSync([]);
      final response = success(
        await api.upload(
          body: UploadFields(
            file: TonikFilePath(file.path, fileName: 'empty.bin'),
            text: 'empty file',
            count: 0,
            enabled: true,
          ),
        ),
      );
      expect(response.fileName, 'empty.bin');
      expect(response.bytes, <int>[]);
      expect(response.enabled, true);
    } finally {
      directory.deleteSync(recursive: true);
    }
  });

  test('binary download preserves every byte', () async {
    expect(success(await api.binary()).toBytes(), [0, 1, 127, 128, 255]);
  });

  test('binary upload preserves every byte', () async {
    final response = success(
      await api.echoBinary(body: TonikFileBytes([0, 1, 127, 128, 255])),
    );
    expect(response.toBytes(), [0, 1, 127, 128, 255]);
  });

  test('UTF-8 response bytes', () async {
    expect((success(await api.text(encoding: 'utf8'))), 'Grüße, 東京 👋');
  });
  test('Latin-1 response bytes', () async {
    expect((success(await api.text(encoding: 'latin1'))), 'café');
  });
  test('Windows-1252 response bytes', () async {
    expect((success(await api.text(encoding: 'windows1252'))), '€ café');
  });
  test('Shift-JIS response bytes', () async {
    expect((success(await api.text(encoding: 'shift-jis'))), '東京');
  });

  test('oneOf card decoding and request roundtrip', () async {
    final response = success(await api.payment(kind: 'card'));
    expect(response.payment, isA<PaymentDocumentPaymentOneOfModelCard>());
    expect(response.toJson(), {
      'payment': {'kind': 'card', 'last4': '4242'},
    });
    final echoed = success(await api.echoPayment(body: response));
    expect(echoed, response);
  });
  test('oneOf bank decoding', () async {
    final response = success(await api.payment(kind: 'bank'));
    expect(response.payment, isA<PaymentDocumentPaymentOneOfModelBank>());
    expect(response.toJson(), {
      'payment': {'kind': 'bank', 'iban': 'DE02120300000000202051'},
    });
  });
  test('anyOf email request roundtrip', () async {
    final body = ContactDocument(
      contact: ContactDocumentContactAnyOfModel(
        emailContact: EmailContact(email: 'ada@example.com'),
      ),
    );
    final response = success(await api.contact(body: body));
    expect(response.toJson(), {
      'contact': {'email': 'ada@example.com'},
    });
  });
  test('anyOf phone request roundtrip', () async {
    final body = ContactDocument(
      contact: ContactDocumentContactAnyOfModel(
        phoneContact: PhoneContact(phone: '+49 123'),
      ),
    );
    final response = success(await api.contact(body: body));
    expect(response.toJson(), {
      'contact': {'phone': '+49 123'},
    });
  });
  test('201 creation omits the write-only secret', () async {
    final response = success(
      await api.createCustomer(
        body: const CustomerInput(name: 'Grace Example', secret: 'fake-secret'),
      ),
    );
    expect(response.toJson(), {
      'id': '123e4567-e89b-12d3-a456-426614174000',
      'name': 'Grace Example',
    });

    // Inspect the raw response too: generated decoders intentionally ignore
    // undeclared properties, so toJson alone cannot detect a leaked secret.
    final rawClient = HttpClient();
    try {
      final request = await rawClient.postUrl(
        Uri.parse('${server.baseUrl}/customers'),
      );
      request.headers.contentType = ContentType.json;
      request.write('{"name":"Grace Example","secret":"fake-secret"}');
      final raw = await request.close();
      expect(raw.statusCode, 201);
      expect(jsonDecode(await utf8.decoder.bind(raw).join()), {
        'id': '123e4567-e89b-12d3-a456-426614174000',
        'name': 'Grace Example',
      });
    } finally {
      rawClient.close(force: true);
    }
  });
  test('204 deletion has no response body', () async {
    expect(await api.deleteProduct(), isA<TonikSuccess<void, Object>>());
  });
  test('declared 404 is a decoded response', () async {
    expect(success(await api.missing()).detail, 'Product not found');
  });
  test('allOf combines product and audit fields in flat JSON', () async {
    final value = success(await api.detailsOperation());
    expect(value.product.id, 42);
    expect(value.product.customer.name, 'Ada Example');
    expect(value.audit.source, 'fixture');
    expect(value.toJson(), containsPair('source', 'fixture'));
  });
  test('anyOf preserves an object matching both alternatives', () async {
    const body = ContactDocument(
      contact: ContactDocumentContactAnyOfModel(
        emailContact: EmailContact(email: 'ada@example.com'),
        phoneContact: PhoneContact(phone: '+49 123'),
      ),
    );
    final value = success(await api.contact(body: body));
    expect(value.contact.emailContact?.email, 'ada@example.com');
    expect(value.contact.phoneContact?.phone, '+49 123');
    expect(value.toJson(), {
      'contact': {'email': 'ada@example.com', 'phone': '+49 123'},
    });
  });
}
