import 'dart:convert';

import 'package:datadog_api/datadog_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';

void main() {
  late ImposterServer imposterServer;
  late String baseUrl;

  setUpAll(() async {
    imposterServer = await setupImposterServer();
    baseUrl = 'http://localhost:${imposterServer.port}';
  });

  CustomServer buildServer({required String responseStatus}) => CustomServer(
    baseUrl: baseUrl,
    serverConfig: testServerConfig(
      headers: {'X-Response-Status': responseStatus},
    ),
  );

  test('gets a historical security signal', () async {
    final api = SecurityMonitoringApi(buildServer(responseStatus: '200'));

    final result = await api.getSecurityMonitoringHistsignal(
      histsignalId: 'signal-42',
    );

    final response =
        requireSuccess(result).value
            as GetSecurityMonitoringHistsignalResponse200;
    expect(response.body.data?.id, 'abc-123');
    expect(
      response.body.data?.attributes?.message,
      'A large number of failed login attempts.',
    );
    expect(response.body.data?.attributes?.tags, ['source:production']);
    expect(response.body.data?.attributes?.timestamp, DateTime.utc(2024));
    final request = await imposterServer.takeRequest();
    expect(request.method, 'GET');
    expect(
      request.uri.path,
      '/api/v2/siem-historical-detections/histsignals/signal-42',
    );
  });

  test('removes an insight with a JSON DELETE body', () async {
    final api = CaseManagementApi(buildServer(responseStatus: '200'));

    final result = await api.removeCaseInsights(
      caseId: 'case-42',
      body: const CaseInsightsRequest(
        data: CaseInsightsData(
          attributes: CaseInsightsAttributes(
            insights: [
              CaseInsight(
                ref: '/security/signals/signal-42',
                resourceId: 'signal-42',
                $type: CaseInsightType.securitySignal,
              ),
            ],
          ),
        ),
      ),
    );

    final response =
        requireSuccess(result).value as RemoveCaseInsightsResponse200;
    expect(response.body.data?.id, '00000000-0000-0000-0000-000000000001');
    expect(
      response.body.data?.attributes.title,
      'Memory leak investigation on API',
    );
    final request = await imposterServer.takeRequest();
    expect(request.method, 'DELETE');
    expect(request.uri.path, '/api/v2/cases/case-42/insights');
    expect(request.headers['content-type'], contains('application/json'));
    expect(jsonDecode(request.body!), {
      'data': {
        'type': 'case',
        'attributes': {
          'insights': [
            {
              'ref': '/security/signals/signal-42',
              'resource_id': 'signal-42',
              'type': 'SECURITY_SIGNAL',
            },
          ],
        },
      },
    });
  });

  test('decodes a missing historical signal response', () async {
    final api = SecurityMonitoringApi(buildServer(responseStatus: '404'));

    final result = await api.getSecurityMonitoringHistsignal(
      histsignalId: 'missing',
    );

    final response =
        requireSuccess(result).value
            as GetSecurityMonitoringHistsignalResponse404;
    expect(response.body.errors, ['Signal not found']);
    expect(
      (await imposterServer.takeRequest()).uri.path,
      '/api/v2/siem-historical-detections/histsignals/missing',
    );
  });
}
