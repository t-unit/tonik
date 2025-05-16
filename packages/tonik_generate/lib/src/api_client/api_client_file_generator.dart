import 'dart:io';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/api_client/api_client_generator.dart';

class ApiClientFileGenerator {
  ApiClientFileGenerator({required this.apiClientGenerator});

  final ApiClientGenerator apiClientGenerator;
  final log = Logger('ApiClientFileGenerator');

  void writeFiles({
    required ApiDocument apiDocument,
    required String outputDirectory,
    required String package,
  }) {
    log.fine('Writing API client files');

    final clientDirectory = path.joinAll([
      outputDirectory,
      package,
      'lib',
      'src',
      'api_client',
    ]);

    Directory(clientDirectory).createSync(recursive: true);

    for (final entry in apiDocument.operationsByTag.entries) {
      final result = apiClientGenerator.generate(entry.value, entry.key);

      log.fine('Writing file ${result.filename}');
      final file = File(path.join(clientDirectory, result.filename));
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(result.code);
    }
  }
} 
