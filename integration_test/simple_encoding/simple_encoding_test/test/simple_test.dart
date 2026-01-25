import 'package:big_decimal/big_decimal.dart';
import 'package:dio/dio.dart';
import 'package:simple_encoding_api/simple_encoding_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

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

  test('testAnyOfInPath string', () async {
    final api = buildAlbumsApi(responseStatus: '200');
    final response = await api.testAnyOfInPath(
      flexibleValue: const FlexibleValue(string: 'string'),
    );

    expect(response, isA<TonikSuccess<void>>());
    final success = response as TonikSuccess<void>;
    expect(success.response.statusCode, 200);
    expect(
      success.response.requestOptions.uri.path,
      '/v1/anyof/string',
    );
  });

  test('testAnyOfInPath integer', () async {
    final api = buildAlbumsApi(responseStatus: '200');
    final response = await api.testAnyOfInPath(
      flexibleValue: const FlexibleValue(int: 1),
    );

    expect(response, isA<TonikSuccess<void>>());
    final success = response as TonikSuccess<void>;
    expect(success.response.statusCode, 200);
    expect(
      success.response.requestOptions.uri.path,
      '/v1/anyof/1',
    );
  });

  test('testAnyOfInPath object', () async {
    final api = buildAlbumsApi(responseStatus: '200');
    final response = await api.testAnyOfInPath(
      flexibleValue: const FlexibleValue(
        simpleObject: SimpleObject(value: -1, name: 'John Doe'),
      ),
    );

    expect(response, isA<TonikSuccess<void>>());
    final success = response as TonikSuccess<void>;
    expect(success.response.statusCode, 200);
    expect(
      success.response.requestOptions.uri.path,
      '/v1/anyof/name,John%20Doe,value,-1',
    );
  });

  test('testAnyOfCompositeInPath with EntityType', () async {
    final api = buildAlbumsApi(responseStatus: '200');
    final response = await api.testAnyOfCompositeInPath(
      dynamicValue: DynamicCompositeValue(
        entityType: EntityTypePersonEntity(
          PersonEntity(
            $type: PersonEntityTypeModel.person,
            firstName: 'John',
            lastName: 'Doe',
            age: 30,
            birthDate: Date(1970, 1, 1),
          ),
        ),
      ),
    );

    expect(response, isA<TonikSuccess<void>>());
    final success = response as TonikSuccess<void>;
    expect(success.response.statusCode, 200);
    expect(
      success.response.requestOptions.uri.path,
      '/v1/anyof-composite/type,person,first_name,John,last_name,Doe,age,30,birth_date,1970-01-01',
    );
  });

  test('testAnyOfCompositeInPath with FlexibleValue string', () async {
    final api = buildAlbumsApi(responseStatus: '200');
    final response = await api.testAnyOfCompositeInPath(
      dynamicValue: const DynamicCompositeValue(
        flexibleValue: FlexibleValue(string: 'test-value'),
      ),
    );

    expect(response, isA<TonikSuccess<void>>());
    final success = response as TonikSuccess<void>;
    expect(success.response.statusCode, 200);
    expect(
      success.response.requestOptions.uri.path,
      '/v1/anyof-composite/test-value',
    );
  });

  test('testAnyOfCompositeInPath with FlexibleValue object', () async {
    final api = buildAlbumsApi(responseStatus: '200');
    final response = await api.testAnyOfCompositeInPath(
      dynamicValue: const DynamicCompositeValue(
        flexibleValue: FlexibleValue(
          simpleObject: SimpleObject(value: 42, name: 'Test Object'),
        ),
      ),
    );

    expect(response, isA<TonikSuccess<void>>());
    final success = response as TonikSuccess<void>;
    expect(success.response.statusCode, 200);
    expect(
      success.response.requestOptions.uri.path,
      '/v1/anyof-composite/name,Test%20Object,value,42',
    );
  });

  test('testAnyOfCompositeInPath with CompositeEntity', () async {
    final api = buildAlbumsApi(responseStatus: '200');
    final response = await api.testAnyOfCompositeInPath(
      dynamicValue: DynamicCompositeValue(
        compositeEntity: CompositeEntity(
          baseEntity: const BaseEntity(
            name: 'Composite Test',
            description: 'Testing composite entity',
          ),
          timestampMixin: TimestampMixin(
            createdAt: DateTime.utc(1970, 1, 1, 14, 30),
          ),
          compositeEntityModel: const CompositeEntityModel(
            specificField: 'specific-value',
          ),
        ),
      ),
    );

    expect(response, isA<TonikSuccess<void>>());
    final success = response as TonikSuccess<void>;
    expect(success.response.statusCode, 200);
    expect(
      success.response.requestOptions.uri.path,
      '/v1/anyof-composite/name,Composite%20Test,description,Testing%20composite%20entity,created_at,1970-01-01T14%3A30%3A00.000Z,specific_field,specific-value',
    );
  });

  test('testPrimitiveInPath', () async {
    final api = buildAlbumsApi(responseStatus: '200');
    final response = await api.testPrimitiveInPath(
      integer: 1,
      double: 1,
      number: 23,
      string: 'string',
      boolean: true,
      datetime: DateTime.utc(1970),
      date: Date(2000, 1, 1),
      decimal: BigDecimal.parse('23'),
      uri: Uri.parse('https://example.com'),
      $enum: StatusEnum.active,
    );

    expect(response, isA<TonikSuccess<void>>());
    final success = response as TonikSuccess<void>;
    expect(success.response.statusCode, 200);
    expect(
      success.response.requestOptions.uri.path,
      '/v1/primitive/1/1.0/23/string/true/1970-01-01T00%3A00%3A00.000Z/2000-01-01/23/https%3A%2F%2Fexample.com/active',
    );
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
        createdAt: DateTime.utc(1970, 1, 1, 14, 30),
        birthDate: Date(92000, 1, 1),
        balance: BigDecimal.parse('123.45'),
        website: Uri.parse('https://example.com'),
        email: 'john.doe@example.com',
        fullName: 'John Doe',
        age: 30,
        status: StatusEnum.active,
        priority: PriorityEnum.one,
      ),
    );

    expect(response, isA<TonikSuccess<void>>());
    final success = response as TonikSuccess<void>;
    expect(success.response.statusCode, 200);
    expect(
      success.response.requestOptions.uri.path,
      '/v1/complex/id,987,score,123.45,rating,123.45,username,john_doe,is_verified,true,created_at,1970-01-01T14%3A30%3A00.000Z,birth_date,92000-01-01,balance,123.45,website,https%3A%2F%2Fexample.com,email,john.doe%40example.com,full_name,John%20Doe,age,30,status,active,priority,1',
    );
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
          createdAt: DateTime.utc(1970, 1, 1, 14, 30),
        ),
        compositeEntityModel: const CompositeEntityModel(
          specificField: 'John Doe',
        ),
      ),
    );

    expect(response, isA<TonikSuccess<void>>());
    final success = response as TonikSuccess<void>;
    expect(success.response.statusCode, 200);
    expect(
      success.response.requestOptions.uri.path,
      '/v1/allof/name,John%20Doe,description,lalala%20lululu,created_at,1970-01-01T14%3A30%3A00.000Z,specific_field,John%20Doe',
    );
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

    expect(response, isA<TonikError<void>>());
    final error = response as TonikError<void>;
    expect(error.error, isA<EncodingException>());
  });

  test('testAliasesInPath', () async {
    final api = buildAlbumsApi(responseStatus: '200');
    final response = await api.testAliasesInPath(
      userId: 11,
      userName: 'John Doe',
      timestamp: DateTime.utc(1970, 1, 1, 14, 30),
    );

    expect(response, isA<TonikSuccess<void>>());
    final success = response as TonikSuccess<void>;
    expect(success.response.statusCode, 200);
    expect(
      success.response.requestOptions.uri.path,
      '/v1/aliases/11/John%20Doe',
    );
    expect(
      success.response.requestOptions.headers['x-timestamp'],
      '1970-01-01T14%3A30%3A00.000Z',
    );
  });
}
