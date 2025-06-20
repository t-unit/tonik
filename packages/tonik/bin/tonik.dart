import 'dart:io';

import 'package:args/args.dart';
import 'package:logging/logging.dart';
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
      'output-dir',
      abbr: 'o',
      help: 'Directory where generated project will be placed.',
      valueHelp: 'path',
      defaultsTo: '.',
    )
    ..addOption(
      'package-name',
      abbr: 'p',
      help: 'Name of the package to generate.',
      valueHelp: 'name',
      mandatory: true,
    )
    ..addOption(
      'spec',
      help: 'Path to OpenAPI document.',
      abbr: 's',
      valueHelp: 'path',
      mandatory: true,
    )
    ..addOption(
      'log-level',
      help: 'Set the logging level (verbose, info, warn, silent).',
      defaultsTo: 'warn',
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
  String logLevel;
  String packageName;
  String openApiPath;
  String outputDir;

  try {
    final results = argParser.parse(arguments);

    if (results.flag('help')) {
      printUsage(argParser);
      return;
    }

    logLevel = results['log-level'] as String;
    packageName = results['package-name'] as String;
    openApiPath = results['spec'] as String;
    outputDir = results['output-dir'] as String;
  } on FormatException catch (formatException) {
    print(formatException.message);
    printUsage(argParser);
    exit(128);
  } on Object catch (_) {
    printUsage(argParser);
    exit(128);
  }

  Logger.root.level = switch (logLevel) {
    'verbose' => Level.FINEST,
    'info' => Level.INFO,
    'warn' => Level.WARNING,
    'silent' => Level.OFF,
    _ => Level.WARNING,
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

  final ApiDocument apiDocument;
  try {
    apiDocument = Importer().import(apiSpec);
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
    const Generator().generate(
      apiDocument: apiDocument,
      outputDirectory: outputDir,
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
