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
      final response = await api.testFormPrimitive(integer: 1);

      expect(response, isA<TonikSuccess<void>>());

      final success = response as TonikSuccess<void>;
      expect(success.response.requestOptions.uri.query, 'integer=1');
    });

    test('double', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testFormPrimitive(double: 1);

      expect(response, isA<TonikSuccess<void>>());

      final success = response as TonikSuccess<void>;
      expect(success.response.requestOptions.uri.query, 'double=1.0');
    });

    test('number', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testFormPrimitive(number: 1.0);

      expect(response, isA<TonikSuccess<void>>());

      final success = response as TonikSuccess<void>;
      expect(success.response.requestOptions.uri.query, 'number=1.0');
    });

    test('number', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testFormPrimitive(number: 1.0);

      expect(response, isA<TonikSuccess<void>>());

      final success = response as TonikSuccess<void>;
      expect(success.response.requestOptions.uri.query, 'number=1.0');
    });

    test('string', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testFormPrimitive(string: 'test');

      expect(response, isA<TonikSuccess<void>>());

      final success = response as TonikSuccess<void>;
      expect(success.response.requestOptions.uri.query, 'string=test');
    });

    test('boolean', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testFormPrimitive(boolean: true);

      expect(response, isA<TonikSuccess<void>>());

      final success = response as TonikSuccess<void>;
      expect(success.response.requestOptions.uri.query, 'boolean=true');
    });

    test('datetime', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testFormPrimitive(
        datetime: DateTime.utc(2000),
      );

      expect(response, isA<TonikSuccess<void>>());

      final success = response as TonikSuccess<void>;
      expect(
        success.response.requestOptions.uri.query,
        'datetime=2000-01-01T00%3A00%3A00.000Z',
      );
    });

    test('date', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testFormPrimitive(date: Date(2000, 6, 15));

      expect(response, isA<TonikSuccess<void>>());

      final success = response as TonikSuccess<void>;
      expect(success.response.requestOptions.uri.query, 'date=2000-06-15');
    });

    test('decimal', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testFormPrimitive(
        decimal: BigDecimal.parse('1.000'),
      );

      expect(response, isA<TonikSuccess<void>>());

      final success = response as TonikSuccess<void>;
      expect(success.response.requestOptions.uri.query, 'decimal=1.000');
    });
  });

  group('complex', () {
    test('class', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testFormComplex(
        $class: const Class(name: 'test', age: 1),
      );

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(
        success.response.requestOptions.uri.query,
        'class=name,test,age,1',
      );
    });

    test('classNested', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testFormComplex(
        classNested: const ClassNested(
          name: 'test',
          age: 1,
          nested: Class(name: 'test', age: 1),
        ),
      );

      expect(
        response,
        isA<TonikError<void>>(),
        reason: 'nested data not supported in form encoding',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });

    test('enum', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testFormComplex($enum: Enum.value1);

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(success.response.requestOptions.uri.query, 'enum=value1');
    });

    test('classAlias', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testFormComplex(
        classAlias: const ClassAlias(name: 'test', age: 1),
      );

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(
        success.response.requestOptions.uri.query,
        'classAlias=name,test,age,1',
      );
    });

    test('anyOfPrimitive', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testFormComplex(
        anyOfPrimitive: const AnyOfPrimitive(string: 'test'),
      );

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(success.response.requestOptions.uri.query, 'anyOfPrimitive=test');
    });

    test('anyOfComplex', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testFormComplex(
        anyOfComplex: const AnyOfComplex($class: Class(name: 'test', age: 1)),
      );

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(
        success.response.requestOptions.uri.query,
        'anyOfComplex=name,test,age,1',
      );
    });

    test('oneOfPrimitive', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testFormComplex(
        oneOfPrimitive: const OneOfPrimitiveString('test'),
      );

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(success.response.requestOptions.uri.query, 'oneOfPrimitive=test');
    });

    test('oneOfComplex', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testFormComplex(
        oneOfComplex: const OneOfComplexClassModel(
          OneOfComplexModel(value: 'test', amount: 1),
        ),
      );

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(
        success.response.requestOptions.uri.query,
        'oneOfComplex=value,test,amount,1',
      );
    });

    test('allOfPrimitive', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testFormComplex(
        allOfPrimitive: const AllOfPrimitive(string: '1', int: 1),
      );

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(success.response.requestOptions.uri.query, 'allOfPrimitive=1');
    });

    test('allOfComplex', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testFormComplex(
        allOfComplex: const AllOfComplex(
          $class: Class(name: 'test', age: 1),
          allOfComplexModel: AllOfComplexModel(value: 'test', amount: 1),
        ),
      );

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(
        success.response.requestOptions.uri.query,
        'allOfComplex=name,test,age,1,value,test,amount,1',
      );
    });
  });

  group('complex - explode true', () {
    test('class', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testFormComplexExplode(
        $class: const Class(name: 'test', age: 1),
      );

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(
        success.response.requestOptions.uri.query,
        'class=name=test&age=1',
      );
    });

    test('classNested', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testFormComplexExplode(
        classNested: const ClassNested(
          name: 'test',
          age: 1,
          nested: Class(name: 'test', age: 1),
        ),
      );

      expect(
        response,
        isA<TonikError<void>>(),
        reason: 'nested data not supported in form encoding',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });

    test('enum', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testFormComplexExplode($enum: Enum.value1);

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(success.response.requestOptions.uri.query, 'enum=value1');
    });

    test('classAlias', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testFormComplexExplode(
        classAlias: const ClassAlias(name: 'test', age: 1),
      );

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(
        success.response.requestOptions.uri.query,
        'classAlias=name=test&age=1',
      );
    });

    test('anyOfPrimitive', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testFormComplexExplode(
        anyOfPrimitive: const AnyOfPrimitive(string: 'test'),
      );

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(success.response.requestOptions.uri.query, 'anyOfPrimitive=test');
    });

    test('anyOfComplex', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testFormComplexExplode(
        anyOfComplex: const AnyOfComplex($class: Class(name: 'test', age: 1)),
      );

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(
        success.response.requestOptions.uri.query,
        'anyOfComplex=name=test&age=1',
      );
    });

    test('oneOfPrimitive', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testFormComplexExplode(
        oneOfPrimitive: const OneOfPrimitiveString('test'),
      );

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(success.response.requestOptions.uri.query, 'oneOfPrimitive=test');
    });

    test('oneOfComplex', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testFormComplexExplode(
        oneOfComplex: const OneOfComplexClassModel(
          OneOfComplexModel(value: 'test', amount: 1),
        ),
      );

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(
        success.response.requestOptions.uri.query,
        'oneOfComplex=value=test&amount=1',
      );
    });

    test('allOfPrimitive', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testFormComplexExplode(
        allOfPrimitive: const AllOfPrimitive(string: '1', int: 1),
      );

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(success.response.requestOptions.uri.query, 'allOfPrimitive=1');
    });

    test('allOfComplex', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testFormComplexExplode(
        allOfComplex: const AllOfComplex(
          $class: Class(name: 'test', age: 1),
          allOfComplexModel: AllOfComplexModel(value: 'test', amount: 1),
        ),
      );

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(
        success.response.requestOptions.uri.query,
        'allOfComplex=name=test&age=1&value=test&amount=1',
      );
    });
  });

  group('list', () {
    test('string', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testFormList(
        listString: ['test', 'test2', 'white space', 'special&&chars'],
      );
      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(
        success.response.requestOptions.uri.query,
        'listString=test,test2,white%20space,special%26%26chars',
      );
    });

    test('oneOfPrimitive', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testFormList(
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
      final response = await api.testFormList(
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
      final response = await api.testFormList(
        listOneOfComplexMixed: [
          const FormListParametersArrayOneOfModelClass(
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
      final response = await api.testFormList(
        listOneOfComplexMixed: [const FormListParametersArrayOneOfModelInt(1)],
      );
      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(
        success.response.requestOptions.uri.query,
        'listOneOfComplexMixed=1',
      );
    });
  });

  group('list - explode true', () {
    test('string', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testFormListExplode(
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
      final response = await api.testFormListExplode(
        listOneOfPrimitive: [
          const OneOfPrimitiveString('test'),
          const OneOfPrimitiveString('test2'),
        ],
      );
      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(
        success.response.requestOptions.uri.query,
        'listOneOfPrimitive=test&listOneOfPrimitive=test2',
      );
    });

    test('listOneOfComplex', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testFormListExplode(
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
      final response = await api.testFormPrimitive(
        uri: Uri.parse('https://example.com/path?query=value'),
      );

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(
        success.response.requestOptions.uri.query,
        'uri=https%3A%2F%2Fexample.com%2Fpath%3Fquery%3Dvalue',
      );
    });

    test('integerEnum', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testFormPrimitive(
        integerEnum: PriorityEnum.two,
      );

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(success.response.requestOptions.uri.query, 'integerEnum=2');
    });

    test('nullableString with value', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testFormPrimitive(nullableString: 'test');

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(success.response.requestOptions.uri.query, 'nullableString=test');
    });

    test('nullableString with null', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testFormPrimitive();

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(success.response.requestOptions.uri.query, '');
    });

    test('nullableInteger with value', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testFormPrimitive(nullableInteger: 42);

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(success.response.requestOptions.uri.query, 'nullableInteger=42');
    });

    test('nullableInteger with null', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testFormPrimitive();

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(success.response.requestOptions.uri.query, '');
    });
  });

  group('complex - new types', () {
    test('integerEnum', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testFormComplex(integerEnum: PriorityEnum.one);

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(success.response.requestOptions.uri.query, 'integerEnum=1');
    });

    test('nullableClass with value', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testFormComplex(
        nullableClass: const NullableClass(name: 'test', age: 25),
      );

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(
        success.response.requestOptions.uri.query,
        'nullableClass=name,test,age,25',
      );
    });

    test('nullableClass with null', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testFormComplex();

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(success.response.requestOptions.uri.query, '');
    });

    test('deeplyNestedClass', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testFormComplex(
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
        reason: 'deeply nested data not supported in form encoding',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });
  });

  group('complex - explode true - new types', () {
    test('integerEnum', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testFormComplexExplode(
        integerEnum: PriorityEnum.three,
      );

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(success.response.requestOptions.uri.query, 'integerEnum=3');
    });

    test('nullableClass with value', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testFormComplexExplode(
        nullableClass: const NullableClass(name: 'test'),
      );

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(
        success.response.requestOptions.uri.query,
        'nullableClass=name=test',
      );
    });

    test('deeplyNestedClass', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testFormComplexExplode(
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
        reason: 'deeply nested data not supported in form encoding',
      );
      final error = response as TonikError<void>;
      expect(error.type, TonikErrorType.encoding);
    });
  });
}
