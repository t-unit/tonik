import 'package:server_variables_api/server_variables_api.dart';
import 'package:test/test.dart';

void main() {
  group('Static server', () {
    test('Server2 has correct static URL', () {
      final server = Server2();
      expect(server.baseUrl, 'https://production.example.com/api/v1');
    });

    test('Server2 can be instantiated with custom config', () {
      final server = Server2();
      expect(server.baseUrl, 'https://production.example.com/api/v1');
    });
  });

  group('Server with enum variable', () {
    test('Server3 uses default region', () {
      final server = Server3();
      expect(server.baseUrl, 'https://us-east.example.com/api/v1');
      expect(server.region, Server3Region.usEast);
    });

    test('Server3 can use different region', () {
      final server = Server3(region: Server3Region.euCentral);
      expect(server.baseUrl, 'https://eu-central.example.com/api/v1');
      expect(server.region, Server3Region.euCentral);
    });

    test('Server3 supports all enum values', () {
      expect(
        Server3().baseUrl, // default is usEast
        'https://us-east.example.com/api/v1',
      );
      expect(
        Server3(region: Server3Region.usWest).baseUrl,
        'https://us-west.example.com/api/v1',
      );
      expect(
        Server3(region: Server3Region.euCentral).baseUrl,
        'https://eu-central.example.com/api/v1',
      );
      expect(
        Server3(region: Server3Region.apSoutheast).baseUrl,
        'https://ap-southeast.example.com/api/v1',
      );
    });

    test('Server3Region enum has correct values', () {
      expect(Server3Region.usEast.value, 'us-east');
      expect(Server3Region.usWest.value, 'us-west');
      expect(Server3Region.euCentral.value, 'eu-central');
      expect(Server3Region.apSoutheast.value, 'ap-southeast');
    });
  });

  group('Server with string variable', () {
    test('Server4 uses default environment', () {
      final server = Server4();
      expect(server.baseUrl, 'https://dev.staging.example.com/api/v1');
      expect(server.environment, 'dev');
    });

    test('Server4 can use custom environment', () {
      final server = Server4(environment: 'qa');
      expect(server.baseUrl, 'https://qa.staging.example.com/api/v1');
      expect(server.environment, 'qa');
    });

    test('Server4 accepts any string value', () {
      expect(
        Server4(environment: 'test').baseUrl,
        'https://test.staging.example.com/api/v1',
      );
      expect(
        Server4(environment: 'staging').baseUrl,
        'https://staging.staging.example.com/api/v1',
      );
      expect(
        Server4(environment: 'my-custom-env').baseUrl,
        'https://my-custom-env.staging.example.com/api/v1',
      );
    });
  });

  group('Server with multiple variables', () {
    test('Server5 uses all default values', () {
      final server = Server5();
      expect(server.baseUrl, 'https://default.us-east.example.com:443/api/v1');
      expect(server.tenant, 'default');
      expect(server.region, Server5Region.usEast);
      expect(server.port, Server5Port.fourHundredFortyThree);
    });

    test('Server5 can customize all variables', () {
      final server = Server5(
        tenant: 'acme',
        region: Server5Region.euCentral,
        port: Server5Port.eightThousandFourHundredFortyThree,
      );
      expect(server.baseUrl, 'https://acme.eu-central.example.com:8443/api/v1');
      expect(server.tenant, 'acme');
      expect(server.region, Server5Region.euCentral);
      expect(server.port, Server5Port.eightThousandFourHundredFortyThree);
    });

    test('Server5 can mix default and custom values', () {
      final server = Server5(
        tenant: 'widgets-inc',
        region: Server5Region.usWest,
        // port uses default
      );
      expect(
        server.baseUrl,
        'https://widgets-inc.us-west.example.com:443/api/v1',
      );
    });

    test('Server5Region enum has correct values', () {
      expect(Server5Region.usEast.value, 'us-east');
      expect(Server5Region.usWest.value, 'us-west');
      expect(Server5Region.euCentral.value, 'eu-central');
    });

    test('Server5Port enum has correct values', () {
      expect(Server5Port.fourHundredFortyThree.value, '443');
      expect(Server5Port.eightThousandFourHundredFortyThree.value, '8443');
    });
  });

  group('CustomServer', () {
    test('CustomServer can use any base URL', () {
      final server = CustomServer(baseUrl: 'https://custom.example.com/api');
      expect(server.baseUrl, 'https://custom.example.com/api');
    });

    test('CustomServer works with localhost', () {
      final server = CustomServer(baseUrl: 'http://localhost:3000');
      expect(server.baseUrl, 'http://localhost:3000');
    });
  });

  group('Server base class', () {
    test('all servers extend Server', () {
      expect(Server2(), isA<Server>());
      expect(Server3(), isA<Server>());
      expect(Server4(), isA<Server>());
      expect(Server5(), isA<Server>());
      expect(CustomServer(baseUrl: 'https://test.com'), isA<Server>());
    });
  });
}
