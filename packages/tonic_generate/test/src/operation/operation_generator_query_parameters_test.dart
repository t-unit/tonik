import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonic_core/tonic_core.dart';
import 'package:tonic_generate/src/operation/operation_generator.dart';
import 'package:tonic_generate/src/util/name_generator.dart';
import 'package:tonic_generate/src/util/name_manager.dart';

void main() {
  group('OperationGenerator.generateQueryParametersMethod', () {
    late OperationGenerator generator;
    late Context context;
    late DartEmitter emitter;
    late NameManager nameManager;
    late NameGenerator nameGenerator;

    final format =
        DartFormatter(
          languageVersion: DartFormatter.latestLanguageVersion,
        ).format;

    setUp(() {
      nameGenerator = NameGenerator();
      nameManager = NameManager(generator: nameGenerator);
      generator = OperationGenerator(
        nameManager: nameManager,
        package: 'package:api/api.dart',
      );
      context = Context.initial();
      emitter = DartEmitter(useNullSafetySyntax: true);
    });

    test('returns empty map for operation without query parameters', () {
      final operation = Operation(
        operationId: 'getUsers',
        context: context,
        summary: 'Get users',
        description: 'Gets a list of users',
        tags: const {},
        isDeprecated: false,
        path: '/users',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        responses: const {},
      );

      const expectedMethod = '''
        Map<String, dynamic> _queryParameters() {
          final result = <String, dynamic>{};
          return result;
        }
      ''';

      final method = generator.generateQueryParametersMethod(operation, []);

      expect(method, isA<Method>());

      final returnTypeString = method.returns?.accept(emitter).toString();
      expect(returnTypeString, contains('Map<String,dynamic>'));

      expect(method.requiredParameters, isEmpty);
      expect(method.optionalParameters, isEmpty);

      expect(
        collapseWhitespace(format(method.accept(emitter).toString())),
        collapseWhitespace(expectedMethod),
      );
    });

    test('adds parameters when query parameters exist', () {
      final queryParam = QueryParameterObject(
        name: 'filter',
        rawName: 'filter',
        description: 'Filter results',
        isRequired: false,
        isDeprecated: false,
        allowEmptyValue: true,
        explode: false,
        encoding: QueryParameterEncoding.form,
        allowReserved: false,
        model: StringModel(context: context),
        context: context,
      );

      final operation = Operation(
        operationId: 'listUsers',
        context: context,
        summary: 'List users',
        description: 'Lists all users with filters',
        tags: const {},
        isDeprecated: false,
        path: '/users',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: {queryParam},
        pathParameters: const {},
        responses: const {},
      );

      final queryParameters =
          <({String normalizedName, QueryParameterObject parameter})>[
            (normalizedName: 'filter', parameter: queryParam),
          ];

      final method = generator.generateQueryParametersMethod(
        operation,
        queryParameters,
      );

      expect(method, isA<Method>());
      expect(method.optionalParameters, hasLength(1));
      expect(method.optionalParameters.first.name, 'filter');
      expect(method.optionalParameters.first.type?.symbol, 'String');
      expect(method.optionalParameters.first.named, isTrue);
      expect(method.optionalParameters.first.required, isFalse);
    });

    test('encodes query parameters with form style (default)', () {
      final queryParam = QueryParameterObject(
        name: 'filter',
        rawName: 'filter',
        description: 'Filter results',
        isRequired: false,
        isDeprecated: false,
        allowEmptyValue: true,
        explode: false,
        encoding: QueryParameterEncoding.form,
        allowReserved: false,
        model: ClassModel(context: context, properties: const {}),
        context: context,
      );

      final operation = Operation(
        operationId: 'listUsers',
        context: context,
        summary: 'List users',
        description: 'Lists all users with filters',
        tags: const {},
        isDeprecated: false,
        path: '/users',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: {queryParam},
        pathParameters: const {},
        responses: const {},
      );

      const expectedMethod = '''
        Map<String, dynamic> _queryParameters({Anonymous? filter}) {
          final result = <String, dynamic>{};
          final formEncoder = FormEncoder();
          if (filter != null) {
            result['filter'] = formEncoder.encode(filter.toJson());
          }
          return result;
        }
      ''';

      final queryParameters =
          <({String normalizedName, QueryParameterObject parameter})>[
            (normalizedName: 'filter', parameter: queryParam),
          ];

      final method = generator.generateQueryParametersMethod(
        operation,
        queryParameters,
      );

      expect(method, isA<Method>());
      expect(
        collapseWhitespace(format(method.accept(emitter).toString())),
        collapseWhitespace(expectedMethod),
      );
    });

    test('encodes query parameters with deepObject style', () {
      final queryParam = QueryParameterObject(
        name: 'filter',
        rawName: 'filter',
        description: 'Filter results',
        isRequired: false,
        isDeprecated: false,
        allowEmptyValue: true,
        explode: false,
        encoding: QueryParameterEncoding.deepObject,
        allowReserved: false,
        model: ClassModel(context: context, properties: const {}),
        context: context,
      );

      final operation = Operation(
        operationId: 'listUsers',
        context: context,
        summary: 'List users',
        description: 'Lists all users with filters',
        tags: const {},
        isDeprecated: false,
        path: '/users',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: {queryParam},
        pathParameters: const {},
        responses: const {},
      );

      const expectedMethod = '''
        Map<String, dynamic> _queryParameters({Anonymous? filter}) {
          final result = <String, dynamic>{};
          final deepObjectEncoder = DeepObjectEncoder();
          if (filter != null) {
            result.addAll(deepObjectEncoder.encode('filter', filter.toJson()));
          }
          return result;
        }
      ''';

      final queryParameters =
          <({String normalizedName, QueryParameterObject parameter})>[
            (normalizedName: 'filter', parameter: queryParam),
          ];

      final method = generator.generateQueryParametersMethod(
        operation,
        queryParameters,
      );

      expect(method, isA<Method>());
      expect(
        collapseWhitespace(format(method.accept(emitter).toString())),
        collapseWhitespace(expectedMethod),
      );
    });

    test('encodes query parameters with delimited style', () {
      final queryParam = QueryParameterObject(
        name: 'tags',
        rawName: 'tags',
        description: 'Filter by tags',
        isRequired: false,
        isDeprecated: false,
        allowEmptyValue: true,
        explode: false,
        encoding: QueryParameterEncoding.spaceDelimited,
        allowReserved: false,
        model: ListModel(
          context: context,
          content: StringModel(context: context),
        ),
        context: context,
      );

      final operation = Operation(
        operationId: 'listUsers',
        context: context,
        summary: 'List users',
        description: 'Lists all users with filters',
        tags: const {},
        isDeprecated: false,
        path: '/users',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: {queryParam},
        pathParameters: const {},
        responses: const {},
      );

      const expectedMethod = '''
        Map<String, dynamic> _queryParameters({List<String>? tags}) {
          final result = <String, dynamic>{};
          final spacedEncoder = DelimitedEncoder.spaced();
          if (tags != null) {
            result['tags'] = spacedEncoder.encode(tags);
          }
          return result;
        }
      ''';

      final queryParameters =
          <({String normalizedName, QueryParameterObject parameter})>[
            (normalizedName: 'tags', parameter: queryParam),
          ];

      final method = generator.generateQueryParametersMethod(
        operation,
        queryParameters,
      );

      expect(method, isA<Method>());
      expect(
        collapseWhitespace(format(method.accept(emitter).toString())),
        collapseWhitespace(expectedMethod),
      );
    });

    test('encodes complex query parameters with deepObject style', () {
      final queryParam = QueryParameterObject(
        name: 'filter',
        rawName: 'filter',
        description: 'Complex filter',
        isRequired: false,
        isDeprecated: false,
        allowEmptyValue: true,
        explode: false,
        encoding: QueryParameterEncoding.deepObject,
        allowReserved: false,
        model: ClassModel(context: context, properties: const {}),
        context: context,
      );

      final operation = Operation(
        operationId: 'listUsers',
        context: context,
        summary: 'List users',
        description: 'Lists all users with filters',
        tags: const {},
        isDeprecated: false,
        path: '/users',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: {queryParam},
        pathParameters: const {},
        responses: const {},
      );

      const expectedMethod = '''
        Map<String, dynamic> _queryParameters({Anonymous? filter}) {
          final result = <String, dynamic>{};
          final deepObjectEncoder = DeepObjectEncoder();
          if (filter != null) {
            result.addAll(deepObjectEncoder.encode('filter', filter.toJson()));
          }
          return result;
        }
      ''';

      final queryParameters =
          <({String normalizedName, QueryParameterObject parameter})>[
            (normalizedName: 'filter', parameter: queryParam),
          ];

      final method = generator.generateQueryParametersMethod(
        operation,
        queryParameters,
      );

      expect(method, isA<Method>());
      expect(
        collapseWhitespace(format(method.accept(emitter).toString())),
        collapseWhitespace(expectedMethod),
      );
    });

    test('encodes multiple parameters with different encoders', () {
      final filterParam = QueryParameterObject(
        name: 'filter',
        rawName: 'filter',
        description: 'Filter results',
        isRequired: false,
        isDeprecated: false,
        allowEmptyValue: true,
        explode: false,
        encoding: QueryParameterEncoding.deepObject,
        allowReserved: false,
        model: ClassModel(context: context, properties: const {}),
        context: context,
      );

      final tagsParam = QueryParameterObject(
        name: 'tags',
        rawName: 'tags',
        description: 'Filter by tags',
        isRequired: false,
        isDeprecated: false,
        allowEmptyValue: true,
        explode: false,
        encoding: QueryParameterEncoding.spaceDelimited,
        allowReserved: false,
        model: ListModel(
          context: context,
          content: StringModel(context: context),
        ),
        context: context,
      );

      final sortParam = QueryParameterObject(
        name: 'sort',
        rawName: 'sort',
        description: 'Sort order',
        isRequired: false,
        isDeprecated: false,
        allowEmptyValue: true,
        explode: false,
        encoding: QueryParameterEncoding.form,
        allowReserved: false,
        model: StringModel(context: context),
        context: context,
      );

      final operation = Operation(
        operationId: 'listUsers',
        context: context,
        summary: 'List users',
        description: 'Lists all users with filters',
        tags: const {},
        isDeprecated: false,
        path: '/users',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: {filterParam, tagsParam, sortParam},
        pathParameters: const {},
        responses: const {},
      );

      const expectedMethod = '''
        Map<String, dynamic> _queryParameters({
          Anonymous? filter,
          List<String>? tags,
          String? sort,
        }) {
          final result = <String, dynamic>{};
          final deepObjectEncoder = DeepObjectEncoder();
          final spacedEncoder = DelimitedEncoder.spaced();
          final formEncoder = FormEncoder();
          if (filter != null) {
            result.addAll(deepObjectEncoder.encode('filter', filter.toJson()));
          }
          if (tags != null) {
            result['tags'] = spacedEncoder.encode(tags);
          }
          if (sort != null) {
            result['sort'] = formEncoder.encode(sort);
          }
          return result;
        }
      ''';

      final queryParameters =
          <({String normalizedName, QueryParameterObject parameter})>[
            (normalizedName: 'filter', parameter: filterParam),
            (normalizedName: 'tags', parameter: tagsParam),
            (normalizedName: 'sort', parameter: sortParam),
          ];

      final method = generator.generateQueryParametersMethod(
        operation,
        queryParameters,
      );

      expect(method, isA<Method>());
      expect(
        collapseWhitespace(format(method.accept(emitter).toString())),
        collapseWhitespace(expectedMethod),
      );
    });

    test('encodes parameters with explode=true', () {
      final filterParam = QueryParameterObject(
        name: 'filter',
        rawName: 'filter',
        description: 'Filter results',
        isRequired: false,
        isDeprecated: false,
        allowEmptyValue: true,
        explode: true,
        encoding: QueryParameterEncoding.form,
        allowReserved: false,
        model: ClassModel(context: context, properties: const {}),
        context: context,
      );

      final tagsParam = QueryParameterObject(
        name: 'tags',
        rawName: 'tags',
        description: 'Filter by tags',
        isRequired: false,
        isDeprecated: false,
        allowEmptyValue: true,
        explode: true,
        encoding: QueryParameterEncoding.spaceDelimited,
        allowReserved: false,
        model: ListModel(
          context: context,
          content: StringModel(context: context),
        ),
        context: context,
      );

      final operation = Operation(
        operationId: 'listUsers',
        context: context,
        summary: 'List users',
        description: 'Lists all users with filters',
        tags: const {},
        isDeprecated: false,
        path: '/users',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: {filterParam, tagsParam},
        pathParameters: const {},
        responses: const {},
      );

      const expectedMethod = '''
        Map<String, dynamic> _queryParameters({Anonymous? filter, List<String>? tags}) {
          final result = <String, dynamic>{};
          final formEncoder = FormEncoder();
          final spacedEncoder = DelimitedEncoder.spaced();
          if (filter != null) {
            result['filter'] = formEncoder.encode(filter.toJson(), explode: true);
          }
          if (tags != null) {
            result['tags'] = spacedEncoder.encode(tags, explode: true);
          }
          return result;
        }
      ''';

      final queryParameters =
          <({String normalizedName, QueryParameterObject parameter})>[
            (normalizedName: 'filter', parameter: filterParam),
            (normalizedName: 'tags', parameter: tagsParam),
          ];

      final method = generator.generateQueryParametersMethod(
        operation,
        queryParameters,
      );

      expect(method, isA<Method>());
      expect(
        collapseWhitespace(format(method.accept(emitter).toString())),
        collapseWhitespace(expectedMethod),
      );
    });

    test('encodes required parameters with allowEmptyValue=false', () {
      final filterParam = QueryParameterObject(
        name: 'filter',
        rawName: 'filter',
        description: 'Filter results',
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: false,
        encoding: QueryParameterEncoding.form,
        allowReserved: false,
        model: ClassModel(context: context, properties: const {}),
        context: context,
      );

      final operation = Operation(
        operationId: 'listUsers',
        context: context,
        summary: 'List users',
        description: 'Lists all users with filters',
        tags: const {},
        isDeprecated: false,
        path: '/users',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: {filterParam},
        pathParameters: const {},
        responses: const {},
      );

      const expectedMethod = '''
        Map<String, dynamic> _queryParameters({required Anonymous filter}) {
          final result = <String, dynamic>{};
          final formEncoder = FormEncoder();
          result['filter'] = formEncoder.encode(filter.toJson());
          return result;
        }
      ''';

      final queryParameters =
          <({String normalizedName, QueryParameterObject parameter})>[
            (normalizedName: 'filter', parameter: filterParam),
          ];

      final method = generator.generateQueryParametersMethod(
        operation,
        queryParameters,
      );

      expect(method, isA<Method>());
      expect(
        collapseWhitespace(format(method.accept(emitter).toString())),
        collapseWhitespace(expectedMethod),
      );
    });

    test('encodes optional parameters with allowEmptyValue=false', () {
      final filterParam = QueryParameterObject(
        name: 'filter',
        rawName: 'filter',
        description: 'Filter results',
        isRequired: false,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: false,
        encoding: QueryParameterEncoding.form,
        allowReserved: false,
        model: ClassModel(context: context, properties: const {}),
        context: context,
      );

      final operation = Operation(
        operationId: 'listUsers',
        context: context,
        summary: 'List users',
        description: 'Lists all users with filters',
        tags: const {},
        isDeprecated: false,
        path: '/users',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: {filterParam},
        pathParameters: const {},
        responses: const {},
      );

      const expectedMethod = '''
        Map<String, dynamic> _queryParameters({Anonymous? filter}) {
          final result = <String, dynamic>{};
          final formEncoder = FormEncoder();
          if (filter != null) {
            result['filter'] = formEncoder.encode(filter.toJson());
          }
          return result;
        }
      ''';

      final queryParameters =
          <({String normalizedName, QueryParameterObject parameter})>[
            (normalizedName: 'filter', parameter: filterParam),
          ];

      final method = generator.generateQueryParametersMethod(
        operation,
        queryParameters,
      );

      expect(method, isA<Method>());
      expect(
        collapseWhitespace(format(method.accept(emitter).toString())),
        collapseWhitespace(expectedMethod),
      );
    });

    test('handles empty value validation for different types', () {
      final stringParam = QueryParameterObject(
        name: 'name',
        rawName: 'name',
        description: 'User name',
        isRequired: false,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: false,
        encoding: QueryParameterEncoding.form,
        allowReserved: false,
        model: StringModel(context: context),
        context: context,
      );

      final listParam = QueryParameterObject(
        name: 'tags',
        rawName: 'tags',
        description: 'User tags',
        isRequired: false,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: false,
        encoding: QueryParameterEncoding.form,
        allowReserved: false,
        model: ListModel(
          context: context,
          content: StringModel(context: context),
        ),
        context: context,
      );

      final numberParam = QueryParameterObject(
        name: 'age',
        rawName: 'age',
        description: 'User age',
        isRequired: false,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: false,
        encoding: QueryParameterEncoding.form,
        allowReserved: false,
        model: IntegerModel(context: context),
        context: context,
      );

      final boolParam = QueryParameterObject(
        name: 'active',
        rawName: 'active',
        description: 'User active status',
        isRequired: false,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: false,
        encoding: QueryParameterEncoding.form,
        allowReserved: false,
        model: BooleanModel(context: context),
        context: context,
      );

      final operation = Operation(
        operationId: 'listUsers',
        context: context,
        summary: 'List users',
        description: 'Lists all users with filters',
        tags: const {},
        isDeprecated: false,
        path: '/users',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: {stringParam, listParam, numberParam, boolParam},
        pathParameters: const {},
        responses: const {},
      );

      const expectedMethod = '''
        Map<String, dynamic> _queryParameters({
          String? name,
          List<String>? tags,
          int? age,
          bool? active,
        }) {
          final result = <String, dynamic>{};
          final formEncoder = FormEncoder();
          if (name != null && name.isNotEmpty) {
            result['name'] = formEncoder.encode(name);
          }
          if (tags != null && tags.isNotEmpty) {
            result['tags'] = formEncoder.encode(tags);
          }
          if (age != null) {
            result['age'] = formEncoder.encode(age);
          }
          if (active != null) {
            result['active'] = formEncoder.encode(active);
          }
          return result;
        }
      ''';

      final queryParameters =
          <({String normalizedName, QueryParameterObject parameter})>[
            (normalizedName: 'name', parameter: stringParam),
            (normalizedName: 'tags', parameter: listParam),
            (normalizedName: 'age', parameter: numberParam),
            (normalizedName: 'active', parameter: boolParam),
          ];

      final method = generator.generateQueryParametersMethod(
        operation,
        queryParameters,
      );

      expect(method, isA<Method>());
      expect(
        collapseWhitespace(format(method.accept(emitter).toString())),
        collapseWhitespace(expectedMethod),
      );
    });

    test('handles empty value validation for class models', () {
      final classWithStringParam = QueryParameterObject(
        name: 'filter',
        rawName: 'filter',
        description: 'Filter results',
        isRequired: false,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: false,
        encoding: QueryParameterEncoding.form,
        allowReserved: false,
        model: ClassModel(context: context, properties: const {}),
        context: context,
      );

      final classWithNumberParam = QueryParameterObject(
        name: 'range',
        rawName: 'range',
        description: 'Range filter',
        isRequired: false,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: false,
        encoding: QueryParameterEncoding.form,
        allowReserved: false,
        model: ClassModel(context: context, properties: const {}),
        context: context,
      );

      final operation = Operation(
        operationId: 'listUsers',
        context: context,
        summary: 'List users',
        description: 'Lists all users with filters',
        tags: const {},
        isDeprecated: false,
        path: '/users',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: {classWithStringParam, classWithNumberParam},
        pathParameters: const {},
        responses: const {},
      );

      const expectedMethod = '''
        Map<String, dynamic> _queryParameters({
          Anonymous? filter,
          AnonymousModel? range,
        }) {
          final result = <String, dynamic>{};
          final formEncoder = FormEncoder();
          if (filter != null) {
            result['filter'] = formEncoder.encode(filter.toJson());
          }
          if (range != null) {
            result['range'] = formEncoder.encode(range.toJson());
          }
          return result;
        }
      ''';

      final queryParameters =
          <({String normalizedName, QueryParameterObject parameter})>[
            (normalizedName: 'filter', parameter: classWithStringParam),
            (normalizedName: 'range', parameter: classWithNumberParam),
          ];

      final method = generator.generateQueryParametersMethod(
        operation,
        queryParameters,
      );

      expect(method, isA<Method>());
      expect(
        collapseWhitespace(format(method.accept(emitter).toString())),
        collapseWhitespace(expectedMethod),
      );
    });

    test('encodes different model types with different encoders', () {
      final enumModel = EnumModel(
        context: context,
        values: const {'red', 'green', 'blue'},
        isNullable: false,
      );

      final stringModel = StringModel(context: context);
      final integerModel = IntegerModel(context: context);
      final booleanModel = BooleanModel(context: context);
      final classModel = ClassModel(context: context, properties: const {});

      final oneOfModel = OneOfModel(
        context: context,
        models: {
          (discriminatorValue: 'string', model: stringModel),
          (discriminatorValue: 'integer', model: integerModel),
        },
        name: 'OneOfValue',
        discriminator: 'type',
      );

      final anyOfModel = AnyOfModel(
        context: context,
        models: {
          (discriminatorValue: 'string', model: stringModel),
          (discriminatorValue: 'boolean', model: booleanModel),
        },
        name: 'AnyOfCondition',
        discriminator: 'type',
      );

      final allOfModel = AllOfModel(
        context: context,
        models: {classModel, classModel},
        name: 'AllOfComposite',
      );

      final enumParam = QueryParameterObject(
        name: 'color',
        rawName: 'color',
        description: 'Color filter',
        isRequired: false,
        isDeprecated: false,
        allowEmptyValue: true,
        explode: false,
        encoding: QueryParameterEncoding.form,
        allowReserved: false,
        model: enumModel,
        context: context,
      );

      final oneOfParam = QueryParameterObject(
        name: 'value',
        rawName: 'value',
        description: 'Value filter',
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: true,
        explode: false,
        encoding: QueryParameterEncoding.deepObject,
        allowReserved: false,
        model: oneOfModel,
        context: context,
      );

      final anyOfParam = QueryParameterObject(
        name: 'condition',
        rawName: 'condition',
        description: 'Condition filter',
        isRequired: false,
        isDeprecated: false,
        allowEmptyValue: true,
        explode: false,
        encoding: QueryParameterEncoding.spaceDelimited,
        allowReserved: false,
        model: anyOfModel,
        context: context,
      );

      final allOfParam = QueryParameterObject(
        name: 'composite',
        rawName: 'composite',
        description: 'Composite filter',
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: true,
        explode: false,
        encoding: QueryParameterEncoding.pipeDelimited,
        allowReserved: false,
        model: allOfModel,
        context: context,
      );

      final operation = Operation(
        operationId: 'complexFilter',
        context: context,
        summary: 'Complex filter operation',
        description: 'Operation with various model types as parameters',
        tags: const {},
        isDeprecated: false,
        path: '/filter',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: {enumParam, oneOfParam, anyOfParam, allOfParam},
        pathParameters: const {},
        responses: const {},
      );

      const expectedMethod = '''
        Map<String, dynamic> _queryParameters({
          Anonymous? color,
          required OneOfValue value,
          AnyOfCondition? condition,
          required AllOfComposite composite,
        }) {
          final result = <String, dynamic>{};
          final formEncoder = FormEncoder();
          final deepObjectEncoder = DeepObjectEncoder();
          final spacedEncoder = DelimitedEncoder.spaced();
          final pipedEncoder = DelimitedEncoder.piped();
          if (color != null) {
            result['color'] = formEncoder.encode(color.toJson());
          }
          result.addAll(deepObjectEncoder.encode('value', value.toJson()));
          if (condition != null) {
            result['condition'] = spacedEncoder.encode(condition.toJson());
          }
          result['composite'] = pipedEncoder.encode(composite.toJson());
          return result;
        }
      ''';

      final queryParameters =
          <({String normalizedName, QueryParameterObject parameter})>[
            (normalizedName: 'color', parameter: enumParam),
            (normalizedName: 'value', parameter: oneOfParam),
            (normalizedName: 'condition', parameter: anyOfParam),
            (normalizedName: 'composite', parameter: allOfParam),
          ];

      final method = generator.generateQueryParametersMethod(
        operation,
        queryParameters,
      );

      expect(method, isA<Method>());
      expect(
        collapseWhitespace(format(method.accept(emitter).toString())),
        collapseWhitespace(expectedMethod),
      );
    });
  });
}
