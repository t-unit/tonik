import 'package:change_case/change_case.dart';
import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/server/server_generator.dart';

void main() {
  late ServerGenerator generator;
  late NameManager nameManager;
  late DartEmitter emitter;
  late List<Server> testServers;
  late List<Class> generatedClasses;
  late Class baseClass;

  setUp(() {
    nameManager = NameManager(generator: NameGenerator());
    generator = ServerGenerator(nameManager: nameManager);
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
    baseClass = generatedClasses.first;
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
        'ServerConfig',
      );
      expect(serverConfigField.modifier, FieldModifier.final$);

      final dioField = fields.firstWhere((f) => f.name == '_dio');
      expect(dioField.type?.accept(emitter).toString(), 'Dio?');
      // _dio should not be final because it needs to be initialized lazily
      expect(dioField.modifier, isNot(FieldModifier.final$));
    });

    test('generates constructor with named parameters', () {
      final constructor = baseClass.constructors.first;
      // Constructor should not be const since _dio is not final
      // and initialized later
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

      // Test getter body content
      final bodyCode = dioGetter.body!.accept(emitter).toString();
      expect(bodyCode, contains('if (_dio == null)'));
      expect(bodyCode, contains('serverConfig.configureDio'));
      expect(bodyCode, contains('return _dio!'));
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
        "super(baseUrl: 'https://production.example.com')",
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
        "super(baseUrl: 'https://staging.example.com')",
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
      // Get the expected names
      final names = nameManager.serverNames(testServers);

      // Test base class name matches naming from NameManager
      expect(generatedClasses[0].name, names.baseName);

      // Test server class names match naming from NameManager
      var index = 1;
      for (final entry in names.serverMap.entries) {
        expect(generatedClasses[index++].name, entry.value);
      }

      // Test custom server name matches naming from NameManager
      expect(generatedClasses.last.name, names.customName);
    });
  });

  group('ServerGenerator output', () {
    test('generates file with correct structure', () {
      final result = generator.generate(testServers);

      // Test filename is generated correctly
      final names = nameManager.serverNames(testServers);
      expect(result.filename, '${names.baseName.toSnakeCase()}.dart');

      // Test for header
      expect(
        result.code,
        contains('// Generated code - do not modify by hand'),
      );
      expect(result.code, contains('// ignore_for_file:'));

      // Test imports are included
      expect(result.code, contains("import 'package:dio/dio.dart'"));
      expect(
        result.code,
        contains("import 'package:tonik_util/tonik_util.dart'"),
      );
    });
  });
}
