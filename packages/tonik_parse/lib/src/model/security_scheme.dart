import 'package:json_annotation/json_annotation.dart';

part 'security_scheme.g.dart';

enum SecuritySchemeType {
  apiKey,
  http,
  oauth2,
  openIdConnect,
}

enum ApiKeyLocation {
  query,
  header,
  cookie,
}

@JsonSerializable(createToJson: false)
class SecurityScheme {
  SecurityScheme({
    required this.type,
    this.description,
    this.name,
    this.$in,
    this.scheme,
    this.bearerFormat,
    this.flows,
    this.openIdConnectUrl,
  });

  factory SecurityScheme.fromJson(Map<String, dynamic> json) =>
      _$SecuritySchemeFromJson(json);

  final SecuritySchemeType type;
  final String? description;
  final String? name;
  @JsonKey(name: 'in')
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

@JsonSerializable(createToJson: false)
class OAuth2Flows {
  OAuth2Flows({
    this.implicit,
    this.password,
    this.clientCredentials,
    this.authorizationCode,
  });

  factory OAuth2Flows.fromJson(Map<String, dynamic> json) =>
      _$OAuth2FlowsFromJson(json);

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

@JsonSerializable(createToJson: false)
class OAuth2Flow {
  OAuth2Flow({
    required this.scopes,
    this.authorizationUrl,
    this.tokenUrl,
    this.refreshUrl,
  });

  factory OAuth2Flow.fromJson(Map<String, dynamic> json) =>
      _$OAuth2FlowFromJson(json);

  final String? authorizationUrl;
  final String? tokenUrl;
  final String? refreshUrl;
  final Map<String, String> scopes;

  @override
  String toString() =>
      'OAuth2Flow{authorizationUrl: $authorizationUrl, tokenUrl: $tokenUrl, '
      'refreshUrl: $refreshUrl, scopes: $scopes}';
}
