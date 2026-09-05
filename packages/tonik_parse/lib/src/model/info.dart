import 'package:tonik_parse/src/model/contact.dart';
import 'package:tonik_parse/src/model/license.dart';

class Info({
  required final String title,
  required final String? summary,
  required final String? description,
  required final String version,
  required final Contact? contact,
  required final License? license,
  required final String? termsOfService,
}) {
  factory fromJson(Map<String, dynamic> json) => Info(
    title: json['title'] as String,
    version: json['version'] as String,
    summary: json['summary'] as String?,
    description: json['description'] as String?,
    contact: json['contact'] == null
        ? null
        : Contact.fromJson(json['contact'] as Map<String, dynamic>),
    license: json['license'] == null
        ? null
        : License.fromJson(json['license'] as Map<String, dynamic>),
    termsOfService: json['termsOfService'] as String?,
  );

  @override
  String toString() =>
      'Info{title: $title, summary: $summary, description: $description, '
      'version: $version, contact: $contact, license: $license, '
      'termsOfService: $termsOfService}';
}
