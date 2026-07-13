import 'package:test/test.dart';
import 'package:tonik_util/src/encoding/encoding_exception.dart';
import 'package:tonik_util/src/encoding/form_field_encoding.dart';
import 'package:tonik_util/src/encoding/parameter_entry.dart';
import 'package:tonik_util/src/encoding/property_value.dart';
import 'package:tonik_util/src/encoding/property_value_form_encoder.dart';

void main() {
  group('object-level explode=true', () {
    test('explodes a flagged array into repeated keys beside a scalar', () {
      expect(
        <String, PropertyValue>{
          'name': const PropertyValue.scalar('John'),
          'colors': const PropertyValue.array(['red', 'green', 'blue']),
        }.toForm(
          'p',
          explode: true,
          allowEmpty: true,
          fieldEncodings: const {'colors': FormFieldEncoding(explode: true)},
        ),
        const <ParameterEntry>[
          (name: 'name', value: 'John'),
          (name: 'colors', value: 'red'),
          (name: 'colors', value: 'green'),
          (name: 'colors', value: 'blue'),
        ],
      );
    });

    test('comma-joins an array with no descriptor beside a scalar', () {
      expect(
        <String, PropertyValue>{
          'q': const PropertyValue.scalar('hello'),
          'tags': const PropertyValue.array(['urgent', 'open']),
        }.toForm('p', explode: true, allowEmpty: true),
        const <ParameterEntry>[
          (name: 'q', value: 'hello'),
          (name: 'tags', value: 'urgent,open'),
        ],
      );
    });

    test('comma-joins an array with an explicit explode=false descriptor', () {
      expect(
        <String, PropertyValue>{
          'colors': const PropertyValue.array(['red', 'green', 'blue']),
        }.toForm(
          'p',
          explode: true,
          allowEmpty: true,
          fieldEncodings: const {'colors': FormFieldEncoding()},
        ),
        const <ParameterEntry>[(name: 'colors', value: 'red,green,blue')],
      );
    });
  });

  group('object-level explode=true empty distinction', () {
    test('omits an exploded empty array entirely', () {
      expect(
        <String, PropertyValue>{
          'name': const PropertyValue.scalar('John'),
          'tags': const PropertyValue.array([]),
        }.toForm(
          'p',
          explode: true,
          allowEmpty: true,
          fieldEncodings: const {'tags': FormFieldEncoding(explode: true)},
        ),
        const <ParameterEntry>[(name: 'name', value: 'John')],
      );
    });

    test('emits one empty-value entry for an exploded single empty-string '
        'element', () {
      expect(
        <String, PropertyValue>{
          'tags': const PropertyValue.array(['']),
        }.toForm(
          'p',
          explode: true,
          allowEmpty: true,
          fieldEncodings: const {'tags': FormFieldEncoding(explode: true)},
        ),
        const <ParameterEntry>[(name: 'tags', value: '')],
      );
    });

    test('emits one empty-value entry for a non-exploded empty array', () {
      expect(
        <String, PropertyValue>{
          'tags': const PropertyValue.array([]),
        }.toForm('p', explode: true, allowEmpty: true),
        const <ParameterEntry>[(name: 'tags', value: '')],
      );
    });

    test('omits an empty scalar flagged as an exploded array beside a '
        'scalar', () {
      expect(
        <String, PropertyValue>{
          'name': const PropertyValue.scalar('John'),
          'numbers': const PropertyValue.scalar(''),
        }.toForm(
          'p',
          explode: true,
          allowEmpty: true,
          fieldEncodings: const {'numbers': FormFieldEncoding(explode: true)},
        ),
        const <ParameterEntry>[(name: 'name', value: 'John')],
      );
    });

    test('keeps an empty scalar with no explode descriptor', () {
      expect(
        <String, PropertyValue>{
          'name': const PropertyValue.scalar(''),
        }.toForm('p', explode: true, allowEmpty: true),
        const <ParameterEntry>[(name: 'name', value: '')],
      );
    });
  });

  group('object-level explode=true comma inside element', () {
    test('percent-encodes an element comma when exploded without '
        'allowReserved', () {
      expect(
        <String, PropertyValue>{
          'tags': const PropertyValue.array(['a,b', 'c']),
        }.toForm(
          'p',
          explode: true,
          allowEmpty: true,
          fieldEncodings: const {'tags': FormFieldEncoding(explode: true)},
        ),
        const <ParameterEntry>[
          (name: 'tags', value: 'a%2Cb'),
          (name: 'tags', value: 'c'),
        ],
      );
    });

    test('keeps an element comma literal when exploded with allowReserved', () {
      expect(
        <String, PropertyValue>{
          'tags': const PropertyValue.array(['a,b', 'c']),
        }.toForm(
          'p',
          explode: true,
          allowEmpty: true,
          fieldEncodings: const {
            'tags': FormFieldEncoding(explode: true, allowReserved: true),
          },
        ),
        const <ParameterEntry>[
          (name: 'tags', value: 'a,b'),
          (name: 'tags', value: 'c'),
        ],
      );
    });

    test('percent-encodes element commas but keeps separators literal when '
        'non-exploded without allowReserved', () {
      expect(
        <String, PropertyValue>{
          'tags': const PropertyValue.array(['a,b', 'c']),
        }.toForm('p', explode: true, allowEmpty: true),
        const <ParameterEntry>[(name: 'tags', value: 'a%2Cb,c')],
      );
    });
  });

  group('object-level explode=false collapse', () {
    test('collapses scalars and an array into a single comma-joined entry', () {
      expect(
        <String, PropertyValue>{
          'a': const PropertyValue.scalar('1'),
          'colors': const PropertyValue.array(['red', 'green', 'blue']),
        }.toForm('p', explode: false, allowEmpty: true),
        const <ParameterEntry>[(name: 'p', value: 'a,1,colors,red,green,blue')],
      );
    });

    test('ignores fieldEncodings when collapsing', () {
      expect(
        <String, PropertyValue>{
          'a': const PropertyValue.scalar('1'),
          'colors': const PropertyValue.array(['red', 'green', 'blue']),
        }.toForm(
          'p',
          explode: false,
          allowEmpty: true,
          fieldEncodings: const {'colors': FormFieldEncoding(explode: true)},
        ),
        const <ParameterEntry>[(name: 'p', value: 'a,1,colors,red,green,blue')],
      );
    });

    test('ignores a per-property allowReserved when collapsing', () {
      expect(
        <String, PropertyValue>{
          'k/1': const PropertyValue.scalar('a/b'),
        }.toForm(
          'p',
          explode: false,
          allowEmpty: true,
          fieldEncodings: const {'k/1': FormFieldEncoding(allowReserved: true)},
        ),
        const <ParameterEntry>[(name: 'p', value: 'k%2F1,a%2Fb')],
      );
    });

    test('collapses an empty array into an empty value segment', () {
      expect(
        <String, PropertyValue>{
          'colors': const PropertyValue.array([]),
        }.toForm('p', explode: false, allowEmpty: true),
        const <ParameterEntry>[(name: 'p', value: 'colors,')],
      );
    });
  });

  group('allowReserved', () {
    test('applies a per-property override to values and component-encodes '
        'keys', () {
      expect(
        <String, PropertyValue>{
          'a/1': const PropertyValue.scalar('x/y'),
          'b/2': const PropertyValue.scalar('p/q'),
        }.toForm(
          'p',
          explode: true,
          allowEmpty: true,
          fieldEncodings: const {'a/1': FormFieldEncoding(allowReserved: true)},
        ),
        const <ParameterEntry>[
          (name: 'a%2F1', value: 'x/y'),
          (name: 'b%2F2', value: 'p%2Fq'),
        ],
      );
    });

    test('applies an object-level override to values while component-encoding '
        'keys when exploded', () {
      expect(
        <String, PropertyValue>{
          'a/1': const PropertyValue.scalar('a/b'),
          'tags': const PropertyValue.array(['a/b']),
        }.toForm('p', explode: true, allowEmpty: true, allowReserved: true),
        const <ParameterEntry>[
          (name: 'a%2F1', value: 'a/b'),
          (name: 'tags', value: 'a/b'),
        ],
      );
    });

    test('applies an object-level override to values while component-encoding '
        'keys when collapsed', () {
      expect(
        <String, PropertyValue>{
          'k/1': const PropertyValue.scalar('a/b'),
        }.toForm('p', explode: false, allowEmpty: true, allowReserved: true),
        const <ParameterEntry>[(name: 'p', value: 'k%2F1,a/b')],
      );
    });

    test("a descriptor's default allowReserved wins over the object-level "
        'flag', () {
      expect(
        <String, PropertyValue>{
          'tags': const PropertyValue.array(['a/b']),
        }.toForm(
          'p',
          explode: true,
          allowEmpty: true,
          allowReserved: true,
          fieldEncodings: const {'tags': FormFieldEncoding(explode: true)},
        ),
        const <ParameterEntry>[(name: 'tags', value: 'a%2Fb')],
      );
    });

    test('keeps element reserved chars literal joined by literal commas for a '
        'non-exploded array', () {
      expect(
        <String, PropertyValue>{
          'tags': const PropertyValue.array(['a/b', 'c/d']),
        }.toForm('p', explode: true, allowEmpty: true, allowReserved: true),
        const <ParameterEntry>[(name: 'tags', value: 'a/b,c/d')],
      );
    });
  });

  group('useQueryComponent space rendering', () {
    test('renders a space as + when useQueryComponent is true', () {
      expect(
        <String, PropertyValue>{
          'q': const PropertyValue.scalar('a b'),
        }.toForm('p', explode: true, allowEmpty: true, useQueryComponent: true),
        const <ParameterEntry>[(name: 'q', value: 'a+b')],
      );
    });

    test('renders a space as %20 when useQueryComponent is false', () {
      expect(
        <String, PropertyValue>{
          'q': const PropertyValue.scalar('a b'),
        }.toForm('p', explode: true, allowEmpty: true),
        const <ParameterEntry>[(name: 'q', value: 'a%20b')],
      );
    });
  });

  group('EmptyValueException', () {
    test('empty map is omitted regardless of explode and allowEmpty', () {
      expect(
        <String, PropertyValue>{}.toForm(
          'p',
          explode: false,
          allowEmpty: true,
        ),
        const <ParameterEntry>[],
      );
      expect(
        <String, PropertyValue>{}.toForm(
          'p',
          explode: true,
          allowEmpty: true,
        ),
        const <ParameterEntry>[],
      );
      expect(
        <String, PropertyValue>{}.toForm(
          'p',
          explode: false,
          allowEmpty: false,
        ),
        const <ParameterEntry>[],
      );
      expect(
        <String, PropertyValue>{}.toForm(
          'p',
          explode: true,
          allowEmpty: false,
        ),
        const <ParameterEntry>[],
      );
    });

    test('throws on a scalar empty string when allowEmpty is false', () {
      expect(
        () => <String, PropertyValue>{
          'key': const PropertyValue.scalar(''),
        }.toForm('p', explode: true, allowEmpty: false),
        throwsA(isA<EmptyValueException>()),
      );
    });

    test('does not throw on a scalar empty string when allowEmpty is true', () {
      expect(
        <String, PropertyValue>{
          'key': const PropertyValue.scalar(''),
        }.toForm('p', explode: true, allowEmpty: true),
        const <ParameterEntry>[(name: 'key', value: '')],
      );
    });

    test('throws on an empty array when allowEmpty is false', () {
      expect(
        () => <String, PropertyValue>{
          'tags': const PropertyValue.array([]),
        }.toForm('p', explode: true, allowEmpty: false),
        throwsA(isA<EmptyValueException>()),
      );
    });

    test('does not throw on an empty array when allowEmpty is true', () {
      expect(
        <String, PropertyValue>{
          'tags': const PropertyValue.array([]),
        }.toForm(
          'p',
          explode: true,
          allowEmpty: true,
          fieldEncodings: const {'tags': FormFieldEncoding(explode: true)},
        ),
        const <ParameterEntry>[],
      );
    });

    test('throws on an empty exploded array descriptor when allowEmpty is '
        'false', () {
      expect(
        () => <String, PropertyValue>{
          'tags': const PropertyValue.array([]),
        }.toForm(
          'p',
          explode: true,
          allowEmpty: false,
          fieldEncodings: const {'tags': FormFieldEncoding(explode: true)},
        ),
        throwsA(isA<EmptyValueException>()),
      );
    });
  });
}
