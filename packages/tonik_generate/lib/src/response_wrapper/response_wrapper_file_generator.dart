import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/generated_artifact_writer.dart';
import 'package:tonik_generate/src/response_wrapper/response_wrapper_generator.dart';

/// Generates and writes response wrapper files to disk.
class ResponseWrapperFileGenerator {
  ResponseWrapperFileGenerator({required this.responseWrapperGenerator});

  final ResponseWrapperGenerator responseWrapperGenerator;
  final log = Logger('ResponseWrapperFileGenerator');

  List<String> writeFiles({
    required ApiDocument apiDocument,
    required String outputDirectory,
    required String package,
  }) {
    log.fine('Writing response wrapper files for operations');

    final relativeDirectory = createGeneratedArtifactDirectory(
      outputDirectory: outputDirectory,
      package: package,
      relativePath: path.posix.join('lib', 'src', 'response_wrapper'),
    );
    final generatedFiles = <String>[];
    for (final operation in apiDocument.operations) {
      // Only generate for operations with two or more statuses
      if (operation.responses.length < 2) {
        log.fine(
          'Skipping operation ${operation.operationId} with '
          '${operation.responses.length} statuses',
        );
        continue;
      }

      final result = responseWrapperGenerator.generate(operation);

      log.fine('Writing file ${result.filename}');
      generatedFiles.add(
        writeGeneratedArtifact(
          outputDirectory: outputDirectory,
          package: package,
          relativePath: path.posix.join(relativeDirectory, result.filename),
          content: result.code,
        ),
      );
    }
    return generatedFiles;
  }
}
