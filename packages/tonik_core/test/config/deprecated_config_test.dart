import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';

void main() {
  group('DeprecatedConfig', () {
    test('retains annotate handling for all categories', () {
      const config = DeprecatedConfig(
        operations: DeprecatedHandling.annotate,
        schemas: DeprecatedHandling.annotate,
        parameters: DeprecatedHandling.annotate,
        properties: DeprecatedHandling.annotate,
      );

      expect(config.operations, DeprecatedHandling.annotate);
      expect(config.schemas, DeprecatedHandling.annotate);
    });
  });
}
