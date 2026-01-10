import 'package:dio/dio.dart';
import 'package:inference_api/inference_api.dart';
import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

import 'test_helper.dart';

void main() {
  const port = 8093;
  const baseUrl = 'http://localhost:$port';

  late ImposterServer imposterServer;

  setUpAll(() async {
    imposterServer = ImposterServer(port: port);
    await setupImposterServer(imposterServer);
  });

  DefaultApi buildApi({required String responseStatus}) {
    return DefaultApi(
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

  group('sendMessageProtoRouteApiV1InferSendMessagePost', () {
    group('request encoding', () {
      test('request path is /api/v1/infer/send_message', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api
            .sendMessageProtoRouteApiV1InferSendMessagePost(
              body: const SendMessageRequest(
                chatSessionId: 'session-123',
                userId: 'user-456',
                messageId: 'msg-789',
                message: 'Hello, how can you help?',
              ),
            );

        final success =
            response
                as TonikSuccess<
                  SendMessageProtoRouteApiV1InferSendMessagePostResponse
                >;
        expect(
          success.response.requestOptions.path,
          'http://localhost:8093/api/v1/infer/send_message',
        );
      });

      test('request method is POST', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api
            .sendMessageProtoRouteApiV1InferSendMessagePost(
              body: const SendMessageRequest(
                chatSessionId: 'session-123',
                userId: 'user-456',
                messageId: 'msg-789',
                message: 'Hello',
              ),
            );

        final success =
            response
                as TonikSuccess<
                  SendMessageProtoRouteApiV1InferSendMessagePostResponse
                >;
        expect(success.response.requestOptions.method, 'POST');
      });

      test('content-type header is application/json', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api
            .sendMessageProtoRouteApiV1InferSendMessagePost(
              body: const SendMessageRequest(
                chatSessionId: 'session-123',
                userId: 'user-456',
                messageId: 'msg-789',
                message: 'Hello',
              ),
            );

        final success =
            response
                as TonikSuccess<
                  SendMessageProtoRouteApiV1InferSendMessagePostResponse
                >;
        expect(
          success.response.requestOptions.contentType,
          'application/json',
        );
      });

      test('request body encodes chat_session_id as JSON property', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api
            .sendMessageProtoRouteApiV1InferSendMessagePost(
              body: const SendMessageRequest(
                chatSessionId: 'my-session-abc',
                userId: 'user-456',
                messageId: 'msg-789',
                message: 'Hello',
              ),
            );

        final success =
            response
                as TonikSuccess<
                  SendMessageProtoRouteApiV1InferSendMessagePostResponse
                >;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody['chat_session_id'], 'my-session-abc');
      });

      test('request body encodes user_id as JSON property', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api
            .sendMessageProtoRouteApiV1InferSendMessagePost(
              body: const SendMessageRequest(
                chatSessionId: 'session-123',
                userId: 'my-user-xyz',
                messageId: 'msg-789',
                message: 'Hello',
              ),
            );

        final success =
            response
                as TonikSuccess<
                  SendMessageProtoRouteApiV1InferSendMessagePostResponse
                >;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody['user_id'], 'my-user-xyz');
      });

      test('request body encodes message_id as JSON property', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api
            .sendMessageProtoRouteApiV1InferSendMessagePost(
              body: const SendMessageRequest(
                chatSessionId: 'session-123',
                userId: 'user-456',
                messageId: 'custom-msg-id',
                message: 'Hello',
              ),
            );

        final success =
            response
                as TonikSuccess<
                  SendMessageProtoRouteApiV1InferSendMessagePostResponse
                >;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody['message_id'], 'custom-msg-id');
      });

      test('request body encodes message as JSON property', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api
            .sendMessageProtoRouteApiV1InferSendMessagePost(
              body: const SendMessageRequest(
                chatSessionId: 'session-123',
                userId: 'user-456',
                messageId: 'msg-789',
                message: 'What is the weather today?',
              ),
            );

        final success =
            response
                as TonikSuccess<
                  SendMessageProtoRouteApiV1InferSendMessagePostResponse
                >;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody['message'], 'What is the weather today?');
      });

      test('special characters in message are preserved in JSON', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api
            .sendMessageProtoRouteApiV1InferSendMessagePost(
              body: const SendMessageRequest(
                chatSessionId: 'session-123',
                userId: 'user-456',
                messageId: 'msg-789',
                message: r'Special chars: @#$%^&*(){}[]|\"',
              ),
            );

        final success =
            response
                as TonikSuccess<
                  SendMessageProtoRouteApiV1InferSendMessagePostResponse
                >;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody['message'], r'Special chars: @#$%^&*(){}[]|\"');
      });

      test('unicode characters in message are preserved in JSON', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api
            .sendMessageProtoRouteApiV1InferSendMessagePost(
              body: const SendMessageRequest(
                chatSessionId: 'session-123',
                userId: 'user-456',
                messageId: 'msg-789',
                message: '你好世界 🌍 مرحبا',
              ),
            );

        final success =
            response
                as TonikSuccess<
                  SendMessageProtoRouteApiV1InferSendMessagePostResponse
                >;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody['message'], '你好世界 🌍 مرحبا');
      });

      test('request body contains required properties', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api
            .sendMessageProtoRouteApiV1InferSendMessagePost(
              body: const SendMessageRequest(
                chatSessionId: 'session-123',
                userId: 'user-456',
                messageId: 'msg-789',
                message: 'Hello',
              ),
            );

        final success =
            response
                as TonikSuccess<
                  SendMessageProtoRouteApiV1InferSendMessagePostResponse
                >;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(
          requestBody.keys,
          containsAll(['chat_session_id', 'user_id', 'message_id', 'message']),
        );
      });

      test('request body encodes custom_context when provided', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api
            .sendMessageProtoRouteApiV1InferSendMessagePost(
              body: const SendMessageRequest(
                chatSessionId: 'session-123',
                userId: 'user-456',
                messageId: 'msg-789',
                message: 'Hello',
                customContext: SendMessageRequestCustomContextAnyOfModel(
                  string: 'my custom context data',
                ),
              ),
            );

        final success =
            response
                as TonikSuccess<
                  SendMessageProtoRouteApiV1InferSendMessagePostResponse
                >;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody['custom_context'], 'my custom context data');
      });

      test('request body omits custom_context when null', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api
            .sendMessageProtoRouteApiV1InferSendMessagePost(
              body: const SendMessageRequest(
                chatSessionId: 'session-123',
                userId: 'user-456',
                messageId: 'msg-789',
                message: 'Hello',
              ),
            );

        final success =
            response
                as TonikSuccess<
                  SendMessageProtoRouteApiV1InferSendMessagePostResponse
                >;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody.containsKey('custom_context'), isFalse);
      });

      test('request body encodes reply_to_id when provided', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api
            .sendMessageProtoRouteApiV1InferSendMessagePost(
              body: const SendMessageRequest(
                chatSessionId: 'session-123',
                userId: 'user-456',
                messageId: 'msg-789',
                message: 'Hello',
                replyToId: SendMessageRequestReplyToIdAnyOfModel(
                  string: 'reply-msg-123',
                ),
              ),
            );

        final success =
            response
                as TonikSuccess<
                  SendMessageProtoRouteApiV1InferSendMessagePostResponse
                >;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody['reply_to_id'], 'reply-msg-123');
      });

      test('request body omits reply_to_id when null', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api
            .sendMessageProtoRouteApiV1InferSendMessagePost(
              body: const SendMessageRequest(
                chatSessionId: 'session-123',
                userId: 'user-456',
                messageId: 'msg-789',
                message: 'Hello',
              ),
            );

        final success =
            response
                as TonikSuccess<
                  SendMessageProtoRouteApiV1InferSendMessagePostResponse
                >;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody.containsKey('reply_to_id'), isFalse);
      });

      test('request body encodes followup_selection when provided', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api
            .sendMessageProtoRouteApiV1InferSendMessagePost(
              body: const SendMessageRequest(
                chatSessionId: 'session-123',
                userId: 'user-456',
                messageId: 'msg-789',
                message: 'Hello',
                followupSelection:
                    SendMessageRequestFollowupSelectionAnyOfModel(
                      followupSelection: FollowupSelection(
                        followupSrcId: 'followup-src-abc',
                        choiceId: 42,
                      ),
                    ),
              ),
            );

        final success =
            response
                as TonikSuccess<
                  SendMessageProtoRouteApiV1InferSendMessagePostResponse
                >;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody['followup_selection'], isA<Map<String, dynamic>>());
        final followup =
            requestBody['followup_selection'] as Map<String, dynamic>;
        expect(followup['followup_src_id'], 'followup-src-abc');
        expect(followup['choice_id'], 42);
      });

      test('request body omits followup_selection when null', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api
            .sendMessageProtoRouteApiV1InferSendMessagePost(
              body: const SendMessageRequest(
                chatSessionId: 'session-123',
                userId: 'user-456',
                messageId: 'msg-789',
                message: 'Hello',
              ),
            );

        final success =
            response
                as TonikSuccess<
                  SendMessageProtoRouteApiV1InferSendMessagePostResponse
                >;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody.containsKey('followup_selection'), isFalse);
      });

      test('request body encodes start_time when provided', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api
            .sendMessageProtoRouteApiV1InferSendMessagePost(
              body: const SendMessageRequest(
                chatSessionId: 'session-123',
                userId: 'user-456',
                messageId: 'msg-789',
                message: 'Hello',
                startTime: SendMessageRequestStartTimeAnyOfModel(
                  int: 1704067200,
                ),
              ),
            );

        final success =
            response
                as TonikSuccess<
                  SendMessageProtoRouteApiV1InferSendMessagePostResponse
                >;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody['start_time'], 1704067200);
      });

      test('request body omits start_time when null', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api
            .sendMessageProtoRouteApiV1InferSendMessagePost(
              body: const SendMessageRequest(
                chatSessionId: 'session-123',
                userId: 'user-456',
                messageId: 'msg-789',
                message: 'Hello',
              ),
            );

        final success =
            response
                as TonikSuccess<
                  SendMessageProtoRouteApiV1InferSendMessagePostResponse
                >;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody.containsKey('start_time'), isFalse);
      });

      test('request body encodes end_time when provided', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api
            .sendMessageProtoRouteApiV1InferSendMessagePost(
              body: const SendMessageRequest(
                chatSessionId: 'session-123',
                userId: 'user-456',
                messageId: 'msg-789',
                message: 'Hello',
                endTime: SendMessageRequestEndTimeAnyOfModel(
                  int: 1704153600,
                ),
              ),
            );

        final success =
            response
                as TonikSuccess<
                  SendMessageProtoRouteApiV1InferSendMessagePostResponse
                >;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody['end_time'], 1704153600);
      });

      test('request body omits end_time when null', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api
            .sendMessageProtoRouteApiV1InferSendMessagePost(
              body: const SendMessageRequest(
                chatSessionId: 'session-123',
                userId: 'user-456',
                messageId: 'msg-789',
                message: 'Hello',
              ),
            );

        final success =
            response
                as TonikSuccess<
                  SendMessageProtoRouteApiV1InferSendMessagePostResponse
                >;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody.containsKey('end_time'), isFalse);
      });

      test('request body encodes user_intent when provided', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api
            .sendMessageProtoRouteApiV1InferSendMessagePost(
              body: const SendMessageRequest(
                chatSessionId: 'session-123',
                userId: 'user-456',
                messageId: 'msg-789',
                message: 'Hello',
                userIntent: SendMessageRequestUserIntentAnyOfModel(
                  userIntent: UserIntent.searchCode,
                ),
              ),
            );

        final success =
            response
                as TonikSuccess<
                  SendMessageProtoRouteApiV1InferSendMessagePostResponse
                >;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody['user_intent'], 'SEARCH_CODE');
      });

      test(
        'request body encodes user_intent with different enum values',
        () async {
          final api = buildApi(responseStatus: '200');

          final response = await api
              .sendMessageProtoRouteApiV1InferSendMessagePost(
                body: const SendMessageRequest(
                  chatSessionId: 'session-123',
                  userId: 'user-456',
                  messageId: 'msg-789',
                  message: 'Hello',
                  userIntent: SendMessageRequestUserIntentAnyOfModel(
                    userIntent: UserIntent.directAnswer,
                  ),
                ),
              );

          final success =
              response
                  as TonikSuccess<
                    SendMessageProtoRouteApiV1InferSendMessagePostResponse
                  >;
          final requestBody =
              success.response.requestOptions.data as Map<String, dynamic>;
          expect(requestBody['user_intent'], 'DIRECT_ANSWER');
        },
      );

      test('request body omits user_intent when null', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api
            .sendMessageProtoRouteApiV1InferSendMessagePost(
              body: const SendMessageRequest(
                chatSessionId: 'session-123',
                userId: 'user-456',
                messageId: 'msg-789',
                message: 'Hello',
              ),
            );

        final success =
            response
                as TonikSuccess<
                  SendMessageProtoRouteApiV1InferSendMessagePostResponse
                >;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody.containsKey('user_intent'), isFalse);
      });

      test('request body encodes connectors array when provided', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api
            .sendMessageProtoRouteApiV1InferSendMessagePost(
              body: const SendMessageRequest(
                chatSessionId: 'session-123',
                userId: 'user-456',
                messageId: 'msg-789',
                message: 'Hello',
                connectors: [
                  Connector(
                    name: 'github-connector',
                    $type: ConnectorType.github,
                  ),
                  Connector(
                    name: 'datadog-connector',
                    $type: ConnectorType.datadog,
                  ),
                ],
              ),
            );

        final success =
            response
                as TonikSuccess<
                  SendMessageProtoRouteApiV1InferSendMessagePostResponse
                >;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody['connectors'], isA<List<dynamic>>());
        final connectors = requestBody['connectors'] as List<dynamic>;
        expect(connectors.length, 2);
        final connector0 = connectors[0] as Map<String, dynamic>;
        final connector1 = connectors[1] as Map<String, dynamic>;
        expect(connector0['name'], 'github-connector');
        expect(connector0['type'], 'GITHUB');
        expect(connector1['name'], 'datadog-connector');
        expect(connector1['type'], 'DATADOG');
      });

      test('request body encodes empty connectors array', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api
            .sendMessageProtoRouteApiV1InferSendMessagePost(
              body: const SendMessageRequest(
                chatSessionId: 'session-123',
                userId: 'user-456',
                messageId: 'msg-789',
                message: 'Hello',
                connectors: [],
              ),
            );

        final success =
            response
                as TonikSuccess<
                  SendMessageProtoRouteApiV1InferSendMessagePostResponse
                >;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody['connectors'], isA<List<dynamic>>());
        expect((requestBody['connectors'] as List<dynamic>).isEmpty, isTrue);
      });

      test('request body omits connectors when null', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api
            .sendMessageProtoRouteApiV1InferSendMessagePost(
              body: const SendMessageRequest(
                chatSessionId: 'session-123',
                userId: 'user-456',
                messageId: 'msg-789',
                message: 'Hello',
              ),
            );

        final success =
            response
                as TonikSuccess<
                  SendMessageProtoRouteApiV1InferSendMessagePostResponse
                >;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody.containsKey('connectors'), isFalse);
      });

      test('request body encodes interruption_reply as true', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api
            .sendMessageProtoRouteApiV1InferSendMessagePost(
              body: const SendMessageRequest(
                chatSessionId: 'session-123',
                userId: 'user-456',
                messageId: 'msg-789',
                message: 'Hello',
                interruptionReply: true,
              ),
            );

        final success =
            response
                as TonikSuccess<
                  SendMessageProtoRouteApiV1InferSendMessagePostResponse
                >;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody['interruption_reply'], true);
      });

      test('request body encodes interruption_reply as false', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api
            .sendMessageProtoRouteApiV1InferSendMessagePost(
              body: const SendMessageRequest(
                chatSessionId: 'session-123',
                userId: 'user-456',
                messageId: 'msg-789',
                message: 'Hello',
                interruptionReply: false,
              ),
            );

        final success =
            response
                as TonikSuccess<
                  SendMessageProtoRouteApiV1InferSendMessagePostResponse
                >;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody['interruption_reply'], false);
      });

      test('request body omits interruption_reply when null', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api
            .sendMessageProtoRouteApiV1InferSendMessagePost(
              body: const SendMessageRequest(
                chatSessionId: 'session-123',
                userId: 'user-456',
                messageId: 'msg-789',
                message: 'Hello',
              ),
            );

        final success =
            response
                as TonikSuccess<
                  SendMessageProtoRouteApiV1InferSendMessagePostResponse
                >;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody.containsKey('interruption_reply'), isFalse);
      });

      test('request body encodes user_specified_llm when provided', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api
            .sendMessageProtoRouteApiV1InferSendMessagePost(
              body: const SendMessageRequest(
                chatSessionId: 'session-123',
                userId: 'user-456',
                messageId: 'msg-789',
                message: 'Hello',
                userSpecifiedLlm: SendMessageRequestUserSpecifiedLlmAnyOfModel(
                  supportedLlm: SupportedLlm.gptO4,
                ),
              ),
            );

        final success =
            response
                as TonikSuccess<
                  SendMessageProtoRouteApiV1InferSendMessagePostResponse
                >;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody['user_specified_llm'], 'gpt-4o');
      });

      test(
        'request body encodes user_specified_llm with claude model',
        () async {
          final api = buildApi(responseStatus: '200');

          final response = await api
              .sendMessageProtoRouteApiV1InferSendMessagePost(
                body: const SendMessageRequest(
                  chatSessionId: 'session-123',
                  userId: 'user-456',
                  messageId: 'msg-789',
                  message: 'Hello',
                  userSpecifiedLlm:
                      SendMessageRequestUserSpecifiedLlmAnyOfModel(
                        supportedLlm: SupportedLlm.claude35SonnetLatest,
                      ),
                ),
              );

          final success =
              response
                  as TonikSuccess<
                    SendMessageProtoRouteApiV1InferSendMessagePostResponse
                  >;
          final requestBody =
              success.response.requestOptions.data as Map<String, dynamic>;
          expect(requestBody['user_specified_llm'], 'claude-3-5-sonnet-latest');
        },
      );

      test('request body omits user_specified_llm when null', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api
            .sendMessageProtoRouteApiV1InferSendMessagePost(
              body: const SendMessageRequest(
                chatSessionId: 'session-123',
                userId: 'user-456',
                messageId: 'msg-789',
                message: 'Hello',
              ),
            );

        final success =
            response
                as TonikSuccess<
                  SendMessageProtoRouteApiV1InferSendMessagePostResponse
                >;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody.containsKey('user_specified_llm'), isFalse);
      });

      test('request body encodes reasoning_mode as copilot', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api
            .sendMessageProtoRouteApiV1InferSendMessagePost(
              body: const SendMessageRequest(
                chatSessionId: 'session-123',
                userId: 'user-456',
                messageId: 'msg-789',
                message: 'Hello',
                reasoningMode: ReasoningMode.copilot,
              ),
            );

        final success =
            response
                as TonikSuccess<
                  SendMessageProtoRouteApiV1InferSendMessagePostResponse
                >;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody['reasoning_mode'], 'copilot');
      });

      test('request body encodes reasoning_mode as investigate', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api
            .sendMessageProtoRouteApiV1InferSendMessagePost(
              body: const SendMessageRequest(
                chatSessionId: 'session-123',
                userId: 'user-456',
                messageId: 'msg-789',
                message: 'Hello',
                reasoningMode: ReasoningMode.investigate,
              ),
            );

        final success =
            response
                as TonikSuccess<
                  SendMessageProtoRouteApiV1InferSendMessagePostResponse
                >;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody['reasoning_mode'], 'investigate');
      });

      test('request body omits reasoning_mode when null', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api
            .sendMessageProtoRouteApiV1InferSendMessagePost(
              body: const SendMessageRequest(
                chatSessionId: 'session-123',
                userId: 'user-456',
                messageId: 'msg-789',
                message: 'Hello',
              ),
            );

        final success =
            response
                as TonikSuccess<
                  SendMessageProtoRouteApiV1InferSendMessagePostResponse
                >;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody.containsKey('reasoning_mode'), isFalse);
      });

      test('request body encodes all optional fields together', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api
            .sendMessageProtoRouteApiV1InferSendMessagePost(
              body: const SendMessageRequest(
                chatSessionId: 'session-123',
                userId: 'user-456',
                messageId: 'msg-789',
                message: 'Hello with all fields',
                customContext: SendMessageRequestCustomContextAnyOfModel(
                  string: 'context data',
                ),
                replyToId: SendMessageRequestReplyToIdAnyOfModel(
                  string: 'reply-123',
                ),
                startTime: SendMessageRequestStartTimeAnyOfModel(
                  int: 1704067200,
                ),
                endTime: SendMessageRequestEndTimeAnyOfModel(
                  int: 1704153600,
                ),
                userIntent: SendMessageRequestUserIntentAnyOfModel(
                  userIntent: UserIntent.searchLogs,
                ),
                connectors: [
                  Connector(name: 'my-connector', $type: ConnectorType.elastic),
                ],
                interruptionReply: true,
                reasoningMode: ReasoningMode.investigate,
              ),
            );

        final success =
            response
                as TonikSuccess<
                  SendMessageProtoRouteApiV1InferSendMessagePostResponse
                >;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody['chat_session_id'], 'session-123');
        expect(requestBody['user_id'], 'user-456');
        expect(requestBody['message_id'], 'msg-789');
        expect(requestBody['message'], 'Hello with all fields');
        expect(requestBody['custom_context'], 'context data');
        expect(requestBody['reply_to_id'], 'reply-123');
        expect(requestBody['start_time'], 1704067200);
        expect(requestBody['end_time'], 1704153600);
        expect(requestBody['user_intent'], 'SEARCH_LOGS');
        expect(requestBody['connectors'], isA<List<dynamic>>());
        expect(requestBody['interruption_reply'], true);
        expect(requestBody['reasoning_mode'], 'investigate');
      });
    });

    group('response decoding - 200', () {
      test('200 response is decoded as Response200', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api
            .sendMessageProtoRouteApiV1InferSendMessagePost(
              body: const SendMessageRequest(
                chatSessionId: 'session-123',
                userId: 'user-456',
                messageId: 'msg-789',
                message: 'Hello',
              ),
            );

        expect(
          response,
          isA<
            TonikSuccess<SendMessageProtoRouteApiV1InferSendMessagePostResponse>
          >(),
        );
        final success =
            response
                as TonikSuccess<
                  SendMessageProtoRouteApiV1InferSendMessagePostResponse
                >;
        expect(success.response.statusCode, 200);
        expect(
          success.value,
          isA<SendMessageProtoRouteApiV1InferSendMessagePostResponse200>(),
        );
      });

      test('200 response body is ChatMessageEnvelope', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api
            .sendMessageProtoRouteApiV1InferSendMessagePost(
              body: const SendMessageRequest(
                chatSessionId: 'session-123',
                userId: 'user-456',
                messageId: 'msg-789',
                message: 'Hello',
              ),
            );

        final success =
            response
                as TonikSuccess<
                  SendMessageProtoRouteApiV1InferSendMessagePostResponse
                >;
        final response200 =
            success.value
                as SendMessageProtoRouteApiV1InferSendMessagePostResponse200;
        expect(response200.body, isA<ChatMessageEnvelope>());
      });
    });

    group('response decoding - 422', () {
      test('422 response is decoded as Response422', () async {
        final api = buildApi(responseStatus: '422');

        final response = await api
            .sendMessageProtoRouteApiV1InferSendMessagePost(
              body: const SendMessageRequest(
                chatSessionId: 'session-123',
                userId: 'user-456',
                messageId: 'msg-789',
                message: 'Hello',
              ),
            );

        expect(
          response,
          isA<
            TonikSuccess<SendMessageProtoRouteApiV1InferSendMessagePostResponse>
          >(),
        );
        final success =
            response
                as TonikSuccess<
                  SendMessageProtoRouteApiV1InferSendMessagePostResponse
                >;
        expect(success.response.statusCode, 422);
        expect(
          success.value,
          isA<SendMessageProtoRouteApiV1InferSendMessagePostResponse422>(),
        );
      });

      test('422 response body is HttpValidationError', () async {
        final api = buildApi(responseStatus: '422');

        final response = await api
            .sendMessageProtoRouteApiV1InferSendMessagePost(
              body: const SendMessageRequest(
                chatSessionId: 'session-123',
                userId: 'user-456',
                messageId: 'msg-789',
                message: 'Hello',
              ),
            );

        final success =
            response
                as TonikSuccess<
                  SendMessageProtoRouteApiV1InferSendMessagePostResponse
                >;
        final response422 =
            success.value
                as SendMessageProtoRouteApiV1InferSendMessagePostResponse422;
        expect(response422.body, isA<HttpValidationError>());
      });
    });
  });

  group('sendMessageProtoRouteApiV2InferSendMessagePost', () {
    group('request encoding', () {
      test('request path is /api/v2/infer/send_message', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api
            .sendMessageProtoRouteApiV2InferSendMessagePost(
              body: const SendMessageRequest(
                chatSessionId: 'session-123',
                userId: 'user-456',
                messageId: 'msg-789',
                message: 'Hello V2',
              ),
            );

        final success =
            response
                as TonikSuccess<
                  SendMessageProtoRouteApiV2InferSendMessagePostResponse
                >;
        expect(
          success.response.requestOptions.path,
          'http://localhost:8093/api/v2/infer/send_message',
        );
      });

      test('request method is POST', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api
            .sendMessageProtoRouteApiV2InferSendMessagePost(
              body: const SendMessageRequest(
                chatSessionId: 'session-123',
                userId: 'user-456',
                messageId: 'msg-789',
                message: 'Hello',
              ),
            );

        final success =
            response
                as TonikSuccess<
                  SendMessageProtoRouteApiV2InferSendMessagePostResponse
                >;
        expect(success.response.requestOptions.method, 'POST');
      });

      test('content-type header is application/json', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api
            .sendMessageProtoRouteApiV2InferSendMessagePost(
              body: const SendMessageRequest(
                chatSessionId: 'session-123',
                userId: 'user-456',
                messageId: 'msg-789',
                message: 'Hello',
              ),
            );

        final success =
            response
                as TonikSuccess<
                  SendMessageProtoRouteApiV2InferSendMessagePostResponse
                >;
        expect(
          success.response.requestOptions.contentType,
          'application/json',
        );
      });
    });

    group('response decoding - 200', () {
      test('200 response is decoded as Response200', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api
            .sendMessageProtoRouteApiV2InferSendMessagePost(
              body: const SendMessageRequest(
                chatSessionId: 'session-123',
                userId: 'user-456',
                messageId: 'msg-789',
                message: 'Hello',
              ),
            );

        expect(
          response,
          isA<
            TonikSuccess<SendMessageProtoRouteApiV2InferSendMessagePostResponse>
          >(),
        );
        final success =
            response
                as TonikSuccess<
                  SendMessageProtoRouteApiV2InferSendMessagePostResponse
                >;
        expect(success.response.statusCode, 200);
        expect(
          success.value,
          isA<SendMessageProtoRouteApiV2InferSendMessagePostResponse200>(),
        );
      });
    });

    group('response decoding - 422', () {
      test('422 response is decoded as Response422', () async {
        final api = buildApi(responseStatus: '422');

        final response = await api
            .sendMessageProtoRouteApiV2InferSendMessagePost(
              body: const SendMessageRequest(
                chatSessionId: 'session-123',
                userId: 'user-456',
                messageId: 'msg-789',
                message: 'Hello',
              ),
            );

        expect(
          response,
          isA<
            TonikSuccess<SendMessageProtoRouteApiV2InferSendMessagePostResponse>
          >(),
        );
        final success =
            response
                as TonikSuccess<
                  SendMessageProtoRouteApiV2InferSendMessagePostResponse
                >;
        expect(success.response.statusCode, 422);
        expect(
          success.value,
          isA<SendMessageProtoRouteApiV2InferSendMessagePostResponse422>(),
        );
      });
    });
  });

  group('listConnectorsProtoRouteApiV1InferListConnectorsGet', () {
    group('request encoding', () {
      test('request path is /api/v1/infer/list_connectors', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api
            .listConnectorsProtoRouteApiV1InferListConnectorsGet();

        final success =
            response
                as TonikSuccess<
                  List<ApiV1InferListConnectorsGet200BodyArrayModel>
                >;
        expect(
          success.response.requestOptions.path,
          'http://localhost:8093/api/v1/infer/list_connectors',
        );
      });

      test('request method is GET', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api
            .listConnectorsProtoRouteApiV1InferListConnectorsGet();

        final success =
            response
                as TonikSuccess<
                  List<ApiV1InferListConnectorsGet200BodyArrayModel>
                >;
        expect(success.response.requestOptions.method, 'GET');
      });

      test('request has no body', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api
            .listConnectorsProtoRouteApiV1InferListConnectorsGet();

        final success =
            response
                as TonikSuccess<
                  List<ApiV1InferListConnectorsGet200BodyArrayModel>
                >;
        expect(success.response.requestOptions.data, isNull);
      });
    });

    group('response decoding - 200', () {
      test('200 response returns a list', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api
            .listConnectorsProtoRouteApiV1InferListConnectorsGet();

        expect(
          response,
          isA<
            TonikSuccess<List<ApiV1InferListConnectorsGet200BodyArrayModel>>
          >(),
        );
        final success =
            response
                as TonikSuccess<
                  List<ApiV1InferListConnectorsGet200BodyArrayModel>
                >;
        expect(success.response.statusCode, 200);
        expect(
          success.value,
          isA<List<ApiV1InferListConnectorsGet200BodyArrayModel>>(),
        );
      });
    });
  });

  group('getSupportedModelsApiV1InferSupportedModelsGet', () {
    group('request encoding', () {
      test('request path is /api/v1/infer/supported_models', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api
            .getSupportedModelsApiV1InferSupportedModelsGet();

        final success = response as TonikSuccess<List<String>>;
        expect(
          success.response.requestOptions.path,
          'http://localhost:8093/api/v1/infer/supported_models',
        );
      });

      test('request method is GET', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api
            .getSupportedModelsApiV1InferSupportedModelsGet();

        final success = response as TonikSuccess<List<String>>;
        expect(success.response.requestOptions.method, 'GET');
      });

      test('request has no body', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api
            .getSupportedModelsApiV1InferSupportedModelsGet();

        final success = response as TonikSuccess<List<String>>;
        expect(success.response.requestOptions.data, isNull);
      });
    });

    group('response decoding - 200', () {
      test('200 response returns list of strings', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api
            .getSupportedModelsApiV1InferSupportedModelsGet();

        expect(response, isA<TonikSuccess<List<String>>>());
        final success = response as TonikSuccess<List<String>>;
        expect(success.response.statusCode, 200);
        expect(success.value, isA<List<String>>());
      });
    });
  });

  group('getGithubRepositories', () {
    group('request encoding', () {
      test('request path is /api/v1/github/repositories', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.getGithubRepositories(
          body: const GithubRepositoriesRequest(),
        );

        final success = response as TonikSuccess<GetGithubRepositoriesResponse>;
        expect(
          success.response.requestOptions.path,
          'http://localhost:8093/api/v1/github/repositories',
        );
      });

      test('request method is POST', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.getGithubRepositories(
          body: const GithubRepositoriesRequest(),
        );

        final success = response as TonikSuccess<GetGithubRepositoriesResponse>;
        expect(success.response.requestOptions.method, 'POST');
      });

      test('content-type header is application/json', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.getGithubRepositories(
          body: const GithubRepositoriesRequest(),
        );

        final success = response as TonikSuccess<GetGithubRepositoriesResponse>;
        expect(
          success.response.requestOptions.contentType,
          'application/json',
        );
      });
    });

    group('response decoding - 200', () {
      test('200 response is decoded as Response200', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.getGithubRepositories(
          body: const GithubRepositoriesRequest(),
        );

        expect(
          response,
          isA<TonikSuccess<GetGithubRepositoriesResponse>>(),
        );
        final success = response as TonikSuccess<GetGithubRepositoriesResponse>;
        expect(success.response.statusCode, 200);
        expect(
          success.value,
          isA<GetGithubRepositoriesResponse200>(),
        );
      });

      test('200 response body is list of strings', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.getGithubRepositories(
          body: const GithubRepositoriesRequest(),
        );

        final success = response as TonikSuccess<GetGithubRepositoriesResponse>;
        final response200 = success.value as GetGithubRepositoriesResponse200;
        expect(response200.body, isA<List<String>>());
      });
    });

    group('response decoding - 422', () {
      test('422 response is decoded as Response422', () async {
        final api = buildApi(responseStatus: '422');

        final response = await api.getGithubRepositories(
          body: const GithubRepositoriesRequest(),
        );

        expect(
          response,
          isA<TonikSuccess<GetGithubRepositoriesResponse>>(),
        );
        final success = response as TonikSuccess<GetGithubRepositoriesResponse>;
        expect(success.response.statusCode, 422);
        expect(
          success.value,
          isA<GetGithubRepositoriesResponse422>(),
        );
      });

      test('422 response body is HttpValidationError', () async {
        final api = buildApi(responseStatus: '422');

        final response = await api.getGithubRepositories(
          body: const GithubRepositoriesRequest(),
        );

        final success = response as TonikSuccess<GetGithubRepositoriesResponse>;
        final response422 = success.value as GetGithubRepositoriesResponse422;
        expect(response422.body, isA<HttpValidationError>());
      });
    });
  });

  group('getGithubReleaseProtoRouteApiV1GithubReleasePost', () {
    group('request encoding', () {
      test('request path is /api/v1/github/release', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api
            .getGithubReleaseProtoRouteApiV1GithubReleasePost(
              body: const GithubReleaseRequest(repo: 'owner/repo'),
            );

        final success =
            response
                as TonikSuccess<
                  GetGithubReleaseProtoRouteApiV1GithubReleasePostResponse
                >;
        expect(
          success.response.requestOptions.path,
          'http://localhost:8093/api/v1/github/release',
        );
      });

      test('request method is POST', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api
            .getGithubReleaseProtoRouteApiV1GithubReleasePost(
              body: const GithubReleaseRequest(repo: 'owner/repo'),
            );

        final success =
            response
                as TonikSuccess<
                  GetGithubReleaseProtoRouteApiV1GithubReleasePostResponse
                >;
        expect(success.response.requestOptions.method, 'POST');
      });

      test('content-type header is application/json', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api
            .getGithubReleaseProtoRouteApiV1GithubReleasePost(
              body: const GithubReleaseRequest(repo: 'owner/repo'),
            );

        final success =
            response
                as TonikSuccess<
                  GetGithubReleaseProtoRouteApiV1GithubReleasePostResponse
                >;
        expect(
          success.response.requestOptions.contentType,
          'application/json',
        );
      });

      test('request body encodes repo as JSON property', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api
            .getGithubReleaseProtoRouteApiV1GithubReleasePost(
              body: const GithubReleaseRequest(repo: 'flutter/flutter'),
            );

        final success =
            response
                as TonikSuccess<
                  GetGithubReleaseProtoRouteApiV1GithubReleasePostResponse
                >;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody['repo'], 'flutter/flutter');
      });

      test('request body encodes latestOnly when provided', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api
            .getGithubReleaseProtoRouteApiV1GithubReleasePost(
              body: const GithubReleaseRequest(
                repo: 'owner/repo',
                latestOnly: true,
              ),
            );

        final success =
            response
                as TonikSuccess<
                  GetGithubReleaseProtoRouteApiV1GithubReleasePostResponse
                >;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody['latest_only'], true);
      });

      test('request body does not include latestOnly when null', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api
            .getGithubReleaseProtoRouteApiV1GithubReleasePost(
              body: const GithubReleaseRequest(repo: 'owner/repo'),
            );

        final success =
            response
                as TonikSuccess<
                  GetGithubReleaseProtoRouteApiV1GithubReleasePostResponse
                >;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody.containsKey('latest_only'), isFalse);
      });
    });

    group('response decoding - 200', () {
      test('200 response is decoded as Response200', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api
            .getGithubReleaseProtoRouteApiV1GithubReleasePost(
              body: const GithubReleaseRequest(repo: 'owner/repo'),
            );

        expect(
          response,
          isA<
            TonikSuccess<
              GetGithubReleaseProtoRouteApiV1GithubReleasePostResponse
            >
          >(),
        );
        final success =
            response
                as TonikSuccess<
                  GetGithubReleaseProtoRouteApiV1GithubReleasePostResponse
                >;
        expect(success.response.statusCode, 200);
        expect(
          success.value,
          isA<GetGithubReleaseProtoRouteApiV1GithubReleasePostResponse200>(),
        );
      });

      test('200 response body is list of GithubRelease', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api
            .getGithubReleaseProtoRouteApiV1GithubReleasePost(
              body: const GithubReleaseRequest(repo: 'owner/repo'),
            );

        final success =
            response
                as TonikSuccess<
                  GetGithubReleaseProtoRouteApiV1GithubReleasePostResponse
                >;
        final response200 =
            success.value
                as GetGithubReleaseProtoRouteApiV1GithubReleasePostResponse200;
        expect(response200.body, isA<List<GithubRelease>>());
      });
    });

    group('response decoding - 422', () {
      test('422 response is decoded as Response422', () async {
        final api = buildApi(responseStatus: '422');

        final response = await api
            .getGithubReleaseProtoRouteApiV1GithubReleasePost(
              body: const GithubReleaseRequest(repo: 'owner/repo'),
            );

        expect(
          response,
          isA<
            TonikSuccess<
              GetGithubReleaseProtoRouteApiV1GithubReleasePostResponse
            >
          >(),
        );
        final success =
            response
                as TonikSuccess<
                  GetGithubReleaseProtoRouteApiV1GithubReleasePostResponse
                >;
        expect(success.response.statusCode, 422);
        expect(
          success.value,
          isA<GetGithubReleaseProtoRouteApiV1GithubReleasePostResponse422>(),
        );
      });
    });
  });

  group('getPrRouteApiV1GithubPrPost', () {
    group('request encoding', () {
      test('request path is /api/v1/github/pr', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.getPrRouteApiV1GithubPrPost(
          body: const GithubPrRequest(commitSha: 'abc123def456'),
        );

        final success =
            response as TonikSuccess<GetPrRouteApiV1GithubPrPostResponse>;
        expect(
          success.response.requestOptions.path,
          'http://localhost:8093/api/v1/github/pr',
        );
      });

      test('request method is POST', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.getPrRouteApiV1GithubPrPost(
          body: const GithubPrRequest(commitSha: 'abc123def456'),
        );

        final success =
            response as TonikSuccess<GetPrRouteApiV1GithubPrPostResponse>;
        expect(success.response.requestOptions.method, 'POST');
      });

      test('content-type header is application/json', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.getPrRouteApiV1GithubPrPost(
          body: const GithubPrRequest(commitSha: 'abc123def456'),
        );

        final success =
            response as TonikSuccess<GetPrRouteApiV1GithubPrPostResponse>;
        expect(
          success.response.requestOptions.contentType,
          'application/json',
        );
      });

      test('request body encodes commit_sha as JSON property', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.getPrRouteApiV1GithubPrPost(
          body: const GithubPrRequest(commitSha: 'xyz789commit'),
        );

        final success =
            response as TonikSuccess<GetPrRouteApiV1GithubPrPostResponse>;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody['commit_sha'], 'xyz789commit');
      });

      test(
        'request body includes only commit_sha when optional fields are null',
        () async {
          final api = buildApi(responseStatus: '200');

          final response = await api.getPrRouteApiV1GithubPrPost(
            body: const GithubPrRequest(commitSha: 'abc123'),
          );

          final success =
              response as TonikSuccess<GetPrRouteApiV1GithubPrPostResponse>;
          final requestBody =
              success.response.requestOptions.data as Map<String, dynamic>;
          expect(requestBody.containsKey('commit_sha'), isTrue);
          expect(requestBody.containsKey('customer_id'), isFalse);
          expect(requestBody.containsKey('repository'), isFalse);
        },
      );
    });

    group('response decoding - 200', () {
      test('200 response is decoded as Response200', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.getPrRouteApiV1GithubPrPost(
          body: const GithubPrRequest(commitSha: 'abc123def456'),
        );

        expect(
          response,
          isA<TonikSuccess<GetPrRouteApiV1GithubPrPostResponse>>(),
        );
        final success =
            response as TonikSuccess<GetPrRouteApiV1GithubPrPostResponse>;
        expect(success.response.statusCode, 200);
        expect(success.value, isA<GetPrRouteApiV1GithubPrPostResponse200>());
      });

      test('200 response body is list of GithubPr', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.getPrRouteApiV1GithubPrPost(
          body: const GithubPrRequest(commitSha: 'abc123def456'),
        );

        final success =
            response as TonikSuccess<GetPrRouteApiV1GithubPrPostResponse>;
        final response200 =
            success.value as GetPrRouteApiV1GithubPrPostResponse200;
        expect(response200.body, isA<List<GithubPr>>());
      });
    });

    group('response decoding - 422', () {
      test('422 response is decoded as Response422', () async {
        final api = buildApi(responseStatus: '422');

        final response = await api.getPrRouteApiV1GithubPrPost(
          body: const GithubPrRequest(commitSha: 'abc123def456'),
        );

        expect(
          response,
          isA<TonikSuccess<GetPrRouteApiV1GithubPrPostResponse>>(),
        );
        final success =
            response as TonikSuccess<GetPrRouteApiV1GithubPrPostResponse>;
        expect(success.response.statusCode, 422);
        expect(success.value, isA<GetPrRouteApiV1GithubPrPostResponse422>());
      });
    });
  });

  group('getBranchesRouteApiV1GithubBranchListPost', () {
    group('request encoding', () {
      test('request path is /api/v1/github/branch/list', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.getBranchesRouteApiV1GithubBranchListPost(
          body: const GithubGetBranchesRequest(),
        );

        final success =
            response
                as TonikSuccess<
                  GetBranchesRouteApiV1GithubBranchListPostResponse
                >;
        expect(
          success.response.requestOptions.path,
          'http://localhost:8093/api/v1/github/branch/list',
        );
      });

      test('request method is POST', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.getBranchesRouteApiV1GithubBranchListPost(
          body: const GithubGetBranchesRequest(),
        );

        final success =
            response
                as TonikSuccess<
                  GetBranchesRouteApiV1GithubBranchListPostResponse
                >;
        expect(success.response.requestOptions.method, 'POST');
      });

      test('content-type header is application/json', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.getBranchesRouteApiV1GithubBranchListPost(
          body: const GithubGetBranchesRequest(),
        );

        final success =
            response
                as TonikSuccess<
                  GetBranchesRouteApiV1GithubBranchListPostResponse
                >;
        expect(
          success.response.requestOptions.contentType,
          'application/json',
        );
      });
    });

    group('response decoding - 200', () {
      test('200 response is decoded as Response200', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.getBranchesRouteApiV1GithubBranchListPost(
          body: const GithubGetBranchesRequest(),
        );

        expect(
          response,
          isA<
            TonikSuccess<GetBranchesRouteApiV1GithubBranchListPostResponse>
          >(),
        );
        final success =
            response
                as TonikSuccess<
                  GetBranchesRouteApiV1GithubBranchListPostResponse
                >;
        expect(success.response.statusCode, 200);
        expect(
          success.value,
          isA<GetBranchesRouteApiV1GithubBranchListPostResponse200>(),
        );
      });

      test('200 response body is list of GithubBranch', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.getBranchesRouteApiV1GithubBranchListPost(
          body: const GithubGetBranchesRequest(),
        );

        final success =
            response
                as TonikSuccess<
                  GetBranchesRouteApiV1GithubBranchListPostResponse
                >;
        final response200 =
            success.value
                as GetBranchesRouteApiV1GithubBranchListPostResponse200;
        expect(response200.body, isA<List<GithubBranch>>());
      });
    });

    group('response decoding - 422', () {
      test('422 response is decoded as Response422', () async {
        final api = buildApi(responseStatus: '422');

        final response = await api.getBranchesRouteApiV1GithubBranchListPost(
          body: const GithubGetBranchesRequest(),
        );

        expect(
          response,
          isA<
            TonikSuccess<GetBranchesRouteApiV1GithubBranchListPostResponse>
          >(),
        );
        final success =
            response
                as TonikSuccess<
                  GetBranchesRouteApiV1GithubBranchListPostResponse
                >;
        expect(success.response.statusCode, 422);
        expect(
          success.value,
          isA<GetBranchesRouteApiV1GithubBranchListPostResponse422>(),
        );
      });
    });
  });

  group('getAlertRouteApiV1NewrelicAlertPost', () {
    group('request encoding', () {
      test('request path is /api/v1/newrelic/alert', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.getAlertRouteApiV1NewrelicAlertPost(
          body: const GetAlertRequest(
            connectorName: 'newrelic-prod',
            violationId: 'violation-123',
            accountId: 'account-456',
          ),
        );

        final success =
            response
                as TonikSuccess<GetAlertRouteApiV1NewrelicAlertPostResponse>;
        expect(
          success.response.requestOptions.path,
          'http://localhost:8093/api/v1/newrelic/alert',
        );
      });

      test('request method is POST', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.getAlertRouteApiV1NewrelicAlertPost(
          body: const GetAlertRequest(
            connectorName: 'newrelic-prod',
            violationId: 'violation-123',
            accountId: 'account-456',
          ),
        );

        final success =
            response
                as TonikSuccess<GetAlertRouteApiV1NewrelicAlertPostResponse>;
        expect(success.response.requestOptions.method, 'POST');
      });

      test('content-type header is application/json', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.getAlertRouteApiV1NewrelicAlertPost(
          body: const GetAlertRequest(
            connectorName: 'newrelic-prod',
            violationId: 'violation-123',
            accountId: 'account-456',
          ),
        );

        final success =
            response
                as TonikSuccess<GetAlertRouteApiV1NewrelicAlertPostResponse>;
        expect(
          success.response.requestOptions.contentType,
          'application/json',
        );
      });

      test('request body encodes connector_name as JSON property', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.getAlertRouteApiV1NewrelicAlertPost(
          body: const GetAlertRequest(
            connectorName: 'my-newrelic-connector',
            violationId: 'violation-123',
            accountId: 'account-456',
          ),
        );

        final success =
            response
                as TonikSuccess<GetAlertRouteApiV1NewrelicAlertPostResponse>;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody['connector_name'], 'my-newrelic-connector');
      });

      test('request body encodes violation_id as JSON property', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.getAlertRouteApiV1NewrelicAlertPost(
          body: const GetAlertRequest(
            connectorName: 'newrelic-prod',
            violationId: 'my-violation-xyz',
            accountId: 'account-456',
          ),
        );

        final success =
            response
                as TonikSuccess<GetAlertRouteApiV1NewrelicAlertPostResponse>;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody['violation_id'], 'my-violation-xyz');
      });

      test('request body encodes account_id as JSON property', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.getAlertRouteApiV1NewrelicAlertPost(
          body: const GetAlertRequest(
            connectorName: 'newrelic-prod',
            violationId: 'violation-123',
            accountId: 'my-account-id',
          ),
        );

        final success =
            response
                as TonikSuccess<GetAlertRouteApiV1NewrelicAlertPostResponse>;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody['account_id'], 'my-account-id');
      });

      test('request body contains all required properties', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.getAlertRouteApiV1NewrelicAlertPost(
          body: const GetAlertRequest(
            connectorName: 'newrelic-prod',
            violationId: 'violation-123',
            accountId: 'account-456',
          ),
        );

        final success =
            response
                as TonikSuccess<GetAlertRouteApiV1NewrelicAlertPostResponse>;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(
          requestBody.keys,
          containsAll(['connector_name', 'violation_id', 'account_id']),
        );
      });
    });

    group('response decoding - 200', () {
      test('200 response is decoded as Response200', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.getAlertRouteApiV1NewrelicAlertPost(
          body: const GetAlertRequest(
            connectorName: 'newrelic-prod',
            violationId: 'violation-123',
            accountId: 'account-456',
          ),
        );

        expect(
          response,
          isA<TonikSuccess<GetAlertRouteApiV1NewrelicAlertPostResponse>>(),
        );
        final success =
            response
                as TonikSuccess<GetAlertRouteApiV1NewrelicAlertPostResponse>;
        expect(success.response.statusCode, 200);
        expect(
          success.value,
          isA<GetAlertRouteApiV1NewrelicAlertPostResponse200>(),
        );
      });

      test('200 response body is ApiV1NewrelicAlertPost200BodyModel', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.getAlertRouteApiV1NewrelicAlertPost(
          body: const GetAlertRequest(
            connectorName: 'newrelic-prod',
            violationId: 'violation-123',
            accountId: 'account-456',
          ),
        );

        final success =
            response
                as TonikSuccess<GetAlertRouteApiV1NewrelicAlertPostResponse>;
        final response200 =
            success.value as GetAlertRouteApiV1NewrelicAlertPostResponse200;
        expect(response200.body, isA<ApiV1NewrelicAlertPost200BodyModel>());
      });
    });

    group('response decoding - 422', () {
      test('422 response is decoded as Response422', () async {
        final api = buildApi(responseStatus: '422');

        final response = await api.getAlertRouteApiV1NewrelicAlertPost(
          body: const GetAlertRequest(
            connectorName: 'newrelic-prod',
            violationId: 'violation-123',
            accountId: 'account-456',
          ),
        );

        expect(
          response,
          isA<TonikSuccess<GetAlertRouteApiV1NewrelicAlertPostResponse>>(),
        );
        final success =
            response
                as TonikSuccess<GetAlertRouteApiV1NewrelicAlertPostResponse>;
        expect(success.response.statusCode, 422);
        expect(
          success.value,
          isA<GetAlertRouteApiV1NewrelicAlertPostResponse422>(),
        );
      });

      test('422 response body is HttpValidationError', () async {
        final api = buildApi(responseStatus: '422');

        final response = await api.getAlertRouteApiV1NewrelicAlertPost(
          body: const GetAlertRequest(
            connectorName: 'newrelic-prod',
            violationId: 'violation-123',
            accountId: 'account-456',
          ),
        );

        final success =
            response
                as TonikSuccess<GetAlertRouteApiV1NewrelicAlertPostResponse>;
        final response422 =
            success.value as GetAlertRouteApiV1NewrelicAlertPostResponse422;
        expect(response422.body, isA<HttpValidationError>());
      });
    });
  });

  group('getDatadogAlertRouteApiV1DatadogAlertPost', () {
    group('request encoding', () {
      test('request path is /api/v1/datadog/alert', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.getDatadogAlertRouteApiV1DatadogAlertPost(
          body: const GetDatadogAlertRequest(
            connectorName: 'datadog-prod',
            link: 'https://app.datadoghq.com/monitors/123',
            monitorId: 'monitor-456',
            host: 'prod-server-1',
          ),
        );

        final success =
            response
                as TonikSuccess<
                  GetDatadogAlertRouteApiV1DatadogAlertPostResponse
                >;
        expect(
          success.response.requestOptions.path,
          'http://localhost:8093/api/v1/datadog/alert',
        );
      });

      test('request method is POST', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.getDatadogAlertRouteApiV1DatadogAlertPost(
          body: const GetDatadogAlertRequest(
            connectorName: 'datadog-prod',
            link: 'https://app.datadoghq.com/monitors/123',
            monitorId: 'monitor-456',
            host: 'prod-server-1',
          ),
        );

        final success =
            response
                as TonikSuccess<
                  GetDatadogAlertRouteApiV1DatadogAlertPostResponse
                >;
        expect(success.response.requestOptions.method, 'POST');
      });

      test('content-type header is application/json', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.getDatadogAlertRouteApiV1DatadogAlertPost(
          body: const GetDatadogAlertRequest(
            connectorName: 'datadog-prod',
            link: 'https://app.datadoghq.com/monitors/123',
            monitorId: 'monitor-456',
            host: 'prod-server-1',
          ),
        );

        final success =
            response
                as TonikSuccess<
                  GetDatadogAlertRouteApiV1DatadogAlertPostResponse
                >;
        expect(
          success.response.requestOptions.contentType,
          'application/json',
        );
      });

      test('request body encodes connector_name as JSON property', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.getDatadogAlertRouteApiV1DatadogAlertPost(
          body: const GetDatadogAlertRequest(
            connectorName: 'my-datadog-connector',
            link: 'https://app.datadoghq.com/monitors/123',
            monitorId: 'monitor-456',
            host: 'prod-server-1',
          ),
        );

        final success =
            response
                as TonikSuccess<
                  GetDatadogAlertRouteApiV1DatadogAlertPostResponse
                >;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody['connector_name'], 'my-datadog-connector');
      });

      test('request body encodes link as JSON property', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.getDatadogAlertRouteApiV1DatadogAlertPost(
          body: const GetDatadogAlertRequest(
            connectorName: 'datadog-prod',
            link: 'https://app.datadoghq.com/custom/link',
            monitorId: 'monitor-456',
            host: 'prod-server-1',
          ),
        );

        final success =
            response
                as TonikSuccess<
                  GetDatadogAlertRouteApiV1DatadogAlertPostResponse
                >;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody['link'], 'https://app.datadoghq.com/custom/link');
      });

      test('request body encodes monitor_id as JSON property', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.getDatadogAlertRouteApiV1DatadogAlertPost(
          body: const GetDatadogAlertRequest(
            connectorName: 'datadog-prod',
            link: 'https://app.datadoghq.com/monitors/123',
            monitorId: 'custom-monitor-id',
            host: 'prod-server-1',
          ),
        );

        final success =
            response
                as TonikSuccess<
                  GetDatadogAlertRouteApiV1DatadogAlertPostResponse
                >;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody['monitor_id'], 'custom-monitor-id');
      });

      test('request body encodes host as JSON property', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.getDatadogAlertRouteApiV1DatadogAlertPost(
          body: const GetDatadogAlertRequest(
            connectorName: 'datadog-prod',
            link: 'https://app.datadoghq.com/monitors/123',
            monitorId: 'monitor-456',
            host: 'my-custom-host',
          ),
        );

        final success =
            response
                as TonikSuccess<
                  GetDatadogAlertRouteApiV1DatadogAlertPostResponse
                >;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody['host'], 'my-custom-host');
      });

      test('request body contains all required properties', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.getDatadogAlertRouteApiV1DatadogAlertPost(
          body: const GetDatadogAlertRequest(
            connectorName: 'datadog-prod',
            link: 'https://app.datadoghq.com/monitors/123',
            monitorId: 'monitor-456',
            host: 'prod-server-1',
          ),
        );

        final success =
            response
                as TonikSuccess<
                  GetDatadogAlertRouteApiV1DatadogAlertPostResponse
                >;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(
          requestBody.keys,
          containsAll(['connector_name', 'link', 'monitor_id', 'host']),
        );
      });
    });

    group('response decoding - 200', () {
      test('200 response is decoded as Response200', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.getDatadogAlertRouteApiV1DatadogAlertPost(
          body: const GetDatadogAlertRequest(
            connectorName: 'datadog-prod',
            link: 'https://app.datadoghq.com/monitors/123',
            monitorId: 'monitor-456',
            host: 'prod-server-1',
          ),
        );

        expect(
          response,
          isA<
            TonikSuccess<GetDatadogAlertRouteApiV1DatadogAlertPostResponse>
          >(),
        );
        final success =
            response
                as TonikSuccess<
                  GetDatadogAlertRouteApiV1DatadogAlertPostResponse
                >;
        expect(success.response.statusCode, 200);
        expect(
          success.value,
          isA<GetDatadogAlertRouteApiV1DatadogAlertPostResponse200>(),
        );
      });

      test('200 response body is ApiV1DatadogAlertPost200BodyModel', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.getDatadogAlertRouteApiV1DatadogAlertPost(
          body: const GetDatadogAlertRequest(
            connectorName: 'datadog-prod',
            link: 'https://app.datadoghq.com/monitors/123',
            monitorId: 'monitor-456',
            host: 'prod-server-1',
          ),
        );

        final success =
            response
                as TonikSuccess<
                  GetDatadogAlertRouteApiV1DatadogAlertPostResponse
                >;
        final response200 =
            success.value
                as GetDatadogAlertRouteApiV1DatadogAlertPostResponse200;
        expect(response200.body, isA<ApiV1DatadogAlertPost200BodyModel>());
      });
    });

    group('response decoding - 422', () {
      test('422 response is decoded as Response422', () async {
        final api = buildApi(responseStatus: '422');

        final response = await api.getDatadogAlertRouteApiV1DatadogAlertPost(
          body: const GetDatadogAlertRequest(
            connectorName: 'datadog-prod',
            link: 'https://app.datadoghq.com/monitors/123',
            monitorId: 'monitor-456',
            host: 'prod-server-1',
          ),
        );

        expect(
          response,
          isA<
            TonikSuccess<GetDatadogAlertRouteApiV1DatadogAlertPostResponse>
          >(),
        );
        final success =
            response
                as TonikSuccess<
                  GetDatadogAlertRouteApiV1DatadogAlertPostResponse
                >;
        expect(success.response.statusCode, 422);
        expect(
          success.value,
          isA<GetDatadogAlertRouteApiV1DatadogAlertPostResponse422>(),
        );
      });

      test('422 response body is HttpValidationError', () async {
        final api = buildApi(responseStatus: '422');

        final response = await api.getDatadogAlertRouteApiV1DatadogAlertPost(
          body: const GetDatadogAlertRequest(
            connectorName: 'datadog-prod',
            link: 'https://app.datadoghq.com/monitors/123',
            monitorId: 'monitor-456',
            host: 'prod-server-1',
          ),
        );

        final success =
            response
                as TonikSuccess<
                  GetDatadogAlertRouteApiV1DatadogAlertPostResponse
                >;
        final response422 =
            success.value
                as GetDatadogAlertRouteApiV1DatadogAlertPostResponse422;
        expect(response422.body, isA<HttpValidationError>());
      });
    });
  });
}
