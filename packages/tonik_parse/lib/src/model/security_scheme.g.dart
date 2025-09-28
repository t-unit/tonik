// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'security_scheme.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SecurityScheme _$SecuritySchemeFromJson(Map<String, dynamic> json) =>
    SecurityScheme(
      type: $enumDecode(_$SecuritySchemeTypeEnumMap, json['type']),
      description: json['description'] as String?,
      name: json['name'] as String?,
      $in: $enumDecodeNullable(_$ApiKeyLocationEnumMap, json['in']),
      scheme: json['scheme'] as String?,
      bearerFormat: json['bearerFormat'] as String?,
      flows:
          json['flows'] == null
              ? null
              : OAuth2Flows.fromJson(json['flows'] as Map<String, dynamic>),
      openIdConnectUrl: json['openIdConnectUrl'] as String?,
    );

const _$SecuritySchemeTypeEnumMap = {
  SecuritySchemeType.apiKey: 'apiKey',
  SecuritySchemeType.http: 'http',
  SecuritySchemeType.oauth2: 'oauth2',
  SecuritySchemeType.openIdConnect: 'openIdConnect',
};

const _$ApiKeyLocationEnumMap = {
  ApiKeyLocation.query: 'query',
  ApiKeyLocation.header: 'header',
  ApiKeyLocation.cookie: 'cookie',
};

OAuth2Flows _$OAuth2FlowsFromJson(Map<String, dynamic> json) => OAuth2Flows(
  implicit:
      json['implicit'] == null
          ? null
          : OAuth2Flow.fromJson(json['implicit'] as Map<String, dynamic>),
  password:
      json['password'] == null
          ? null
          : OAuth2Flow.fromJson(json['password'] as Map<String, dynamic>),
  clientCredentials:
      json['clientCredentials'] == null
          ? null
          : OAuth2Flow.fromJson(
            json['clientCredentials'] as Map<String, dynamic>,
          ),
  authorizationCode:
      json['authorizationCode'] == null
          ? null
          : OAuth2Flow.fromJson(
            json['authorizationCode'] as Map<String, dynamic>,
          ),
);

OAuth2Flow _$OAuth2FlowFromJson(Map<String, dynamic> json) => OAuth2Flow(
  scopes: Map<String, String>.from(json['scopes'] as Map),
  authorizationUrl: json['authorizationUrl'] as String?,
  tokenUrl: json['tokenUrl'] as String?,
  refreshUrl: json['refreshUrl'] as String?,
);
