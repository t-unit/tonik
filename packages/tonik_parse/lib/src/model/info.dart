import 'package:json_annotation/json_annotation.dart';
import 'package:tonik_core/tonik_core.dart';

part 'info.g.dart';

@JsonSerializable()
class Info {
  Info({
    required this.title,
    required this.description,
    required this.version,
    this.contact,
    this.license,
    this.termsOfService,
  });

  factory Info.fromJson(Map<String, dynamic> json) => _$InfoFromJson(json);

  final String title;
  final String? description;
  final String version;
  final Contact? contact;
  final License? license;
  final String? termsOfService;

  @override
  String toString() =>
      'Info{title: $title, description: $description, version: $version, '
      'contact: $contact, license: $license, termsOfService: $termsOfService}';
}
