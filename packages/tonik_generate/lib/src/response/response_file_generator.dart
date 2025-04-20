import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/response/response_generator.dart';

/// Generates and writes response files to disk.
class ResponseFileGenerator {
  ResponseFileGenerator({required this.responseGenerator});

  final ResponseGenerator responseGenerator;
  final log = Logger('ResponseFileGenerator');

  void writeFiles({
    required ApiDocument apiDocument,
    required String outputDirectory,
    required String package,
  }) {
    log.fine('Writing ${apiDocument.responses.length} response files');

    final responseDirectory = path.joinAll([
      outputDirectory,
      package,
      'lib',
      'src',
      'response',
    ]);

    Directory(responseDirectory).createSync(recursive: true);

    for (final response in apiDocument.responses) {
      // Skip responses with no headers and just one body
      if (!response.hasHeaders && response.bodyCount <= 1) {
        log.fine(
          'Skipping response ${response.name} with '
          '${response.bodyCount} bodies and no headers',
        );
        continue;
      }

      final result = responseGenerator.generate(response);

      log.fine('Writing file ${result.filename}');
      final file = File(path.join(responseDirectory, result.filename));
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(result.code);
    }
  }
}
