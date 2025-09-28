import 'package:json_annotation/json_annotation.dart';

part 'external_documentation.g.dart';

@JsonSerializable(createToJson: false)
class ExternalDocumentation {
  ExternalDocumentation({required this.url, this.description});

  factory ExternalDocumentation.fromJson(Map<String, dynamic> json) =>
      _$ExternalDocumentationFromJson(json);

  final String? description;
  final String url;

  @override
  String toString() =>
      'ExternalDocumentation{description: $description, url: $url}';
}
