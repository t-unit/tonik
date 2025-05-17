import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/api_client/api_client_file_generator.dart';
import 'package:tonik_generate/src/api_client/api_client_generator.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';

void main() {
  group('ApiClientFileGenerator', () {
    late Directory tempDir;
    late ApiClientFileGenerator generator;
    late NameManager nameManager;
    late Context testContext;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync();
      nameManager = NameManager(generator: NameGenerator());
      final apiClientGenerator = ApiClientGenerator(
        nameManager: nameManager,
        package: 'test_package',
      );
      generator = ApiClientFileGenerator(
        apiClientGenerator: apiClientGenerator,
      );
      testContext = Context.initial();
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('creates api client directory if it does not exist', () {
      const apiDoc = ApiDocument(
        title: 'Test API',
        version: '1.0.0',
        description: 'Test API Description',
        models: {},
        responseHeaders: {},
        requestHeaders: {},
        servers: {},
        operations: {},
        responses: <Response>{},
        queryParameters: {},
        pathParameters: {},
        requestBodies: {},
      );
      generator.writeFiles(
        apiDocument: apiDoc,
        outputDirectory: tempDir.path,
        package: 'test_package',
      );

      final clientDir = Directory(
        path.join(tempDir.path, 'test_package', 'lib', 'src', 'api_client'),
      );
      expect(clientDir.existsSync(), isTrue);
    });

    test('generates file for tag with operations', () {
      final operation = Operation(
        operationId: 'getUser',
        context: testContext,
        summary: 'Get user',
        description: 'Get user by ID',
        tags: {const Tag(name: 'users')},
        isDeprecated: false,
        path: '/users/{id}',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        responses: const {},
        requestBody: null,
      );

      final apiDoc = ApiDocument(
        title: 'Test API',
        version: '1.0.0',
        description: 'Test API Description',
        models: const {},
        responseHeaders: const {},
        requestHeaders: const {},
        servers: const {},
        operations: {operation},
        responses: const <Response>{},
        queryParameters: const {},
        pathParameters: const {},
        requestBodies: const {},
      );

      generator.writeFiles(
        apiDocument: apiDoc,
        outputDirectory: tempDir.path,
        package: 'test_package',
      );

      final clientDir = Directory(
        path.join(tempDir.path, 'test_package', 'lib', 'src', 'api_client'),
      );
      expect(clientDir.listSync(), hasLength(1));
      expect(clientDir.listSync().first.path, endsWith('users_api.dart'));
    });

    test('generates multiple files for different tags', () {
      final userOperation = Operation(
        operationId: 'getUser',
        context: testContext,
        summary: 'Get user',
        description: 'Get user by ID',
        tags: {const Tag(name: 'users')},
        isDeprecated: false,
        path: '/users/{id}',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        responses: const {},
        requestBody: null,
      );

      final petOperation = Operation(
        operationId: 'getPet',
        context: testContext,
        summary: 'Get pet',
        description: 'Get pet by ID',
        tags: {const Tag(name: 'pets')},
        isDeprecated: false,
        path: '/pets/{id}',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        responses: const {},
        requestBody: null,
      );

      final apiDoc = ApiDocument(
        title: 'Test API',
        version: '1.0.0',
        description: 'Test API Description',
        models: const {},
        responseHeaders: const {},
        requestHeaders: const {},
        servers: const {},
        operations: {userOperation, petOperation},
        responses: const <Response>{},
        queryParameters: const {},
        pathParameters: const {},
        requestBodies: const {},
      );

      generator.writeFiles(
        apiDocument: apiDoc,
        outputDirectory: tempDir.path,
        package: 'test_package',
      );

      final clientDir = Directory(
        path.join(tempDir.path, 'test_package', 'lib', 'src', 'api_client'),
      );
      expect(clientDir.listSync(), hasLength(2));
      expect(
        clientDir.listSync().map((e) => path.basename(e.path)).toList()..sort(),
        ['pets_api.dart', 'users_api.dart'],
      );
    });

    test('generates file for operation without tags', () {
      final operation = Operation(
        operationId: 'untaggedOperation',
        context: testContext,
        summary: 'Untagged operation',
        description: 'Operation without any tags',
        tags: const {}, // No tags
        isDeprecated: false,
        path: '/misc/operation',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        responses: const {},
        requestBody: null,
      );

      final apiDoc = ApiDocument(
        title: 'Test API',
        version: '1.0.0',
        description: 'Test API Description',
        models: const {},
        responseHeaders: const {},
        requestHeaders: const {},
        servers: const {},
        operations: {operation},
        responses: const <Response>{},
        queryParameters: const {},
        pathParameters: const {},
        requestBodies: const {},
      );

      generator.writeFiles(
        apiDocument: apiDoc,
        outputDirectory: tempDir.path,
        package: 'test_package',
      );

      final clientDir = Directory(
        path.join(tempDir.path, 'test_package', 'lib', 'src', 'api_client'),
      );
      expect(clientDir.listSync(), hasLength(1));
      expect(clientDir.listSync().first.path, endsWith('default_api.dart'));
      
      // Read the generated file to verify it contains the operation
      final fileContent = File(clientDir.listSync().first.path).readAsStringSync();
      expect(fileContent, contains('untaggedOperation'));
      expect(fileContent, contains('class DefaultApi'));
    });
    
    test('generates files for tagged and untagged operations', () {
      final taggedOperation = Operation(
        operationId: 'getUser',
        context: testContext,
        summary: 'Get user',
        description: 'Get user by ID',
        tags: {const Tag(name: 'users')},
        isDeprecated: false,
        path: '/users/{id}',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        responses: const {},
        requestBody: null,
      );
      
      final untaggedOperation = Operation(
        operationId: 'untaggedOperation',
        context: testContext,
        summary: 'Untagged operation',
        description: 'Operation without any tags',
        tags: const {}, // No tags
        isDeprecated: false,
        path: '/misc/operation',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        responses: const {},
        requestBody: null,
      );

      final apiDoc = ApiDocument(
        title: 'Test API',
        version: '1.0.0',
        description: 'Test API Description',
        models: const {},
        responseHeaders: const {},
        requestHeaders: const {},
        servers: const {},
        operations: {taggedOperation, untaggedOperation},
        responses: const <Response>{},
        queryParameters: const {},
        pathParameters: const {},
        requestBodies: const {},
      );

      generator.writeFiles(
        apiDocument: apiDoc,
        outputDirectory: tempDir.path,
        package: 'test_package',
      );

      final clientDir = Directory(
        path.join(tempDir.path, 'test_package', 'lib', 'src', 'api_client'),
      );
      expect(clientDir.listSync(), hasLength(2));
      
      final fileNames = clientDir.listSync()
          .map((e) => path.basename(e.path))
          .toList()..sort();
      expect(fileNames, ['default_api.dart', 'users_api.dart']);
      
      // Check content of default API
      final defaultApiContent = File(
        path.join(clientDir.path, 'default_api.dart'),
      ).readAsStringSync();
      expect(defaultApiContent, contains('untaggedOperation'));
      expect(defaultApiContent, contains('class DefaultApi'));
      
      // Check content of users API
      final usersApiContent = File(
        path.join(clientDir.path, 'users_api.dart'),
      ).readAsStringSync();
      expect(usersApiContent, contains('getUser'));
      expect(usersApiContent, contains('class UsersApi'));
    });
  });
}
