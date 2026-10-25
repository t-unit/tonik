import 'package:defs_api/defs_api.dart';
import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  test('deep and escaped schema pointers retain their value types', () {
    final value = DeepUse.fromJson(const {
      'id': 42,
      'slash': 'hello',
      'child': {'next': <String, Object?>{}},
    });

    expect(value.id, 42);
    expect(value.slash, 'hello');
    expect(value.child?.next, isNotNull);
    expect(value.toJson(), {
      'id': 42,
      'slash': 'hello',
      'child': {'next': <String, Object?>{}},
    });
  });

  test('a required pointer to a nullable primitive preserves null', () {
    final value = NullablePointerUse.fromJson(const {'value': null});

    expect(value.value, isNull);
    expect(value.toJson(), {'value': null});
  });

  test(
    'recursive list pointers keep source and referenced item types compatible',
    () {
      final source = RecursiveListSource.fromJson(const {
        'nodes': [
          {
            'next': [<String, Object?>{}],
          },
        ],
      });
      final value = RecursiveListUse(nodes: source.nodes);

      expect(value.nodes.single.next, hasLength(1));
      expect(value.toJson(), {
        'nodes': [
          {
            'next': [<String, Object?>{}],
          },
        ],
      });
    },
  );

  test(
    'a structurally extended pointer retains one assignable public type',
    () {
      final owner = MergedPointerOwner.fromJson(const {
        'child': {
          'base': 'root',
          'extra': 1,
          'next': {'base': 'leaf', 'extra': 2},
        },
      });
      // The explicit type checks assignability between the pointer and owner.
      // ignore: omit_local_variable_types
      final MergedPointerUse shared = owner.child;

      expect(shared.toJson(), {
        'base': 'root',
        'extra': 1,
        'next': {'base': 'leaf', 'extra': 2},
      });
    },
  );

  test('recursive structurally extended pointers retain base requirements', () {
    expect(
      () => MergedPointerOwner.fromJson(const {
        'child': {
          'base': 'root',
          'extra': 1,
          'next': {'extra': 2},
        },
      }),
      throwsA(isA<DecodingException>()),
    );
  });

  test('recursive nested unions round-trip arrays and scalar leaves', () {
    final owner = RecursiveUnionOwner.fromJson(const {
      'child': [
        'leaf',
        ['branch'],
      ],
    });

    expect(owner.toJson(), {
      'child': [
        'leaf',
        ['branch'],
      ],
    });
  });

  test('recursive allOf additional properties round-trip object leaves', () {
    final owner = RecursiveAllOfOwner.fromJson(const {
      'child': {
        'name': 'root',
        'next': {'name': 'leaf'},
      },
    });

    expect(owner.toJson(), {
      'child': {
        'name': 'root',
        'next': {'name': 'leaf'},
      },
    });
  });

  test('recursive class additional properties round-trip object leaves', () {
    final owner = RecursiveAdditionalOwner.fromJson(const {
      'child': {
        'name': 'root',
        'next': {'name': 'leaf'},
      },
    });

    expect(owner.toJson(), {
      'child': {
        'name': 'root',
        'next': {'name': 'leaf'},
      },
    });
  });

  test('raw oneOf pointers retain their concrete string alternative', () {
    final value = RawOneChoice.fromJson('hello');

    expect(value.toJson(), 'hello');
  });

  test('raw anyOf pointers retain their concrete string alternative', () {
    final value = RawAnyChoice.fromJson('hello');

    expect(value.toJson(), 'hello');
  });

  test('raw allOf pointers retain their concrete object member', () {
    final value = RawAllChoice.fromJson(const {'label': 'hello'});

    expect(value.toJson(), {'label': 'hello'});
  });

  test('owner-first self lists and maps use recursive collection helpers', () {
    final owner = SelfCollectionOwner.fromJson(const {
      'list': [
        [<Object?>[]],
      ],
      'map': {'child': <String, Object?>{}},
    });

    expect(owner.toJson(), {
      'list': [
        [<Object?>[]],
      ],
      'map': {'child': <String, Object?>{}},
    });
  });
}
