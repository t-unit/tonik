import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  late String executable;
  late String packageConfig;
  late Directory directory;

  setUpAll(() async {
    final parser = await Isolate.resolvePackageUri(
      Uri.parse('package:tonik/src/config/cli_parser.dart'),
    );
    executable = parser!.resolve('../../../bin/tonik.dart').toFilePath();
    packageConfig = (await Isolate.packageConfig)!.toFilePath();
  });

  setUp(() {
    directory = Directory.systemTemp.createTempSync('tonik_destination_test_');
    File(path.join(directory.path, 'openapi.yaml')).writeAsStringSync('''
openapi: 3.0.0
info:
  title: Test API
  version: 1.0.0
paths: {}
''');
  });

  tearDown(() {
    directory.deleteSync(recursive: true);
  });

  test('generates a missing package in a non-empty output directory', () async {
    final result = await Process.run(Platform.resolvedExecutable, [
      '--packages=$packageConfig',
      executable,
      '--spec',
      'openapi.yaml',
      '--package-name',
      'test_api',
    ], workingDirectory: directory.path);

    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(
      File(path.join(directory.path, 'test_api', 'pubspec.yaml')).existsSync(),
      isTrue,
    );
    expect(
      File(path.join(directory.path, 'openapi.yaml')).existsSync(),
      isTrue,
    );
  });

  test('generates into an empty package directory', () async {
    Directory(path.join(directory.path, 'generated', 'test_api'))
        .createSync(recursive: true);

    final result = await Process.run(Platform.resolvedExecutable, [
      '--packages=$packageConfig',
      executable,
      '--spec',
      'openapi.yaml',
      '--package-name',
      'test_api',
      '--output-dir',
      'generated',
    ], workingDirectory: directory.path);

    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(
      File(path.join(directory.path, 'generated', 'test_api', 'pubspec.yaml'))
          .existsSync(),
      isTrue,
    );
  });

  test('rejects a non-empty destination without changing files', () async {
    final destination = Directory(
      path.join(directory.path, 'generated', 'test_api'),
    )..createSync(recursive: true);
    final pubspec = File(path.join(destination.path, 'pubspec.yaml'))
      ..writeAsStringSync('original pubspec');
    final hiddenFile = File(path.join(destination.path, '.keep'))
      ..writeAsStringSync('keep this');

    final result = await Process.run(Platform.resolvedExecutable, [
      '--packages=$packageConfig',
      executable,
      '--spec',
      'openapi.yaml',
      '--package-name',
      'test_api',
      '--output-dir',
      'generated',
      '--log-level',
      'silent',
    ], workingDirectory: directory.path);

    expect(result.exitCode, 1);
    expect(result.stderr, contains('generated${path.separator}test_api'));
    expect(result.stderr, contains('is not empty'));
    expect(result.stderr, contains('--overwrite'));
    expect(pubspec.readAsStringSync(), 'original pubspec');
    expect(hiddenFile.readAsStringSync(), 'keep this');
    expect(destination.listSync(recursive: true), hasLength(2));
  });

  test('rejects a default destination containing only a directory', () async {
    final child = Directory(
      path.join(directory.path, 'test_api', 'empty_child'),
    )..createSync(recursive: true);

    final result = await Process.run(Platform.resolvedExecutable, [
      '--packages=$packageConfig',
      executable,
      '--spec',
      'openapi.yaml',
      '--package-name',
      'test_api',
    ], workingDirectory: directory.path);

    expect(result.exitCode, 1);
    expect(result.stderr, contains('is not empty'));
    expect(child.existsSync(), isTrue);
    expect(child.parent.listSync(recursive: true), hasLength(1));
  });

  test('rejects a non-empty destination resolved from config', () async {
    File(path.join(directory.path, 'custom.yaml')).writeAsStringSync('''
spec: openapi.yaml
outputDir: configured
packageName: configured_api
''');
    final destination = Directory(
      path.join(directory.path, 'configured', 'configured_api'),
    )..createSync(recursive: true);
    final hiddenFile = File(path.join(destination.path, '.keep'))
      ..writeAsStringSync('keep this');

    final result = await Process.run(Platform.resolvedExecutable, [
      '--packages=$packageConfig',
      executable,
      '--config',
      'custom.yaml',
    ], workingDirectory: directory.path);

    expect(result.exitCode, 1);
    expect(
      result.stderr,
      contains('configured${path.separator}configured_api'),
    );
    expect(result.stderr, contains('--overwrite'));
    expect(hiddenFile.readAsStringSync(), 'keep this');
    expect(destination.listSync(recursive: true), hasLength(1));
  });

  test(
    'checks CLI destination overrides instead of config destination',
    () async {
      File(path.join(directory.path, 'tonik.yaml')).writeAsStringSync('''
spec: openapi.yaml
outputDir: configured
packageName: configured_api
''');
      final configured = Directory(
        path.join(directory.path, 'configured', 'configured_api'),
      )..createSync(recursive: true);
      final existing = File(path.join(configured.path, 'notes.txt'))
        ..writeAsStringSync('keep configured package');

      final result = await Process.run(Platform.resolvedExecutable, [
        '--packages=$packageConfig',
        executable,
        '--output-dir',
        'generated',
        '--package-name',
        'test_api',
      ], workingDirectory: directory.path);

      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
      expect(
        File(path.join(directory.path, 'generated', 'test_api', 'pubspec.yaml'))
            .existsSync(),
        isTrue,
      );
      expect(existing.readAsStringSync(), 'keep configured package');
      expect(configured.listSync(recursive: true), hasLength(1));
    },
  );

  test('overwrite regenerates files and preserves unrelated files', () async {
    final destination = Directory(path.join(directory.path, 'test_api'))
      ..createSync();
    final pubspec = File(path.join(destination.path, 'pubspec.yaml'))
      ..writeAsStringSync('original pubspec');
    final unrelated = File(path.join(destination.path, 'notes.txt'))
      ..writeAsStringSync('keep this');

    final result = await Process.run(Platform.resolvedExecutable, [
      '--packages=$packageConfig',
      executable,
      '--spec',
      'openapi.yaml',
      '--package-name',
      'test_api',
      '--overwrite',
    ], workingDirectory: directory.path);

    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    final generatedPubspec = loadYaml(pubspec.readAsStringSync()) as YamlMap;
    expect(generatedPubspec['name'], 'test_api');
    expect(Directory(path.join(destination.path, 'lib')).existsSync(), isTrue);
    expect(unrelated.readAsStringSync(), 'keep this');
  });
}
