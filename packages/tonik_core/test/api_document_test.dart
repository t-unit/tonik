import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';

void main() {
  group('operationsByTag', () {
    test('returns empty set if no operations', () {
      final document = ApiDocument(
        title: 'Test',
        version: '1.0.0',
        models: const {},
        responseHeaders: const {},
        servers: const {},
        operations: const {},
        responses: const {},
        requestHeaders: const {},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: const {},
        requestBodies: const {},
      );

      expect(document.operationsByTag, isEmpty);
    });

    test('returns operations grouped by tag', () {
      final fooTag = Tag(name: 'foo');
      final barTag = Tag(name: 'bar');

      final fooOperation = Operation(
        operationId: 'test',
        context: Context.initial().push('test'),
        path: '/test',
        tags: {fooTag},
        isDeprecated: false,
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: const {},
        responses: const {},
        securitySchemes: const {},
      );

      final barOperation = Operation(
        operationId: 'test2',
        context: Context.initial().push('test'),
        path: '/test2',
        tags: {barTag},
        isDeprecated: false,
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: const {},
        responses: const {},
        securitySchemes: const {},
      );

      final document = ApiDocument(
        title: 'Test',
        version: '1.0.0',
        models: const {},
        responseHeaders: const {},
        servers: const {},
        operations: {fooOperation, barOperation},
        responses: const {},
        requestHeaders: const {},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: const {},
        requestBodies: const {},
      );

      final fooOperations = document.operationsByTag[fooTag];
      expect(fooOperations, contains(fooOperation));

      final barOperations = document.operationsByTag[barTag];
      expect(barOperations, contains(barOperation));
    });

    test('duplicates operations in different tags', () {
      final fooTag = Tag(name: 'foo');
      final barTag = Tag(name: 'bar');

      final twoTagOperation = Operation(
        operationId: 'test',
        context: Context.initial().push('test'),
        path: '/test',
        tags: {fooTag, barTag},
        isDeprecated: false,
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: const {},
        responses: const {},
        securitySchemes: const {},
      );

      final document = ApiDocument(
        title: 'Test',
        version: '1.0.0',
        models: const {},
        responseHeaders: const {},
        servers: const {},
        operations: {
          twoTagOperation,
          Operation(
            operationId: 'test',
            context: Context.initial().push('test'),
            path: '/test',
            tags: {fooTag},
            isDeprecated: false,
            method: HttpMethod.get,
            headers: const {},
            queryParameters: const {},
            pathParameters: const {},
            cookieParameters: const {},
            responses: const {},
            securitySchemes: const {},
          ),
        },
        responses: const {},
        requestHeaders: const {},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: const {},
        requestBodies: const {},
      );

      final fooOperations = document.operationsByTag[fooTag];
      expect(fooOperations, contains(twoTagOperation));

      final barOperations = document.operationsByTag[barTag];
      expect(barOperations, contains(twoTagOperation));
    });
  });
}
