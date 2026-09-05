import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/generated_artifact_writer.dart';
import 'package:tonik_generate/src/response/response_generator.dart';

/// Generates and writes response files to disk.
class ResponseFileGenerator({
  required final ResponseGenerator responseGenerator,
}) {
  final log = Logger('ResponseFileGenerator');

  List<String> writeFiles({
    required ApiDocument apiDocument,
    required String outputDirectory,
    required String package,
  }) {
    log.fine('Writing ${apiDocument.responses.length} response files');

    final relativeDirectory = createGeneratedArtifactDirectory(
      outputDirectory: outputDirectory,
      package: package,
      relativePath: path.posix.join('lib', 'src', 'response'),
    );
    final generatedFiles = <String>[];
    for (final response in apiDocument.responses) {
      // Skip responses with no headers and just one body
      if (!response.hasHeaders && response.bodyCount <= 1) {
        log.fine(
          'Skipping response ${response.name ?? response.context} with '
          '${response.bodyCount} bodies and no headers',
        );
        continue;
      }

      final result = responseGenerator.generate(response);

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
