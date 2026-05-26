enum SecuritySchemeType {
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

enum ApiKeyLocation {
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

class SecurityScheme {
  SecurityScheme({
    required this.type,
    required this.description,
    required this.name,
    required this.$in,
    required this.scheme,
    required this.bearerFormat,
    required this.flows,
    required this.openIdConnectUrl,
  });

  factory SecurityScheme.fromJson(Map<String, dynamic> json) => SecurityScheme(
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

  final SecuritySchemeType type;
  final String? description;
  final String? name;
  final ApiKeyLocation? $in;
  final String? scheme;
  final String? bearerFormat;
  final OAuth2Flows? flows;
  final String? openIdConnectUrl;

  @override
  String toString() =>
      'SecurityScheme{type: $type, description: $description, '
      'name: $name, in: ${$in}, scheme: $scheme, bearerFormat: $bearerFormat, '
      'flows: $flows, openIdConnectUrl: $openIdConnectUrl}';
}

class OAuth2Flows {
  OAuth2Flows({
    required this.implicit,
    required this.password,
    required this.clientCredentials,
    required this.authorizationCode,
  });

  factory OAuth2Flows.fromJson(Map<String, dynamic> json) => OAuth2Flows(
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

class OAuth2Flow {
  OAuth2Flow({
    required this.scopes,
    required this.authorizationUrl,
    required this.tokenUrl,
    required this.refreshUrl,
  });

  factory OAuth2Flow.fromJson(Map<String, dynamic> json) => OAuth2Flow(
    scopes: Map<String, String>.from(json['scopes'] as Map),
    authorizationUrl: json['authorizationUrl'] as String?,
    tokenUrl: json['tokenUrl'] as String?,
    refreshUrl: json['refreshUrl'] as String?,
  );

  final String? authorizationUrl;
  final String? tokenUrl;
  final String? refreshUrl;
  final Map<String, String> scopes;

  @override
  String toString() =>
      'OAuth2Flow{authorizationUrl: $authorizationUrl, tokenUrl: $tokenUrl, '
      'refreshUrl: $refreshUrl, scopes: $scopes}';
}
