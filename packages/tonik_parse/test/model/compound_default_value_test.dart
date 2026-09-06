import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/tonik_parse.dart';

ApiDocument _import(Map<String, Object?> schemas) => Importer().import({
  'openapi': '3.1.0',
  'info': {'title': 'Test API', 'version': '1.0.0'},
  'paths': <String, Object?>{},
  'components': {'schemas': schemas},
});

Model _named(ApiDocument api, String name) =>
    api.models.firstWhere((m) => m is NamedModel && m.name == name);

Map<String, Object?> _ref(String name) => {
  r'$ref': '#/components/schemas/$name',
};

void main() {
  for (final kind in ['allOf', 'oneOf', 'anyOf']) {
    group('$kind defaults', () {
      for (final members in [1, 2]) {
        test(
          '$members members preserve enclosing defaults through references',
          () {
            final api = _import({
              // Resolve forward references as well as an extra alias hop.
              'Outer': _ref('Alias'),
              'Alias': _ref('Value'),
              'Override': {..._ref('Value'), 'default': 2},
              'Value': {
                kind: [
                  {'type': 'integer'},
                  if (members == 2)
                    {'type': kind == 'allOf' ? 'number' : 'string'},
                ],
                'default': 3,
              },
              'Holder': {
                'type': 'object',
                'properties': {
                  'direct': _ref('Value'),
                  'aliased': _ref('Outer'),
                  'aliasOverride': _ref('Override'),
                  'localOverride': {..._ref('Outer'), 'default': 0},
                  'nullLocal': {..._ref('Value'), 'default': null},
                },
              },
            });
            final value = _named(api, 'Value') as CompositeModel;
            expect(value.defaultValue, 3);
            expect((_named(api, 'Outer') as AliasModel).defaultValue, 3);
            final holder = _named(api, 'Holder') as ClassModel;
            expect(
              {
                for (final p in holder.properties)
                  p.name: p.effectiveDefaultValue,
              },
              {
                'direct': 3,
                'aliased': 3,
                'aliasOverride': 2,
                'localOverride': 0,
                // Explicit schema default:null retains the existing fallback.
                'nullLocal': 3,
              },
            );
          },
        );
      }

      test(
        'inline and defs models retain defaults without a Property carrier',
        () {
          final schema = {
            kind: [
              {'type': 'boolean'},
            ],
            'default': false,
          };
          final api = _import({
            'Values': {'type': 'array', 'items': schema},
            'Holder': {
              'type': 'object',
              r'$defs': {'Value': schema},
              'properties': {
                'value': {r'$ref': r'#/components/schemas/Holder/$defs/Value'},
              },
            },
          });
          final list = _named(api, 'Values') as ListModel;
          expect((list.content as CompositeModel).defaultValue, isFalse);
          final holder = _named(api, 'Holder') as ClassModel;
          expect(holder.properties.single.effectiveDefaultValue, isFalse);
        },
      );

      test(
        'absent and null enclosing defaults do not inherit branch defaults',
        () {
          final api = _import({
            'Branch': {'type': 'integer', 'default': 7},
            'Absent': {
              kind: [_ref('Branch')],
            },
            'ExplicitNull': {
              kind: [_ref('Branch')],
              'nullable': true,
              'default': null,
            },
            'Holder': {
              'type': 'object',
              'properties': {
                'absent': _ref('Absent'),
                'explicitNull': _ref('ExplicitNull'),
              },
            },
          });
          final holder = _named(api, 'Holder') as ClassModel;
          for (final property in holder.properties) {
            expect(property.effectiveDefaultValue, isNull);
            expect((property.model as CompositeModel).defaultValue, isNull);
          }
        },
      );
    });
  }

  test(
    'type-array defaults survive named and recursive OneOf construction',
    () {
      const schema = {
        'type': ['integer', 'string'],
        'default': 0,
      };
      final api = _import({
        'Value': schema,
        'Values': {'type': 'array', 'items': schema},
        'Holder': {
          'type': 'object',
          'properties': {'value': _ref('Value')},
        },
      });
      expect((_named(api, 'Value') as OneOfModel).defaultValue, 0);
      final values = _named(api, 'Values') as ListModel;
      expect((values.content as OneOfModel).defaultValue, 0);
      final holder = _named(api, 'Holder') as ClassModel;
      expect(holder.properties.single.effectiveDefaultValue, 0);
    },
  );

  test(
    'structural ref wrappers preserve defaults in named and property paths',
    () {
      final schema = {
        ..._ref('Base'),
        'properties': {
          'count': {'type': 'integer'},
        },
        'default': {'count': 3},
      };
      final api = _import({
        'Base': {'type': 'object'},
        'Named': schema,
        'Holder': {
          'type': 'object',
          'properties': {'value': schema},
        },
      });
      expect((_named(api, 'Named') as AllOfModel).defaultValue, {'count': 3});
      final holder = _named(api, 'Holder') as ClassModel;
      expect((holder.properties.single.model as AllOfModel).defaultValue, {
        'count': 3,
      });
    },
  );

  for (final kind in ['allOf', 'oneOf', 'anyOf']) {
    for (final location in ['path', 'query', 'header', 'cookie']) {
      test('$location parameter reads $kind defaults through an alias', () {
        final api = Importer().import({
          'openapi': '3.1.0',
          'info': {'title': 'Test API', 'version': '1.0.0'},
          'paths': {
            '/items/{value}': {
              'get': {
                'operationId': 'getItem',
                'parameters': [
                  {
                    'name': 'value',
                    'in': location,
                    'required': location == 'path',
                    'schema': _ref('Alias'),
                  },
                ],
                'responses': {
                  '200': {'description': 'OK'},
                },
              },
            },
          },
          'components': {
            'schemas': {
              'Alias': _ref('Value'),
              'Value': {
                kind: [
                  {'type': 'integer'},
                ],
                'default': 3,
              },
            },
          },
        });
        final value = switch (location) {
          'path' => api.pathParameters.single.resolve().effectiveDefaultValue,
          'query' => api.queryParameters.single.resolve().effectiveDefaultValue,
          'header' => api.requestHeaders.single.resolve().effectiveDefaultValue,
          'cookie' =>
            api.cookieParameters.single.resolve().effectiveDefaultValue,
          _ => throw StateError('Unexpected parameter location'),
        };
        expect(value, 3);
      });
    }
  }
}
