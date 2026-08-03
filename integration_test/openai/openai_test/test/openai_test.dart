import 'package:openai_full_api/openai_full_api.dart' hide Response;
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';

void main() {
  late ImposterServer imposterServer;
  late String baseUrl;

  setUpAll(() async {
    imposterServer = await setupImposterServer();
    baseUrl = 'http://localhost:${imposterServer.port}/v1';
  });

  // ── Helper ───────────────────────────────────────────────────────────

  CustomServer buildServer({required String responseStatus}) {
    return CustomServer(
      baseUrl: baseUrl,
      serverConfig: testServerConfig(
        headers: {'X-Response-Status': responseStatus},
      ),
    );
  }

  // ── GET /models (ListModels) ─────────────────────────────────────────

  group('ListModels', () {
    test('list_models 200', () async {
      final api = ModelsApi(buildServer(responseStatus: '200'));

      final result = await api.listModels();

      expect(
        result,
        isTonikSuccess,
      );
      final success = requireSuccess(result);
      expect(success.response.statusCode, 200);

      final uri = success.response.requestOptions.uri;
      expect(uri.path, '/v1/models');
    });
  });

  // ── GET /models/{model} (RetrieveModel) ──────────────────────────────

  group('RetrieveModel', () {
    test('retrieve_model 200', () async {
      final api = ModelsApi(buildServer(responseStatus: '200'));

      final result = await api.retrieveModel(model: 'gpt-4o');

      expect(result, isTonikSuccess);
      final success = requireSuccess(result);
      expect(success.response.statusCode, 200);

      final uri = success.response.requestOptions.uri;
      expect(uri.path, '/v1/models/gpt-4o');
    });
  });

  // ── DELETE /models/{model} (DeleteModel) ─────────────────────────────

  group('DeleteModel', () {
    test('delete_model 200', () async {
      final api = ModelsApi(buildServer(responseStatus: '200'));

      final result = await api.deleteModel(model: 'ft:gpt-4o:org:suffix:id');

      expect(
        result,
        isTonikSuccess,
      );
      final success = requireSuccess(result);
      expect(success.response.statusCode, 200);

      final uri = success.response.requestOptions.uri;
      expect(
        uri.path,
        '/v1/models/ft%3Agpt-4o%3Aorg%3Asuffix%3Aid',
      );
      expect(success.response.requestOptions.method, 'DELETE');
    });
  });

  // ── POST /embeddings (CreateEmbedding) ───────────────────────────────

  group('CreateEmbedding', () {
    test('create_embedding 200', () async {
      final api = EmbeddingsApi(buildServer(responseStatus: '200'));

      final result = await api.createEmbedding(
        body: const CreateEmbeddingRequest(
          input: CreateEmbeddingRequestInputOneOfModelString(
            'Hello world',
          ),
          model: CreateEmbeddingRequestModelAnyOfModel(
            string: 'text-embedding-ada-002',
          ),
        ),
      );

      expect(
        result,
        isTonikSuccess,
      );
      final success = requireSuccess(result);
      expect(success.response.statusCode, 200);

      final uri = success.response.requestOptions.uri;
      expect(uri.path, '/v1/embeddings');
    });
  });

  // ── POST /moderations (CreateModeration) ─────────────────────────────

  group('CreateModeration', () {
    test('create_moderation 200', () async {
      final api = ModerationsApi(buildServer(responseStatus: '200'));

      final result = await api.createModeration(
        body: const CreateModerationRequest(
          input: CreateModerationRequestInputOneOfModelString(
            'Test input',
          ),
        ),
      );

      expect(
        result,
        isTonikSuccess,
      );
      final success = requireSuccess(result);
      expect(success.response.statusCode, 200);

      final uri = success.response.requestOptions.uri;
      expect(uri.path, '/v1/moderations');
    });
  });

  // ── POST /chat/completions (CreateChatCompletion) ────────────────────

  group('CreateChatCompletion', () {
    test('create_chat_completion 200 json', () async {
      final api = ChatApi(buildServer(responseStatus: '200'));

      final result = await api.createChatCompletion(
        body: const CreateChatCompletionRequest(
          createChatCompletionRequestModel: CreateChatCompletionRequestModel(
            messages: [
              ChatCompletionRequestMessageChatCompletionRequestUserMessage(
                ChatCompletionRequestUserMessage(
                  content:
                      ChatCompletionRequestUserMessageContentOneOfModelString(
                        'Hello!',
                      ),
                  role: ChatCompletionRequestUserMessageRoleModel.user,
                ),
              ),
            ],
            model: ModelIdsShared(string: 'gpt-4o'),
          ),
          createModelResponseProperties: CreateModelResponseProperties(
            modelResponseProperties: ModelResponseProperties(),
          ),
        ),
      );

      expect(
        result,
        isTonikSuccess,
      );
      final success = requireSuccess(result);
      expect(success.response.statusCode, 200);
      expect(
        success.value,
        isA<ChatCompletionsPost200ResponseJson>(),
      );

      final uri = success.response.requestOptions.uri;
      expect(uri.path, '/v1/chat/completions');
    });
  });

  // ── GET /files (ListFiles) ───────────────────────────────────────────

  group('ListFiles', () {
    test('list_files 200', () async {
      final api = FilesApi(buildServer(responseStatus: '200'));

      final result = await api.listFiles(purpose: 'fine-tune', limit: 10);

      expect(result, isTonikSuccess);
      final success = requireSuccess(result);
      expect(success.response.statusCode, 200);

      final uri = success.response.requestOptions.uri;
      expect(uri.path, '/v1/files');
      expect(uri.queryParameters['purpose'], 'fine-tune');
      expect(uri.queryParameters['limit'], '10');
    });

    test('list_files 200 applies schema default for limit', () async {
      final api = FilesApi(buildServer(responseStatus: '200'));

      final result = await api.listFiles();

      expect(result, isTonikSuccess);
      final success = requireSuccess(result);
      expect(success.response.statusCode, 200);

      final uri = success.response.requestOptions.uri;
      expect(uri.path, '/v1/files');
      expect(uri.queryParameters['limit'], '10000');
      expect(uri.queryParameters['order'], 'desc');
      expect(uri.queryParameters.containsKey('purpose'), isFalse);
      expect(uri.queryParameters.containsKey('after'), isFalse);
    });
  });

  // ── GET /batches/{batch_id} (RetrieveBatch) ──────────────────────────

  group('RetrieveBatch', () {
    test('retrieve_batch 200', () async {
      final api = BatchApi(buildServer(responseStatus: '200'));

      final result = await api.retrieveBatch(batchId: 'batch_abc123');

      expect(result, isTonikSuccess);
      final success = requireSuccess(result);
      expect(success.response.statusCode, 200);

      final uri = success.response.requestOptions.uri;
      expect(uri.path, '/v1/batches/batch_abc123');
    });
  });

  // ── GET /fine_tuning/jobs/{id}/events (ListFineTuningEvents) ─────────

  group('ListFineTuningEvents', () {
    test('list_fine_tuning_events 200', () async {
      final api = FineTuningApi(buildServer(responseStatus: '200'));

      final result = await api.listFineTuningEvents(
        fineTuningJobId: 'ftjob-abc123',
        after: 'evt-abc',
        limit: 5,
      );

      expect(
        result,
        isTonikSuccess,
      );
      final success = requireSuccess(result);
      expect(success.response.statusCode, 200);

      final uri = success.response.requestOptions.uri;
      expect(
        uri.path,
        '/v1/fine_tuning/jobs/ftjob-abc123/events',
      );
      expect(uri.queryParameters['after'], 'evt-abc');
      expect(uri.queryParameters['limit'], '5');
    });

    test(
      'list_fine_tuning_events 200 applies schema default for limit',
      () async {
        final api = FineTuningApi(buildServer(responseStatus: '200'));

        final result = await api.listFineTuningEvents(
          fineTuningJobId: 'ftjob-abc123',
        );

        expect(
          result,
          isTonikSuccess,
        );
        final success = requireSuccess(result);
        expect(success.response.statusCode, 200);

        final uri = success.response.requestOptions.uri;
        expect(
          uri.path,
          '/v1/fine_tuning/jobs/ftjob-abc123/events',
        );
        expect(uri.queryParameters['limit'], '20');
        expect(uri.queryParameters.containsKey('after'), isFalse);
      },
    );
  });

  // ── POST /fine_tuning/jobs/{id}/cancel (CancelFineTuningJob) ─────────

  group('CancelFineTuningJob', () {
    test('cancel_fine_tuning_job 200', () async {
      final api = FineTuningApi(buildServer(responseStatus: '200'));

      final result = await api.cancelFineTuningJob(
        fineTuningJobId: 'ftjob-abc123',
      );

      expect(result, isTonikSuccess);
      final success = requireSuccess(result);
      expect(success.response.statusCode, 200);

      final uri = success.response.requestOptions.uri;
      expect(
        uri.path,
        '/v1/fine_tuning/jobs/ftjob-abc123/cancel',
      );
    });
  });
}
