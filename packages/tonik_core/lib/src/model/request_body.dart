import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:tonik_core/tonik_core.dart';

sealed class RequestBody {
  const RequestBody({required this.name, required this.context});

  final String? name;
  final Context context;
}

@immutable
class RequestBodyAlias extends RequestBody {
  const RequestBodyAlias({
    required super.name,
    required this.requestBody,
    required super.context,
  });

  final RequestBody requestBody;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RequestBodyAlias &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          requestBody == other.requestBody &&
          context == other.context;

  @override
  int get hashCode => Object.hash(name, requestBody, context);

  @override
  String toString() =>
      'RequestBodyAlias(name: $name, '
      'requestBody: $requestBody)';
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

  final String? description;
  final bool isRequired;
  final Set<RequestContent> content;

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

@immutable
class RequestContent {
  const RequestContent({
    required this.model,
    required this.contentType,
    required this.rawContentType,
  });

  final Model model;
  final ContentType contentType;
  final String rawContentType;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! RequestContent) return false;

    return model == other.model &&
        contentType == other.contentType &&
        rawContentType == other.rawContentType;
  }

  @override
  int get hashCode => Object.hash(model, contentType, rawContentType);

  @override
  String toString() =>
      'RequestContent(model: $model, contentType: $contentType, '
      'rawContentType: $rawContentType)';
}
