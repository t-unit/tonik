import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:tonik_core/tonik_core.dart';

@immutable
class RequestBody {
  const RequestBody({
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
    if (other is! RequestBody) return false;

    return description == other.description &&
        isRequired == other.isRequired &&
        const DeepCollectionEquality().equals(content, other.content);
  }

  @override
  int get hashCode => Object.hash(
    description,
    isRequired,
    const DeepCollectionEquality().hash(content),
  );

  @override
  String toString() =>
      'RequestBody(description: $description, isRequired: $isRequired, '
      'content: $content)';
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
