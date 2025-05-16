import 'package:code_builder/code_builder.dart';
import 'package:collection/collection.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/util/type_reference_generator.dart';

/// Generates the appropriate return type for an operation 
/// based on its responses.
TypeReference resultTypeForOperation(
  Operation operation,
  NameManager nameManager,
  String package,
) {
  final responses = operation.responses;
  final response = responses.values.firstOrNull;
  final hasHeaders = response?.hasHeaders ?? false;
  final bodyCount = response?.bodyCount ?? 0;
  final hasMultipleResponses = responses.length > 1;

  return switch ((hasHeaders, bodyCount, hasMultipleResponses)) {
    (_, _, true) => TypeReference(
      (b) =>
          b
            ..symbol = 'TonikResult'
            ..url = 'package:tonik_util/tonik_util.dart'
            ..types.add(
              refer(nameManager.responseWrapperNames(operation).$1, package),
            ),
    ),

    (false, 0, false) => TypeReference(
      (b) =>
          b
            ..symbol = 'TonikResult'
            ..url = 'package:tonik_util/tonik_util.dart'
            ..types.add(refer('void')),
    ),

    (false, 1, false) => TypeReference(
      (b) =>
          b
            ..symbol = 'TonikResult'
            ..url = 'package:tonik_util/tonik_util.dart'
            ..types.add(
              typeReference(
                response!.resolved.bodies.first.model,
                nameManager,
                package,
              ),
            ),
    ),

    (true, _, false) || (false, _, false) => TypeReference(
      (b) =>
          b
            ..symbol = 'TonikResult'
            ..url = 'package:tonik_util/tonik_util.dart'
            ..types.add(
              refer(
                nameManager.responseNames(response!.resolved).baseName,
                package,
              ),
            ),
    ),
  };
} 
