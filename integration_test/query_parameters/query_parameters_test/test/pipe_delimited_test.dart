import 'package:big_decimal/big_decimal.dart';
import 'package:dio/dio.dart';
import 'package:query_parameters_api/query_parameters_api.dart';
import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

import 'test_helper.dart';

void main() {
  const port = 9092;
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
      final response = await api.testPipeDelimitedPrimitive(integer: 1);

      expect(
        response,
        isA<TonikError<void>>(),
        reason: 'only lists are supported in pipeDelimited encoding',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });

    test('double', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testPipeDelimitedPrimitive(double: 1);

      expect(
        response,
        isA<TonikError<void>>(),
        reason: 'only lists are supported in pipeDelimited encoding',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });

    test('number', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testPipeDelimitedPrimitive(number: 1.0);

      expect(
        response,
        isA<TonikError<void>>(),
        reason: 'only lists are supported in pipeDelimited encoding',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });

    test('string', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testPipeDelimitedPrimitive(string: 'test');

      expect(
        response,
        isA<TonikError<void>>(),
        reason: 'only lists are supported in pipeDelimited encoding',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });

    test('boolean', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testPipeDelimitedPrimitive(boolean: true);

      expect(
        response,
        isA<TonikError<void>>(),
        reason: 'only lists are supported in pipeDelimited encoding',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });

    test('datetime', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testPipeDelimitedPrimitive(
        datetime: DateTime.utc(2000),
      );

      expect(
        response,
        isA<TonikError<void>>(),
        reason: 'only lists are supported in pipeDelimited encoding',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });

    test('date', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testPipeDelimitedPrimitive(
        date: Date(2000, 6, 15),
      );

      expect(
        response,
        isA<TonikError<void>>(),
        reason: 'only lists are supported in pipeDelimited encoding',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });

    test('decimal', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testPipeDelimitedPrimitive(
        decimal: BigDecimal.parse('1.000'),
      );

      expect(
        response,
        isA<TonikError<void>>(),
        reason: 'only lists are supported in pipeDelimited encoding',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });
  });

  group('complex', () {
    test('class', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testPipeDelimitedComplex(
        $class: const Class(name: 'test', age: 1),
      );

      expect(
        response,
        isA<TonikError<void>>(),
        reason: 'only lists are supported in pipeDelimited encoding',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });

    test('classNested', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testPipeDelimitedComplex(
        classNested: const ClassNested(
          name: 'test',
          age: 1,
          nested: Class(name: 'test', age: 1),
        ),
      );

      expect(
        response,
        isA<TonikError<void>>(),
        reason: 'only lists are supported in pipeDelimited encoding',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });

    test('enum', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testPipeDelimitedComplex($enum: Enum.value1);

      expect(
        response,
        isA<TonikError<void>>(),
        reason: 'only lists are supported in pipeDelimited encoding',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });

    test('classAlias', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testPipeDelimitedComplex(
        classAlias: const ClassAlias(name: 'test', age: 1),
      );

      expect(
        response,
        isA<TonikError<void>>(),
        reason: 'only lists are supported in pipeDelimited encoding',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });

    test('anyOfPrimitive', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testPipeDelimitedComplex(
        anyOfPrimitive: const AnyOfPrimitive(string: 'test'),
      );

      expect(
        response,
        isA<TonikError<void>>(),
        reason: 'only lists are supported in pipeDelimited encoding',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });

    test('anyOfComplex', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testPipeDelimitedComplex(
        anyOfComplex: const AnyOfComplex($class: Class(name: 'test', age: 1)),
      );

      expect(
        response,
        isA<TonikError<void>>(),
        reason: 'only lists are supported in pipeDelimited encoding',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });

    test('oneOfPrimitive', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testPipeDelimitedComplex(
        oneOfPrimitive: const OneOfPrimitiveString('test'),
      );

      expect(
        response,
        isA<TonikError<void>>(),
        reason: 'only lists are supported in pipeDelimited encoding',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });

    test('oneOfComplex', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testPipeDelimitedComplex(
        oneOfComplex: const OneOfComplexClassModel(
          OneOfComplexModel(value: 'test', amount: 1),
        ),
      );

      expect(
        response,
        isA<TonikError<void>>(),
        reason: 'only lists are supported in pipeDelimited encoding',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });

    test('allOfPrimitive', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testPipeDelimitedComplex(
        allOfPrimitive: const AllOfPrimitive(string: '1', int: 1),
      );

      expect(
        response,
        isA<TonikError<void>>(),
        reason: 'only lists are supported in pipeDelimited encoding',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });

    test('allOfComplex', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testPipeDelimitedComplex(
        allOfComplex: const AllOfComplex(
          $class: Class(name: 'test', age: 1),
          allOfComplexModel: AllOfComplexModel(value: 'test', amount: 1),
        ),
      );

      expect(
        response,
        isA<TonikError<void>>(),
        reason: 'only lists are supported in pipeDelimited encoding',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });
  });

  group('complex - explode true', () {
    test('class', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testPipeDelimitedComplexExplode(
        $class: const Class(name: 'test', age: 1),
      );

      expect(
        response,
        isA<TonikError<void>>(),
        reason: 'only lists are supported in pipeDelimited encoding',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });

    test('classNested', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testPipeDelimitedComplexExplode(
        classNested: const ClassNested(
          name: 'test',
          age: 1,
          nested: Class(name: 'test', age: 1),
        ),
      );

      expect(
        response,
        isA<TonikError<void>>(),
        reason: 'only lists are supported in pipeDelimited encoding',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });

    test('enum', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testPipeDelimitedComplexExplode(
        $enum: Enum.value1,
      );

      expect(
        response,
        isA<TonikError<void>>(),
        reason: 'only lists are supported in pipeDelimited encoding',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });

    test('classAlias', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testPipeDelimitedComplexExplode(
        classAlias: const ClassAlias(name: 'test', age: 1),
      );

      expect(
        response,
        isA<TonikError<void>>(),
        reason: 'only lists are supported in pipeDelimited encoding',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });

    test('anyOfPrimitive', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testPipeDelimitedComplexExplode(
        anyOfPrimitive: const AnyOfPrimitive(string: 'test'),
      );

      expect(
        response,
        isA<TonikError<void>>(),
        reason: 'only lists are supported in pipeDelimited encoding',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });

    test('anyOfComplex', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testPipeDelimitedComplexExplode(
        anyOfComplex: const AnyOfComplex($class: Class(name: 'test', age: 1)),
      );

      expect(
        response,
        isA<TonikError<void>>(),
        reason: 'only lists are supported in pipeDelimited encoding',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });

    test('oneOfPrimitive', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testPipeDelimitedComplexExplode(
        oneOfPrimitive: const OneOfPrimitiveString('test'),
      );

      expect(
        response,
        isA<TonikError<void>>(),
        reason: 'only lists are supported in pipeDelimited encoding',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });

    test('oneOfComplex', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testPipeDelimitedComplexExplode(
        oneOfComplex: const OneOfComplexClassModel(
          OneOfComplexModel(value: 'test', amount: 1),
        ),
      );

      expect(
        response,
        isA<TonikError<void>>(),
        reason: 'only lists are supported in pipeDelimited encoding',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });

    test('allOfPrimitive', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testPipeDelimitedComplexExplode(
        allOfPrimitive: const AllOfPrimitive(string: '1', int: 1),
      );

      expect(
        response,
        isA<TonikError<void>>(),
        reason: 'only lists are supported in pipeDelimited encoding',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });

    test('allOfComplex', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testPipeDelimitedComplexExplode(
        allOfComplex: const AllOfComplex(
          $class: Class(name: 'test', age: 1),
          allOfComplexModel: AllOfComplexModel(value: 'test', amount: 1),
        ),
      );

      expect(
        response,
        isA<TonikError<void>>(),
        reason: 'only lists are supported in pipeDelimited encoding',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });
  });

  group('list', () {
    test('string', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testPipeDelimitedList(
        listString: ['test', 'test2', 'white pipe', 'special&&chars'],
      );
      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(
        success.response.requestOptions.uri.query,
        'listString=test%7Ctest2%7Cwhite%20pipe%7Cspecial%26%26chars',
      );
    });

    test('oneOfPrimitive', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testPipeDelimitedList(
        listOneOfPrimitive: [
          const OneOfPrimitiveString('test'),
          const OneOfPrimitiveString('test2'),
        ],
      );
      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(
        success.response.requestOptions.uri.query,
        'listOneOfPrimitive=test%7Ctest2',
      );
    });

    test('listOneOfComplex', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testPipeDelimitedList(
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
      final response = await api.testPipeDelimitedList(
        listOneOfComplexMixed: [
          const PipeDelimitedListParametersArrayOneOfModelClass(
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
      final response = await api.testPipeDelimitedList(
        listOneOfComplexMixed: [
          const PipeDelimitedListParametersArrayOneOfModelInt(3),
          const PipeDelimitedListParametersArrayOneOfModelInt(4),
          const PipeDelimitedListParametersArrayOneOfModelInt(5),
        ],
      );
      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(
        success.response.requestOptions.uri.query,
        'listOneOfComplexMixed=3%7C4%7C5',
      );
    });
  });

  group('list - explode true', () {
    test('string', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testPipeDelimitedListExplode(
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
      final response = await api.testPipeDelimitedListExplode(
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
      final response = await api.testPipeDelimitedListExplode(
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
      final response = await api.testPipeDelimitedPrimitive(
        uri: Uri.parse('https://example.com'),
      );

      expect(
        response,
        isA<TonikError<void>>(),
        reason: 'only lists are supported in pipeDelimited encoding',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });

    test('integerEnum', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testPipeDelimitedPrimitive(
        integerEnum: PriorityEnum.two,
      );

      expect(
        response,
        isA<TonikError<void>>(),
        reason: 'only lists are supported in pipeDelimited encoding',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });

    test('nullableString with value', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testPipeDelimitedPrimitive(
        nullableString: 'test',
      );

      expect(
        response,
        isA<TonikError<void>>(),
        reason: 'only lists are supported in pipeDelimited encoding',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });

    test('nullableString with null', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testPipeDelimitedPrimitive();

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(success.response.requestOptions.uri.query, '');
    });

    test('nullableInteger with null', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testPipeDelimitedPrimitive();

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(success.response.requestOptions.uri.query, '');
    });
  });

  group('complex - new types', () {
    test('integerEnum', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testPipeDelimitedComplex(
        integerEnum: PriorityEnum.one,
      );

      expect(
        response,
        isA<TonikError<void>>(),
        reason: 'only lists are supported in pipeDelimited encoding',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });

    test('nullableClass with null', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testPipeDelimitedComplex();

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(success.response.requestOptions.uri.query, '');
    });

    test('deeplyNestedClass', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testPipeDelimitedComplex(
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
        reason: 'only lists are supported in pipeDelimited encoding',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });
  });
}
