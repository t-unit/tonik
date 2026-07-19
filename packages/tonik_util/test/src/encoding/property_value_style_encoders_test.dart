import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  group('PropertyValueStyleEncoders.toUri', () {
    test('encodes scalar pairs once and keeps separators literal', () {
      const value = {
        'a/b': PropertyValue.scalar('x=y'),
        'empty': PropertyValue.scalar(''),
      };

      expect(
        value.toUri(allowEmpty: true),
        'a%2Fb,x%3Dy,empty,',
      );
    });

    test('preserves reserved values when requested', () {
      const value = {'formula': PropertyValue.scalar('x/y?z')};

      expect(
        value.toUri(allowEmpty: true, allowReserved: true),
        'formula,x/y?z',
      );
    });

    test('empty scalar beside a filled scalar renders with allowEmpty=false',
        () {
      const value = {
        'color': PropertyValue.scalar(''),
        'size': PropertyValue.scalar('xl'),
      };
      expect(value.toUri(allowEmpty: false), 'color,,size,xl');
    });
  });

  group('PropertyValueStyleEncoders.toSimple', () {
    test('scalar object with explode=false matches the string-map counterpart',
        () {
      const value = {
        'color': PropertyValue.scalar('blue'),
        'size': PropertyValue.scalar('large'),
      };
      expect(
        value.toSimple(explode: false, allowEmpty: true),
        'color,blue,size,large',
      );
    });

    test('scalar object with explode=true matches the string-map counterpart',
        () {
      const value = {
        'color': PropertyValue.scalar('blue'),
        'size': PropertyValue.scalar('large'),
      };
      expect(
        value.toSimple(explode: true, allowEmpty: true),
        'color=blue,size=large',
      );
    });

    test('reserved characters in scalar values are percent-encoded', () {
      const value = {'formula': PropertyValue.scalar('x=y+z')};
      expect(
        value.toSimple(explode: true, allowEmpty: true),
        'formula=x%3Dy%2Bz',
      );
    });

    test('reserved characters in keys are percent-encoded', () {
      const value = {'a/b': PropertyValue.scalar('v')};
      expect(
        value.toSimple(explode: false, allowEmpty: false),
        'a%2Fb,v',
      );
    });

    test('array beside a scalar comma-joins with explode=false', () {
      const value = {
        'a': PropertyValue.scalar('x'),
        'tags': PropertyValue.array(['t1', 't2']),
      };
      expect(
        value.toSimple(explode: false, allowEmpty: true),
        'a,x,tags,t1,t2',
      );
    });

    test('array beside a scalar comma-joins with explode=true', () {
      const value = {
        'a': PropertyValue.scalar('x'),
        'tags': PropertyValue.array(['t1', 't2']),
      };
      expect(
        value.toSimple(explode: true, allowEmpty: true),
        'a=x,tags=t1,t2',
      );
    });

    test('comma inside an element is percent-encoded, separator stays literal',
        () {
      const value = {
        'k': PropertyValue.array(['a,b', 'c']),
      };
      expect(
        value.toSimple(explode: true, allowEmpty: true),
        'k=a%2Cb,c',
      );
    });

    test('empty map renders empty string with allowEmpty=true', () {
      const value = <String, PropertyValue>{};
      expect(value.toSimple(explode: false, allowEmpty: true), '');
      expect(value.toSimple(explode: true, allowEmpty: true), '');
    });

    test('empty map throws with allowEmpty=false', () {
      const value = <String, PropertyValue>{};
      expect(
        () => value.toSimple(explode: false, allowEmpty: false),
        throwsA(isA<EmptyValueException>()),
      );
      expect(
        () => value.toSimple(explode: true, allowEmpty: false),
        throwsA(isA<EmptyValueException>()),
      );
    });

    test('empty scalar renders with allowEmpty=true', () {
      const value = {'k': PropertyValue.scalar('')};
      expect(value.toSimple(explode: false, allowEmpty: true), 'k,');
      expect(value.toSimple(explode: true, allowEmpty: true), 'k=');
    });

    test('empty scalar renders with allowEmpty=false', () {
      const value = {'k': PropertyValue.scalar('')};
      expect(value.toSimple(explode: false, allowEmpty: false), 'k,');
      expect(value.toSimple(explode: true, allowEmpty: false), 'k=');
    });

    test('empty array renders empty value with allowEmpty=false', () {
      const value = {'k': PropertyValue.array(<String>[])};
      expect(value.toSimple(explode: false, allowEmpty: false), 'k,');
      expect(value.toSimple(explode: true, allowEmpty: false), 'k=');
    });

    test('empty scalar beside a filled scalar renders with allowEmpty=false',
        () {
      const value = {
        'color': PropertyValue.scalar(''),
        'size': PropertyValue.scalar('xl'),
      };
      expect(
        value.toSimple(explode: false, allowEmpty: false),
        'color,,size,xl',
      );
      expect(
        value.toSimple(explode: true, allowEmpty: false),
        'color=,size=xl',
      );
    });

    test('empty array renders empty value with allowEmpty=true', () {
      const value = {'k': PropertyValue.array(<String>[])};
      expect(value.toSimple(explode: false, allowEmpty: true), 'k,');
      expect(value.toSimple(explode: true, allowEmpty: true), 'k=');
    });

    test('single empty-string element is not an empty array and never throws',
        () {
      const value = {
        'k': PropertyValue.array(['']),
      };
      expect(value.toSimple(explode: false, allowEmpty: false), 'k,');
      expect(value.toSimple(explode: true, allowEmpty: false), 'k=');
    });

    test('literal leaves reserved keys and values unencoded with '
        'explode=false', () {
      const value = {
        'a/b': PropertyValue.scalar('x=y+z'),
        'tags': PropertyValue.array(['a,b', 'c d']),
      };
      expect(
        value.toSimple(explode: false, allowEmpty: true, literal: true),
        'a/b,x=y+z,tags,a,b,c d',
      );
    });

    test('literal leaves reserved keys and values unencoded with '
        'explode=true', () {
      const value = {
        'a/b': PropertyValue.scalar('x=y+z'),
        'tags': PropertyValue.array(['a,b', 'c d']),
      };
      expect(
        value.toSimple(explode: true, allowEmpty: true, literal: true),
        'a/b=x=y+z,tags=a,b,c d',
      );
    });
  });

  group('PropertyValueStyleEncoders.toLabel', () {
    test('scalar object with explode=false matches the string-map counterpart',
        () {
      const value = {
        'x': PropertyValue.scalar('1'),
        'y': PropertyValue.scalar('2'),
      };
      expect(value.toLabel(explode: false, allowEmpty: true), '.x,1,y,2');
    });

    test('scalar object with explode=true matches the string-map counterpart',
        () {
      const value = {
        'x': PropertyValue.scalar('1'),
        'y': PropertyValue.scalar('2'),
      };
      expect(value.toLabel(explode: true, allowEmpty: true), '.x=1.y=2');
    });

    test('reserved characters in scalar values are percent-encoded', () {
      const value = {
        'street': PropertyValue.scalar('123 Main St'),
        'city': PropertyValue.scalar('New York'),
      };
      expect(
        value.toLabel(explode: true, allowEmpty: true),
        '.street=123%20Main%20St.city=New%20York',
      );
    });

    test('reserved characters in keys are percent-encoded', () {
      const value = {'a/b': PropertyValue.scalar('v')};
      expect(
        value.toLabel(explode: false, allowEmpty: false),
        '.a%2Fb,v',
      );
    });

    test('array beside a scalar comma-joins with explode=false', () {
      const value = {
        'a': PropertyValue.scalar('x'),
        'tags': PropertyValue.array(['t1', 't2']),
      };
      expect(
        value.toLabel(explode: false, allowEmpty: true),
        '.a,x,tags,t1,t2',
      );
    });

    test('array beside a scalar comma-joins with explode=true', () {
      const value = {
        'a': PropertyValue.scalar('x'),
        'tags': PropertyValue.array(['t1', 't2']),
      };
      expect(value.toLabel(explode: true, allowEmpty: true), '.a=x.tags=t1,t2');
    });

    test('comma inside an element is percent-encoded, separator stays literal',
        () {
      const value = {
        'k': PropertyValue.array(['a,b', 'c']),
      };
      expect(value.toLabel(explode: true, allowEmpty: true), '.k=a%2Cb,c');
    });

    test('empty map renders . with allowEmpty=true', () {
      const value = <String, PropertyValue>{};
      expect(value.toLabel(explode: false, allowEmpty: true), '.');
      expect(value.toLabel(explode: true, allowEmpty: true), '.');
    });

    test('empty map throws with allowEmpty=false', () {
      const value = <String, PropertyValue>{};
      expect(
        () => value.toLabel(explode: false, allowEmpty: false),
        throwsA(isA<EmptyValueException>()),
      );
      expect(
        () => value.toLabel(explode: true, allowEmpty: false),
        throwsA(isA<EmptyValueException>()),
      );
    });

    test('empty scalar renders with allowEmpty=true', () {
      const value = {'k': PropertyValue.scalar('')};
      expect(value.toLabel(explode: false, allowEmpty: true), '.k,');
      expect(value.toLabel(explode: true, allowEmpty: true), '.k=');
    });

    test('empty scalar renders with allowEmpty=false', () {
      const value = {'k': PropertyValue.scalar('')};
      expect(value.toLabel(explode: false, allowEmpty: false), '.k,');
      expect(value.toLabel(explode: true, allowEmpty: false), '.k=');
    });

    test('empty array renders empty value with allowEmpty=false', () {
      const value = {'k': PropertyValue.array(<String>[])};
      expect(value.toLabel(explode: false, allowEmpty: false), '.k,');
      expect(value.toLabel(explode: true, allowEmpty: false), '.k=');
    });

    test('empty scalar beside a filled scalar renders with allowEmpty=false',
        () {
      const value = {
        'color': PropertyValue.scalar(''),
        'size': PropertyValue.scalar('xl'),
      };
      expect(
        value.toLabel(explode: false, allowEmpty: false),
        '.color,,size,xl',
      );
      expect(
        value.toLabel(explode: true, allowEmpty: false),
        '.color=.size=xl',
      );
    });

    test('single empty-string element is not an empty array and never throws',
        () {
      const value = {
        'k': PropertyValue.array(['']),
      };
      expect(value.toLabel(explode: false, allowEmpty: false), '.k,');
      expect(value.toLabel(explode: true, allowEmpty: false), '.k=');
    });
  });

  group('PropertyValueStyleEncoders.toMatrix', () {
    test('scalar object with explode=false matches the string-map counterpart',
        () {
      const value = {
        'x': PropertyValue.scalar('1'),
        'y': PropertyValue.scalar('2'),
      };
      expect(
        value.toMatrix('point', explode: false, allowEmpty: true),
        ';point=x,1,y,2',
      );
    });

    test('scalar object with explode=true matches the string-map counterpart',
        () {
      const value = {
        'x': PropertyValue.scalar('1'),
        'y': PropertyValue.scalar('2'),
      };
      expect(
        value.toMatrix('point', explode: true, allowEmpty: true),
        ';x=1;y=2',
      );
    });

    test('reserved characters in keys and values are percent-encoded', () {
      const value = {
        'key & name': PropertyValue.scalar('value,test'),
        'other': PropertyValue.scalar('normal'),
      };
      expect(
        value.toMatrix('data', explode: true, allowEmpty: true),
        ';key%20%26%20name=value%2Ctest;other=normal',
      );
    });

    test('array beside a scalar comma-joins with explode=false', () {
      const value = {
        'a': PropertyValue.scalar('x'),
        'tags': PropertyValue.array(['t1', 't2']),
      };
      expect(
        value.toMatrix('p', explode: false, allowEmpty: true),
        ';p=a,x,tags,t1,t2',
      );
    });

    test('array beside a scalar comma-joins with explode=true', () {
      const value = {
        'a': PropertyValue.scalar('x'),
        'tags': PropertyValue.array(['t1', 't2']),
      };
      expect(
        value.toMatrix('p', explode: true, allowEmpty: true),
        ';a=x;tags=t1,t2',
      );
    });

    test('comma inside an element is percent-encoded, separator stays literal',
        () {
      const value = {
        'k': PropertyValue.array(['a,b', 'c']),
      };
      expect(
        value.toMatrix('p', explode: true, allowEmpty: true),
        ';k=a%2Cb,c',
      );
    });

    test('empty map renders ;paramName with allowEmpty=true', () {
      const value = <String, PropertyValue>{};
      expect(value.toMatrix('point', explode: false, allowEmpty: true),
          ';point');
      expect(
          value.toMatrix('point', explode: true, allowEmpty: true), ';point');
    });

    test('empty map throws with allowEmpty=false', () {
      const value = <String, PropertyValue>{};
      expect(
        () => value.toMatrix('point', explode: false, allowEmpty: false),
        throwsA(isA<EmptyValueException>()),
      );
      expect(
        () => value.toMatrix('point', explode: true, allowEmpty: false),
        throwsA(isA<EmptyValueException>()),
      );
    });

    test('empty scalar renders name-only when exploded with allowEmpty=true',
        () {
      const value = {'k': PropertyValue.scalar('')};
      expect(value.toMatrix('p', explode: false, allowEmpty: true), ';p=k,');
      expect(value.toMatrix('p', explode: true, allowEmpty: true), ';k');
    });

    test('empty scalar renders name-only when exploded with allowEmpty=false',
        () {
      const value = {'k': PropertyValue.scalar('')};
      expect(value.toMatrix('p', explode: false, allowEmpty: false), ';p=k,');
      expect(value.toMatrix('p', explode: true, allowEmpty: false), ';k');
    });

    test('empty array renders name-only when exploded with allowEmpty=false',
        () {
      const value = {'k': PropertyValue.array(<String>[])};
      expect(value.toMatrix('p', explode: false, allowEmpty: false), ';p=k,');
      expect(value.toMatrix('p', explode: true, allowEmpty: false), ';k');
    });

    test('empty scalar beside a filled scalar renders with allowEmpty=false',
        () {
      const value = {
        'color': PropertyValue.scalar(''),
        'size': PropertyValue.scalar('xl'),
      };
      expect(
        value.toMatrix('filter', explode: false, allowEmpty: false),
        ';filter=color,,size,xl',
      );
      expect(
        value.toMatrix('filter', explode: true, allowEmpty: false),
        ';color;size=xl',
      );
    });

    test('single empty-string element is not an empty array and never throws',
        () {
      const value = {
        'k': PropertyValue.array(['']),
      };
      expect(value.toMatrix('p', explode: false, allowEmpty: false), ';p=k,');
      expect(value.toMatrix('p', explode: true, allowEmpty: false), ';k=');
    });
  });

  group('PropertyValueStyleEncoders.toRawStyleParts', () {
    test('exploded object emits one raw part per key', () {
      const value = {
        'note': PropertyValue.scalar('a b'),
        'query': PropertyValue.scalar('m&n=o?p'),
      };
      expect(value.toRawStyleParts('obj', explode: true), [
        (name: 'note', value: 'a b'),
        (name: 'query', value: 'm&n=o?p'),
      ]);
    });

    test('exploded array values join elements with commas, raw', () {
      const value = {
        'tags': PropertyValue.array(['x y', 'z&w']),
      };
      expect(value.toRawStyleParts('obj', explode: true), [
        (name: 'tags', value: 'x y,z&w'),
      ]);
    });

    test('non-exploded object emits one raw comma-joined part', () {
      const value = {
        'a': PropertyValue.scalar('1 2'),
        'b': PropertyValue.scalar('3&4'),
      };
      expect(value.toRawStyleParts('obj', explode: false), [
        (name: 'obj', value: 'a,1 2,b,3&4'),
      ]);
    });

    test('non-exploded array values join inside the expansion', () {
      const value = {
        'tags': PropertyValue.array(['x', 'y']),
      };
      expect(value.toRawStyleParts('obj', explode: false), [
        (name: 'obj', value: 'tags,x,y'),
      ]);
    });

    test('empty-string scalar values stay defined', () {
      const value = {'note': PropertyValue.scalar('')};
      expect(value.toRawStyleParts('obj', explode: true), [
        (name: 'note', value: ''),
      ]);
    });

    test('empty exploded object emits no parts', () {
      const value = <String, PropertyValue>{};
      expect(value.toRawStyleParts('obj', explode: true), isEmpty);
    });

    test('empty non-exploded object emits one empty part', () {
      const value = <String, PropertyValue>{};
      expect(value.toRawStyleParts('obj', explode: false), [
        (name: 'obj', value: ''),
      ]);
    });
  });

  group('PropertyValueStyleEncoders.toDeepObject', () {
    test('scalar object produces bracketed name entries', () {
      const value = {
        'x': PropertyValue.scalar('1'),
        'y': PropertyValue.scalar('2'),
      };
      expect(
        value.toDeepObject('point', explode: true, allowEmpty: true),
        [
          (name: 'point[x]', value: '1'),
          (name: 'point[y]', value: '2'),
        ],
      );
    });

    test('keys are component-encoded, brackets stay literal', () {
      const value = {'a b': PropertyValue.scalar('v')};
      expect(
        value.toDeepObject('f', explode: true, allowEmpty: true),
        [(name: 'f[a%20b]', value: 'v')],
      );
    });

    test('reserved characters in values are percent-encoded without '
        'allowReserved', () {
      const value = {'path': PropertyValue.scalar('a/b:c')};
      expect(
        value.toDeepObject('filter', explode: true, allowEmpty: true),
        [(name: 'filter[path]', value: 'a%2Fb%3Ac')],
      );
    });

    test('reserved characters in values stay literal with allowReserved', () {
      const value = {'path': PropertyValue.scalar('a/b:c')};
      expect(
        value.toDeepObject(
          'filter',
          explode: true,
          allowEmpty: true,
          allowReserved: true,
        ),
        [(name: 'filter[path]', value: 'a/b:c')],
      );
    });

    test('reserved characters in keys stay component-encoded with '
        'allowReserved', () {
      const value = {'a/b': PropertyValue.scalar('x/y')};
      expect(
        value.toDeepObject(
          'p',
          explode: true,
          allowEmpty: false,
          allowReserved: true,
        ),
        const <ParameterEntry>[(name: 'p[a%2Fb]', value: 'x/y')],
      );
    });

    test('array value throws with the list-unsupported message', () {
      const value = {
        'a': PropertyValue.scalar('x'),
        'tags': PropertyValue.array(['t1', 't2']),
      };
      expect(
        () => value.toDeepObject('p', explode: true, allowEmpty: true),
        throwsA(
          isA<EncodingException>().having(
            (e) => e.message,
            'message',
            'Lists are not supported in this encoding style',
          ),
        ),
      );
    });

    test('empty array throws the list-unsupported message, not empty-value',
        () {
      const value = {'k': PropertyValue.array(<String>[])};
      expect(
        () => value.toDeepObject('p', explode: true, allowEmpty: false),
        throwsA(
          isA<EncodingException>().having(
            (e) => e.message,
            'message',
            'Lists are not supported in this encoding style',
          ),
        ),
      );
    });

    test('explode=false throws', () {
      const value = {'x': PropertyValue.scalar('1')};
      expect(
        () => value.toDeepObject('p', explode: false, allowEmpty: true),
        throwsA(
          isA<EncodingException>().having(
            (e) => e.message,
            'message',
            'deepObject style requires explode=true',
          ),
        ),
      );
    });

    test('empty map renders empty list with allowEmpty=true', () {
      const value = <String, PropertyValue>{};
      expect(
        value.toDeepObject('p', explode: true, allowEmpty: true),
        <ParameterEntry>[],
      );
    });

    test('empty map throws with allowEmpty=false', () {
      const value = <String, PropertyValue>{};
      expect(
        () => value.toDeepObject('p', explode: true, allowEmpty: false),
        throwsA(isA<EmptyValueException>()),
      );
    });

    test('empty scalar renders empty value with allowEmpty=true', () {
      const value = {'k': PropertyValue.scalar('')};
      expect(
        value.toDeepObject('p', explode: true, allowEmpty: true),
        [(name: 'p[k]', value: '')],
      );
    });

    test('empty scalar throws with allowEmpty=false', () {
      const value = {'k': PropertyValue.scalar('')};
      expect(
        () => value.toDeepObject('p', explode: true, allowEmpty: false),
        throwsA(isA<EmptyValueException>()),
      );
    });
  });

  group('PropertyValueStyleEncoders.toPipeDelimited', () {
    test('flattens alternating key/value tokens joined by literal pipe', () {
      const value = {
        'R': PropertyValue.scalar('100'),
        'G': PropertyValue.scalar('200'),
        'B': PropertyValue.scalar('150'),
      };
      expect(
        value.toPipeDelimited('color', allowEmpty: true),
        [(name: 'color', value: 'R|100|G|200|B|150')],
      );
    });

    test('uri-encodes values while keeping the pipe delimiter literal', () {
      const value = {
        'note': PropertyValue.scalar('a b'),
        'op': PropertyValue.scalar('x=y'),
      };
      expect(
        value.toPipeDelimited('color', allowEmpty: true),
        [(name: 'color', value: 'note|a%20b|op|x%3Dy')],
      );
    });

    test('joins array elements with the pipe delimiter', () {
      const value = {
        'tags': PropertyValue.array(['a', 'b']),
      };
      expect(
        value.toPipeDelimited('color', allowEmpty: true),
        [(name: 'color', value: 'tags|a|b')],
      );
    });

    test('percent-encodes reserved key and value chars without allowReserved',
        () {
      const value = {'a/b': PropertyValue.scalar('a/b:c')};
      expect(
        value.toPipeDelimited('color', allowEmpty: true),
        [(name: 'color', value: 'a%2Fb|a%2Fb%3Ac')],
      );
    });

    test('keeps reserved key and value chars literal with allowReserved', () {
      const value = {'a/b': PropertyValue.scalar('a/b:c')};
      expect(
        value.toPipeDelimited('color', allowEmpty: true, allowReserved: true),
        [(name: 'color', value: 'a/b|a/b:c')],
      );
    });

    test('percent-encodes a pipe inside a value, keeping the delimiter literal',
        () {
      const value = {'a': PropertyValue.scalar('x|y')};
      expect(
        value.toPipeDelimited('color', allowEmpty: true),
        [(name: 'color', value: 'a|x%7Cy')],
      );
    });

    test('omits an empty object when allowEmpty=true', () {
      const value = <String, PropertyValue>{};
      expect(
        value.toPipeDelimited('color', allowEmpty: true),
        <ParameterEntry>[],
      );
    });

    test('empty object throws with allowEmpty=false', () {
      const value = <String, PropertyValue>{};
      expect(
        () => value.toPipeDelimited('color', allowEmpty: false),
        throwsA(isA<EmptyValueException>()),
      );
    });
  });

  group('PropertyValueStyleEncoders.toSpaceDelimited', () {
    test('flattens alternating key/value tokens joined by %20', () {
      const value = {
        'R': PropertyValue.scalar('100'),
        'G': PropertyValue.scalar('200'),
        'B': PropertyValue.scalar('150'),
      };
      expect(
        value.toSpaceDelimited('coord', allowEmpty: true),
        [(name: 'coord', value: 'R%20100%20G%20200%20B%20150')],
      );
    });

    test('uri-encodes values while keeping the space delimiter as %20', () {
      const value = {'op': PropertyValue.scalar('x=y')};
      expect(
        value.toSpaceDelimited('coord', allowEmpty: true),
        [(name: 'coord', value: 'op%20x%3Dy')],
      );
    });

    test('joins array elements with the space delimiter', () {
      const value = {
        'tags': PropertyValue.array(['a', 'b']),
      };
      expect(
        value.toSpaceDelimited('coord', allowEmpty: true),
        [(name: 'coord', value: 'tags%20a%20b')],
      );
    });

    test('percent-encodes reserved key and value chars without allowReserved',
        () {
      const value = {'a/b': PropertyValue.scalar('a/b:c')};
      expect(
        value.toSpaceDelimited('coord', allowEmpty: true),
        [(name: 'coord', value: 'a%2Fb%20a%2Fb%3Ac')],
      );
    });

    test('keeps reserved key and value chars literal with allowReserved', () {
      const value = {'a/b': PropertyValue.scalar('a/b:c')};
      expect(
        value.toSpaceDelimited('coord', allowEmpty: true, allowReserved: true),
        [(name: 'coord', value: 'a/b%20a/b:c')],
      );
    });

    test('a space inside a value becomes %20, matching the delimiter', () {
      const value = {'a': PropertyValue.scalar('x y')};
      expect(
        value.toSpaceDelimited('coord', allowEmpty: true),
        [(name: 'coord', value: 'a%20x%20y')],
      );
    });

    test('omits an empty object when allowEmpty=true', () {
      const value = <String, PropertyValue>{};
      expect(
        value.toSpaceDelimited('coord', allowEmpty: true),
        <ParameterEntry>[],
      );
    });

    test('empty object throws with allowEmpty=false', () {
      const value = <String, PropertyValue>{};
      expect(
        () => value.toSpaceDelimited('coord', allowEmpty: false),
        throwsA(isA<EmptyValueException>()),
      );
    });
  });
}
