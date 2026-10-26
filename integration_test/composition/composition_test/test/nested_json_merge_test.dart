import 'package:composition_api/composition_api.dart';
import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  test('anyOf preserves overlapping nested object properties', () {
    final value = AnyOfNestedDetails.fromJson(const {
      'details': {'givenName': 'Ada', 'familyName': 'Lovelace'},
    });
    expect(value.toJson(), {
      'details': {'givenName': 'Ada', 'familyName': 'Lovelace'},
    });
  });

  test('allOf preserves overlapping nested object properties', () {
    final value = AllOfNestedDetails.fromJson(const {
      'details': {'givenName': 'Ada', 'familyName': 'Lovelace'},
    });
    expect(value.toJson(), {
      'details': {'givenName': 'Ada', 'familyName': 'Lovelace'},
    });
  });

  test('allOf merges nested objects selected by a scalar or object union', () {
    final value = AllOfUnionNestedDetails.fromJson(const {
      'details': {'givenName': 'Ada', 'familyName': 'Lovelace'},
    });

    expect(value.toJson(), {
      'details': {'givenName': 'Ada', 'familyName': 'Lovelace'},
    });
  });

  test('anyOf preserves sibling schema fields and nested branch fields', () {
    final value = ContactDetails.fromJson(const {
      'details': {
        'givenName': 'Ada',
        'familyName': 'Lovelace',
        'title': 'Countess',
      },
    });
    expect(value.toJson(), {
      'details': {
        'givenName': 'Ada',
        'familyName': 'Lovelace',
        'title': 'Countess',
      },
    });
  });

  test('anyOf enforces required fields from its sibling object schema', () {
    expect(
      () => ContactDetails.fromJson(const {
        'details': {'givenName': 'Ada'},
      }),
      throwsA(
        isA<InvalidTypeException>().having(
          (error) => error.context,
          'context',
          'ContactDetailsDetailsModel.familyName',
        ),
      ),
    );
  });

  test('nullable siblings preserve named and inline null values', () {
    final value = NullableContactDetailsHolder.fromJson(const {
      'named': null,
      'inline': null,
    });
    expect(value.named, isNull);
    expect(value.inline, isNull);
    expect(value.toJson(), {'named': null, 'inline': null});
  });

  test(
    'object siblings preserve values after skipping a direct self-reference',
    () {
      final value = SelfReferencedContact.fromJson(const {
        'name': 'Ada',
        'email': 'ada@example.test',
      });
      expect(value.toJson(), {'name': 'Ada', 'email': 'ada@example.test'});
    },
  );
}
