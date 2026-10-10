import 'package:code_builder/code_builder.dart';
import 'package:collection/collection.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/transport/transport_backend_generator.dart';
import 'package:tonik_generate/src/util/source_file_url.dart';
import 'package:tonik_generate/src/util/type_reference_generator.dart';

/// Generates the appropriate return type for an operation
/// based on its responses.
TypeReference resultTypeForOperation(
  Operation operation,
  NameManager nameManager,
  String package,
  TransportBackendGenerator backendGenerator, {
  bool useImmutableCollections = false,
}) {
  final responses = operation.responses;
  final response = responses.values.firstOrNull;
  final hasHeaders = response?.hasHeaders ?? false;
  final bodyCount = response?.bodyCount ?? 0;
  final hasMultipleResponses = responses.length > 1;
  final nativeResponseType = nativeResponseTypeForOperation(
    operation,
    backendGenerator,
  );
  return switch ((hasHeaders, bodyCount, hasMultipleResponses)) {
    (_, _, true) => TypeReference(
      (b) => b
        ..symbol = 'TonikResult'
        ..url = 'package:tonik_util/tonik_util.dart'
        ..types.addAll([
          refer(
            nameManager.responseWrapperNames(operation).$1,
            sourceFileUrl(
              package,
              'response_wrapper',
              nameManager.responseWrapperNames(operation).$1,
            ),
          ),
          nativeResponseType,
        ]),
    ),

    (false, 0, false) => TypeReference(
      (b) => b
        ..symbol = 'TonikResult'
        ..url = 'package:tonik_util/tonik_util.dart'
        ..types.addAll([refer('void'), nativeResponseType]),
    ),

    (false, 1, false) => TypeReference(
      (b) => b
        ..symbol = 'TonikResult'
        ..url = 'package:tonik_util/tonik_util.dart'
        ..types.addAll([
          responseBodyType(
            response!.resolved.bodies.first,
            nameManager,
            package,
            backendGenerator,
            useImmutableCollections: useImmutableCollections,
          ),
          nativeResponseType,
        ]),
    ),

    (true, _, false) || (false, _, false) => TypeReference(
      (b) => b
        ..symbol = 'TonikResult'
        ..url = 'package:tonik_util/tonik_util.dart'
        ..types.addAll([
          refer(
            nameManager.responseNames(response!.resolved).baseName,
            sourceFileUrl(
              package,
              'response',
              nameManager.responseNames(response.resolved).baseName,
            ),
          ),
          nativeResponseType,
        ]),
    ),
  };
}

bool hasStreamingResponse(Operation operation) =>
    operation.responses.values.any(
      (response) => response.resolved.bodies.any(
        (body) => body.delivery != ResponseDelivery.complete,
      ),
    );

TypeReference nativeResponseTypeForOperation(
  Operation operation,
  TransportBackendGenerator backend,
) => hasStreamingResponse(operation)
    ? backend.streamingNativeResponseType
    : backend.nativeResponseType;

TypeReference responseBodyType(
  ResponseBody body,
  NameManager nameManager,
  String package,
  TransportBackendGenerator backendGenerator, {
  bool useImmutableCollections = false,
}) {
  final itemType = typeReference(
    body.model,
    nameManager,
    package,
    useImmutableCollections: useImmutableCollections,
  );
  return body.delivery == ResponseDelivery.complete
      ? itemType
      : TypeReference(
          (b) => b
            ..symbol = 'Stream'
            ..url = 'dart:async'
            ..types.add(
              TypeReference(
                (b) => b
                  ..symbol = 'TonikResult'
                  ..url = 'package:tonik_util/tonik_util.dart'
                  ..types.addAll([
                    itemType,
                    backendGenerator.streamingNativeResponseType,
                  ]),
              ),
            ),
        );
}
