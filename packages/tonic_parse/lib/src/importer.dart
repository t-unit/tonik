import 'package:tonic_core/tonic_core.dart';
import 'package:tonic_parse/src/model/open_api_object.dart';
import 'package:tonic_parse/src/model_importer.dart';
import 'package:tonic_parse/src/operation_importer.dart';
import 'package:tonic_parse/src/server_importer.dart';

class Importer {
  ApiDocument import(Map<String, dynamic> fileContent) {
    final openApiObject = OpenApiObject.fromJson(fileContent);

    return ApiDocument(
      title: openApiObject.info.title,
      version: openApiObject.info.version,
      description: openApiObject.info.description,
      models: ModelImporter(openApiObject).import(),
      servers: ServerImporter(openApiObject: openApiObject).import(),
      taggedOperations:
          OperationImporter(openApiObject: openApiObject).import(),
    );
  }
}
