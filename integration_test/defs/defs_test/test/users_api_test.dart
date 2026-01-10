import 'package:defs_api/defs_api.dart';
import 'package:test/test.dart';

void main() {
  group(r'UserTypes$DefsUserSettingsUserSettingsThemeModel enum', () {
    test('has expected values', () {
      expect(
        UserTypes$DefsUserSettingsUserSettingsThemeModel.values,
        hasLength(3),
      );
      expect(
        UserTypes$DefsUserSettingsUserSettingsThemeModel.light.toJson(),
        'light',
      );
      expect(
        UserTypes$DefsUserSettingsUserSettingsThemeModel.dark.toJson(),
        'dark',
      );
      expect(
        UserTypes$DefsUserSettingsUserSettingsThemeModel.system.toJson(),
        'system',
      );
    });

    test('fromJson parses correctly', () {
      expect(
        UserTypes$DefsUserSettingsUserSettingsThemeModel.fromJson('light'),
        UserTypes$DefsUserSettingsUserSettingsThemeModel.light,
      );
      expect(
        UserTypes$DefsUserSettingsUserSettingsThemeModel.fromJson('dark'),
        UserTypes$DefsUserSettingsUserSettingsThemeModel.dark,
      );
      expect(
        UserTypes$DefsUserSettingsUserSettingsThemeModel.fromJson('system'),
        UserTypes$DefsUserSettingsUserSettingsThemeModel.system,
      );
    });
  });

  group('CreateUserRequest model', () {
    test('serializes to JSON', () {
      const request = CreateUserRequest(
        email: 'test@example.com',
        name: 'Test User',
      );

      final json = request.toJson()! as Map<String, Object?>;
      expect(json['email'], 'test@example.com');
      expect(json['name'], 'Test User');
    });

    test('serializes with profile', () {
      const request = CreateUserRequest(
        email: 'test@example.com',
        name: 'Test User',
        profile: UserProfile(
          bio: 'Hello',
          settings: UserSettings(
            theme: UserTypes$DefsUserSettingsUserSettingsThemeModel.light,
          ),
        ),
      );

      final json = request.toJson()! as Map<String, Object?>;
      expect(json['email'], 'test@example.com');
      expect(json['profile'], isA<Map<String, Object?>>());
    });

    test('deserializes from JSON', () {
      final json = {
        'email': 'test@example.com',
        'name': 'Test User',
        'profile': {
          'bio': 'Hello',
          'settings': {'theme': 'dark', 'notifications_enabled': true},
        },
      };

      final request = CreateUserRequest.fromJson(json);
      expect(request.email, 'test@example.com');
      expect(request.name, 'Test User');
      expect(request.profile?.bio, 'Hello');
      expect(
        request.profile?.settings?.theme,
        UserTypes$DefsUserSettingsUserSettingsThemeModel.dark,
      );
    });
  });

  group('UserResponse model', () {
    test('deserializes from JSON', () {
      final json = {
        'id': '550e8400-e29b-41d4-a716-446655440000',
        'email': 'test@example.com',
        'name': 'Test User',
        'created_at': '2024-01-01T00:00:00Z',
      };

      final response = UserResponse.fromJson(json);
      expect(response.id, '550e8400-e29b-41d4-a716-446655440000');
      expect(response.email, 'test@example.com');
      expect(response.name, 'Test User');
    });
  });
}
