import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';

void main() {
  group('EnumConfig', () {
    test('defaults to generating unknown case named "unknown"', () {
      const config = EnumConfig();

      expect(config.generateUnknownCase, isFalse);
      expect(config.unknownCaseName, 'unknown');
    });
  });
}
