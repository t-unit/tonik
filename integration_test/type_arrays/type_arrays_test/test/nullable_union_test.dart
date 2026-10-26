import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';
import 'package:type_arrays_api/type_arrays_api.dart';

void main() {
  test('nullable anyOf members preserve required null properties', () {
    final profile = NullableUnionProfile.fromJson(const {
      'externalId': null,
      'referencedId': null,
    });

    expect(profile.externalId, isNull);
    expect(profile.referencedId, isNull);
    expect(profile.toJson(), {'externalId': null, 'referencedId': null});
  });

  test('nullable anyOf members preserve string and integer values', () {
    final profile = NullableUnionProfile.fromJson(const {
      'externalId': 'A-42',
      'referencedId': 42,
    });

    expect(profile.toJson(), {'externalId': 'A-42', 'referencedId': 42});
  });

  test('nullable anyOf rejects values outside its alternatives', () {
    expect(
      () => NullableUnionProfile.fromJson(const {
        'externalId': true,
        'referencedId': null,
      }),
      throwsA(isA<JsonDecodingException>()),
    );
  });

  test('required write-only nullable union encodes an explicit null', () {
    const value = NullableWriteOnlyUnion(externalId: null);

    expect(value.toJson(), {'externalId': null});
  });

  test('required write-only nonnullable union rejects null', () {
    const value = NonnullableWriteOnlyUnion(externalId: null);

    expect(value.toJson, throwsA(isA<EncodingException>()));
  });
}
