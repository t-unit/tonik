import 'package:simple_encoding_api/simple_encoding_api.dart';
import 'package:test/test.dart';

void main() {
  group('Header Roundtrip Duplicate Field Lines', () {
    test('generated response model preserves the list boundary', () {
      const value = HeadersRoundtripListsSimpleGet200Response(
        xStringList: ['first', 'second'],
      );

      expect(value.xStringList, ['first', 'second']);
    });
  });
}
