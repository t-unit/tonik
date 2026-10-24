import 'package:simple_encoding_api/simple_encoding_api.dart';
import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  test('preserves declared and additional percent keys in simple objects', () {
    final decoded = PercentKeyObject.fromSimple(
      'a%=raw,%41=encoded,A=letter,extra%=more',
      explode: true,
    );

    expect(decoded.toJson(), {
      'a%': 'raw',
      '%41': 'encoded',
      'A': 'letter',
      'extra%': 'more',
    });
  });

  test('preserves declared and additional percent keys in header objects', () {
    final decoded = PercentKeyObject.fromSimple(
      'a%=raw, %41=encoded, A=letter, extra%=more',
      explode: true,
      isHeader: true,
    );

    expect(decoded.toJson(), {
      'a%': 'raw',
      '%41': 'encoded',
      'A': 'letter',
      'extra%': 'more',
    });
  });

  test('keeps percent signs and percent-looking names in simple lists', () {
    final decoded = HeaderPerson.fromSimple(
      'age,30,tags,100%,%6Eame,name,Alice',
      explode: false,
    );

    expect(decoded.tags, ['100%', '%6Eame']);
    expect(decoded.name, 'Alice');
  });

  test('keeps percent signs and percent-looking names in header lists', () {
    final decoded = HeaderPerson.fromSimple(
      'age,30,tags,100%,%6Eame,name,Alice',
      explode: false,
      isHeader: true,
    );

    expect(decoded.tags, ['100%', '%6Eame']);
    expect(decoded.name, 'Alice');
  });

  test('preserves additional percent keys through simple allOf decoding', () {
    final decoded = HeaderPersonWithExtras.fromSimple(
      'a%,raw,%41,encoded,name,Alice,age,30',
      explode: false,
    );

    expect(decoded.additionalProperties, {'a%': 'raw', '%41': 'encoded'});
  });

  test('preserves additional percent keys through header allOf decoding', () {
    final decoded = HeaderPersonWithExtras.fromSimple(
      'a%,raw, %41,encoded, name,Alice, age,30',
      explode: false,
      isHeader: true,
    );

    expect(decoded.additionalProperties, {'a%': 'raw', '%41': 'encoded'});
  });

  test(
    'dispatches a literal percent-looking discriminator in simple input',
    () {
      expect(
        () => PercentKeyChoice.fromSimple('%41=person', explode: true),
        throwsA(isA<InvalidTypeException>()),
      );
    },
  );

  test(
    'dispatches a literal percent-looking discriminator in header input',
    () {
      expect(
        () => PercentKeyChoice.fromSimple(
          '%41=person',
          explode: true,
          isHeader: true,
        ),
        throwsA(isA<InvalidTypeException>()),
      );
    },
  );

  test('retains percent-decoded form keys', () {
    final decoded = PercentKeyObject.fromForm(
      'a%25=raw&%2541=encoded&A=letter',
      explode: true,
    );

    expect(decoded.toJson(), {'a%': 'raw', '%41': 'encoded', 'A': 'letter'});
  });
}
