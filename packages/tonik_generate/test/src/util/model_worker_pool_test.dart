import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/model/all_of_generator.dart';
import 'package:tonik_generate/src/model/any_of_generator.dart';
import 'package:tonik_generate/src/model/class_generator.dart';
import 'package:tonik_generate/src/model/enum_generator.dart';
import 'package:tonik_generate/src/model/model_file_generator.dart';
import 'package:tonik_generate/src/model/one_of_generator.dart';
import 'package:tonik_generate/src/model/typedef_generator.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/util/model_worker_pool.dart';

const _package = 'pkg';

({
  NameManager nameManager,
  StableModelSorter stableModelSorter,
  ModelFileGenerator modelFileGenerator,
})
_buildSerial() {
  final nameGenerator = NameGenerator();
  final stableModelSorter = StableModelSorter();
  final nameManager = NameManager(
    generator: nameGenerator,
    stableModelSorter: stableModelSorter,
  );
  final classGenerator = ClassGenerator(
    nameManager: nameManager,
    package: _package,
  );
  final enumGenerator = EnumGenerator(nameManager: nameManager);
  final anyOfGenerator = AnyOfGenerator(
    nameManager: nameManager,
    package: _package,
    stableModelSorter: stableModelSorter,
  );
  final oneOfGenerator = OneOfGenerator(
    nameManager: nameManager,
    package: _package,
    stableModelSorter: stableModelSorter,
  );
  final typedefGenerator = TypedefGenerator(
    nameManager: nameManager,
    package: _package,
  );
  final allOfGenerator = AllOfGenerator(
    nameManager: nameManager,
    package: _package,
    stableModelSorter: stableModelSorter,
  );

  return (
    nameManager: nameManager,
    stableModelSorter: stableModelSorter,
    modelFileGenerator: ModelFileGenerator(
      classGenerator: classGenerator,
      enumGenerator: enumGenerator,
      anyOfGenerator: anyOfGenerator,
      oneOfGenerator: oneOfGenerator,
      typedefGenerator: typedefGenerator,
      allOfGenerator: allOfGenerator,
    ),
  );
}

