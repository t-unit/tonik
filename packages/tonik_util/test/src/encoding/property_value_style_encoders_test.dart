import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
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

    test('empty scalar throws with allowEmpty=false', () {
      const value = {'k': PropertyValue.scalar('')};
      expect(
        () => value.toSimple(explode: false, allowEmpty: false),
        throwsA(isA<EmptyValueException>()),
      );
    });

    test('empty array throws with allowEmpty=false', () {
      const value = {'k': PropertyValue.array(<String>[])};
      expect(
        () => value.toSimple(explode: false, allowEmpty: false),
        throwsA(isA<EmptyValueException>()),
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

    test('empty scalar throws with allowEmpty=false', () {
      const value = {'k': PropertyValue.scalar('')};
      expect(
        () => value.toLabel(explode: false, allowEmpty: false),
        throwsA(isA<EmptyValueException>()),
      );
    });

    test('empty array throws with allowEmpty=false', () {
      const value = {'k': PropertyValue.array(<String>[])};
      expect(
        () => value.toLabel(explode: false, allowEmpty: false),
        throwsA(isA<EmptyValueException>()),
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

    test('empty scalar renders with allowEmpty=true', () {
      const value = {'k': PropertyValue.scalar('')};
      expect(value.toMatrix('p', explode: false, allowEmpty: true), ';p=k,');
      expect(value.toMatrix('p', explode: true, allowEmpty: true), ';k=');
    });

    test('empty scalar throws with allowEmpty=false', () {
      const value = {'k': PropertyValue.scalar('')};
      expect(
        () => value.toMatrix('p', explode: false, allowEmpty: false),
        throwsA(isA<EmptyValueException>()),
      );
    });

    test('empty array throws with allowEmpty=false', () {
      const value = {'k': PropertyValue.array(<String>[])};
      expect(
        () => value.toMatrix('p', explode: false, allowEmpty: false),
        throwsA(isA<EmptyValueException>()),
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
}
