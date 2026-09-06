import 'package:code_builder/code_builder.dart';
import 'package:tonik_generate/src/transport/operation_request_plan.dart';

/// Generates the backend-specific operation base shared by generated
/// operations.
abstract interface class const OperationBaseGenerator() {
  String get className;

  String get filename;

  String get clientConstructorParameterName;

  Iterable<Spec> generate();

  Reference baseType({
    required String package,
    required Reference valueType,
    String? filename,
  });

  Expression executionInvocation({
    required String package,
    required String filename,
    required OperationRequestPlan plan,
    required Expression path,
    required Expression queryParameters,
    required Expression data,
    required Expression options,
    required Expression? decode,
    required bool isVoid,
    required bool isDataAsync,
  });
}
