import 'dart:convert';

import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  test('merges nested multipart object values without losing fields', () {
    final value = mergeMultipartValues(
      [
        {
          'id': 'upload-1',
          'metadata': {'source': 'base'},
        },
        {
          'metadata': {
            'annotations': {
              'labels': ['one', 'two'],
            },
          },
        },
      ],
      propertyName: 'metadata',
      mergeObjects: true,
    );

    expect(value, {
      'id': 'upload-1',
      'metadata': {
        'source': 'base',
        'annotations': {
          'labels': ['one', 'two'],
        },
      },
    });
  });

  test('combines repeated lists in occurrence and element order', () {
    expect(
      mergeMultipartValues([
        [1, 2],
        [3, 4],
      ], propertyName: 'files'),
      [1, 2, 3, 4],
    );
  });

  test('combines non-List iterables in contribution order', () {
    expect(
      mergeMultipartValues([
        [1, 2].where((value) => value > 0),
        [3, 4].where((value) => value > 0),
      ], propertyName: 'files'),
      [1, 2, 3, 4],
    );
  });

  test('typed list merging preserves its element type and order', () {
    final value = mergeMultipartLists<String>([
      const ['one', 'two'],
      const ['three'],
    ], propertyName: 'tags');

    expect(value, ['one', 'two', 'three']);
    expect(value, isA<List<String>>());
  });

  test('generic merging compares enum occurrences from one generated type', () {
    expect(
      mergeMultipartValues(const [
        _Status.ready,
        _Status.ready,
      ], propertyName: 'status'),
      _Status.ready,
    );
    expect(
      () => mergeMultipartValues(const [
        _Status.ready,
        _Status.complete,
      ], propertyName: 'status'),
      throwsA(isA<EncodingException>()),
    );
  });

  test('styled object merging accepts equal scalar payloads', () {
    expect(
      mergeMultipartPropertyValues([
        const {'id': PropertyValue.scalar('same')},
        const {'id': PropertyValue.scalar('same')},
      ], propertyName: 'metadata'),
      const {'id': PropertyValue.scalar('same')},
    );
  });

  test('styled object merging concatenates array payloads in order', () {
    final value = mergeMultipartPropertyValues([
      const {
        'labels': PropertyValue.array(['one', 'two']),
      },
      const {
        'labels': PropertyValue.array(['three', 'four']),
      },
    ], propertyName: 'metadata');

    expect((value!['labels']! as ArrayPropertyValue).values, [
      'one',
      'two',
      'three',
      'four',
    ]);
  });

  test('merged styled objects retain form and deepObject behavior', () {
    final value = mergeMultipartPropertyValues([
      const {
        'id': PropertyValue.scalar('same'),
        'labels': PropertyValue.array(['one']),
      },
      const {
        'id': PropertyValue.scalar('same'),
        'labels': PropertyValue.array(['two']),
      },
    ], propertyName: 'metadata')!;

    expect(value.toRawStyleParts('metadata', explode: true), [
      (name: 'id', value: 'same'),
      (name: 'labels', value: 'one,two'),
    ]);
    expect(
      value.toForm(
        'metadata',
        explode: true,
        allowEmpty: true,
        textEncoding: utf8,
      ),
      [(name: 'id', value: 'same'), (name: 'labels', value: 'one,two')],
    );

    final scalarValue = mergeMultipartPropertyValues([
      const {
        'id': PropertyValue.scalar('same'),
        'left': PropertyValue.scalar('one'),
      },
      const {
        'id': PropertyValue.scalar('same'),
        'right': PropertyValue.scalar('two'),
      },
    ], propertyName: 'metadata')!;
    expect(
      scalarValue.toDeepObject('metadata', explode: true, allowEmpty: true),
      [
        (name: 'metadata[id]', value: 'same'),
        (name: 'metadata[left]', value: 'one'),
        (name: 'metadata[right]', value: 'two'),
      ],
    );
  });

  test('styled object merging rejects unequal scalar payloads', () {
    expect(
      () => mergeMultipartPropertyValues([
        const {'id': PropertyValue.scalar('left')},
        const {'id': PropertyValue.scalar('right')},
      ], propertyName: 'metadata'),
      throwsA(isA<EncodingException>()),
    );
  });

  test('styled object merging rejects scalar and array payloads', () {
    expect(
      () => mergeMultipartPropertyValues([
        const {'label': PropertyValue.scalar('one')},
        const {
          'label': PropertyValue.array(['one']),
        },
      ], propertyName: 'metadata'),
      throwsA(isA<EncodingException>()),
    );
  });

  test('merges repeated map values and nested iterables', () {
    expect(
      mergeMultipartValues(
        [
          {
            'base': true,
            'labels': [1, 2],
          },
          {
            'annotation': 'value',
            'labels': [3, 4].where((value) => value > 0),
          },
        ],
        propertyName: 'metadata',
        mergeObjects: true,
      ),
      {
        'base': true,
        'labels': [1, 2, 3, 4],
        'annotation': 'value',
      },
    );
  });

  test('rejects conflicting nested values before transport encoding', () {
    expect(
      () => mergeMultipartValues(
        [
          {'id': 'first'},
          {'id': 'second'},
        ],
        propertyName: 'metadata',
        mergeObjects: true,
      ),
      throwsA(isA<EncodingException>()),
    );
  });
}

enum _Status { ready, complete }
