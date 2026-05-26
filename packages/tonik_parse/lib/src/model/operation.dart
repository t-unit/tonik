import 'package:tonik_parse/src/model/parameter.dart';
import 'package:tonik_parse/src/model/reference.dart';
import 'package:tonik_parse/src/model/request_body.dart';
import 'package:tonik_parse/src/model/response.dart';
import 'package:tonik_parse/src/model/server.dart';

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

  factory Operation.fromJson(Map<String, dynamic> json) => Operation(
    tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
    summary: json['summary'] as String?,
    description: json['description'] as String?,
    operationId: json['operationId'] as String?,
    parameters: (json['parameters'] as List<dynamic>?)
        ?.map(ReferenceWrapper<Parameter>.fromJson)
        .toList(),
    requestBody: json['requestBody'] == null
        ? null
        : ReferenceWrapper<RequestBody>.fromJson(json['requestBody']),
    responses: (json['responses'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(k, ReferenceWrapper<Response>.fromJson(e)),
    ),
    isDeprecated: json['deprecated'] as bool?,
    servers: (json['servers'] as List<dynamic>?)
        ?.map((e) => Server.fromJson(e as Map<String, dynamic>))
        .toList(),
    security: (json['security'] as List<dynamic>?)
        ?.map(
          (e) => (e as Map<String, dynamic>).map(
            (k, e) => MapEntry(
              k,
              (e as List<dynamic>).map((e) => e as String).toList(),
            ),
          ),
        )
        .toList(),
    xDartName: json['x-dart-name'] as String?,
  );

  final List<String>? tags;
  final String? summary;
  final String? description;
  final String? operationId;
  final List<ReferenceWrapper<Parameter>>? parameters;
  final ReferenceWrapper<RequestBody>? requestBody;
  final Map<String, ReferenceWrapper<Response>> responses;
  final bool? isDeprecated;
  final List<Server>? servers;
  final List<Map<String, List<String>>>? security;
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
