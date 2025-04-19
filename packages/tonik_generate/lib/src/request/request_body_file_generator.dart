import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/request/request_body_generator.dart';

/// Generates and writes request body files to disk.
class RequestBodyFileGenerator {
  RequestBodyFileGenerator({required this.requestBodyGenerator});

  final RequestBodyGenerator requestBodyGenerator;
  final log = Logger('RequestBodyFileGenerator');

  void writeFiles({
    required ApiDocument apiDocument,
    required String outputDirectory,
    required String package,
  }) {
    final requestBodyDirectory = path.joinAll([
      outputDirectory,
      package,
      'lib',
      'src',
      'request_body',
    ]);

    for (final requestBody in apiDocument.requestBodies) {
      // Skip request bodies with no content or just one content type
      if (requestBody.contentCount <= 1) {
        log.fine(
          'Skipping request body ${requestBody.name} with '
          '${requestBody.contentCount} content types',
        );
        continue;
      }

      final name = requestBodyGenerator.nameManager.requestBodyName(
        requestBody,
      );
      log.fine('Generating request body $name');

      final result = requestBodyGenerator.generate(requestBody);

      log.fine('Writing file ${result.filename}');
      final file = File(path.join(requestBodyDirectory, result.filename));
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(result.code);
    }
  }
}
