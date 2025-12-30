import 'package:logging/logging.dart';
import 'package:tonik_core/tonik_core.dart' as core;
import 'package:tonik_parse/src/model/open_api_object.dart';
import 'package:tonik_parse/src/model/reference.dart';
import 'package:tonik_parse/src/model/security_scheme.dart' as parse;

class SecuritySchemeImporter {
  SecuritySchemeImporter(this.openApiObject);

  final OpenApiObject openApiObject;
  final log = Logger('SecuritySchemeImporter');

  late Map<String, core.SecurityScheme> securitySchemes;

  static core.Context get rootContext =>
      core.Context.initial().pushAll(['components', 'securitySchemes']);

  void import() {
    securitySchemes = <String, core.SecurityScheme>{};

    final schemes = openApiObject.components?.securitySchemes;
    if (schemes == null) return;

    final context = rootContext;

    for (final entry in schemes.entries) {
      final name = entry.key;
      final wrapper = entry.value;

      log.fine('Importing security scheme $name');

      final coreScheme = importSecurityScheme(
        name,
        wrapper,
        context.push(name),
      );
      securitySchemes[name] = coreScheme;
    }
  }

  core.SecurityScheme importSecurityScheme(
    String name,
    ReferenceWrapper<parse.SecurityScheme> wrapper,
    core.Context context,
  ) {
    switch (wrapper) {
      case Reference():
        throw UnimplementedError(
          'Security scheme references not yet supported',
        );
      case InlinedObject():
        return _parseSecurityScheme(name, wrapper.object, context);
    }
  }

  core.SecurityScheme _parseSecurityScheme(
    String name,
    parse.SecurityScheme scheme,
    core.Context context,
  ) {
    switch (scheme.type) {
      case parse.SecuritySchemeType.apiKey:
        return core.ApiKeySecurityScheme(
          type: core.SecuritySchemeType.apiKey,
          description: scheme.description,
          location: _parseApiKeyLocation(scheme.$in!),
        );
      case parse.SecuritySchemeType.http:
        return core.HttpSecurityScheme(
          type: core.SecuritySchemeType.http,
          description: scheme.description,
          scheme: scheme.scheme!,
          bearerFormat: scheme.bearerFormat,
        );
      case parse.SecuritySchemeType.oauth2:
        return core.OAuth2SecurityScheme(
          type: core.SecuritySchemeType.oauth2,
          description: scheme.description,
          flows: _parseOAuth2Flows(scheme.flows!),
        );
      case parse.SecuritySchemeType.openIdConnect:
        return core.OpenIdConnectSecurityScheme(
          type: core.SecuritySchemeType.openIdConnect,
          description: scheme.description,
          openIdConnectUrl: scheme.openIdConnectUrl!,
        );
      case parse.SecuritySchemeType.mutualTLS:
        return core.MutualTlsSecurityScheme(
          type: core.SecuritySchemeType.mutualTLS,
          description: scheme.description,
        );
    }
  }

  core.ApiKeyLocation _parseApiKeyLocation(parse.ApiKeyLocation location) {
    switch (location) {
      case parse.ApiKeyLocation.query:
        return core.ApiKeyLocation.query;
      case parse.ApiKeyLocation.header:
        return core.ApiKeyLocation.header;
      case parse.ApiKeyLocation.cookie:
        return core.ApiKeyLocation.cookie;
    }
  }

  core.OAuth2Flows _parseOAuth2Flows(parse.OAuth2Flows flows) {
    return core.OAuth2Flows(
      implicit: flows.implicit != null
          ? _parseOAuth2Flow(flows.implicit!)
          : null,
      password: flows.password != null
          ? _parseOAuth2Flow(flows.password!)
          : null,
      clientCredentials: flows.clientCredentials != null
          ? _parseOAuth2Flow(flows.clientCredentials!)
          : null,
      authorizationCode: flows.authorizationCode != null
          ? _parseOAuth2Flow(flows.authorizationCode!)
          : null,
    );
  }

  core.OAuth2Flow _parseOAuth2Flow(parse.OAuth2Flow flow) {
    return core.OAuth2Flow(
      authorizationUrl: flow.authorizationUrl ?? '',
      tokenUrl: flow.tokenUrl ?? '',
      refreshUrl: flow.refreshUrl,
      scopes: flow.scopes,
    );
  }
}
