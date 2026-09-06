import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:tonik_core/tonik_core.dart';

sealed class const RequestBody({
  required final String? name,
  required final Context context,
}) {
  String? get description;

  int get contentCount;

  Set<RequestContent> get resolvedContent;

  bool get isRequired;
}

@immutable
class const RequestBodyAlias({
  required super.name,
  required final RequestBody requestBody,
  required super.context,
  @override final String? description,
}) extends RequestBody {
  @override
  int get contentCount => requestBody.contentCount;

  @override
  Set<RequestContent> get resolvedContent => requestBody.resolvedContent;

  @override
  bool get isRequired => requestBody.isRequired;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RequestBodyAlias &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          requestBody == other.requestBody &&
          description == other.description &&
          context == other.context;

  @override
  int get hashCode => Object.hash(name, requestBody, description, context);

  @override
  String toString() =>
      'RequestBodyAlias(name: $name, '
      'requestBody: $requestBody, description: $description)';
}

@immutable
class const RequestBodyObject({
  required super.name,
  required super.context,
  @override required final String? description,
  @override required final bool isRequired,
  required final Set<RequestContent> content,
}) extends RequestBody {
  @override
  int get contentCount => content.length;

  @override
  Set<RequestContent> get resolvedContent => content;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! RequestBodyObject) return false;

    return name == other.name &&
        context == other.context &&
        description == other.description &&
        isRequired == other.isRequired &&
        const DeepCollectionEquality().equals(content, other.content);
  }

  @override
  int get hashCode => Object.hash(
    name,
    context,
    description,
    isRequired,
    const DeepCollectionEquality().hash(content),
  );

  @override
  String toString() =>
      'RequestBodyObject(name: $name, description: $description, '
      'isRequired: $isRequired, content: $content)';
}

sealed class RequestContent._({
  required var String rawContentType,
  required var List<Example> examples,
  required var String wireContentType,
  required var TextEncoding textEncoding,
}) {
  new({
    required String rawContentType,
    required List<Example> examples,
    String? wireContentType,
    TextEncoding textEncoding = TextEncoding.utf8,
  }) : this._(
         rawContentType: rawContentType,
         examples: examples,
         wireContentType: wireContentType ?? rawContentType,
         textEncoding: textEncoding,
       );

  ContentType get contentType;
}

final class ModelRequestContent({
  required var Model model,
  @override required final ContentType contentType,
  required super.rawContentType,
  required super.examples,
  super.wireContentType,
  super.textEncoding,

  /// Per-property encoding for application/x-www-form-urlencoded bodies, keyed
  /// by identity on [model]'s resolved [Property] instances — transformers must
  /// mutate those in place, never rebuild, or lookups silently miss.
  var Map<Property, FieldEncoding>? formEncoding,
}) extends RequestContent {
  this {
    if (contentType == ContentType.multipart) {
      throw ArgumentError('Multipart content requires multipart parts.');
    }
  }

  @override
  String toString() =>
      'ModelRequestContent(model: $model, contentType: $contentType, '
      'rawContentType: $rawContentType, wireContentType: $wireContentType, '
      'textEncoding: $textEncoding, examples: $examples)';
}

final class MultipartRequestContent({
  required var Model model,

  /// Per-use multipart encoding settings keyed by the raw schema property
  /// name. Defaults are resolved from the property's model by the generator.
  required final Map<String, PartEncoding> encoding,
  required super.rawContentType,
  required super.examples,
  super.wireContentType,
  super.textEncoding,
}) extends RequestContent {
  @override
  ContentType get contentType => ContentType.multipart;
}
