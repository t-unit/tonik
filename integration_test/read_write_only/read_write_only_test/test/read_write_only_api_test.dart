import 'package:dio/dio.dart';
import 'package:read_write_only_api/read_write_only_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  late ImposterServer imposterServer;
  late String baseUrl;

  setUpAll(() async {
    imposterServer = await setupImposterServer();
    baseUrl = 'http://localhost:${imposterServer.port}';
  });

  ReadWriteOnlyApi buildApi({required String responseStatus}) {
    return ReadWriteOnlyApi(
      CustomServer(
        baseUrl: baseUrl,
        serverConfig: ServerConfig(
          baseOptions: BaseOptions(
            headers: {'X-Response-Status': responseStatus},
          ),
        ),
      ),
    );
  }

  group('User model - mixed readOnly/writeOnly', () {
    group('toJson excludes readOnly properties', () {
      test('request body does not contain readOnly fields', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.createUser(
          body: const User(
            id: 42,
            name: 'Alice',
            password: 'secret123',
            createdAt: '2025-01-01',
          ),
        );

        final success = response as TonikSuccess<User>;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;

        // readOnly properties (id, createdAt) must NOT be in the request.
        expect(requestBody.containsKey('id'), isFalse);
        expect(requestBody.containsKey('createdAt'), isFalse);

        // Normal and writeOnly properties must be in the request.
        expect(requestBody['name'], 'Alice');
        expect(requestBody['password'], 'secret123');
      });

      test('optional non-readOnly fields are included when set', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.createUser(
          body: const User(
            id: 1,
            name: 'Bob',
            email: 'bob@example.com',
            password: 'pass',
          ),
        );

        final success = response as TonikSuccess<User>;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;

        expect(requestBody['name'], 'Bob');
        expect(requestBody['email'], 'bob@example.com');
        expect(requestBody['password'], 'pass');
        expect(requestBody.containsKey('id'), isFalse);
        expect(requestBody.containsKey('createdAt'), isFalse);
      });
    });

    group('fromJson excludes writeOnly properties', () {
      test('response decoding ignores writeOnly fields', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.getUser(userId: 42);

        final success = response as TonikSuccess<User>;
        final user = success.value;

        // readOnly and normal properties are parsed from the response.
        expect(user.id, 42);
        expect(user.name, 'Alice');
        expect(user.createdAt, '2025-01-01T00:00:00Z');

        // writeOnly property is null because fromJson excludes it.
        expect(user.password, isNull);
      });

      test('response with optional readOnly field present', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.getUser(userId: 99);

        final success = response as TonikSuccess<User>;
        final user = success.value;

        expect(user.id, 99);
        expect(user.name, 'Bob');
        expect(user.email, 'bob@example.com');
        expect(user.createdAt, '2025-06-15T12:00:00Z');
        expect(user.password, isNull);
      });
    });
  });

  group('User model - serialization roundtrips', () {
    test('toJson produces only writable properties', () {
      const user = User(
        id: 10,
        name: 'Charlie',
        email: 'charlie@example.com',
        password: 'hunter2',
        createdAt: '2025-03-01',
      );
      final json = user.toJson()! as Map;

      expect(json.containsKey('id'), isFalse);
      expect(json.containsKey('createdAt'), isFalse);
      expect(json['name'], 'Charlie');
      expect(json['email'], 'charlie@example.com');
      expect(json['password'], 'hunter2');
    });

    test('toJson includes writeOnly property when set', () {
      const user = User(name: 'NoPassword', password: 'secret');
      final json = user.toJson()! as Map;

      expect(json['name'], 'NoPassword');
      expect(json['password'], 'secret');
      expect(json.containsKey('id'), isFalse);
      expect(json.containsKey('createdAt'), isFalse);
    });

    test('fromJson parses only readable properties', () {
      final user = User.fromJson(const {
        'id': 7,
        'name': 'Diana',
        'email': 'diana@example.com',
        'password': 'should_be_ignored',
        'createdAt': '2025-04-01',
      });

      expect(user.id, 7);
      expect(user.name, 'Diana');
      expect(user.email, 'diana@example.com');
      expect(user.createdAt, '2025-04-01');
      // password is writeOnly — fromJson does not parse it.
      expect(user.password, isNull);
    });
  });

  group('Credentials model - all writeOnly', () {
    test('toJson includes all properties when set', () {
      const credentials = Credentials(username: 'admin', password: 'secret');
      final json = credentials.toJson()! as Map;

      expect(json['username'], 'admin');
      expect(json['password'], 'secret');
    });

    test('fromJson throws when all properties are writeOnly', () {
      expect(
        () => Credentials.fromJson(const {
          'username': 'admin',
          'password': 'secret',
        }),
        throwsA(isA<JsonDecodingException>()),
      );
    });
  });

  group('AuditEntry model - all readOnly', () {
    test('toJson produces empty map (all are readOnly)', () {
      const entry = AuditEntry(
        entryId: 1,
        timestamp: '2025-01-01',
        action: 'login',
      );
      final json = entry.toJson()! as Map;

      expect(json, isEmpty);
    });

    test('fromJson parses all properties (all are readOnly)', () {
      final entry = AuditEntry.fromJson(const {
        'entryId': 42,
        'timestamp': '2025-06-01T10:00:00Z',
        'action': 'logout',
      });

      expect(entry.entryId, 42);
      expect(entry.timestamp, '2025-06-01T10:00:00Z');
      expect(entry.action, 'logout');
    });

    test('constructor allows omitting all readOnly properties', () {
      const entry = AuditEntry();
      expect(entry.entryId, isNull);
      expect(entry.timestamp, isNull);
      expect(entry.action, isNull);
    });
  });

  group('User model - parameterProperties excludes readOnly', () {
    test('parameterProperties only includes writable fields', () {
      const user = User(
        id: 1,
        name: 'Test',
        password: 'pass',
        createdAt: '2025-01-01',
      );
      final params = user.parameterProperties();

      // readOnly fields (id, createdAt) excluded from parameterProperties.
      expect(params.containsKey('id'), isFalse);
      expect(params.containsKey('createdAt'), isFalse);

      // Normal and writeOnly fields are included.
      expect(params.containsKey('name'), isTrue);
      expect(params.containsKey('password'), isTrue);
    });

    test('parameterProperties includes optional non-readOnly when present', () {
      const user = User(
        id: 1,
        name: 'Test',
        email: 'test@example.com',
        password: 'pass',
        createdAt: '2025-01-01',
      );
      final params = user.parameterProperties();

      expect(params.containsKey('email'), isTrue);
      expect(params['email'], 'test%40example.com');
    });

    test('parameterProperties includes writeOnly fields', () {
      const user = User(name: 'Test', password: 'pass');
      final params = user.parameterProperties();

      expect(params.containsKey('name'), isTrue);
      expect(params.containsKey('password'), isTrue);
      expect(params['password'], 'pass');
    });
  });

  group('User model - encoding methods exclude readOnly', () {
    test('toSimple excludes readOnly fields', () {
      const user = User(
        id: 1,
        name: 'Test',
        password: 'pass',
      );
      final simple = user.toSimple(explode: false, allowEmpty: true);

      expect(simple.contains('id'), isFalse);
      expect(simple.contains('createdAt'), isFalse);
      expect(simple, contains('name'));
      expect(simple, contains('password'));
    });

    test('toForm excludes readOnly fields', () {
      const user = User(
        id: 1,
        name: 'Test',
        password: 'pass',
      );
      final form = user.toForm(explode: true, allowEmpty: true);

      expect(form.contains('id='), isFalse);
      expect(form.contains('createdAt='), isFalse);
      expect(form, contains('name=Test'));
      expect(form, contains('password=pass'));
    });

    test('toLabel excludes readOnly fields', () {
      const user = User(
        id: 1,
        name: 'Test',
        password: 'pass',
      );
      final label = user.toLabel(explode: false, allowEmpty: true);

      expect(label, isNot(contains('id')));
      expect(label, isNot(contains('createdAt')));
      expect(label, contains('name'));
      expect(label, contains('password'));
    });
  });

  group('fromSimple excludes writeOnly properties', () {
    test('fromSimple parses only readable properties', () {
      final user = User.fromSimple(
        'id,1,name,Alice,createdAt,2025-01-01',
        explode: false,
      );

      expect(user.id, 1);
      expect(user.name, 'Alice');
      expect(user.createdAt, '2025-01-01');
      expect(user.password, isNull);
    });
  });

  group('fromForm excludes writeOnly properties', () {
    test('fromForm parses only readable properties', () {
      final user = User.fromForm(
        'id=1&name=Alice&createdAt=2025-01-01',
        explode: true,
      );

      expect(user.id, 1);
      expect(user.name, 'Alice');
      expect(user.createdAt, '2025-01-01');
      expect(user.password, isNull);
    });
  });
}
