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

/// Uncaught async worker error. Dart's isolate `onError` channel
/// stringifies the original error before delivery, so the concrete type is
/// only recoverable for sync throws (those arrive via the internal
/// `_ModelError`).
class ModelWorkerAsyncError implements Exception {
  ModelWorkerAsyncError(this.message);
  final String message;

  @override
  String toString() => 'tonik model worker async error: $message';
}

/// Worker error whose original runtime type could not cross the isolate
/// boundary (e.g. held a live [ReceivePort]). [originalTypeName] preserves
/// it for diagnostics.
class NonSendableWorkerError implements Exception {
  const NonSendableWorkerError(this.message, this.originalTypeName);
  final String message;
  final String originalTypeName;

  @override
  String toString() =>
      'Worker error (original type $originalTypeName, non-sendable): $message';
}

/// Bounded isolate pool that parallelises [ModelFileGenerator.writeOne]
/// across [Model]s. Forwards `Logger.root` records from workers to main
/// with their original [Level] and logger name preserved.
class ModelWorkerPool {
  ModelWorkerPool({
    this.maxInflight = _defaultMaxInflight,
  });

  static const int _defaultMaxInflight = 256;

  /// Cap on outstanding jobs across all workers; bounds peak memory of
  /// queued `(filename, code)` pairs.
  final int maxInflight;

  int _exitedWorkers = 0;
  int _spawnedWorkers = 0;

  int get spawnedWorkers => _spawnedWorkers;

  /// Equal to [spawnedWorkers] after every [run] returns.
  int get exitedWorkers => _exitedWorkers;

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
      // Unblock whichever await is current: handshakes during setup,
      // `completer.future` afterwards.
      for (final c in handshakeCompleters) {
        if (!c.isCompleted) c.completeError(error, stack);
      }
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
      // Defer so a racing `_ModelError` / `errorPort` can capture the real
      // cause before we synthesise the watchdog StateError.
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
      // Unknown message = worker/main protocol drift (programming error).
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
          onExit: exitPort.sendPort,
          onError: errorPort.sendPort,
          debugName: 'tonik-model-worker-$i',
        );
        isolates.add(isolate);
        _spawnedWorkers++;
      }

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
      // Let workers drain queued logs before kill.
      await Future<void>.delayed(Duration.zero);
      for (final isolate in isolates) {
        isolate.kill();
      }
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

/// Custom user-installed [Level]s do not round-trip — identity is lost.
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
  // Try original objects first (richer), fall back to stringified copies
  // if `SendPort.send` rejects them as non-sendable — main must never be
  // left waiting on `Future.wait` for a worker that died in its own catch.
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
    // ignore: retry with stringified copies below.
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
    // Both sends refused — leave a breadcrumb before the isolate dies.
    stderr.writeln(
      'tonik model worker $workerId: failed to forward error '
      '(${error.runtimeType}) to main: $error',
    );
  }
}

Future<void> _workerEntry(_WorkerInit init) async {
  // Top-level guard: anything escaping below is forwarded to main as a
  // setup-time _ModelError so main never hangs on `Future.wait`.
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
        // Best-effort: main has aborted or completed, drop the record.
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

/// [error]/[stack] are the originals when sendable, stringified otherwise.
/// `modelIndex == null` flags a setup-time failure (no inflight to release).
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

/// `error`/`stackTrace` are stringified at the boundary; `record.error is
/// SomeException` checks in main listeners will not match.
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
