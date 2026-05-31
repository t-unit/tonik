import 'package:test/test.dart';
import 'package:tonik_generate/src/util/default_member_name.dart';

void main() {
  group('pickDefaultMemberName', () {
    test('returns <name>Default when no collision', () {
      expect(
        pickDefaultMemberName(
          propertyName: 'count',
          reservedNames: const <String>{'count', 'name'},
        ),
        'countDefault',
      );
    });

    test('returns <name>Default2 on a single collision', () {
      expect(
        pickDefaultMemberName(
          propertyName: 'value',
          reservedNames: const <String>{'value', 'valueDefault'},
        ),
        'valueDefault2',
      );
    });

    test('skips occupied suffixes and returns the next free one', () {
      expect(
        pickDefaultMemberName(
          propertyName: 'value',
          reservedNames: const <String>{
            'value',
            'valueDefault',
            'valueDefault2',
            'valueDefault3',
          },
        ),
        'valueDefault4',
      );
    });

    test('does not mutate the passed-in reserved set', () {
      final reserved = <String>{'a', 'aDefault'};
      pickDefaultMemberName(propertyName: 'a', reservedNames: reserved);
      expect(reserved, {'a', 'aDefault'});
    });
  });
}
