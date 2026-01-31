import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/util/operation_parameter_generator.dart';

void main() {
  late NameManager nameManager;
  late NameGenerator nameGenerator;
  late Context context;
  late DartEmitter emitter;

  setUp(() {
    nameGenerator = NameGenerator();
    nameManager = NameManager(generator: nameGenerator);
    context = Context.initial();
    emitter = DartEmitter(useNullSafetySyntax: true);
  });

  group('generateParameters', () {
    test('generates parameters for cookie parameters', () {
      final cookieParam = CookieParameterObject(
        name: 'sessionId',
        rawName: 'session_id',
        description: 'Session identifier',
        isRequired: true,
        isDeprecated: false,
        explode: false,
        model: StringModel(context: context),
        encoding: CookieParameterEncoding.form,
        context: context,
      );

      final operation = Operation(
        operationId: 'testOp',
        context: context,
        tags: const {},
        isDeprecated: false,
        path: '/test',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: {cookieParam},
        responses: const {},
        securitySchemes: const {},
      );

      final parameters = generateParameters(
        operation: operation,
        nameManager: nameManager,
        package: 'package:api/api.dart',
      );

      expect(parameters.length, 1);
      expect(parameters.first.name, 'sessionId');
      expect(parameters.first.required, isTrue);
      expect(parameters.first.named, isTrue);
      expect(
        parameters.first.type?.accept(emitter).toString(),
        'String',
      );
    });

    test('generates optional parameters for optional cookies', () {
      final cookieParam = CookieParameterObject(
        name: 'trackingId',
        rawName: 'tracking_id',
        description: 'Tracking identifier',
        isRequired: false,
        isDeprecated: false,
        explode: false,
        model: StringModel(context: context),
        encoding: CookieParameterEncoding.form,
        context: context,
      );

      final operation = Operation(
        operationId: 'testOp',
        context: context,
        tags: const {},
        isDeprecated: false,
        path: '/test',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: {cookieParam},
        responses: const {},
        securitySchemes: const {},
      );

      final parameters = generateParameters(
        operation: operation,
        nameManager: nameManager,
        package: 'package:api/api.dart',
      );

      expect(parameters.length, 1);
      expect(parameters.first.name, 'trackingId');
      expect(parameters.first.required, isFalse);
      expect(
        parameters.first.type?.accept(emitter).toString(),
        'String?',
      );
    });

    test('adds deprecation annotation for deprecated cookie parameters', () {
      final cookieParam = CookieParameterObject(
        name: 'oldCookie',
        rawName: 'old_cookie',
        description: 'Old cookie',
        isRequired: true,
        isDeprecated: true,
        explode: false,
        model: StringModel(context: context),
        encoding: CookieParameterEncoding.form,
        context: context,
      );

      final operation = Operation(
        operationId: 'testOp',
        context: context,
        tags: const {},
        isDeprecated: false,
        path: '/test',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: {cookieParam},
        responses: const {},
        securitySchemes: const {},
      );

      final parameters = generateParameters(
        operation: operation,
        nameManager: nameManager,
        package: 'package:api/api.dart',
      );

      expect(parameters.length, 1);
      expect(parameters.first.annotations.length, 1);

      // Use object introspection for annotation.
      final annotation = parameters.first.annotations.first;
      expect(annotation, isA<InvokeExpression>());
      final invoke = annotation as InvokeExpression;
      expect(invoke.target, isA<Reference>());
      final ref = invoke.target as Reference;
      expect(ref.symbol, 'Deprecated');
      expect(ref.url, 'dart:core');
    });

    test('normalizes cookie parameter names', () {
      final cookieParam = CookieParameterObject(
        name: null,
        rawName: 'session_id',
        description: 'Session',
        isRequired: true,
        isDeprecated: false,
        explode: false,
        model: StringModel(context: context),
        encoding: CookieParameterEncoding.form,
        context: context,
      );

      final operation = Operation(
        operationId: 'testOp',
        context: context,
        tags: const {},
        isDeprecated: false,
        path: '/test',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: {cookieParam},
        responses: const {},
        securitySchemes: const {},
      );

      final parameters = generateParameters(
        operation: operation,
        nameManager: nameManager,
        package: 'package:api/api.dart',
      );

      // Name should be normalized from 'session_id' to 'sessionId'.
      expect(parameters.first.name, 'sessionId');
    });

    test('generates parameters for integer cookie', () {
      final cookieParam = CookieParameterObject(
        name: 'pageNum',
        rawName: 'page_num',
        description: 'Page number',
        isRequired: true,
        isDeprecated: false,
        explode: false,
        model: IntegerModel(context: context),
        encoding: CookieParameterEncoding.form,
        context: context,
      );

      final operation = Operation(
        operationId: 'testOp',
        context: context,
        tags: const {},
        isDeprecated: false,
        path: '/test',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: {cookieParam},
        responses: const {},
        securitySchemes: const {},
      );

      final parameters = generateParameters(
        operation: operation,
        nameManager: nameManager,
        package: 'package:api/api.dart',
      );

      expect(parameters.length, 1);
      expect(parameters.first.name, 'pageNum');
      expect(
        parameters.first.type?.accept(emitter).toString(),
        'int',
      );
    });

    test('generates parameters for boolean cookie', () {
      final cookieParam = CookieParameterObject(
        name: 'debugMode',
        rawName: 'debug_mode',
        description: 'Debug mode',
        isRequired: false,
        isDeprecated: false,
        explode: false,
        model: BooleanModel(context: context),
        encoding: CookieParameterEncoding.form,
        context: context,
      );

      final operation = Operation(
        operationId: 'testOp',
        context: context,
        tags: const {},
        isDeprecated: false,
        path: '/test',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: {cookieParam},
        responses: const {},
        securitySchemes: const {},
      );

      final parameters = generateParameters(
        operation: operation,
        nameManager: nameManager,
        package: 'package:api/api.dart',
      );

      expect(parameters.length, 1);
      expect(parameters.first.name, 'debugMode');
      expect(
        parameters.first.type?.accept(emitter).toString(),
        'bool?',
      );
    });

    test('adds type suffix when cookie name conflicts with other params', () {
      final pathParam = PathParameterObject(
        name: null,
        rawName: 'id',
        description: null,
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: false,
        model: StringModel(context: context),
        encoding: PathParameterEncoding.simple,
        context: context,
      );

      final cookieParam = CookieParameterObject(
        name: null,
        rawName: 'id',
        description: null,
        isRequired: true,
        isDeprecated: false,
        explode: false,
        model: StringModel(context: context),
        encoding: CookieParameterEncoding.form,
        context: context,
      );

      final operation = Operation(
        operationId: 'testOp',
        context: context,
        tags: const {},
        isDeprecated: false,
        path: '/test/{id}',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: {pathParam},
        cookieParameters: {cookieParam},
        responses: const {},
        securitySchemes: const {},
      );

      final parameters = generateParameters(
        operation: operation,
        nameManager: nameManager,
        package: 'package:api/api.dart',
      );

      expect(parameters.length, 2);

      final paramNames = parameters.map((p) => p.name).toList();
      expect(paramNames, contains('idPath'));
      expect(paramNames, contains('idCookie'));
    });

    test('includes cookies along with other parameter types', () {
      final pathParam = PathParameterObject(
        name: null,
        rawName: 'userId',
        description: null,
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: false,
        model: StringModel(context: context),
        encoding: PathParameterEncoding.simple,
        context: context,
      );

      final queryParam = QueryParameterObject(
        name: null,
        rawName: 'filter',
        description: null,
        isRequired: false,
        isDeprecated: false,
        allowEmptyValue: false,
        allowReserved: false,
        explode: false,
        model: StringModel(context: context),
        encoding: QueryParameterEncoding.form,
        context: context,
      );

      final headerParam = RequestHeaderObject(
        name: null,
        rawName: 'X-Api-Key',
        description: null,
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: false,
        model: StringModel(context: context),
        encoding: HeaderParameterEncoding.simple,
        context: context,
      );

      final cookieParam = CookieParameterObject(
        name: null,
        rawName: 'session_id',
        description: null,
        isRequired: true,
        isDeprecated: false,
        explode: false,
        model: StringModel(context: context),
        encoding: CookieParameterEncoding.form,
        context: context,
      );

      final operation = Operation(
        operationId: 'testOp',
        context: context,
        tags: const {},
        isDeprecated: false,
        path: '/users/{userId}',
        method: HttpMethod.get,
        headers: {headerParam},
        queryParameters: {queryParam},
        pathParameters: {pathParam},
        cookieParameters: {cookieParam},
        responses: const {},
        securitySchemes: const {},
      );

      final parameters = generateParameters(
        operation: operation,
        nameManager: nameManager,
        package: 'package:api/api.dart',
      );

      expect(parameters.length, 4);

      final paramNames = parameters.map((p) => p.name).toList();
      expect(paramNames, contains('userId'));
      expect(paramNames, contains('filter'));
      expect(paramNames, contains('apiKey')); // x- prefix removed.
      expect(paramNames, contains('sessionId'));
    });
  });
}
