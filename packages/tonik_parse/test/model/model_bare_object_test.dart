import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/tonik_parse.dart';

Map<String, dynamic> specWithSchemas(
  Map<String, dynamic> schemas, {
  String version = '3.0.0',
}) => {
  'openapi': version,
  'info': {'title': 'Test', 'version': '1.0.0'},
  'paths': <String, dynamic>{},
  'components': {'schemas': schemas},
};

void main() {
  group('bare object classification', () {
    test(
      'bare type: object with omitted additionalProperties imports as an '
      'Any-valued map',
      () {
        final spec = specWithSchemas({
          'Freeform': {'type': 'object'},
        });

        final api = Importer().import(spec);
        final mapModel = api.models.whereType<MapModel>().firstWhere(
          (m) => m.name == 'Freeform',
        );

        expect(mapModel.valueModel, isA<AnyModel>());
      },
    );

    test(
      'bare type: object with empty properties map imports as an '
      'Any-valued map',
      () {
        final spec = specWithSchemas({
          'Freeform': {'type': 'object', 'properties': <String, dynamic>{}},
        });

        final api = Importer().import(spec);
        final mapModel = api.models.whereType<MapModel>().firstWhere(
          (m) => m.name == 'Freeform',
        );

        expect(mapModel.valueModel, isA<AnyModel>());
      },
    );

    test(
      'bare type: object imports as an Any-valued map in OpenAPI 3.1',
      () {
        final spec = specWithSchemas(
          {
            'Freeform': {'type': 'object'},
          },
          version: '3.1.0',
        );

        final api = Importer().import(spec);
        final mapModel = api.models.whereType<MapModel>().firstWhere(
          (m) => m.name == 'Freeform',
        );

        expect(mapModel.valueModel, isA<AnyModel>());
      },
    );

    test('inline bare object property imports as an Any-valued map', () {
      final spec = specWithSchemas({
        'Holder': {
          'type': 'object',
          'required': ['id'],
          'properties': {
            'id': {'type': 'string'},
            'freeform': {'type': 'object'},
          },
        },
      });

      final api = Importer().import(spec);
      final holder = api.models.whereType<ClassModel>().firstWhere(
        (m) => m.name == 'Holder',
      );
      final freeform = holder.properties
          .firstWhere((p) => p.name == 'freeform')
          .model;

      expect(freeform, isA<MapModel>());
      expect((freeform as MapModel).valueModel, isA<AnyModel>());
    });

    test(
      'object with declared properties and omitted additionalProperties '
      'stays a class',
      () {
        final spec = specWithSchemas({
          'Closed': {
            'type': 'object',
            'properties': {
              'name': {'type': 'string'},
            },
          },
        });

        final api = Importer().import(spec);

        expect(
          api.models.whereType<ClassModel>().where((m) => m.name == 'Closed'),
          hasLength(1),
        );
        expect(
          api.models.whereType<MapModel>().where((m) => m.name == 'Closed'),
          isEmpty,
        );
      },
    );

    test(
      'pure object with additionalProperties false does not become a map',
      () {
        final spec = specWithSchemas({
          'Sealed': {'type': 'object', 'additionalProperties': false},
        });

        final api = Importer().import(spec);

        expect(
          api.models.whereType<MapModel>().where((m) => m.name == 'Sealed'),
          isEmpty,
        );
      },
    );

    test(
      'pure object with additionalProperties true imports as an '
      'Any-valued map',
      () {
        final spec = specWithSchemas({
          'Open': {'type': 'object', 'additionalProperties': true},
        });

        final api = Importer().import(spec);
        final mapModel = api.models.whereType<MapModel>().firstWhere(
          (m) => m.name == 'Open',
        );

        expect(mapModel.valueModel, isA<AnyModel>());
      },
    );

    test(
      'pure object with empty-schema additionalProperties imports as an '
      'Any-valued map',
      () {
        final spec = specWithSchemas({
          'Open': {
            'type': 'object',
            'additionalProperties': <String, dynamic>{},
          },
        });

        final api = Importer().import(spec);
        final mapModel = api.models.whereType<MapModel>().firstWhere(
          (m) => m.name == 'Open',
        );

        expect(mapModel.valueModel, isA<AnyModel>());
      },
    );
  });
}
