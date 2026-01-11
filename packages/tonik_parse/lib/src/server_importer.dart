import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/src/model/open_api_object.dart';
import 'package:tonik_parse/src/model/server.dart' as parse;

/// Imports server definitions from an OpenAPI document.
class ServerImporter {
  ServerImporter({required this.openApiObject});

  final OpenApiObject openApiObject;

  Set<Server> import() {
    final mapped = openApiObject.servers?.map(_importServer);
    return mapped?.toSet() ?? {};
  }

  Server _importServer(parse.Server server) {
    final variables = server.variables?.entries.map((entry) {
      return ServerVariable(
        name: entry.key,
        defaultValue: entry.value.defaultValue,
        enumValues: entry.value.enumValues,
        description: entry.value.description,
      );
    }).toList();

    return Server(
      url: server.url,
      description: server.description,
      variables: variables ?? [],
    );
  }
}
