import 'dart:convert';

import 'package:form_urlencoded_api/form_urlencoded_api.dart';
import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  test('oneOf toForm preserves per-field allowReserved', () {
    const form = OneOfArrayBodyFormArrayBodyForm(
      ArrayBodyForm(q: 'a/b?c', tags: ['x/y']),
    );

    expect(
      form.toForm(
        'body',
        explode: true,
        allowEmpty: true,
        textEncoding: utf8,
        fieldEncodings: const {'q': FormFieldEncoding(allowReserved: true)},
      ),
      [(name: 'q', value: 'a/b?c'), (name: 'tags', value: 'x%2Fy')],
    );
  });

  test('oneOf toForm preserves per-field explode', () {
    const form = OneOfArrayBodyFormArrayBodyForm(
      ArrayBodyForm(q: 'hello', tags: ['a,b', 'c']),
    );

    expect(
      form.toForm(
        'body',
        explode: true,
        allowEmpty: true,
        textEncoding: utf8,
        fieldEncodings: const {'tags': FormFieldEncoding(explode: true)},
      ),
      [
        (name: 'q', value: 'hello'),
        (name: 'tags', value: 'a%2Cb'),
        (name: 'tags', value: 'c'),
      ],
    );
  });
}
