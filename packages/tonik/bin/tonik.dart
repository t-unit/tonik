import 'dart:io';

import 'package:args/args.dart';
import 'package:logging/logging.dart';
import 'package:tonik/src/config/cli_config.dart';
import 'package:tonik/src/config/cli_parser.dart';
import 'package:tonik/src/config/config_loader.dart';
import 'package:tonik/src/config/log_level.dart';
import 'package:tonik/src/openapi_loader.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/tonik_generate.dart';
import 'package:tonik_parse/tonik_parse.dart';

const issueUrl = 'https://github.com/t-unit/tonik/issues';

void printUsage(ArgParser argParser) {
  print('Usage: tonik <flags> [arguments]');
  print(argParser.usage);
}

final Logger logger = Logger('tonik');

CliConfig _mergeConfigOrExit(ArgResults arguments, CliConfig fileConfig) {
  try {
    return mergeCliConfig(
      arguments: arguments,
      fileConfig: fileConfig,
      environmentWorkerCount: Platform.environment['TONIK_WORKERS'],
    );
  } on FormatException catch (formatException) {
    stderr.writeln('Error: ${formatException.message}');
    exit(128);
  }
}

Future<void> main(List<String> arguments) async {
  final argParser = buildCliParser();
  late ArgResults results;

  try {
    results = argParser.parse(arguments);

    if (results.flag('help')) {
      printUsage(argParser);
      return;
    }
  } on FormatException catch (formatException) {
    print(formatException.message);
    printUsage(argParser);
    exit(128);
  } on Object catch (_) {
    printUsage(argParser);
    exit(128);
  }

  final configPath = results.option('config') ?? 'tonik.yaml';
  final fileConfig = ConfigLoader.load(configPath);

  final mergedConfig = _mergeConfigOrExit(results, fileConfig);

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
