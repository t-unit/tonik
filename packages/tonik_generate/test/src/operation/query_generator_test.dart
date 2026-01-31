import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/operation/query_generator.dart';

void main() {
  group('QueryGenerator.generateQueryParametersMethod', () {
    late QueryGenerator generator;
    late Context context;
    late DartEmitter emitter;
    late NameManager nameManager;
    late NameGenerator nameGenerator;

    final format = DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    ).format;

    setUp(() {
      nameGenerator = NameGenerator();
      nameManager = NameManager(generator: nameGenerator);
      generator = QueryGenerator(
        nameManager: nameManager,
        package: 'package:api/api.dart',
      );
      context = Context.initial();
      emitter = DartEmitter(useNullSafetySyntax: true);
    });

    test('returns null for operation without query parameters', () {
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
        cookieParameters: const {},
        responses: const {},
        securitySchemes: const {},
      );

      const expectedMethod = r'''
        String? _queryParameters() {
          final entries = <ParameterEntry>[];
          if (entries.isEmpty) {
            return null;
          }
          return entries.map((e) => '${e.name}=${e.value}').join('&');
        }
      ''';

      final method = generator.generateQueryParametersMethod(operation, []);

      expect(method, isA<Method>());
      expect(method.returns?.accept(emitter).toString(), 'String?');
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
        cookieParameters: const {},
        responses: const {},
        securitySchemes: const {},
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
        model: ClassModel(
          isDeprecated: false,
          context: context,
          properties: const [],
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
        cookieParameters: const {},
        responses: const {},
        securitySchemes: const {},
      );

      const expectedMethod = r'''
        String? _queryParameters({AnonymousModel? filter}) {
          final entries = <ParameterEntry>[];
          if (filter != null) {
            entries.add((
              name: r'filter',
              value: filter.toForm(explode: false, allowEmpty: true),
            ));
          }
          if (entries.isEmpty) {
            return null;
          }
          return entries.map((e) => '${e.name}=${e.value}').join('&');
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
        model: ClassModel(
          isDeprecated: false,
          context: context,
          properties: const [],
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
        cookieParameters: const {},
        responses: const {},
        securitySchemes: const {},
      );

      const expectedMethod = r'''
        String? _queryParameters({AnonymousModel? filter}) {
          final entries = <ParameterEntry>[];
          if (filter != null) {
            entries.addAll(
              filter.toDeepObject(r'filter', explode: false, allowEmpty: true),
            );
          }
          if (entries.isEmpty) {
            return null;
          }
          return entries.map((e) => '${e.name}=${e.value}').join('&');
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
        cookieParameters: const {},
        responses: const {},
        securitySchemes: const {},
      );

      const expectedMethod = r'''
        String? _queryParameters({List<String>? tags}) {
          final entries = <ParameterEntry>[];
          if (tags != null) {
            for (final value in tags.toSpaceDelimited(
              explode: false,
              allowEmpty: true,
            )) {
              entries.add((name: r'tags', value: value));
            }
          }
          if (entries.isEmpty) {
            return null;
          }
          return entries.map((e) => '${e.name}=${e.value}').join('&');
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
        model: ClassModel(
          isDeprecated: false,
          context: context,
          properties: const [],
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
        cookieParameters: const {},
        responses: const {},
        securitySchemes: const {},
      );

      const expectedMethod = r'''
        String? _queryParameters({AnonymousModel? filter}) {
          final entries = <ParameterEntry>[];
          if (filter != null) {
            entries.addAll(
              filter.toDeepObject(r'filter', explode: false, allowEmpty: true),
            );
          }
          if (entries.isEmpty) {
            return null;
          }
          return entries.map((e) => '${e.name}=${e.value}').join('&');
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
        model: ClassModel(
          isDeprecated: false,
          context: context,
          properties: const [],
        ),
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
        encoding: QueryParameterEncoding.pipeDelimited,
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
        queryParameters: {filterParam, tagsParam, sortParam},
        pathParameters: const {},
        cookieParameters: const {},
        responses: const {},
        securitySchemes: const {},
      );

      const expectedMethod = r'''
        String? _queryParameters({
          AnonymousModel? filter,
          List<String>? tags,
          List<String>? sort,
        }) {
          final entries = <ParameterEntry>[];
          if (filter != null) {
            entries.addAll(
              filter.toDeepObject(r'filter', explode: false, allowEmpty: true),
            );
          }
          if (tags != null) {
            for (final value in tags.toSpaceDelimited(
              explode: false,
              allowEmpty: true,
            )) {
              entries.add((name: r'tags', value: value));
            }
          }
          if (sort != null) {
            for (final value in sort.toPipeDelimited(
              explode: false,
              allowEmpty: true,
            )) {
              entries.add((name: r'sort', value: value));
            }
          }
          if (entries.isEmpty) {
            return null;
          }
          return entries.map((e) => '${e.name}=${e.value}').join('&');
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
        model: ClassModel(
          isDeprecated: false,
          context: context,
          properties: const [],
        ),
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
        cookieParameters: const {},
        responses: const {},
        securitySchemes: const {},
      );

      const expectedMethod = r'''
        String? _queryParameters({AnonymousModel? filter, List<String>? tags}) {
          final entries = <ParameterEntry>[];
          if (filter != null) {
            entries.add((
              name: r'filter',
              value: filter.toForm(explode: true, allowEmpty: true),
            ));
          }
          if (tags != null) {
            for (final value in tags.toSpaceDelimited(
              explode: true,
              allowEmpty: true,
            )) {
              entries.add((name: r'tags', value: value));
            }
          }
          if (entries.isEmpty) {
            return null;
          }
          return entries.map((e) => '${e.name}=${e.value}').join('&');
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
        model: ClassModel(
          isDeprecated: false,
          context: context,
          properties: const [],
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
        queryParameters: {filterParam},
        pathParameters: const {},
        cookieParameters: const {},
        responses: const {},
        securitySchemes: const {},
      );

      const expectedMethod = r'''
        String? _queryParameters({required AnonymousModel filter}) {
          final entries = <ParameterEntry>[];
          entries.add((
            name: r'filter',
            value: filter.toForm(explode: false, allowEmpty: false),
          ));
          if (entries.isEmpty) {
            return null;
          }
          return entries.map((e) => '${e.name}=${e.value}').join('&');
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
        model: ClassModel(
          isDeprecated: false,
          context: context,
          properties: const [],
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
        queryParameters: {filterParam},
        pathParameters: const {},
        cookieParameters: const {},
        responses: const {},
        securitySchemes: const {},
      );

      const expectedMethod = r'''
        String? _queryParameters({AnonymousModel? filter}) {
          final entries = <ParameterEntry>[];
          if (filter != null) {
            entries.add((
              name: r'filter',
              value: filter.toForm(explode: false, allowEmpty: false),
            ));
          }
          if (entries.isEmpty) {
            return null;
          }
          return entries.map((e) => '${e.name}=${e.value}').join('&');
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
        cookieParameters: const {},
        responses: const {},
        securitySchemes: const {},
      );

      const expectedMethod = r'''
        String? _queryParameters({
          String? name,
          List<String>? tags,
          int? age,
          bool? active,
        }) {
          final entries = <ParameterEntry>[];
          if (name != null) {
            entries.add((
              name: r'name',
              value: name.toForm(explode: false, allowEmpty: false),
            ));
          }
          if (tags != null) {
            entries.add((
              name: r'tags',
              value: tags.toForm(explode: false, allowEmpty: false),
            ));
          }
          if (age != null) {
            entries.add((
              name: r'age',
              value: age.toForm(explode: false, allowEmpty: false),
            ));
          }
          if (active != null) {
            entries.add((
              name: r'active',
              value: active.toForm(explode: false, allowEmpty: false),
            ));
          }
          if (entries.isEmpty) {
            return null;
          }
          return entries.map((e) => '${e.name}=${e.value}').join('&');
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
        model: ClassModel(
          isDeprecated: false,
          context: context,
          properties: const [],
        ),
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
        model: ClassModel(
          isDeprecated: false,
          context: context,
          properties: const [],
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
        queryParameters: {classWithStringParam, classWithNumberParam},
        pathParameters: const {},
        cookieParameters: const {},
        responses: const {},
        securitySchemes: const {},
      );

      const expectedMethod = r'''
        String? _queryParameters({AnonymousModel? filter, AnonymousModel2? range}) {
          final entries = <ParameterEntry>[];
          if (filter != null) {
            entries.add((
              name: r'filter',
              value: filter.toForm(explode: false, allowEmpty: false),
            ));
          }
          if (range != null) {
            entries.add((
              name: r'range',
              value: range.toForm(explode: false, allowEmpty: false),
            ));
          }
          if (entries.isEmpty) {
            return null;
          }
          return entries.map((e) => '${e.name}=${e.value}').join('&');
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
        isDeprecated: false,
        context: context,
        values: {
          const EnumEntry(value: 'red'),
          const EnumEntry(value: 'green'),
          const EnumEntry(value: 'blue'),
        },
        isNullable: false,
      );

      final stringModel = StringModel(context: context);
      final integerModel = IntegerModel(context: context);

      final oneOfModel = OneOfModel(
        isDeprecated: false,
        context: context,
        models: {
          (discriminatorValue: 'string', model: stringModel),
          (discriminatorValue: 'integer', model: integerModel),
        },
        name: 'OneOfValue',
        discriminator: 'type',
      );

      final intListModel = ListModel(
        context: context,
        content: IntegerModel(context: context),
      );

      final enumListModel = ListModel(
        context: context,
        content: EnumModel(
          isDeprecated: false,
          context: context,
          values: {
            const EnumEntry(value: 'A'),
            const EnumEntry(value: 'B'),
            const EnumEntry(value: 'C'),
          },
          isNullable: false,
        ),
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

      final intListParam = QueryParameterObject(
        name: 'ids',
        rawName: 'ids',
        description: 'ID list',
        isRequired: false,
        isDeprecated: false,
        allowEmptyValue: true,
        explode: false,
        encoding: QueryParameterEncoding.spaceDelimited,
        allowReserved: false,
        model: intListModel,
        context: context,
      );

      final enumListParam = QueryParameterObject(
        name: 'categories',
        rawName: 'categories',
        description: 'Category list',
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: true,
        explode: false,
        encoding: QueryParameterEncoding.pipeDelimited,
        allowReserved: false,
        model: enumListModel,
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
        queryParameters: {enumParam, oneOfParam, intListParam, enumListParam},
        pathParameters: const {},
        cookieParameters: const {},
        responses: const {},
        securitySchemes: const {},
      );

      const expectedMethod = r'''
        String? _queryParameters({
          AnonymousModel? color,
          required OneOfValue value,
          List<int>? ids,
          required List<AnonymousModel2> categories,
        }) {
          final entries = <ParameterEntry>[];
          if (color != null) {
            entries.add((
              name: r'color',
              value: color.toForm(explode: false, allowEmpty: true),
            ));
          }
          entries.addAll(
            value.toDeepObject(r'value', explode: false, allowEmpty: true),
          );
          if (ids != null) {
            for (final value in ids
                .map((e) => e.uriEncode(allowEmpty: true, useQueryComponent: true))
                .toList()
                .toSpaceDelimited(
              explode: false,
              allowEmpty: true,
                  alreadyEncoded: true,
                )) {
              entries.add((name: r'ids', value: value));
            }
          }
          for (final value in categories
              .map((e) => e.uriEncode(allowEmpty: true, useQueryComponent: true))
              .toList()
              .toPipeDelimited(
            explode: false,
            allowEmpty: true,
                alreadyEncoded: true,
          )) {
            entries.add((name: r'categories', value: value));
          }
          if (entries.isEmpty) {
            return null;
          }
          return entries.map((e) => '${e.name}=${e.value}').join('&');
        }
      ''';

      final queryParameters =
          <({String normalizedName, QueryParameterObject parameter})>[
            (normalizedName: 'color', parameter: enumParam),
            (normalizedName: 'value', parameter: oneOfParam),
            (normalizedName: 'ids', parameter: intListParam),
            (normalizedName: 'categories', parameter: enumListParam),
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

    test('handles simple list of enums', () {
      final enumModel = EnumModel(
        isDeprecated: false,
        context: context,
        values: {
          const EnumEntry(value: 'RED'),
          const EnumEntry(value: 'GREEN'),
          const EnumEntry(value: 'BLUE'),
        },
        isNullable: false,
      );

      final listModel = ListModel(context: context, content: enumModel);

      final queryParam = QueryParameterObject(
        name: 'colors',
        rawName: 'colors',
        description: 'List of colors',
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: true,
        encoding: QueryParameterEncoding.form,
        allowReserved: false,
        model: listModel,
        context: context,
      );

      final operation = Operation(
        operationId: 'listColors',
        context: context,
        summary: 'List colors',
        description: 'Lists all colors',
        tags: const {},
        isDeprecated: false,
        path: '/colors',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: {queryParam},
        pathParameters: const {},
        cookieParameters: const {},
        responses: const {},
        securitySchemes: const {},
      );

      const expectedMethod = r'''
         String? _queryParameters({required List<AnonymousModel> colors}) {
            final entries = <ParameterEntry>[];
            entries.addAll(
              colors.map(
                (e) => (name: r'colors', value: e.toForm(explode: true, allowEmpty: false)),
              ),
            );
            if (entries.isEmpty) {
              return null;
            }
            return entries.map((e) => '${e.name}=${e.value}').join('&');
          }
        ''';

      final queryParameters =
          <({String normalizedName, QueryParameterObject parameter})>[
            (normalizedName: 'colors', parameter: queryParam),
          ];

      final method = generator.generateQueryParametersMethod(
        operation,
        queryParameters,
      );

      expect(method, isA<Method>());
      expect(method.optionalParameters.first.named, isTrue);
      expect(method.optionalParameters.first.required, isTrue);
      expect(
        collapseWhitespace(format(method.accept(emitter).toString())),
        collapseWhitespace(expectedMethod),
      );
    });

    test('generates code that throws for nested list of class models', () {
      final innerModel = ClassModel(
        isDeprecated: false,
        context: context,
        properties: const [],
      );
      final innerListModel = ListModel(context: context, content: innerModel);
      final outerListModel = ListModel(
        context: context,
        content: innerListModel,
      );

      final queryParam = QueryParameterObject(
        name: 'matrix',
        rawName: 'matrix',
        description: 'Matrix of items',
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: true,
        encoding: QueryParameterEncoding.form,
        allowReserved: false,
        model: outerListModel,
        context: context,
      );

      final operation = Operation(
        operationId: 'getMatrix',
        context: context,
        summary: 'Get matrix',
        description: 'Gets matrix data',
        tags: const {},
        isDeprecated: false,
        path: '/data',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: {queryParam},
        pathParameters: const {},
        cookieParameters: const {},
        responses: const {},
        securitySchemes: const {},
      );

      final queryParameters =
          <({String normalizedName, QueryParameterObject parameter})>[
            (normalizedName: 'matrix', parameter: queryParam),
          ];

      const expectedMethod = r'''
          String? _queryParameters({required List<List<AnonymousModel>> matrix}) {
            final entries = <ParameterEntry>[];
            if (matrix.isNotEmpty) {
              throw EncodingException(
                'Form encoding only supports lists of simple types',
              );
            }
            if (entries.isEmpty) {
              return null;
            }
            return entries.map((e) => '${e.name}=${e.value}').join('&');
          }
        ''';

      final method = generator.generateQueryParametersMethod(
        operation,
        queryParameters,
      );

      expect(method, isA<Method>());
      expect(method.optionalParameters.first.named, isTrue);
      expect(method.optionalParameters.first.required, isTrue);
      expect(
        collapseWhitespace(format(method.accept(emitter).toString())),
        collapseWhitespace(expectedMethod),
      );
    });

    test(
      'generates code that throws when non-list type used with '
      'delimited encoding',
      () {
        final stringModel = StringModel(context: context);

        final stringParam = QueryParameterObject(
          name: 'name',
          rawName: 'name',
          description: 'Name parameter',
          isRequired: true,
          isDeprecated: false,
          allowEmptyValue: false,
          explode: false,
          encoding: QueryParameterEncoding.spaceDelimited,
          allowReserved: false,
          model: stringModel,
          context: context,
        );

        final operation = Operation(
          operationId: 'getData',
          context: context,
          summary: 'Get data',
          description: 'Gets data',
          tags: const {},
          isDeprecated: false,
          path: '/data',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: {stringParam},
          pathParameters: const {},
          cookieParameters: const {},
          responses: const {},
          securitySchemes: const {},
        );

        const expectedMethod = r'''
          String? _queryParameters({required String name}) {
            final entries = <ParameterEntry>[];
            throw EncodingException(
              r'Parameter name: spaceDelimited encoding only supports list types',
            );
            if (entries.isEmpty) {
              return null;
            }
            return entries.map((e) => '${e.name}=${e.value}').join('&');
          }
        ''';

        final queryParameters =
            <({String normalizedName, QueryParameterObject parameter})>[
              (normalizedName: 'name', parameter: stringParam),
            ];

        final method = generator.generateQueryParametersMethod(
          operation,
          queryParameters,
        );

        expect(method, isA<Method>());
        expect(method.optionalParameters.first.named, isTrue);
        expect(method.optionalParameters.first.required, isTrue);
        expect(
          collapseWhitespace(format(method.accept(emitter).toString())),
          collapseWhitespace(expectedMethod),
        );
      },
    );

    test(
      'generates code for list of oneOf with mixed types requiring '
      'runtime check',
      () {
        final stringModel = StringModel(context: context);
        final classModel = ClassModel(
          isDeprecated: false,
          context: context,
          properties: const [],
        );

        final oneOfModel = OneOfModel(
          isDeprecated: false,
          context: context,
          models: {
            (discriminatorValue: 'string', model: stringModel),
            (discriminatorValue: 'object', model: classModel),
          },
          name: 'MixedOneOf',
          discriminator: 'type',
        );

        final oneOfListModel = ListModel(
          context: context,
          content: oneOfModel,
        );

        final oneOfListParam = QueryParameterObject(
          name: 'values',
          rawName: 'values',
          description: 'Value list',
          isRequired: true,
          isDeprecated: false,
          allowEmptyValue: false,
          explode: false,
          encoding: QueryParameterEncoding.pipeDelimited,
          allowReserved: false,
          model: oneOfListModel,
          context: context,
        );

        final operation = Operation(
          operationId: 'getValues',
          context: context,
          summary: 'Get values',
          description: 'Gets values',
          tags: const {},
          isDeprecated: false,
          path: '/data',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: {oneOfListParam},
          pathParameters: const {},
          cookieParameters: const {},
          responses: const {},
          securitySchemes: const {},
        );

        const expectedMethod = r'''
           String? _queryParameters({required List<MixedOneOf> values}) {
             final entries = <ParameterEntry>[];
             for (final item in values) {
               if (item.currentEncodingShape != EncodingShape.simple) {
                 throw EncodingException(
                   r'Parameter values: pipeDelimited encoding requires simple encoding shape',
                 );
               }
             }
             for (final value in values
                 .map((item) => item.uriEncode(allowEmpty: false))
                 .toList()
                 .toPipeDelimited(
                   explode: false,
                   allowEmpty: false,
                   alreadyEncoded: true,
                 )) {
               entries.add((name: r'values', value: value));
             }
             if (entries.isEmpty) {
               return null;
             }
             return entries.map((e) => '${e.name}=${e.value}').join('&');
           }
         ''';

        final queryParameters =
            <({String normalizedName, QueryParameterObject parameter})>[
              (normalizedName: 'values', parameter: oneOfListParam),
            ];

        final method = generator.generateQueryParametersMethod(
          operation,
          queryParameters,
        );

        expect(method, isA<Method>());
        expect(method.optionalParameters.first.named, isTrue);
        expect(method.optionalParameters.first.required, isTrue);
        expect(
          collapseWhitespace(format(method.accept(emitter).toString())),
          collapseWhitespace(expectedMethod),
        );
      },
    );

    test(
      'generates code for list of oneOf with explode=true',
      () {
        final stringModel = StringModel(context: context);
        final intModel = IntegerModel(context: context);

        final oneOfModel = OneOfModel(
          isDeprecated: false,
          context: context,
          models: {
            (discriminatorValue: 'string', model: stringModel),
            (discriminatorValue: 'int', model: intModel),
          },
          name: 'SimpleOneOf',
          discriminator: 'type',
        );

        final oneOfListModel = ListModel(
          context: context,
          content: oneOfModel,
        );

        final oneOfListParam = QueryParameterObject(
          name: 'items',
          rawName: 'items',
          description: 'Item list',
          isRequired: true,
          isDeprecated: false,
          allowEmptyValue: false,
          explode: true,
          encoding: QueryParameterEncoding.spaceDelimited,
          allowReserved: false,
          model: oneOfListModel,
          context: context,
        );

        final operation = Operation(
          operationId: 'getItems',
          context: context,
          summary: 'Get items',
          description: 'Gets items',
          tags: const {},
          isDeprecated: false,
          path: '/data',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: {oneOfListParam},
          pathParameters: const {},
          cookieParameters: const {},
          responses: const {},
          securitySchemes: const {},
        );

        const expectedMethod = r'''
           String? _queryParameters({required List<SimpleOneOf> items}) {
             final entries = <ParameterEntry>[];
             for (final item in items) {
               if (item.currentEncodingShape != EncodingShape.simple) {
                 throw EncodingException(
                   r'Parameter items: spaceDelimited encoding requires simple encoding shape',
                 );
               }
               entries.add((name: r'items', value: item.uriEncode(allowEmpty: false)));
             }
             if (entries.isEmpty) {
               return null;
             }
             return entries.map((e) => '${e.name}=${e.value}').join('&');
           }
         ''';

        final queryParameters =
            <({String normalizedName, QueryParameterObject parameter})>[
              (normalizedName: 'items', parameter: oneOfListParam),
            ];

        final method = generator.generateQueryParametersMethod(
          operation,
          queryParameters,
        );

        expect(method, isA<Method>());
        expect(method.optionalParameters.first.named, isTrue);
        expect(method.optionalParameters.first.required, isTrue);
        expect(
          collapseWhitespace(format(method.accept(emitter).toString())),
          collapseWhitespace(expectedMethod),
        );
      },
    );

    test(
      'generates code that throws when list of class models used with '
      'delimited encoding',
      () {
        final classModel = ClassModel(
          isDeprecated: false,
          context: context,
          properties: const [],
        );
        final classListModel = ListModel(
          context: context,
          content: classModel,
        );

        final classListParam = QueryParameterObject(
          name: 'filters',
          rawName: 'filters',
          description: 'Filter list',
          isRequired: true,
          isDeprecated: false,
          allowEmptyValue: false,
          explode: false,
          encoding: QueryParameterEncoding.spaceDelimited,
          allowReserved: false,
          model: classListModel,
          context: context,
        );

        final operation = Operation(
          operationId: 'getFiltered',
          context: context,
          summary: 'Get filtered',
          description: 'Gets filtered data',
          tags: const {},
          isDeprecated: false,
          path: '/data',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: {classListParam},
          pathParameters: const {},
          cookieParameters: const {},
          responses: const {},
          securitySchemes: const {},
        );

        const expectedMethod = r'''
          String? _queryParameters({required List<AnonymousModel> filters}) {
            final entries = <ParameterEntry>[];
            throw EncodingException(
              r'Parameter filters: spaceDelimited encoding does not support list content type',
            );
            if (entries.isEmpty) {
              return null;
            }
            return entries.map((e) => '${e.name}=${e.value}').join('&');
          }
        ''';

        final queryParameters =
            <({String normalizedName, QueryParameterObject parameter})>[
              (normalizedName: 'filters', parameter: classListParam),
            ];

        final method = generator.generateQueryParametersMethod(
          operation,
          queryParameters,
        );

        expect(method, isA<Method>());
        expect(method.optionalParameters.first.named, isTrue);
        expect(method.optionalParameters.first.required, isTrue);
        expect(
          collapseWhitespace(format(method.accept(emitter).toString())),
          collapseWhitespace(expectedMethod),
        );
      },
    );

    test('handles parameter names that are Dart keywords', () {
      final parameter = QueryParameterObject(
        name: r'$class',
        rawName: 'class',
        model: ListModel(
          content: StringModel(context: context),
          context: context,
        ),
        isRequired: true,
        isDeprecated: false,
        description: null,
        explode: false,
        allowEmptyValue: false,
        encoding: QueryParameterEncoding.spaceDelimited,
        allowReserved: false,
        context: context,
      );

      final operation = Operation(
        operationId: 'getData',
        context: context,
        summary: 'Get data',
        description: 'Gets data by class',
        tags: const {},
        isDeprecated: false,
        path: '/data',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: {parameter},
        pathParameters: const {},
        cookieParameters: const {},
        responses: const {},
        securitySchemes: const {},
      );

      const expectedMethod = r'''
        String? _queryParameters({required List<String> $class}) {
          final entries = <ParameterEntry>[];
          for (final value in $class.toSpaceDelimited(
            explode: false,
            allowEmpty: false,
          )) {
            entries.add((name: r'class', value: value));
          }
          if (entries.isEmpty) {
            return null;
          }
          return entries.map((e) => '${e.name}=${e.value}').join('&');
        }
      ''';

      final queryParameters =
          <({String normalizedName, QueryParameterObject parameter})>[
            (normalizedName: r'$class', parameter: parameter),
          ];

      final method = generator.generateQueryParametersMethod(
        operation,
        queryParameters,
      );

      expect(method, isA<Method>());
      expect(method.optionalParameters.first.name, r'$class');
      expect(method.optionalParameters.first.named, isTrue);
      expect(method.optionalParameters.first.required, isTrue);
      expect(
        collapseWhitespace(format(method.accept(emitter).toString())),
        collapseWhitespace(expectedMethod),
      );
    });

    test('handles enum parameter names that are Dart keywords', () {
      final parameter = QueryParameterObject(
        name: r'$enum',
        rawName: 'enum',
        model: ListModel(
          content: EnumModel(
            isDeprecated: false,
            values: {
              const EnumEntry(value: 'a'),
              const EnumEntry(value: 'b'),
            },
            isNullable: false,
            context: context,
          ),
          context: context,
        ),
        isRequired: true,
        isDeprecated: false,
        description: null,
        explode: false,
        allowEmptyValue: false,
        encoding: QueryParameterEncoding.pipeDelimited,
        allowReserved: false,
        context: context,
      );

      final operation = Operation(
        operationId: 'getData',
        context: context,
        summary: 'Get data',
        description: 'Gets data by enum',
        tags: const {},
        isDeprecated: false,
        path: '/data',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: {parameter},
        pathParameters: const {},
        cookieParameters: const {},
        responses: const {},
        securitySchemes: const {},
      );

      const expectedMethod = r'''
        String? _queryParameters({required List<AnonymousModel> $enum}) {
          final entries = <ParameterEntry>[];
          for (final value in $enum
              .map((e) => e.uriEncode(allowEmpty: false, useQueryComponent: true))
              .toList()
              .toPipeDelimited(
                explode: false,
                allowEmpty: false,
                alreadyEncoded: true,
              )) {
            entries.add((name: r'enum', value: value));
          }
          if (entries.isEmpty) {
            return null;
          }
          return entries.map((e) => '${e.name}=${e.value}').join('&');
        }
      ''';

      final queryParameters =
          <({String normalizedName, QueryParameterObject parameter})>[
            (normalizedName: r'$enum', parameter: parameter),
          ];

      final method = generator.generateQueryParametersMethod(
        operation,
        queryParameters,
      );

      expect(method, isA<Method>());
      expect(method.optionalParameters.first.name, r'$enum');
      expect(method.optionalParameters.first.named, isTrue);
      expect(method.optionalParameters.first.required, isTrue);
      expect(
        collapseWhitespace(format(method.accept(emitter).toString())),
        collapseWhitespace(expectedMethod),
      );
    });

    test('uses raw name in error messages for keyword parameters', () {
      final parameter = QueryParameterObject(
        name: r'$class',
        rawName: 'class',
        model: StringModel(context: context),
        isRequired: true,
        isDeprecated: false,
        description: null,
        explode: false,
        allowEmptyValue: false,
        encoding: QueryParameterEncoding.spaceDelimited,
        allowReserved: false,
        context: context,
      );

      final operation = Operation(
        operationId: 'getData',
        context: context,
        summary: 'Get data',
        description: 'Gets data',
        tags: const {},
        isDeprecated: false,
        path: '/data',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: {parameter},
        pathParameters: const {},
        cookieParameters: const {},
        responses: const {},
        securitySchemes: const {},
      );

      const expectedMethod = r'''
        String? _queryParameters({required String $class}) {
          final entries = <ParameterEntry>[];
          throw EncodingException(
            r'Parameter $class: spaceDelimited encoding only supports list types',
          );
          if (entries.isEmpty) {
            return null;
          }
          return entries.map((e) => '${e.name}=${e.value}').join('&');
        }
      ''';

      final queryParameters =
          <({String normalizedName, QueryParameterObject parameter})>[
            (normalizedName: r'$class', parameter: parameter),
          ];

      final method = generator.generateQueryParametersMethod(
        operation,
        queryParameters,
      );

      expect(method, isA<Method>());
      expect(method.optionalParameters.first.name, r'$class');
      expect(
        collapseWhitespace(format(method.accept(emitter).toString())),
        collapseWhitespace(expectedMethod),
      );
    });

    test('uses raw name in error messages for unsupported list content', () {
      final parameter = QueryParameterObject(
        name: r'$void',
        rawName: 'void',
        model: ListModel(
          content: ClassModel(
            isDeprecated: false,
            name: 'SomeClass',
            properties: const [],
            context: context,
          ),
          context: context,
        ),
        isRequired: true,
        isDeprecated: false,
        description: null,
        explode: false,
        allowEmptyValue: false,
        encoding: QueryParameterEncoding.pipeDelimited,
        allowReserved: false,
        context: context,
      );

      final operation = Operation(
        operationId: 'getData',
        context: context,
        summary: 'Get data',
        description: 'Gets data',
        tags: const {},
        isDeprecated: false,
        path: '/data',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: {parameter},
        pathParameters: const {},
        cookieParameters: const {},
        responses: const {},
        securitySchemes: const {},
      );

      const expectedMethod = r'''
        String? _queryParameters({required List<SomeClass> $void}) {
          final entries = <ParameterEntry>[];
          throw EncodingException(
            r'Parameter $void: pipeDelimited encoding does not support list content type',
          );
          if (entries.isEmpty) {
            return null;
          }
          return entries.map((e) => '${e.name}=${e.value}').join('&');
        }
      ''';

      final queryParameters =
          <({String normalizedName, QueryParameterObject parameter})>[
            (normalizedName: r'$void', parameter: parameter),
          ];

      final method = generator.generateQueryParametersMethod(
        operation,
        queryParameters,
      );

      expect(method, isA<Method>());
      expect(method.optionalParameters.first.name, r'$void');
      expect(
        collapseWhitespace(format(method.accept(emitter).toString())),
        collapseWhitespace(expectedMethod),
      );
    });

    test('handles raw names with special characters like dollar signs', () {
      final parameter = QueryParameterObject(
        name: r'$price',
        rawName: r'$price',
        model: ListModel(
          content: StringModel(context: context),
          context: context,
        ),
        isRequired: true,
        isDeprecated: false,
        description: null,
        explode: false,
        allowEmptyValue: false,
        encoding: QueryParameterEncoding.spaceDelimited,
        allowReserved: false,
        context: context,
      );

      final operation = Operation(
        operationId: 'getData',
        context: context,
        summary: 'Get data',
        description: 'Gets data with price',
        tags: const {},
        isDeprecated: false,
        path: '/data',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: {parameter},
        pathParameters: const {},
        cookieParameters: const {},
        responses: const {},
        securitySchemes: const {},
      );

      const expectedMethod = r'''
        String? _queryParameters({required List<String> $price}) {
          final entries = <ParameterEntry>[];
          for (final value in $price.toSpaceDelimited(
            explode: false,
            allowEmpty: false,
          )) {
            entries.add((name: r'$price', value: value));
          }
          if (entries.isEmpty) {
            return null;
          }
          return entries.map((e) => '${e.name}=${e.value}').join('&');
        }
      ''';

      final queryParameters =
          <({String normalizedName, QueryParameterObject parameter})>[
            (normalizedName: r'$price', parameter: parameter),
          ];

      final method = generator.generateQueryParametersMethod(
        operation,
        queryParameters,
      );

      expect(method, isA<Method>());
      expect(method.optionalParameters.first.name, r'$price');
      expect(
        collapseWhitespace(format(method.accept(emitter).toString())),
        collapseWhitespace(expectedMethod),
      );
    });
  });
}
