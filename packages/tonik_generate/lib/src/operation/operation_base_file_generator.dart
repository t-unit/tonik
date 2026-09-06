import 'dart:io';

import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:path/path.dart' as path;
import 'package:tonik_generate/src/generated_artifact_writer.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/operation/operation_base_generator.dart';
import 'package:tonik_generate/src/util/core_prefixed_allocator.dart';
import 'package:tonik_generate/src/util/format_with_header.dart';

class const OperationBaseFileGenerator({
  required final OperationBaseGenerator operationBaseGenerator,
  required final String operationBaseFilename,
  required final NameManager nameManager,
}) {
  String writeFile({required String outputDirectory, required String package}) {
    final operationDirectory = Directory(
      path.join(outputDirectory, package, 'lib', 'src', 'operation'),
    );
    if (operationDirectory.existsSync()) {
      final baseFilenamePattern = RegExp(
        r'^(?:dio|http)_operation(?:_base)*\.dart$',
      );
      for (final stale in operationDirectory.listSync().whereType<File>()) {
        final staleFilename = path.basename(stale.path);
        if (staleFilename != operationBaseFilename &&
            !nameManager.operationFilenames.contains(staleFilename) &&
            baseFilenamePattern.hasMatch(staleFilename) &&
            stale.readAsStringSync().startsWith(
              '// Generated code - do not modify by hand',
            )) {
          stale.deleteSync();
        }
      }
    }

    final library = Library(
      (builder) => builder.body.addAll(operationBaseGenerator.generate()),
    );
    final emitter = DartEmitter(
      allocator: CorePrefixedAllocator(),
      orderDirectives: true,
      useNullSafetySyntax: true,
    );
    final formatter = DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    );
    final code = formatter.formatWithHeader(library.accept(emitter).toString());

    return writeGeneratedArtifact(
      outputDirectory: outputDirectory,
      package: package,
      relativePath: path.posix.join(
        'lib',
        'src',
        'operation',
        operationBaseFilename,
      ),
      content: code,
    );
  }
}
