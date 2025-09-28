import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/src/model/open_api_object.dart';

class ExternalDocumentationImporter {
  ExternalDocumentationImporter({required this.openApiObject});

  final OpenApiObject openApiObject;

  ExternalDocumentation? import() {
    final externalDocs = openApiObject.externalDocs;
    if (externalDocs == null) return null;

    return ExternalDocumentation(
      description: externalDocs.description,
      url: externalDocs.url,
    );
  }
}
