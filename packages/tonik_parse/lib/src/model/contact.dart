class Contact({
  required final String? name,
  required final String? url,
  required final String? email,
}) {
  factory fromJson(Map<String, dynamic> json) {
    return Contact(
      name: json['name'] as String?,
      url: json['url'] as String?,
      email: json['email'] as String?,
    );
  }

  @override
  String toString() => 'Contact{name: $name, url: $url, email: $email}';
}
