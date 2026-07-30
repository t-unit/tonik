import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/server/server_generator.dart';
import 'package:tonik_generate/src/transport/dio_backend_generator.dart';
import 'package:tonik_generate/src/transport/http_backend_generator.dart';

void main() {
  late ServerGenerator generator;
  late NameManager nameManager;
  late DartEmitter emitter;
  late List<Server> testServers;
  late List<Class> generatedClasses;
  late Class dioAdapter;
  late Class baseClass;

  final format = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  ).format;

  setUp(() {
    nameManager = NameManager(
      generator: NameGenerator(),
      stableModelSorter: StableModelSorter(),
    );
    generator = ServerGenerator(
      nameManager: nameManager,
      backendGenerator: const DioBackendGenerator(),
    );
    emitter = DartEmitter(useNullSafetySyntax: true);

    testServers = [
      const Server(
        url: 'https://production.example.com',
        description: 'Production server',
      ),
      const Server(
        url: 'https://staging.example.com',
        description: 'Staging server',
      ),
    ];

    generatedClasses = generator.generateClasses(testServers);
    dioAdapter = generator.generateClientAdapter();
    baseClass = generatedClasses.first;
  });

  group('ServerGenerator Dio adapter', () {
    test('generates a private adapter in the server library', () {
      expect(dioAdapter.name, '_DioClientAdapter');

      final baseUrlField = dioAdapter.fields.firstWhere(
        (f) => f.name == 'baseUrl',
      );
      expect(baseUrlField.type?.accept(emitter).toString(), 'String');
      expect(baseUrlField.modifier, FieldModifier.final$);

      final serverConfigField = dioAdapter.fields.firstWhere(
        (f) => f.name == 'serverConfig',
      );
      expect(
        serverConfigField.type?.accept(emitter).toString(),
        'ServerConfig<Dio>',
      );
      expect(serverConfigField.modifier, FieldModifier.final$);

      final dioField = dioAdapter.fields.firstWhere(
        (f) => f.name == r'_$dio',
      );
      expect(dioField.type?.accept(emitter).toString(), 'Dio?');
    });

    test('generates lazy, cached resolution', () {
      final dioGetter = dioAdapter.methods.firstWhere((m) => m.name == 'dio');

      const expectedBody = r'''
        if (_$isClosed) {
          throw _$closedError;
        }

        final cachedDio = _$dio;
        if (cachedDio != null) {
          return cachedDio;
        }

        final client = serverConfig.client;
        final clientFactory = serverConfig.clientFactory;

        final resolvedDio = client ?? clientFactory?.call() ?? Dio() ;
        _$ownsDio = client == null;
        resolvedDio.options.baseUrl = baseUrl;
        return _$dio = resolvedDio;
      ''';

      expect(
        collapseWhitespace(dioGetter.body!.accept(emitter).toString()),
        collapseWhitespace(expectedBody),
      );
    });
  });

  group('ServerGenerator base class', () {
    test('generates sealed abstract class', () {
      expect(baseClass.sealed, isTrue);
      expect(baseClass.abstract, isTrue);
    });

    test('generates required fields', () {
      final fields = baseClass.fields;
      expect(fields.length, 3);

      final baseUrlField = fields.firstWhere((f) => f.name == 'baseUrl');
      expect(baseUrlField.type?.accept(emitter).toString(), 'String');
      expect(baseUrlField.modifier, FieldModifier.final$);

      final serverConfigField = fields.firstWhere(
        (f) => f.name == 'serverConfig',
      );
      expect(
        serverConfigField.type?.accept(emitter).toString(),
        'ServerConfig<Dio>',
      );
      expect(serverConfigField.modifier, FieldModifier.final$);

      final adapterField = fields.firstWhere(
        (f) => f.name == r'_$dioAdapter',
      );
      expect(
        adapterField.type?.accept(emitter).toString(),
        '_DioClientAdapter',
      );
      expect(adapterField.modifier, FieldModifier.final$);
    });

    test('generates constructor with named parameters', () {
      final constructor = baseClass.constructors.first;
      expect(constructor.constant, isFalse);
      expect(constructor.optionalParameters.length, 2);

      final baseUrlParam = constructor.optionalParameters.first;
      expect(baseUrlParam.name, 'baseUrl');
      expect(baseUrlParam.named, isTrue);
      expect(baseUrlParam.required, isTrue);
      expect(baseUrlParam.toThis, isTrue);

      final serverConfigParam = constructor.optionalParameters.last;
      expect(serverConfigParam.name, 'serverConfig');
      expect(serverConfigParam.named, isTrue);
      expect(serverConfigParam.required, isTrue);
      expect(serverConfigParam.toThis, isTrue);
    });

    test('generates dio getter with lazy initialization', () {
      final dioGetter = baseClass.methods.firstWhere((m) => m.name == 'dio');
      expect(dioGetter.type, MethodType.getter);
      expect(dioGetter.returns?.accept(emitter).toString(), 'Dio');
      expect(dioGetter.lambda, isTrue);

      final bodyCode = dioGetter.body!.accept(emitter).toString();
      expect(
        collapseWhitespace(bodyCode),
        collapseWhitespace(r'_$dioAdapter.dio'),
      );
    });

    test('generates idempotent adapter-backed close', () {
      final close = baseClass.methods.firstWhere((m) => m.name == 'close');

      expect(close.returns?.accept(emitter).toString(), 'void');
      expect(close.lambda, isTrue);
      expect(
        collapseWhitespace(close.body!.accept(emitter).toString()),
        collapseWhitespace(r'_$dioAdapter.close()'),
      );
    });
  });

  group('ServerGenerator server classes', () {
    test('generates subclass for each server', () {
      // Skip the first class (base class) and the last class (custom class)
      final serverClasses = generatedClasses.sublist(
        1,
        generatedClasses.length - 1,
      );
      expect(serverClasses.length, 2);
    });

    test('generates production server subclass correctly', () {
      final productionClass = generatedClasses[1];

      expect(productionClass.name, 'ProductionServer');
      expect(productionClass.extend?.accept(emitter).toString(), 'Server');
      expect(
        productionClass.docs.first,
        '/// Production server - https://production.example.com',
      );
    });

    test('generates production server constructor correctly', () {
      final productionClass = generatedClasses[1];
      final productionConstructor = productionClass.constructors.first;

      // Constructor should not be const since base class
      // constructor isn't const
      expect(productionConstructor.constant, isFalse);
      expect(productionConstructor.optionalParameters.length, 1);

      final serverConfigParam = productionConstructor.optionalParameters.first;
      expect(serverConfigParam.name, 'serverConfig');
      expect(serverConfigParam.named, isTrue);
      // Super parameters shouldn't have type annotations
      expect(serverConfigParam.type, isNull);
      expect(serverConfigParam.toSuper, isTrue);

      final initializer = productionConstructor.initializers.first;
      expect(
        initializer.accept(emitter).toString(),
        "super(baseUrl: r'https://production.example.com')",
      );
    });

    test('generates staging server subclass correctly', () {
      final stagingClass = generatedClasses[2];

      expect(stagingClass.name, 'StagingServer');
      expect(stagingClass.extend?.accept(emitter).toString(), 'Server');
      expect(
        stagingClass.docs.first,
        '/// Staging server - https://staging.example.com',
      );
    });

    test('generates staging server constructor correctly', () {
      final stagingClass = generatedClasses[2];
      final stagingConstructor = stagingClass.constructors.first;

      // Constructor should not be const since base class constructor
      // isn't const
      expect(stagingConstructor.constant, isFalse);
      expect(stagingConstructor.optionalParameters.length, 1);

      final serverConfigParam = stagingConstructor.optionalParameters.first;
      expect(serverConfigParam.name, 'serverConfig');
      expect(serverConfigParam.named, isTrue);
      // Super parameters shouldn't have type annotations
      expect(serverConfigParam.type, isNull);
      expect(serverConfigParam.toSuper, isTrue);

      final initializer = stagingConstructor.initializers.first;
      expect(
        initializer.accept(emitter).toString(),
        "super(baseUrl: r'https://staging.example.com')",
      );
    });
  });

  group('ServerGenerator custom server class', () {
    test('generates custom server subclass correctly', () {
      final customClass = generatedClasses.last;

      expect(customClass.name, 'CustomServer');
      expect(customClass.extend?.accept(emitter).toString(), 'Server');
      expect(
        customClass.docs.first,
        '/// Custom server with user-defined base URL',
      );
    });

    test('generates custom server constructor with required baseUrl', () {
      final customClass = generatedClasses.last;
      final customConstructor = customClass.constructors.first;

      // Constructor should not be const since base class constructor
      // isn't const
      expect(customConstructor.constant, isFalse);
      expect(customConstructor.optionalParameters.length, 2);

      final baseUrlParam = customConstructor.optionalParameters.first;
      expect(baseUrlParam.name, 'baseUrl');
      expect(baseUrlParam.named, isTrue);
      expect(baseUrlParam.required, isTrue);
      // Super parameters shouldn't have type annotations
      expect(baseUrlParam.type, isNull);
      expect(baseUrlParam.toSuper, isTrue);

      final serverConfigParam = customConstructor.optionalParameters.last;
      expect(serverConfigParam.name, 'serverConfig');
      expect(serverConfigParam.named, isTrue);
      // Super parameters shouldn't have type annotations
      expect(serverConfigParam.type, isNull);
      expect(serverConfigParam.toSuper, isTrue);

      // Custom constructor doesn't have initializers with super parameters
      expect(customConstructor.initializers, isEmpty);
    });
  });

  group('ServerGenerator name management', () {
    test('uses names from NameManager', () {
      final names = nameManager.serverNames(testServers);

      expect(generatedClasses[0].name, names.baseName);

      var index = 1;
      for (final entry in names.serverMap.entries) {
        expect(generatedClasses[index++].name, entry.value);
      }

      expect(generatedClasses.last.name, names.customName);
    });
  });

  group('ServerGenerator multi-line descriptions', () {
    test(
      'static server with multi-line description has proper doc comments',
      () {
        final servers = [
          const Server(
            url: 'https://api.example.com',
            description: "Production server.\nThe main server's endpoint.",
          ),
        ];

        final classes = generator.generateClasses(servers);
        final serverClass = classes[1]; // first server class after base

        expect(serverClass.docs, [
          '/// Production server.',
          "/// The main server's endpoint. - https://api.example.com",
        ]);
      },
    );

    test(
      'templated server with multi-line description has proper doc comments',
      () {
        final servers = [
          const Server(
            url: 'https://{env}.example.com',
            description: "Environment server.\nThe server's URL varies.",
            variables: [
              ServerVariable(
                name: 'env',
                defaultValue: 'prod',
                description: 'Environment',
              ),
            ],
          ),
        ];

        final classes = generator.generateClasses(servers);
        final serverClass = classes[1];

        expect(serverClass.docs, [
          '/// Environment server.',
          "/// The server's URL varies. - https://{env}.example.com",
        ]);
      },
    );

    test('multi-line server description does not crash DartFormatter', () {
      final servers = [
        const Server(
          url: 'https://api.example.com',
          description: "Production server.\nThe main server's endpoint.",
        ),
      ];

      expect(() => generator.generate(servers), returnsNormally);
    });
  });

  group('ServerGenerator output', () {
    test('generates the complete server library', () {
      final result = generator.generate(testServers);

      expect(result.filename, 'server.dart');

      const expectedCode = r'''
        // Generated code - do not modify by hand

        // ignore_for_file: no_leading_underscores_for_library_prefixes
        import 'dart:core' as _i1;

        import 'package:dio/dio.dart' as _i3;
        import 'package:tonik_util/tonik_util.dart' as _i2;

        class _DioClientAdapter {
          _DioClientAdapter(this.baseUrl, this.serverConfig);

          final _i1.String baseUrl;

          final _i2.ServerConfig<_i3.Dio> serverConfig;

          _i3.Dio? _$dio;

          _i1.bool _$ownsDio = false;

          _i1.bool _$isClosed = false;

          final _i1.StateError _$closedError = _i1.StateError(
            'Cannot access Dio after the server has been closed.',
          );

          _i3.Dio get dio {
            if (_$isClosed) {
              throw _$closedError;
            }

            final cachedDio = _$dio;
            if (cachedDio != null) {
              return cachedDio;
            }

            final client = serverConfig.client;
            final clientFactory = serverConfig.clientFactory;
            final resolvedDio =
                client ?? clientFactory?.call() ?? _i3.Dio();
            _$ownsDio = client == null;
            resolvedDio.options.baseUrl = baseUrl;
            return _$dio = resolvedDio;
          }

          void close() {
            if (_$isClosed) {
              return;
            }

            _$isClosed = true;
            if (_$ownsDio) {
              _$dio?.close();
            }
          }
        }

        sealed class Server {
          Server({required this.baseUrl, required this.serverConfig})
            : _$dioAdapter = _DioClientAdapter(baseUrl, serverConfig);

          final _i1.String baseUrl;

          final _i2.ServerConfig<_i3.Dio> serverConfig;

          final _DioClientAdapter _$dioAdapter;

          _i3.Dio get dio => _$dioAdapter.dio;

          void close() => _$dioAdapter.close();
        }

        /// Production server - https://production.example.com
        class ProductionServer extends Server {
          ProductionServer({
            super.serverConfig = const _i2.ServerConfig<_i3.Dio>(),
          }) : super(baseUrl: r'https://production.example.com');
        }

        /// Staging server - https://staging.example.com
        class StagingServer extends Server {
          StagingServer({
            super.serverConfig = const _i2.ServerConfig<_i3.Dio>(),
          }) : super(baseUrl: r'https://staging.example.com');
        }

        /// Custom server with user-defined base URL
        class CustomServer extends Server {
          CustomServer({
            required super.baseUrl,
            super.serverConfig = const _i2.ServerConfig<_i3.Dio>(),
          });
        }
      ''';

      expect(
        collapseWhitespace(format(result.code)),
        collapseWhitespace(format(expectedCode)),
      );
    });

    test('generates the complete http lifecycle server library', () {
      final httpNameManager = NameManager(
        generator: NameGenerator(),
        stableModelSorter: StableModelSorter(),
      );
      final httpGenerator = ServerGenerator(
        nameManager: httpNameManager,
        backendGenerator: const HttpBackendGenerator(),
      );
      final result = httpGenerator.generate(const []);

      expect(result.filename, 'server.dart');

      const expectedCode = r'''
        // Generated code - do not modify by hand

        // ignore_for_file: no_leading_underscores_for_library_prefixes
        import 'dart:core' as _i3;

        import 'package:http/http.dart' as _i2;
        import 'package:tonik_util/tonik_util.dart' as _i1;

        class _HttpClientAdapter {
          _HttpClientAdapter(this.serverConfig);

          final _i1.ServerConfig<_i2.Client> serverConfig;

          _i2.Client? _$client;

          _i3.bool _$ownsClient = false;

          _i3.bool _$isClosed = false;

          final _i3.StateError _$closedError = _i3.StateError(
            'Cannot access the HTTP client after the server has been closed.',
          );

          _i2.Client get client {
            if (_$isClosed) {
              throw _$closedError;
            }

            final cachedClient = _$client;
            if (cachedClient != null) {
              return cachedClient;
            }

            final configuredClient = serverConfig.client;
            final resolvedClient =
                configuredClient ??
                serverConfig.clientFactory?.call() ??
                _i2.Client();
            _$ownsClient = configuredClient == null;
            return _$client = resolvedClient;
          }

          void close() {
            if (_$isClosed) {
              return;
            }

            _$isClosed = true;
            if (_$ownsClient) {
              _$client?.close();
            }
          }
        }

        sealed class Server {
          Server({required this.baseUrl, required this.serverConfig})
            : _$httpClientAdapter = _HttpClientAdapter(serverConfig);

          final _i3.String baseUrl;

          final _i1.ServerConfig<_i2.Client> serverConfig;

          final _HttpClientAdapter _$httpClientAdapter;

          _i2.Client get client => _$httpClientAdapter.client;

          void close() => _$httpClientAdapter.close();
        }

        /// Custom server with user-defined base URL
        class CustomServer extends Server {
          CustomServer({
            required super.baseUrl,
            super.serverConfig = const _i1.ServerConfig<_i2.Client>(),
          });
        }
      ''';

      expect(
        collapseWhitespace(format(result.code)),
        collapseWhitespace(format(expectedCode)),
      );
    });
  });

  group('special characters in server URL', () {
    test(
      'generates valid code when static server URL contains single quote',
      () {
        final servers = [
          const Server(
            url: "https://it's-a-server.example.com",
            description: 'Test server',
          ),
        ];

        expect(() => generator.generate(servers), returnsNormally);
      },
    );

    test(
      'generates valid code when templated server URL contains single quote',
      () {
        final servers = [
          const Server(
            url: "https://it's-a-{env}.example.com",
            description: 'Templated server',
            variables: [
              ServerVariable(
                name: 'env',
                defaultValue: 'prod',
                description: 'Environment',
              ),
            ],
          ),
        ];

        expect(() => generator.generate(servers), returnsNormally);
      },
    );
  });
}
