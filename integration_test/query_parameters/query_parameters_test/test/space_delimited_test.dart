import 'package:big_decimal/big_decimal.dart';
import 'package:dio/dio.dart';
import 'package:query_parameters_api/query_parameters_api.dart';
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

  QueryApi buildQueryApi({required String responseStatus}) {
    return QueryApi(
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

  group('primitive', () {
    test('integer', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testSpaceDelimitedPrimitive(integer: 1);

      expect(
        response,
        isA<TonikError<void>>(),
        reason: 'only lists are supported in spaceDelimited encoding',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });

    test('double', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testSpaceDelimitedPrimitive(double: 1);

      expect(
        response,
        isA<TonikError<void>>(),
        reason: 'only lists are supported in spaceDelimited encoding',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });

    test('number', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testSpaceDelimitedPrimitive(number: 1.0);

      expect(
        response,
        isA<TonikError<void>>(),
        reason: 'only lists are supported in spaceDelimited encoding',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });

    test('string', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testSpaceDelimitedPrimitive(string: 'test');

      expect(
        response,
        isA<TonikError<void>>(),
        reason: 'only lists are supported in spaceDelimited encoding',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });

    test('boolean', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testSpaceDelimitedPrimitive(boolean: true);

      expect(
        response,
        isA<TonikError<void>>(),
        reason: 'only lists are supported in spaceDelimited encoding',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });

    test('datetime', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testSpaceDelimitedPrimitive(
        datetime: DateTime.utc(2000),
      );

      expect(
        response,
        isA<TonikError<void>>(),
        reason: 'only lists are supported in spaceDelimited encoding',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });

    test('date', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testSpaceDelimitedPrimitive(
        date: Date(2000, 6, 15),
      );

      expect(
        response,
        isA<TonikError<void>>(),
        reason: 'only lists are supported in spaceDelimited encoding',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });

    test('decimal', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testSpaceDelimitedPrimitive(
        decimal: BigDecimal.parse('1.000'),
      );

      expect(
        response,
        isA<TonikError<void>>(),
        reason: 'only lists are supported in spaceDelimited encoding',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });
  });

  group('complex', () {
    test('class', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testSpaceDelimitedComplex(
        $class: const Class(name: 'test', age: 1),
      );

      expect(
        response,
        isA<TonikError<void>>(),
        reason: 'only lists are supported in spaceDelimited encoding',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });

    test('classNested', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testSpaceDelimitedComplex(
        classNested: const ClassNested(
          name: 'test',
          age: 1,
          nested: Class(name: 'test', age: 1),
        ),
      );

      expect(
        response,
        isA<TonikError<void>>(),
        reason: 'only lists are supported in spaceDelimited encoding',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });

    test('enum', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testSpaceDelimitedComplex($enum: Enum.value1);

      expect(
        response,
        isA<TonikError<void>>(),
        reason: 'only lists are supported in spaceDelimited encoding',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });

    test('classAlias', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testSpaceDelimitedComplex(
        classAlias: const ClassAlias(name: 'test', age: 1),
      );

      expect(
        response,
        isA<TonikError<void>>(),
        reason: 'only lists are supported in spaceDelimited encoding',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });

    test('anyOfPrimitive', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testSpaceDelimitedComplex(
        anyOfPrimitive: const AnyOfPrimitive(string: 'test'),
      );

      expect(
        response,
        isA<TonikError<void>>(),
        reason: 'only lists are supported in spaceDelimited encoding',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });

    test('anyOfComplex', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testSpaceDelimitedComplex(
        anyOfComplex: const AnyOfComplex($class: Class(name: 'test', age: 1)),
      );

      expect(
        response,
        isA<TonikError<void>>(),
        reason: 'only lists are supported in spaceDelimited encoding',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });

    test('oneOfPrimitive', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testSpaceDelimitedComplex(
        oneOfPrimitive: const OneOfPrimitiveString('test'),
      );

      expect(
        response,
        isA<TonikError<void>>(),
        reason: 'only lists are supported in spaceDelimited encoding',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });

    test('oneOfComplex', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testSpaceDelimitedComplex(
        oneOfComplex: const OneOfComplexClassModel(
          OneOfComplexModel(value: 'test', amount: 1),
        ),
      );

      expect(
        response,
        isA<TonikError<void>>(),
        reason: 'only lists are supported in spaceDelimited encoding',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });

    test('allOfPrimitive', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testSpaceDelimitedComplex(
        allOfPrimitive: const AllOfPrimitive(string: '1', int: 1),
      );

      expect(
        response,
        isA<TonikError<void>>(),
        reason: 'only lists are supported in spaceDelimited encoding',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });

    test('allOfComplex', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testSpaceDelimitedComplex(
        allOfComplex: const AllOfComplex(
          $class: Class(name: 'test', age: 1),
          allOfComplexModel: AllOfComplexModel(value: 'test', amount: 1),
        ),
      );

      expect(
        response,
        isA<TonikError<void>>(),
        reason: 'only lists are supported in spaceDelimited encoding',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });
  });

  group('complex - explode true', () {
    test('class', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testSpaceDelimitedComplexExplode(
        $class: const Class(name: 'test', age: 1),
      );

      expect(
        response,
        isA<TonikError<void>>(),
        reason: 'only lists are supported in spaceDelimited encoding',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });

    test('classNested', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testSpaceDelimitedComplexExplode(
        classNested: const ClassNested(
          name: 'test',
          age: 1,
          nested: Class(name: 'test', age: 1),
        ),
      );

      expect(
        response,
        isA<TonikError<void>>(),
        reason: 'only lists are supported in spaceDelimited encoding',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });

    test('enum', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testSpaceDelimitedComplexExplode(
        $enum: Enum.value1,
      );

      expect(
        response,
        isA<TonikError<void>>(),
        reason: 'only lists are supported in spaceDelimited encoding',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });

    test('classAlias', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testSpaceDelimitedComplexExplode(
        classAlias: const ClassAlias(name: 'test', age: 1),
      );

      expect(
        response,
        isA<TonikError<void>>(),
        reason: 'only lists are supported in spaceDelimited encoding',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });

    test('anyOfPrimitive', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testSpaceDelimitedComplexExplode(
        anyOfPrimitive: const AnyOfPrimitive(string: 'test'),
      );

      expect(
        response,
        isA<TonikError<void>>(),
        reason: 'only lists are supported in spaceDelimited encoding',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });

    test('anyOfComplex', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testSpaceDelimitedComplexExplode(
        anyOfComplex: const AnyOfComplex($class: Class(name: 'test', age: 1)),
      );

      expect(
        response,
        isA<TonikError<void>>(),
        reason: 'only lists are supported in spaceDelimited encoding',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });

    test('oneOfPrimitive', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testSpaceDelimitedComplexExplode(
        oneOfPrimitive: const OneOfPrimitiveString('test'),
      );

      expect(
        response,
        isA<TonikError<void>>(),
        reason: 'only lists are supported in spaceDelimited encoding',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });

    test('oneOfComplex', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testSpaceDelimitedComplexExplode(
        oneOfComplex: const OneOfComplexClassModel(
          OneOfComplexModel(value: 'test', amount: 1),
        ),
      );

      expect(
        response,
        isA<TonikError<void>>(),
        reason: 'only lists are supported in spaceDelimited encoding',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });

    test('allOfPrimitive', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testSpaceDelimitedComplexExplode(
        allOfPrimitive: const AllOfPrimitive(string: '1', int: 1),
      );

      expect(
        response,
        isA<TonikError<void>>(),
        reason: 'only lists are supported in spaceDelimited encoding',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });

    test('allOfComplex', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testSpaceDelimitedComplexExplode(
        allOfComplex: const AllOfComplex(
          $class: Class(name: 'test', age: 1),
          allOfComplexModel: AllOfComplexModel(value: 'test', amount: 1),
        ),
      );

      expect(
        response,
        isA<TonikError<void>>(),
        reason: 'only lists are supported in spaceDelimited encoding',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });
  });

  group('list', () {
    test('string', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testSpaceDelimitedList(
        listString: ['test', 'test2', 'white space', 'special&&chars'],
      );
      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(
        success.response.requestOptions.uri.query,
        'listString=test%20test2%20white%20space%20special%26%26chars',
      );
    });

    test('oneOfPrimitive', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testSpaceDelimitedList(
        listOneOfPrimitive: [
          const OneOfPrimitiveString('test'),
          const OneOfPrimitiveString('test2'),
        ],
      );
      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(
        success.response.requestOptions.uri.query,
        'listOneOfPrimitive=test%20test2',
      );
    });

    test('listOneOfComplex', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testSpaceDelimitedList(
        listOneOfComplex: [
          const OneOfComplexClassModel(
            OneOfComplexModel(value: 'test', amount: 1),
          ),
        ],
      );
      expect(response, isA<TonikError<void>>());
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });

    test('listOneOfComplexMixed - complex', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testSpaceDelimitedList(
        listOneOfComplexMixed: [
          const SpaceDelimitedListParametersArrayOneOfModelClass(
            Class(name: 'test', age: 1),
          ),
        ],
      );
      expect(response, isA<TonikError<void>>());
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });

    test('listOneOfComplexMixed - simple', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testSpaceDelimitedList(
        listOneOfComplexMixed: [
          const SpaceDelimitedListParametersArrayOneOfModelInt(3),
          const SpaceDelimitedListParametersArrayOneOfModelInt(4),
          const SpaceDelimitedListParametersArrayOneOfModelInt(5),
        ],
      );
      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(
        success.response.requestOptions.uri.query,
        'listOneOfComplexMixed=3%204%205',
      );
    });
  });

  group('list - explode true', () {
    test('string', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testSpaceDelimitedListExplode(
        listString: ['test', 'test2'],
      );
      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(
        success.response.requestOptions.uri.query,
        'listString=test&listString=test2',
      );
    });

    test('oneOfPrimitive', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testSpaceDelimitedListExplode(
        listOneOfPrimitive: [const OneOfPrimitiveString('test')],
      );
      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(
        success.response.requestOptions.uri.query,
        'listOneOfPrimitive=test',
      );
    });

    test('listOneOfComplex', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testSpaceDelimitedListExplode(
        listOneOfComplex: [
          const OneOfComplexClassModel(
            OneOfComplexModel(value: 'test', amount: 1),
          ),
        ],
      );
      expect(response, isA<TonikError<void>>());
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });
  });

  group('primitive - new types', () {
    test('uri', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testSpaceDelimitedPrimitive(
        uri: Uri.parse('https://example.com'),
      );

      expect(
        response,
        isA<TonikError<void>>(),
        reason: 'only lists are supported in spaceDelimited encoding',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });

    test('integerEnum', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testSpaceDelimitedPrimitive(
        integerEnum: PriorityEnum.two,
      );

      expect(
        response,
        isA<TonikError<void>>(),
        reason: 'only lists are supported in spaceDelimited encoding',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });

    test('nullableString with value', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testSpaceDelimitedPrimitive(
        nullableString: 'test',
      );

      expect(
        response,
        isA<TonikError<void>>(),
        reason: 'only lists are supported in spaceDelimited encoding',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });

    test('nullableString with null', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testSpaceDelimitedPrimitive();

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(success.response.requestOptions.uri.query, '');
    });

    test('nullableInteger with null', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testSpaceDelimitedPrimitive();

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(success.response.requestOptions.uri.query, '');
    });
  });

  group('complex - new types', () {
    test('integerEnum', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testSpaceDelimitedComplex(
        integerEnum: PriorityEnum.one,
      );

      expect(
        response,
        isA<TonikError<void>>(),
        reason: 'only lists are supported in spaceDelimited encoding',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });

    test('nullableClass with null', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testSpaceDelimitedComplex();

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(success.response.requestOptions.uri.query, '');
    });

    test('deeplyNestedClass', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testSpaceDelimitedComplex(
        deeplyNestedClass: const DeeplyNestedClass(
          name: 'outer',
          nested: ClassNested(
            name: 'middle',
            age: 1,
            nested: Class(name: 'inner', age: 2),
          ),
        ),
      );

      expect(
        response,
        isA<TonikError<void>>(),
        reason: 'only lists are supported in spaceDelimited encoding',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });
  });
}
