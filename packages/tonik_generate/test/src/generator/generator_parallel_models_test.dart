import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/generator.dart';
import 'package:tonik_generate/src/util/model_worker_pool.dart';

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

ApiDocument _modelsDocument(int count, Context ctx) {
  final models = <Model>{};
  for (var i = 0; i < count; i++) {
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
  return ApiDocument(
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
        final apiDoc = _modelsDocument(Generator.parallelThreshold, ctx);

        var parallelPoolCount = 0;
        const parallelPackage = 'parallel_pkg';
        await const Generator().generate(
          apiDocument: apiDoc,
          outputDirectory: tempDir.path,
          package: parallelPackage,
          config: const TonikConfig(workerCount: 2),
          workerPoolFactory: () {
            parallelPoolCount++;
            return ModelWorkerPool();
          },
        );

        var serialPoolCount = 0;
        const serialPackage = 'serial_pkg';
        await const Generator().generate(
          apiDocument: apiDoc,
          outputDirectory: tempDir.path,
          package: serialPackage,
          config: const TonikConfig(workerCount: 1),
          workerPoolFactory: () {
            serialPoolCount++;
            return ModelWorkerPool();
          },
        );

        expect(
          parallelPoolCount,
          1,
          reason: 'parallel branch must instantiate the worker pool once',
        );
        expect(
          serialPoolCount,
          0,
          reason: 'serial branch must not instantiate the worker pool',
        );

        final parallelTree = _readModelTree(tempDir.path, parallelPackage);
        final serialTree = _readModelTree(tempDir.path, serialPackage);

        expect(parallelTree, isNotEmpty);
        expect(parallelTree.length, apiDoc.models.length);
        expect(parallelTree, serialTree);
      },
    );

    test(
      'runs serially when model count is below parallelThreshold',
      () async {
        final apiDoc = _modelsDocument(Generator.parallelThreshold - 1, ctx);

        var poolCount = 0;
        await const Generator().generate(
          apiDocument: apiDoc,
          outputDirectory: tempDir.path,
          package: 'below_threshold_pkg',
          config: const TonikConfig(workerCount: 8),
          workerPoolFactory: () {
            poolCount++;
            return ModelWorkerPool();
          },
        );

        expect(
          poolCount,
          0,
          reason: 'below-threshold path must skip the worker pool entirely '
              'regardless of how many workers the caller requested',
        );

        final tree = _readModelTree(tempDir.path, 'below_threshold_pkg');
        expect(tree, isNotEmpty);
        expect(tree.length, apiDoc.models.length);
      },
    );
  });

  group('Generator.clampAutoWorkerCount', () {
    test('reserves one CPU for main and clamps to [1, 16]', () {
      expect(Generator.clampAutoWorkerCount(0), 1);
      expect(Generator.clampAutoWorkerCount(1), 1);
      expect(Generator.clampAutoWorkerCount(2), 1);
      expect(Generator.clampAutoWorkerCount(17), 16);
      expect(Generator.clampAutoWorkerCount(100), 16);
    });

    test('returns processorCount - 1 inside the clamp window', () {
      expect(Generator.clampAutoWorkerCount(3), 2);
      expect(Generator.clampAutoWorkerCount(8), 7);
      expect(Generator.clampAutoWorkerCount(16), 15);
    });
  });
}
