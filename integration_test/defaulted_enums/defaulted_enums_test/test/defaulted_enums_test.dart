import 'package:defaulted_enums_api/defaulted_enums_api.dart';
import 'package:test/test.dart';

void main() {
  group('Subscription — enum const defaults', () {
    test('constructor with no args yields enum defaults', () {
      const value = Subscription();
      expect(value.priority, SubscriptionPriorityModel.medium);
      expect(value.level, SubscriptionLevelModel.two);
      expect(value.status, Status.active);
      expect(value.fallbackPriority, isNull);
    });

    test('public static const exposes enum default values', () {
      expect(Subscription.priorityDefault, SubscriptionPriorityModel.medium);
      expect(Subscription.levelDefault, SubscriptionLevelModel.two);
      expect(Subscription.statusDefault, Status.active);
    });

    test('fromJson with empty map yields enum defaults', () {
      final value = Subscription.fromJson(const <String, Object?>{});
      expect(value.priority, SubscriptionPriorityModel.medium);
      expect(value.level, SubscriptionLevelModel.two);
      expect(value.status, Status.active);
      expect(value.fallbackPriority, isNull);
    });

    test('fromJson supplied wire values override the defaults', () {
      final value = Subscription.fromJson(const <String, Object?>{
        'priority': 'high',
        'level': 3,
        'status': 'inactive',
      });
      expect(value.priority, SubscriptionPriorityModel.high);
      expect(value.level, SubscriptionLevelModel.three);
      expect(value.status, Status.inactive);
    });

    test('round-trip: fromJson(toJson(...)) yields an equal instance', () {
      const original = Subscription();
      final encoded = original.toJson()! as Map<String, Object?>;
      final decoded = Subscription.fromJson(encoded);
      expect(decoded, original);
    });

    test(
      'default value NOT in enum values is dropped — the field keeps the '
      'no-default behaviour and remains null when the key is missing',
      () {
        // `fallbackPriority` was declared with default "nonexistent" but the
        // enum only contains [low, medium, high]; the generator must drop the
        // default and emit no static const member.
        final value = Subscription.fromJson(const <String, Object?>{});
        expect(value.fallbackPriority, isNull);
      },
    );
  });
}
