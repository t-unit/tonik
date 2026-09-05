import 'package:path/path.dart' as path;
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/generated_artifact_writer.dart';
import 'package:tonik_generate/src/server/server_generator.dart';

/// Generates server class files.
class const ServerFileGenerator({
  required final ServerGenerator serverGenerator,
}) {
  /// Writes server files to the specified output directory.
  String writeFiles({
    required ApiDocument apiDocument,
    required String outputDirectory,
    required String package,
  }) {
    // Always generate the servers file, even if no servers are defined
    // because we need the base and custom classes
    final result = serverGenerator.generate(apiDocument.servers.toList());

    return writeGeneratedArtifact(
      outputDirectory: outputDirectory,
      package: package,
      relativePath: path.posix.join('lib', 'src', 'server', result.filename),
      content: result.code,
    );
  }
}
