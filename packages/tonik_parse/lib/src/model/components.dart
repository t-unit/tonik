import 'package:json_annotation/json_annotation.dart';
import 'package:tonik_parse/src/model/header.dart';
import 'package:tonik_parse/src/model/parameter.dart';
import 'package:tonik_parse/src/model/reference.dart';
import 'package:tonik_parse/src/model/request_body.dart';
import 'package:tonik_parse/src/model/response.dart';
import 'package:tonik_parse/src/model/schema.dart';
import 'package:tonik_parse/src/model/security_scheme.dart';

part 'components.g.dart';

@JsonSerializable(createToJson: false)
class Components {
  Components({
    required this.schemas,
    required this.responses,
    required this.parameters,
    required this.requestBodies,
    required this.headers,
    required this.securitySchemes,
  });

  factory Components.fromJson(Map<String, dynamic> json) =>
      _$ComponentsFromJson(json);

  final Map<String, ReferenceWrapper<Schema>>? schemas;
  final Map<String, ReferenceWrapper<Response>>? responses;
  final Map<String, ReferenceWrapper<Parameter>>? parameters;
  final Map<String, ReferenceWrapper<RequestBody>>? requestBodies;
  final Map<String, ReferenceWrapper<Header>>? headers;
  final Map<String, ReferenceWrapper<SecurityScheme>>? securitySchemes;

  // We ignore the examples, links and callbacks properties.

  @override
  String toString() =>
      'Components{schemas: $schemas, responses: $responses, '
      'parameters: $parameters, requestBodies: $requestBodies, '
      'headers: $headers, securitySchemes: $securitySchemes}';
}
