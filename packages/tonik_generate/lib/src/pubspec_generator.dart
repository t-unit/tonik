import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:tonik_core/tonik_core.dart';

final _semverRegExp = RegExp(
  r'^\d+\.\d+\.\d+'
  r'(-[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*)?'
  r'(\+[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*)?$',
);

/// Returns a valid semver version string for use in pubspec.yaml.
///
/// If [version] is already valid semver, it is returned as-is.
/// Otherwise, the original value is sanitized and appended as a prerelease
/// tag to `0.0.1` (e.g. `0.0.1-2026-02-25.clover`).
String sanitizeVersion(String version) {
  final trimmed = version.trim();
  if (trimmed.isEmpty) return '0.0.1';

  if (_semverRegExp.hasMatch(trimmed)) return trimmed;

  // Replace disallowed characters with hyphens, collapse runs, strip edges.
  final sanitized = trimmed
      .replaceAll(RegExp(r'[^0-9A-Za-z.\-]'), '-')
      .replaceAll(RegExp('-{2,}'), '-')
      .replaceAll(RegExp(r'\.{2,}'), '.')
      .replaceAll(RegExp(r'^[.\-]+|[.\-]+$'), '');

  if (sanitized.isEmpty) return '0.0.1';

  return '0.0.1-$sanitized';
}

void generatePubspec({
  required ApiDocument apiDocument,
  required String outputDirectory,
  required String package,
  bool useImmutableCollections = false,
}) {
  final pubspecDir = path.join(outputDirectory, package);
  final pubspecFile = File(path.join(pubspecDir, 'pubspec.yaml'));

  if (!pubspecFile.parent.existsSync()) {
    pubspecFile.parent.createSync(recursive: true);
  }

  final version = sanitizeVersion(apiDocument.version);
  final ficDependency = useImmutableCollections
      ? '\n  fast_immutable_collections: ^11.0.0'
      : '';
  final content =
      '''
name: $package
description: Generated API client for ${apiDocument.title}
version: $version
environment:
  sdk: '>=3.10.0 <4.0.0'

dependencies:
  big_decimal: ^0.7.0
  collection: ^1.17.0
  dio: ^5.8.0+1$ficDependency
  meta: ^1.16.0
  tonik_util: ^0.6.0

dev_dependencies:
  lints: ^6.0.0
''';

  pubspecFile.writeAsStringSync(content);
}
