import 'package:tonik_core/tonik_core.dart' as core;
import 'package:tonik_parse/src/model/open_api_object.dart';

class LicenseImporter {
  LicenseImporter({required this.openApiObject});

  final OpenApiObject openApiObject;

  core.License? import() {
    final license = openApiObject.info.license;
    if (license == null) return null;

    return core.License(
      name: license.name,
      url: license.url,
    );
  }
}
