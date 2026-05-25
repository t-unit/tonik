import 'package:json_annotation/json_annotation.dart';

part 'example.g.dart';

@JsonSerializable(createToJson: false)
class Example {
  Example({
    this.summary,
    this.description,
    this.value,
    this.externalValue,
  });

  factory Example.fromJson(Map<String, dynamic> json) =>
      _$ExampleFromJson(json);

  final String? summary;
  final String? description;
  final Object? value;
  final String? externalValue;

  @override
  String toString() =>
      'Example{summary: $summary, description: $description, '
      'value: $value, externalValue: $externalValue}';
}
