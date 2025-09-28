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

  final docComments = _formatApiDocumentation(apiDocument);

  final buffer =
      StringBuffer()
        ..writeln('// Generated code - do not modify by hand')
        ..writeln('// ignore_for_file: lines_longer_than_80_chars')
        ..writeln()
        ..writeln();

  docComments.forEach(buffer.writeln);

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

List<String> _formatApiDocumentation(ApiDocument apiDocument) {
  final lines = <String>[];

  if (apiDocument.title.isNotEmpty) {
    lines.add('/// ${apiDocument.title}');
  }

  if (apiDocument.version.isNotEmpty) {
    lines.add('/// Version ${apiDocument.version}');
  }

  if (apiDocument.description != null && apiDocument.description!.isNotEmpty) {
    lines.addAll(formatDocComment(apiDocument.description));
  }

  if (apiDocument.contact != null) {
    lines
      ..add('///')
      ..add('/// Contact: ${apiDocument.contact!.name ?? 'N/A'}');

    if (apiDocument.contact!.email != null) {
      lines.add('/// Email: ${apiDocument.contact!.email}');
    }

    if (apiDocument.contact!.url != null) {
      lines.add('/// URL: ${apiDocument.contact!.url}');
    }
  }

  if (apiDocument.license != null) {
    lines
      ..add('///')
      ..add('/// License: ${apiDocument.license!.name ?? 'N/A'}');

    if (apiDocument.license!.url != null) {
      lines.add('/// License URL: ${apiDocument.license!.url}');
    }
  }

  if (apiDocument.termsOfService != null) {
    lines
      ..add('///')
      ..add('/// Terms of Service: ${apiDocument.termsOfService}');
  }

  if (apiDocument.externalDocs != null) {
    lines
      ..add('///')
      ..add('/// Documentation: ${apiDocument.externalDocs!.description ?? 'N/A'}');

    if (apiDocument.externalDocs!.url.isNotEmpty) {
      lines.add('/// Documentation URL: ${apiDocument.externalDocs!.url}');
    }
  }

  return lines;
}
