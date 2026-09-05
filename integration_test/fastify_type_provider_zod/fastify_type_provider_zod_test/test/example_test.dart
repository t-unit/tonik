import 'package:fastify_type_provider_zod_api/fastify_type_provider_zod_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';

void main() {
  late ImposterServer imposterServer;
  late String baseUrl;

  setUpAll(() async {
    imposterServer = await setupImposterServer();
    baseUrl = 'http://localhost:${imposterServer.port}';
  });

  ExampleApi buildExampleApi({required String responseStatus}) {
    return ExampleApi(
      CustomServer(
        baseUrl: baseUrl,
        serverConfig: testServerConfig(
          headers: {'X-Response-Status': responseStatus},
        ),
      ),
    );
  }

  test('exampleExamplePost exampleDtoInputDeletedAtAnyOf', () async {
    final api = buildExampleApi(responseStatus: '200');
    final response = await api.exampleExamplePost(
      body: const ExampleDtoInput(
        email: 'john.doe@example.com',
        password: 'password',
        deletedAt: ExampleDtoInputDeletedAtAnyOfModel(),
      ),
    );

    expect(response, isTonikSuccess);
    final success = requireSuccess(response);
    expect(success.response.statusCode, 200);

    final data = success.value;
    expect(data.email, isA<String>());
    expect(data.password, isA<String>());
    expect(data.deletedAt, isA<ExampleDtoDeletedAtAnyOfModel>());
    expect(data.deletedAt.dateTime, isA<DateTime>());
  });

  test('exampleExamplePost exampleDtoInputDeletedAtAnyOfModel', () async {
    final api = buildExampleApi(responseStatus: '200');
    final response = await api.exampleExamplePost(
      body: const ExampleDtoInput(
        email: 'john.doe@example.com',
        password: 'password',
        deletedAt: ExampleDtoInputDeletedAtAnyOfModel(
          exampleDtoInputDeletedAtAnyOfModel2:
              ExampleDtoInputDeletedAtAnyOfModel2(),
        ),
      ),
    );

    expect(response, isTonikSuccess);
    final success = requireSuccess(response);
    expect(success.response.statusCode, 200);

    final data = success.value;
    expect(data.email, isA<String>());
    expect(data.password, isA<String>());
    expect(data.deletedAt, isA<ExampleDtoDeletedAtAnyOfModel>());
    expect(data.deletedAt.dateTime, isA<DateTime>());
  });
}
