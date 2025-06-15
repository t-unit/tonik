import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/server/server_generator.dart';

/// Generates server class files.
class ServerFileGenerator {
  /// Creates a new ServerFileGenerator.
  const ServerFileGenerator({
    required this.serverGenerator,
  });

  /// The generator used to generate server classes.
  final ServerGenerator serverGenerator;

  /// Writes server files to the specified output directory.
  void writeFiles({
    required ApiDocument apiDocument,
    required String outputDirectory,
    required String package,
  }) {
    // Always generate the servers file, even if no servers are defined
    // because we need the base and custom classes
    final serverDirPath = path.join(
      outputDirectory,
      package,
      'lib',
      'src',
      'server',
    );

    final serverDir = Directory(serverDirPath);
    if (!serverDir.existsSync()) {
      serverDir.createSync(recursive: true);
    }

    final result = serverGenerator.generate(apiDocument.servers.toList());

    final filePath = path.join(serverDirPath, result.filename);
    File(filePath).writeAsStringSync(result.code);
  }
}
