import 'package:defaulted_enums_api/defaulted_enums_api.dart';
import 'package:test/test.dart';

void main() {
  group(
    'operation parameter enum defaults — public static const accessors',
    () {
      test('query enum default is reachable on the operation class', () {
        expect(ListSubscriptions.statusDefault, Status.active);
      });
    },
  );
}
