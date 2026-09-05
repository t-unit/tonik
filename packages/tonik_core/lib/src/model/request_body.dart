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

final class MultipartRequestContent._({
  required var List<MultipartPart> parts,
  required final Context context,
  required super.rawContentType,
  required super.examples,
  required final String? sourceName,
  required final Context sourceContext,
  required var String? sourceNameOverride,
  required var AdditionalPropertiesPolicy additionalPropertiesPolicy,
  super.wireContentType,
  super.textEncoding,
  final String? name,
  var String? nameOverride,
  var List<Example> schemaExamples = const [],
  final MultipartContentAlias? alias,
  var String? description,
  var bool isDeprecated = false,
  var bool isNullable = false,
  var bool isReadOnly = false,
  var bool isWriteOnly = false,
}) extends RequestContent {
  new({
    required List<MultipartPart> parts,
    required Context context,
    required String rawContentType,
    required List<Example> examples,
    String? wireContentType,
    TextEncoding textEncoding = TextEncoding.utf8,
    String? name,
    String? nameOverride,
    String? sourceName,
    Context? sourceContext,
    String? sourceNameOverride,
    List<Example> schemaExamples = const [],
    MultipartContentAlias? alias,
    String? description,
    bool isDeprecated = false,
    bool isNullable = false,
    bool isReadOnly = false,
    bool isWriteOnly = false,
    AdditionalPropertiesPolicy? additionalPropertiesPolicy,
  }) : this._(
         parts: parts,
         context: context,
         rawContentType: rawContentType,
         examples: examples,
         wireContentType: wireContentType,
         textEncoding: textEncoding,
         name: name,
         nameOverride: nameOverride,
         sourceName: sourceName ?? name,
         sourceContext: sourceContext ?? context,
         sourceNameOverride:
             sourceNameOverride ??
             (sourceName == null || sourceName == name ? nameOverride : null),
         schemaExamples: schemaExamples,
         alias: alias,
         description: description,
         isDeprecated: isDeprecated,
         isNullable: isNullable,
         isReadOnly: isReadOnly,
         isWriteOnly: isWriteOnly,
         additionalPropertiesPolicy:
             additionalPropertiesPolicy ??
             AllowedAdditionalProperties(
               valueModel: AnyModel(context: context),
               origin: AdditionalPropertiesOrigin.implicitDefault,
             ),
       );

  @override
  ContentType get contentType => ContentType.multipart;
}

final class MultipartContentAlias({
  required final String targetName,
  required final Context targetContext,
  var String? targetNameOverride,
  final bool isNullable = false,
  final String? description,
  final bool isDeprecated = false,
  final List<Example> examples = const [],
});

final class MultipartPart({
  required final String name,
  required var Model model,
  required var PartEncoding encoding,
  required var bool isRequired,
  required var bool isNullable,
  required var bool isDeprecated,
  required var List<Example> examples,
  required var Object? defaultValue,
  var String? nameOverride,
  var String? description,
  var bool isReadOnly = false,
  var bool isWriteOnly = false,
});
