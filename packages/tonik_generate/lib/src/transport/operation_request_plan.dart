import 'package:code_builder/code_builder.dart';
import 'package:meta/meta.dart';
import 'package:tonik_core/tonik_core.dart';

/// Backend-neutral generator-time meaning of one operation request.
///
/// This value is consumed by a selected transport generator. It is never
/// emitted into a generated package.
@immutable
class const OperationRequestPlan._({
  required final HttpMethod method,
  required final Expression uri,
  required final List<RequestValuePlan> pathParameters,
  required final List<RequestValuePlan> queryParameters,
  required final List<RequestValuePlan> headers,
  required final List<RequestValuePlan> cookies,
  required final Expression? contentType,
  required final Expression cancellation,
  required final ResponseRequirements response,
  required final RequestBodyPlan body,
}) {
  new({
    required HttpMethod method,
    required Expression uri,
    required List<RequestValuePlan> pathParameters,
    required List<RequestValuePlan> queryParameters,
    required List<RequestValuePlan> headers,
    required List<RequestValuePlan> cookies,
    required Expression? contentType,
    required Expression cancellation,
    required ResponseRequirements response,
    required RequestBodyPlan body,
  }) : this._(
         method: method,
         uri: uri,
         pathParameters: List.unmodifiable(pathParameters),
         queryParameters: List.unmodifiable(queryParameters),
         headers: List.unmodifiable(headers),
         cookies: List.unmodifiable(cookies),
         contentType: contentType,
         cancellation: cancellation,
         response: response,
         body: body,
       );

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
class const RequestValuePlan({
  required final String rawName,
  required final String normalizedName,
  required final Expression value,
  required final bool isRequired,
  required final bool allowEmpty,
  required final bool allowsMultiple,
});

/// Response details required by common response selection and decoding.
@immutable
class const ResponseRequirements._({
  required final bool expectsBytes,
  required final List<ResponseStatus> statuses,
  required final List<String> contentTypes,
}) {
  new({
    required bool expectsBytes,
    required List<ResponseStatus> statuses,
    required List<String> contentTypes,
  }) : this._(
         expectsBytes: expectsBytes,
         statuses: List.unmodifiable(statuses),
         contentTypes: List.unmodifiable(contentTypes),
       );
}

/// Backend-neutral request body meaning.
sealed class const RequestBodyPlan();

@immutable
final class const AbsentBodyPlan() extends RequestBodyPlan;

sealed class const PresentBodyPlan({
  required final Expression value,
  required final String rawContentType,
  required final bool isRequired,
}) extends RequestBodyPlan;

@immutable
final class const JsonBodyPlan({
  required super.value,
  required super.rawContentType,
  required super.isRequired,
}) extends PresentBodyPlan;

@immutable
final class const TextBodyPlan({
  required super.value,
  required super.rawContentType,
  required final TextEncoding encoding,
  required super.isRequired,
}) extends PresentBodyPlan;

@immutable
final class const BytesBodyPlan({
  required super.value,
  required super.rawContentType,
  required super.isRequired,
}) extends PresentBodyPlan;

@immutable
class const FormEntryPlan({
  required final String name,
  required final Expression value,
  required final bool isNullable,
  required final bool allowsMultiple,
});

@immutable
final class const FormBodyPlan._({
  required super.value,
  required super.rawContentType,
  required final List<FormEntryPlan> entries,
  required super.isRequired,
}) extends PresentBodyPlan {
  new({
    required Expression value,
    required String rawContentType,
    required List<FormEntryPlan> entries,
    required bool isRequired,
  }) : this._(
         value: value,
         rawContentType: rawContentType,
         entries: List.unmodifiable(entries),
         isRequired: isRequired,
       );
}

enum MultipartValueSource() {
  field,
  text,
  bytes,
  path,
  file,
}

sealed class const MultipartEmission();

final class const MultipartCode(final Code code) extends MultipartEmission;

enum MultipartMergeHelper() {
  dynamicValues,
  lists,
  propertyValues,
}

final class const MultipartAppend({
  required final Expression name,
  required final Expression value,
  required final MultipartValueSource source,
  final Expression? filename,
  final String? contentType,
  final Expression? headers,
}) extends MultipartEmission;

@immutable
final class const MultipartBodyPlan._({
  required super.value,
  required super.rawContentType,
  required final List<MultipartEmission> emissions,
  required super.isRequired,
  required final bool usesCustomParts,
  required final Set<MultipartMergeHelper> mergeHelpers,
  required final String? runtimeEncodingError,
}) extends PresentBodyPlan {
  new({
    required Expression value,
    required String rawContentType,
    required List<MultipartEmission> emissions,
    required bool isRequired,
    bool usesCustomParts = false,
    Set<MultipartMergeHelper> mergeHelpers = const {},
    String? runtimeEncodingError,
  }) : this._(
         value: value,
         rawContentType: rawContentType,
         emissions: List.unmodifiable(emissions),
         isRequired: isRequired,
         usesCustomParts: usesCustomParts,
         mergeHelpers: Set.unmodifiable(mergeHelpers),
         runtimeEncodingError: runtimeEncodingError,
       );
}

/// A runtime-selected body variant for OpenAPI operations with multiple media
/// types. Each arm still has one of the concrete backend-neutral meanings.
@immutable
final class const BodySelectionPlan._({
  required final Expression value,
  required final List<PresentBodyPlan> variants,
  required final bool isRequired,
}) extends RequestBodyPlan {
  new({
    required Expression value,
    required List<PresentBodyPlan> variants,
    required bool isRequired,
  }) : this._(
         value: value,
         variants: List.unmodifiable(variants),
         isRequired: isRequired,
       );
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
