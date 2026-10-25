import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:type_arrays_api/type_arrays_api.dart';

void main() {
  late TypeArraysApi api;

  setUpAll(() async {
    final server = await setupImposterServer();
    api = TypeArraysApi(
      CustomServer(baseUrl: 'http://localhost:${server.port}'),
    );
  });

  test('decodes a null response for a named nullable array', () async {
    final success = requireSuccess(await api.getNullableTags());

    expect(success.value, isNull);
  });

  test('decodes a null response for an inline nullable array', () async {
    final success = requireSuccess(await api.getInlineNullableTags());

    expect(success.value, isNull);
  });

  test('decodes a null response for an inline nullable multi-type', () async {
    final success = requireSuccess(await api.getInlineNullableValue());

    expect(success.value, isNull);
  });

  test(
    'round-trips required named, inline array and multi-type null values',
    () async {
      final input = NullableArrayValues.fromJson(const {
        'namedTags': null,
        'inlineTags': null,
        'value': null,
      });

      final success = requireSuccess(await api.echoNullableValues(body: input));

      expect(success.value.toJson(), {
        'namedTags': null,
        'inlineTags': null,
        'value': null,
      });
    },
  );

  test('round-trips non-null array and multi-type values', () async {
    final input = NullableArrayValues.fromJson(const {
      'namedTags': ['first'],
      'inlineTags': ['second'],
      'value': 42,
    });

    final success = requireSuccess(await api.echoNullableValues(body: input));

    expect(success.value.toJson(), {
      'namedTags': ['first'],
      'inlineTags': ['second'],
      'value': 42,
    });
  });
}
