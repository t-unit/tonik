import 'package:big_decimal/big_decimal.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';
import 'package:query_parameters_api/query_parameters_api.dart';
import 'package:tonik_util/tonik_util.dart';

import 'test_helper.dart';

void main() {
  const port = 9093;
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
      final response = await api.testDeepObjectPrimitive(integer: 1);

      expect(response, isA<TonikError<void>>());
      final error = response as TonikError<void>;
      expect(
        error.type,
        TonikErrorType.encoding,
        reason: 'primitive data not supported in deepObject encoding',
      );
    });

    test('double', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testDeepObjectPrimitive(double: 1.0);

      expect(response, isA<TonikError<void>>());
      final error = response as TonikError<void>;
      expect(
        error.type,
        TonikErrorType.encoding,
        reason: 'primitive data not supported in deepObject encoding',
      );
    });

    test('number', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testDeepObjectPrimitive(number: 1.0);

      expect(response, isA<TonikError<void>>());
      final error = response as TonikError<void>;
      expect(
        error.type,
        TonikErrorType.encoding,
        reason: 'primitive data not supported in deepObject encoding',
      );
    });

    test('number', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testDeepObjectPrimitive(number: 1.0);

      expect(response, isA<TonikError<void>>());
      final error = response as TonikError<void>;
      expect(
        error.type,
        TonikErrorType.encoding,
        reason: 'primitive data not supported in deepObject encoding',
      );
    });

    test('string', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testDeepObjectPrimitive(string: 'test');

      expect(response, isA<TonikError<void>>());
      final error = response as TonikError<void>;
      expect(
        error.type,
        TonikErrorType.encoding,
        reason: 'primitive data not supported in deepObject encoding',
      );
    });

    test('boolean', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testDeepObjectPrimitive(boolean: true);

      expect(response, isA<TonikError<void>>());
      final error = response as TonikError<void>;
      expect(
        error.type,
        TonikErrorType.encoding,
        reason: 'primitive data not supported in deepObject encoding',
      );
    });

    test('datetime', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testDeepObjectPrimitive(
        datetime: DateTime.utc(2000),
      );

      expect(response, isA<TonikError<void>>());
      final error = response as TonikError<void>;
      expect(
        error.type,
        TonikErrorType.encoding,
        reason: 'primitive data not supported in deepObject encoding',
      );
    });

    test('date', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testDeepObjectPrimitive(
        date: Date(2000, 6, 15),
      );

      expect(response, isA<TonikError<void>>());
      final error = response as TonikError<void>;
      expect(
        error.type,
        TonikErrorType.encoding,
        reason: 'primitive data not supported in deepObject encoding',
      );
    });

    test('decimal', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testDeepObjectPrimitive(
        decimal: BigDecimal.parse('1.000'),
      );

      expect(response, isA<TonikError<void>>());
      final error = response as TonikError<void>;
      expect(
        error.type,
        TonikErrorType.encoding,
        reason: 'primitive data not supported in deepObject encoding',
      );
    });
  });

  group('complex', () {
    test('class', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testDeepObjectComplex(
        $class: Class(name: 'test', age: 1),
      );

      expect(response, isA<TonikError<void>>());
      final error = response as TonikError<void>;
      expect(
        error.type,
        TonikErrorType.encoding,
        reason: 'explode is required in deepObject encoding',
      );
    });

    test('classNested', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testDeepObjectComplex(
        classNested: ClassNested(
          name: 'test',
          age: 1,
          nested: Class(name: 'test', age: 1),
        ),
      );

      expect(response, isA<TonikError<void>>());
      final error = response as TonikError<void>;
      expect(
        error.type,
        TonikErrorType.encoding,
        reason: 'explode is required in deepObject encoding',
      );
    });

    test('enum', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testDeepObjectComplex($enum: Enum.value1);

      expect(response, isA<TonikError<void>>());
      final error = response as TonikError<void>;
      expect(
        error.type,
        TonikErrorType.encoding,
        reason: 'explode is required in deepObject encoding',
      );
    });

    test('classAlias', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testDeepObjectComplex(
        classAlias: ClassAlias(name: 'test', age: 1),
      );

      expect(response, isA<TonikError<void>>());
      final error = response as TonikError<void>;
      expect(
        error.type,
        TonikErrorType.encoding,
        reason: 'explode is required in deepObject encoding',
      );
    });

    test('anyOfPrimitive', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testDeepObjectComplex(
        anyOfPrimitive: AnyOfPrimitive(string: 'test'),
      );

      expect(response, isA<TonikError<void>>());
      final error = response as TonikError<void>;
      expect(
        error.type,
        TonikErrorType.encoding,
        reason: 'explode is required in deepObject encoding',
      );
    });

    test('anyOfComplex', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testDeepObjectComplex(
        anyOfComplex: AnyOfComplex($class: Class(name: 'test', age: 1)),
      );

      expect(response, isA<TonikError<void>>());
      final error = response as TonikError<void>;
      expect(
        error.type,
        TonikErrorType.encoding,
        reason: 'explode is required in deepObject encoding',
      );
    });

    test('oneOfPrimitive', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testDeepObjectComplex(
        oneOfPrimitive: OneOfPrimitiveString('test'),
      );

      expect(response, isA<TonikError<void>>());
      final error = response as TonikError<void>;
      expect(
        error.type,
        TonikErrorType.encoding,
        reason: 'explode is required in deepObject encoding',
      );
    });

    test('oneOfComplex', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testDeepObjectComplex(
        oneOfComplex: OneOfComplexClassModel(
          OneOfComplexModel(value: 'test', amount: 1),
        ),
      );

      expect(response, isA<TonikError<void>>());
      final error = response as TonikError<void>;
      expect(
        error.type,
        TonikErrorType.encoding,
        reason: 'explode is required in deepObject encoding',
      );
    });

    test('allOfPrimitive', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testDeepObjectComplex(
        allOfPrimitive: AllOfPrimitive(string: '1', int: 1),
      );

      expect(response, isA<TonikError<void>>());
      final error = response as TonikError<void>;
      expect(
        error.type,
        TonikErrorType.encoding,
        reason: 'explode is required in deepObject encoding',
      );
    });

    test('allOfComplex', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testDeepObjectComplex(
        allOfComplex: AllOfComplex(
          $class: Class(name: 'test', age: 1),
          allOfComplexModel: AllOfComplexModel(value: 'test', amount: 1),
        ),
      );

      expect(response, isA<TonikError<void>>());
      final error = response as TonikError<void>;
      expect(
        error.type,
        TonikErrorType.encoding,
        reason: 'explode is required in deepObject encoding',
      );
    });
  });

  group('complex - explode true', () {
    test('class', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testDeepObjectComplexExplode(
        $class: Class(name: 'test', age: 1),
      );

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(
        success.response.requestOptions.uri.query,
        'class%5Bname%5D=test&class%5Bage%5D=1',
      );
    });

    test('classNested', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testDeepObjectComplexExplode(
        classNested: ClassNested(
          name: 'test',
          age: 1,
          nested: Class(name: 'test', age: 1),
        ),
      );

      expect(
        response,
        isA<TonikError<void>>(),
        reason: 'nested data not supported in deepObject encoding',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });

    test('enum', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testDeepObjectComplexExplode(
        $enum: Enum.value1,
      );

      expect(response, isA<TonikError<void>>());
      final error = response as TonikError<void>;
      expect(
        error.type,
        TonikErrorType.encoding,
        reason: 'primitive data not supported in deepObject encoding',
      );
    });

    test('classAlias', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testDeepObjectComplexExplode(
        classAlias: ClassAlias(name: 'test', age: 1),
      );

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(
        success.response.requestOptions.uri.query,
        'classAlias%5Bname%5D=test&classAlias%5Bage%5D=1',
      );
    });

    test('anyOfPrimitive', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testDeepObjectComplexExplode(
        anyOfPrimitive: AnyOfPrimitive(string: 'test'),
      );

      expect(response, isA<TonikError<void>>());
      final error = response as TonikError<void>;
      expect(
        error.type,
        TonikErrorType.encoding,
        reason: 'primitive data not supported in deepObject encoding',
      );
    });

    test('anyOfComplex', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testDeepObjectComplexExplode(
        anyOfComplex: AnyOfComplex($class: Class(name: 'test', age: 1)),
      );

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(
        success.response.requestOptions.uri.query,
        'anyOfComplex%5Bname%5D=test&anyOfComplex%5Bage%5D=1',
      );
    });

    test('oneOfPrimitive', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testDeepObjectComplexExplode(
        oneOfPrimitive: OneOfPrimitiveString('test'),
      );

      expect(response, isA<TonikError<void>>());
      final error = response as TonikError<void>;
      expect(
        error.type,
        TonikErrorType.encoding,
        reason: 'primitive data not supported in deepObject encoding',
      );
    });

    test('oneOfComplex', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testDeepObjectComplexExplode(
        oneOfComplex: OneOfComplexClassModel(
          OneOfComplexModel(value: 'test', amount: 1),
        ),
      );

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(
        success.response.requestOptions.uri.query,
        'oneOfComplex%5Bvalue%5D=test&oneOfComplex%5Bamount%5D=1',
      );
    });

    test('allOfPrimitive', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testDeepObjectComplexExplode(
        allOfPrimitive: AllOfPrimitive(string: '1', int: 1),
      );

      expect(response, isA<TonikError<void>>());
      final error = response as TonikError<void>;
      expect(
        error.type,
        TonikErrorType.encoding,
        reason: 'primitive data not supported in deepObject encoding',
      );
    });

    test('allOfComplex', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testDeepObjectComplexExplode(
        allOfComplex: AllOfComplex(
          $class: Class(name: 'test', age: 1),
          allOfComplexModel: AllOfComplexModel(value: 'test', amount: 1),
        ),
      );

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(
        success.response.requestOptions.uri.query,
        'allOfComplex%5Bname%5D=test&allOfComplex%5Bage%5D=1&allOfComplex%5Bvalue%5D=test&allOfComplex%5Bamount%5D=1',
      );
    });
  });

  group('list', () {
    test('string', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testDeepObjectList(
        listString: ['test', 'test2', 'white space', 'special&&chars'],
      );

      expect(response, isA<TonikError<void>>());
      final error = response as TonikError<void>;
      expect(
        error.type,
        TonikErrorType.encoding,
        reason: 'list data not supported in deepObject encoding',
      );
    });

    test('oneOfPrimitive', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testDeepObjectList(
        listOneOfPrimitive: [OneOfPrimitiveString('test')],
      );

      expect(response, isA<TonikError<void>>());
      final error = response as TonikError<void>;
      expect(
        error.type,
        TonikErrorType.encoding,
        reason: 'list data not supported in deepObject encoding',
      );
    });

    test('listOneOfComplex', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testDeepObjectList(
        listOneOfComplex: [
          OneOfComplexClassModel(OneOfComplexModel(value: 'test', amount: 1)),
        ],
      );

      expect(response, isA<TonikError<void>>());
      final error = response as TonikError<void>;
      expect(
        error.type,
        TonikErrorType.encoding,
        reason: 'list data not supported in deepObject encoding',
      );
    });

    test('listOneOfComplexMixed - complex', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testDeepObjectList(
        listOneOfComplexMixed: [
          DeepObjectListParametersArrayOneOfModelClass(
            Class(name: 'test', age: 1),
          ),
        ],
      );

      expect(response, isA<TonikError<void>>());
      final error = response as TonikError<void>;
      expect(
        error.type,
        TonikErrorType.encoding,
        reason: 'list data not supported in deepObject encoding',
      );
    });

    test('listOneOfComplexMixed - simple', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testDeepObjectList(
        listOneOfComplexMixed: [DeepObjectListParametersArrayOneOfModelInt(1)],
      );

      expect(response, isA<TonikError<void>>());
      final error = response as TonikError<void>;
      expect(
        error.type,
        TonikErrorType.encoding,
        reason: 'list data not supported in deepObject encoding',
      );
    });
  });

  group('list - explode true', () {
    test('string', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testDeepObjectListExplode(
        listString: ['test', 'test2'],
      );

      expect(response, isA<TonikError<void>>());
      final error = response as TonikError<void>;
      expect(
        error.type,
        TonikErrorType.encoding,
        reason: 'list data not supported in deepObject encoding',
      );
    });

    test('oneOfPrimitive', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testDeepObjectListExplode(
        listOneOfPrimitive: [OneOfPrimitiveString('test')],
      );

      expect(response, isA<TonikError<void>>());
      final error = response as TonikError<void>;
      expect(
        error.type,
        TonikErrorType.encoding,
        reason: 'list data not supported in deepObject encoding',
      );
    });

    test('listOneOfComplex', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testDeepObjectListExplode(
        listOneOfComplex: [
          OneOfComplexClassModel(OneOfComplexModel(value: 'test', amount: 1)),
        ],
      );

      expect(response, isA<TonikError<void>>());
      final error = response as TonikError<void>;
      expect(
        error.type,
        TonikErrorType.encoding,
        reason: 'list data not supported in deepObject encoding',
      );
    });
  });

  group('primitive - new types', () {
    test('uri', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testDeepObjectPrimitive(
        uri: Uri.parse('https://example.com'),
      );

      expect(response, isA<TonikError<void>>());
      final error = response as TonikError<void>;
      expect(
        error.type,
        TonikErrorType.encoding,
        reason: 'primitive data not supported in deepObject encoding',
      );
    });

    test('integerEnum', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testDeepObjectPrimitive(
        integerEnum: PriorityEnum.two,
      );

      expect(response, isA<TonikError<void>>());
      final error = response as TonikError<void>;
      expect(
        error.type,
        TonikErrorType.encoding,
        reason: 'primitive data not supported in deepObject encoding',
      );
    });

    test('nullableString with value', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testDeepObjectPrimitive(
        nullableString: 'test',
      );

      expect(response, isA<TonikError<void>>());
      final error = response as TonikError<void>;
      expect(
        error.type,
        TonikErrorType.encoding,
        reason: 'primitive data not supported in deepObject encoding',
      );
    });

    test('nullableString with null', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testDeepObjectPrimitive(nullableString: null);

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(success.response.requestOptions.uri.query, '');
    });

    test('nullableInteger with null', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testDeepObjectPrimitive(nullableInteger: null);

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(success.response.requestOptions.uri.query, '');
    });
  });

  group('complex - new types', () {
    test('integerEnum', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testDeepObjectComplex(
        integerEnum: PriorityEnum.one,
      );

      expect(response, isA<TonikError<void>>());
      final error = response as TonikError<void>;
      expect(
        error.type,
        TonikErrorType.encoding,
        reason: 'explode is required in deepObject encoding',
      );
    });

    test('nullableClass with null (explode false)', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testDeepObjectComplex(nullableClass: null);

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(success.response.requestOptions.uri.query, '');
    });

    test('deeplyNestedClass (explode false)', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testDeepObjectComplex(
        deeplyNestedClass: DeeplyNestedClass(
          name: 'outer',
          nested: ClassNested(
            name: 'middle',
            age: 1,
            nested: Class(name: 'inner', age: 2),
          ),
        ),
      );

      expect(response, isA<TonikError<void>>());
      final error = response as TonikError<void>;
      expect(
        error.type,
        TonikErrorType.encoding,
        reason: 'explode is required in deepObject encoding',
      );
    });
  });

  group('complex - explode true - new types', () {
    test('integerEnum', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testDeepObjectComplexExplode(
        integerEnum: PriorityEnum.one,
      );

      expect(response, isA<TonikError<void>>());
      final error = response as TonikError<void>;
      expect(
        error.type,
        TonikErrorType.encoding,
        reason: 'primitive data not supported in deepObject encoding',
      );
    });

    test('nullableClass with value', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testDeepObjectComplexExplode(
        nullableClass: NullableClass(name: 'test', age: 25),
      );

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(
        success.response.requestOptions.uri.query,
        'nullableClass%5Bname%5D=test&nullableClass%5Bage%5D=25',
      );
    });

    test('nullableClass with null', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testDeepObjectComplexExplode(
        nullableClass: null,
      );

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(success.response.requestOptions.uri.query, '');
    });

    test('nullableClass with nullable age', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testDeepObjectComplexExplode(
        nullableClass: NullableClass(name: 'test', age: null),
      );

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(
        success.response.requestOptions.uri.query,
        'nullableClass%5Bname%5D=test',
      );
    });

    test('deeplyNestedClass', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testDeepObjectComplexExplode(
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
        reason: 'nested data not supported in deepObject encoding',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });
  });
}
