import 'package:json_annotation/json_annotation.dart';
import 'package:tonik_parse/src/model/contact.dart';
import 'package:tonik_parse/src/model/license.dart';

part 'info.g.dart';

@JsonSerializable(createToJson: false)
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

  factory Info.fromJson(Map<String, dynamic> json) => _$InfoFromJson(json);

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
