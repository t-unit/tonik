import 'package:code_builder/code_builder.dart';
import 'package:meta/meta.dart';
import 'package:tonik_core/tonik_core.dart';

/// Backend-neutral generator-time meaning of one operation request.
///
/// This value is consumed by a selected transport generator. It is never
/// emitted into a generated package.
@immutable
class OperationRequestPlan {
  OperationRequestPlan({
    required this.method,
    required this.uri,
    required List<RequestValuePlan> pathParameters,
    required List<RequestValuePlan> queryParameters,
    required List<RequestValuePlan> headers,
    required List<RequestValuePlan> cookies,
    required this.contentType,
    required this.cancellation,
    required this.response,
    required this.body,
  }) : pathParameters = List.unmodifiable(pathParameters),
       queryParameters = List.unmodifiable(queryParameters),
       headers = List.unmodifiable(headers),
       cookies = List.unmodifiable(cookies);

  final HttpMethod method;
  final Expression uri;
  final List<RequestValuePlan> pathParameters;
  final List<RequestValuePlan> queryParameters;
  final List<RequestValuePlan> headers;
  final List<RequestValuePlan> cookies;
  final Expression? contentType;
  final Expression cancellation;
  final ResponseRequirements response;
  final RequestBodyPlan body;

  String get methodName => switch (method) {
    HttpMethod.get => 'GET',
    HttpMethod.post => 'POST',
    HttpMethod.put => 'PUT',
    HttpMethod.delete => 'DELETE',
    HttpMethod.patch => 'PATCH',
    HttpMethod.head => 'HEAD',
    HttpMethod.options => 'OPTIONS',
    HttpMethod.trace => 'TRACE',
  };
}

/// One ordered query, header, or cookie input.
@immutable
class RequestValuePlan {
  const RequestValuePlan({
    required this.rawName,
    required this.normalizedName,
    required this.value,
    required this.isRequired,
    required this.allowEmpty,
    required this.allowsMultiple,
  });

  final String rawName;
  final String normalizedName;
  final Expression value;
  final bool isRequired;
  final bool allowEmpty;
  final bool allowsMultiple;
}

/// Response details required by common response selection and decoding.
@immutable
class ResponseRequirements {
  ResponseRequirements({
    required this.expectsBytes,
    required List<ResponseStatus> statuses,
    required List<String> contentTypes,
  }) : statuses = List.unmodifiable(statuses),
       contentTypes = List.unmodifiable(contentTypes);

  final bool expectsBytes;
  final List<ResponseStatus> statuses;
  final List<String> contentTypes;
}

/// Backend-neutral request body meaning.
sealed class RequestBodyPlan {
  const RequestBodyPlan();
}

@immutable
final class AbsentBodyPlan extends RequestBodyPlan {
  const AbsentBodyPlan();
}

sealed class PresentBodyPlan extends RequestBodyPlan {
  const PresentBodyPlan({
    required this.value,
    required this.rawContentType,
    required this.isRequired,
  });

  final Expression value;
  final String rawContentType;
  final bool isRequired;
}

@immutable
final class JsonBodyPlan extends PresentBodyPlan {
  const JsonBodyPlan({
    required super.value,
    required super.rawContentType,
    required super.isRequired,
  });
}

@immutable
final class TextBodyPlan extends PresentBodyPlan {
  const TextBodyPlan({
    required super.value,
    required super.rawContentType,
    required this.encoding,
    required super.isRequired,
  });

  final TextEncoding encoding;
}

@immutable
final class BytesBodyPlan extends PresentBodyPlan {
  const BytesBodyPlan({
    required super.value,
    required super.rawContentType,
    required super.isRequired,
  });
}

@immutable
class FormEntryPlan {
  const FormEntryPlan({
    required this.name,
    required this.value,
    required this.isNullable,
    required this.allowsMultiple,
  });

  final String name;
  final Expression value;
  final bool isNullable;
  final bool allowsMultiple;
}

@immutable
final class FormBodyPlan extends PresentBodyPlan {
  FormBodyPlan({
    required super.value,
    required super.rawContentType,
    required List<FormEntryPlan> entries,
    required super.isRequired,
  }) : entries = List.unmodifiable(entries);

  final List<FormEntryPlan> entries;
}

enum MultipartPartSource { scalar, bytes, fileBytesOrPath }

@immutable
class MultipartPartPlan {
  const MultipartPartPlan({
    required this.name,
    required this.value,
    required this.source,
    required this.isNullable,
    required this.filename,
    required this.contentType,
    this.allowsMultiple = false,
  });

  final String name;
  final Expression value;
  final MultipartPartSource source;
  final bool isNullable;
  final bool allowsMultiple;
  final String? filename;
  final String? contentType;
}

@immutable
final class MultipartBodyPlan extends PresentBodyPlan {
  MultipartBodyPlan({
    required super.value,
    required super.rawContentType,
    required List<MultipartPartPlan> parts,
    required super.isRequired,
  }) : parts = List.unmodifiable(parts);

  final List<MultipartPartPlan> parts;
}

/// A runtime-selected body variant for OpenAPI operations with multiple media
/// types. Each arm still has one of the concrete backend-neutral meanings.
@immutable
final class BodySelectionPlan extends RequestBodyPlan {
  BodySelectionPlan({
    required this.value,
    required List<PresentBodyPlan> variants,
    required this.isRequired,
  }) : variants = List.unmodifiable(variants);

  final Expression value;
  final List<PresentBodyPlan> variants;
  final bool isRequired;
}

/// Whether content-type selection depends on the runtime request body value.
bool requestContentTypeNeedsBodyValue(RequestBody? requestBody) {
  final content = requestBody?.resolvedContent;
  if (content == null || content.isEmpty) {
    return false;
  }
  if (requestBody!.contentCount > 1) {
    return true;
  }
  return !requestBody.isRequired &&
      content.first.contentType != ContentType.multipart;
}
