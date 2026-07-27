import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:tonik_generate/src/generated_artifact_writer.dart';

void main() {
  group('writeGeneratedArtifact', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync(
        'generated_artifact_writer_',
      );
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('uses one normalized relative path for writing and reporting', () {
      final relativePath = writeGeneratedArtifact(
        outputDirectory: tempDir.path,
        package: 'example_api',
        relativePath: r'lib\src\api_client\users_api.dart',
        content: 'final users = <Object>[];\n',
      );

      expect(relativePath, 'lib/src/api_client/users_api.dart');
      expect(
        File(
          path.join(
            tempDir.path,
            'example_api',
            'lib',
            'src',
            'api_client',
            'users_api.dart',
          ),
        ).readAsStringSync(),
        'final users = <Object>[];\n',
      );
    });

    test('rejects paths outside the generated package before writing', () {
      expect(
        () => writeGeneratedArtifact(
          outputDirectory: tempDir.path,
          package: 'example_api',
          relativePath: '../outside.dart',
          content: 'final outside = true;\n',
        ),
        throwsFormatException,
      );

      expect(
        File(path.join(tempDir.path, 'outside.dart')).existsSync(),
        isFalse,
      );
    });
  });
}
