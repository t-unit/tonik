import 'package:big_decimal/big_decimal.dart';
import 'package:dio/dio.dart';
import 'package:simple_encoding_api/simple_encoding_api.dart';
import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

import 'test_helper.dart';

void main() {
  const port = 8085;
  const baseUrl = 'http://localhost:$port/v1';

  late ImposterServer imposterServer;

  setUpAll(() async {
    imposterServer = ImposterServer(port: port);
    await setupImposterServer(imposterServer);
  });

  SimpleEncodingApi buildAlbumsApi({required String responseStatus}) {
    return SimpleEncodingApi(
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

  test('testPrimitiveInPath', () async {
    final api = buildAlbumsApi(responseStatus: '200');
    final response = await api.testPrimitiveInPath(
      integer: 1,
      double: 1,
      number: 23,
      string: 'string',
      boolean: true,
      datetime: DateTime(1970),
      date: Date(2000, 1, 1),
      decimal: BigDecimal.parse('23'),
      uri: Uri.parse('https://example.com'),
      $enum: StatusEnum.active,
    );

    expect(response, isA<TonikSuccess<void>>());
    final success = response as TonikSuccess<void>;
    expect(success.response.statusCode, 200);
  });

  test('testHeaders', () async {
    final api = buildAlbumsApi(responseStatus: '200');
    final response = await api.testHeaders(
      integer: 1,
      double: 1,
      number: 23,
      string: 'string',
      boolean: true,
      dateTime: DateTime(1970),
      date: Date(2000, 1, 1),
      decimal: BigDecimal.parse('23'),
      uri: Uri.parse('https://example.com'),
      status: StatusEnum.active,
      tags: ['a', 'b', 'c'],
    );

    expect(response, isA<TonikSuccess<void>>());
    final success = response as TonikSuccess<void>;
    expect(success.response.statusCode, 200);
  });

  test('testComplexInPath', () async {
    final api = buildAlbumsApi(responseStatus: '200');
    final response = await api.testComplexInPath(
      userProfile: UserProfile(
        id: 987,
        score: 123.45,
        rating: 123.45,
        username: 'john_doe',
        isVerified: true,
        createdAt: DateTime(1970, 1, 1, 14, 30),
        birthDate: Date(92000, 1, 1),
        balance: BigDecimal.parse('123.45'),
        website: Uri.parse('https://example.com'),
        email: 'john.doe@example.com',
        fullName: 'John Doe',
        age: 30,
        status: StatusEnum.active,
        priority: PriorityEnum.one,
        tags: const ['a', 'b', 'c'],
        scores: const [123.45, 123.45, 123.45],
        dates: [Date(1970, 1, 1), Date(1970, 1, 1), Date(1970, 1, 1)],
        statuses: const [
          StatusEnum.active,
          StatusEnum.active,
          StatusEnum.active,
        ],
      ),
    );

    expect(response, isA<TonikSuccess<void>>());
    final success = response as TonikSuccess<void>;
    expect(success.response.statusCode, 200);
  });

  test('testAllOfInPath', () async {
    final api = buildAlbumsApi(responseStatus: '200');
    final response = await api.testAllOfInPath(
      entity: CompositeEntity(
        baseEntity: const BaseEntity(
          name: 'John Doe',
          description: 'lalala lululu',
        ),
        timestampMixin: TimestampMixin(
          createdAt: DateTime(1970, 1, 1, 14, 30),
        ),
        compositeEntityModel: const CompositeEntityModel(
          specificField: 'John Doe',
        ),
      ),
    );

    expect(response, isA<TonikSuccess<void>>());
    final success = response as TonikSuccess<void>;
    expect(success.response.statusCode, 200);
  });

  test('testOneOfInHeader Person', () async {
    final api = buildAlbumsApi(responseStatus: '200');
    final response = await api.testOneOfInHeader(
      entity: EntityTypePerson(
        PersonEntity(
          $type: PersonEntityType.person,
          firstName: 'John',
          lastName: 'Doe',
          age: 30,
          birthDate: Date(1970, 1, 1),
        ),
      ),
    );

    expect(response, isA<TonikSuccess<void>>());
    final success = response as TonikSuccess<void>;
    expect(success.response.statusCode, 200);
  });

  test('testOneOfInHeader Company', () async {
    final api = buildAlbumsApi(responseStatus: '200');
    final response = await api.testOneOfInHeader(
      entity: const EntityTypeCompany(
        CompanyEntity(
          $type: CompanyEntityType.company,
          companyName: 'Capyboi GmbH',
        ),
      ),
    );

    expect(response, isA<TonikSuccess<void>>());
    final success = response as TonikSuccess<void>;
    expect(success.response.statusCode, 200);
  });

  test('testOneOfInHeader System', () async {
    final api = buildAlbumsApi(responseStatus: '200');
    final response = await api.testOneOfInHeader(
      entity: const EntityTypeSystem(
        SystemEntity(
          $type: SystemEntityType.system,
          systemId: '1',
          version: '1.0.0',
          active: true,
          config: SystemEntityConfig(
            timeout: 1000,
            retries: -1,
          ),
        ),
      ),
    );

    // Simple encoding does not support nested objects.
    // We are expecting an error for this test.
    expect(response, isA<TonikError<void>>());
    final error = response as TonikError<void>;
    expect(error.error, isA<UnsupportedEncodingTypeException>());
  });

  test('testListInPath', () async {
    final api = buildAlbumsApi(responseStatus: '200');
    final response = await api.testListInPath(
      stringList: ['a', 'b', 'c'],
      numbers: [1, 2, 3],
      objects: [
        const SimpleObject(value: 1, name: 'John Doe'),
        const SimpleObject(value: 2, name: 'Jane Doe'),
        const SimpleObject(value: 3, name: 'Jim Doe'),
      ],
    );

    // Simple encoding does not support objects in lists.
    // We are expecting an error for this test.
    expect(response, isA<TonikError<void>>());
    final error = response as TonikError<void>;
    expect(error.error, isA<EncodingException>());
  });

  test('testAliasesInPath', () async {
    final api = buildAlbumsApi(responseStatus: '200');
    final response = await api.testAliasesInPath(
      userId: 11,
      userName: 'John Doe',
      timestamp: DateTime(1970, 1, 1, 14, 30),
    );

    expect(response, isA<TonikSuccess<void>>());
    final success = response as TonikSuccess<void>;
    expect(success.response.statusCode, 200);
  });
}
