import 'package:naming_api/naming_api.dart'
    show
        $RawNullableVariant,
        $RawNullableVariantBaz,
        $RawNullableVariantBazModel,
        $RawNullableVariantBazModel2,
        BarBaz,
        Baz,
        Foo,
        FooBar,
        FooBarBaz,
        FooBarBazModel;
import 'package:test/test.dart';

void main() {
  test(
    'colliding oneOf variants remain distinct through the public library',
    () {
      final first = Foo.fromJson(const {'barBaz': 'first'});
      final second = FooBar.fromJson(const {'baz': 'second'});

      expect(first, const FooBarBaz(BarBaz(barBaz: 'first')));
      expect(second, const FooBarBazModel(Baz(baz: 'second')));
      expect(first.toJson(), {'barBaz': 'first'});
      expect(second.toJson(), {'baz': 'second'});
    },
  );

  test('nullable variants and object implementations have distinct names', () {
    final choice = $RawNullableVariant.fromJson(const {'baz': 'choice'});
    final object = $RawNullableVariantBazModel.fromJson(const {
      'value': 'object',
    });

    expect(choice, const $RawNullableVariantBaz(Baz(baz: 'choice')));
    expect(choice.toJson(), {'baz': 'choice'});
    expect(object.toJson(), {'value': 'object'});
    expect($RawNullableVariantBazModel2.active.toJson(), 'active');
  });
}
