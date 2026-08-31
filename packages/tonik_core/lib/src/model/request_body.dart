import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:tonik_core/tonik_core.dart';

sealed class RequestBody {
  const RequestBody({required this.name, required this.context});

  final String? name;
  final Context context;

  String? get description;

  int get contentCount;

  Set<RequestContent> get resolvedContent;

  bool get isRequired;
}

@immutable
class RequestBodyAlias extends RequestBody {
  const RequestBodyAlias({
    required super.name,
    required this.requestBody,
    required super.context,
    this.description,
  });

  final RequestBody requestBody;

  @override
  final String? description;

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
class RequestBodyObject extends RequestBody {
  const RequestBodyObject({
    required super.name,
    required super.context,
    required this.description,
    required this.isRequired,
    required this.content,
  });

  @override
  final String? description;

  @override
  final bool isRequired;

  final Set<RequestContent> content;

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

sealed class RequestContent {
  RequestContent({
    required this.rawContentType,
    required this.examples,
    String? wireContentType,
    this.textEncoding = TextEncoding.utf8,
  }) : wireContentType = wireContentType ?? rawContentType;

  ContentType get contentType;
  String rawContentType;
  String wireContentType;
  TextEncoding textEncoding;
  List<Example> examples;
}

final class ModelRequestContent extends RequestContent {
  ModelRequestContent({
    required this.model,
    required this.contentType,
    required super.rawContentType,
    required super.examples,
    super.wireContentType,
    super.textEncoding,
    this.formEncoding,
  }) {
    if (contentType == ContentType.multipart) {
      throw ArgumentError('Multipart content requires multipart parts.');
    }
  }

  Model model;
  @override
  final ContentType contentType;

  /// Per-property encoding for application/x-www-form-urlencoded bodies, keyed
  /// by identity on [model]'s resolved [Property] instances — transformers must
  /// mutate those in place, never rebuild, or lookups silently miss.
  Map<Property, FieldEncoding>? formEncoding;

  @override
  String toString() =>
      'ModelRequestContent(model: $model, contentType: $contentType, '
      'rawContentType: $rawContentType, wireContentType: $wireContentType, '
      'textEncoding: $textEncoding, examples: $examples)';
}

final class MultipartRequestContent extends RequestContent {
  MultipartRequestContent({
    required this.parts,
    required this.context,
    required super.rawContentType,
    required super.examples,
    super.wireContentType,
    super.textEncoding,
    this.name,
    this.nameOverride,
    String? sourceName,
    Context? sourceContext,
    String? sourceNameOverride,
    this.schemaExamples = const [],
    this.alias,
    this.description,
    this.isDeprecated = false,
    this.isNullable = false,
    this.isReadOnly = false,
    this.isWriteOnly = false,
    AdditionalPropertiesPolicy? additionalPropertiesPolicy,
  }) : sourceName = sourceName ?? name,
       sourceContext = sourceContext ?? context,
       sourceNameOverride =
           sourceNameOverride ??
           (sourceName == null || sourceName == name ? nameOverride : null),
       additionalPropertiesPolicy =
           additionalPropertiesPolicy ??
           AllowedAdditionalProperties(
             valueModel: AnyModel(context: context),
             origin: AdditionalPropertiesOrigin.implicitDefault,
           );

  @override
  ContentType get contentType => ContentType.multipart;

  final Context context;
  final String? name;
  String? nameOverride;
  final String? sourceName;
  final Context sourceContext;
  String? sourceNameOverride;
  List<Example> schemaExamples;
  final MultipartContentAlias? alias;
  String? description;
  bool isDeprecated;
  bool isNullable;
  bool isReadOnly;
  bool isWriteOnly;
  AdditionalPropertiesPolicy additionalPropertiesPolicy;
  List<MultipartPart> parts;
}

final class MultipartContentAlias {
  MultipartContentAlias({
    required this.targetName,
    required this.targetContext,
    this.targetNameOverride,
    this.isNullable = false,
    this.description,
    this.isDeprecated = false,
    this.examples = const [],
  });

  final String targetName;
  final Context targetContext;
  String? targetNameOverride;
  final bool isNullable;
  final String? description;
  final bool isDeprecated;
  final List<Example> examples;
}

final class MultipartPart {
  MultipartPart({
    required this.name,
    required this.model,
    required this.encoding,
    required this.isRequired,
    required this.isNullable,
    required this.isDeprecated,
    required this.examples,
    required this.defaultValue,
    this.nameOverride,
    this.description,
    this.isReadOnly = false,
    this.isWriteOnly = false,
  });

  final String name;
  String? nameOverride;
  String? description;
  Model model;
  PartEncoding encoding;
  bool isRequired;
  bool isNullable;
  bool isDeprecated;
  bool isReadOnly;
  bool isWriteOnly;
  List<Example> examples;
  Object? defaultValue;
}
