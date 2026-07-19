import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  group('StringMapDelimitedEncoder.toPipeDelimited', () {
    test('flattens alternating key/value tokens joined by literal pipe', () {
      const value = {'R': '100', 'G': '200', 'B': '150'};
      expect(
        value.toPipeDelimited('color', allowEmpty: true),
        [(name: 'color', value: 'R|100|G|200|B|150')],
      );
    });

    test('uri-encodes keys and values while keeping the pipe literal', () {
      const value = {'note': 'a b', 'op': 'x=y'};
      expect(
        value.toPipeDelimited('color', allowEmpty: true),
        [(name: 'color', value: 'note|a%20b|op|x%3Dy')],
      );
    });

    test('percent-encodes a pipe inside a value, keeping the delimiter literal',
        () {
      const value = {'a': 'x|y'};
      expect(
        value.toPipeDelimited('color', allowEmpty: true),
        [(name: 'color', value: 'a|x%7Cy')],
      );
    });

    test('percent-encodes reserved key and value chars without allowReserved',
        () {
      const value = {'a/b': 'a/b:c'};
      expect(
        value.toPipeDelimited('color', allowEmpty: true),
        [(name: 'color', value: 'a%2Fb|a%2Fb%3Ac')],
      );
    });

    test('keeps reserved key and value chars literal with allowReserved', () {
      const value = {'a/b': 'a/b:c'};
      expect(
        value.toPipeDelimited('color', allowEmpty: true, allowReserved: true),
        [(name: 'color', value: 'a/b|a/b:c')],
      );
    });

    test('omits an empty map when allowEmpty=true', () {
      const value = <String, String>{};
      expect(
        value.toPipeDelimited('color', allowEmpty: true),
        <ParameterEntry>[],
      );
    });

    test('empty map throws with allowEmpty=false', () {
      const value = <String, String>{};
      expect(
        () => value.toPipeDelimited('color', allowEmpty: false),
        throwsA(isA<EmptyValueException>()),
      );
    });
  });

  group('StringMapDelimitedEncoder.toSpaceDelimited', () {
    test('flattens alternating key/value tokens joined by %20', () {
      const value = {'R': '100', 'G': '200', 'B': '150'};
      expect(
        value.toSpaceDelimited('coord', allowEmpty: true),
        [(name: 'coord', value: 'R%20100%20G%20200%20B%20150')],
      );
    });

    test('a space inside a value becomes %20, matching the delimiter', () {
      const value = {'a': 'x y'};
      expect(
        value.toSpaceDelimited('coord', allowEmpty: true),
        [(name: 'coord', value: 'a%20x%20y')],
      );
    });

    test('percent-encodes reserved key and value chars without allowReserved',
        () {
      const value = {'a/b': 'a/b:c'};
      expect(
        value.toSpaceDelimited('coord', allowEmpty: true),
        [(name: 'coord', value: 'a%2Fb%20a%2Fb%3Ac')],
      );
    });

    test('keeps reserved key and value chars literal with allowReserved', () {
      const value = {'a/b': 'a/b:c'};
      expect(
        value.toSpaceDelimited('coord', allowEmpty: true, allowReserved: true),
        [(name: 'coord', value: 'a/b%20a/b:c')],
      );
    });

    test('omits an empty map when allowEmpty=true', () {
      const value = <String, String>{};
      expect(
        value.toSpaceDelimited('coord', allowEmpty: true),
        <ParameterEntry>[],
      );
    });

    test('empty map throws with allowEmpty=false', () {
      const value = <String, String>{};
      expect(
        () => value.toSpaceDelimited('coord', allowEmpty: false),
        throwsA(isA<EmptyValueException>()),
      );
    });
  });
}
