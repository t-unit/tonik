import 'package:form_urlencoded_api/form_urlencoded_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';

void main() {
  test('required nullable form sends zero bytes for null', () async {
    final server = await RawRequestServer.start();
    final api = FormApi(CustomServer(baseUrl: server.baseUrl));

    final response = await api.postNullableForm(body: null);

    expect(response, isTonikSuccess);
    final request = await server.takeRequest();
    expect(request.bodyBytes, isEmpty);
    expect(request.header('content-type'), 'application/x-www-form-urlencoded');
  });

  test('required nullable form still encodes a non-null object', () async {
    final server = await RawRequestServer.start();
    final api = FormApi(CustomServer(baseUrl: server.baseUrl));

    final response = await api.postNullableForm(
      body: const $RawNullableForm(name: 'A B'),
    );

    expect(response, isTonikSuccess);
    final request = await server.takeRequest();
    expect(request.bodyBytes, [110, 97, 109, 101, 61, 65, 43, 66]);
    expect(request.header('content-type'), 'application/x-www-form-urlencoded');
  });

  test('required nullable form variant sends zero bytes for null', () async {
    final server = await RawRequestServer.start();
    final api = FormApi(CustomServer(baseUrl: server.baseUrl));

    final response = await api.postNullableMultiForm(
      body: const FormNullableMultiPostBodyRequestBodyXWwwFormUrlencoded(null),
    );

    expect(response, isTonikSuccess);
    final request = await server.takeRequest();
    expect(request.bodyBytes, isEmpty);
    expect(request.header('content-type'), 'application/x-www-form-urlencoded');
  });

  test(
    'required nullable form variant still encodes a non-null object',
    () async {
      final server = await RawRequestServer.start();
      final api = FormApi(CustomServer(baseUrl: server.baseUrl));

      final response = await api.postNullableMultiForm(
        body: const FormNullableMultiPostBodyRequestBodyXWwwFormUrlencoded(
          $RawNullableTypeArrayForm(name: 'A&B'),
        ),
      );

      expect(response, isTonikSuccess);
      final request = await server.takeRequest();
      expect(request.bodyBytes, [110, 97, 109, 101, 61, 65, 37, 50, 54, 66]);
      expect(
        request.header('content-type'),
        'application/x-www-form-urlencoded',
      );
    },
  );
}
