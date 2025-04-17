import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/src/model/open_api_object.dart';

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
