@Timeout(Duration(minutes: 2))
library;

import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:tonik/src/config/config_loader.dart';

void main() {
  late String executable;
  late String packageConfig;
  late Directory directory;
  late File config;

  setUpAll(() async {
    final parser = await Isolate.resolvePackageUri(
      Uri.parse('package:tonik/src/config/cli_parser.dart'),
    );
    executable = parser!.resolve('../../../bin/tonik.dart').toFilePath();
    packageConfig = (await Isolate.packageConfig)!.toFilePath();
  });

  setUp(() {
    directory = Directory.systemTemp.createTempSync('tonik_config_errors_');
    config = File(path.join(directory.path, 'tonik.yaml'));
  });

  tearDown(() => directory.deleteSync(recursive: true));

  test('invalid config fields produce a clean CLI diagnostic', () async {
    config.writeAsStringSync('packageName: 42\n');
    final result = await Process.run(Platform.resolvedExecutable, [
      '--packages=$packageConfig',
      executable,
    ], workingDirectory: directory.path);

    expect(result.exitCode, 128, reason: '${result.stdout}\n${result.stderr}');
    expect(result.stderr, contains('"packageName" must be a string'));
    expect(result.stderr, isNot(contains('Unhandled exception')));
    expect(result.stdout, isNot(contains('Unexpected error')));
  });

  test('malformed config YAML produces a clean CLI diagnostic', () async {
    config.writeAsStringSync('spec: [invalid\n');
    final result = await Process.run(Platform.resolvedExecutable, [
      '--packages=$packageConfig',
      executable,
    ], workingDirectory: directory.path);

    expect(result.exitCode, 128, reason: '${result.stdout}\n${result.stderr}');
    expect(result.stderr, contains('Failed to parse config file'));
    expect(result.stderr, isNot(contains('Unhandled exception')));
  });

  test(
    'invalid enum booleans produce a typed diagnostic through the CLI',
    () async {
      config.writeAsStringSync('enums:\n  generateUnknownCase: "yes"\n');
      final result = await Process.run(Platform.resolvedExecutable, [
        '--packages=$packageConfig',
        executable,
      ], workingDirectory: directory.path);

      expect(
        result.exitCode,
        128,
        reason: '${result.stdout}\n${result.stderr}',
      );
      expect(
        result.stderr,
        contains('"enums.generateUnknownCase" must be a boolean'),
      );
      expect(result.stderr, isNot(contains('TypeError')));
      expect(result.stderr, isNot(contains('Unhandled exception')));
    },
  );

  test('invalid enum names use the existing string parser', () {
    config.writeAsStringSync('enums:\n  unknownCaseName: 42\n');

    expect(
      () => ConfigLoader.load(config.path),
      throwsA(
        isA<ConfigLoaderException>().having(
          (error) => error.message,
          'message',
          'Invalid config: "enums.unknownCaseName" must be a string',
        ),
      ),
    );
  });
}
