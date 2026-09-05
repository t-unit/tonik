import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

@immutable
sealed class const SecurityScheme({
  required final SecuritySchemeType type,
  required final String? description,
}) {
  @override
  String toString() => 'SecurityScheme{type: $type, description: $description}';
}

enum SecuritySchemeType() {
  apiKey,
  http,
  mutualTLS,
  oauth2,
  openIdConnect,
}

class const ApiKeySecurityScheme({
  required super.type,
  required final ApiKeyLocation location,
  required super.description,
}) extends SecurityScheme {
  @override
  String toString() =>
      'ApiKeySecurityScheme{type: $type, description: $description, '
      'location: $location}';
}

enum ApiKeyLocation() {
  query,
  header,
  cookie,
}

class const HttpSecurityScheme({
  required super.type,
  required final String scheme,
  required super.description,
  required final String? bearerFormat,
}) extends SecurityScheme {
  @override
  String toString() =>
      'HttpSecurityScheme{type: $type, description: $description, '
      'scheme: $scheme, bearerFormat: $bearerFormat}';
}

class const OAuth2SecurityScheme({
  required super.type,
  required final OAuth2Flows flows,
  required super.description,
}) extends SecurityScheme {
  @override
  String toString() =>
      'OAuth2SecurityScheme{type: $type, description: $description, '
      'flows: $flows}';
}

class const OpenIdConnectSecurityScheme({
  required super.type,
  required final String openIdConnectUrl,
  required super.description,
}) extends SecurityScheme {
  @override
  String toString() =>
      'OpenIdConnectSecurityScheme{type: $type, description: $description, '
      'openIdConnectUrl: $openIdConnectUrl}';
}

class const MutualTlsSecurityScheme({
  required super.type,
  required super.description,
}) extends SecurityScheme {
  @override
  String toString() =>
      'MutualTlsSecurityScheme{type: $type, description: $description}';
}

@immutable
class const OAuth2Flows({
  required final OAuth2Flow? implicit,
  required final OAuth2Flow? password,
  required final OAuth2Flow? clientCredentials,
  required final OAuth2Flow? authorizationCode,
}) {
  @override
  String toString() =>
      'OAuth2Flows{implicit: $implicit, password: $password, '
      'clientCredentials: $clientCredentials, '
      'authorizationCode: $authorizationCode}';
}

@immutable
class const OAuth2Flow({
  required final String authorizationUrl,
  required final String tokenUrl,
  required final Map<String, String> scopes,
  required final String? refreshUrl,
}) {
  @override
  String toString() =>
      'OAuth2Flow{authorizationUrl: $authorizationUrl, '
      'tokenUrl: $tokenUrl, refreshUrl: $refreshUrl, scopes: $scopes}';
}

@immutable
class const SecurityRequirement({
  required final SecurityScheme scheme,
  required final List<String> scopes,
}) {
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SecurityRequirement) return false;
    return scheme == other.scheme &&
        const ListEquality<String>().equals(scopes, other.scopes);
  }

  @override
  int get hashCode => Object.hash(scheme, Object.hashAll(scopes));

  @override
  String toString() => 'SecurityRequirement{scheme: $scheme, scopes: $scopes}';
}
