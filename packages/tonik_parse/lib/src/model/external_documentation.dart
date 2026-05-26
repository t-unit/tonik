class ExternalDocumentation {
  ExternalDocumentation({required this.url, required this.description});

  factory ExternalDocumentation.fromJson(Map<String, dynamic> json) =>
      ExternalDocumentation(
        url: json['url'] as String,
        description: json['description'] as String?,
      );

  final String? description;
  final String url;

  @override
  String toString() =>
      'ExternalDocumentation{description: $description, url: $url}';
}
