import 'package:tonik_parse/src/model/operation.dart';
import 'package:tonik_parse/src/model/parameter.dart';
import 'package:tonik_parse/src/model/reference.dart';
import 'package:tonik_parse/src/model/server.dart';

class PathItem {
  PathItem({
    required this.summary,
    required this.description,
    required this.get,
    required this.put,
    required this.post,
    required this.delete,
    required this.patch,
    required this.parameters,
    required this.head,
    required this.options,
    required this.servers,
    required this.trace,
  });

  factory PathItem.fromJson(Map<String, dynamic> json) => PathItem(
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

  final String? summary;
  final String? description;
  final Operation? get;
  final Operation? put;
  final Operation? post;
  final Operation? delete;
  final Operation? patch;
  final Operation? head;
  final Operation? options;
  final Operation? trace;
  final List<Server>? servers;

  final List<ReferenceWrapper<Parameter>>? parameters;

  @override
  String toString() =>
      'PathItem{summary: $summary, description: $description, get: $get, '
      'put: $put, post: $post, delete: $delete, patch: $patch, '
      'head: $head, options: $options, trace: $trace, servers: $servers, '
      'parameters: $parameters}';
}
