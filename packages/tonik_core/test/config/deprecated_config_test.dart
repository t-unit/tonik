import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';

void main() {
  group('DeprecatedConfig', () {
    test('defaults to annotate for both operations and schemas', () {
      const config = DeprecatedConfig();

      expect(config.operations, DeprecatedHandling.annotate);
      expect(config.schemas, DeprecatedHandling.annotate);
    });
  });
}
