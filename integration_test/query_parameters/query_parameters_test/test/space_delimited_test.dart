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
        reason: 'parameter cannot be spaceDelimited-encoded',
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
        reason: 'parameter cannot be spaceDelimited-encoded',
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
        reason: 'parameter cannot be spaceDelimited-encoded',
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
        reason: 'parameter cannot be spaceDelimited-encoded',
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
        reason: 'parameter cannot be spaceDelimited-encoded',
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
        reason: 'parameter cannot be spaceDelimited-encoded',
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
        reason: 'parameter cannot be spaceDelimited-encoded',
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
        reason: 'parameter cannot be spaceDelimited-encoded',
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

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(
        success.response.requestOptions.uri.query,
        'class=name%20test%20age%201',
      );
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
        reason: 'nested objects have no flat parameter representation',
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
        reason: 'parameter cannot be spaceDelimited-encoded',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });

    test('classAlias', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testSpaceDelimitedComplex(
        classAlias: const ClassAlias(name: 'test', age: 1),
      );

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(
        success.response.requestOptions.uri.query,
        'classAlias=name%20test%20age%201',
      );
    });

    test('anyOfPrimitive', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testSpaceDelimitedComplex(
        anyOfPrimitive: const AnyOfPrimitive(string: 'test'),
      );

      expect(
        response,
        isA<TonikError<void>>(),
        reason: 'parameter cannot be spaceDelimited-encoded',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });

    test('anyOfComplex', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testSpaceDelimitedComplex(
        anyOfComplex: const AnyOfComplex($class: Class(name: 'test', age: 1)),
      );

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(
        success.response.requestOptions.uri.query,
        'anyOfComplex=name%20test%20age%201',
      );
    });

    test('oneOfPrimitive', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testSpaceDelimitedComplex(
        oneOfPrimitive: const OneOfPrimitiveString('test'),
      );

      expect(
        response,
        isA<TonikError<void>>(),
        reason: 'parameter cannot be spaceDelimited-encoded',
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

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(
        success.response.requestOptions.uri.query,
        'oneOfComplex=value%20test%20amount%201',
      );
    });

    test('allOfPrimitive', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testSpaceDelimitedComplex(
        allOfPrimitive: const AllOfPrimitive(string: '1', int: 1),
      );

      expect(
        response,
        isA<TonikError<void>>(),
        reason: 'parameter cannot be spaceDelimited-encoded',
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

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(
        success.response.requestOptions.uri.query,
        'allOfComplex=name%20test%20age%201%20value%20test%20amount%201',
      );
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
        reason: 'parameter cannot be spaceDelimited-encoded',
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
        reason: 'parameter cannot be spaceDelimited-encoded',
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
        reason: 'parameter cannot be spaceDelimited-encoded',
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
        reason: 'parameter cannot be spaceDelimited-encoded',
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
        reason: 'parameter cannot be spaceDelimited-encoded',
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
        reason: 'parameter cannot be spaceDelimited-encoded',
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
        reason: 'parameter cannot be spaceDelimited-encoded',
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
        reason: 'parameter cannot be spaceDelimited-encoded',
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
        reason: 'parameter cannot be spaceDelimited-encoded',
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
        reason: 'parameter cannot be spaceDelimited-encoded',
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

    test('nullableString percent-encodes elements and empties null', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testSpaceDelimitedList(
        listNullableString: ['a b/c', null, 'd'],
      );
      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(
        success.response.requestOptions.uri.query,
        'listNullableString=a%20b%2Fc%20%20d',
      );
    });

    test('oneOfPrimitive', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testSpaceDelimitedList(
        listOneOfPrimitive: [
          const OneOfPrimitiveString('white space'),
          const OneOfPrimitiveString('test2'),
        ],
      );
      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(
        success.response.requestOptions.uri.query,
        'listOneOfPrimitive=white%20space%20test2',
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

    test('enum', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testSpaceDelimitedList(
        listEnum: [
          SpaceDelimitedListParametersArrayModel.highPriority,
          SpaceDelimitedListParametersArrayModel.urgent,
          SpaceDelimitedListParametersArrayModel.lowPriority,
        ],
      );
      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(
        success.response.requestOptions.uri.query,
        'listEnum=high%20priority%20urgent%20low%20priority',
      );
    });

    test('empty array is dropped from the query', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testSpaceDelimitedList(
        listString: const [],
      );
      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(success.response.requestOptions.uri.query, '');
    });

    test('empty array is dropped while a populated param remains', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testSpaceDelimitedList(
        listString: const [],
        listOneOfPrimitive: [const OneOfPrimitiveString('test')],
      );
      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(
        success.response.requestOptions.uri.query,
        'listOneOfPrimitive=test',
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
        listOneOfPrimitive: [const OneOfPrimitiveString('white space')],
      );
      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(
        success.response.requestOptions.uri.query,
        'listOneOfPrimitive=white%20space',
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

    test('enum', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testSpaceDelimitedListExplode(
        listEnum: [
          SpaceDelimitedListExplodeParametersArrayModel.highPriority,
          SpaceDelimitedListExplodeParametersArrayModel.urgent,
          SpaceDelimitedListExplodeParametersArrayModel.lowPriority,
        ],
      );
      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(
        success.response.requestOptions.uri.query,
        'listEnum=high%20priority&listEnum=urgent&listEnum=low%20priority',
      );
    });

    test('empty array drops the whole query', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testSpaceDelimitedListExplode(
        listString: const [],
      );
      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(success.response.requestOptions.uri.query, '');
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
        reason: 'parameter cannot be spaceDelimited-encoded',
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
        reason: 'parameter cannot be spaceDelimited-encoded',
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
        reason: 'parameter cannot be spaceDelimited-encoded',
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
        reason: 'parameter cannot be spaceDelimited-encoded',
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
        reason: 'parameter cannot be spaceDelimited-encoded',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });
  });

  group('complex - object shapes', () {
    test('free-form map flattens key/value pairs', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testSpaceDelimitedComplex(
        freeFormMap: const {'k1': 'v1', 'k2': 'v2'},
      );

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(
        success.response.requestOptions.uri.query,
        'freeFormMap=k1%20v1%20k2%20v2',
      );
    });

    test('any holding a map flattens key/value pairs', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testSpaceDelimitedComplex(
        anyValue: const <String, String>{'a': '1', 'b': '2'},
      );

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(
        success.response.requestOptions.uri.query,
        'anyValue=a%201%20b%202',
      );
    });

    test('any holding a list joins elements', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testSpaceDelimitedComplex(
        anyValue: const ['blue', 'black', 'brown'],
      );

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(
        success.response.requestOptions.uri.query,
        'anyValue=blue%20black%20brown',
      );
    });

    test('any holding a dynamic map flattens numeric values', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testSpaceDelimitedComplex(
        anyValue: const <String, dynamic>{'R': 100, 'G': 200, 'B': 150},
      );

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(
        success.response.requestOptions.uri.query,
        'anyValue=R%20100%20G%20200%20B%20150',
      );
    });

    test('alias to array encodes identically to an inline array', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testSpaceDelimitedComplex(
        aliasList: const ['a', 'b', 'c'],
      );

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(
        success.response.requestOptions.uri.query,
        'aliasList=a%20b%20c',
      );
    });

    test('mixed composite object variant flattens', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testSpaceDelimitedComplex(
        mixedComposite: const StringOrClassClass(Class(name: 'test', age: 1)),
      );

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(
        success.response.requestOptions.uri.query,
        'mixedComposite=name%20test%20age%201',
      );
    });

    test('mixed composite string variant has no object encoding', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testSpaceDelimitedComplex(
        mixedComposite: const StringOrClassString('hello'),
      );

      expect(response, isA<TonikError<void>>());
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });
  });
}
