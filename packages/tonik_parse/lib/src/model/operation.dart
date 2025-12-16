import 'package:json_annotation/json_annotation.dart';
import 'package:tonik_parse/src/model/parameter.dart';
import 'package:tonik_parse/src/model/reference.dart';
import 'package:tonik_parse/src/model/request_body.dart';
import 'package:tonik_parse/src/model/response.dart';
import 'package:tonik_parse/src/model/server.dart';

part 'operation.g.dart';

@JsonSerializable(createToJson: false)
class Operation {
  Operation({
    required this.tags,
    required this.summary,
    required this.description,
    required this.operationId,
    required this.parameters,
    required this.requestBody,
    required this.responses,
    required this.isDeprecated,
    required this.servers,
    required this.security,
    required this.xDartName,
  });

  factory Operation.fromJson(Map<String, dynamic> json) =>
      _$OperationFromJson(json);

  final List<String>? tags;
  final String? summary;
  final String? description;
  final String? operationId;
  final List<ReferenceWrapper<Parameter>>? parameters;
  final ReferenceWrapper<RequestBody>? requestBody;
  final Map<String, ReferenceWrapper<Response>> responses;
  @JsonKey(name: 'deprecated')
  final bool? isDeprecated;
  final List<Server>? servers;
  final List<Map<String, List<String>>>? security;
  @JsonKey(name: 'x-dart-name')
  final String? xDartName;

  // We ignore the externalDocs and callbacks properties.

  @override
  String toString() =>
      'Operation{tags: $tags, summary: $summary, description: $description, '
      'operationId: $operationId, parameters: $parameters, '
      'requestBody: $requestBody, responses: $responses, '
      'isDeprecated: $isDeprecated, servers: $servers, security: $security, '
      'xDartName: $xDartName}';
}
