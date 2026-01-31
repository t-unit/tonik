import 'package:dio/dio.dart';
import 'package:fastify_type_provider_zod_api/fastify_type_provider_zod_api.dart';
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

  DefaultApi buildAlbumsApi({required String responseStatus}) {
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

  test('exampleExamplePost exampleDtoInputDeletedAtAnyOf', () async {
    final api = buildAlbumsApi(responseStatus: '200');
    final response = await api.exampleExamplePost(
      body: const ExampleDtoInput(
        email: 'john.doe@example.com',
        password: 'password',
        deletedAt: ExampleDtoInputDeletedAtAnyOfModel(),
      ),
    );

    expect(response, isA<TonikSuccess<ExampleDto>>());
    final success = response as TonikSuccess<ExampleDto>;
    expect(success.response.statusCode, 200);

    final data = success.value;
    expect(data.email, isA<String>());
    expect(data.password, isA<String>());
    expect(data.deletedAt, isA<ExampleDtoDeletedAtAnyOfModel>());
    expect(data.deletedAt.dateTime, isA<DateTime>());
  });

  test('exampleExamplePost exampleDtoInputDeletedAtAnyOfModel', () async {
    final api = buildAlbumsApi(responseStatus: '200');
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

    expect(response, isA<TonikSuccess<ExampleDto>>());
    final success = response as TonikSuccess<ExampleDto>;
    expect(success.response.statusCode, 200);

    final data = success.value;
    expect(data.email, isA<String>());
    expect(data.password, isA<String>());
    expect(data.deletedAt, isA<ExampleDtoDeletedAtAnyOfModel>());
    expect(data.deletedAt.dateTime, isA<DateTime>());
  });
}
