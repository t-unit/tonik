import 'package:json_annotation/json_annotation.dart';
import 'package:tonik_parse/src/model/media_type.dart';

part 'request_body.g.dart';

@JsonSerializable(createToJson: false)
class RequestBody {
  RequestBody({
    required this.description,
    required this.content,
    required this.isRequired,
  });

  factory RequestBody.fromJson(Map<String, dynamic> json) =>
      _$RequestBodyFromJson(json);

  final String? description;
  final Map<String, MediaType> content;
  @JsonKey(name: 'required')
  final bool? isRequired;

  @override
  String toString() =>
      'RequestBody{description: $description, content: $content, '
      'isRequired: $isRequired}';
}
