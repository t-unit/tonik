import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/api_client/api_client_generator.dart';
import 'package:tonik_generate/src/generated_artifact_writer.dart';

class ApiClientFileGenerator({
  required final ApiClientGenerator apiClientGenerator,
}) {
  final log = Logger('ApiClientFileGenerator');

  /// Tag used for operations without any tags.
  static final defaultTag = Tag(name: 'default');

  List<String> writeFiles({
    required ApiDocument apiDocument,
    required String outputDirectory,
    required String package,
  }) {
    log.fine('Writing API client files');

    final relativeDirectory = createGeneratedArtifactDirectory(
      outputDirectory: outputDirectory,
      package: package,
      relativePath: path.posix.join('lib', 'src', 'api_client'),
    );
    final generatedFiles = <String>[];
    final servers = apiDocument.servers.toList();

    for (final entry in apiDocument.operationsByTag.entries) {
      final result = apiClientGenerator.generate(
        entry.value,
        entry.key,
        servers,
      );

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

    final untaggedOperations = getUntaggedOperations(apiDocument);
    if (untaggedOperations.isNotEmpty) {
      final result = apiClientGenerator.generate(
        untaggedOperations,
        defaultTag,
        servers,
      );

      log.fine('Writing file for untagged operations: ${result.filename}');
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

  /// Collects all operations from the API document that don't have tags.
  Set<Operation> getUntaggedOperations(ApiDocument apiDocument) {
    final untaggedOperations = <Operation>{};

    for (final operation in apiDocument.operations) {
      if (operation.tags.isEmpty) {
        untaggedOperations.add(operation);
      }
    }

    return untaggedOperations;
  }
}
