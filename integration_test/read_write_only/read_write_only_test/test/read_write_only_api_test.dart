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

    test('toJson throws when required writeOnly is null', () {
      const user = User(name: 'NoPassword', password: null);

      expect(
        () => user.toJson(),
        throwsA(isA<EncodingException>()),
      );
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

    test('fromJson accepts empty object for writeOnly-only model', () {
      final credentials = Credentials.fromJson(const {});

      expect(credentials.username, isNull);
      expect(credentials.password, isNull);
    });

    test('fromSimple accepts empty object for writeOnly-only model', () {
      final credentials = Credentials.fromSimple('', explode: true);

      expect(credentials.username, isNull);
      expect(credentials.password, isNull);
    });

    test('fromForm accepts empty object for writeOnly-only model', () {
      final credentials = Credentials.fromForm('', explode: true);

      expect(credentials.username, isNull);
      expect(credentials.password, isNull);
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

  group('ServerStatus model - schema-level readOnly', () {
    test('constructor makes all properties optional', () {
      const status = ServerStatus();
      expect(status.uptime, isNull);
      expect(status.version, isNull);
      expect(status.region, isNull);
    });

    test('all fields are nullable', () {
      const status = ServerStatus(uptime: 42, version: '1.0', region: 'us');
      expect(status.uptime, 42);
      expect(status.version, '1.0');
      expect(status.region, 'us');
    });

    test('fromJson decodes all properties normally', () {
      final status = ServerStatus.fromJson(const {
        'uptime': 3600,
        'version': '2.1.0',
        'region': 'eu-west',
      });
      expect(status.uptime, 3600);
      expect(status.version, '2.1.0');
      expect(status.region, 'eu-west');
    });

    test('toJson throws EncodingException', () {
      const status = ServerStatus(uptime: 1, version: '1.0');
      expect(() => status.toJson(), throwsA(isA<EncodingException>()));
    });

    test('parameterProperties throws EncodingException', () {
      const status = ServerStatus(uptime: 1, version: '1.0');
      expect(
        () => status.parameterProperties(),
        throwsA(isA<EncodingException>()),
      );
    });

    test('toSimple throws EncodingException', () {
      const status = ServerStatus(uptime: 1, version: '1.0');
      expect(
        () => status.toSimple(explode: false, allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
    });

    test('fromSimple decodes normally', () {
      final status = ServerStatus.fromSimple(
        'uptime,100,version,3.0',
        explode: false,
      );
      expect(status.uptime, 100);
      expect(status.version, '3.0');
    });
  });

  group('PasswordChange model - schema-level writeOnly', () {
    test('constructor keeps required properties required', () {
      const change = PasswordChange(
        newPassword: 'abc',
        confirmPassword: 'abc',
      );
      expect(change.newPassword, 'abc');
      expect(change.confirmPassword, 'abc');
      expect(change.hint, isNull);
    });

    test('toJson includes all properties', () {
      const change = PasswordChange(
        newPassword: 'new123',
        confirmPassword: 'new123',
        hint: 'my dog',
      );
      final json = change.toJson()! as Map;
      expect(json['newPassword'], 'new123');
      expect(json['confirmPassword'], 'new123');
      expect(json['hint'], 'my dog');
    });

    test('fromJson throws JsonDecodingException', () {
      expect(
        () => PasswordChange.fromJson(const {
          'newPassword': 'x',
          'confirmPassword': 'x',
        }),
        throwsA(isA<JsonDecodingException>()),
      );
    });

    test('fromSimple throws SimpleDecodingException', () {
      expect(
        () => PasswordChange.fromSimple('newPassword,x', explode: false),
        throwsA(isA<SimpleDecodingException>()),
      );
    });

    test('fromForm throws FormDecodingException', () {
      expect(
        () => PasswordChange.fromForm('newPassword=x', explode: true),
        throwsA(isA<FormDecodingException>()),
      );
    });

    test('parameterProperties works normally', () {
      const change = PasswordChange(
        newPassword: 'abc',
        confirmPassword: 'def',
      );
      final params = change.parameterProperties();
      expect(params['newPassword'], 'abc');
      expect(params['confirmPassword'], 'def');
    });
  });

  group('ReadOnlyNotification (oneOf) - schema-level readOnly', () {
    test('fromJson decodes email variant normally', () {
      final notification = ReadOnlyNotification.fromJson(const {
        'emailAddress': 'alice@example.com',
        'subject': 'Hello',
        'body': 'World',
      });

      expect(notification, isA<ReadOnlyNotificationNotificationEmail>());
      final email =
          (notification as ReadOnlyNotificationNotificationEmail).value;
      expect(email.emailAddress, 'alice@example.com');
      expect(email.subject, 'Hello');
      expect(email.body, 'World');
    });

    test('fromJson decodes sms variant normally', () {
      final notification = ReadOnlyNotification.fromJson(const {
        'phoneNumber': '+1234567890',
        'message': 'Hi there',
      });

      expect(notification, isA<ReadOnlyNotificationNotificationSms>());
      final sms = (notification as ReadOnlyNotificationNotificationSms).value;
      expect(sms.phoneNumber, '+1234567890');
      expect(sms.message, 'Hi there');
    });

    test('fromSimple decodes normally', () {
      final notification = ReadOnlyNotification.fromSimple(
        'phoneNumber,%2B1234567890,message,Hi',
        explode: false,
      );
      expect(notification, isA<ReadOnlyNotificationNotificationSms>());
    });

    test('fromForm decodes normally', () {
      final notification = ReadOnlyNotification.fromForm(
        'phoneNumber=%2B1234567890&message=Hi',
        explode: true,
      );
      expect(notification, isA<ReadOnlyNotificationNotificationSms>());
    });

    test('toJson throws EncodingException', () {
      final notification = ReadOnlyNotification.fromJson(const {
        'emailAddress': 'test@example.com',
        'subject': 'Test',
      });

      expect(
        notification.toJson,
        throwsA(isA<EncodingException>()),
      );
    });

    test('parameterProperties throws EncodingException', () {
      final notification = ReadOnlyNotification.fromJson(const {
        'emailAddress': 'test@example.com',
        'subject': 'Test',
      });

      expect(
        notification.parameterProperties,
        throwsA(isA<EncodingException>()),
      );
    });

    test('currentEncodingShape throws EncodingException', () {
      final notification = ReadOnlyNotification.fromJson(const {
        'emailAddress': 'test@example.com',
        'subject': 'Test',
      });

      expect(
        () => notification.currentEncodingShape,
        throwsA(isA<EncodingException>()),
      );
    });

    test('uriEncode throws EncodingException', () {
      final notification = ReadOnlyNotification.fromJson(const {
        'emailAddress': 'test@example.com',
        'subject': 'Test',
      });

      expect(
        () => notification.uriEncode(allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
    });

    test(
      'GET /notifications/sent returns decoded readOnly notification',
      () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.getSentNotification();

        final success = response as TonikSuccess<ReadOnlyNotification>;
        final notification = success.value;

        expect(notification, isA<ReadOnlyNotificationNotificationEmail>());
        final email =
            (notification as ReadOnlyNotificationNotificationEmail).value;
        expect(email.emailAddress, 'alice@example.com');
        expect(email.subject, 'Welcome');
        expect(email.body, 'Hello!');
      },
    );
  });

  group('WriteOnlyNotification (oneOf) - schema-level writeOnly', () {
    test('toJson encodes email variant normally', () {
      const notification = WriteOnlyNotificationNotificationEmail(
        NotificationEmail(
          emailAddress: 'bob@example.com',
          subject: 'Meeting',
          body: 'Tomorrow at 10',
        ),
      );
      final json = notification.toJson()! as Map;

      expect(json['emailAddress'], 'bob@example.com');
      expect(json['subject'], 'Meeting');
      expect(json['body'], 'Tomorrow at 10');
    });

    test('toJson encodes sms variant normally', () {
      const notification = WriteOnlyNotificationNotificationSms(
        NotificationSms(
          phoneNumber: '+1234567890',
          message: 'Hello',
        ),
      );
      final json = notification.toJson()! as Map;

      expect(json['phoneNumber'], '+1234567890');
      expect(json['message'], 'Hello');
    });

    test('fromJson throws JsonDecodingException', () {
      expect(
        () => WriteOnlyNotification.fromJson(const {
          'emailAddress': 'test@example.com',
          'subject': 'Test',
        }),
        throwsA(isA<JsonDecodingException>()),
      );
    });

    test('fromSimple throws SimpleDecodingException', () {
      expect(
        () => WriteOnlyNotification.fromSimple(
          'phoneNumber,%2B123,message,Hi',
          explode: false,
        ),
        throwsA(isA<SimpleDecodingException>()),
      );
    });

    test('fromForm throws FormDecodingException', () {
      expect(
        () => WriteOnlyNotification.fromForm(
          'phoneNumber=%2B123&message=Hi',
          explode: true,
        ),
        throwsA(isA<FormDecodingException>()),
      );
    });

    test('POST /notifications/send sends writeOnly notification', () async {
      final api = buildApi(responseStatus: '200');

      final response = await api.sendNotification(
        body: const WriteOnlyNotificationNotificationEmail(
          NotificationEmail(
            emailAddress: 'bob@example.com',
            subject: 'Test',
            body: 'Testing writeOnly oneOf',
          ),
        ),
      );

      final success =
          response as TonikSuccess<NotificationsSendPost200BodyModel>;
      final requestBody =
          success.response.requestOptions.data as Map<String, dynamic>;

      // Verify the request body contains the email notification data.
      expect(requestBody['emailAddress'], 'bob@example.com');
      expect(requestBody['subject'], 'Test');
      expect(requestBody['body'], 'Testing writeOnly oneOf');
    });
  });

  group('ReadOnlyServerInfo (allOf) - schema-level readOnly', () {
    test('fromJson decodes all constituent model fields', () {
      final info = ReadOnlyServerInfo.fromJson(const {
        'serverId': 'srv-001',
        'region': 'us-east',
        'cpuUsage': 42.5,
        'memoryUsage': 75.0,
      });

      expect(info.serverIdentity?.serverId, 'srv-001');
      expect(info.serverIdentity?.region, 'us-east');
      expect(info.serverMetrics?.cpuUsage, 42.5);
      expect(info.serverMetrics?.memoryUsage, 75.0);
    });

    test('constructor fields are optional when readOnly', () {
      const info = ReadOnlyServerInfo();
      expect(info.serverIdentity, isNull);
      expect(info.serverMetrics, isNull);
    });

    test('toJson throws EncodingException', () {
      const info = ReadOnlyServerInfo();
      expect(() => info.toJson(), throwsA(isA<EncodingException>()));
    });

    test('parameterProperties throws EncodingException', () {
      const info = ReadOnlyServerInfo();
      expect(
        () => info.parameterProperties(),
        throwsA(isA<EncodingException>()),
      );
    });

    test('currentEncodingShape throws EncodingException', () {
      const info = ReadOnlyServerInfo();
      expect(
        () => info.currentEncodingShape,
        throwsA(isA<EncodingException>()),
      );
    });

    test('uriEncode throws EncodingException', () {
      const info = ReadOnlyServerInfo();
      expect(
        () => info.uriEncode(allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
    });

    test('fromSimple decodes normally', () {
      final info = ReadOnlyServerInfo.fromSimple(
        'serverId,srv-002,region,eu-west,cpuUsage,10.0,memoryUsage,50.0',
        explode: false,
      );
      expect(info.serverIdentity?.serverId, 'srv-002');
      expect(info.serverIdentity?.region, 'eu-west');
    });

    test('GET /server-info returns decoded readOnly allOf', () async {
      final api = buildApi(responseStatus: '200');

      final response = await api.getServerInfo();

      final success = response as TonikSuccess<ReadOnlyServerInfo>;
      final info = success.value;

      expect(info.serverIdentity?.serverId, 'srv-001');
      expect(info.serverIdentity?.region, 'us-east');
      expect(info.serverMetrics?.cpuUsage, 42.5);
      expect(info.serverMetrics?.memoryUsage, 75.0);
    });
  });

  group('WriteOnlyBulkCommand (allOf) - schema-level writeOnly', () {
    test('toJson encodes all constituent model fields', () {
      const command = WriteOnlyBulkCommand(
        commandAuth: CommandAuth(token: 'abc123'),
        commandBody: CommandBody(action: 'delete', payload: 'item-42'),
      );
      final json = command.toJson()! as Map;

      expect(json['token'], 'abc123');
      expect(json['action'], 'delete');
      expect(json['payload'], 'item-42');
    });

    test('fromJson throws JsonDecodingException', () {
      expect(
        () => WriteOnlyBulkCommand.fromJson(const {
          'token': 'abc',
          'action': 'delete',
        }),
        throwsA(isA<JsonDecodingException>()),
      );
    });

    test('fromSimple throws SimpleDecodingException', () {
      expect(
        () => WriteOnlyBulkCommand.fromSimple(
          'token,abc,action,delete',
          explode: false,
        ),
        throwsA(isA<SimpleDecodingException>()),
      );
    });

    test('fromForm throws FormDecodingException', () {
      expect(
        () => WriteOnlyBulkCommand.fromForm(
          'token=abc&action=delete',
          explode: true,
        ),
        throwsA(isA<FormDecodingException>()),
      );
    });

    test('parameterProperties works normally', () {
      const command = WriteOnlyBulkCommand(
        commandAuth: CommandAuth(token: 'abc123'),
        commandBody: CommandBody(action: 'create'),
      );
      final params = command.parameterProperties();
      expect(params['token'], 'abc123');
      expect(params['action'], 'create');
    });

    test('POST /bulk-command sends writeOnly allOf command', () async {
      final api = buildApi(responseStatus: '200');

      final response = await api.sendBulkCommand(
        body: const WriteOnlyBulkCommand(
          commandAuth: CommandAuth(token: 'secret-token'),
          commandBody: CommandBody(action: 'restart', payload: 'server-1'),
        ),
      );

      final success = response as TonikSuccess<BulkCommandPost200BodyModel>;
      final requestBody =
          success.response.requestOptions.data as Map<String, dynamic>;

      expect(requestBody['token'], 'secret-token');
      expect(requestBody['action'], 'restart');
      expect(requestBody['payload'], 'server-1');
    });
  });

  group('ReadOnlySensorReading (anyOf) - schema-level readOnly', () {
    test('fromJson decodes temperature variant fields', () {
      final reading = ReadOnlySensorReading.fromJson(const {
        'celsius': 23.5,
        'sensorId': 'temp-001',
      });

      expect(reading.temperatureReading, isNotNull);
      expect(reading.temperatureReading?.celsius, 23.5);
      expect(reading.temperatureReading?.sensorId, 'temp-001');
    });

    test('fromJson decodes humidity variant fields', () {
      final reading = ReadOnlySensorReading.fromJson(const {
        'percentage': 65.0,
        'sensorId': 'hum-001',
      });

      expect(reading.humidityReading, isNotNull);
      expect(reading.humidityReading?.percentage, 65.0);
      expect(reading.humidityReading?.sensorId, 'hum-001');
    });

    test('fromSimple decodes normally', () {
      final reading = ReadOnlySensorReading.fromSimple(
        'celsius,23.5,sensorId,temp-001',
        explode: false,
      );
      expect(reading.temperatureReading, isNotNull);
    });

    test('fromForm decodes normally', () {
      final reading = ReadOnlySensorReading.fromForm(
        'celsius=23.5&sensorId=temp-001',
        explode: true,
      );
      expect(reading.temperatureReading, isNotNull);
    });

    test('toJson throws EncodingException', () {
      final reading = ReadOnlySensorReading.fromJson(const {
        'celsius': 23.5,
        'sensorId': 'temp-001',
      });

      expect(
        reading.toJson,
        throwsA(isA<EncodingException>()),
      );
    });

    test('parameterProperties throws EncodingException', () {
      final reading = ReadOnlySensorReading.fromJson(const {
        'celsius': 23.5,
        'sensorId': 'temp-001',
      });

      expect(
        reading.parameterProperties,
        throwsA(isA<EncodingException>()),
      );
    });

    test('currentEncodingShape throws EncodingException', () {
      final reading = ReadOnlySensorReading.fromJson(const {
        'celsius': 23.5,
        'sensorId': 'temp-001',
      });

      expect(
        () => reading.currentEncodingShape,
        throwsA(isA<EncodingException>()),
      );
    });

    test('uriEncode throws EncodingException', () {
      final reading = ReadOnlySensorReading.fromJson(const {
        'celsius': 23.5,
        'sensorId': 'temp-001',
      });

      expect(
        () => reading.uriEncode(allowEmpty: true),
        throwsA(isA<EncodingException>()),
      );
    });

    test(
      'GET /sensor-reading returns decoded readOnly anyOf',
      () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.getSensorReading();

        final success = response as TonikSuccess<ReadOnlySensorReading>;
        final reading = success.value;

        expect(reading.temperatureReading, isNotNull);
        expect(reading.temperatureReading?.celsius, 23.5);
        expect(reading.temperatureReading?.sensorId, 'temp-001');
      },
    );
  });

  group('WriteOnlyDeviceCommand (anyOf) - schema-level writeOnly', () {
    test('toJson encodes reboot command fields normally', () {
      const command = WriteOnlyDeviceCommand(
        rebootCommand: RebootCommand(
          deviceId: 'dev-001',
          force: true,
        ),
      );
      final json = command.toJson()! as Map;

      expect(json['deviceId'], 'dev-001');
      expect(json['force'], isTrue);
    });

    test('toJson encodes firmware update command fields normally', () {
      const command = WriteOnlyDeviceCommand(
        updateFirmwareCommand: UpdateFirmwareCommand(
          deviceId: 'dev-002',
          firmwareUrl: 'https://example.com/fw.bin',
        ),
      );
      final json = command.toJson()! as Map;

      expect(json['deviceId'], 'dev-002');
      expect(json['firmwareUrl'], 'https://example.com/fw.bin');
    });

    test('fromJson throws JsonDecodingException', () {
      expect(
        () => WriteOnlyDeviceCommand.fromJson(const {
          'deviceId': 'dev-001',
          'force': true,
        }),
        throwsA(isA<JsonDecodingException>()),
      );
    });

    test('fromSimple throws SimpleDecodingException', () {
      expect(
        () => WriteOnlyDeviceCommand.fromSimple(
          'deviceId,dev-001,force,true',
          explode: false,
        ),
        throwsA(isA<SimpleDecodingException>()),
      );
    });

    test('fromForm throws FormDecodingException', () {
      expect(
        () => WriteOnlyDeviceCommand.fromForm(
          'deviceId=dev-001&force=true',
          explode: true,
        ),
        throwsA(isA<FormDecodingException>()),
      );
    });

    test('parameterProperties works normally', () {
      const command = WriteOnlyDeviceCommand(
        rebootCommand: RebootCommand(
          deviceId: 'dev-001',
          force: true,
        ),
      );
      final params = command.parameterProperties();
      expect(params['deviceId'], 'dev-001');
      expect(params['force'], 'true');
    });

    test('POST /device-command sends writeOnly anyOf command', () async {
      final api = buildApi(responseStatus: '200');

      final response = await api.sendDeviceCommand(
        body: const WriteOnlyDeviceCommand(
          rebootCommand: RebootCommand(
            deviceId: 'dev-001',
            force: true,
          ),
        ),
      );

      final success = response as TonikSuccess<DeviceCommandPost200BodyModel>;
      final requestBody =
          success.response.requestOptions.data as Map<String, dynamic>;

      expect(requestBody['deviceId'], 'dev-001');
      expect(requestBody['force'], isTrue);
    });
  });
}
