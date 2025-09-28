import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

@immutable
sealed class SecurityScheme {
  const SecurityScheme({
    required this.type,
    required this.description,
  });

  final SecuritySchemeType type;
  final String? description;

  @override
  String toString() => 'SecurityScheme{type: $type, description: $description}';
}

enum SecuritySchemeType {
  apiKey,
  http,
  oauth2,
  openIdConnect,
}

class ApiKeySecurityScheme extends SecurityScheme {
  const ApiKeySecurityScheme({
    required super.type,
    required this.$in,
    required super.description,
  });

  final ApiKeyLocation $in;

  @override
  String toString() =>
      'ApiKeySecurityScheme{type: $type, description: $description, '
      'in: ${$in}}';
}

enum ApiKeyLocation { query, header, cookie }

class HttpSecurityScheme extends SecurityScheme {
  const HttpSecurityScheme({
    required super.type,
    required this.scheme,
    super.description,
    this.bearerFormat,
  });

  final String scheme;
  final String? bearerFormat;

  @override
  String toString() =>
      'HttpSecurityScheme{type: $type, description: $description, '
      'scheme: $scheme, bearerFormat: $bearerFormat}';
}

class OAuth2SecurityScheme extends SecurityScheme {
  const OAuth2SecurityScheme({
    required super.type,
    required this.flows,
    super.description,
  });

  final OAuth2Flows flows;

  @override
  String toString() =>
      'OAuth2SecurityScheme{type: $type, description: $description, '
      'flows: $flows}';
}

class OpenIdConnectSecurityScheme extends SecurityScheme {
  const OpenIdConnectSecurityScheme({
    required super.type,
    required this.openIdConnectUrl,
    super.description,
  });

  final String openIdConnectUrl;

  @override
  String toString() =>
      'OpenIdConnectSecurityScheme{type: $type, description: $description, '
      'openIdConnectUrl: $openIdConnectUrl}';
}

@immutable
class OAuth2Flows {
  const OAuth2Flows({
    this.implicit,
    this.password,
    this.clientCredentials,
    this.authorizationCode,
  });

  final OAuth2Flow? implicit;
  final OAuth2Flow? password;
  final OAuth2Flow? clientCredentials;
  final OAuth2Flow? authorizationCode;

  @override
  String toString() =>
      'OAuth2Flows{implicit: $implicit, password: $password, '
      'clientCredentials: $clientCredentials, '
      'authorizationCode: $authorizationCode}';
}

@immutable
class OAuth2Flow {
  const OAuth2Flow({
    required this.authorizationUrl,
    required this.tokenUrl,
    required this.scopes,
    this.refreshUrl,
  });

  final String authorizationUrl;
  final String tokenUrl;
  final String? refreshUrl;
  final Map<String, String> scopes;

  @override
  String toString() =>
      'OAuth2Flow{authorizationUrl: $authorizationUrl, '
      'tokenUrl: $tokenUrl, refreshUrl: $refreshUrl, scopes: $scopes}';
}

@immutable
class SecurityRequirement {
  const SecurityRequirement({
    required this.scheme,
    required this.scopes,
  });

  final SecurityScheme scheme;
  final List<String> scopes;

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
