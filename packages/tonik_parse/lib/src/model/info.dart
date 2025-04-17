import 'package:json_annotation/json_annotation.dart';

part 'info.g.dart';

@JsonSerializable()
class Info {
  Info({required this.title, required this.description, required this.version});

  factory Info.fromJson(Map<String, dynamic> json) => _$InfoFromJson(json);

  final String title;
  final String? description;
  final String version;

  // We ignore the contact and license properties.

  @override
  String toString() =>
      'Info{title: $title, description: $description, version: $version}';
}
