import 'package:json_annotation/json_annotation.dart';

part 'contact.g.dart';

@JsonSerializable(createToJson: false)
class Contact {
  Contact({
    required this.name,
    required this.url,
    required this.email,
  });

  factory Contact.fromJson(Map<String, dynamic> json) =>
      _$ContactFromJson(json);

  final String? name;
  final String? url;
  final String? email;

  @override
  String toString() => 'Contact{name: $name, url: $url, email: $email}';
}
