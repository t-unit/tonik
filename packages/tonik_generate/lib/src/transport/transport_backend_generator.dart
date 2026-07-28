import 'package:code_builder/code_builder.dart';
import 'package:meta/meta.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/transport/operation_request_plan.dart';

@immutable
class DependencyDescriptor {
  const DependencyDescriptor({
    required this.name,
    required this.versionConstraint,
  });

  final String name;
  final String versionConstraint;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DependencyDescriptor &&
          name == other.name &&
          versionConstraint == other.versionConstraint;

  @override
  int get hashCode => Object.hash(name, versionConstraint);
}

/// Selected immutable generator-time transport implementation.
abstract interface class TransportBackendGenerator {
  const TransportBackendGenerator();

  List<DependencyDescriptor> get dependencies;

  Reference get nativeClientType;

  TypeReference get nativeResponseType;

  /// Response type used while buffering and parsing a completed operation.
  TypeReference get operationResponseType;

  Reference get requestOptionsType;

  Parameter get cancellationParameter;

  Expression responseStatusCode(Expression response);

  Expression responseContentType(Expression response);

  Expression responseBodyBytes(Expression response);

  Expression responseHeaderValues(Expression response, String name);

  Reference get serverConfigType => TypeReference(
    (b) => b
      ..symbol = 'ServerConfig'
      ..url = 'package:tonik_util/tonik_util.dart'
      ..types.add(nativeClientType),
  );

  String get clientGetterName;

  String get clientAccessorFieldName;

  Reference get nativeClientAccessorType;

  String get clientAdapterName;

  String get clientAdapterFieldName;

  Class generateClientAdapter();

  Method generateBodyMethod({
    required Operation operation,
    required NameManager nameManager,
    required String package,
    required bool useImmutableCollections,
  });

  Method generateOptionsMethod({
    required Operation operation,
    required NameManager nameManager,
    required String package,
    required bool useImmutableCollections,
    required List<({String normalizedName, RequestHeaderObject parameter})>
    headers,
    required List<({String normalizedName, CookieParameterObject parameter})>
    cookies,
  });

  Code generateDispatchStatements({
    required OperationRequestPlan plan,
    required String responseVariable,
    required Reference resultValueType,
  });
}
