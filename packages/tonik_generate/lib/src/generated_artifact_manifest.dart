import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

const generatedArtifactManifestFilename = '.tonik-generated-files.json';

final class GeneratedArtifactManifest {
  GeneratedArtifactManifest._({
    required this.packageDirectory,
    required Set<String> previousFiles,
  }) : _previousFiles = previousFiles;

  factory GeneratedArtifactManifest.load(String packageDirectory) {
    final manifestFile = File(
      path.join(packageDirectory, generatedArtifactManifestFilename),
    );
    if (!manifestFile.existsSync()) {
      return GeneratedArtifactManifest._(
        packageDirectory: packageDirectory,
        previousFiles: const {},
      );
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(manifestFile.readAsStringSync());
    } on FormatException catch (error) {
      throw FormatException(
        'Invalid generated artifact manifest at ${manifestFile.path}: '
        '${error.message}',
      );
    }

    if (decoded is! Map<String, Object?> ||
        decoded['version'] != 1 ||
        decoded['files'] is! List<Object?>) {
      throw FormatException(
        'Invalid generated artifact manifest at ${manifestFile.path}.',
      );
    }

    final files = <String>{};
    for (final entry in decoded['files']! as List<Object?>) {
      if (entry is! String) {
        throw FormatException(
          'Invalid generated artifact path in ${manifestFile.path}.',
        );
      }
      files.add(normalizeGeneratedArtifactPath(entry));
    }

    return GeneratedArtifactManifest._(
      packageDirectory: packageDirectory,
      previousFiles: files,
    );
  }

  final String packageDirectory;
  final Set<String> _previousFiles;

  void commit(Iterable<String> generatedFiles) {
    final currentFiles = generatedFiles
        .map(normalizeGeneratedArtifactPath)
        .toSet();
    final staleFiles = _previousFiles.difference(currentFiles).toList()..sort();

    for (final relativePath in staleFiles) {
      final file = File(
        path.joinAll([
          packageDirectory,
          ...path.posix.split(relativePath),
        ]),
      );
      if (file.existsSync()) {
        file.deleteSync();
      }
    }

    final sortedFiles = currentFiles.toList()..sort();
    final content = const JsonEncoder.withIndent('  ').convert({
      'version': 1,
      'files': sortedFiles,
    });
    final manifestFile = File(
      path.join(packageDirectory, generatedArtifactManifestFilename),
    );
    manifestFile.parent.createSync(recursive: true);
    manifestFile.writeAsStringSync('$content\n');
  }
}

String normalizeGeneratedArtifactPath(String artifactPath) {
  final normalized = path.posix.normalize(artifactPath.replaceAll(r'\', '/'));
  if (normalized.isEmpty ||
      normalized == '.' ||
      path.posix.isAbsolute(normalized) ||
      normalized == '..' ||
      normalized.startsWith('../') ||
      RegExp('^[A-Za-z]:/').hasMatch(normalized)) {
    throw FormatException(
      'Generated artifact path must stay within the package: $artifactPath',
    );
  }
  return normalized;
}
