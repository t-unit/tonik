import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:logging/logging.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/model/all_of_generator.dart';
import 'package:tonik_generate/src/model/any_of_generator.dart';
import 'package:tonik_generate/src/model/class_generator.dart';
import 'package:tonik_generate/src/model/enum_generator.dart';
import 'package:tonik_generate/src/model/model_file_generator.dart';
import 'package:tonik_generate/src/model/one_of_generator.dart';
import 'package:tonik_generate/src/model/typedef_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';

/// Carrier exception thrown by [ModelWorkerPool.run] when an uncaught async
/// error escaped a worker's top-level guard (e.g. an unawaited future
/// throwing). Dart's `Isolate.spawn(onError: ...)` channel stringifies the
/// original error and stack before delivery, so callers can use
/// `isA<ModelWorkerAsyncError>()` to distinguish this stringified async
/// path from a synchronous worker throw — the latter arrives with its
/// original concrete type via the internal `_ModelError` carrier.
class ModelWorkerAsyncError implements Exception {
  ModelWorkerAsyncError(this.message);
  final String message;

  @override
  String toString() => 'tonik model worker async error: $message';
}

/// Carrier exception thrown by [ModelWorkerPool.run] when a worker error
/// could not be transported across the [Isolate] boundary with its original
/// runtime type (e.g. the error held a live [ReceivePort]).
///
/// Preserves the textual error and the original runtime type name so log
/// messages remain useful; callers can use `isA<NonSendableWorkerError>()`
/// to distinguish this fallback from a sendable rethrow.
class NonSendableWorkerError implements Exception {
  const NonSendableWorkerError(this.message, this.originalTypeName);
  final String message;
  final String originalTypeName;

  @override
  String toString() =>
      'Worker error (original type $originalTypeName, non-sendable): $message';
}

/// Bounded pool of isolates that parallelise [ModelFileGenerator.writeOne]
/// across [Model]s.
///
/// Usage: instantiate, then `await pool.run(...)`. Each call to [run]
/// spins up the requested worker isolates, ships the shared read-only
/// state once, dispatches all models round-robin, and tears everything
/// down before returning.
class ModelWorkerPool {
  ModelWorkerPool({
    this.maxInflight = _defaultMaxInflight,
  });

  static const int _defaultMaxInflight = 256;

  /// Cap on concurrently outstanding jobs across all workers. Limits the
  /// peak memory used by generated `(filename, code)` pairs queued on
  /// worker outboxes while main has not yet processed their acks.
  final int maxInflight;

  int _exitedWorkers = 0;
  int _spawnedWorkers = 0;

  /// Number of isolates this pool has spawned across all invocations of
  /// [run] on this instance.
  int get spawnedWorkers => _spawnedWorkers;

  /// Number of isolates this pool has confirmed exited across all
  /// invocations of [run]. Equal to [spawnedWorkers] after every
  /// successful or failed [run] returns.
  int get exitedWorkers => _exitedWorkers;

