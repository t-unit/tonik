import 'package:big_decimal/big_decimal.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';
import 'package:query_parameters_api/query_parameters_api.dart';
import 'package:tonik_util/tonik_util.dart';

import 'test_helper.dart';

void main() {
  const port = 9091;
  const baseUrl = 'http://localhost:$port/v1';

  late ImposterServer imposterServer;

  setUpAll(() async {
    imposterServer = ImposterServer(port: port);
    await setupImposterServer(imposterServer);
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
      final response = await api.testSpaceDelimitedPrimitive(double: 1.0);

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
        $class: Class(name: 'test', age: 1),
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
        classNested: ClassNested(
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
        classAlias: ClassAlias(name: 'test', age: 1),
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
        anyOfPrimitive: AnyOfPrimitive(string: 'test'),
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
        anyOfComplex: AnyOfComplex($class: Class(name: 'test', age: 1)),
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
        oneOfPrimitive: OneOfPrimitiveString('test'),
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
        oneOfComplex: OneOfComplexClassModel(
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
        allOfPrimitive: AllOfPrimitive(string: '1', int: 1),
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
        allOfComplex: AllOfComplex(
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
        $class: Class(name: 'test', age: 1),
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
        classNested: ClassNested(
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
        classAlias: ClassAlias(name: 'test', age: 1),
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
        anyOfPrimitive: AnyOfPrimitive(string: 'test'),
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
        anyOfComplex: AnyOfComplex($class: Class(name: 'test', age: 1)),
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
        oneOfPrimitive: OneOfPrimitiveString('test'),
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
        oneOfComplex: OneOfComplexClassModel(
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
        allOfPrimitive: AllOfPrimitive(string: '1', int: 1),
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
        allOfComplex: AllOfComplex(
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
          OneOfPrimitiveString('test'),
          OneOfPrimitiveString('test2'),
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
          OneOfComplexClassModel(OneOfComplexModel(value: 'test', amount: 1)),
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
          SpaceDelimitedListParametersArrayOneOfModelClass(
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
          SpaceDelimitedListParametersArrayOneOfModelInt(3),
          SpaceDelimitedListParametersArrayOneOfModelInt(4),
          SpaceDelimitedListParametersArrayOneOfModelInt(5),
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
        listOneOfPrimitive: [OneOfPrimitiveString('test')],
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
          OneOfComplexClassModel(OneOfComplexModel(value: 'test', amount: 1)),
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
      final response = await api.testSpaceDelimitedPrimitive(
        nullableString: null,
      );

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(success.response.requestOptions.uri.query, '');
    });

    test('nullableInteger with null', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testSpaceDelimitedPrimitive(
        nullableInteger: null,
      );

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
      final response = await api.testSpaceDelimitedComplex(nullableClass: null);

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(success.response.requestOptions.uri.query, '');
    });

    test('deeplyNestedClass', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testSpaceDelimitedComplex(
        deeplyNestedClass: DeeplyNestedClass(
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
