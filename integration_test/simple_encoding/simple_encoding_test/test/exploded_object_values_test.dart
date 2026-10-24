import 'package:simple_encoding_api/simple_encoding_api.dart';
import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  test('retains string fallback for malformed percent keys with equals', () {
    expect(
      HeaderEqualsChoice.fromSimple('%=a=b', explode: true),
      const HeaderEqualsChoiceString('%=a=b'),
    );
    expect(
      HeaderEqualsChoice.fromSimple('%=a=b', explode: true, isHeader: true),
      const HeaderEqualsChoiceString('%=a=b'),
    );
    expect(
      HeaderEqualsChoice.fromSimple('%FF=a=b', explode: true),
      const HeaderEqualsChoiceString('%FF=a=b'),
    );
    expect(
      () => HeaderEqualsChoice.fromForm('%=a=b', explode: true),
      throwsA(isA<DecodingException>()),
    );
  });

  test('round-trips literal simple object values with equals signs', () {
    const original = SimpleObject(name: 'YQ==', value: 1);
    final encoded = original.toSimple(
      explode: true,
      allowEmpty: true,
      literal: true,
    );

    expect(encoded, 'name=YQ==,value=1');
    expect(SimpleObject.fromSimple(encoded, explode: true), original);
    expect(
      SimpleObject.fromSimple(encoded, explode: true, isHeader: true),
      original,
    );
  });

  test('preserves additional equals signs in form object values', () {
    final decoded = SimpleObject.fromForm('name=a=b&value=1', explode: true);

    expect(decoded.name, 'a=b');
    expect(decoded.value, 1);
  });

  test('dispatches header discriminator values containing equals signs', () {
    final decoded = HeaderEqualsChoice.fromSimple(
      'kind=person=special, name=YQ==, age=30',
      explode: true,
      isHeader: true,
    );

    expect(
      decoded,
      const HeaderEqualsChoiceHeaderPerson(
        HeaderPerson(kind: 'person=special', name: 'YQ==', age: 30),
      ),
    );
  });

  test('dispatches simple discriminator values containing equals signs', () {
    final decoded = HeaderEqualsChoice.fromSimple(
      'kind=person=special,name=YQ==,age=30',
      explode: true,
    );

    expect(
      decoded,
      const HeaderEqualsChoiceHeaderPerson(
        HeaderPerson(kind: 'person=special', name: 'YQ==', age: 30),
      ),
    );
  });

  test('validates the selected object after an equals-containing tag', () {
    expect(
      () => HeaderEqualsChoice.fromSimple(
        'kind=person=special',
        explode: true,
        isHeader: true,
      ),
      throwsA(isA<InvalidTypeException>()),
    );
    expect(
      () => HeaderEqualsChoice.fromSimple('kind=person=special', explode: true),
      throwsA(isA<InvalidTypeException>()),
    );
    expect(
      () => HeaderEqualsChoice.fromForm('kind=person=special', explode: true),
      throwsA(isA<InvalidTypeException>()),
    );
  });
}
