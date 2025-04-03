import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:tonic_core/tonic_core.dart';

void generateLibraryFile({
  required ApiDocument apiDocument,
  required String outputDirectory,
  required String package,
}) {
  final packageDir = path.join(outputDirectory, package);
  final libraryFile = File(path.join(packageDir, 'lib', '$package.dart'));
  final srcDir = Directory(path.join(packageDir, 'lib', 'src'));

  final srcFiles = <String>[];
  if (srcDir.existsSync()) {
    srcFiles.addAll(
      srcDir
          .listSync(recursive: true)
          .where((entity) => entity is File && entity.path.endsWith('.dart'))
          .map((file) {
            // Extract the relative path from src directory
            final relativePath = path.relative(file.path, from: srcDir.path);
            return 'src/$relativePath';
          }),
    );
  }

  srcFiles.sort();

  final buffer =
      StringBuffer()
        ..writeln('/// ${apiDocument.title} ${apiDocument.version}')
        ..writeln('/// ${apiDocument.description}')
        ..writeln('library;')
        ..writeln();

  for (final file in srcFiles) {
    final normalizedPath = file.replaceAll(r'\\', '/');
    buffer.writeln("export '$normalizedPath';");
  }

  libraryFile.writeAsStringSync(buffer.toString());
}
