import 'package:tonik_parse/src/model/example.dart';
import 'package:tonik_parse/src/model/header.dart';
import 'package:tonik_parse/src/model/media_type.dart';
import 'package:tonik_parse/src/model/parameter.dart';
import 'package:tonik_parse/src/model/path_item.dart';
import 'package:tonik_parse/src/model/request_body.dart';
import 'package:tonik_parse/src/model/response.dart';
import 'package:tonik_parse/src/model/security_scheme.dart';
import 'package:tonik_parse/src/model/server.dart';

sealed class ReferenceWrapper<T>() {
  factory fromJson(Object? json) {
    const referenceKey = r'$ref';

    final map = json! as Map<String, dynamic>;

    if (map.containsKey(referenceKey)) {
      final ref = parseReference(map[referenceKey]);
      final description = T == MediaType
          ? _optionalString(map['description'])
          : map['description'] as String?;
      final summary = T == MediaType
          ? _optionalString(map['summary'])
          : map['summary'] as String?;
      return Reference(ref, description: description, summary: summary);
    }

    if (T == Server) {
      return InlinedObject(Server.fromJson(map) as T);
    } else if (T == PathItem) {
      return InlinedObject(PathItem.fromJson(map) as T);
    } else if (T == Parameter) {
      return InlinedObject(Parameter.fromJson(map) as T);
    } else if (T == RequestBody) {
      return InlinedObject(RequestBody.fromJson(map) as T);
    } else if (T == Response) {
      return InlinedObject(Response.fromJson(map) as T);
    } else if (T == Header) {
      return InlinedObject(Header.fromJson(map) as T);
    } else if (T == SecurityScheme) {
      return InlinedObject(SecurityScheme.fromJson(map) as T);
    } else if (T == MediaType) {
      return InlinedObject(MediaType.fromJson(map) as T);
    } else if (T == Example) {
      return InlinedObject(Example.fromJson(map) as T);
    }

    throw UnimplementedError();
  }
}

class Reference<T>(
  final String ref, {
  final String? description,
  final String? summary,
}) extends ReferenceWrapper<T> {
  @override
  String toString() =>
      'Reference{ref: $ref, description: $description, summary: $summary}';
}

class InlinedObject<T>(final T object) extends ReferenceWrapper<T> {
  @override
  String toString() => 'InlinedObject{object: $object}';
}

bool isExternalReference(String ref) {
  final uri = Uri.parse(ref);
  return uri.hasScheme ||
      uri.hasAuthority ||
      uri.path.isNotEmpty ||
      uri.hasQuery;
}

String? _optionalString(Object? value) => value is String ? value : null;

String parseReference(Object? value) {
  if (value is String) return value;
  throw MalformedReferenceError(value);
}

// Optional-field recovery must not swallow a malformed reference encountered
// while parsing that field, including references in nested schemas.
class MalformedReferenceError(final Object? value) extends TypeError {
  @override
  String toString() =>
      'Invalid reference: expected a string, found ${value.runtimeType}.';
}
