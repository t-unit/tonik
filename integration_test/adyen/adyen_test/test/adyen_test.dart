import 'dart:convert';

import 'package:adyen_api/adyen_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';

void main() {
  late ImposterServer imposterServer;
  late String baseUrl;

  setUpAll(() async {
    imposterServer = await setupImposterServer();
    baseUrl = 'http://localhost:${imposterServer.port}/v3';
  });

  CustomServer buildServer({required String responseStatus}) => CustomServer(
    baseUrl: baseUrl,
    serverConfig: testServerConfig(
      headers: {'X-Response-Status': responseStatus},
    ),
  );

  test('gets company terminal orders with query parameters', () async {
    final api = TerminalordersCompanylevelApi(
      buildServer(responseStatus: '200'),
    );

    final result = await api.getCompaniesCompanyIdTerminalOrders(
      companyId: 'company-42',
      customerOrderReference: 'purchase-42',
      status: 'Shipped',
      offset: 5,
      limit: 10,
    );

    final response =
        requireSuccess(result).value
            as GetCompaniesCompanyIdTerminalOrdersResponse200;
    expect(response.body.data, hasLength(2));
    expect(response.body.data!.first.id, '5265677890100681');
    expect(response.body.data!.first.status, 'Placed');
    expect(response.body.data!.last.status, 'Cancelled');
    final request = await imposterServer.takeRequest();
    expect(request.method, 'GET');
    expect(request.uri.path, '/v3/companies/company-42/terminalOrders');
    expect(request.uri.queryParameters, {
      'customerOrderReference': 'purchase-42',
      'status': 'Shipped',
      'offset': '5',
      'limit': '10',
    });
  });

  test('patches a merchant API credential', () async {
    final api = ApIcredentialsMerchantlevelApi(
      buildServer(responseStatus: '200'),
    );

    final result = await api
        .patchMerchantsMerchantIdApiCredentialsApiCredentialId(
          merchantId: 'merchant-42',
          apiCredentialId: 'credential-42',
          body: const UpdateMerchantApiCredentialRequest(
            active: false,
            description: 'Disabled for rotation',
            allowedOrigins: ['https://shop.example'],
          ),
        );

    final response =
        requireSuccess(result).value
            as PatchMerchantsMerchantIdApiCredentialsApiCredentialIdResponse200;
    expect(response.body.active, isTrue);
    expect(response.body.id, 'YOUR_API_CREDENTIAL');
    expect(response.body.roles, [
      'Checkout webservice role',
      'Merchant PAL Webservice role',
    ]);
    final request = await imposterServer.takeRequest();
    expect(request.method, 'PATCH');
    expect(
      request.uri.path,
      '/v3/merchants/merchant-42/apiCredentials/credential-42',
    );
    expect(jsonDecode(request.body!), {
      'active': false,
      'description': 'Disabled for rotation',
      'allowedOrigins': ['https://shop.example'],
    });
  });

  test('decodes a terminal order authorization error', () async {
    final api = TerminalordersCompanylevelApi(
      buildServer(responseStatus: '403'),
    );

    final result = await api.getCompaniesCompanyIdTerminalOrders(
      companyId: 'company-42',
    );

    final response =
        requireSuccess(result).value
            as GetCompaniesCompanyIdTerminalOrdersResponse403;
    expect(response.body.status, 403);
    expect(response.body.errorCode, '010');
    expect(response.body.detail, 'Insufficient permissions');
    expect(
      (await imposterServer.takeRequest()).uri.path,
      '/v3/companies/company-42/terminalOrders',
    );
  });
}
