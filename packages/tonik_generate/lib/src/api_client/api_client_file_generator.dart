import 'dart:io';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/api_client/api_client_generator.dart';

class ApiClientFileGenerator {
  ApiClientFileGenerator({required this.apiClientGenerator});

  final ApiClientGenerator apiClientGenerator;
  final log = Logger('ApiClientFileGenerator');

  // Default tag for operations without any tags
  static const defaultTag = Tag(name: 'default');

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

    // Process operations with tags
    for (final entry in apiDocument.operationsByTag.entries) {
      final result = apiClientGenerator.generate(entry.value, entry.key);

      log.fine('Writing file ${result.filename}');
      final file = File(path.join(clientDirectory, result.filename));
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(result.code);
    }

    // Process operations without tags
    final untaggedOperations = getUntaggedOperations(apiDocument);
    if (untaggedOperations.isNotEmpty) {
      final result = apiClientGenerator.generate(
        untaggedOperations,
        defaultTag,
      );

      log.fine('Writing file for untagged operations: ${result.filename}');
      final file = File(path.join(clientDirectory, result.filename));
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(result.code);
    }
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
