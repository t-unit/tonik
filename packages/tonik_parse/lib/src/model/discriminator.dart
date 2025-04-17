import 'package:json_annotation/json_annotation.dart';

part 'discriminator.g.dart';

@JsonSerializable()
class Discriminator {
  Discriminator({required this.propertyName, required this.mapping});

  factory Discriminator.fromJson(Map<String, dynamic> json) =>
      _$DiscriminatorFromJson(json);

  final String propertyName;
  final Map<String, String>? mapping;

  @override
  String toString() =>
      'Discriminator{propertyName: $propertyName, mapping: $mapping}';
}
