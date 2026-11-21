import 'package:composition_api/composition_api.dart';
import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  test('allOf round-trips the base and enclosing properties', () {
    final labeled = Labeled.fromJson(const {'id': 42, 'label': 'created'});

    expect(labeled.toJson(), {'id': 42, 'label': 'created'});
  });

  test('allOf requires the enclosing label', () {
    expect(
      () => Labeled.fromJson(const {'id': 42}),
      throwsA(isA<DecodingException>()),
    );
  });

  test('required references to nullable allOf schemas round-trip null', () {
    final holder = NullableLabeledHolder.fromJson(const {
      'unconstrained': null,
      'extended': null,
      'nested': null,
    });

    expect(holder.unconstrained, isNull);
    expect(holder.extended, isNull);
    expect(holder.nested, isNull);
    expect(holder.toJson(), {
      'unconstrained': null,
      'extended': null,
      'nested': null,
    });
  });
}
