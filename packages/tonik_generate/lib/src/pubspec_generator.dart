import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:tonik_core/tonik_core.dart';

void generatePubspec({
  required ApiDocument apiDocument,
  required String outputDirectory,
  required String package,
}) {
  final pubspecDir = path.join(outputDirectory, package);
  final pubspecFile = File(path.join(pubspecDir, 'pubspec.yaml'));

  if (!pubspecFile.parent.existsSync()) {
    pubspecFile.parent.createSync(recursive: true);
  }

  final content =
      '''
name: $package
description: Generated API client for ${apiDocument.title}
version: ${apiDocument.version}
environment:
  sdk: '>=3.10.0 <4.0.0'

dependencies:
  big_decimal: ^0.7.0
  collection: ^1.17.0
  dio: ^5.8.0+1
  meta: ^1.16.0
  tonik_util: ^0.4.1

dev_dependencies:
  lints: ^6.0.0
''';

  pubspecFile.writeAsStringSync(content);
}
