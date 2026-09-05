import 'dart:io';

import 'package:test/test.dart';

void main() {
  late Directory repository;
  late String hookPath;
  late String installerPath;

  setUp(() async {
    repository = await Directory.systemTemp.createTemp(
      'tonik_commit_msg_hook_test_',
    );
    hookPath = File('.githooks/commit-msg').absolute.path;
    installerPath = File('scripts/install_git_hooks.sh').absolute.path;

    final result = await Process.run('git', [
      'init',
      '--quiet',
    ], workingDirectory: repository.path);
    expect(result.exitCode, 0, reason: result.stderr.toString());
  });

  tearDown(() async {
    await repository.delete(recursive: true);
  });

  test('accepts conventional commit subjects', () async {
    const subjects = [
      'feat: add HTTP transport support',
      'fix(tonik_generate): preserve parameter names',
      'feat!: remove the legacy transport API',
      'refactor(tonik_util)!: replace the content type parser',
      'chore(release): publish packages',
    ];

    for (final subject in subjects) {
      final result = await validateSubject(
        repository: repository,
        hookPath: hookPath,
        subject: subject,
      );
      expect(result.exitCode, 0, reason: result.stderr.toString());
    }
  });

  test('rejects non-conventional commit subjects', () async {
    const subjects = [
      'Update generated API client code',
      'feature: add HTTP transport support',
      'Fix: preserve parameter names',
      'feat add HTTP transport support',
      '',
    ];

    for (final subject in subjects) {
      final result = await validateSubject(
        repository: repository,
        hookPath: hookPath,
        subject: subject,
      );
      expect(result.exitCode, isNot(0));
      expect(
        result.stderr.toString(),
        contains('Use a Conventional Commit subject'),
      );
    }
  });

  test('exempts merge commits', () async {
    File('${repository.path}/.git/MERGE_HEAD').writeAsStringSync('merge\n');

    final result = await validateSubject(
      repository: repository,
      hookPath: hookPath,
      subject: 'Merge pull request #123 from t-unit/example',
    );

    expect(result.exitCode, 0, reason: result.stderr.toString());
  });

  test('installer configures the tracked hooks directory', () async {
    final installResult = await Process.run(
      installerPath,
      const [],
      workingDirectory: repository.path,
    );
    expect(installResult.exitCode, 0, reason: installResult.stderr.toString());

    final configResult = await Process.run('git', [
      'config',
      '--get',
      'core.hooksPath',
    ], workingDirectory: repository.path);
    expect(configResult.exitCode, 0, reason: configResult.stderr.toString());
    expect(configResult.stdout.toString().trim(), '.githooks');
  });
}

Future<ProcessResult> validateSubject({
  required Directory repository,
  required String hookPath,
  required String subject,
}) async {
  final messageFile = File('${repository.path}/COMMIT_EDITMSG')
    ..writeAsStringSync('$subject\n');

  return Process.run(hookPath, [
    messageFile.path,
  ], workingDirectory: repository.path);
}
