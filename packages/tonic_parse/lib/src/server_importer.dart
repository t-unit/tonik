import 'package:tonic_core/tonic_core.dart';
import 'package:tonic_parse/src/model/open_api_object.dart';

class ServerImporter {
  ServerImporter({required this.openApiObject});

  final OpenApiObject openApiObject;

  Set<Server> import() {
    final mapped = openApiObject.servers?.map(
      (server) => Server(url: server.url, description: server.description),
    );
    return mapped?.toSet() ?? {};
  }
}
