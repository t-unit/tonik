import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  group('Nullable Primitive Types', () {
    const primitivesSpec = {
      'openapi': '3.0.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          // String types
          'NullableString': {
            'type': 'string',
            'nullable': true,
          },
          'RequiredString': {
            'type': 'string',
          },
          // DateTime types
          'NullableDateTime': {
            'type': 'string',
            'format': 'date-time',
            'nullable': true,
          },
          'RequiredDateTime': {
            'type': 'string',
            'format': 'date-time',
          },
          // Date types
          'NullableDate': {
            'type': 'string',
            'format': 'date',
            'nullable': true,
          },
          'RequiredDate': {
            'type': 'string',
            'format': 'date',
          },
          // URI types
          'NullableUri': {
            'type': 'string',
            'format': 'uri',
            'nullable': true,
          },
          'RequiredUri': {
            'type': 'string',
            'format': 'uri',
          },
          // Binary types
          'NullableBinary': {
            'type': 'string',
            'format': 'binary',
            'nullable': true,
          },
          'RequiredBinary': {
            'type': 'string',
            'format': 'binary',
          },
          // Decimal types
          'NullableDecimal': {
            'type': 'string',
            'format': 'decimal',
            'nullable': true,
          },
          'RequiredDecimal': {
            'type': 'string',
            'format': 'decimal',
          },
          // Integer types
          'NullableInteger': {
            'type': 'integer',
            'nullable': true,
          },
          'RequiredInteger': {
            'type': 'integer',
          },
          // Number types
          'NullableNumber': {
            'type': 'number',
            'nullable': true,
          },
          'RequiredNumber': {
            'type': 'number',
          },
          // Double types
          'NullableDouble': {
            'type': 'number',
            'format': 'double',
            'nullable': true,
          },
          'RequiredDouble': {
            'type': 'number',
            'format': 'double',
          },
          // Boolean types
          'NullableBoolean': {
            'type': 'boolean',
            'nullable': true,
          },
          'RequiredBoolean': {
            'type': 'boolean',
          },
        },
      },
    };

    test('parses nullable string', () {
      final api = Importer().import(primitivesSpec);
      final model = api.models.firstWhere(
        (m) => m is NamedModel && m.name == 'NullableString',
      );

      expect(model, isA<AliasModel>());
      final aliasModel = model as AliasModel;
      expect(aliasModel.isNullable, isTrue);
      expect(aliasModel.model, isA<StringModel>());
    });

    test('parses non-nullable string', () {
      final api = Importer().import(primitivesSpec);
      final model = api.models.firstWhere(
        (m) => m is NamedModel && m.name == 'RequiredString',
      );

      expect(model, isA<AliasModel>());
      final aliasModel = model as AliasModel;
      expect(aliasModel.isNullable, isFalse);
      expect(aliasModel.model, isA<StringModel>());
    });

    test('parses nullable date-time', () {
      final api = Importer().import(primitivesSpec);
      final model = api.models.firstWhere(
        (m) => m is NamedModel && m.name == 'NullableDateTime',
      );

      expect(model, isA<AliasModel>());
      final aliasModel = model as AliasModel;
      expect(aliasModel.isNullable, isTrue);
      expect(aliasModel.model, isA<DateTimeModel>());
    });

    test('parses non-nullable date-time', () {
      final api = Importer().import(primitivesSpec);
      final model = api.models.firstWhere(
        (m) => m is NamedModel && m.name == 'RequiredDateTime',
      );

      expect(model, isA<AliasModel>());
      final aliasModel = model as AliasModel;
      expect(aliasModel.isNullable, isFalse);
      expect(aliasModel.model, isA<DateTimeModel>());
    });

    test('parses nullable date', () {
      final api = Importer().import(primitivesSpec);
      final model = api.models.firstWhere(
        (m) => m is NamedModel && m.name == 'NullableDate',
      );

      expect(model, isA<AliasModel>());
      final aliasModel = model as AliasModel;
      expect(aliasModel.isNullable, isTrue);
      expect(aliasModel.model, isA<DateModel>());
    });

    test('parses non-nullable date', () {
      final api = Importer().import(primitivesSpec);
      final model = api.models.firstWhere(
        (m) => m is NamedModel && m.name == 'RequiredDate',
      );

      expect(model, isA<AliasModel>());
      final aliasModel = model as AliasModel;
      expect(aliasModel.isNullable, isFalse);
      expect(aliasModel.model, isA<DateModel>());
    });

    test('parses nullable uri', () {
      final api = Importer().import(primitivesSpec);
      final model = api.models.firstWhere(
        (m) => m is NamedModel && m.name == 'NullableUri',
      );

      expect(model, isA<AliasModel>());
      final aliasModel = model as AliasModel;
      expect(aliasModel.isNullable, isTrue);
      expect(aliasModel.model, isA<UriModel>());
    });

    test('parses non-nullable uri', () {
      final api = Importer().import(primitivesSpec);
      final model = api.models.firstWhere(
        (m) => m is NamedModel && m.name == 'RequiredUri',
      );

      expect(model, isA<AliasModel>());
      final aliasModel = model as AliasModel;
      expect(aliasModel.isNullable, isFalse);
      expect(aliasModel.model, isA<UriModel>());
    });

    test('parses nullable binary', () {
      final api = Importer().import(primitivesSpec);
      final model = api.models.firstWhere(
        (m) => m is NamedModel && m.name == 'NullableBinary',
      );

      expect(model, isA<AliasModel>());
      final aliasModel = model as AliasModel;
      expect(aliasModel.isNullable, isTrue);
      expect(aliasModel.model, isA<BinaryModel>());
    });

    test('parses non-nullable binary', () {
      final api = Importer().import(primitivesSpec);
      final model = api.models.firstWhere(
        (m) => m is NamedModel && m.name == 'RequiredBinary',
      );

      expect(model, isA<AliasModel>());
      final aliasModel = model as AliasModel;
      expect(aliasModel.isNullable, isFalse);
      expect(aliasModel.model, isA<BinaryModel>());
    });

    test('parses nullable decimal', () {
      final api = Importer().import(primitivesSpec);
      final model = api.models.firstWhere(
        (m) => m is NamedModel && m.name == 'NullableDecimal',
      );

      expect(model, isA<AliasModel>());
      final aliasModel = model as AliasModel;
      expect(aliasModel.isNullable, isTrue);
      expect(aliasModel.model, isA<DecimalModel>());
    });

    test('parses non-nullable decimal', () {
      final api = Importer().import(primitivesSpec);
      final model = api.models.firstWhere(
        (m) => m is NamedModel && m.name == 'RequiredDecimal',
      );

      expect(model, isA<AliasModel>());
      final aliasModel = model as AliasModel;
      expect(aliasModel.isNullable, isFalse);
      expect(aliasModel.model, isA<DecimalModel>());
    });

    test('parses nullable integer', () {
      final api = Importer().import(primitivesSpec);
      final model = api.models.firstWhere(
        (m) => m is NamedModel && m.name == 'NullableInteger',
      );

      expect(model, isA<AliasModel>());
      final aliasModel = model as AliasModel;
      expect(aliasModel.isNullable, isTrue);
      expect(aliasModel.model, isA<IntegerModel>());
    });

    test('parses non-nullable integer', () {
      final api = Importer().import(primitivesSpec);
      final model = api.models.firstWhere(
        (m) => m is NamedModel && m.name == 'RequiredInteger',
      );

      expect(model, isA<AliasModel>());
      final aliasModel = model as AliasModel;
      expect(aliasModel.isNullable, isFalse);
      expect(aliasModel.model, isA<IntegerModel>());
    });

    test('parses nullable number', () {
      final api = Importer().import(primitivesSpec);
      final model = api.models.firstWhere(
        (m) => m is NamedModel && m.name == 'NullableNumber',
      );

      expect(model, isA<AliasModel>());
      final aliasModel = model as AliasModel;
      expect(aliasModel.isNullable, isTrue);
      expect(aliasModel.model, isA<NumberModel>());
    });

    test('parses non-nullable number', () {
      final api = Importer().import(primitivesSpec);
      final model = api.models.firstWhere(
        (m) => m is NamedModel && m.name == 'RequiredNumber',
      );

      expect(model, isA<AliasModel>());
      final aliasModel = model as AliasModel;
      expect(aliasModel.isNullable, isFalse);
      expect(aliasModel.model, isA<NumberModel>());
    });

    test('parses nullable double', () {
      final api = Importer().import(primitivesSpec);
      final model = api.models.firstWhere(
        (m) => m is NamedModel && m.name == 'NullableDouble',
      );

      expect(model, isA<AliasModel>());
      final aliasModel = model as AliasModel;
      expect(aliasModel.isNullable, isTrue);
      expect(aliasModel.model, isA<DoubleModel>());
    });

    test('parses non-nullable double', () {
      final api = Importer().import(primitivesSpec);
      final model = api.models.firstWhere(
        (m) => m is NamedModel && m.name == 'RequiredDouble',
      );

      expect(model, isA<AliasModel>());
      final aliasModel = model as AliasModel;
      expect(aliasModel.isNullable, isFalse);
      expect(aliasModel.model, isA<DoubleModel>());
    });

    test('parses nullable boolean', () {
      final api = Importer().import(primitivesSpec);
      final model = api.models.firstWhere(
        (m) => m is NamedModel && m.name == 'NullableBoolean',
      );

      expect(model, isA<AliasModel>());
      final aliasModel = model as AliasModel;
      expect(aliasModel.isNullable, isTrue);
      expect(aliasModel.model, isA<BooleanModel>());
    });

    test('parses non-nullable boolean', () {
      final api = Importer().import(primitivesSpec);
      final model = api.models.firstWhere(
        (m) => m is NamedModel && m.name == 'RequiredBoolean',
      );

      expect(model, isA<AliasModel>());
      final aliasModel = model as AliasModel;
      expect(aliasModel.isNullable, isFalse);
      expect(aliasModel.model, isA<BooleanModel>());
    });
  });

  group('Nullable Array Types', () {
    const nullableArraySpec = {
      'openapi': '3.0.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'NullableTagList': {
            'type': 'array',
            'items': {'type': 'string'},
            'nullable': true,
          },
          'RequiredTagList': {
            'type': 'array',
            'items': {'type': 'string'},
          },
        },
      },
    };

    test('parses nullable array', () {
      final api = Importer().import(nullableArraySpec);
      final model = api.models.firstWhere(
        (m) => m is NamedModel && m.name == 'NullableTagList',
      );

      expect(model, isA<ListModel>());
      final listModel = model as ListModel;
      expect(listModel.isNullable, isTrue);
      expect(listModel.content, isA<StringModel>());
    });

    test('parses non-nullable array', () {
      final api = Importer().import(nullableArraySpec);
      final model = api.models.firstWhere(
        (m) => m is NamedModel && m.name == 'RequiredTagList',
      );

      expect(model, isA<ListModel>());
      final listModel = model as ListModel;
      expect(listModel.isNullable, isFalse);
      expect(listModel.content, isA<StringModel>());
    });
  });

  group('Nullable Object Types', () {
    const nullableObjectSpec = {
      'openapi': '3.0.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'NullableAddress': {
            'type': 'object',
            'nullable': true,
            'properties': {
              'street': {'type': 'string'},
            },
          },
          'RequiredAddress': {
            'type': 'object',
            'properties': {
              'street': {'type': 'string'},
            },
          },
        },
      },
    };

    test('parses nullable object', () {
      final api = Importer().import(nullableObjectSpec);
      final model = api.models.firstWhere(
        (m) => m is NamedModel && m.name == 'NullableAddress',
      );

      expect(model, isA<ClassModel>());
      final classModel = model as ClassModel;
      expect(classModel.isNullable, isTrue);
      expect(classModel.properties.length, 1);
      expect(classModel.properties.first.name, 'street');
    });

    test('parses non-nullable object', () {
      final api = Importer().import(nullableObjectSpec);
      final model = api.models.firstWhere(
        (m) => m is NamedModel && m.name == 'RequiredAddress',
      );

      expect(model, isA<ClassModel>());
      final classModel = model as ClassModel;
      expect(classModel.isNullable, isFalse);
      expect(classModel.properties.length, 1);
    });
  });

  group('Nullable Composite Types - oneOf', () {
    const nullableOneOfSpec = {
      'openapi': '3.0.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'Cat': {
            'type': 'object',
            'properties': {
              'meow': {'type': 'string'},
            },
          },
          'Dog': {
            'type': 'object',
            'properties': {
              'bark': {'type': 'string'},
            },
          },
          'NullablePet': {
            'oneOf': [
              {r'$ref': '#/components/schemas/Cat'},
              {r'$ref': '#/components/schemas/Dog'},
            ],
            'nullable': true,
          },
          'RequiredPet': {
            'oneOf': [
              {r'$ref': '#/components/schemas/Cat'},
              {r'$ref': '#/components/schemas/Dog'},
            ],
          },
        },
      },
    };

    test('parses nullable oneOf', () {
      final api = Importer().import(nullableOneOfSpec);
      final model = api.models.firstWhere(
        (m) => m is NamedModel && m.name == 'NullablePet',
      );

      expect(model, isA<OneOfModel>());
      final oneOfModel = model as OneOfModel;
      expect(oneOfModel.isNullable, isTrue);
      expect(oneOfModel.models.length, 2);
    });

    test('parses non-nullable oneOf', () {
      final api = Importer().import(nullableOneOfSpec);
      final model = api.models.firstWhere(
        (m) => m is NamedModel && m.name == 'RequiredPet',
      );

      expect(model, isA<OneOfModel>());
      final oneOfModel = model as OneOfModel;
      expect(oneOfModel.isNullable, isFalse);
    });
  });

  group('Nullable Composite Types - anyOf', () {
    const nullableAnyOfSpec = {
      'openapi': '3.0.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'Success': {
            'type': 'object',
            'properties': {
              'data': {'type': 'string'},
            },
          },
          'Error': {
            'type': 'object',
            'properties': {
              'message': {'type': 'string'},
            },
          },
          'NullableResponse': {
            'anyOf': [
              {r'$ref': '#/components/schemas/Success'},
              {r'$ref': '#/components/schemas/Error'},
            ],
            'nullable': true,
          },
          'RequiredResponse': {
            'anyOf': [
              {r'$ref': '#/components/schemas/Success'},
              {r'$ref': '#/components/schemas/Error'},
            ],
          },
        },
      },
    };

    test('parses nullable anyOf', () {
      final api = Importer().import(nullableAnyOfSpec);
      final model = api.models.firstWhere(
        (m) => m is NamedModel && m.name == 'NullableResponse',
      );

      expect(model, isA<AnyOfModel>());
      final anyOfModel = model as AnyOfModel;
      expect(anyOfModel.isNullable, isTrue);
      expect(anyOfModel.models.length, 2);
    });

    test('parses non-nullable anyOf', () {
      final api = Importer().import(nullableAnyOfSpec);
      final model = api.models.firstWhere(
        (m) => m is NamedModel && m.name == 'RequiredResponse',
      );

      expect(model, isA<AnyOfModel>());
      final anyOfModel = model as AnyOfModel;
      expect(anyOfModel.isNullable, isFalse);
    });
  });

  group('Nullable Composite Types - allOf', () {
    const nullableAllOfSpec = {
      'openapi': '3.0.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'User': {
            'type': 'object',
            'properties': {
              'name': {'type': 'string'},
            },
          },
          'NullableExtendedUser': {
            'allOf': [
              {r'$ref': '#/components/schemas/User'},
              {
                'type': 'object',
                'properties': {
                  'role': {'type': 'string'},
                },
              },
            ],
            'nullable': true,
          },
          'RequiredExtendedUser': {
            'allOf': [
              {r'$ref': '#/components/schemas/User'},
              {
                'type': 'object',
                'properties': {
                  'role': {'type': 'string'},
                },
              },
            ],
          },
        },
      },
    };

    test('parses nullable allOf', () {
      final api = Importer().import(nullableAllOfSpec);
      final model = api.models.firstWhere(
        (m) => m is NamedModel && m.name == 'NullableExtendedUser',
      );

      expect(model, isA<AllOfModel>());
      final allOfModel = model as AllOfModel;
      expect(allOfModel.isNullable, isTrue);
      expect(allOfModel.models.length, 2);
    });

    test('parses non-nullable allOf', () {
      final api = Importer().import(nullableAllOfSpec);
      final model = api.models.firstWhere(
        (m) => m is NamedModel && m.name == 'RequiredExtendedUser',
      );

      expect(model, isA<AllOfModel>());
      final allOfModel = model as AllOfModel;
      expect(allOfModel.isNullable, isFalse);
    });
  });

  group('Type Array with null (OpenAPI 3.1 style)', () {
    const typeArrayNullSpec = {
      'openapi': '3.0.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'FlexibleString': {
            'type': ['string', 'null'],
          },
        },
      },
    };

    test('parses type array with null as nullable', () {
      final api = Importer().import(typeArrayNullSpec);
      final model = api.models.firstWhere(
        (m) => m is NamedModel && m.name == 'FlexibleString',
      );

      expect(model, isA<AliasModel>());
      final aliasModel = model as AliasModel;
      expect(aliasModel.isNullable, isTrue);
      expect(aliasModel.model, isA<StringModel>());
    });
  });

  group('Backward Compatibility', () {
    const nonNullableSpec = {
      'openapi': '3.0.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'RegularTimestamp': {
            'type': 'string',
            'format': 'date-time',
          },
          'RegularString': {
            'type': 'string',
          },
          'RegularList': {
            'type': 'array',
            'items': {'type': 'string'},
          },
          'RegularObject': {
            'type': 'object',
            'properties': {
              'field': {'type': 'string'},
            },
          },
        },
      },
    };

    test('non-nullable primitive defaults to false', () {
      final api = Importer().import(nonNullableSpec);
      final model = api.models.firstWhere(
        (m) => m is NamedModel && m.name == 'RegularTimestamp',
      );

      expect(model, isA<AliasModel>());
      expect((model as AliasModel).isNullable, isFalse);
    });

    test('non-nullable string defaults to false', () {
      final api = Importer().import(nonNullableSpec);
      final model = api.models.firstWhere(
        (m) => m is NamedModel && m.name == 'RegularString',
      );

      expect(model, isA<AliasModel>());
      expect((model as AliasModel).isNullable, isFalse);
    });

    test('non-nullable list defaults to false', () {
      final api = Importer().import(nonNullableSpec);
      final model = api.models.firstWhere(
        (m) => m is NamedModel && m.name == 'RegularList',
      );

      expect(model, isA<ListModel>());
      expect((model as ListModel).isNullable, isFalse);
    });

    test('non-nullable object defaults to false', () {
      final api = Importer().import(nonNullableSpec);
      final model = api.models.firstWhere(
        (m) => m is NamedModel && m.name == 'RegularObject',
      );

      expect(model, isA<ClassModel>());
      expect((model as ClassModel).isNullable, isFalse);
    });
  });

  group('References to Nullable Schemas', () {
    const refToNullableSpec = {
      'openapi': '3.0.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'NullableTimestamp': {
            'type': 'string',
            'format': 'date-time',
            'nullable': true,
          },
          'Event': {
            'type': 'object',
            'properties': {
              'timestamp': {r'$ref': '#/components/schemas/NullableTimestamp'},
            },
          },
        },
      },
    };

    test('references to nullable schemas preserve nullability', () {
      final api = Importer().import(refToNullableSpec);

      // First check the NullableTimestamp is nullable
      final nullableTimestamp = api.models.firstWhere(
        (m) => m is NamedModel && m.name == 'NullableTimestamp',
      );
      expect(nullableTimestamp, isA<AliasModel>());
      expect((nullableTimestamp as AliasModel).isNullable, isTrue);

      // Then check that Event property references it
      final event = api.models.firstWhere(
        (m) => m is NamedModel && m.name == 'Event',
      );
      expect(event, isA<ClassModel>());
      final eventModel = event as ClassModel;
      final timestampProp = eventModel.properties.firstWhere(
        (p) => p.name == 'timestamp',
      );
      expect(timestampProp.model, isA<AliasModel>());
      // The property references the nullable AliasModel
      final refModel = timestampProp.model as AliasModel;
      expect(refModel.name, 'NullableTimestamp');
      expect(refModel.isNullable, isTrue);
    });
  });
}
