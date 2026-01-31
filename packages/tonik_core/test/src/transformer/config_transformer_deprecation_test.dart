import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';

void main() {
  const transformer = ConfigTransformer();

  group('ConfigTransformer/deprecation/operations', () {
    late Context ctx;
    late Tag tag;
    late Operation deprecatedOp;
    late Operation nonDeprecatedOp;
    late ApiDocument document;

    setUp(() {
      ctx = Context.initial();
      tag = Tag(name: 'test', description: 'Test tag');

      deprecatedOp = Operation(
        operationId: 'deprecatedOp',
        context: ctx.push('paths').push('/deprecated').push('get'),
        path: '/deprecated',
        method: HttpMethod.get,
        tags: {tag},
        isDeprecated: true,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: const {},
        responses: const {},
        securitySchemes: const {},
      );

      nonDeprecatedOp = Operation(
        operationId: 'normalOp',
        context: ctx.push('paths').push('/normal').push('get'),
        path: '/normal',
        method: HttpMethod.get,
        tags: {tag},
        isDeprecated: false,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: const {},
        responses: const {},
        securitySchemes: const {},
      );

      document = ApiDocument(
        title: 'Test API',
        version: '1.0.0',
        models: const {},
        responseHeaders: const {},
        requestHeaders: const {},
        servers: const {},
        operations: {deprecatedOp, nonDeprecatedOp},
        responses: const {},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: const {},
        requestBodies: const {},
      );
    });

    test('annotate mode keeps all operations unchanged', () {
      const config = TonikConfig();
      final result = transformer.apply(document, config);

      expect(result.operations, hasLength(2));
      expect(result.operations.contains(deprecatedOp), isTrue);
      expect(result.operations.contains(nonDeprecatedOp), isTrue);

      // Verify identity is preserved
      expect(identical(result.operations, document.operations), isTrue);

      // Verify deprecated status is preserved
      final deprecatedResult = result.operations.firstWhere(
        (op) => op.operationId == 'deprecatedOp',
      );
      expect(deprecatedResult.isDeprecated, isTrue);
      expect(identical(deprecatedResult, deprecatedOp), isTrue);

      final normalResult = result.operations.firstWhere(
        (op) => op.operationId == 'normalOp',
      );
      expect(normalResult.isDeprecated, isFalse);
      expect(identical(normalResult, nonDeprecatedOp), isTrue);
    });

    test('exclude mode removes deprecated operations', () {
      const config = TonikConfig(
        deprecated: DeprecatedConfig(operations: DeprecatedHandling.exclude),
      );

      final result = transformer.apply(document, config);

      expect(result.operations, hasLength(1));
      expect(result.operations.contains(nonDeprecatedOp), isTrue);
      expect(result.operations.contains(deprecatedOp), isFalse);
      expect(identical(result.operations.single, nonDeprecatedOp), isTrue);
    });

    test('ignore mode sets isDeprecated to false for all operations', () {
      const config = TonikConfig(
        deprecated: DeprecatedConfig(operations: DeprecatedHandling.ignore),
      );

      final result = transformer.apply(document, config);

      expect(result.operations, hasLength(2));
      expect(result.operations.contains(deprecatedOp), isTrue);
      expect(result.operations.contains(nonDeprecatedOp), isTrue);

      // Verify identity is preserved but isDeprecated is mutated
      expect(
        identical(
          deprecatedOp,
          result.operations.firstWhere(
            (op) => op.operationId == 'deprecatedOp',
          ),
        ),
        isTrue,
      );
      expect(deprecatedOp.isDeprecated, isFalse);
      expect(nonDeprecatedOp.isDeprecated, isFalse);
    });

    test('default config (annotate) does not modify operations', () {
      const config = TonikConfig();
      final result = transformer.apply(document, config);

      expect(identical(result.operations, document.operations), isTrue);
      expect(deprecatedOp.isDeprecated, isTrue);
      expect(nonDeprecatedOp.isDeprecated, isFalse);
    });

    test('handles empty operations set', () {
      final emptyDoc = ApiDocument(
        title: 'Empty API',
        version: '1.0.0',
        models: const {},
        responseHeaders: const {},
        requestHeaders: const {},
        servers: const {},
        operations: const {},
        responses: const {},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: const {},
        requestBodies: const {},
      );

      const config = TonikConfig(
        deprecated: DeprecatedConfig(operations: DeprecatedHandling.exclude),
      );

      final result = transformer.apply(emptyDoc, config);

      expect(result.operations, isEmpty);
    });

    test('handles operations with no deprecated items in exclude mode', () {
      final onlyNormalDoc = ApiDocument(
        title: 'Test API',
        version: '1.0.0',
        models: const {},
        responseHeaders: const {},
        requestHeaders: const {},
        servers: const {},
        operations: {nonDeprecatedOp},
        responses: const {},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: const {},
        requestBodies: const {},
      );

      const config = TonikConfig(
        deprecated: DeprecatedConfig(operations: DeprecatedHandling.exclude),
      );

      final result = transformer.apply(onlyNormalDoc, config);

      expect(result.operations, hasLength(1));
      expect(result.operations.contains(nonDeprecatedOp), isTrue);
    });
  });

  group('ConfigTransformer/deprecation/schemas', () {
    late Context ctx;
    late ClassModel deprecatedClass;
    late ClassModel nonDeprecatedClass;
    late EnumModel<String> deprecatedEnum;
    late EnumModel<String> nonDeprecatedEnum;
    late ApiDocument document;

    setUp(() {
      ctx = Context.initial();

      deprecatedClass = ClassModel(
        name: 'DeprecatedClass',
        context: ctx.push('components').push('schemas').push('DeprecatedClass'),
        description: 'A deprecated class',
        isDeprecated: true,
        properties: const [],
      );

      nonDeprecatedClass = ClassModel(
        name: 'NormalClass',
        context: ctx.push('components').push('schemas').push('NormalClass'),
        description: 'A normal class',
        isDeprecated: false,
        properties: const [],
      );

      deprecatedEnum = EnumModel<String>(
        name: 'DeprecatedEnum',
        context: ctx.push('components').push('schemas').push('DeprecatedEnum'),
        description: 'A deprecated enum',
        isDeprecated: true,
        isNullable: false,
        values: const {},
      );

      nonDeprecatedEnum = EnumModel<String>(
        name: 'NormalEnum',
        context: ctx.push('components').push('schemas').push('NormalEnum'),
        description: 'A normal enum',
        isDeprecated: false,
        isNullable: false,
        values: const {},
      );

      document = ApiDocument(
        title: 'Test API',
        version: '1.0.0',
        models: {
          deprecatedClass,
          nonDeprecatedClass,
          deprecatedEnum,
          nonDeprecatedEnum,
        },
        responseHeaders: const {},
        requestHeaders: const {},
        servers: const {},
        operations: const {},
        responses: const {},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: const {},
        requestBodies: const {},
      );
    });

    test('annotate mode keeps all schemas unchanged', () {
      const config = TonikConfig();
      final result = transformer.apply(document, config);

      expect(result.models, hasLength(4));
      expect(result.models.contains(deprecatedClass), isTrue);
      expect(result.models.contains(nonDeprecatedClass), isTrue);
      expect(result.models.contains(deprecatedEnum), isTrue);
      expect(result.models.contains(nonDeprecatedEnum), isTrue);

      // Verify identity is preserved
      expect(identical(result.models, document.models), isTrue);

      // Verify deprecated status is preserved
      expect(deprecatedClass.isDeprecated, isTrue);
      expect(deprecatedEnum.isDeprecated, isTrue);
      expect(nonDeprecatedClass.isDeprecated, isFalse);
      expect(nonDeprecatedEnum.isDeprecated, isFalse);
    });

    test('exclude mode removes deprecated schemas', () {
      const config = TonikConfig(
        deprecated: DeprecatedConfig(schemas: DeprecatedHandling.exclude),
      );

      final result = transformer.apply(document, config);

      expect(result.models, hasLength(2));
      expect(result.models.contains(nonDeprecatedClass), isTrue);
      expect(result.models.contains(nonDeprecatedEnum), isTrue);
      expect(result.models.contains(deprecatedClass), isFalse);
      expect(result.models.contains(deprecatedEnum), isFalse);
    });

    test('ignore mode sets isDeprecated to false for all schemas', () {
      const config = TonikConfig(
        deprecated: DeprecatedConfig(schemas: DeprecatedHandling.ignore),
      );

      final result = transformer.apply(document, config);

      expect(result.models, hasLength(4));
      expect(result.models.contains(deprecatedClass), isTrue);
      expect(result.models.contains(nonDeprecatedClass), isTrue);
      expect(result.models.contains(deprecatedEnum), isTrue);
      expect(result.models.contains(nonDeprecatedEnum), isTrue);

      // Verify identity is preserved but isDeprecated is mutated
      expect(deprecatedClass.isDeprecated, isFalse);
      expect(deprecatedEnum.isDeprecated, isFalse);
      expect(nonDeprecatedClass.isDeprecated, isFalse);
      expect(nonDeprecatedEnum.isDeprecated, isFalse);
    });

    test('default config (annotate) does not modify schemas', () {
      const config = TonikConfig();
      final result = transformer.apply(document, config);

      expect(identical(result.models, document.models), isTrue);
      expect(deprecatedClass.isDeprecated, isTrue);
      expect(deprecatedEnum.isDeprecated, isTrue);
      expect(nonDeprecatedClass.isDeprecated, isFalse);
      expect(nonDeprecatedEnum.isDeprecated, isFalse);
    });

    test('handles composite models', () {
      final allOfModel = AllOfModel(
        context: ctx.push('components').push('schemas').push('Combined'),
        description: 'A composite model',
        isDeprecated: true,
        models: {nonDeprecatedClass},
      );

      final docWithComposite = ApiDocument(
        title: 'Test API',
        version: '1.0.0',
        models: {allOfModel, nonDeprecatedClass},
        responseHeaders: const {},
        requestHeaders: const {},
        servers: const {},
        operations: const {},
        responses: const {},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: const {},
        requestBodies: const {},
      );

      const config = TonikConfig(
        deprecated: DeprecatedConfig(
          schemas: DeprecatedHandling.exclude,
        ),
      );

      final result = transformer.apply(docWithComposite, config);

      expect(result.models, hasLength(1));
      expect(result.models.contains(nonDeprecatedClass), isTrue);
      expect(result.models.contains(allOfModel), isFalse);
    });

    test('handles independent operation and schema deprecation modes', () {
      final tag = Tag(name: 'test', description: 'Test tag');
      final deprecatedOp = Operation(
        operationId: 'deprecatedOp',
        context: ctx.push('paths').push('/deprecated').push('get'),
        path: '/deprecated',
        method: HttpMethod.get,
        tags: {tag},
        isDeprecated: true,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: const {},
        responses: const {},
        securitySchemes: const {},
      );

      final mixedDoc = ApiDocument(
        title: 'Test API',
        version: '1.0.0',
        models: {deprecatedClass, nonDeprecatedClass},
        responseHeaders: const {},
        requestHeaders: const {},
        servers: const {},
        operations: {deprecatedOp},
        responses: const {},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: const {},
        requestBodies: const {},
      );

      const config = TonikConfig(
        deprecated: DeprecatedConfig(
          operations: DeprecatedHandling.exclude,
          schemas: DeprecatedHandling.ignore,
        ),
      );

      final result = transformer.apply(mixedDoc, config);

      // Operations should be excluded
      expect(result.operations, isEmpty);

      // Schemas should have isDeprecated set to false
      expect(result.models, hasLength(2));
      expect(deprecatedClass.isDeprecated, isFalse);
      expect(nonDeprecatedClass.isDeprecated, isFalse);
    });
  });

  group('ConfigTransformer/deprecation/parameters', () {
    late Context ctx;
    late Tag tag;
    late QueryParameterObject deprecatedQuery;
    late QueryParameterObject normalQuery;
    late PathParameterObject deprecatedPath;
    late PathParameterObject normalPath;
    late RequestHeaderObject deprecatedHeader;
    late RequestHeaderObject normalHeader;
    late Operation operation;
    late ApiDocument document;

    setUp(() {
      ctx = Context.initial();
      tag = Tag(name: 'test', description: 'Test tag');

      final stringModel = ClassModel(
        name: 'String',
        context: ctx,
        isDeprecated: false,
        properties: const [],
      );

      deprecatedQuery = QueryParameterObject(
        name: 'deprecatedFilter',
        rawName: 'deprecatedFilter',
        description: 'A deprecated query param',
        isRequired: false,
        isDeprecated: true,
        allowEmptyValue: false,
        allowReserved: false,
        explode: true,
        model: stringModel,
        encoding: QueryParameterEncoding.form,
        context: ctx.push('parameters').push('deprecatedFilter'),
      );

      normalQuery = QueryParameterObject(
        name: 'normalFilter',
        rawName: 'normalFilter',
        description: 'A normal query param',
        isRequired: false,
        isDeprecated: false,
        allowEmptyValue: false,
        allowReserved: false,
        explode: true,
        model: stringModel,
        encoding: QueryParameterEncoding.form,
        context: ctx.push('parameters').push('normalFilter'),
      );

      deprecatedPath = PathParameterObject(
        name: 'deprecatedId',
        rawName: 'deprecatedId',
        description: 'A deprecated path param',
        isRequired: true,
        isDeprecated: true,
        allowEmptyValue: false,
        explode: false,
        model: stringModel,
        encoding: PathParameterEncoding.simple,
        context: ctx.push('parameters').push('deprecatedId'),
      );

      normalPath = PathParameterObject(
        name: 'normalId',
        rawName: 'normalId',
        description: 'A normal path param',
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: false,
        model: stringModel,
        encoding: PathParameterEncoding.simple,
        context: ctx.push('parameters').push('normalId'),
      );

      deprecatedHeader = RequestHeaderObject(
        name: 'X-Deprecated-Header',
        rawName: 'X-Deprecated-Header',
        description: 'A deprecated header',
        isRequired: false,
        isDeprecated: true,
        allowEmptyValue: false,
        explode: false,
        model: stringModel,
        encoding: HeaderParameterEncoding.simple,
        context: ctx.push('headers').push('X-Deprecated-Header'),
      );

      normalHeader = RequestHeaderObject(
        name: 'X-Normal-Header',
        rawName: 'X-Normal-Header',
        description: 'A normal header',
        isRequired: false,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: false,
        model: stringModel,
        encoding: HeaderParameterEncoding.simple,
        context: ctx.push('headers').push('X-Normal-Header'),
      );

      operation = Operation(
        operationId: 'testOp',
        context: ctx.push('paths').push('/test').push('get'),
        path: '/test/{deprecatedId}/{normalId}',
        method: HttpMethod.get,
        tags: {tag},
        isDeprecated: false,
        headers: {deprecatedHeader, normalHeader},
        queryParameters: {deprecatedQuery, normalQuery},
        pathParameters: {deprecatedPath, normalPath},
        cookieParameters: const {},
        responses: const {},
        securitySchemes: const {},
      );

      document = ApiDocument(
        title: 'Test API',
        version: '1.0.0',
        models: const {},
        responseHeaders: const {},
        requestHeaders: const {},
        servers: const {},
        operations: {operation},
        responses: const {},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: const {},
        requestBodies: const {},
      );
    });

    test('annotate mode keeps all parameters unchanged', () {
      const config = TonikConfig();
      final result = transformer.apply(document, config);

      final op = result.operations.single;

      expect(op.queryParameters, hasLength(2));
      expect(deprecatedQuery.isDeprecated, isTrue);
      expect(normalQuery.isDeprecated, isFalse);

      expect(op.pathParameters, hasLength(2));
      expect(deprecatedPath.isDeprecated, isTrue);
      expect(normalPath.isDeprecated, isFalse);

      expect(op.headers, hasLength(2));
      expect(deprecatedHeader.isDeprecated, isTrue);
      expect(normalHeader.isDeprecated, isFalse);
    });

    test('exclude mode removes deprecated parameters', () {
      const config = TonikConfig(
        deprecated: DeprecatedConfig(parameters: DeprecatedHandling.exclude),
      );

      final result = transformer.apply(document, config);

      final op = result.operations.single;

      expect(op.queryParameters, hasLength(1));
      expect(op.queryParameters.contains(normalQuery), isTrue);
      expect(op.queryParameters.contains(deprecatedQuery), isFalse);

      expect(op.pathParameters, hasLength(1));
      expect(op.pathParameters.contains(normalPath), isTrue);
      expect(op.pathParameters.contains(deprecatedPath), isFalse);

      expect(op.headers, hasLength(1));
      expect(op.headers.contains(normalHeader), isTrue);
      expect(op.headers.contains(deprecatedHeader), isFalse);
    });

    test('ignore mode sets isDeprecated to false for all parameters', () {
      const config = TonikConfig(
        deprecated: DeprecatedConfig(parameters: DeprecatedHandling.ignore),
      );

      final result = transformer.apply(document, config);

      final op = result.operations.single;

      expect(op.queryParameters, hasLength(2));
      expect(deprecatedQuery.isDeprecated, isFalse);
      expect(normalQuery.isDeprecated, isFalse);

      expect(op.pathParameters, hasLength(2));
      expect(deprecatedPath.isDeprecated, isFalse);
      expect(normalPath.isDeprecated, isFalse);

      expect(op.headers, hasLength(2));
      expect(deprecatedHeader.isDeprecated, isFalse);
      expect(normalHeader.isDeprecated, isFalse);
    });
  });

  group('ConfigTransformer/deprecation/properties', () {
    late Context ctx;
    late ClassModel modelWithDeprecatedProps;
    late ClassModel modelWithoutDeprecatedProps;
    late ApiDocument document;

    setUp(() {
      ctx = Context.initial();

      final stringModel = ClassModel(
        name: 'String',
        context: ctx,
        isDeprecated: false,
        properties: const [],
      );

      final deprecatedProp = Property(
        name: 'deprecatedField',
        model: stringModel,
        isRequired: false,
        isNullable: true,
        isDeprecated: true,
        description: 'A deprecated property',
      );

      final normalProp = Property(
        name: 'normalField',
        model: stringModel,
        isRequired: true,
        isNullable: false,
        isDeprecated: false,
        description: 'A normal property',
      );

      final anotherNormalProp = Property(
        name: 'anotherField',
        model: stringModel,
        isRequired: false,
        isNullable: true,
        isDeprecated: false,
      );

      modelWithDeprecatedProps = ClassModel(
        name: 'ModelWithDeprecated',
        context: ctx
            .push('components')
            .push('schemas')
            .push('ModelWithDeprecated'),
        description: 'Has deprecated properties',
        isDeprecated: false,
        properties: [deprecatedProp, normalProp, anotherNormalProp],
      );

      modelWithoutDeprecatedProps = ClassModel(
        name: 'NormalModel',
        context: ctx.push('components').push('schemas').push('NormalModel'),
        description: 'Only normal properties',
        isDeprecated: false,
        properties: [normalProp],
      );

      document = ApiDocument(
        title: 'Test API',
        version: '1.0.0',
        models: {modelWithDeprecatedProps, modelWithoutDeprecatedProps},
        responseHeaders: const {},
        requestHeaders: const {},
        servers: const {},
        operations: const {},
        responses: const {},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: const {},
        requestBodies: const {},
      );
    });

    test('annotate mode keeps all properties unchanged', () {
      const config = TonikConfig();

      transformer.apply(document, config);

      expect(modelWithDeprecatedProps.properties, hasLength(3));
      expect(modelWithDeprecatedProps.properties[0].isDeprecated, isTrue);
      expect(modelWithDeprecatedProps.properties[1].isDeprecated, isFalse);
      expect(modelWithDeprecatedProps.properties[2].isDeprecated, isFalse);

      expect(modelWithoutDeprecatedProps.properties, hasLength(1));
      expect(modelWithoutDeprecatedProps.properties[0].isDeprecated, isFalse);
    });

    test('exclude mode removes deprecated properties', () {
      const config = TonikConfig(
        deprecated: DeprecatedConfig(properties: DeprecatedHandling.exclude),
      );

      transformer.apply(document, config);

      expect(modelWithDeprecatedProps.properties, hasLength(2));
      expect(
        modelWithDeprecatedProps.properties.any(
          (p) => p.name == 'deprecatedField',
        ),
        isFalse,
      );
      expect(
        modelWithDeprecatedProps.properties.any((p) => p.name == 'normalField'),
        isTrue,
      );
      expect(
        modelWithDeprecatedProps.properties.any(
          (p) => p.name == 'anotherField',
        ),
        isTrue,
      );

      expect(modelWithoutDeprecatedProps.properties, hasLength(1));
    });

    test('ignore mode sets isDeprecated to false for all properties', () {
      const config = TonikConfig(
        deprecated: DeprecatedConfig(properties: DeprecatedHandling.ignore),
      );

      transformer.apply(document, config);

      expect(modelWithDeprecatedProps.properties, hasLength(3));
      for (final prop in modelWithDeprecatedProps.properties) {
        expect(prop.isDeprecated, isFalse);
      }

      expect(modelWithoutDeprecatedProps.properties, hasLength(1));
      expect(modelWithoutDeprecatedProps.properties[0].isDeprecated, isFalse);
    });
  });
}
