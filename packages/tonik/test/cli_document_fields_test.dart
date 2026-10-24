@Timeout(Duration(minutes: 2))
library;

import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

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
  setUp(
    () => directory = Directory.systemTemp.createTempSync(
      'tonik_document_fields_',
    ),
  );
  tearDown(() => directory.deleteSync(recursive: true));

  test(
    'numeric YAML versions produce a field-specific CLI diagnostic',
    () async {
      File(path.join(directory.path, 'openapi.yaml')).writeAsStringSync('''
openapi: 3.0.0
info: {title: Test API, version: 1.0}
paths: {}
''');
      final result = await Process.run(Platform.resolvedExecutable, [
        '--packages=$packageConfig',
        executable,
        '--spec',
        'openapi.yaml',
        '--package-name',
        'test_api',
      ], workingDirectory: directory.path);

      expect(result.exitCode, 1, reason: '${result.stdout}\n${result.stderr}');
      expect(result.stderr, contains('info.version must be a string'));
      expect(result.stdout, isNot(contains('Unexpected error')));
      expect(result.stderr, isNot(contains('Unhandled exception')));
    },
  );

  test(
    'numeric YAML server defaults identify their field in CLI output',
    () async {
      File(path.join(directory.path, 'openapi.yaml')).writeAsStringSync('''
openapi: 3.0.0
info: {title: Test API, version: '1.0'}
paths: {}
servers:
  - url: https://example.com:{port}
    variables:
      port: {default: 8080}
''');
      final result = await Process.run(Platform.resolvedExecutable, [
        '--packages=$packageConfig',
        executable,
        '--spec',
        'openapi.yaml',
        '--package-name',
        'test_api',
      ], workingDirectory: directory.path);

      expect(result.exitCode, 1, reason: '${result.stdout}\n${result.stderr}');
      expect(
        result.stderr,
        contains('server.variables.port.default must be a string'),
      );
      expect(result.stdout, isNot(contains('Unexpected error')));
      expect(result.stderr, isNot(contains('TypeError')));
    },
  );
}
