import 'package:tonik_parse/src/model/header.dart';
import 'package:tonik_parse/src/model/parameter.dart';
import 'package:tonik_parse/src/model/path_item.dart';
import 'package:tonik_parse/src/model/request_body.dart';
import 'package:tonik_parse/src/model/response.dart';
import 'package:tonik_parse/src/model/schema.dart';
import 'package:tonik_parse/src/model/server.dart';

sealed class ReferenceWrapper<T> {
  ReferenceWrapper();

  factory ReferenceWrapper.fromJson(Object? json) {
    const referenceKey = r'$ref';

    final map = json! as Map<String, dynamic>;

    if (map.containsKey(referenceKey)) {
      return Reference(map[referenceKey]! as String);
    }

    if (T == Server) {
      return InlinedObject(Server.fromJson(map) as T);
    } else if (T == PathItem) {
      return InlinedObject(PathItem.fromJson(map) as T);
    } else if (T == Schema) {
      return InlinedObject(Schema.fromJson(map) as T);
    } else if (T == Parameter) {
      return InlinedObject(Parameter.fromJson(map) as T);
    } else if (T == RequestBody) {
      return InlinedObject(RequestBody.fromJson(map) as T);
    } else if (T == Response) {
      return InlinedObject(Response.fromJson(map) as T);
    } else if (T == Header) {
      return InlinedObject(Header.fromJson(map) as T);
    }

    throw UnimplementedError();
  }

  Map<String, dynamic> toJson() => throw UnimplementedError();
}

class Reference<T> extends ReferenceWrapper<T> {
  Reference(this.ref);

  final String ref;

  @override
  String toString() => 'Reference{ref: $ref}';
}

class InlinedObject<T> extends ReferenceWrapper<T> {
  InlinedObject(this.object);

  final T object;

  @override
  String toString() => 'InlinedObject{object: $object}';
}