  /// Dispatches every model in [apiDocument] to a pool of `workerCount`
  /// isolates, awaits all acks (or rethrows the first worker error), and
  /// shuts the pool down.
  ///
  /// The caller's `Logger.root.onRecord` listeners receive forwarded
  /// records from workers with the original [Level] and logger name
  /// preserved.
  Future<void> run({
    required ApiDocument apiDocument,
    required NameManager nameManager,
    required StableModelSorter stableModelSorter,
    required String outputDirectory,
    required String package,
    required bool useImmutableCollections,
    required int workerCount,
  }) async {
    if (workerCount < 1) {
      throw ArgumentError.value(
        workerCount,
        'workerCount',
        'must be at least 1',
      );
    }

    final models = apiDocument.models.toList(growable: false);
    if (models.isEmpty) return;

    final effectiveWorkerCount = math.min(workerCount, models.length);

    final mainInbox = ReceivePort();
    final exitPort = ReceivePort();
    final errorPort = ReceivePort();
    final isolates = <Isolate>[];
    final workerInboxes = <SendPort>[];
    final handshakeCompleters = List<Completer<SendPort>>.generate(
      effectiveWorkerCount,
      (_) => Completer<SendPort>(),
    );
    final exitCompleters = List<Completer<void>>.generate(
      effectiveWorkerCount,
      (_) => Completer<void>(),
    );
    var nextExitSlot = 0;

    final completer = Completer<void>();
    var nextIndex = 0;
    var inflight = 0;
    var acked = 0;
    var aborted = false;
    var handshakesDone = false;
    Object? capturedSetupError;
    StackTrace? capturedSetupStack;

    final poolLog = Logger('ModelWorkerPool');

    void abortWith(Object error, StackTrace stack) {
      if (aborted) {
        // Surface — but do not act on — secondary worker errors so they
        // are at least visible in the log stream.
        poolLog.warning(
          'additional worker error suppressed after primary failure: $error',
          error,
          stack,
        );
        return;
      }
      aborted = true;
      capturedSetupError ??= error;
      capturedSetupStack ??= stack;
      // Force every still-pending handshake into the error path so any
      // `Future.wait` further down resolves instead of hanging forever.
      for (final c in handshakeCompleters) {
        if (!c.isCompleted) c.completeError(error, stack);
      }
      // Before all handshakes resolve, the run is awaiting `Future.wait`
      // on the handshake completers — they propagate the error. After
      // handshakes are done, the run is awaiting `completer.future`;
      // completeError there is what unblocks.
      if (handshakesDone && !completer.isCompleted) {
        completer.completeError(error, stack);
      }
    }

    late StreamSubscription<dynamic> mainSubscription;
    late StreamSubscription<dynamic> exitSubscription;
    late StreamSubscription<dynamic> errorSubscription;

    void dispatchNext() {
      if (aborted) return;
      while (nextIndex < models.length && inflight < maxInflight) {
        final idx = nextIndex++;
        workerInboxes[idx % workerInboxes.length].send(_ModelJob(idx));
        inflight++;
      }
      if (nextIndex >= models.length && inflight == 0 && !aborted) {
        if (!completer.isCompleted) completer.complete();
      }
    }

    errorSubscription = errorPort.listen((dynamic msg) {
      if (aborted) return;
      final parts = msg is List && msg.length >= 2 ? msg : ['$msg', ''];
      abortWith(
        ModelWorkerAsyncError('${parts[0]}'),
        StackTrace.fromString('${parts[1]}'),
      );
    });

    exitSubscription = exitPort.listen((dynamic _) {
      _exitedWorkers++;
      if (nextExitSlot < exitCompleters.length) {
        exitCompleters[nextExitSlot++].complete();
      }
      // Defer a microtask so a racing `_ModelError` or `errorPort` message
      // can land first and capture the real cause. Without this, an exit
      // notification that arrives microseconds before its underlying error
      // would clobber the real exception with the synthetic StateError below.
      scheduleMicrotask(() {
        if (aborted) return;
        final stillPending =
            handshakeCompleters.any((c) => !c.isCompleted) ||
            acked < models.length;
        if (!stillPending) return;
        final error =
            capturedSetupError ??
            StateError(
              'tonik model worker (id < $effectiveWorkerCount) exited '
              'unexpectedly before completing its assigned jobs '
              '(acked $acked of ${models.length}).',
            );
        final stack = capturedSetupStack ?? StackTrace.current;
        abortWith(error, stack);
      });
    });

    mainSubscription = mainInbox.listen((dynamic msg) {
      if (msg is _WorkerHandshake) {
        if (!handshakeCompleters[msg.workerId].isCompleted) {
          handshakeCompleters[msg.workerId].complete(msg.sendPort);
        }
        return;
      }
      if (msg is _ModelAck) {
        acked++;
        inflight--;
        dispatchNext();
        return;
      }
      if (msg is _ModelError) {
        // Setup-time failures bypass the inflight bookkeeping since no job
        // was outstanding when the worker died.
        if (!msg.isSetupFailure) inflight--;
        abortWith(msg.error, msg.stack);
        return;
      }
      if (msg is _WorkerLog) {
        Logger(msg.loggerName).log(
          _levelForValue(msg.levelValue, msg.levelName),
          msg.message,
          msg.error,
          msg.stackTrace == null
              ? null
              : StackTrace.fromString(msg.stackTrace!),
        );
        return;
      }
      // Protocol drift is a programming error, not a runtime warning —
      // any unknown message type means worker and main are out of sync.
      abortWith(
        StateError('protocol drift: unknown worker message ${msg.runtimeType}'),
        StackTrace.current,
      );
    });

    try {
      for (var i = 0; i < effectiveWorkerCount; i++) {
        final isolate = await Isolate.spawn<_WorkerInit>(
          _workerEntry,
          _WorkerInit(
            mainInbox: mainInbox.sendPort,
            workerId: i,
            models: models,
            nameManager: nameManager,
            outputDirectory: outputDirectory,
            package: package,
            useImmutableCollections: useImmutableCollections,
            stableModelSorter: stableModelSorter,
          ),
          // Surface uncaught async errors via errorPort so a dying
          // worker cannot leave main blocked on Future.wait. See
          // [ModelWorkerAsyncError] for the rationale on stringification.
          onExit: exitPort.sendPort,
          onError: errorPort.sendPort,
          debugName: 'tonik-model-worker-$i',
        );
        isolates.add(isolate);
        _spawnedWorkers++;
      }

      // If a worker exits early or errors out, its handshake completer
      // fires with the captured error (set by exitPort / errorPort
      // listeners through abortWith). That error propagates here, the
      // outer try/finally tears the pool down, and `run` rethrows.
      workerInboxes.addAll(
        await Future.wait(handshakeCompleters.map((c) => c.future)),
      );
      handshakesDone = true;

      dispatchNext();

      await completer.future;
    } finally {
      for (final port in workerInboxes) {
        try {
          port.send(const _Shutdown());
        } on Object {
          // Worker already dead; nothing to shut down.
        }
      }
      // Yield once so each worker has a chance to process the queued
      // `_Shutdown` and flush any final log records before we kill them.
      // Without this, a `Logger.warning` emitted in the same microtask as
      // shutdown can be lost.
      await Future<void>.delayed(Duration.zero);
      for (final isolate in isolates) {
        isolate.kill();
      }
      // Without this wait, the spawnedWorkers/exitedWorkers counters race
      // with the caller; tests cannot deterministically observe teardown.
      if (isolates.isNotEmpty) {
        await Future.wait(
          exitCompleters.take(isolates.length).map((c) => c.future),
        );
      }
      await mainSubscription.cancel();
      await exitSubscription.cancel();
      await errorSubscription.cancel();
      mainInbox.close();
      exitPort.close();
      errorPort.close();
    }

    if (!aborted && acked != models.length) {
      throw StateError(
        'ModelWorkerPool finished with $acked acks for ${models.length} '
        'models; some jobs were lost '
        '(spawned=$_spawnedWorkers, exited=$_exitedWorkers, '
        'inflight=$inflight, nextIndex=$nextIndex).',
      );
    }
  }
}

