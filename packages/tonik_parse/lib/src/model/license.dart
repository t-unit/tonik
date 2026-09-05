class License({
  required final String name,
  required final String? identifier,
  required final String? url,
}) {
  factory fromJson(Map<String, dynamic> json) => License(
    name: json['name'] as String,
    identifier: json['identifier'] as String?,
    url: json['url'] as String?,
  );

  @override
  String toString() =>
      'License{name: $name, identifier: $identifier, url: $url}';
}
