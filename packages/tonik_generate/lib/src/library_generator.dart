import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/doc_comment_formatter.dart';

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

  final docComments = formatDocComments([
    apiDocument.title,
    apiDocument.version,
    apiDocument.description,
  ]);

  final buffer =
      StringBuffer()
        ..writeln('// Generated code - do not modify by hand')
        ..writeln('// ignore_for_file: lines_longer_than_80_chars')
        ..writeln()
        ..writeln();

  for (final docComment in docComments) {
    buffer.writeln(docComment);
  }

  buffer
    ..writeln()
    ..writeln()
    ..writeln('library;')
    ..writeln();

  for (final file in srcFiles) {
    final normalizedPath = file.replaceAll(r'\\', '/');
    buffer.writeln("export '$normalizedPath';");
  }

  libraryFile.writeAsStringSync(buffer.toString());
}
