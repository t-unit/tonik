import 'package:test/test.dart';
import 'package:tonik_util/src/encoding/map_encoder.dart';

void main() {
  group('MapParameterEncoder', () {
    group('toParameterMap', () {
      test('converts Map<String, int> to Map<String, String>', () {
        final map = {'a': 1, 'b': 2, 'c': 3};
        expect(map.toParameterMap(), {'a': '1', 'b': '2', 'c': '3'});
      });

      test('converts Map<String, double> to Map<String, String>', () {
        final map = {'x': 1.5, 'y': 2.7};
        expect(map.toParameterMap(), {'x': '1.5', 'y': '2.7'});
      });

      test('converts Map<String, bool> to Map<String, String>', () {
        final map = {'enabled': true, 'visible': false};
        expect(map.toParameterMap(), {'enabled': 'true', 'visible': 'false'});
      });

      test('converts Map<String, num> to Map<String, String>', () {
        final map = <String, num>{'count': 42, 'ratio': 3.14};
        expect(map.toParameterMap(), {'count': '42', 'ratio': '3.14'});
      });

      test('returns empty map for empty input', () {
        final map = <String, int>{};
        expect(map.toParameterMap(), <String, String>{});
      });

      test('works with Map<String, String> as identity', () {
        final map = {'key': 'value', 'name': 'test'};
        expect(map.toParameterMap(), {'key': 'value', 'name': 'test'});
      });
    });
  });
}
