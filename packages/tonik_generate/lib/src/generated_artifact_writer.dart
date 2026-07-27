import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:tonik_generate/src/generated_artifact_manifest.dart';

String createGeneratedArtifactDirectory({
  required String outputDirectory,
  required String package,
  required String relativePath,
}) {
  final artifactPath = _resolveGeneratedArtifactPath(
    outputDirectory: outputDirectory,
    package: package,
    relativePath: relativePath,
  );
  Directory(artifactPath.absolute).createSync(recursive: true);
  return artifactPath.relative;
}

String writeGeneratedArtifact({
  required String outputDirectory,
  required String package,
  required String relativePath,
  required String content,
}) {
  final artifactPath = _resolveGeneratedArtifactPath(
    outputDirectory: outputDirectory,
    package: package,
    relativePath: relativePath,
  );
  final file = File(artifactPath.absolute);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(content);
  return artifactPath.relative;
}

({String absolute, String relative}) _resolveGeneratedArtifactPath({
  required String outputDirectory,
  required String package,
  required String relativePath,
}) {
  final normalizedPath = normalizeGeneratedArtifactPath(relativePath);
  return (
    absolute: path.joinAll([
      outputDirectory,
      package,
      ...path.posix.split(normalizedPath),
    ]),
    relative: normalizedPath,
  );
}
