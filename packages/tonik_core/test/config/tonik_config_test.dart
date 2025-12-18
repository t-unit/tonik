import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';

void main() {
  group('TonikConfig', () {
    test('defaults to empty nested configs', () {
      const config = TonikConfig();

      expect(config.nameOverrides, const NameOverridesConfig());
      expect(config.contentTypes, isEmpty);
      expect(config.filter, const FilterConfig());
      expect(config.deprecated, const DeprecatedConfig());
      expect(config.enums, const EnumConfig());
    });
  });
}
