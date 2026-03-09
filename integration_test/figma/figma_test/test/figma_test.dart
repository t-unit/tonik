import 'package:dio/dio.dart';
import 'package:figma_api/figma_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  late ImposterServer imposterServer;
  late String baseUrl;

  setUpAll(() async {
    imposterServer = await setupImposterServer();
    baseUrl = 'http://localhost:${imposterServer.port}';
  });

  // ── Helpers ──────────────────────────────────────────────────────────

  ActivityLogsApi buildActivityLogsApi({required String responseStatus}) {
    return ActivityLogsApi(
      CustomServer(
        baseUrl: baseUrl,
        serverConfig: ServerConfig(
          baseOptions: BaseOptions(
            headers: {'X-Response-Status': responseStatus},
          ),
        ),
      ),
    );
  }

  PaymentsApi buildPaymentsApi({required String responseStatus}) {
    return PaymentsApi(
      CustomServer(
        baseUrl: baseUrl,
        serverConfig: ServerConfig(
          baseOptions: BaseOptions(
            headers: {'X-Response-Status': responseStatus},
          ),
        ),
      ),
    );
  }

  WebhooksApi buildWebhooksApi({required String responseStatus}) {
    return WebhooksApi(
      CustomServer(
        baseUrl: baseUrl,
        serverConfig: ServerConfig(
          baseOptions: BaseOptions(
            headers: {'X-Response-Status': responseStatus},
          ),
        ),
      ),
    );
  }

  DevResourcesApi buildDevResourcesApi({required String responseStatus}) {
    return DevResourcesApi(
      CustomServer(
        baseUrl: baseUrl,
        serverConfig: ServerConfig(
          baseOptions: BaseOptions(
            headers: {'X-Response-Status': responseStatus},
          ),
        ),
      ),
    );
  }

  LibraryAnalyticsApi buildLibraryAnalyticsApi({
    required String responseStatus,
  }) {
    return LibraryAnalyticsApi(
      CustomServer(
        baseUrl: baseUrl,
        serverConfig: ServerConfig(
          baseOptions: BaseOptions(
            headers: {'X-Response-Status': responseStatus},
          ),
        ),
      ),
    );
  }

  CommentReactionsApi buildCommentReactionsApi({
    required String responseStatus,
  }) {
    return CommentReactionsApi(
      CustomServer(
        baseUrl: baseUrl,
        serverConfig: ServerConfig(
          baseOptions: BaseOptions(
            headers: {'X-Response-Status': responseStatus},
          ),
        ),
      ),
    );
  }

  // ── Activity Logs ────────────────────────────────────────────────────

  group('Activity Logs', () {
    test('getActivityLogs 200', () async {
      final api = buildActivityLogsApi(responseStatus: '200');

      final result = await api.getActivityLogs(
        events: 'login,logout',
        limit: 10,
        order: V1ActivityLogsParametersModel.desc,
      );

      expect(result, isA<TonikSuccess<GetActivityLogsResponse>>());
      final success = result as TonikSuccess<GetActivityLogsResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<GetActivityLogsResponse200>());

      final uri = success.response.requestOptions.uri;
      expect(uri.path, '/v1/activity_logs');
      expect(uri.queryParameters['events'], 'login,logout');
      expect(uri.queryParameters['limit'], '10');
      expect(uri.queryParameters['order'], 'desc');
    });

    test('getActivityLogs 200 with time range', () async {
      final api = buildActivityLogsApi(responseStatus: '200');

      final result = await api.getActivityLogs(
        startTime: 1700000000,
        endTime: 1700086400,
      );

      expect(result, isA<TonikSuccess<GetActivityLogsResponse>>());
      final success = result as TonikSuccess<GetActivityLogsResponse>;
      expect(success.value, isA<GetActivityLogsResponse200>());

      final uri = success.response.requestOptions.uri;
      expect(uri.queryParameters['start_time'], '1700000000');
      expect(uri.queryParameters['end_time'], '1700086400');
    });

    test('getActivityLogs 403', () async {
      final api = buildActivityLogsApi(responseStatus: '403');

      final result = await api.getActivityLogs();

      expect(result, isA<TonikSuccess<GetActivityLogsResponse>>());
      final success = result as TonikSuccess<GetActivityLogsResponse>;
      expect(success.response.statusCode, 403);
      expect(success.value, isA<GetActivityLogsResponse403>());
    });

    test('getActivityLogs 429', () async {
      final api = buildActivityLogsApi(responseStatus: '429');

      final result = await api.getActivityLogs();

      expect(result, isA<TonikSuccess<GetActivityLogsResponse>>());
      final success = result as TonikSuccess<GetActivityLogsResponse>;
      expect(success.response.statusCode, 429);
      expect(success.value, isA<GetActivityLogsResponse429>());
    });
  });

  // ── Payments ─────────────────────────────────────────────────────────

  group('Payments', () {
    test('getPayments 200 with plugin payment token', () async {
      final api = buildPaymentsApi(responseStatus: '200');

      final result = await api.getPayments(
        pluginPaymentToken: 'tok_abc123',
      );

      expect(result, isA<TonikSuccess<GetPaymentsResponse>>());
      final success = result as TonikSuccess<GetPaymentsResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<GetPaymentsResponse200>());

      final uri = success.response.requestOptions.uri;
      expect(uri.path, '/v1/payments');
      expect(uri.queryParameters['plugin_payment_token'], 'tok_abc123');
    });

    test('getPayments 200 with user and resource IDs', () async {
      final api = buildPaymentsApi(responseStatus: '200');

      final result = await api.getPayments(
        userId: 'user_42',
        pluginId: 'plugin_99',
      );

      expect(result, isA<TonikSuccess<GetPaymentsResponse>>());
      final success = result as TonikSuccess<GetPaymentsResponse>;
      expect(success.value, isA<GetPaymentsResponse200>());

      final uri = success.response.requestOptions.uri;
      expect(uri.queryParameters['user_id'], 'user_42');
      expect(uri.queryParameters['plugin_id'], 'plugin_99');
    });

    test('getPayments 200 with community file and widget IDs', () async {
      final api = buildPaymentsApi(responseStatus: '200');

      final result = await api.getPayments(
        userId: 'user_1',
        communityFileId: 'cf_abc',
        widgetId: 'wdg_xyz',
      );

      expect(result, isA<TonikSuccess<GetPaymentsResponse>>());
      final success = result as TonikSuccess<GetPaymentsResponse>;
      expect(success.value, isA<GetPaymentsResponse200>());

      final uri = success.response.requestOptions.uri;
      expect(uri.queryParameters['community_file_id'], 'cf_abc');
      expect(uri.queryParameters['widget_id'], 'wdg_xyz');
    });

    test('getPayments 401', () async {
      final api = buildPaymentsApi(responseStatus: '401');

      final result = await api.getPayments();

      expect(result, isA<TonikSuccess<GetPaymentsResponse>>());
      final success = result as TonikSuccess<GetPaymentsResponse>;
      expect(success.response.statusCode, 401);
      expect(success.value, isA<GetPaymentsResponse401>());
    });
  });

  // ── Webhook Requests ─────────────────────────────────────────────────

  group('Webhook Requests', () {
    test('getWebhookRequests 200', () async {
      final api = buildWebhooksApi(responseStatus: '200');

      final result = await api.getWebhookRequests(
        webhookId: 'wh_12345',
      );

      expect(result, isA<TonikSuccess<GetWebhookRequestsResponse>>());
      final success = result as TonikSuccess<GetWebhookRequestsResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<GetWebhookRequestsResponse200>());

      final uri = success.response.requestOptions.uri;
      expect(uri.path, '/v2/webhooks/wh_12345/requests');
    });

    test('getWebhookRequests 404', () async {
      final api = buildWebhooksApi(responseStatus: '404');

      final result = await api.getWebhookRequests(webhookId: 'nonexistent');

      expect(result, isA<TonikSuccess<GetWebhookRequestsResponse>>());
      final success = result as TonikSuccess<GetWebhookRequestsResponse>;
      expect(success.response.statusCode, 404);
      expect(success.value, isA<GetWebhookRequestsResponse404>());
    });

    test('getWebhookRequests 403', () async {
      final api = buildWebhooksApi(responseStatus: '403');

      final result = await api.getWebhookRequests(webhookId: 'wh_12345');

      expect(result, isA<TonikSuccess<GetWebhookRequestsResponse>>());
      final success = result as TonikSuccess<GetWebhookRequestsResponse>;
      expect(success.response.statusCode, 403);
      expect(success.value, isA<GetWebhookRequestsResponse403>());
    });
  });

  // ── Post Webhook ─────────────────────────────────────────────────────

  group('Post Webhook', () {
    test('postWebhook 200', () async {
      final api = buildWebhooksApi(responseStatus: '200');

      final result = await api.postWebhook(
        body: const V2WebhooksPostBodyBodyModel(
          eventType: WebhookV2Event.fileUpdate,
          context: 'team',
          contextId: 'team_123',
          endpoint: 'https://example.com/webhook',
          passcode: 'secret123',
          status: WebhookV2Status.active,
          description: 'File update notifications',
        ),
      );

      expect(result, isA<TonikSuccess<PostWebhookResponse>>());
      final success = result as TonikSuccess<PostWebhookResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<PostWebhookResponse200>());

      final value = (success.value as PostWebhookResponse200).body;
      expect(value, isA<WebhookV2>());
      expect(value.id, isA<String>());
      expect(value.eventType, isA<WebhookV2Event>());
      expect(value.status, isA<WebhookV2Status>());

      expect(success.response.requestOptions.uri.path, '/v2/webhooks');
      expect(success.response.requestOptions.method, 'POST');
    });

    test('postWebhook 200 with paused status', () async {
      final api = buildWebhooksApi(responseStatus: '200');

      final result = await api.postWebhook(
        body: const V2WebhooksPostBodyBodyModel(
          eventType: WebhookV2Event.libraryPublish,
          context: 'project',
          contextId: 'proj_456',
          endpoint: 'https://example.com/hooks/library',
          passcode: 'mysecret',
          status: WebhookV2Status.paused,
        ),
      );

      expect(result, isA<TonikSuccess<PostWebhookResponse>>());
      final success = result as TonikSuccess<PostWebhookResponse>;
      expect(success.value, isA<PostWebhookResponse200>());
    });

    test('postWebhook 400', () async {
      final api = buildWebhooksApi(responseStatus: '400');

      final result = await api.postWebhook(
        body: const V2WebhooksPostBodyBodyModel(
          eventType: WebhookV2Event.fileComment,
          context: 'file',
          contextId: 'file_789',
          endpoint: 'https://example.com/hooks',
          passcode: 'pass',
        ),
      );

      expect(result, isA<TonikSuccess<PostWebhookResponse>>());
      final success = result as TonikSuccess<PostWebhookResponse>;
      expect(success.response.statusCode, 400);
      expect(success.value, isA<PostWebhookResponse400>());
    });
  });

  // ── Put Webhook ──────────────────────────────────────────────────────

  group('Put Webhook', () {
    test('putWebhook 200', () async {
      final api = buildWebhooksApi(responseStatus: '200');

      final result = await api.putWebhook(
        webhookId: 'wh_update_1',
        body: const V2WebhooksWebhookIdPutBodyBodyModel(
          eventType: WebhookV2Event.fileVersionUpdate,
          endpoint: 'https://example.com/webhook/v2',
          passcode: 'newsecret',
          status: WebhookV2Status.active,
          description: 'Updated webhook',
        ),
      );

      expect(result, isA<TonikSuccess<PutWebhookResponse>>());
      final success = result as TonikSuccess<PutWebhookResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<PutWebhookResponse200>());

      final value = (success.value as PutWebhookResponse200).body;
      expect(value, isA<WebhookV2>());

      final uri = success.response.requestOptions.uri;
      expect(uri.path, '/v2/webhooks/wh_update_1');
      expect(success.response.requestOptions.method, 'PUT');
    });

    test('putWebhook 404', () async {
      final api = buildWebhooksApi(responseStatus: '404');

      final result = await api.putWebhook(
        webhookId: 'nonexistent',
        body: const V2WebhooksWebhookIdPutBodyBodyModel(
          eventType: WebhookV2Event.ping,
          endpoint: 'https://example.com/hooks',
          passcode: 'pass',
        ),
      );

      expect(result, isA<TonikSuccess<PutWebhookResponse>>());
      final success = result as TonikSuccess<PutWebhookResponse>;
      expect(success.response.statusCode, 404);
      expect(success.value, isA<PutWebhookResponse404>());
    });
  });

  // ── Delete Dev Resource ──────────────────────────────────────────────

  group('Delete Dev Resource', () {
    test('deleteDevResource 200', () async {
      final api = buildDevResourcesApi(responseStatus: '200');

      final result = await api.deleteDevResource(
        fileKey: 'file_abc',
        devResourceId: 'dr_123',
      );

      expect(result, isA<TonikSuccess<DeleteDevResourceResponse>>());
      final success = result as TonikSuccess<DeleteDevResourceResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<DeleteDevResourceResponse200>());

      final uri = success.response.requestOptions.uri;
      expect(uri.path, '/v1/files/file_abc/dev_resources/dr_123');
      expect(success.response.requestOptions.method, 'DELETE');
    });

    test('deleteDevResource 404', () async {
      final api = buildDevResourcesApi(responseStatus: '404');

      final result = await api.deleteDevResource(
        fileKey: 'file_abc',
        devResourceId: 'nonexistent',
      );

      expect(result, isA<TonikSuccess<DeleteDevResourceResponse>>());
      final success = result as TonikSuccess<DeleteDevResourceResponse>;
      expect(success.response.statusCode, 404);
      expect(success.value, isA<DeleteDevResourceResponse404>());
    });

    test('deleteDevResource 401', () async {
      final api = buildDevResourcesApi(responseStatus: '401');

      final result = await api.deleteDevResource(
        fileKey: 'file_abc',
        devResourceId: 'dr_123',
      );

      expect(result, isA<TonikSuccess<DeleteDevResourceResponse>>());
      final success = result as TonikSuccess<DeleteDevResourceResponse>;
      expect(success.response.statusCode, 401);
      expect(success.value, isA<DeleteDevResourceResponse401>());
    });
  });

  // ── Post Dev Resources ───────────────────────────────────────────────

  group('Post Dev Resources', () {
    test('postDevResources 200', () async {
      final api = buildDevResourcesApi(responseStatus: '200');

      final result = await api.postDevResources(
        body: const V1DevResourcesPostBodyBodyModel(
          devResources: [
            V1DevResourcesPostBodyBodyDevResourcesArrayModel(
              name: 'GitHub Issue',
              url: 'https://github.com/org/repo/issues/42',
              fileKey: 'file_abc',
              nodeId: '1:2',
            ),
            V1DevResourcesPostBodyBodyDevResourcesArrayModel(
              name: 'Storybook',
              url: 'https://storybook.example.com/button',
              fileKey: 'file_abc',
              nodeId: '3:4',
            ),
          ],
        ),
      );

      expect(result, isA<TonikSuccess<PostDevResourcesResponse>>());
      final success = result as TonikSuccess<PostDevResourcesResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<PostDevResourcesResponse200>());

      expect(success.response.requestOptions.uri.path, '/v1/dev_resources');
      expect(success.response.requestOptions.method, 'POST');
    });

    test('postDevResources 400', () async {
      final api = buildDevResourcesApi(responseStatus: '400');

      final result = await api.postDevResources(
        body: const V1DevResourcesPostBodyBodyModel(
          devResources: [
            V1DevResourcesPostBodyBodyDevResourcesArrayModel(
              name: 'Bad Resource',
              url: 'not-a-url',
              fileKey: 'file_abc',
              nodeId: '1:2',
            ),
          ],
        ),
      );

      expect(result, isA<TonikSuccess<PostDevResourcesResponse>>());
      final success = result as TonikSuccess<PostDevResourcesResponse>;
      expect(success.response.statusCode, 400);
      expect(success.value, isA<PostDevResourcesResponse400>());
    });
  });

  // ── Put Dev Resources ────────────────────────────────────────────────

  group('Put Dev Resources', () {
    test('putDevResources 200', () async {
      final api = buildDevResourcesApi(responseStatus: '200');

      final result = await api.putDevResources(
        body: const V1DevResourcesPutBodyBodyModel(
          devResources: [
            V1DevResourcesPutBodyBodyDevResourcesArrayModel(
              id: 'dr_123',
              name: 'Updated Resource Name',
              url: 'https://example.com/updated',
            ),
          ],
        ),
      );

      expect(result, isA<TonikSuccess<PutDevResourcesResponse>>());
      final success = result as TonikSuccess<PutDevResourcesResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<PutDevResourcesResponse200>());

      expect(success.response.requestOptions.uri.path, '/v1/dev_resources');
      expect(success.response.requestOptions.method, 'PUT');
    });

    test('putDevResources 403', () async {
      final api = buildDevResourcesApi(responseStatus: '403');

      final result = await api.putDevResources(
        body: const V1DevResourcesPutBodyBodyModel(
          devResources: [
            V1DevResourcesPutBodyBodyDevResourcesArrayModel(id: 'dr_123'),
          ],
        ),
      );

      expect(result, isA<TonikSuccess<PutDevResourcesResponse>>());
      final success = result as TonikSuccess<PutDevResourcesResponse>;
      expect(success.response.statusCode, 403);
      expect(success.value, isA<PutDevResourcesResponse403>());
    });
  });

  // ── Library Analytics: Component Actions ─────────────────────────────

  group('Library Analytics - Component Actions', () {
    test('getLibraryAnalyticsComponentActions 200 by component', () async {
      final api = buildLibraryAnalyticsApi(responseStatus: '200');

      final result = await api.getLibraryAnalyticsComponentActions(
        fileKey: 'lib_file_1',
        groupBy:
            V1AnalyticsLibrariesFileKeyComponentActionsParametersModel
                .component,
        startDate: '2024-01-01',
        endDate: '2024-12-31',
      );

      expect(
        result,
        isA<TonikSuccess<GetLibraryAnalyticsComponentActionsResponse>>(),
      );
      final success =
          result
              as TonikSuccess<GetLibraryAnalyticsComponentActionsResponse>;
      expect(success.response.statusCode, 200);
      expect(
        success.value,
        isA<GetLibraryAnalyticsComponentActionsResponse200>(),
      );

      final uri = success.response.requestOptions.uri;
      expect(
        uri.path,
        '/v1/analytics/libraries/lib_file_1/component/actions',
      );
      expect(uri.queryParameters['group_by'], 'component');
      expect(uri.queryParameters['start_date'], '2024-01-01');
      expect(uri.queryParameters['end_date'], '2024-12-31');
    });

    test('getLibraryAnalyticsComponentActions 200 by team', () async {
      final api = buildLibraryAnalyticsApi(responseStatus: '200');

      final result = await api.getLibraryAnalyticsComponentActions(
        fileKey: 'lib_file_1',
        groupBy:
            V1AnalyticsLibrariesFileKeyComponentActionsParametersModel.team,
      );

      expect(
        result,
        isA<TonikSuccess<GetLibraryAnalyticsComponentActionsResponse>>(),
      );
      final success =
          result
              as TonikSuccess<GetLibraryAnalyticsComponentActionsResponse>;
      expect(success.value,
          isA<GetLibraryAnalyticsComponentActionsResponse200>());

      expect(
        success.response.requestOptions.uri.queryParameters['group_by'],
        'team',
      );
    });

    test('getLibraryAnalyticsComponentActions 200 with cursor', () async {
      final api = buildLibraryAnalyticsApi(responseStatus: '200');

      final result = await api.getLibraryAnalyticsComponentActions(
        fileKey: 'lib_file_1',
        groupBy:
            V1AnalyticsLibrariesFileKeyComponentActionsParametersModel
                .component,
        cursor: 'next_page_token_abc',
      );

      expect(
        result,
        isA<TonikSuccess<GetLibraryAnalyticsComponentActionsResponse>>(),
      );
      final success =
          result
              as TonikSuccess<GetLibraryAnalyticsComponentActionsResponse>;
      expect(
        success.response.requestOptions.uri.queryParameters['cursor'],
        'next_page_token_abc',
      );
    });

    test('getLibraryAnalyticsComponentActions 403', () async {
      final api = buildLibraryAnalyticsApi(responseStatus: '403');

      final result = await api.getLibraryAnalyticsComponentActions(
        fileKey: 'lib_file_1',
        groupBy:
            V1AnalyticsLibrariesFileKeyComponentActionsParametersModel
                .component,
      );

      expect(
        result,
        isA<TonikSuccess<GetLibraryAnalyticsComponentActionsResponse>>(),
      );
      final success =
          result
              as TonikSuccess<GetLibraryAnalyticsComponentActionsResponse>;
      expect(success.response.statusCode, 403);
      expect(
        success.value,
        isA<GetLibraryAnalyticsComponentActionsResponse403>(),
      );
    });
  });

  // ── Library Analytics: Variable Usages ───────────────────────────────

  group('Library Analytics - Variable Usages', () {
    test('getLibraryAnalyticsVariableUsages 200 by variable', () async {
      final api = buildLibraryAnalyticsApi(responseStatus: '200');

      final result = await api.getLibraryAnalyticsVariableUsages(
        fileKey: 'var_lib_file',
        groupBy:
            V1AnalyticsLibrariesFileKeyVariableUsagesParametersModel.variable,
      );

      expect(
        result,
        isA<TonikSuccess<GetLibraryAnalyticsVariableUsagesResponse>>(),
      );
      final success =
          result
              as TonikSuccess<GetLibraryAnalyticsVariableUsagesResponse>;
      expect(success.response.statusCode, 200);
      expect(
        success.value,
        isA<GetLibraryAnalyticsVariableUsagesResponse200>(),
      );

      final uri = success.response.requestOptions.uri;
      expect(
        uri.path,
        '/v1/analytics/libraries/var_lib_file/variable/usages',
      );
      expect(uri.queryParameters['group_by'], 'variable');
    });

    test('getLibraryAnalyticsVariableUsages 200 by file', () async {
      final api = buildLibraryAnalyticsApi(responseStatus: '200');

      final result = await api.getLibraryAnalyticsVariableUsages(
        fileKey: 'var_lib_file',
        groupBy:
            V1AnalyticsLibrariesFileKeyVariableUsagesParametersModel.file,
      );

      expect(
        result,
        isA<TonikSuccess<GetLibraryAnalyticsVariableUsagesResponse>>(),
      );
      final success =
          result
              as TonikSuccess<GetLibraryAnalyticsVariableUsagesResponse>;
      expect(
        success.response.requestOptions.uri.queryParameters['group_by'],
        'file',
      );
    });

    test('getLibraryAnalyticsVariableUsages 401', () async {
      final api = buildLibraryAnalyticsApi(responseStatus: '401');

      final result = await api.getLibraryAnalyticsVariableUsages(
        fileKey: 'var_lib_file',
        groupBy:
            V1AnalyticsLibrariesFileKeyVariableUsagesParametersModel.variable,
      );

      expect(
        result,
        isA<TonikSuccess<GetLibraryAnalyticsVariableUsagesResponse>>(),
      );
      final success =
          result
              as TonikSuccess<GetLibraryAnalyticsVariableUsagesResponse>;
      expect(success.response.statusCode, 401);
      expect(
        success.value,
        isA<GetLibraryAnalyticsVariableUsagesResponse401>(),
      );
    });
  });

  // ── Delete Comment Reaction ──────────────────────────────────────────

  group('Delete Comment Reaction', () {
    test('deleteCommentReaction 200', () async {
      final api = buildCommentReactionsApi(responseStatus: '200');

      final result = await api.deleteCommentReaction(
        fileKey: 'file_xyz',
        commentId: 'comment_42',
        emoji: ':thumbsup:',
      );

      expect(result, isA<TonikSuccess<DeleteCommentReactionResponse>>());
      final success = result as TonikSuccess<DeleteCommentReactionResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<DeleteCommentReactionResponse200>());

      final uri = success.response.requestOptions.uri;
      expect(uri.path, '/v1/files/file_xyz/comments/comment_42/reactions');
      expect(uri.queryParameters['emoji'], ':thumbsup:');
      expect(success.response.requestOptions.method, 'DELETE');
    });

    test('deleteCommentReaction 404', () async {
      final api = buildCommentReactionsApi(responseStatus: '404');

      final result = await api.deleteCommentReaction(
        fileKey: 'file_xyz',
        commentId: 'comment_42',
        emoji: ':heart:',
      );

      expect(result, isA<TonikSuccess<DeleteCommentReactionResponse>>());
      final success = result as TonikSuccess<DeleteCommentReactionResponse>;
      expect(success.response.statusCode, 404);
      expect(success.value, isA<DeleteCommentReactionResponse404>());
    });

    test('deleteCommentReaction 403', () async {
      final api = buildCommentReactionsApi(responseStatus: '403');

      final result = await api.deleteCommentReaction(
        fileKey: 'file_xyz',
        commentId: 'comment_42',
        emoji: ':fire:',
      );

      expect(result, isA<TonikSuccess<DeleteCommentReactionResponse>>());
      final success = result as TonikSuccess<DeleteCommentReactionResponse>;
      expect(success.response.statusCode, 403);
      expect(success.value, isA<DeleteCommentReactionResponse403>());
    });
  });

  // ── Get Local Variables ──────────────────────────────────────────────

  group('Get Local Variables', () {
    test('getLocalVariables 200', () async {
      final api = VariablesApi(
        CustomServer(
          baseUrl: baseUrl,
          serverConfig: ServerConfig(
            baseOptions: BaseOptions(
              headers: {'X-Response-Status': '200'},
            ),
          ),
        ),
      );

      final result = await api.getLocalVariables(fileKey: 'vars_file_1');

      expect(result, isA<TonikSuccess<GetLocalVariablesResponse>>());
      final success = result as TonikSuccess<GetLocalVariablesResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<GetLocalVariablesResponse200>());

      final uri = success.response.requestOptions.uri;
      expect(uri.path, '/v1/files/vars_file_1/variables/local');
    });

    test('getLocalVariables 403', () async {
      final api = VariablesApi(
        CustomServer(
          baseUrl: baseUrl,
          serverConfig: ServerConfig(
            baseOptions: BaseOptions(
              headers: {'X-Response-Status': '403'},
            ),
          ),
        ),
      );

      final result = await api.getLocalVariables(fileKey: 'vars_file_1');

      expect(result, isA<TonikSuccess<GetLocalVariablesResponse>>());
      final success = result as TonikSuccess<GetLocalVariablesResponse>;
      expect(success.response.statusCode, 403);
      expect(success.value, isA<GetLocalVariablesResponse403>());
    });

    test('getLocalVariables 404', () async {
      final api = VariablesApi(
        CustomServer(
          baseUrl: baseUrl,
          serverConfig: ServerConfig(
            baseOptions: BaseOptions(
              headers: {'X-Response-Status': '404'},
            ),
          ),
        ),
      );

      final result = await api.getLocalVariables(fileKey: 'nonexistent');

      expect(result, isA<TonikSuccess<GetLocalVariablesResponse>>());
      final success = result as TonikSuccess<GetLocalVariablesResponse>;
      expect(success.response.statusCode, 404);
      expect(success.value, isA<GetLocalVariablesResponse404>());
    });
  });
}
