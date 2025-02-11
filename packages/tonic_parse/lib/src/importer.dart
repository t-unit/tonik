import 'package:tonic_core/tonic_core.dart';
import 'package:tonic_parse/src/model/open_api_object.dart';
import 'package:tonic_parse/src/model_importer.dart';

class Importer {
  ApiDocument import(Map<String, dynamic> fileContent) {
    final openApiObject = OpenApiObject.fromJson(fileContent);

    return ApiDocument(
      title: openApiObject.info.title,
      version: openApiObject.info.version,
      description: openApiObject.info.description,
      models: ModelImporter(openApiObject).import(),
      servers: _importServers(openApiObject),
    );
  }

  Set<Server> _importServers(OpenApiObject openApiObject) {
    final servers = openApiObject.servers
        ?.map(
          (server) => Server(
            url: server.url,
            description: server.description,
          ),
        )
        .toSet();
    return servers ?? {};
  }
}