/// Resolves a [Level] for a forwarded record, preferring the canonical
/// [Level.LEVELS] entry by value so a record's display name (`FINE`,
/// `INFO`, ...) matches what the worker emitted. For non-canonical values
/// (user-installed custom levels), synthesises a [Level] from the
/// forwarded name+value — identity is not preserved across isolates.
Level _levelForValue(int value, String name) {
  for (final level in Level.LEVELS) {
    if (level.value == value) return level;
  }
  return Level(name, value);
}

void _sendModelError(
  SendPort mainInbox,
  int workerId, {
  required int? modelIndex,
  required Object error,
  required StackTrace stack,
}) {
  // First attempt forwards the originals — richer downstream because main
  // can `isA<ConcreteError>()` and read the original stack. If
  // [SendPort.send] rejects either object as non-sendable, we retry with
  // stringified copies so main is never left waiting on a `Future.wait`
  // for a worker that silently died inside its own catch block.
  try {
    mainInbox.send(
      _ModelError(
        workerId: workerId,
        modelIndex: modelIndex,
        error: error,
        stack: stack,
      ),
    );
    return;
  } on Object {
    // fall through to stringified fallback
  }
  try {
    mainInbox.send(
      _ModelError(
        workerId: workerId,
        modelIndex: modelIndex,
        error: NonSendableWorkerError(
          error.toString(),
          error.runtimeType.toString(),
        ),
        stack: StackTrace.fromString(stack.toString()),
      ),
    );
  } on Object {
    // Last resort: every send route refused. Best-effort breadcrumb to
    // stderr so the developer at least sees the original error before
    // main's exit listener observes the dying isolate and aborts.
    stderr.writeln(
      'tonik model worker $workerId: failed to forward error '
      '(${error.runtimeType}) to main: $error',
    );
  }
}

