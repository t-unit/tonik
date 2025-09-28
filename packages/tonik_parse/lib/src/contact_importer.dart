import 'package:tonik_core/tonik_core.dart' as core;
import 'package:tonik_parse/src/model/open_api_object.dart';

class ContactImporter {
  ContactImporter({required this.openApiObject});

  final OpenApiObject openApiObject;

  core.Contact? import() {
    final contact = openApiObject.info.contact;
    if (contact == null) return null;

    return core.Contact(
      name: contact.name,
      url: contact.url,
      email: contact.email,
    );
  }
}
