enum SecuritySchemeType() {
  apiKey,
  http,
  mutualTLS,
  oauth2,
  openIdConnect;

  static SecuritySchemeType fromJson(Object? value) => switch (value) {
    'apiKey' => SecuritySchemeType.apiKey,
    'http' => SecuritySchemeType.http,
    'mutualTLS' => SecuritySchemeType.mutualTLS,
    'oauth2' => SecuritySchemeType.oauth2,
    'openIdConnect' => SecuritySchemeType.openIdConnect,
    _ => throw FormatException('Invalid SecuritySchemeType: $value'),
  };
}

enum ApiKeyLocation() {
  query,
  header,
  cookie;

  static ApiKeyLocation fromJson(Object? value) => switch (value) {
    'query' => ApiKeyLocation.query,
    'header' => ApiKeyLocation.header,
    'cookie' => ApiKeyLocation.cookie,
    _ => throw FormatException('Invalid ApiKeyLocation: $value'),
  };
}

class SecurityScheme({
  required final SecuritySchemeType type,
  required final String? description,
  required final String? name,
  required final ApiKeyLocation? $in,
  required final String? scheme,
  required final String? bearerFormat,
  required final OAuth2Flows? flows,
  required final String? openIdConnectUrl,
}) {
  factory fromJson(Map<String, dynamic> json) => SecurityScheme(
    type: SecuritySchemeType.fromJson(json['type']),
    description: json['description'] as String?,
    name: json['name'] as String?,
    $in: json['in'] == null ? null : ApiKeyLocation.fromJson(json['in']),
    scheme: json['scheme'] as String?,
    bearerFormat: json['bearerFormat'] as String?,
    flows: json['flows'] == null
        ? null
        : OAuth2Flows.fromJson(json['flows'] as Map<String, dynamic>),
    openIdConnectUrl: json['openIdConnectUrl'] as String?,
  );

  @override
  String toString() =>
      'SecurityScheme{type: $type, description: $description, '
      'name: $name, in: ${$in}, scheme: $scheme, bearerFormat: $bearerFormat, '
      'flows: $flows, openIdConnectUrl: $openIdConnectUrl}';
}

class OAuth2Flows({
  required final OAuth2Flow? implicit,
  required final OAuth2Flow? password,
  required final OAuth2Flow? clientCredentials,
  required final OAuth2Flow? authorizationCode,
}) {
  factory fromJson(Map<String, dynamic> json) => OAuth2Flows(
    implicit: json['implicit'] == null
        ? null
        : OAuth2Flow.fromJson(json['implicit'] as Map<String, dynamic>),
    password: json['password'] == null
        ? null
        : OAuth2Flow.fromJson(json['password'] as Map<String, dynamic>),
    clientCredentials: json['clientCredentials'] == null
        ? null
        : OAuth2Flow.fromJson(
            json['clientCredentials'] as Map<String, dynamic>,
          ),
    authorizationCode: json['authorizationCode'] == null
        ? null
        : OAuth2Flow.fromJson(
            json['authorizationCode'] as Map<String, dynamic>,
          ),
  );

  @override
  String toString() =>
      'OAuth2Flows{implicit: $implicit, password: $password, '
      'clientCredentials: $clientCredentials, '
      'authorizationCode: $authorizationCode}';
}

class OAuth2Flow({
  required final Map<String, String> scopes,
  required final String? authorizationUrl,
  required final String? tokenUrl,
  required final String? refreshUrl,
}) {
  factory fromJson(Map<String, dynamic> json) => OAuth2Flow(
    scopes: Map<String, String>.from(json['scopes'] as Map),
    authorizationUrl: json['authorizationUrl'] as String?,
    tokenUrl: json['tokenUrl'] as String?,
    refreshUrl: json['refreshUrl'] as String?,
  );

  @override
  String toString() =>
      'OAuth2Flow{authorizationUrl: $authorizationUrl, tokenUrl: $tokenUrl, '
      'refreshUrl: $refreshUrl, scopes: $scopes}';
}
