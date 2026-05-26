class Contact {
  Contact({required this.name, required this.url, required this.email});

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      name: json['name'] as String?,
      url: json['url'] as String?,
      email: json['email'] as String?,
    );
  }

  final String? name;
  final String? url;
  final String? email;

  @override
  String toString() => 'Contact{name: $name, url: $url, email: $email}';
}
