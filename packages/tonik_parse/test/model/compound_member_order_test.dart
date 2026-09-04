import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  test(
    'composition parsing preserves declaration order and repeated references',
    () {
      final api = Importer().import({
        'openapi': '3.0.3',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Zebra': {'type': 'string'},
            'Alpha': {'type': 'integer'},
            'All': {
              'allOf': [
                {r'$ref': '#/components/schemas/Zebra'},
                {r'$ref': '#/components/schemas/Alpha'},
                {r'$ref': '#/components/schemas/Zebra'},
              ],
            },
            'One': {
              'oneOf': [
                {r'$ref': '#/components/schemas/Zebra'},
                {r'$ref': '#/components/schemas/Alpha'},
                {r'$ref': '#/components/schemas/Zebra'},
              ],
            },
            'Any': {
              'anyOf': [
                {r'$ref': '#/components/schemas/Zebra'},
                {r'$ref': '#/components/schemas/Alpha'},
                {r'$ref': '#/components/schemas/Zebra'},
              ],
            },
          },
        },
      });
      final zebra = api.models.whereType<AliasModel>().singleWhere(
        (m) => m.name == 'Zebra',
      );
      final alpha = api.models.whereType<AliasModel>().singleWhere(
        (m) => m.name == 'Alpha',
      );
      final allOf = api.models.whereType<AllOfModel>().single;
      final oneOf = api.models.whereType<OneOfModel>().single;
      final anyOf = api.models.whereType<AnyOfModel>().single;

      expect(allOf.models, [zebra, alpha, zebra]);
      expect(oneOf.containedModels, [zebra, alpha, zebra]);
      expect(anyOf.containedModels, [zebra, alpha, zebra]);
    },
  );
}
