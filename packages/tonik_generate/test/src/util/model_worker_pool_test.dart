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

void main() {
  group('ModelWorkerPool.run', () {
    late Directory tempDir;
    late ApiDocument apiDoc;
    late NameManager nameManager;
    late StableModelSorter sorter;
    late ModelFileGenerator serialGenerator;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('model_worker_pool_');
      apiDoc = _allSubtypeDocument(Context.initial());
      sorter = StableModelSorter();
      nameManager = _prime(_makeNameManager(sorter), apiDoc);
      serialGenerator = _serialGenerator(nameManager, sorter);
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    Future<void> runPool({
      ApiDocument? doc,
      NameManager? names,
      String? outputDirectory,
      int workerCount = 2,
    }) {
      return ModelWorkerPool().run(
        apiDocument: doc ?? apiDoc,
        nameManager: names ?? nameManager,
        stableModelSorter: sorter,
        outputDirectory: outputDirectory ?? tempDir.path,
        package: _package,
        useImmutableCollections: false,
        workerCount: workerCount,
      );
    }

    test('produces byte-identical file tree as serial writeFiles', () async {
      final serialDir = Directory(path.join(tempDir.path, 'serial'))
        ..createSync();
      final parallelDir = Directory(path.join(tempDir.path, 'parallel'))
        ..createSync();

      serialGenerator.writeFiles(
        apiDocument: apiDoc,
        outputDirectory: serialDir.path,
        package: _package,
      );

      // Fresh NameManager — naming has mutable state we don't want to
      // share between the two runs.
      final parallelNames = _prime(_makeNameManager(sorter), apiDoc);
      await runPool(names: parallelNames, outputDirectory: parallelDir.path);

      expect(
        _readModelTree(parallelDir.path),
        _readModelTree(serialDir.path),
      );
    });

    test(
      'rethrows worker error with original concrete type and worker stack',
      () async {
        try {
          await runPool(
            outputDirectory: _unwritableDirectory(tempDir),
            workerCount: 1,
          );
          fail('expected the worker write to throw');
        } on FileSystemException catch (_, stack) {
          expect(stack.toString(), contains('model_file_generator.dart'));
        }
      },
    );

    test('surfaces uncaught async errors as ModelWorkerAsyncError', () async {
      // Many models behind a single worker so the async crash scheduled on
      // the first lookup lands at main before the worker has acked all jobs.
      final hooked = _HookedNameManager(sorter)
        ..onLookup = _oneShot(() {
          unawaited(
            Future<void>.microtask(
              () => throw StateError('synthetic async crash'),
            ),
          );
        });
      _prime(hooked, apiDoc).armed = true;

      try {
        await runPool(names: hooked, workerCount: 1)
            .timeout(const Duration(seconds: 15));
        fail('expected ModelWorkerAsyncError');
      } on TimeoutException {
        fail('pool silently hung on uncaught async worker error');
      } on ModelWorkerAsyncError catch (e) {
        expect(e.toString(), contains('synthetic async crash'));
      }
    });

    test('aborts (does not hang) when worker throws non-sendable error',
        () async {
      final hooked = _HookedNameManager(sorter)
        ..onLookup = () => throw _PortBearingError(ReceivePort());
      _prime(hooked, apiDoc).armed = true;

      try {
        await runPool(names: hooked, workerCount: 1)
            .timeout(const Duration(seconds: 15));
        fail('expected the non-sendable error to surface');
      } on TimeoutException {
        fail('pool silently hung on non-sendable worker error');
      } on NonSendableWorkerError catch (e) {
        expect(e.originalTypeName, contains('_PortBearingError'));
      }
    });

    test('aborts when worker setup throws before handshake', () async {
      final hooked = _HookedNameManager(sorter)
        ..onLookup = () => throw StateError('synthetic worker setup failure');
      _prime(hooked, apiDoc).armed = true;

      await expectLater(
        runPool(names: hooked, workerCount: 1)
            .timeout(const Duration(seconds: 15)),
        throwsA(isA<StateError>()),
      );
    });

    test(
      'forwards Logger records to main with original level and logger name',
      () async {
        final records = await _captureRecords(runPool);
        final modelGenRecord = records.firstWhere(
          (r) => r.loggerName == 'ModelGenerator',
        );

        expect(modelGenRecord.level, Level.FINE);
      },
    );

    test(
      'forwards log.warning attached error as stringified type name '
      'with reconstructable stack',
      () async {
        final hooked = _HookedNameManager(sorter)
          ..onLookup = _oneShot(() {
            try {
              throw _AttachedException('synthetic warning payload');
            } on _AttachedException catch (e, s) {
              Logger('TestWorkerLogger').warning('attached error log', e, s);
            }
          });
        _prime(hooked, apiDoc).armed = true;

        final records = await _captureRecords(
          () => runPool(names: hooked, workerCount: 1),
        );
        final warning = records.firstWhere(
          (r) => r.loggerName == 'TestWorkerLogger' && r.level == Level.WARNING,
        );

        expect(warning.error, isA<String>());
        expect(warning.error! as String, contains('_AttachedException'));
        expect(warning.stackTrace.toString(), isNotEmpty);
      },
    );

    test('removes pool listeners from Logger.root after run returns', () async {
      await runPool();

      final recordsAfter = <LogRecord>[];
      final sub = Logger.root.onRecord.listen(recordsAfter.add);
      Logger('test-after-run').warning('post-run');
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(
        recordsAfter.where((r) => r.loggerName == 'test-after-run'),
        hasLength(1),
      );
    });

    test('terminates all isolates after run completes successfully', () async {
      final pool = ModelWorkerPool();
      await pool.run(
        apiDocument: apiDoc,
        nameManager: nameManager,
        stableModelSorter: sorter,
        outputDirectory: tempDir.path,
        package: _package,
        useImmutableCollections: false,
        workerCount: 2,
      );

      expect(pool.spawnedWorkers, 2);
      expect(pool.exitedWorkers, pool.spawnedWorkers);
    });

    test('terminates all isolates after run fails', () async {
      final pool = ModelWorkerPool();
      try {
        await pool.run(
          apiDocument: apiDoc,
          nameManager: nameManager,
          stableModelSorter: sorter,
          outputDirectory: _unwritableDirectory(tempDir),
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
      expect(
        () => runPool(workerCount: 0),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('returns immediately when models set is empty', () async {
      final empty = _emptyDocument();
      final names = _prime(_makeNameManager(sorter), empty);

      await runPool(doc: empty, names: names, workerCount: 4);

      final modelDir = Directory(
        path.join(tempDir.path, _package, 'lib', 'src', 'model'),
      );
      expect(modelDir.existsSync(), isFalse);
    });
  });
}

NameManager _makeNameManager(StableModelSorter sorter) => NameManager(
  generator: NameGenerator(),
  stableModelSorter: sorter,
);

T _prime<T extends NameManager>(T names, ApiDocument doc) {
  names.prime(
    models: doc.models,
    responses: doc.responses,
    requestBodies: doc.requestBodies,
    operations: doc.operations,
    tags: doc.operationsByTag.keys,
    servers: doc.servers,
  );
  return names;
}

ModelFileGenerator _serialGenerator(
  NameManager names,
  StableModelSorter sorter,
) {
  return ModelFileGenerator(
    classGenerator: ClassGenerator(nameManager: names, package: _package),
    enumGenerator: EnumGenerator(nameManager: names),
    anyOfGenerator: AnyOfGenerator(
      nameManager: names,
      package: _package,
      stableModelSorter: sorter,
    ),
    oneOfGenerator: OneOfGenerator(
      nameManager: names,
      package: _package,
      stableModelSorter: sorter,
    ),
    typedefGenerator: TypedefGenerator(
      nameManager: names,
      package: _package,
    ),
    allOfGenerator: AllOfGenerator(
      nameManager: names,
      package: _package,
      stableModelSorter: sorter,
    ),
  );
}

/// Returns a path whose creation as a directory will always fail. Pointing
/// `outputDirectory` here lets workers exercise the `FileSystemException`
/// path on every OS — `mkdir` under a regular file is rejected by Windows
/// and POSIX alike, with no permission assumptions on `/`.
String _unwritableDirectory(Directory tempDir) {
  final blocker = File(path.join(tempDir.path, 'blocker'));
  if (!blocker.existsSync()) blocker.writeAsStringSync('x');
  return path.join(blocker.path, 'sub');
}

Map<String, String> _readModelTree(String root) {
  final modelDir = Directory(path.join(root, _package, 'lib', 'src', 'model'));
  if (!modelDir.existsSync()) return const {};
  final entries = modelDir.listSync().whereType<File>().toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  return {
    for (final file in entries)
      path.basename(file.path): file.readAsStringSync(),
  };
}

/// Runs [body] with `Logger.root` at [Level.ALL] and returns every record
/// emitted during its execution.
Future<List<LogRecord>> _captureRecords(Future<void> Function() body) async {
  final previousLevel = Logger.root.level;
  Logger.root.level = Level.ALL;
  final records = <LogRecord>[];
  final sub = Logger.root.onRecord.listen(records.add);
  try {
    await body();
  } finally {
    await sub.cancel();
    Logger.root.level = previousLevel;
  }
  return records;
}

/// Wraps [action] so it runs at most once across repeated invocations.
void Function() _oneShot(void Function() action) {
  var fired = false;
  return () {
    if (fired) return;
    fired = true;
    action();
  };
}

ApiDocument _allSubtypeDocument(Context ctx) {
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
        values: {const EnumEntry(value: 1), const EnumEntry(value: 2)},
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
        models: {StringModel(context: ctx), IntegerModel(context: ctx)},
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

ApiDocument _emptyDocument() => ApiDocument(
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

/// NameManager that invokes [onLookup] on every `modelName` call once
/// [armed] is true. Replaces the family of one-off subclasses used to
/// exercise the worker pool's failure paths.
class _HookedNameManager extends NameManager {
  _HookedNameManager(StableModelSorter sorter)
    : super(generator: NameGenerator(), stableModelSorter: sorter);

  void Function() onLookup = () {};
  bool armed = false;

  @override
  String modelName(Model model) {
    if (armed) onLookup();
    return super.modelName(model);
  }
}

class _PortBearingError implements Exception {
  _PortBearingError(this.port);
  final ReceivePort port;
  @override
  String toString() => 'PortBearingError carrying $port';
}

class _AttachedException implements Exception {
  _AttachedException(this.message);
  final String message;
  @override
  String toString() => '_AttachedException: $message';
}
