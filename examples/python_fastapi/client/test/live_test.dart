import 'dart:convert';
import 'dart:io';

import 'package:python_fastapi_api/python_fastapi_api.dart';
import 'package:python_fastapi_example/live.dart';
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
    final echoed =
        success(await api.echoProduct(body: product)) as EchoProductResponse200;
    expect(echoed.body, product);
    expect(echoed.body.updated.timeZoneOffset, const Duration(hours: 2));
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
      ) as InspectResponse200;
      expect(response.body.text, 'café + tea & milk 100%');
      expect(response.body.count, 2);
      expect(response.body.enabled, false);
      expect(response.body.tags, ['a,b', '東京 space']);
      expect(response.body.contentType, 'trace-42');
      expect(response.body.fileName, 'session-42');
      expect(response.body.raw, contains('tags=a%2Cb'));
    },
  );

  test(
    'URL-encoded plus, space, ampersand and repeated array fields',
    () async {
      final response = success(
        await api.form(
          body: const BodyForm(
            text: 'café + tea & milk=x',
            count: 2,
            enabled: false,
            tags: ['a,b', '東京 space'],
          ),
        ),
      ) as FormResponse200;
      expect(response.body.text, 'café + tea & milk=x');
      expect(response.body.count, 2);
      expect(response.body.enabled, false);
      expect(response.body.tags, ['a,b', '東京 space']);
      expect(
        response.body.contentType,
        startsWith('application/x-www-form-urlencoded'),
      );
      expect(response.body.raw, contains('%2B'));
      expect(response.body.raw, contains('%26'));
    },
  );

  test('multipart memory file and parsed scalar fields', () async {
    final response = success(
      await api.upload(
        body: BodyUpload(
          file: TonikFileBytes([0, 1, 127, 128, 255], fileName: 'sample.bin'),
          text: 'café + tea & milk',
          count: 2,
          enabled: false,
        ),
      ),
    ) as UploadResponse200;
    expect(response.body.fileName, 'sample.bin');
    expect(response.body.contentType, 'application/octet-stream');
    expect(response.body.bytes, [0, 1, 127, 128, 255]);
    expect(response.body.text, 'café + tea & milk');
    expect(response.body.count, 2);
    expect(response.body.enabled, false);
  });

  test('multipart path-backed empty file', () async {
    final directory = Directory.systemTemp.createTempSync('tonik-upload-');
    try {
      final file = File('${directory.path}/empty.bin')..writeAsBytesSync([]);
      final response = success(
        await api.upload(
          body: BodyUpload(
            file: TonikFilePath(file.path, fileName: 'empty.bin'),
            text: 'empty file',
            count: 0,
            enabled: true,
          ),
        ),
      ) as UploadResponse200;
      expect(response.body.fileName, 'empty.bin');
      expect(response.body.bytes, <int>[]);
      expect(response.body.enabled, true);
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
    ) as EchoBinaryResponse200;
    expect(response.body.toBytes(), [0, 1, 127, 128, 255]);
  });

  test('UTF-8 response bytes', () async {
    expect(
      (success(
        await api.text(encoding: TextEncodingParametersModel.utf8),
      ) as TextResponse200).body,
      'Grüße, 東京 👋',
    );
  });
  test('Latin-1 response bytes', () async {
    expect(
      (success(
        await api.text(encoding: TextEncodingParametersModel.latin1),
      ) as TextResponse200).body,
      'café',
    );
  });
  test('Windows-1252 response bytes', () async {
    expect(
      (success(
        await api.text(encoding: TextEncodingParametersModel.windows1252),
      ) as TextResponse200).body,
      '€ café',
    );
  });
  test('Shift-JIS response bytes', () async {
    expect(
      (success(
        await api.text(encoding: TextEncodingParametersModel.shiftJis),
      ) as TextResponse200).body,
      '東京',
    );
  });

  test('oneOf card decoding and request roundtrip', () async {
    final response = success(
      await api.payment(kind: PaymentsKindParametersModel.card),
    ) as PaymentResponse200;
    expect(response.body.payment, isA<PaymentDocumentPaymentOneOfModelCard>());
    expect(response.body.toJson(), {
      'payment': {'kind': 'card', 'last4': '4242'},
    });
    final echoed = success(
      await api.echoPayment(body: response.body),
    ) as EchoPaymentResponse200;
    expect(echoed.body, response.body);
  });
  test('oneOf bank decoding', () async {
    final response = success(
      await api.payment(kind: PaymentsKindParametersModel.bank),
    ) as PaymentResponse200;
    expect(response.body.payment, isA<PaymentDocumentPaymentOneOfModelBank>());
    expect(response.body.toJson(), {
      'payment': {'kind': 'bank', 'iban': 'DE02120300000000202051'},
    });
  });
  test('anyOf email request roundtrip', () async {
    final body = ContactDocument(
      contact: ContactDocumentContactAnyOfModel(
        emailContact: EmailContact(email: 'ada@example.com'),
      ),
    );
    final response =
        success(await api.contact(body: body)) as ContactResponse200;
    expect(response.body.toJson(), {
      'contact': {'email': 'ada@example.com'},
    });
  });
  test('anyOf phone request roundtrip', () async {
    final body = ContactDocument(
      contact: ContactDocumentContactAnyOfModel(
        phoneContact: PhoneContact(phone: '+49 123'),
      ),
    );
    final response =
        success(await api.contact(body: body)) as ContactResponse200;
    expect(response.body.toJson(), {
      'contact': {'phone': '+49 123'},
    });
  });
  test('201 creation omits the write-only secret', () async {
    final response = success(
      await api.createCustomer(
        body: const CustomerInput(name: 'Grace Example', secret: 'fake-secret'),
      ),
    ) as CreateCustomerResponse201;
    expect(response.body.toJson(), {
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
  test('native query validation returns the declared 422 body', () async {
    final result = success(
      await api.inspect(
        key: 'tea',
        count: -1,
        enabled: false,
        tags: ['tea'],
        trace: 'trace-42',
        session: 'session-42',
      ),
    ) as InspectResponse422;
    expect(result.body.detail!.single.$type, 'greater_than_equal');
    expect(
      result.body.detail!.single.msg,
      'Input should be greater than or equal to 0',
    );
    expect(result.body.detail!.single.loc[0].toJson(), 'query');
    expect(result.body.detail!.single.loc[1].toJson(), 'count');
  });
  test('multipart file arrays and repeated text fields', () async {
    final directory = Directory.systemTemp.createTempSync('tonik-batch-');
    try {
      final empty = File('${directory.path}/empty.bin')..writeAsBytesSync([]);
      final result = success(
        await api.batchUpload(
          body: BodyBatchUpload(
            files: [
              TonikFileBytes([0, 1, 127, 128, 255], fileName: 'sample.bin'),
              TonikFilePath(empty.path, fileName: 'empty.bin'),
            ],
            tags: ['tea', '東京 space'],
          ),
        ),
      ) as BatchUploadResponse200;
      expect(result.body.files.length, 2);
      expect(result.body.files[0].fileName, 'sample.bin');
      expect(result.body.files[0].contentType, 'application/octet-stream');
      expect(result.body.files[0].bytes, [0, 1, 127, 128, 255]);
      expect(result.body.files[1].fileName, 'empty.bin');
      expect(result.body.files[1].bytes, <int>[]);
      expect(result.body.tags, ['tea', '東京 space']);
    } finally {
      directory.deleteSync(recursive: true);
    }
  });
  test('multipart omits an optional file', () async {
    final result = success(
      await api.optionalUpload(
        body: const BodyOptionalUpload(text: 'no attachment'),
      ),
    ) as OptionalUploadResponse200;
    expect(result.body.text, 'no attachment');
    expect(result.body.enabled, false);
    expect(result.body.fileName, '');
    expect(result.body.bytes, <int>[]);
  });
  test('anyOf preserves an object matching both alternatives', () async {
    const body = ContactDocument(
      contact: ContactDocumentContactAnyOfModel(
        emailContact: EmailContact(email: 'ada@example.com'),
        phoneContact: PhoneContact(phone: '+49 123'),
      ),
    );
    final result = success(await api.contact(body: body)) as ContactResponse200;
    expect(result.body.contact.emailContact?.email, 'ada@example.com');
    expect(result.body.contact.phoneContact?.phone, '+49 123');
    expect(result.body.toJson(), {
      'contact': {'email': 'ada@example.com', 'phone': '+49 123'},
    });
  });
  test('recursive categories preserve empty children', () async {
    final result = success(await api.categoryOperation());
    expect(result.name, 'catalog');
    expect(result.children.single.name, 'tea');
    expect(result.children.single.children, <Category>[]);
  });
  test('vendor JSON uses the documented Product model', () async {
    expect(success(await api.vendor()).customer.name, 'Ada Example');
  });
  test('configured CSV media type decodes as text', () async {
    expect(success(await api.csv()), 'id,name\n42,Tea\n');
  });
  test('problem+json error has a typed 400 payload', () async {
    final problem = success(await api.problemOperation());
    expect(problem.status, 400);
    expect(problem.$type, 'https://example.test/problems/catalog');
    expect(problem.title, 'Catalog problem');
    expect(problem.detail, 'Fake product is unavailable');
  });
}
