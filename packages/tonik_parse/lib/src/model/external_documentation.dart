class ExternalDocumentation({
  required final String url,
  required final String? description,
}) {
  factory fromJson(Map<String, dynamic> json) => ExternalDocumentation(
    url: json['url'] as String,
    description: json['description'] as String?,
  );

  @override
  String toString() =>
      'ExternalDocumentation{description: $description, url: $url}';
}