Future<void> _workerEntry(_WorkerInit init) async {
  // Top-level guard — any throw escaping below this point either inside
  // sub-generator construction, handshake, the per-job loop's outer
  // machinery, or an unawaited future, is forwarded to main as a
  // setup-time _ModelError. Without this the failure is swallowed by
  // the isolate's default error handler and main hangs on Future.wait.
  try {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      final log = _WorkerLog(
        levelValue: record.level.value,
        levelName: record.level.name,
        loggerName: record.loggerName,
        message: record.message,
        error: record.error?.toString(),
        stackTrace: record.stackTrace?.toString(),
      );
      try {
        init.mainInbox.send(log);
      } on Object {
        // Best-effort log forwarding; if the port is closed we silently
        // drop. Main has already aborted (or completed) in that case.
      }
    });

    final classGenerator = ClassGenerator(
      nameManager: init.nameManager,
      package: init.package,
      useImmutableCollections: init.useImmutableCollections,
    );
    final enumGenerator = EnumGenerator(nameManager: init.nameManager);
    final oneOfGenerator = OneOfGenerator(
      nameManager: init.nameManager,
      package: init.package,
      stableModelSorter: init.stableModelSorter,
      useImmutableCollections: init.useImmutableCollections,
    );
    final anyOfGenerator = AnyOfGenerator(
      nameManager: init.nameManager,
      package: init.package,
      stableModelSorter: init.stableModelSorter,
      useImmutableCollections: init.useImmutableCollections,
    );
    final typedefGenerator = TypedefGenerator(
      nameManager: init.nameManager,
      package: init.package,
      useImmutableCollections: init.useImmutableCollections,
    );
    final allOfGenerator = AllOfGenerator(
      nameManager: init.nameManager,
      package: init.package,
      stableModelSorter: init.stableModelSorter,
      useImmutableCollections: init.useImmutableCollections,
    );

    final modelFileGenerator = ModelFileGenerator(
      classGenerator: classGenerator,
      enumGenerator: enumGenerator,
      anyOfGenerator: anyOfGenerator,
      oneOfGenerator: oneOfGenerator,
      typedefGenerator: typedefGenerator,
      allOfGenerator: allOfGenerator,
    );

    final inbox = ReceivePort();
    init.mainInbox.send(_WorkerHandshake(init.workerId, inbox.sendPort));

    await for (final msg in inbox) {
      if (msg is _ModelJob) {
        try {
          modelFileGenerator.writeOne(
            init.models[msg.modelIndex],
            outputDirectory: init.outputDirectory,
            package: init.package,
          );
          init.mainInbox.send(_ModelAck(init.workerId, msg.modelIndex));
        } on Object catch (error, stack) {
          _sendModelError(
            init.mainInbox,
            init.workerId,
            modelIndex: msg.modelIndex,
            error: error,
            stack: stack,
          );
        }
      } else if (msg is _Shutdown) {
        inbox.close();
        return;
      }
    }
  } on Object catch (error, stack) {
    _sendModelError(
      init.mainInbox,
      init.workerId,
      modelIndex: null,
      error: error,
      stack: stack,
    );
  }
}

class _WorkerInit {
  const _WorkerInit({
    required this.mainInbox,
    required this.workerId,
    required this.models,
    required this.nameManager,
    required this.outputDirectory,
    required this.package,
    required this.useImmutableCollections,
    required this.stableModelSorter,
  });

  final SendPort mainInbox;
  final int workerId;
  final List<Model> models;
  final NameManager nameManager;
  final String outputDirectory;
  final String package;
  final bool useImmutableCollections;
  final StableModelSorter stableModelSorter;
}

class _ModelJob {
  const _ModelJob(this.modelIndex);
  final int modelIndex;
}

class _Shutdown {
  const _Shutdown();
}

class _ModelAck {
  const _ModelAck(this.workerId, this.modelIndex);
  final int workerId;
  final int modelIndex;
}

/// [error] and [stack] may be the original objects (if sendable across the
/// isolate boundary) or fallback stringified copies. A null [modelIndex]
/// flags a worker that died outside the per-job dispatch loop (handshake,
/// sub-generator construction, uncaught async error inside the top-level
/// guard); main does not decrement `inflight` for those.
class _ModelError {
  const _ModelError({
    required this.workerId,
    required this.modelIndex,
    required this.error,
    required this.stack,
  });
  final int workerId;
  final int? modelIndex;
  final Object error;
  final StackTrace stack;

  bool get isSetupFailure => modelIndex == null;
}

/// The boundary stringifies `error` and `stackTrace` because
/// [LogRecord.error] may hold a non-sendable Object. Listeners on
/// `Logger.root` that branched on `record.error is SomeException` will
/// not behave the same under the parallel path — they observe a `String`
/// instead of the original type. `record.time` on the replayed entry is
/// set by main, not the worker.
class _WorkerLog {
  const _WorkerLog({
    required this.levelValue,
    required this.levelName,
    required this.loggerName,
    required this.message,
    required this.error,
    required this.stackTrace,
  });

  final int levelValue;
  final String levelName;
  final String loggerName;
  final String message;
  final String? error;
  final String? stackTrace;
}

class _WorkerHandshake {
  const _WorkerHandshake(this.workerId, this.sendPort);
  final int workerId;
  final SendPort sendPort;
}