ApiDocument _allSubtypeModelDocument(Context ctx) {
  return ApiDocument(
    title: 'Test',
    version: '1.0.0',
    description: 'Test',
    models: <Model>{
      ClassModel(
        isDeprecated: false,
        name: 'User',
        properties: const [],
        context: ctx,
        examples: const [],
      ),
      EnumModel<String>(
        isDeprecated: false,
        name: 'Status',
        values: {
          const EnumEntry(value: 'active'),
          const EnumEntry(value: 'inactive'),
        },
        isNullable: false,
        context: ctx,
        examples: const [],
      ),
      EnumModel<int>(
        isDeprecated: false,
        name: 'Priority',
        values: {
          const EnumEntry(value: 1),
          const EnumEntry(value: 2),
        },
        isNullable: false,
        context: ctx,
        examples: const [],
      ),
      OneOfModel(
        isDeprecated: false,
        name: 'Choice',
        models: {
          (discriminatorValue: null, model: StringModel(context: ctx)),
          (discriminatorValue: null, model: IntegerModel(context: ctx)),
        },
        context: ctx,
        examples: const [],
      ),
      AnyOfModel(
        isDeprecated: false,
        name: 'FlexibleModel',
        models: {
          (discriminatorValue: null, model: StringModel(context: ctx)),
          (discriminatorValue: null, model: IntegerModel(context: ctx)),
        },
        context: ctx,
        examples: const [],
      ),
      AllOfModel(
        isDeprecated: false,
        name: 'Combined',
        models: {
          StringModel(context: ctx),
          IntegerModel(context: ctx),
        },
        context: ctx,
        examples: const [],
      ),
      AliasModel(
        name: 'UserId',
        model: StringModel(context: ctx),
        context: ctx,
        examples: const [],
        defaultValue: null,
      ),
      ListModel(
        name: 'UserList',
        content: StringModel(context: ctx),
        context: ctx,
        examples: const [],
      ),
      MapModel(
        name: 'UserMap',
        valueModel: StringModel(context: ctx),
        context: ctx,
        examples: const [],
      ),
    },
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

void _primeBoth(NameManager nameManager, ApiDocument apiDocument) {
  nameManager.prime(
    models: apiDocument.models,
    responses: apiDocument.responses,
    requestBodies: apiDocument.requestBodies,
    operations: apiDocument.operations,
    tags: apiDocument.operationsByTag.keys,
    servers: apiDocument.servers,
  );
}

Map<String, String> _readModelTree(String root) {
  final modelDir = Directory(path.join(root, _package, 'lib', 'src', 'model'));
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
  group('ModelWorkerPool.run', () {
    late Directory tempDir;
    late Context ctx;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('model_worker_pool_');
      ctx = Context.initial();
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('produces byte-identical file tree as serial writeFiles', () async {
      final apiDoc = _allSubtypeModelDocument(ctx);

      final serialDir = Directory(path.join(tempDir.path, 'serial'))
        ..createSync();
      final parallelDir = Directory(path.join(tempDir.path, 'parallel'))
        ..createSync();

      final serial = _buildSerial();
      _primeBoth(serial.nameManager, apiDoc);
      serial.modelFileGenerator.writeFiles(
        apiDocument: apiDoc,
        outputDirectory: serialDir.path,
        package: _package,
      );

      final parallel = _buildSerial();
      _primeBoth(parallel.nameManager, apiDoc);
      await ModelWorkerPool().run(
        apiDocument: apiDoc,
        nameManager: parallel.nameManager,
        stableModelSorter: parallel.stableModelSorter,
        outputDirectory: parallelDir.path,
        package: _package,
        useImmutableCollections: false,
        workerCount: 2,
      );

      expect(_readModelTree(parallelDir.path), _readModelTree(serialDir.path));
    });

    test(
      'rethrows worker error with original concrete type and worker stack',
      () async {
        final apiDoc = ApiDocument(
          title: 'Test',
          version: '1.0.0',
          description: 'Test',
          models: <Model>{
            ClassModel(
              isDeprecated: false,
              name: 'User',
              properties: const [],
              context: ctx,
              examples: const [],
            ),
          },
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

        final setup = _buildSerial();
        _primeBoth(setup.nameManager, apiDoc);

        Object? capturedError;
        StackTrace? capturedStack;
        try {
          await ModelWorkerPool().run(
            apiDocument: apiDoc,
            nameManager: setup.nameManager,
            stableModelSorter: setup.stableModelSorter,
            outputDirectory: '/this/path/does/not/exist/and/cannot/be/created',
            package: _package,
            useImmutableCollections: false,
            workerCount: 1,
          );
        } on Object catch (e, s) {
          capturedError = e;
          capturedStack = s;
        }

        expect(
          capturedError,
          isA<FileSystemException>(),
          reason: 'pool must rethrow the worker-side throw with its '
              'original concrete type, not wrap it in StateError',
        );
        expect(
          capturedError,
          isNot(isA<StateError>()),
          reason: 'a racing exit notification must not clobber the real '
              'worker exception with the watchdog StateError',
        );
        expect(
          capturedStack.toString(),
          contains('model_file_generator.dart'),
          reason: 'stack must contain a worker-side frame so users can '
              'locate the failing generator path',
        );
      },
    );

    test(
      'surfaces uncaught async errors as ModelWorkerAsyncError',
      () async {
        // Many models behind a single worker so the async crash scheduled
        // during the first model can land at main before the worker has
        // acked all remaining jobs. With one model the ack and the async
        // error would race at the completer.
        final apiDoc = _allSubtypeModelDocument(ctx);

        final nameGenerator = NameGenerator();
        final stableModelSorter = StableModelSorter();
        final nameManager = _AsyncCrashingNameManager(
          generator: nameGenerator,
          stableModelSorter: stableModelSorter,
        )
          ..prime(
            models: apiDoc.models,
            responses: apiDoc.responses,
            requestBodies: apiDoc.requestBodies,
            operations: apiDoc.operations,
            tags: apiDoc.operationsByTag.keys,
            servers: apiDoc.servers,
          )
          ..armed = true;

        Object? capturedError;
        await ModelWorkerPool()
            .run(
              apiDocument: apiDoc,
              nameManager: nameManager,
              stableModelSorter: stableModelSorter,
              outputDirectory: tempDir.path,
              package: _package,
              useImmutableCollections: false,
              workerCount: 1,
            )
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () => fail(
                'pool silently hung on uncaught async worker error',
              ),
            )
            .catchError((Object e) {
              capturedError = e;
            });

        expect(
          capturedError,
          isA<ModelWorkerAsyncError>(),
          reason: 'uncaught async errors must arrive as a named carrier so '
              'callers can distinguish them from the sync rethrow path',
        );
        expect(
          capturedError.toString(),
          contains('synthetic async crash'),
          reason: 'the original error message must round-trip through '
              'ModelWorkerAsyncError',
        );
      },
    );

    test(
      'aborts (does not silently hang) when worker throws non-sendable error',
      () async {
        final apiDoc = ApiDocument(
          title: 'Test',
          version: '1.0.0',
          description: 'Test',
          models: <Model>{
            ClassModel(
              isDeprecated: false,
              name: 'User',
              properties: const [],
              context: ctx,
              examples: const [],
            ),
          },
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

        final nameGenerator = NameGenerator();
        final stableModelSorter = StableModelSorter();
        final nameManager = _NonSendableThrowingNameManager(
          generator: nameGenerator,
          stableModelSorter: stableModelSorter,
        )
          ..prime(
            models: apiDoc.models,
            responses: apiDoc.responses,
            requestBodies: apiDoc.requestBodies,
            operations: apiDoc.operations,
            tags: apiDoc.operationsByTag.keys,
            servers: apiDoc.servers,
          )
          ..armed = true;

        Object? capturedError;
        await ModelWorkerPool()
            .run(
              apiDocument: apiDoc,
              nameManager: nameManager,
              stableModelSorter: stableModelSorter,
              outputDirectory: tempDir.path,
              package: _package,
              useImmutableCollections: false,
              workerCount: 1,
            )
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () => fail(
                'pool silently hung on non-sendable worker error',
              ),
            )
            .catchError((Object e) {
              capturedError = e;
            });

        expect(
          capturedError,
          isNotNull,
          reason: 'a non-sendable worker error must surface as some '
              'thrown error, not be swallowed into a hang',
        );
        expect(
          capturedError.toString(),
          contains('non-sendable'),
          reason: 'fallback carrier should identify itself so users can '
              'tell sendable rethrow apart from stringified fallback',
        );
        expect(
          capturedError.toString(),
          contains('_PortBearingError'),
          reason: 'fallback carrier should preserve the original '
              'runtime type name in its message',
        );
      },
    );

    test('aborts when worker setup throws before handshake', () async {
      final apiDoc = ApiDocument(
        title: 'Test',
        version: '1.0.0',
        description: 'Test',
        models: <Model>{
          ClassModel(
            isDeprecated: false,
            name: 'User',
            properties: const [],
            context: ctx,
            examples: const [],
          ),
        },
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

      final nameGenerator = NameGenerator();
      final stableModelSorter = StableModelSorter();
      final nameManager = _ConstructorThrowingNameManager(
        generator: nameGenerator,
        stableModelSorter: stableModelSorter,
      )
        ..prime(
          models: apiDoc.models,
          responses: apiDoc.responses,
          requestBodies: apiDoc.requestBodies,
          operations: apiDoc.operations,
          tags: apiDoc.operationsByTag.keys,
          servers: apiDoc.servers,
        )
        ..armed = true;

      Object? capturedError;
      await ModelWorkerPool()
          .run(
            apiDocument: apiDoc,
            nameManager: nameManager,
            stableModelSorter: stableModelSorter,
            outputDirectory: tempDir.path,
            package: _package,
            useImmutableCollections: false,
            workerCount: 1,
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => fail(
              'pool silently hung on worker setup/handshake-time throw',
            ),
          )
          .catchError((Object e) {
            capturedError = e;
          });

      expect(
        capturedError,
        isNotNull,
        reason: 'a worker setup-time throw must surface as a thrown error, '
            'not a silent hang on Future.wait(handshakeCompleters)',
      );
    });

    test(
      'forwarded log records reach main Logger.root with original level + name',
      () async {
        final apiDoc = _allSubtypeModelDocument(ctx);

        final outDir = Directory(path.join(tempDir.path, 'logout'))
          ..createSync();

        final setup = _buildSerial();
        _primeBoth(setup.nameManager, apiDoc);

        final previousLevel = Logger.root.level;
        Logger.root.level = Level.ALL;
        final forwarded = <LogRecord>[];
        final sub = Logger.root.onRecord.listen(forwarded.add);

        try {
          await ModelWorkerPool().run(
            apiDocument: apiDoc,
            nameManager: setup.nameManager,
            stableModelSorter: setup.stableModelSorter,
            outputDirectory: outDir.path,
            package: _package,
            useImmutableCollections: false,
            workerCount: 2,
          );
        } finally {
          await sub.cancel();
          Logger.root.level = previousLevel;
        }

        final modelGeneratorRecords = forwarded
            .where((r) => r.loggerName == 'ModelGenerator')
            .toList();
        expect(modelGeneratorRecords, isNotEmpty);
        expect(
          modelGeneratorRecords.first.level,
          Level.FINE,
          reason: 'canonical Level (preserving name + value) should '
              'round-trip via _WorkerLog',
        );
        expect(modelGeneratorRecords.first.level.name, Level.FINE.name);
      },
    );

    test('removes main Logger.root subscription after run returns', () async {
      final apiDoc = _allSubtypeModelDocument(ctx);
      final outDir = Directory(path.join(tempDir.path, 'cleanout'))
        ..createSync();

      final setup = _buildSerial();
      _primeBoth(setup.nameManager, apiDoc);

      await ModelWorkerPool().run(
        apiDocument: apiDoc,
        nameManager: setup.nameManager,
        stableModelSorter: setup.stableModelSorter,
        outputDirectory: outDir.path,
        package: _package,
        useImmutableCollections: false,
        workerCount: 2,
      );

      final recordsAfter = <LogRecord>[];
      final sub = Logger.root.onRecord.listen(recordsAfter.add);
      Logger('test-after-run').warning('post-run');
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(
        recordsAfter.where((r) => r.loggerName == 'test-after-run').length,
        1,
        reason: 'only the test listener should observe new records — '
            'pool listeners must be torn down',
      );
    });

    test('terminates all isolates after run completes successfully', () async {
      final apiDoc = _allSubtypeModelDocument(ctx);
      final outDir = Directory(path.join(tempDir.path, 'isolateout'))
        ..createSync();

      final setup = _buildSerial();
      _primeBoth(setup.nameManager, apiDoc);

      final pool = ModelWorkerPool();
      await pool.run(
        apiDocument: apiDoc,
        nameManager: setup.nameManager,
        stableModelSorter: setup.stableModelSorter,
        outputDirectory: outDir.path,
        package: _package,
        useImmutableCollections: false,
        workerCount: 2,
      );

      expect(pool.spawnedWorkers, 2);
      expect(pool.exitedWorkers, pool.spawnedWorkers);
    });

    test('terminates all isolates after run fails', () async {
      final apiDoc = _allSubtypeModelDocument(ctx);

      final setup = _buildSerial();
      _primeBoth(setup.nameManager, apiDoc);

      final pool = ModelWorkerPool();
      try {
        await pool.run(
          apiDocument: apiDoc,
          nameManager: setup.nameManager,
          stableModelSorter: setup.stableModelSorter,
          outputDirectory: '/no/such/dir/and/cannot/be/made',
          package: _package,
          useImmutableCollections: false,
          workerCount: 2,
        );
        fail('expected failure');
      } on Object catch (_) {
        // expected
      }

      expect(pool.spawnedWorkers, 2);
      expect(pool.exitedWorkers, pool.spawnedWorkers);
    });

    test('throws ArgumentError when workerCount is below 1', () {
      final apiDoc = _allSubtypeModelDocument(ctx);
      final setup = _buildSerial();
      _primeBoth(setup.nameManager, apiDoc);

      expect(
        () => ModelWorkerPool().run(
          apiDocument: apiDoc,
          nameManager: setup.nameManager,
          stableModelSorter: setup.stableModelSorter,
          outputDirectory: tempDir.path,
          package: _package,
          useImmutableCollections: false,
          workerCount: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('returns immediately when models set is empty', () async {
      final apiDoc = ApiDocument(
        title: 'Test',
        version: '1.0.0',
        models: const <Model>{},
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

      final setup = _buildSerial();
      _primeBoth(setup.nameManager, apiDoc);

      await ModelWorkerPool().run(
        apiDocument: apiDoc,
        nameManager: setup.nameManager,
        stableModelSorter: setup.stableModelSorter,
        outputDirectory: tempDir.path,
        package: _package,
        useImmutableCollections: false,
        workerCount: 4,
      );

      expect(
        Directory(
          path.join(tempDir.path, _package, 'lib', 'src', 'model'),
        ).existsSync(),
        isFalse,
      );
    });
  });
}

/// NameManager that, once [armed] is set, throws a non-sendable error
/// (carrying a live [ReceivePort]) on the next `modelName` lookup.
/// Arming after `prime()` lets the worker — but not the main isolate —
/// trip the throw, exercising the fallback path of `_sendModelError`.
class _NonSendableThrowingNameManager extends NameManager {
  _NonSendableThrowingNameManager({
    required super.generator,
    required super.stableModelSorter,
  });

  bool armed = false;

  @override
  String modelName(Model model) {
    if (armed) throw _PortBearingError(ReceivePort());
    return super.modelName(model);
  }
}

/// NameManager that, once [armed], throws synchronously on `modelName`
/// — used to provoke a worker-side throw from the per-job dispatch loop
/// and prove main never silently hangs.
class _ConstructorThrowingNameManager extends NameManager {
  _ConstructorThrowingNameManager({
    required super.generator,
    required super.stableModelSorter,
  });

  bool armed = false;

  @override
  String modelName(Model model) {
    if (armed) throw StateError('synthetic worker setup failure');
    return super.modelName(model);
  }
}

class _PortBearingError implements Exception {
  _PortBearingError(this.port);
  final ReceivePort port;
  @override
  String toString() => 'PortBearingError carrying $port';
}

/// NameManager that, once [armed], schedules an unawaited future that
/// throws asynchronously on the first call — bypassing the worker's
/// per-job `try/catch` and triggering the isolate `onError` channel.
/// Schedules only once so the worker still processes models 2..N normally;
/// the async error fires while remaining jobs are in flight, making the
/// arrival order at main deterministic (errorPort lands before all acks).
class _AsyncCrashingNameManager extends NameManager {
  _AsyncCrashingNameManager({
    required super.generator,
    required super.stableModelSorter,
  });

  bool armed = false;
  bool _fired = false;

  @override
  String modelName(Model model) {
    if (armed && !_fired) {
      _fired = true;
      unawaited(
        Future<void>.microtask(() {
          throw StateError('synthetic async crash');
        }),
      );
    }
    return super.modelName(model);
  }
}
