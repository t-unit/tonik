import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/pubspec_generator.dart';

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
      expect(sanitizeVersion('1.0.0-alpha.1+build.42'), '1.0.0-alpha.1+build.42');
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
      );

      generatePubspec(
        apiDocument: apiDoc,
        outputDirectory: tempDir.path,
        package: 'test_pkg',
      );

      final content = File(
        path.join(tempDir.path, 'test_pkg', 'pubspec.yaml'),
      ).readAsStringSync();

      expect(content, contains('version: 0.0.1-2026-02-25.clover'));
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
      );

      generatePubspec(
        apiDocument: apiDoc,
        outputDirectory: tempDir.path,
        package: 'test_pkg',
      );

      final content = File(
        path.join(tempDir.path, 'test_pkg', 'pubspec.yaml'),
      ).readAsStringSync();

      expect(content, contains('version: 1.0.0'));
    });
  });
}
