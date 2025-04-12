import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:tonic_core/tonic_core.dart';
import 'package:tonic_generate/src/operation/operation_generator.dart';

class OperationFileGenerator {
  OperationFileGenerator({required this.operationGenerator});

  final OperationGenerator operationGenerator;

  final log = Logger('OperationFileGenerator');

  void writeFiles({
    required ApiDocument apiDocument,
    required String outputDirectory,
    required String package,
  }) {
    final operationDirectory = path.joinAll([
      outputDirectory,
      package,
      'lib',
      'src',
      'operation',
    ]);

    for (final operation in apiDocument.operations) {
      final name = operationGenerator.nameManager.operationName(operation);
      log.fine('Generating operation $name');

      final result = operationGenerator.generateCallableOperation(operation);

      log.fine('Writing file ${result.filename}');
      final file = File(path.join(operationDirectory, result.filename));
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(result.code);
    }
  }
}
