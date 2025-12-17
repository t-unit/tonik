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
    );
}

void printUsage(ArgParser argParser) {
  print('Usage: tonik <flags> [arguments]');
  print(argParser.usage);
}

final Logger logger = Logger('tonik');

void main(List<String> arguments) {
  final argParser = buildParser();
  String? logLevelArg;
  String? packageNameArg;
  String? openApiPathArg;
  String? outputDirArg;
  String? configPathArg;

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

  final mergedConfig = fileConfig.merge(
    spec: openApiPathArg,
    outputDir: outputDirArg,
    packageName: packageNameArg,
    logLevel: cliLogLevel,
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
    ).import(apiSpec);
    logger.info('Successfully parsed OpenAPI document');
  } on Object catch (e, s) {
    logger
      ..fine('Failed to parse OpenAPI document', e, s)
      ..severe(
        'Unexpected error while parsing OpenAPI document. '
        'Unexpected error while parsing OpenAPI document. '
        'If you think your document is valid, please run '
        'with verbose logging and report this issue at $issueUrl',
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
    const Generator().generate(
      apiDocument: apiDocument,
      outputDirectory: outputDir ?? '.',
      package: packageName,
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
