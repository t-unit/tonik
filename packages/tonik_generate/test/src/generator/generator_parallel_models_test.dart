import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/generator.dart';

Map<String, String> _readModelTree(String root, String package) {
  final modelDir = Directory(path.join(root, package, 'lib', 'src', 'model'));
  if (!modelDir.existsSync()) return const {};
  final result = <String, String>{};
  final entries = modelDir.listSync().whereType<File>().toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  for (final file in entries) {
    result[path.basename(file.path)] = file.readAsStringSync();
  }
  return result;
}

void main() {
  group('Generator parallel model path', () {
    late Directory tempDir;
    late Context ctx;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('gen_parallel_');
      ctx = Context.initial();
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test(
      'dispatches via worker pool when threshold is met and workerCount > 1',
      () async {
        final models = <Model>{};
        for (var i = 0; i < Generator.parallelThreshold; i++) {
          models.add(
            ClassModel(
              isDeprecated: false,
              name: 'Model$i',
              properties: const [],
              context: ctx,
              examples: const [],
            ),
          );
        }

        final apiDoc = ApiDocument(
          title: 'Test',
          version: '1.0.0',
          description: 'Test',
          models: models,
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

        const parallelPackage = 'parallel_pkg';
        await const Generator().generate(
          apiDocument: apiDoc,
          outputDirectory: tempDir.path,
          package: parallelPackage,
          config: const TonikConfig(workerCount: 2),
        );

        const serialPackage = 'serial_pkg';
        await const Generator().generate(
          apiDocument: apiDoc,
          outputDirectory: tempDir.path,
          package: serialPackage,
          config: const TonikConfig(workerCount: 1),
        );

        final parallelTree = _readModelTree(tempDir.path, parallelPackage);
        final serialTree = _readModelTree(tempDir.path, serialPackage);

        expect(parallelTree, isNotEmpty);
        expect(parallelTree.length, models.length);
        expect(parallelTree, serialTree);
      },
    );
  });

  group('Generator.resolveWorkerCount', () {
    test('returns explicit requested value when provided', () {
      expect(Generator.resolveWorkerCount(0), 0);
      expect(Generator.resolveWorkerCount(1), 1);
      expect(Generator.resolveWorkerCount(8), 8);
    });

    test('auto-sizes when null is passed', () {
      final auto = Generator.resolveWorkerCount(null);
      expect(auto, greaterThanOrEqualTo(1));
      expect(auto, lessThanOrEqualTo(16));
    });
  });
}
