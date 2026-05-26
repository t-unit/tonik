class License {
  License({required this.name, required this.identifier, required this.url});

  factory License.fromJson(Map<String, dynamic> json) => License(
    name: json['name'] as String,
    identifier: json['identifier'] as String?,
    url: json['url'] as String?,
  );

  final String name;
  final String? identifier;
  final String? url;

  @override
  String toString() =>
      'License{name: $name, identifier: $identifier, url: $url}';
}
