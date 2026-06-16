import 'dart:io';

import 'package:args/args.dart';
import 'package:logging/logging.dart';
import 'package:tonik/src/config/config_loader.dart';
import 'package:tonik/src/config/log_level.dart';
import 'package:tonik/src/openapi_loader.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/tonik_generate.dart';
import 'package:tonik_parse/tonik_parse.dart';

const issueUrl = 'https://github.com/t-unit/tonik/issues';

ArgParser buildParser() {
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

void printUsage(ArgParser argParser) {
  print('Usage: tonik <flags> [arguments]');
  print(argParser.usage);
}

final Logger logger = Logger('tonik');

int? _parseWorkerCountOrExit(String? raw, {required String source}) {
  if (raw == null || raw.isEmpty) return null;
  final parsed = int.tryParse(raw);
  if (parsed == null || parsed < 0) {
    stderr.writeln('Error: invalid value "$raw" for $source.');
    exit(128);
  }
  return parsed;
}

Future<void> main(List<String> arguments) async {
  final argParser = buildParser();
  String? logLevelArg;
  String? packageNameArg;
  String? openApiPathArg;
  String? outputDirArg;
  String? configPathArg;
  var immutableCollectionsArg = false;
  String? workersArg;

  try {
    final results = argParser.parse(arguments);

    if (results.flag('help')) {
      printUsage(argParser);
      return;
    }

    logLevelArg = results['log-level'] as String?;
    packageNameArg = results['package-name'] as String?;
    openApiPathArg = results['spec'] as String?;
    outputDirArg = results['output-dir'] as String?;
    configPathArg = results['config'] as String?;
    immutableCollectionsArg = results.flag('immutable-collections');
    workersArg = results['workers'] as String?;
  } on FormatException catch (formatException) {
    print(formatException.message);
    printUsage(argParser);
    exit(128);
  } on Object catch (_) {
    printUsage(argParser);
    exit(128);
  }

  final cliLogLevel = switch (logLevelArg) {
    null => null,
    'verbose' => LogLevel.verbose,
    'info' => LogLevel.info,
    'warn' => LogLevel.warn,
    'silent' => LogLevel.silent,
    _ => () {
      print(
        'Error: Invalid log level "$logLevelArg". '
        'Must be one of: verbose, info, warn, silent',
      );
      exit(128);
    }(),
  };

  final configPath = configPathArg ?? 'tonik.yaml';
  final fileConfig = ConfigLoader.load(configPath);

  final cliWorkerCount = _parseWorkerCountOrExit(
    workersArg,
    source: '--workers',
  );
  // Env only consulted when neither CLI nor file specified a value. File's
  // `0` is the documented default and equivalent to unset for precedence,
  // so we fall through to env in that case.
  final envWorkerCount =
      cliWorkerCount != null || fileConfig.workerCount != 0
      ? null
      : _parseWorkerCountOrExit(
          Platform.environment['TONIK_WORKERS'],
          source: 'TONIK_WORKERS',
        );

  final mergedConfig = fileConfig.merge(
    spec: openApiPathArg,
    outputDir: outputDirArg,
    packageName: packageNameArg,
    logLevel: cliLogLevel,
    useImmutableCollections: immutableCollectionsArg ? true : null,
    workerCount: cliWorkerCount ?? envWorkerCount,
  );

  final packageName = mergedConfig.packageName;
  final openApiPath = mergedConfig.spec;
  final outputDir = mergedConfig.outputDir;
  final logLevel = mergedConfig.logLevel;

  if (packageName == null) {
    print('Error: --package-name is required (or specify in tonik.yaml)');
    printUsage(argParser);
    exit(128);
  }

  if (openApiPath == null) {
    print('Error: --spec is required (or specify in tonik.yaml)');
    printUsage(argParser);
    exit(128);
  }

  Logger.root.level = switch (logLevel) {
    LogLevel.verbose => Level.FINEST,
    LogLevel.info => Level.INFO,
    LogLevel.warn => Level.WARNING,
    LogLevel.silent => Level.OFF,
    null => Level.WARNING,
  };

  Logger.root.onRecord.listen((record) {
    final displayLevel = switch (record.level) {
      Level.ALL ||
      Level.FINEST ||
      Level.FINER ||
      Level.FINE ||
      Level.CONFIG => 'verbose',
      Level.INFO => 'info',
      Level.WARNING => 'warn',
      Level.SEVERE || Level.SHOUT => 'error',
      _ => 'error',
    };

    print('[$displayLevel] ${record.message}');
    if (record.error != null) {
      print('${record.error}');
    }
    if (record.stackTrace != null) {
      print('${record.stackTrace}');
    }
  });

  logger
    ..info('Starting Tonik')
    ..fine('Package name: $packageName')
    ..fine('OpenAPI document: $openApiPath')
    ..fine('Output directory: $outputDir');

  Map<String, dynamic> apiSpec;
  try {
    apiSpec = loadOpenApiDocument(openApiPath);
    logger.info('Successfully loaded OpenAPI document');
  } on OpenApiLoaderException catch (e) {
    logger.severe(e.message);
    exit(1);
  } on Object catch (e, s) {
    logger
      ..fine('Failed to load OpenAPI document', e, s)
      ..severe(
        'Unexpected error while loading OpenAPI document. '
        'Make sure to run with verbose logging and report this issue at '
        '$issueUrl',
      );
    exit(1);
  }

  ApiDocument apiDocument;
  try {
    apiDocument = Importer(
      contentTypes: mergedConfig.contentTypes,
      contentMediaTypes: mergedConfig.contentMediaTypes,
    ).import(apiSpec);
    logger.info('Successfully parsed OpenAPI document');
  } on Object catch (e, s) {
    logger
      ..fine('Failed to parse OpenAPI document', e, s)
      ..severe(
        'Unexpected error while parsing OpenAPI document. '
        'If you think your document is valid, please run '
        'with verbose logging and report this issue at $issueUrl',
      );
    exit(1);
  }

  try {
    const normalizer = ContentTypeNormalizer();
    apiDocument = normalizer.apply(apiDocument);
    logger.fine('Applied content type normalization');
  } on Object catch (e, s) {
    logger
      ..fine('Failed to normalize content types', e, s)
      ..severe(
        'Unexpected error while normalizing content types. '
        'Please run with verbose logging and report this issue at $issueUrl',
      );
    exit(1);
  }

  try {
    const transformer = ConfigTransformer();
    apiDocument = transformer.apply(apiDocument, mergedConfig.toTonikConfig());
    logger.fine('Applied configuration transformations');
  } on Object catch (e, s) {
    logger
      ..fine('Failed to apply configuration', e, s)
      ..severe(
        'Unexpected error while applying configuration. '
        'Please run with verbose logging and report this issue at $issueUrl',
      );
    exit(1);
  }

  try {
    await const Generator().generate(
      apiDocument: apiDocument,
      outputDirectory: outputDir ?? '.',
      package: packageName,
      config: mergedConfig.toTonikConfig(),
    );
    logger.info('Successfully generated code');
  } on Object catch (e, s) {
    logger
      ..fine('Failed to generate code', e, s)
      ..severe(
        'Unexpected error while generating code. '
        'If you think your document is valid, please run with '
        'verbose logging and report this issue at $issueUrl',
      );
    exit(1);
  }
}
