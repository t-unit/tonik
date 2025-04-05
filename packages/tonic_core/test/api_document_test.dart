import 'package:test/test.dart';
import 'package:tonic_core/tonic_core.dart';

void main() {
  group('operationsByTag', () {
    test('returns empty set if no operations', () {
      const document = ApiDocument(
        title: 'Test',
        version: '1.0.0',
        models: {},
        responseHeaders: {},
        servers: {},
        operations: {},
        responses: {},
        requestHeaders: {},
        queryParameters: {},
        pathParameters: {},
      );

      expect(document.operationsByTag, isEmpty);
    });

    test('returns operations grouped by tag', () {
      final fooOperation = Operation(
        operationId: 'test',
        context: Context.initial().push('test'),
        path: '/test',
        tags: {const Tag(name: 'foo')},
        summary: null,
        description: null,
        isDeprecated: false,
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        responses: const {},
      );

      final barOperation = Operation(
        operationId: 'test2',
        context: Context.initial().push('test'),
        path: '/test2',
        tags: {const Tag(name: 'bar')},
        summary: null,
        description: null,
        isDeprecated: false,
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        responses: const {},
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
      );

      final fooOperations = document.operationsByTag[const Tag(name: 'foo')];
      expect(fooOperations, contains(fooOperation));

      final barOperations = document.operationsByTag[const Tag(name: 'bar')];
      expect(barOperations, contains(barOperation));
    });

    test('duplicates operations in different tags', () {
      final twoTagOperation = Operation(
        operationId: 'test',
        context: Context.initial().push('test'),
        path: '/test',
        tags: {const Tag(name: 'foo'), const Tag(name: 'bar')},
        summary: null,
        description: null,
        isDeprecated: false,
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        responses: const {},
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
            tags: {const Tag(name: 'foo')},
            summary: null,
            description: null,
            isDeprecated: false,
            method: HttpMethod.get,
            headers: const {},
            queryParameters: const {},
            pathParameters: const {},
            responses: const {},
          ),
        },
        responses: const {},
        requestHeaders: const {},
        queryParameters: const {},
        pathParameters: const {},
      );

      final fooOperations = document.operationsByTag[const Tag(name: 'foo')];
      expect(fooOperations, contains(twoTagOperation));

      final barOperations = document.operationsByTag[const Tag(name: 'bar')];
      expect(barOperations, contains(twoTagOperation));
    });
  });
}
