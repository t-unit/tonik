import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/response_wrapper/response_wrapper_generator.dart';

/// Generates and writes response wrapper files to disk.
class ResponseWrapperFileGenerator {
  ResponseWrapperFileGenerator({required this.responseWrapperGenerator});

  final ResponseWrapperGenerator responseWrapperGenerator;
  final log = Logger('ResponseWrapperFileGenerator');

  void writeFiles({
    required ApiDocument apiDocument,
    required String outputDirectory,
    required String package,
  }) {
    log.fine('Writing response wrapper files for operations');

    final wrapperDirectory = path.joinAll([
      outputDirectory,
      package,
      'lib',
      'src',
      'response_wrapper',
    ]);

    Directory(wrapperDirectory).createSync(recursive: true);

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
      final file = File(path.join(wrapperDirectory, result.filename));
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(result.code);
    }
  }
}
