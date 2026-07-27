import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/generated_artifact_writer.dart';
import 'package:tonik_generate/src/operation/operation_generator.dart';

class OperationFileGenerator {
  OperationFileGenerator({required this.operationGenerator});

  final OperationGenerator operationGenerator;

  final log = Logger('OperationFileGenerator');

  List<String> writeFiles({
    required ApiDocument apiDocument,
    required String outputDirectory,
    required String package,
  }) {
    log.fine('Writing ${apiDocument.operations.length} operation files');

    final generatedFiles = <String>[];
    for (final operation in apiDocument.operations) {
      final name = operationGenerator.nameManager.operationName(operation);
      log.fine('Generating operation $name');

      final result = operationGenerator.generateCallableOperation(operation);

      log.fine('Writing file ${result.filename}');
      generatedFiles.add(
        writeGeneratedArtifact(
          outputDirectory: outputDirectory,
          package: package,
          relativePath: path.posix.join(
            'lib',
            'src',
            'operation',
            result.filename,
          ),
          content: result.code,
        ),
      );
    }
    return generatedFiles;
  }
}
