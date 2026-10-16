import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';

void main() {
  group('EnumConfig', () {
    test('retains the unknown case configuration', () {
      const config = EnumConfig(
        generateUnknownCase: false,
        unknownCaseName: 'unknown',
      );

      expect(config.generateUnknownCase, isFalse);
      expect(config.unknownCaseName, 'unknown');
    });
  });
}
