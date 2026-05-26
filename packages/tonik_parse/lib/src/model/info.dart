import 'package:tonik_parse/src/model/contact.dart';
import 'package:tonik_parse/src/model/license.dart';

class Info {
  Info({
    required this.title,
    required this.summary,
    required this.description,
    required this.version,
    required this.contact,
    required this.license,
    required this.termsOfService,
  });

  factory Info.fromJson(Map<String, dynamic> json) => Info(
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

  final String title;
  final String? summary;
  final String? description;
  final String version;
  final Contact? contact;
  final License? license;
  final String? termsOfService;

  @override
  String toString() =>
      'Info{title: $title, summary: $summary, description: $description, '
      'version: $version, contact: $contact, license: $license, '
      'termsOfService: $termsOfService}';
}
