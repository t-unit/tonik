# Authentication Guide

This guide explains how to handle authentication when using Tonik-generated API clients.

## Overview

Tonik generates API client classes that work with Server objects. Authentication is configured through `ServerConfig` interceptors, providing clean separation between API logic and authentication concerns.

## Basic Authentication Setup

### 1. Bearer Token Authentication

```dart
import 'package:dio/dio.dart';
import 'package:tonik/your_api_client.dart'; // Your generated client
import 'package:tonik_util/tonik_util.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._token);
  
  final String _token;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $_token';
    }
    handler.next(options);
  }
}

// Setup with ServerConfig
final serverConfig = ServerConfig(
  interceptors: [AuthInterceptor('your-jwt-token-here')],
);

final server = YourServer(serverConfig: serverConfig);
final apiClient = YourApiClient(server);
final users = await apiClient.getUsers();
```

### 2. API Key Authentication

```dart
class ApiKeyService {
  ApiKeyService(this._apiKey);

  final String _apiKey;

  String get apiKey => _apiKey;

  Interceptor createAuthInterceptor() {
    return _ApiKeyInterceptor(this);
  }
}

class _ApiKeyInterceptor extends Interceptor {
  _ApiKeyInterceptor(this._apiKeyService);

  final ApiKeyService _apiKeyService;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_apiKeyService.apiKey.isNotEmpty) {
      // Add as query parameter
      options.queryParameters['api_key'] = _apiKeyService.apiKey;

      // Or add as header
      // options.headers['X-API-Key'] = _apiKeyService.apiKey;
    }
    handler.next(options);
  }
}

// Setup with ServerConfig
final apiKeyService = ApiKeyService('your-api-key-here');
final serverConfig = ServerConfig(
  interceptors: [apiKeyService.createAuthInterceptor()],
);

final server = YourServer(serverConfig: serverConfig);
final apiClient = YourApiClient(server);
```

### 3. OAuth2 Flow

```dart
class OAuth2Service {
  OAuth2Service({
    required this.clientId,
    required this.clientSecret,
    required this.tokenUrl,
  });

  String? _accessToken;
  final String _clientId;
  final String _clientSecret;
  final String _tokenUrl;

  String? get accessToken => _accessToken;

  Future<void> _refreshToken() async {
    final response = await Dio().post(
      _tokenUrl,
      data: {
        'grant_type': 'client_credentials',
        'client_id': _clientId,
        'client_secret': _clientSecret,
      },
    );

    _accessToken = response.data['access_token'];
  }

  Interceptor createAuthInterceptor() {
    return _OAuth2Interceptor(this);
  }
}

class _OAuth2Interceptor extends Interceptor {
  _OAuth2Interceptor(this._oauth2Service);

  final OAuth2Service _oauth2Service;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (_oauth2Service.accessToken == null) {
      await _oauth2Service._refreshToken();
    }

    if (_oauth2Service.accessToken != null) {
      options.headers['Authorization'] = 'Bearer ${_oauth2Service.accessToken}';
    }
    handler.next(options);
  }
}

// Setup with ServerConfig
final oauth2Service = OAuth2Service(
  clientId: 'your-client-id',
  clientSecret: 'your-client-secret',
  tokenUrl: 'https://auth.example.com/oauth/token',
);

final serverConfig = ServerConfig(
  interceptors: [oauth2Service.createAuthInterceptor()],
);

final server = YourServer(serverConfig: serverConfig);
final apiClient = YourApiClient(server);
```

## Advanced Authentication Patterns

### Token Refresh with Retry

```dart
class TokenRefreshService {
  TokenRefreshService(this._tokenUrl);

  String? _accessToken;
  String? _refreshToken;
  final String _tokenUrl;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;

  Future<void> _refreshAccessToken() async {
    final response = await Dio().post(
      _tokenUrl,
      data: {
        'grant_type': 'refresh_token',
        'refresh_token': _refreshToken,
      },
    );

    _accessToken = response.data['access_token'];
    _refreshToken = response.data['refresh_token'];
  }

  Interceptor createAuthInterceptor() {
    return _TokenRefreshInterceptor(this);
  }
}

class _TokenRefreshInterceptor extends Interceptor {
  _TokenRefreshInterceptor(this._tokenService);

  final TokenRefreshService _tokenService;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_tokenService.accessToken != null) {
      options.headers['Authorization'] = 'Bearer ${_tokenService.accessToken}';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && _tokenService.refreshToken != null) {
      try {
        // Try to refresh token
        await _tokenService._refreshAccessToken();
        // Retry the original request
        final response = await Dio().request(
          err.requestOptions.path,
          options: Options(
            method: err.requestOptions.method,
            headers: err.requestOptions.headers,
          ).compose(
            err.requestOptions.extra['dio'] as BaseOptions?,
            err.requestOptions.path,
            data: err.requestOptions.data,
            queryParameters: err.requestOptions.queryParameters,
          ),
        );
        handler.resolve(response);
      } catch (e) {
        handler.reject(err);
      }
    } else {
      handler.reject(err);
    }
  }
}
```

### Multiple Authentication Methods

```dart
class MultiAuthService {
  MultiAuthService(this._authHeaders);

  final Map<String, String> _authHeaders;
  Map<String, String> get authHeaders => _authHeaders;

  Interceptor createAuthInterceptor() {
    return _MultiAuthInterceptor(this);
  }
}

class _MultiAuthInterceptor extends Interceptor {
  _MultiAuthInterceptor(this._authService);

  final MultiAuthService _authService;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Add all authentication headers
    options.headers.addAll(_authService.authHeaders);
    handler.next(options);
  }
}

// Setup for multiple auth methods
final multiAuthService = MultiAuthService({
  'Authorization': 'Bearer your-jwt-token',
  'X-API-Key': 'your-api-key',
  'X-Client-ID': 'your-client-id',
});

final serverConfig = ServerConfig(
  interceptors: [multiAuthService.createAuthInterceptor()],
);

final server = YourServer(serverConfig: serverConfig);
final apiClient = YourApiClient(server);
```

## Security Scheme Documentation

While Tonik doesn't generate authentication code, it does parse and expose security scheme information from the OpenAPI specification. This information can be found in:

- `ApiDocument.securitySchemes` - Available security schemes
- Operation-level security requirements in `Operation.security`

You can use this information to:

1. **Generate documentation** about required authentication
2. **Configure interceptors** based on operation requirements
3. **Create authentication setup guides** for your API

## Best Practices

1. **Create dedicated authentication services** that provide interceptor factories
2. **Configure authentication through ServerConfig** interceptors
3. **Keep authentication logic completely separate** from generated API client code
4. **Handle token refresh** gracefully with retry logic in your service classes
5. **Consider security scheme information** from the OpenAPI spec for documentation
6. **Test authentication flows** thoroughly with mocked services

