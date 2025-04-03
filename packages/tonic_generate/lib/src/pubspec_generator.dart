import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:tonic_core/tonic_core.dart';

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

  final content = '''
name: $package
description: Generated API client for ${apiDocument.title}
version: ${apiDocument.version}
environment:
  sdk: ">=3.7.0 <4.0.0"

dependencies:
  big_decimal: ^0.5.0
  collection: ^1.17.0
''';

  pubspecFile.writeAsStringSync(content);
}
