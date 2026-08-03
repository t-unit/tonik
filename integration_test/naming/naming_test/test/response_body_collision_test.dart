import 'dart:convert';

import 'package:naming_api/src/api_client/default_api2.dart';
import 'package:naming_api/src/server/server.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';

void main() {
  test('keeps the decoded body and the raw body_ header', () async {
    final api = DefaultApi2(
      CustomServer(
        baseUrl: 'http://localhost',
        serverConfig: testServerConfig(
          response: TestResponseStub(
            statusCode: 200,
            headers: const {
              'content-type': ['application/json'],
              'body_': ['header-value'],
            },
            bodyBytes: utf8.encode('{"id":"body-value"}'),
          ),
        ),
      ),
    );

    final result = await api.getResponseWithNormalizedBodyHeader();

    expect(
      result,
      isTonikSuccess,
    );
    final value = requireSuccess(result).value;
    expect(value.body, 'header-value');
    expect(value.body2.id, 'body-value');
  });
}
