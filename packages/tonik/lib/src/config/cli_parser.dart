import 'package:args/args.dart';
import 'package:tonik/src/config/cli_config.dart';
import 'package:tonik/src/config/config_loader.dart';
import 'package:tonik/src/config/log_level.dart';
import 'package:tonik_core/tonik_core.dart';

/// Builds the argument parser used by the Tonik executable.
ArgParser buildCliParser() {
  return ArgParser()
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Print this usage information.',
    )
    ..addOption(
      'config',
      abbr: 'c',
      help: 'Path to configuration file (defaults to tonik.yaml).',
      valueHelp: 'path',
    )
    ..addOption(
      'output-dir',
      abbr: 'o',
      help: 'Directory where generated project will be placed.',
      valueHelp: 'path',
    )
    ..addOption(
      'package-name',
      abbr: 'p',
      help: 'Name of the package to generate.',
      valueHelp: 'name',
    )
    ..addOption(
      'spec',
      help: 'Path to OpenAPI document.',
      abbr: 's',
      valueHelp: 'path',
    )
    ..addOption(
      'log-level',
      help: 'Set the logging level (verbose, info, warn, silent).',
      allowed: ['verbose', 'info', 'warn', 'silent'],
    )
    ..addOption(
      'backend',
      help: 'Set the generated transport backend (dio or http).',
      allowed: ['dio', 'http'],
    )
    ..addFlag(
      'immutable-collections',
      help:
          'Use IList/IMap from fast_immutable_collections '
          'instead of List/Map.',
      negatable: false,
    )
    ..addOption(
      'workers',
      help:
          'Number of worker isolates for parallel model file generation. '
          '0 (default) auto-sizes to (numberOfProcessors - 1) clamped '
          'to 1..16; 1 forces serial; >= 2 sets the worker count.',
      valueHelp: 'n',
    );
}

/// Merges parsed CLI arguments over a file configuration.
///
/// [environmentWorkerCount] supports the existing `TONIK_WORKERS` fallback.
/// There is deliberately no environment-variable transport override.
CliConfig mergeCliConfig({
  required ArgResults arguments,
  required CliConfig fileConfig,
  String? environmentWorkerCount,
}) {
  final cliWorkerCount = _parseWorkerCount(
    arguments.option('workers'),
    source: '--workers',
  );
  // File's `0` is unset for precedence purposes (the documented default).
  final environmentWorkers =
      cliWorkerCount != null || fileConfig.workerCount != 0
      ? null
      : _parseWorkerCount(environmentWorkerCount, source: 'TONIK_WORKERS');

  return fileConfig.merge(
    spec: arguments.option('spec'),
    outputDir: arguments.option('output-dir'),
    packageName: arguments.option('package-name'),
    logLevel: switch (arguments.option('log-level')) {
      null => null,
      'verbose' => LogLevel.verbose,
      'info' => LogLevel.info,
      'warn' => LogLevel.warn,
      'silent' => LogLevel.silent,
      final value => throw FormatException(
        'Invalid log level "$value". '
        'Must be one of: verbose, info, warn, silent',
      ),
    },
    backend: switch (arguments.option('backend')) {
      null => null,
      'dio' => TransportBackend.dio,
      'http' => TransportBackend.http,
      final value => throw FormatException(
        'Invalid backend "$value". Must be one of: dio, http',
      ),
    },
    useImmutableCollections: arguments.flag('immutable-collections')
        ? true
        : null,
    workerCount: cliWorkerCount ?? environmentWorkers,
  );
}

int? _parseWorkerCount(String? raw, {required String source}) {
  if (raw == null || raw.isEmpty) {
    return null;
  }
  final parsed = int.tryParse(raw);
  if (parsed == null || parsed < 0) {
    throw FormatException('Invalid value "$raw" for $source.');
  }
  return parsed;
}
