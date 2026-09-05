import 'package:tonik_parse/src/model/operation.dart';
import 'package:tonik_parse/src/model/parameter.dart';
import 'package:tonik_parse/src/model/reference.dart';
import 'package:tonik_parse/src/model/server.dart';

class PathItem({
  required final String? summary,
  required final String? description,
  required final Operation? get,
  required final Operation? put,
  required final Operation? post,
  required final Operation? delete,
  required final Operation? patch,
  required final List<ReferenceWrapper<Parameter>>? parameters,
  required final Operation? head,
  required final Operation? options,
  required final List<Server>? servers,
  required final Operation? trace,
}) {
  factory fromJson(Map<String, dynamic> json) => PathItem(
    summary: json['summary'] as String?,
    description: json['description'] as String?,
    get: json['get'] == null
        ? null
        : Operation.fromJson(json['get'] as Map<String, dynamic>),
    put: json['put'] == null
        ? null
        : Operation.fromJson(json['put'] as Map<String, dynamic>),
    post: json['post'] == null
        ? null
        : Operation.fromJson(json['post'] as Map<String, dynamic>),
    delete: json['delete'] == null
        ? null
        : Operation.fromJson(json['delete'] as Map<String, dynamic>),
    patch: json['patch'] == null
        ? null
        : Operation.fromJson(json['patch'] as Map<String, dynamic>),
    parameters: (json['parameters'] as List<dynamic>?)
        ?.map(ReferenceWrapper<Parameter>.fromJson)
        .toList(),
    head: json['head'] == null
        ? null
        : Operation.fromJson(json['head'] as Map<String, dynamic>),
    options: json['options'] == null
        ? null
        : Operation.fromJson(json['options'] as Map<String, dynamic>),
    servers: (json['servers'] as List<dynamic>?)
        ?.map((e) => Server.fromJson(e as Map<String, dynamic>))
        .toList(),
    trace: json['trace'] == null
        ? null
        : Operation.fromJson(json['trace'] as Map<String, dynamic>),
  );

  @override
  String toString() =>
      'PathItem{summary: $summary, description: $description, get: $get, '
      'put: $put, post: $post, delete: $delete, patch: $patch, '
      'head: $head, options: $options, trace: $trace, servers: $servers, '
      'parameters: $parameters}';
}
