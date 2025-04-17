import 'package:json_annotation/json_annotation.dart';
import 'package:tonik_parse/src/model/operation.dart';
import 'package:tonik_parse/src/model/parameter.dart';
import 'package:tonik_parse/src/model/reference.dart';
import 'package:tonik_parse/src/model/server.dart';

part 'path_item.g.dart';

@JsonSerializable()
class PathItem {
  PathItem({
    required this.ref,
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

  factory PathItem.fromJson(Map<String, dynamic> json) =>
      _$PathItemFromJson(json);

  final String? ref;
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
