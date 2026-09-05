import 'package:tonik_parse/src/model/example.dart';
import 'package:tonik_parse/src/model/header.dart';
import 'package:tonik_parse/src/model/parameter.dart';
import 'package:tonik_parse/src/model/path_item.dart';
import 'package:tonik_parse/src/model/reference.dart';
import 'package:tonik_parse/src/model/request_body.dart';
import 'package:tonik_parse/src/model/response.dart';
import 'package:tonik_parse/src/model/schema.dart';
import 'package:tonik_parse/src/model/security_scheme.dart';

class Components({
  required final Map<String, Schema>? schemas,
  required final Map<String, ReferenceWrapper<Response>>? responses,
  required final Map<String, ReferenceWrapper<Parameter>>? parameters,
  required final Map<String, ReferenceWrapper<RequestBody>>? requestBodies,
  required final Map<String, ReferenceWrapper<Header>>? headers,
  required final Map<String, ReferenceWrapper<SecurityScheme>>? securitySchemes,
  required final Map<String, ReferenceWrapper<PathItem>>? pathItems,
  required final Map<String, ReferenceWrapper<Example>>? examples,
}) {
  factory fromJson(Map<String, dynamic> json) => Components(
    schemas: const SchemaMapConverter().fromJson(
      json['schemas'] as Map<String, dynamic>?,
    ),
    responses: (json['responses'] as Map<String, dynamic>?)?.map(
      (k, e) => MapEntry(k, ReferenceWrapper<Response>.fromJson(e)),
    ),
    parameters: (json['parameters'] as Map<String, dynamic>?)?.map(
      (k, e) => MapEntry(k, ReferenceWrapper<Parameter>.fromJson(e)),
    ),
    requestBodies: (json['requestBodies'] as Map<String, dynamic>?)?.map(
      (k, e) => MapEntry(k, ReferenceWrapper<RequestBody>.fromJson(e)),
    ),
    headers: (json['headers'] as Map<String, dynamic>?)?.map(
      (k, e) => MapEntry(k, ReferenceWrapper<Header>.fromJson(e)),
    ),
    securitySchemes: (json['securitySchemes'] as Map<String, dynamic>?)?.map(
      (k, e) => MapEntry(k, ReferenceWrapper<SecurityScheme>.fromJson(e)),
    ),
    pathItems: (json['pathItems'] as Map<String, dynamic>?)?.map(
      (k, e) => MapEntry(k, ReferenceWrapper<PathItem>.fromJson(e)),
    ),
    examples: (json['examples'] as Map<String, dynamic>?)?.map(
      (k, e) => MapEntry(k, ReferenceWrapper<Example>.fromJson(e)),
    ),
  );

  // We ignore the links and callbacks properties.

  @override
  String toString() =>
      'Components{schemas: $schemas, responses: $responses, '
      'parameters: $parameters, requestBodies: $requestBodies, '
      'headers: $headers, securitySchemes: $securitySchemes, '
      'pathItems: $pathItems, examples: $examples}';
}
