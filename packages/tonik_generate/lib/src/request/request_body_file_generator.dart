import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/generated_artifact_writer.dart';
import 'package:tonik_generate/src/model/class_generator.dart';
import 'package:tonik_generate/src/request/request_body_generator.dart';

/// Generates and writes request body files to disk.
class RequestBodyFileGenerator({
  required final RequestBodyGenerator requestBodyGenerator,
  required final ClassGenerator classGenerator,
}) {
  final log = Logger('RequestBodyFileGenerator');

  List<String> writeFiles({
    required ApiDocument apiDocument,
    required String outputDirectory,
    required String package,
    List<String> excludeSchemas = const [],
    DeprecatedHandling deprecatedSchemas = DeprecatedHandling.annotate,
  }) {
    log.fine('Writing ${apiDocument.requestBodies.length} request body files');

    final generatedFiles = <String>[];
    final names = requestBodyGenerator.nameManager;
    final emittedModels = {
      for (final model in apiDocument.models.whereType<NamedModel>())
        names.modelName(model),
    };
    for (final requestBody in apiDocument.requestBodies) {
      for (final content
          in requestBody.resolvedContent.whereType<MultipartRequestContent>()) {
        final name = names.multipartObjectName(content);
        final isComponent =
            content.sourceName != null &&
            content.sourceContext ==
                Context.initial().pushAll(['components', 'schemas']);
        final results = [
          if (!isComponent &&
              !excludeSchemas.contains(content.sourceName) &&
              !(deprecatedSchemas == DeprecatedHandling.exclude &&
                  content.isDeprecated) &&
              emittedModels.add(name))
            classGenerator.generateMultipart(content),
          if (content.alias != null &&
              emittedModels.add(names.multipartAliasName(content)))
            classGenerator.generateMultipartAlias(content),
        ];
        for (final result in results) {
          generatedFiles.add(
            writeGeneratedArtifact(
              outputDirectory: outputDirectory,
              package: package,
              relativePath: path.posix.join(
                'lib',
                'src',
                'model',
                result.filename,
              ),
              content: result.code,
            ),
          );
        }
      }
      if (requestBody.contentCount <= 1) {
        log.fine(
          'Skipping request body ${requestBody.name ?? requestBody.context} '
          'with ${requestBody.contentCount} content types',
        );
        continue;
      }

      final (name, _) = requestBodyGenerator.nameManager.requestBodyNames(
        requestBody,
      );
      log.fine('Generating request body $name');

      final result = requestBodyGenerator.generate(requestBody);

      log.fine('Writing file ${result.filename}');
      generatedFiles.add(
        writeGeneratedArtifact(
          outputDirectory: outputDirectory,
          package: package,
          relativePath: path.posix.join(
            'lib',
            'src',
            'request_body',
            result.filename,
          ),
          content: result.code,
        ),
      );
    }
    return generatedFiles;
  }
}
