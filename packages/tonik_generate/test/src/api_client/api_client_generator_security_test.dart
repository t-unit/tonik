import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/api_client/api_client_generator.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';

void main() {
  late ApiClientGenerator generator;
  late NameManager nameManager;
  late Context testContext;
  late List<Server> testServers;

  setUp(() {
    nameManager = NameManager(generator: NameGenerator());
    generator = ApiClientGenerator(
      nameManager: nameManager,
      package: 'package:test_package/test_package.dart',
    );
    testContext = Context.initial();

    testServers = [
      const Server(
        url: 'https://api.example.com',
        description: 'Production server',
      ),
    ];
  });

  group('ApiClientGenerator Security Information', () {
    test('includes security information in method documentation', () {
      final operation = Operation(
        operationId: 'getSecureData',
        context: testContext,
        summary: 'Get secure data',
        description: 'Get secure data with authentication',
        tags: {const Tag(name: 'secure')},
        isDeprecated: false,
        path: '/secure/data',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        responses: const {},
        requestBody: null,
        securitySchemes: const {
          ApiKeySecurityScheme(
            type: SecuritySchemeType.apiKey,
            description: 'API Key authentication',
            location: ApiKeyLocation.header,
          ),
          HttpSecurityScheme(
            type: SecuritySchemeType.http,
            description: 'Bearer token authentication',
            scheme: 'bearer',
            bearerFormat: 'JWT',
          ),
        },
      );

      final generatedClass = generator.generateClass(
        {operation},
        const Tag(name: 'secure'),
        testServers,
      );

      final method = generatedClass.methods.first;

      // Check that security information is included in method documentation
      expect(method.docs, isNotEmpty);
      final docsString = method.docs.join('\n');
      expect(docsString, contains('Security:'));
      expect(
        docsString,
        contains('- API Key (header): API Key authentication'),
      );
      expect(
        docsString,
        contains('- HTTP Bearer: Bearer token authentication'),
      );
    });

    test('includes OAuth2 security information in method documentation', () {
      final operation = Operation(
        operationId: 'getUserProfile',
        context: testContext,
        summary: 'Get user profile',
        description: 'Get authenticated user profile',
        tags: {const Tag(name: 'users')},
        isDeprecated: false,
        path: '/users/me',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        responses: const {},
        requestBody: null,
        securitySchemes: const {
          OAuth2SecurityScheme(
            type: SecuritySchemeType.oauth2,
            description: 'OAuth2 authentication',
            flows: OAuth2Flows(
              authorizationCode: OAuth2Flow(
                authorizationUrl: 'https://example.com/auth',
                tokenUrl: 'https://example.com/token',
                scopes: {'read:profile': 'Read user profile'},
                refreshUrl: null,
              ),
              implicit: null,
              password: null,
              clientCredentials: null,
            ),
          ),
        },
      );

      final generatedClass = generator.generateClass(
        {operation},
        const Tag(name: 'users'),
        testServers,
      );

      final method = generatedClass.methods.first;

      expect(method.docs, isNotEmpty);
      final docsString = method.docs.join('\n');
      expect(docsString, contains('Security:'));
      expect(docsString, contains('- OAuth2: OAuth2 authentication'));
      expect(docsString, contains('Required scopes: read:profile'));
    });

    test('includes OpenID Connect security information', () {
      final operation = Operation(
        operationId: 'getIdentity',
        context: testContext,
        summary: 'Get identity',
        description: 'Get user identity',
        tags: {const Tag(name: 'identity')},
        isDeprecated: false,
        path: '/identity',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        responses: const {},
        requestBody: null,
        securitySchemes: const {
          OpenIdConnectSecurityScheme(
            type: SecuritySchemeType.openIdConnect,
            description: 'OpenID Connect authentication',
            openIdConnectUrl:
                'https://example.com/.well-known/openid_configuration',
          ),
        },
      );

      final generatedClass = generator.generateClass(
        {operation},
        const Tag(name: 'identity'),
        testServers,
      );

      final method = generatedClass.methods.first;

      expect(method.docs, isNotEmpty);
      final docsString = method.docs.join('\n');
      expect(docsString, contains('Security:'));
      expect(
        docsString,
        contains('- OpenID Connect: OpenID Connect authentication'),
      );
      expect(
        docsString,
        contains(
          'Discovery URL: https://example.com/.well-known/openid_configuration',
        ),
      );
    });

    test('omits security section when no security schemes', () {
      final operation = Operation(
        operationId: 'getPublicData',
        context: testContext,
        summary: 'Get public data',
        description: 'Get public data without authentication',
        tags: {const Tag(name: 'public')},
        isDeprecated: false,
        path: '/public/data',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        responses: const {},
        requestBody: null,
        securitySchemes: const {},
      );

      final generatedClass = generator.generateClass(
        {operation},
        const Tag(name: 'public'),
        testServers,
      );

      final method = generatedClass.methods.first;

      // Should not include security section when no security schemes
      final docsString = method.docs.join('\n');
      expect(docsString, isNot(contains('Security:')));
    });

    test('handles multiple security schemes correctly', () {
      final operation = Operation(
        operationId: 'getMultiSecureData',
        context: testContext,
        summary: 'Get multi-secure data',
        description: 'Get data with multiple authentication options',
        tags: {const Tag(name: 'secure')},
        isDeprecated: false,
        path: '/multi-secure/data',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        responses: const {},
        requestBody: null,
        securitySchemes: const {
          ApiKeySecurityScheme(
            type: SecuritySchemeType.apiKey,
            description: 'API Key in header',
            location: ApiKeyLocation.header,
          ),
          ApiKeySecurityScheme(
            type: SecuritySchemeType.apiKey,
            description: 'API Key in query',
            location: ApiKeyLocation.query,
          ),
          HttpSecurityScheme(
            type: SecuritySchemeType.http,
            description: 'Basic authentication',
            scheme: 'basic',
            bearerFormat: null,
          ),
        },
      );

      final generatedClass = generator.generateClass(
        {operation},
        const Tag(name: 'secure'),
        testServers,
      );

      final method = generatedClass.methods.first;

      expect(method.docs, isNotEmpty);
      final docsString = method.docs.join('\n');
      expect(docsString, contains('Security:'));
      expect(docsString, contains('- API Key (header): API Key in header'));
      expect(docsString, contains('- API Key (query): API Key in query'));
      expect(docsString, contains('- HTTP Basic: Basic authentication'));
    });

    test('omits description when none provided', () {
      final operation = Operation(
        operationId: 'getNoDescData',
        context: testContext,
        summary: 'Get data without descriptions',
        description: 'Get data with security schemes without descriptions',
        tags: {const Tag(name: 'nodesc')},
        isDeprecated: false,
        path: '/nodesc/data',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        responses: const {},
        requestBody: null,
        securitySchemes: const {
          ApiKeySecurityScheme(
            type: SecuritySchemeType.apiKey,
            description: null, // No description
            location: ApiKeyLocation.header,
          ),
          HttpSecurityScheme(
            type: SecuritySchemeType.http,
            description: '', // Empty description
            scheme: 'bearer',
            bearerFormat: null,
          ),
        },
      );

      final generatedClass = generator.generateClass(
        {operation},
        const Tag(name: 'nodesc'),
        testServers,
      );

      final method = generatedClass.methods.first;

      expect(method.docs, isNotEmpty);
      final docsString = method.docs.join('\n');
      expect(docsString, contains('Security:'));
      expect(docsString, contains('- API Key (header)'));
      expect(docsString, contains('- HTTP Bearer'));
      // Should not contain "No description"
      expect(docsString, isNot(contains('No description')));
      // Should not have descriptions after the scheme names
      expect(docsString, isNot(contains('- API Key (header):')));
      expect(docsString, isNot(contains('- HTTP Bearer:')));
    });
  });
}
