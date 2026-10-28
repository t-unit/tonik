import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/pubspec_generator.dart';
import 'package:tonik_generate/src/transport/dio_backend_generator.dart';
import 'package:tonik_generate/src/transport/http_backend_generator.dart';
import 'package:yaml/yaml.dart';

void main() {
  group('sanitizeVersion', () {
    test('returns valid semver version as-is', () {
      expect(sanitizeVersion('1.0.0'), '1.0.0');
    });

    test('returns semver with prerelease as-is', () {
      expect(sanitizeVersion('1.0.0-beta.1'), '1.0.0-beta.1');
    });

    test('returns semver with build metadata as-is', () {
      expect(sanitizeVersion('1.0.0+build.42'), '1.0.0+build.42');
    });

    test('returns semver with prerelease and build as-is', () {
      expect(
        sanitizeVersion('1.0.0-alpha.1+build.42'),
        '1.0.0-alpha.1+build.42',
      );
    });

    test('returns 0.0.1 fallback for non-semver date-based version', () {
      expect(sanitizeVersion('2026-02-25.clover'), '0.0.1-2026-02-25.clover');
    });

    test('sanitizes characters not allowed in semver prerelease', () {
      expect(sanitizeVersion('v1.0 beta!'), '0.0.1-v1.0-beta');
    });

    test('handles empty version', () {
      expect(sanitizeVersion(''), '0.0.1');
    });

    test('handles version that is just whitespace', () {
      expect(sanitizeVersion('   '), '0.0.1');
    });

    test('collapses consecutive hyphens in sanitized version', () {
      expect(sanitizeVersion('a--b'), '0.0.1-a-b');
    });

    test('removes leading and trailing hyphens from sanitized part', () {
      expect(sanitizeVersion('-abc-'), '0.0.1-abc');
    });

    test('removes leading and trailing dots from sanitized part', () {
      expect(sanitizeVersion('.abc.'), '0.0.1-abc');
    });

    test('collapses consecutive dots in sanitized version', () {
      expect(sanitizeVersion('a..b'), '0.0.1-a.b');
    });

    test('handles version with only special characters', () {
      expect(sanitizeVersion('!!!'), '0.0.1');
    });

    test('preserves SNAPSHOT-style prerelease suffix', () {
      expect(sanitizeVersion('1.0.27-SNAPSHOT'), '1.0.27-SNAPSHOT');
    });

    test('handles bare number', () {
      expect(sanitizeVersion('3'), '0.0.1-3');
    });

    test('handles two-part version number', () {
      expect(sanitizeVersion('1.0'), '0.0.1-1.0');
    });
  });

  group('generatePubspec', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync();
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('uses sanitized version in generated pubspec', () {
      final apiDoc = ApiDocument(
        title: 'Test API',
        version: '2026-02-25.clover',
        description: 'Test',
        models: const {},
        responseHeaders: const {},
        requestHeaders: const {},
        servers: const {},
        operations: const {},
        responses: const <Response>{},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: const {},
        requestBodies: const {},
        summary: null,
        contact: null,
        license: null,
        termsOfService: null,
        externalDocs: null,
      );

      generatePubspec(
        apiDocument: apiDoc,
        outputDirectory: tempDir.path,
        package: 'test_pkg',
        backendGenerator: const DioBackendGenerator(),
      );

      final content = File(path.join(tempDir.path, 'test_pkg', 'pubspec.yaml'))
          .readAsStringSync();

      expect(loadYaml(content), {
        'name': 'test_pkg',
        'description': 'Generated API client for Test API',
        'version': '0.0.1-2026-02-25.clover',
        'environment': {'sdk': '>=3.13.0 <4.0.0'},
        'dependencies': {
          'big_decimal': '^0.7.0',
          'collection': '^1.19.1',
          'dio': '^5.11.1',
          'meta': '^1.19.0',
          'tonik_util': '^0.11.1',
        },
        'dev_dependencies': {'lints': '^6.1.0'},
      });
    });

    test('keeps valid semver version in generated pubspec', () {
      final apiDoc = ApiDocument(
        title: 'Test API',
        version: '1.0.0',
        description: 'Test',
        models: const {},
        responseHeaders: const {},
        requestHeaders: const {},
        servers: const {},
        operations: const {},
        responses: const <Response>{},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: const {},
        requestBodies: const {},
        summary: null,
        contact: null,
        license: null,
        termsOfService: null,
        externalDocs: null,
      );

      generatePubspec(
        apiDocument: apiDoc,
        outputDirectory: tempDir.path,
        package: 'test_pkg',
        backendGenerator: const DioBackendGenerator(),
      );

      final content = File(path.join(tempDir.path, 'test_pkg', 'pubspec.yaml'))
          .readAsStringSync();

      final pubspec = loadYaml(content) as YamlMap;
      expect(pubspec['version'], '1.0.0');
    });
    test('includes fast_immutable_collections when enabled', () {
      final apiDoc = ApiDocument(
        title: 'Test API',
        version: '1.0.0',
        description: 'Test',
        models: const {},
        responseHeaders: const {},
        requestHeaders: const {},
        servers: const {},
        operations: const {},
        responses: const <Response>{},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: const {},
        requestBodies: const {},
        summary: null,
        contact: null,
        license: null,
        termsOfService: null,
        externalDocs: null,
      );

      generatePubspec(
        apiDocument: apiDoc,
        outputDirectory: tempDir.path,
        package: 'test_pkg',
        backendGenerator: const DioBackendGenerator(),
        useImmutableCollections: true,
      );

      final content = File(path.join(tempDir.path, 'test_pkg', 'pubspec.yaml'))
          .readAsStringSync();

      final pubspec = loadYaml(content) as YamlMap;
      final dependencies = pubspec['dependencies'] as YamlMap;
      expect(dependencies['fast_immutable_collections'], '^12.0.0');
    });

    test('does not include fast_immutable_collections when disabled', () {
      final apiDoc = ApiDocument(
        title: 'Test API',
        version: '1.0.0',
        description: 'Test',
        models: const {},
        responseHeaders: const {},
        requestHeaders: const {},
        servers: const {},
        operations: const {},
        responses: const <Response>{},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: const {},
        requestBodies: const {},
        summary: null,
        contact: null,
        license: null,
        termsOfService: null,
        externalDocs: null,
      );

      generatePubspec(
        apiDocument: apiDoc,
        outputDirectory: tempDir.path,
        package: 'test_pkg',
        backendGenerator: const DioBackendGenerator(),
      );

      final content = File(path.join(tempDir.path, 'test_pkg', 'pubspec.yaml'))
          .readAsStringSync();

      final pubspec = loadYaml(content) as YamlMap;
      final dependencies = pubspec['dependencies'] as YamlMap;
      expect(dependencies.containsKey('fast_immutable_collections'), isFalse);
    });

    test('writes exactly the selected transport dependency', () {
      final apiDoc = ApiDocument(
        title: 'Test API',
        version: '1.0.0',
        models: const {},
        responseHeaders: const {},
        requestHeaders: const {},
        servers: const {},
        operations: const {},
        responses: const <Response>{},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: const {},
        requestBodies: const {},
        summary: null,
        description: null,
        contact: null,
        license: null,
        termsOfService: null,
        externalDocs: null,
      );

      generatePubspec(
        apiDocument: apiDoc,
        outputDirectory: tempDir.path,
        package: 'dio_pkg',
        backendGenerator: const DioBackendGenerator(),
      );
      generatePubspec(
        apiDocument: apiDoc,
        outputDirectory: tempDir.path,
        package: 'http_pkg',
        backendGenerator: const HttpBackendGenerator(),
      );

      final dio = File(path.join(tempDir.path, 'dio_pkg', 'pubspec.yaml'))
          .readAsStringSync();
      final http = File(path.join(tempDir.path, 'http_pkg', 'pubspec.yaml'))
          .readAsStringSync();

      final dioPubspec = loadYaml(dio) as YamlMap;
      final httpPubspec = loadYaml(http) as YamlMap;
      expect(dioPubspec['dependencies'], {
        'big_decimal': '^0.7.0',
        'collection': '^1.19.1',
        'dio': '^5.11.1',
        'meta': '^1.19.0',
        'tonik_util': '^0.11.1',
      });
      expect(httpPubspec['dependencies'], {
        'big_decimal': '^0.7.0',
        'collection': '^1.19.1',
        'http': '^1.6.0',
        'meta': '^1.19.0',
        'tonik_util': '^0.11.1',
      });
    });

    test('preserves colon-space in the title', () {
      final apiDoc = ApiDocument(
        title: 'Acme: Orders API',
        version: '1.0.0',
        models: const {},
        responseHeaders: const {},
        requestHeaders: const {},
        servers: const {},
        operations: const {},
        responses: const <Response>{},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: const {},
        requestBodies: const {},
        summary: null,
        description: null,
        contact: null,
        license: null,
        termsOfService: null,
        externalDocs: null,
      );

      generatePubspec(
        apiDocument: apiDoc,
        outputDirectory: tempDir.path,
        package: 'test_pkg',
        backendGenerator: const DioBackendGenerator(),
      );

      final content = File(path.join(tempDir.path, 'test_pkg', 'pubspec.yaml'))
          .readAsStringSync();
      final pubspec = loadYaml(content) as YamlMap;

      expect(
        pubspec['description'],
        'Generated API client for Acme: Orders API',
      );
    });

    test('preserves hash comments in the title', () {
      final apiDoc = ApiDocument(
        title: 'Pet Store API #2',
        version: '1.0.0',
        models: const {},
        responseHeaders: const {},
        requestHeaders: const {},
        servers: const {},
        operations: const {},
        responses: const <Response>{},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: const {},
        requestBodies: const {},
        summary: null,
        description: null,
        contact: null,
        license: null,
        termsOfService: null,
        externalDocs: null,
      );

      generatePubspec(
        apiDocument: apiDoc,
        outputDirectory: tempDir.path,
        package: 'test_pkg',
        backendGenerator: const DioBackendGenerator(),
      );

      final content = File(path.join(tempDir.path, 'test_pkg', 'pubspec.yaml'))
          .readAsStringSync();
      final pubspec = loadYaml(content) as YamlMap;

      expect(
        pubspec['description'],
        'Generated API client for Pet Store API #2',
      );
    });

    test('preserves line feeds in the title', () {
      final apiDoc = ApiDocument(
        title: 'Pet Store\nAPI',
        version: '1.0.0',
        models: const {},
        responseHeaders: const {},
        requestHeaders: const {},
        servers: const {},
        operations: const {},
        responses: const <Response>{},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: const {},
        requestBodies: const {},
        summary: null,
        description: null,
        contact: null,
        license: null,
        termsOfService: null,
        externalDocs: null,
      );

      generatePubspec(
        apiDocument: apiDoc,
        outputDirectory: tempDir.path,
        package: 'test_pkg',
        backendGenerator: const DioBackendGenerator(),
      );

      final content = File(path.join(tempDir.path, 'test_pkg', 'pubspec.yaml'))
          .readAsStringSync();
      final pubspec = loadYaml(content) as YamlMap;

      expect(pubspec['description'], 'Generated API client for Pet Store\nAPI');
    });

    test('preserves carriage returns and line feeds in the title', () {
      final apiDoc = ApiDocument(
        title: 'Pet Store\r\nAPI',
        version: '1.0.0',
        models: const {},
        responseHeaders: const {},
        requestHeaders: const {},
        servers: const {},
        operations: const {},
        responses: const <Response>{},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: const {},
        requestBodies: const {},
        summary: null,
        description: null,
        contact: null,
        license: null,
        termsOfService: null,
        externalDocs: null,
      );

      generatePubspec(
        apiDocument: apiDoc,
        outputDirectory: tempDir.path,
        package: 'test_pkg',
        backendGenerator: const HttpBackendGenerator(),
      );

      final content = File(path.join(tempDir.path, 'test_pkg', 'pubspec.yaml'))
          .readAsStringSync();
      final pubspec = loadYaml(content) as YamlMap;

      expect(
        pubspec['description'],
        'Generated API client for Pet Store\r\nAPI',
      );
    });

    test('preserves quotes and backslashes in the title', () {
      final apiDoc = ApiDocument(
        title: r'''Pet's "Store" \ API''',
        version: '1.0.0',
        models: const {},
        responseHeaders: const {},
        requestHeaders: const {},
        servers: const {},
        operations: const {},
        responses: const <Response>{},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: const {},
        requestBodies: const {},
        summary: null,
        description: null,
        contact: null,
        license: null,
        termsOfService: null,
        externalDocs: null,
      );

      generatePubspec(
        apiDocument: apiDoc,
        outputDirectory: tempDir.path,
        package: 'test_pkg',
        backendGenerator: const DioBackendGenerator(),
      );

      final content = File(path.join(tempDir.path, 'test_pkg', 'pubspec.yaml'))
          .readAsStringSync();
      final pubspec = loadYaml(content) as YamlMap;

      expect(
        pubspec['description'],
        r'''Generated API client for Pet's "Store" \ API''',
      );
    });

    test('keeps YAML-looking lines inside the description', () {
      final apiDoc = ApiDocument(
        title: 'Pet Store\npublish_to: https://example.com',
        version: '1.0.0',
        models: const {},
        responseHeaders: const {},
        requestHeaders: const {},
        servers: const {},
        operations: const {},
        responses: const <Response>{},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: const {},
        requestBodies: const {},
        summary: null,
        description: null,
        contact: null,
        license: null,
        termsOfService: null,
        externalDocs: null,
      );

      generatePubspec(
        apiDocument: apiDoc,
        outputDirectory: tempDir.path,
        package: 'test_pkg',
        backendGenerator: const DioBackendGenerator(),
      );

      final content = File(path.join(tempDir.path, 'test_pkg', 'pubspec.yaml'))
          .readAsStringSync();
      final pubspec = loadYaml(content) as YamlMap;

      expect(
        pubspec['description'],
        'Generated API client for Pet Store\npublish_to: https://example.com',
      );
      expect(pubspec.containsKey('publish_to'), isFalse);
    });
  });
}
