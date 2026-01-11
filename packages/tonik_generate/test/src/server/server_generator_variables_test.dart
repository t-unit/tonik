import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/server/server_generator.dart';

void main() {
  late ServerGenerator generator;
  late NameManager nameManager;
  late DartEmitter emitter;

  final format = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  ).format;

  setUp(() {
    nameManager = NameManager(generator: NameGenerator());
    generator = ServerGenerator(nameManager: nameManager);
    emitter = DartEmitter(useNullSafetySyntax: true);
  });

  group('ServerGenerator templated URLs with enum variables', () {
    late List<Server> servers;
    late List<Class> classes;
    late List<Enum> enums;
    late Class serverClass;
    late Enum regionEnum;

    setUp(() {
      servers = [
        const Server(
          url: 'https://regional.example.com/{region}',
          description: 'Regional server',
          variables: [
            ServerVariable(
              name: 'region',
              defaultValue: 'us-east',
              enumValues: ['us-east', 'us-west', 'eu-central'],
            ),
          ],
        ),
      ];

      classes = generator.generateClasses(servers);
      enums = generator.generateEnums(servers);
      serverClass = classes[1];
      regionEnum = enums.first;
    });

    test('generates enum for constrained variable', () {
      expect(enums, hasLength(1));
      expect(regionEnum.name, 'RegionalServerRegion');
    });

    test('generates enum with value field and const constructor', () {
      final valueField = regionEnum.fields.firstWhere(
        (f) => f.name == 'value',
      );
      expect(valueField.type?.accept(emitter).toString(), 'String');
      expect(valueField.modifier, FieldModifier.final$);

      final enumConstructor = regionEnum.constructors.first;
      expect(enumConstructor.constant, isTrue);
      expect(enumConstructor.requiredParameters.first.name, 'value');
      expect(enumConstructor.requiredParameters.first.toThis, isTrue);
    });

    test('generates enum values with normalized names', () {
      final valueNames = regionEnum.values.map((v) => v.name).toList();
      expect(valueNames, ['usEast', 'usWest', 'euCentral']);
    });

    test('generates enum values with raw value arguments', () {
      final usEast = regionEnum.values.firstWhere((v) => v.name == 'usEast');
      expect(usEast.arguments.first.accept(emitter).toString(), "'us-east'");
    });

    test('generates complete enum', () {
      const expectedEnum = '''
        /// Allowed values for the region variable.
        enum RegionalServerRegion {
          usEast('us-east'),
          usWest('us-west'),
          euCentral('eu-central');

          const RegionalServerRegion(this.value);
          final String value;
        }
      ''';

      expect(
        collapseWhitespace(format(regionEnum.accept(emitter).toString())),
        collapseWhitespace(format(expectedEnum)),
      );
    });

    test('generates server class with variable field', () {
      final regionField = serverClass.fields.firstWhere(
        (f) => f.name == 'region',
      );
      expect(
        regionField.type?.accept(emitter).toString(),
        'RegionalServerRegion',
      );
      expect(regionField.modifier, FieldModifier.final$);
    });

    test('generates constructor with enum parameter', () {
      final constructor = serverClass.constructors.first;
      final regionParam = constructor.optionalParameters.firstWhere(
        (p) => p.name == 'region',
      );
      expect(regionParam.toThis, isTrue);
      expect(regionParam.named, isTrue);
      expect(
        regionParam.defaultTo?.accept(emitter).toString(),
        'RegionalServerRegion.usEast',
      );
    });

    test('generates constructor with URL using enum value', () {
      final constructor = serverClass.constructors.first;
      final initCode = constructor.initializers.first
          .accept(emitter)
          .toString();
      expect(
        initCode,
        r"super(baseUrl: 'https://regional.example.com/${region.value}')",
      );
    });

    test('generates complete templated server class with enum', () {
      const expectedClass = r'''
        /// Regional server - https://regional.example.com/{region}
        class RegionalServer extends Server {
          RegionalServer({
            this.region = RegionalServerRegion.usEast,
            super.serverConfig = const ServerConfig(),
          }) : super(
            baseUrl: 'https://regional.example.com/${region.value}',
          );

          final RegionalServerRegion region;
        }
      ''';

      expect(
        collapseWhitespace(format(serverClass.accept(emitter).toString())),
        collapseWhitespace(format(expectedClass)),
      );
    });
  });

  group('ServerGenerator templated URLs with string variables', () {
    late List<Server> servers;
    late List<Class> classes;
    late Class serverClass;

    setUp(() {
      servers = [
        const Server(
          url: 'https://environment.example.com/{env}',
          description: 'Environment server',
          variables: [ServerVariable(name: 'env', defaultValue: 'prod')],
        ),
      ];

      classes = generator.generateClasses(servers);
      serverClass = classes[1];
    });

    test('does not generate enum for unconstrained variable', () {
      final enums = generator.generateEnums(servers);
      expect(enums, isEmpty);
    });

    test('generates server class with String field', () {
      final envField = serverClass.fields.firstWhere((f) => f.name == 'env');
      expect(envField.type?.accept(emitter).toString(), 'String');
      expect(envField.modifier, FieldModifier.final$);
    });

    test('generates constructor with String parameter', () {
      final constructor = serverClass.constructors.first;
      final envParam = constructor.optionalParameters.firstWhere(
        (p) => p.name == 'env',
      );
      expect(envParam.toThis, isTrue);
      expect(envParam.named, isTrue);
      expect(envParam.defaultTo?.accept(emitter).toString(), "'prod'");
    });

    test('generates constructor with URL using string interpolation', () {
      final constructor = serverClass.constructors.first;
      final initCode = constructor.initializers.first
          .accept(emitter)
          .toString();
      expect(
        initCode,
        r"super(baseUrl: 'https://environment.example.com/${env}')",
      );
    });

    test('generates complete templated server class with string variable', () {
      const expectedClass = r'''
        /// Environment server - https://environment.example.com/{env}
        class EnvironmentServer extends Server {
          EnvironmentServer({
            this.env = 'prod',
            super.serverConfig = const ServerConfig(),
          }) : super(baseUrl: 'https://environment.example.com/${env}');

          final String env;
        }
      ''';

      expect(
        collapseWhitespace(format(serverClass.accept(emitter).toString())),
        collapseWhitespace(format(expectedClass)),
      );
    });
  });

  group('ServerGenerator with multiple variables', () {
    late List<Server> servers;
    late List<Class> classes;
    late List<Enum> enums;
    late Class serverClass;

    setUp(() {
      servers = [
        const Server(
          url: 'https://configurable.example.com/{host}:{port}/api',
          description: 'Configurable server',
          variables: [
            ServerVariable(name: 'host', defaultValue: 'localhost'),
            ServerVariable(
              name: 'port',
              defaultValue: '8080',
              enumValues: ['8080', '8443'],
            ),
          ],
        ),
      ];

      classes = generator.generateClasses(servers);
      enums = generator.generateEnums(servers);
      serverClass = classes[1];
    });

    test('generates enum only for constrained variable', () {
      expect(enums, hasLength(1));
      expect(enums.first.name, 'ConfigurableServerPort');
    });

    test('generates enum with numeric values converted to words', () {
      final portEnum = enums.first;
      final valueNames = portEnum.values.map((v) => v.name).toList();
      expect(
        valueNames,
        ['eightThousandEighty', 'eightThousandFourHundredFortyThree'],
      );
    });

    test('generates fields for both variables', () {
      final hostField = serverClass.fields.firstWhere((f) => f.name == 'host');
      expect(hostField.type?.accept(emitter).toString(), 'String');
      expect(hostField.modifier, FieldModifier.final$);

      final portField = serverClass.fields.firstWhere((f) => f.name == 'port');
      expect(
        portField.type?.accept(emitter).toString(),
        'ConfigurableServerPort',
      );
      expect(portField.modifier, FieldModifier.final$);
    });

    test('generates constructor with mixed parameter types', () {
      final constructor = serverClass.constructors.first;

      final hostParam = constructor.optionalParameters.firstWhere(
        (p) => p.name == 'host',
      );
      expect(hostParam.toThis, isTrue);
      expect(hostParam.defaultTo?.accept(emitter).toString(), "'localhost'");

      final portParam = constructor.optionalParameters.firstWhere(
        (p) => p.name == 'port',
      );
      expect(portParam.toThis, isTrue);
      expect(
        portParam.defaultTo?.accept(emitter).toString(),
        'ConfigurableServerPort.eightThousandEighty',
      );
    });

    test('generates URL with mixed interpolation', () {
      final constructor = serverClass.constructors.first;
      final initCode = constructor.initializers.first
          .accept(emitter)
          .toString();
      expect(
        initCode,
        r"super(baseUrl: 'https://configurable.example.com/${host}:${port.value}/api')",
      );
    });

    test('generates complete server class with multiple variables', () {
      const expectedClass = r'''
        /// Configurable server - https://configurable.example.com/{host}:{port}/api
        class ConfigurableServer extends Server {
          ConfigurableServer({
            this.host = 'localhost',
            this.port = ConfigurableServerPort.eightThousandEighty,
            super.serverConfig = const ServerConfig(),
          }) : super(
            baseUrl: 'https://configurable.example.com/${host}:${port.value}/api',
          );

          final String host;
          final ConfigurableServerPort port;
        }
      ''';

      expect(
        collapseWhitespace(format(serverClass.accept(emitter).toString())),
        collapseWhitespace(format(expectedClass)),
      );
    });
  });

  group('ServerGenerator mixed templated and static servers', () {
    late List<Server> servers;
    late List<Class> classes;

    setUp(() {
      servers = [
        const Server(
          url: 'https://production.example.com',
          description: 'Production',
        ),
        const Server(
          url: 'https://dynamic.example.com/{env}',
          description: 'Dynamic',
          variables: [
            ServerVariable(name: 'env', defaultValue: 'staging'),
          ],
        ),
      ];

      classes = generator.generateClasses(servers);
    });

    test('generates static server without variable fields', () {
      final productionClass = classes[1];
      // Static server should have no fields (variables).
      expect(productionClass.fields, isEmpty);
    });

    test('generates templated server with variable field', () {
      final dynamicClass = classes[2];
      expect(dynamicClass.fields, hasLength(1));
      expect(dynamicClass.fields.first.name, 'env');
    });

    test('generates static server constructor without variable params', () {
      final productionClass = classes[1];
      final constructor = productionClass.constructors.first;
      final paramNames = constructor.optionalParameters
          .map((p) => p.name)
          .toList();
      expect(paramNames, ['serverConfig']);
    });

    test('generates templated server constructor with variable params', () {
      final dynamicClass = classes[2];
      final constructor = dynamicClass.constructors.first;
      final paramNames = constructor.optionalParameters
          .map((p) => p.name)
          .toList();
      expect(paramNames, ['env', 'serverConfig']);
    });
  });

  group('ServerGenerator full output', () {
    test('generates file with enum and templated server class', () {
      final servers = [
        const Server(
          url: 'https://regional.example.com/{region}:{port}',
          description: 'Regional server',
          variables: [
            ServerVariable(
              name: 'region',
              defaultValue: 'us-east',
              enumValues: ['us-east', 'us-west', 'eu-central'],
            ),
            ServerVariable(name: 'port', defaultValue: '443'),
          ],
        ),
      ];

      final result = generator.generate(servers);

      // Verify file structure.
      expect(
        result.code,
        contains('// Generated code - do not modify by hand'),
      );
      expect(result.code, contains("import 'package:dio/dio.dart'"));
      expect(
        result.code,
        contains("import 'package:tonik_util/tonik_util.dart'"),
      );

      // Verify enum declaration is present.
      expect(result.code, contains('enum RegionalServerRegion'));
      expect(result.code, contains("usEast('us-east')"));
      expect(result.code, contains("usWest('us-west')"));
      expect(result.code, contains("euCentral('eu-central')"));
      expect(result.code, contains('const RegionalServerRegion(this.value)'));

      // Verify server class declaration is present.
      expect(result.code, contains('class RegionalServer extends Server'));
      expect(
        result.code,
        contains('this.region = RegionalServerRegion.usEast'),
      );
      expect(result.code, contains("this.port = '443'"));
      expect(result.code, contains('final RegionalServerRegion region'));

      // Verify URL interpolation.
      expect(
        result.code,
        contains(r'https://regional.example.com/${region.value}:${port}'),
      );
    });
  });
}
