import 'package:json_annotation/json_annotation.dart';

part 'license.g.dart';

@JsonSerializable(createToJson: false)
class License {
  License({
    required this.name,
    required this.identifier,
    required this.url,
  });

  factory License.fromJson(Map<String, dynamic> json) =>
      _$LicenseFromJson(json);

  final String name;
  final String? identifier;
  final String? url;

  @override
  String toString() =>
      'License{name: $name, identifier: $identifier, url: $url}';
}
