import 'package:dio/dio.dart';
import 'package:openai_full_api/openai_full_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  late ImposterServer imposterServer;
  late String baseUrl;

  setUpAll(() async {
    imposterServer = await setupImposterServer();
    baseUrl = 'http://localhost:${imposterServer.port}/v1';
  });

  // ── Helper ───────────────────────────────────────────────────────────

  /// Creates a [Dio] instance for direct operation usage.
  Dio buildDio({required String responseStatus}) {
    return Dio(
      BaseOptions(
        baseUrl: baseUrl,
        headers: {'X-Response-Status': responseStatus},
      ),
    );
  }

  // ── GET /models (ListModels) ─────────────────────────────────────────

  group('ListModels', () {
    test('list_models 200', () async {
      final op = ListModels(buildDio(responseStatus: '200'));

      final result = await op();

      expect(result, isA<TonikSuccess<ListModelsResponse>>());
      final success = result as TonikSuccess<ListModelsResponse>;
      expect(success.response.statusCode, 200);

      final uri = success.response.requestOptions.uri;
      expect(uri.path, '/v1/models');
    });
  });

  // ── GET /models/{model} (RetrieveModel) ──────────────────────────────

  group('RetrieveModel', () {
    test('retrieve_model 200', () async {
      final op = RetrieveModel(buildDio(responseStatus: '200'));

      final result = await op(model: 'gpt-4o');

      expect(result, isA<TonikSuccess<Model>>());
      final success = result as TonikSuccess<Model>;
      expect(success.response.statusCode, 200);

      final uri = success.response.requestOptions.uri;
      expect(uri.path, '/v1/models/gpt-4o');
    });
  });

  // ── DELETE /models/{model} (DeleteModel) ─────────────────────────────

  group('DeleteModel', () {
    test('delete_model 200', () async {
      final op = DeleteModel(buildDio(responseStatus: '200'));

      final result = await op(model: 'ft:gpt-4o:org:suffix:id');

      expect(result, isA<TonikSuccess<DeleteModelResponse>>());
      final success = result as TonikSuccess<DeleteModelResponse>;
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
      final op = CreateEmbedding(buildDio(responseStatus: '200'));

      final result = await op(
        body: const CreateEmbeddingRequest(
          input: CreateEmbeddingRequestInputOneOfModelString(
            'Hello world',
          ),
          model: CreateEmbeddingRequestModelAnyOfModel(
            string: 'text-embedding-ada-002',
          ),
        ),
      );

      expect(result, isA<TonikSuccess<CreateEmbeddingResponse>>());
      final success =
          result as TonikSuccess<CreateEmbeddingResponse>;
      expect(success.response.statusCode, 200);

      final uri = success.response.requestOptions.uri;
      expect(uri.path, '/v1/embeddings');
    });
  });

  // ── POST /moderations (CreateModeration) ─────────────────────────────

  group('CreateModeration', () {
    test('create_moderation 200', () async {
      final op = CreateModeration(buildDio(responseStatus: '200'));

      final result = await op(
        body: const CreateModerationRequest(
          input: CreateModerationRequestInputOneOfModelString(
            'Test input',
          ),
        ),
      );

      expect(
        result,
        isA<TonikSuccess<CreateModerationResponse>>(),
      );
      final success =
          result as TonikSuccess<CreateModerationResponse>;
      expect(success.response.statusCode, 200);

      final uri = success.response.requestOptions.uri;
      expect(uri.path, '/v1/moderations');
    });
  });

  // ── POST /chat/completions (CreateChatCompletion) ────────────────────

  group('CreateChatCompletion', () {
    test('create_chat_completion 200 json', () async {
      final op = CreateChatCompletion(
        buildDio(responseStatus: '200'),
      );

      final result = await op(
        body: const CreateChatCompletionRequest(
          createChatCompletionRequestModel:
              CreateChatCompletionRequestModel(
            messages: [
              ChatCompletionRequestMessageChatCompletionRequestUserMessage(
                ChatCompletionRequestUserMessage(
                  content:
                      ChatCompletionRequestUserMessageContentOneOfModelString(
                    'Hello!',
                  ),
                  role:
                      ChatCompletionRequestUserMessageRoleModel
                          .user,
                ),
              ),
            ],
            model: ModelIdsShared(string: 'gpt-4o'),
          ),
          createModelResponseProperties:
              CreateModelResponseProperties(
            modelResponseProperties:
                ModelResponseProperties(),
          ),
        ),
      );

      expect(
        result,
        isA<TonikSuccess<ChatCompletionsPost200Response>>(),
      );
      final success =
          result as TonikSuccess<ChatCompletionsPost200Response>;
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
      final op = ListFiles(buildDio(responseStatus: '200'));

      final result = await op(purpose: 'fine-tune', limit: 10);

      expect(result, isA<TonikSuccess<ListFilesResponse>>());
      final success = result as TonikSuccess<ListFilesResponse>;
      expect(success.response.statusCode, 200);

      final uri = success.response.requestOptions.uri;
      expect(uri.path, '/v1/files');
      expect(uri.queryParameters['purpose'], 'fine-tune');
      expect(uri.queryParameters['limit'], '10');
    });

    test('list_files 200 no params', () async {
      final op = ListFiles(buildDio(responseStatus: '200'));

      final result = await op();

      expect(result, isA<TonikSuccess<ListFilesResponse>>());
      final success = result as TonikSuccess<ListFilesResponse>;
      expect(success.response.statusCode, 200);

      final uri = success.response.requestOptions.uri;
      expect(uri.path, '/v1/files');
      expect(uri.queryParameters, isEmpty);
    });
  });

  // ── GET /batches/{batch_id} (RetrieveBatch) ──────────────────────────

  group('RetrieveBatch', () {
    test('retrieve_batch 200', () async {
      final op = RetrieveBatch(buildDio(responseStatus: '200'));

      final result = await op(batchId: 'batch_abc123');

      expect(result, isA<TonikSuccess<Batch>>());
      final success = result as TonikSuccess<Batch>;
      expect(success.response.statusCode, 200);

      final uri = success.response.requestOptions.uri;
      expect(uri.path, '/v1/batches/batch_abc123');
    });
  });

  // ── GET /fine_tuning/jobs/{id}/events (ListFineTuningEvents) ─────────

  group('ListFineTuningEvents', () {
    test('list_fine_tuning_events 200', () async {
      final op = ListFineTuningEvents(
        buildDio(responseStatus: '200'),
      );

      final result = await op(
        fineTuningJobId: 'ftjob-abc123',
        after: 'evt-abc',
        limit: 5,
      );

      expect(
        result,
        isA<TonikSuccess<ListFineTuningJobEventsResponse>>(),
      );
      final success = result
          as TonikSuccess<ListFineTuningJobEventsResponse>;
      expect(success.response.statusCode, 200);

      final uri = success.response.requestOptions.uri;
      expect(
        uri.path,
        '/v1/fine_tuning/jobs/ftjob-abc123/events',
      );
      expect(uri.queryParameters['after'], 'evt-abc');
      expect(uri.queryParameters['limit'], '5');
    });

    test('list_fine_tuning_events 200 no query params', () async {
      final op = ListFineTuningEvents(
        buildDio(responseStatus: '200'),
      );

      final result = await op(fineTuningJobId: 'ftjob-abc123');

      expect(
        result,
        isA<TonikSuccess<ListFineTuningJobEventsResponse>>(),
      );
      final success = result
          as TonikSuccess<ListFineTuningJobEventsResponse>;
      expect(success.response.statusCode, 200);

      final uri = success.response.requestOptions.uri;
      expect(
        uri.path,
        '/v1/fine_tuning/jobs/ftjob-abc123/events',
      );
      expect(uri.queryParameters, isEmpty);
    });
  });

  // ── POST /fine_tuning/jobs/{id}/cancel (CancelFineTuningJob) ─────────

  group('CancelFineTuningJob', () {
    test('cancel_fine_tuning_job 200', () async {
      final op = CancelFineTuningJob(
        buildDio(responseStatus: '200'),
      );

      final result = await op(fineTuningJobId: 'ftjob-abc123');

      expect(result, isA<TonikSuccess<FineTuningJob>>());
      final success = result as TonikSuccess<FineTuningJob>;
      expect(success.response.statusCode, 200);

      final uri = success.response.requestOptions.uri;
      expect(
        uri.path,
        '/v1/fine_tuning/jobs/ftjob-abc123/cancel',
      );
    });
  });
}
