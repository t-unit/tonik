import 'package:collection/collection.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  group(r'$ref with annotation siblings', () {
    test(r'$ref + description creates AliasModel with description', () {
      const fileContent = {
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Pet': {
              'type': 'object',
              'properties': {
                'name': {'type': 'string'},
              },
            },
            'DescribedPetAlias': {
              r'$ref': '#/components/schemas/Pet',
              'description': 'A pet with extra documentation',
            },
          },
        },
      };

      final api = Importer().import(fileContent);

      final alias = api.models.firstWhereOrNull(
        (m) => m is NamedModel && m.name == 'DescribedPetAlias',
      );
      expect(alias, isNotNull);
      expect(alias, isA<AliasModel>());

      final aliasModel = alias! as AliasModel;
      expect(aliasModel.model, isA<ClassModel>());
      expect(aliasModel.description, 'A pet with extra documentation');
    });

    test(r'$ref + deprecated creates deprecated AliasModel', () {
      const fileContent = {
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'NewPet': {
              'type': 'object',
              'properties': {
                'name': {'type': 'string'},
              },
            },
            'LegacyPet': {
              r'$ref': '#/components/schemas/NewPet',
              'deprecated': true,
            },
          },
        },
      };

      final api = Importer().import(fileContent);

      final alias = api.models.firstWhereOrNull(
        (m) => m is NamedModel && m.name == 'LegacyPet',
      );
      expect(alias, isNotNull);
      expect(alias, isA<AliasModel>());

      final aliasModel = alias! as AliasModel;
      expect(aliasModel.isDeprecated, isTrue);
    });

    test(r'$ref + description + deprecated creates AliasModel with both', () {
      const fileContent = {
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'NewPet': {
              'type': 'object',
              'properties': {
                'name': {'type': 'string'},
              },
            },
            'OldPet': {
              r'$ref': '#/components/schemas/NewPet',
              'deprecated': true,
              'description': 'Use NewPet instead. Will be removed in v2.',
            },
          },
        },
      };

      final api = Importer().import(fileContent);

      final alias = api.models.firstWhereOrNull(
        (m) => m is NamedModel && m.name == 'OldPet',
      );
      expect(alias, isNotNull);
      expect(alias, isA<AliasModel>());

      final aliasModel = alias! as AliasModel;
      expect(aliasModel.model, isA<ClassModel>());
      expect(
        aliasModel.description,
        'Use NewPet instead. Will be removed in v2.',
      );
      expect(aliasModel.isDeprecated, isTrue);
    });
  });

  group(r'$ref with type array containing null', () {
    test(r'$ref + type: [object, null] creates nullable AliasModel', () {
      const fileContent = {
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Pet': {
              'type': 'object',
              'properties': {
                'name': {'type': 'string'},
              },
            },
            'NullablePet': {
              r'$ref': '#/components/schemas/Pet',
              'type': ['object', 'null'],
            },
          },
        },
      };

      final api = Importer().import(fileContent);

      final nullable = api.models.firstWhereOrNull(
        (m) => m is NamedModel && m.name == 'NullablePet',
      );
      expect(nullable, isNotNull);
      expect(nullable, isA<AliasModel>());

      final aliasModel = nullable! as AliasModel;
      expect(aliasModel.isNullable, isTrue);
    });

    test(r'$ref + type: [null] creates nullable AliasModel', () {
      const fileContent = {
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Pet': {
              'type': 'object',
              'properties': {
                'name': {'type': 'string'},
              },
            },
            'MaybeNull': {
              r'$ref': '#/components/schemas/Pet',
              'type': ['null'],
            },
          },
        },
      };

      final api = Importer().import(fileContent);

      final nullable = api.models.firstWhereOrNull(
        (m) => m is NamedModel && m.name == 'MaybeNull',
      );
      expect(nullable, isNotNull);
      expect(nullable, isA<AliasModel>());

      final aliasModel = nullable! as AliasModel;
      expect(aliasModel.isNullable, isTrue);
    });

    test(
      r'$ref + type: [string, null] to string ref creates nullable alias',
      () {
        const fileContent = {
          'openapi': '3.1.0',
          'info': {'title': 'Test API', 'version': '1.0.0'},
          'paths': <String, dynamic>{},
          'components': {
            'schemas': {
              'UserId': {
                'type': 'string',
              },
              'NullableUserId': {
                r'$ref': '#/components/schemas/UserId',
                'type': ['string', 'null'],
              },
            },
          },
        };

        final api = Importer().import(fileContent);

        final nullable = api.models.firstWhereOrNull(
          (m) => m is NamedModel && m.name == 'NullableUserId',
        );
        expect(nullable, isNotNull);
        expect(nullable, isA<AliasModel>());

        final aliasModel = nullable! as AliasModel;
        expect(aliasModel.isNullable, isTrue);
      },
    );

    test(
      r'$ref + type: [object, null] + description creates nullable '
      'AliasModel with description',
      () {
        const fileContent = {
          'openapi': '3.1.0',
          'info': {'title': 'Test API', 'version': '1.0.0'},
          'paths': <String, dynamic>{},
          'components': {
            'schemas': {
              'Pet': {
                'type': 'object',
                'properties': {
                  'name': {'type': 'string'},
                },
              },
              'OptionalPet': {
                r'$ref': '#/components/schemas/Pet',
                'type': ['object', 'null'],
                'description': 'An optional pet that may be null',
              },
            },
          },
        };

        final api = Importer().import(fileContent);

        final optional = api.models.firstWhereOrNull(
          (m) => m is NamedModel && m.name == 'OptionalPet',
        );
        expect(optional, isNotNull);
        expect(optional, isA<AliasModel>());

        final aliasModel = optional! as AliasModel;
        expect(aliasModel.isNullable, isTrue);
        expect(aliasModel.description, 'An optional pet that may be null');
      },
    );

    test(
      r'$ref + type: [object, null] + deprecated creates nullable '
      'deprecated AliasModel',
      () {
        const fileContent = {
          'openapi': '3.1.0',
          'info': {'title': 'Test API', 'version': '1.0.0'},
          'paths': <String, dynamic>{},
          'components': {
            'schemas': {
              'Pet': {
                'type': 'object',
                'properties': {
                  'name': {'type': 'string'},
                },
              },
              'DeprecatedNullablePet': {
                r'$ref': '#/components/schemas/Pet',
                'type': ['object', 'null'],
                'deprecated': true,
              },
            },
          },
        };

        final api = Importer().import(fileContent);

        final deprecated = api.models.firstWhereOrNull(
          (m) => m is NamedModel && m.name == 'DeprecatedNullablePet',
        );
        expect(deprecated, isNotNull);
        expect(deprecated, isA<AliasModel>());

        final aliasModel = deprecated! as AliasModel;
        expect(aliasModel.isNullable, isTrue);
        expect(aliasModel.isDeprecated, isTrue);
      },
    );
  });

  group(r'$ref in composite types without siblings', () {
    test(r'$ref members in allOf resolve directly without AliasModel', () {
      const fileContent = {
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Named': {
              'type': 'object',
              'properties': {
                'name': {'type': 'string'},
              },
            },
            'Timestamped': {
              'type': 'object',
              'properties': {
                'createdAt': {'type': 'string', 'format': 'date-time'},
              },
            },
            'NamedTimestamped': {
              'allOf': [
                {r'$ref': '#/components/schemas/Named'},
                {r'$ref': '#/components/schemas/Timestamped'},
              ],
            },
          },
        },
      };

      final api = Importer().import(fileContent);

      final combined = api.models.firstWhereOrNull(
        (m) => m is NamedModel && m.name == 'NamedTimestamped',
      );
      expect(combined, isNotNull);
      expect(combined, isA<AllOfModel>());

      final allOfModel = combined! as AllOfModel;
      expect(allOfModel.models, hasLength(2));
      for (final member in allOfModel.models) {
        expect(member, isA<ClassModel>());
      }
    });

    test(r'$ref members in oneOf resolve directly without AliasModel', () {
      const fileContent = {
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Dog': {
              'type': 'object',
              'properties': {
                'breed': {'type': 'string'},
              },
            },
            'Cat': {
              'type': 'object',
              'properties': {
                'color': {'type': 'string'},
              },
            },
            'Pet': {
              'oneOf': [
                {r'$ref': '#/components/schemas/Dog'},
                {r'$ref': '#/components/schemas/Cat'},
              ],
            },
          },
        },
      };

      final api = Importer().import(fileContent);

      final pet = api.models.firstWhereOrNull(
        (m) => m is NamedModel && m.name == 'Pet',
      );
      expect(pet, isNotNull);
      expect(pet, isA<OneOfModel>());

      final oneOfModel = pet! as OneOfModel;
      expect(oneOfModel.models, hasLength(2));
      for (final member in oneOfModel.models) {
        expect(member.model, isA<ClassModel>());
      }
    });

    test(r'$ref members in anyOf resolve directly without AliasModel', () {
      const fileContent = {
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Option1': {
              'type': 'object',
              'properties': {
                'opt1': {'type': 'boolean'},
              },
            },
            'Option2': {
              'type': 'object',
              'properties': {
                'opt2': {'type': 'boolean'},
              },
            },
            'Flexible': {
              'anyOf': [
                {r'$ref': '#/components/schemas/Option1'},
                {r'$ref': '#/components/schemas/Option2'},
              ],
            },
          },
        },
      };

      final api = Importer().import(fileContent);

      final flexible = api.models.firstWhereOrNull(
        (m) => m is NamedModel && m.name == 'Flexible',
      );
      expect(flexible, isNotNull);
      expect(flexible, isA<AnyOfModel>());

      final anyOfModel = flexible! as AnyOfModel;
      expect(anyOfModel.models, hasLength(2));
      for (final member in anyOfModel.models) {
        expect(member.model, isA<ClassModel>());
      }
    });
  });

  group(r'$ref in composite types with siblings', () {
    test(r'$ref + description in allOf member creates AliasModel', () {
      const fileContent = {
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Named': {
              'type': 'object',
              'properties': {
                'name': {'type': 'string'},
              },
            },
            'Timestamped': {
              'type': 'object',
              'properties': {
                'createdAt': {'type': 'string', 'format': 'date-time'},
              },
            },
            'DescribedCombo': {
              'allOf': [
                {
                  r'$ref': '#/components/schemas/Named',
                  'description': 'The named part',
                },
                {r'$ref': '#/components/schemas/Timestamped'},
              ],
            },
          },
        },
      };

      final api = Importer().import(fileContent);

      final combined = api.models.firstWhereOrNull(
        (m) => m is NamedModel && m.name == 'DescribedCombo',
      );
      expect(combined, isNotNull);
      expect(combined, isA<AllOfModel>());

      final allOfModel = combined! as AllOfModel;
      expect(allOfModel.models, hasLength(2));

      final aliasMembers = allOfModel.models.whereType<AliasModel>().toList();
      expect(aliasMembers, hasLength(1));
      expect(aliasMembers.first.description, 'The named part');
      expect(aliasMembers.first.name, isNull);

      final classMembers = allOfModel.models.whereType<ClassModel>().toList();
      expect(classMembers, hasLength(1));
    });

    test(
      r'$ref + deprecated in oneOf member creates deprecated AliasModel',
      () {
        const fileContent = {
          'openapi': '3.1.0',
          'info': {'title': 'Test API', 'version': '1.0.0'},
          'paths': <String, dynamic>{},
          'components': {
            'schemas': {
              'Dog': {
                'type': 'object',
                'properties': {
                  'breed': {'type': 'string'},
                },
              },
              'Cat': {
                'type': 'object',
                'properties': {
                  'color': {'type': 'string'},
                },
              },
              'Pet': {
                'oneOf': [
                  {
                    r'$ref': '#/components/schemas/Dog',
                    'deprecated': true,
                  },
                  {r'$ref': '#/components/schemas/Cat'},
                ],
              },
            },
          },
        };

        final api = Importer().import(fileContent);

        final pet = api.models.firstWhereOrNull(
          (m) => m is NamedModel && m.name == 'Pet',
        );
        expect(pet, isNotNull);
        expect(pet, isA<OneOfModel>());

        final oneOfModel = pet! as OneOfModel;
        expect(oneOfModel.models, hasLength(2));

        final aliasMembers = oneOfModel.models
            .map((m) => m.model)
            .whereType<AliasModel>()
            .toList();
        expect(aliasMembers, hasLength(1));
        expect(aliasMembers.first.isDeprecated, isTrue);
        expect(aliasMembers.first.name, isNull);

        final classMembers = oneOfModel.models
            .map((m) => m.model)
            .whereType<ClassModel>()
            .toList();
        expect(classMembers, hasLength(1));
      },
    );

    test(
      r'$ref + type: [null] in anyOf member creates nullable AliasModel',
      () {
        const fileContent = {
          'openapi': '3.1.0',
          'info': {'title': 'Test API', 'version': '1.0.0'},
          'paths': <String, dynamic>{},
          'components': {
            'schemas': {
              'Option1': {
                'type': 'object',
                'properties': {
                  'opt1': {'type': 'boolean'},
                },
              },
              'Option2': {
                'type': 'object',
                'properties': {
                  'opt2': {'type': 'boolean'},
                },
              },
              'Flexible': {
                'anyOf': [
                  {
                    r'$ref': '#/components/schemas/Option1',
                    'type': ['object', 'null'],
                  },
                  {r'$ref': '#/components/schemas/Option2'},
                ],
              },
            },
          },
        };

        final api = Importer().import(fileContent);

        final flexible = api.models.firstWhereOrNull(
          (m) => m is NamedModel && m.name == 'Flexible',
        );
        expect(flexible, isNotNull);
        expect(flexible, isA<AnyOfModel>());

        final anyOfModel = flexible! as AnyOfModel;
        expect(anyOfModel.models, hasLength(2));

        final aliasMembers = anyOfModel.models
            .map((m) => m.model)
            .whereType<AliasModel>()
            .toList();
        expect(aliasMembers, hasLength(1));
        expect(aliasMembers.first.isNullable, isTrue);
        expect(aliasMembers.first.name, isNull);

        final classMembers = anyOfModel.models
            .map((m) => m.model)
            .whereType<ClassModel>()
            .toList();
        expect(classMembers, hasLength(1));
      },
    );

    test(r'all $ref members with siblings in allOf create AliasModels', () {
      const fileContent = {
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'A': {
              'type': 'object',
              'properties': {
                'a': {'type': 'string'},
              },
            },
            'B': {
              'type': 'object',
              'properties': {
                'b': {'type': 'string'},
              },
            },
            'AllDescribed': {
              'allOf': [
                {
                  r'$ref': '#/components/schemas/A',
                  'description': 'First part',
                },
                {
                  r'$ref': '#/components/schemas/B',
                  'description': 'Second part',
                },
              ],
            },
          },
        },
      };

      final api = Importer().import(fileContent);

      final combined = api.models.firstWhereOrNull(
        (m) => m is NamedModel && m.name == 'AllDescribed',
      );
      expect(combined, isNotNull);
      expect(combined, isA<AllOfModel>());

      final allOfModel = combined! as AllOfModel;
      expect(allOfModel.models, hasLength(2));

      for (final member in allOfModel.models) {
        expect(member, isA<AliasModel>());
        expect((member as AliasModel).name, isNull);
      }

      final descriptions = allOfModel.models.whereType<AliasModel>().map(
        (a) => a.description,
      );
      expect(descriptions, containsAll(['First part', 'Second part']));
    });
  });

  group(r'$ref in properties without siblings', () {
    test(r'$ref property resolves directly without AliasModel', () {
      const fileContent = {
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Address': {
              'type': 'object',
              'properties': {
                'street': {'type': 'string'},
                'city': {'type': 'string'},
              },
            },
            'Person': {
              'type': 'object',
              'properties': {
                'name': {'type': 'string'},
                'address': {
                  r'$ref': '#/components/schemas/Address',
                },
              },
            },
          },
        },
      };

      final api = Importer().import(fileContent);

      final person = api.models.firstWhereOrNull(
        (m) => m is NamedModel && m.name == 'Person',
      );
      expect(person, isNotNull);
      expect(person, isA<ClassModel>());

      final personClass = person! as ClassModel;
      final addressProp = personClass.properties.firstWhereOrNull(
        (p) => p.name == 'address',
      );
      expect(addressProp, isNotNull);
      expect(addressProp!.model, isA<ClassModel>());
      expect((addressProp.model as ClassModel).name, 'Address');
    });

    test(r'$ref property to enum resolves directly without AliasModel', () {
      const fileContent = {
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Status': {
              'type': 'string',
              'enum': ['active', 'inactive'],
            },
            'User': {
              'type': 'object',
              'properties': {
                'name': {'type': 'string'},
                'status': {
                  r'$ref': '#/components/schemas/Status',
                },
              },
            },
          },
        },
      };

      final api = Importer().import(fileContent);

      final user = api.models.firstWhereOrNull(
        (m) => m is NamedModel && m.name == 'User',
      );
      expect(user, isNotNull);
      expect(user, isA<ClassModel>());

      final userClass = user! as ClassModel;
      final statusProp = userClass.properties.firstWhereOrNull(
        (p) => p.name == 'status',
      );
      expect(statusProp, isNotNull);
      expect(statusProp!.model, isA<EnumModel<String>>());
    });
  });

  group(r'$ref in properties with siblings', () {
    test(r'$ref + description in property sets description on property', () {
      const fileContent = {
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Address': {
              'type': 'object',
              'properties': {
                'street': {'type': 'string'},
                'city': {'type': 'string'},
              },
            },
            'Person': {
              'type': 'object',
              'properties': {
                'name': {'type': 'string'},
                'address': {
                  r'$ref': '#/components/schemas/Address',
                  'description': 'The persons home address',
                },
              },
            },
          },
        },
      };

      final api = Importer().import(fileContent);

      final person = api.models.firstWhereOrNull(
        (m) => m is NamedModel && m.name == 'Person',
      );
      expect(person, isNotNull);
      expect(person, isA<ClassModel>());

      final personClass = person! as ClassModel;
      final addressProp = personClass.properties.firstWhereOrNull(
        (p) => p.name == 'address',
      );
      expect(addressProp, isNotNull);
      expect(addressProp!.model, isA<ClassModel>());
      expect(addressProp.description, 'The persons home address');
    });

    test(r'$ref + deprecated in property sets deprecated on property', () {
      const fileContent = {
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'LegacyAddress': {
              'type': 'object',
              'properties': {
                'street': {'type': 'string'},
              },
            },
            'Person': {
              'type': 'object',
              'properties': {
                'name': {'type': 'string'},
                'oldAddress': {
                  r'$ref': '#/components/schemas/LegacyAddress',
                  'deprecated': true,
                },
              },
            },
          },
        },
      };

      final api = Importer().import(fileContent);

      final person = api.models.firstWhereOrNull(
        (m) => m is NamedModel && m.name == 'Person',
      );
      expect(person, isNotNull);
      expect(person, isA<ClassModel>());

      final personClass = person! as ClassModel;
      final oldAddressProp = personClass.properties.firstWhereOrNull(
        (p) => p.name == 'oldAddress',
      );
      expect(oldAddressProp, isNotNull);
      expect(oldAddressProp!.model, isA<ClassModel>());
      expect(oldAddressProp.isDeprecated, isTrue);
    });

    test(r'$ref + type: [null] in property sets nullable on property', () {
      const fileContent = {
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Address': {
              'type': 'object',
              'properties': {
                'street': {'type': 'string'},
              },
            },
            'Person': {
              'type': 'object',
              'properties': {
                'name': {'type': 'string'},
                'address': {
                  r'$ref': '#/components/schemas/Address',
                  'type': ['object', 'null'],
                },
              },
            },
          },
        },
      };

      final api = Importer().import(fileContent);

      final person = api.models.firstWhereOrNull(
        (m) => m is NamedModel && m.name == 'Person',
      );
      expect(person, isNotNull);
      expect(person, isA<ClassModel>());

      final personClass = person! as ClassModel;
      final addressProp = personClass.properties.firstWhereOrNull(
        (p) => p.name == 'address',
      );
      expect(addressProp, isNotNull);
      expect(addressProp!.model, isA<ClassModel>());
      expect(addressProp.isNullable, isTrue);
    });

    test(
      r'$ref + description + deprecated + nullable in property '
      'sets all annotations on property',
      () {
        const fileContent = {
          'openapi': '3.1.0',
          'info': {'title': 'Test API', 'version': '1.0.0'},
          'paths': <String, dynamic>{},
          'components': {
            'schemas': {
              'Address': {
                'type': 'object',
                'properties': {
                  'street': {'type': 'string'},
                },
              },
              'Person': {
                'type': 'object',
                'properties': {
                  'name': {'type': 'string'},
                  'address': {
                    r'$ref': '#/components/schemas/Address',
                    'type': ['object', 'null'],
                    'deprecated': true,
                    'description': 'Old nullable address field',
                  },
                },
              },
            },
          },
        };

        final api = Importer().import(fileContent);

        final person = api.models.firstWhereOrNull(
          (m) => m is NamedModel && m.name == 'Person',
        );
        expect(person, isNotNull);
        expect(person, isA<ClassModel>());

        final personClass = person! as ClassModel;
        final addressProp = personClass.properties.firstWhereOrNull(
          (p) => p.name == 'address',
        );
        expect(addressProp, isNotNull);
        expect(addressProp!.model, isA<ClassModel>());
        expect(addressProp.isNullable, isTrue);
        expect(addressProp.isDeprecated, isTrue);
        expect(addressProp.description, 'Old nullable address field');
      },
    );
  });

  group(r'recursive $ref with annotation siblings', () {
    test(
      'direct self-reference with description does not cause infinite loop',
      () {
        const fileContent = {
          'openapi': '3.1.0',
          'info': {'title': 'Test API', 'version': '1.0.0'},
          'paths': <String, dynamic>{},
          'components': {
            'schemas': {
              'TreeNode': {
                'type': 'object',
                'properties': {
                  'value': {'type': 'string'},
                  'children': {
                    'type': 'array',
                    'items': {
                      r'$ref': '#/components/schemas/TreeNode',
                      'description': 'A child node',
                    },
                  },
                },
              },
            },
          },
        };

        final api = Importer().import(fileContent);

        final treeNode = api.models.firstWhereOrNull(
          (m) => m is NamedModel && m.name == 'TreeNode',
        );
        expect(treeNode, isNotNull);
        expect(treeNode, isA<ClassModel>());

        final treeNodeClass = treeNode! as ClassModel;
        final childrenProp = treeNodeClass.properties.firstWhereOrNull(
          (p) => p.name == 'children',
        );
        expect(childrenProp, isNotNull);
        expect(childrenProp!.model, isA<ListModel>());
      },
    );

    test('self-referencing alias schema with annotation siblings '
        'does not cause infinite loop', () {
      const fileContent = {
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'LinkedNode': {
              'type': 'object',
              'properties': {
                'data': {'type': 'string'},
                'next': {
                  r'$ref': '#/components/schemas/LinkedNode',
                  'description': 'Reference to next node',
                  'deprecated': true,
                },
              },
            },
          },
        },
      };

      final api = Importer().import(fileContent);

      final linkedNode = api.models.firstWhereOrNull(
        (m) => m is NamedModel && m.name == 'LinkedNode',
      );
      expect(linkedNode, isNotNull);
      expect(linkedNode, isA<ClassModel>());

      final linkedNodeClass = linkedNode! as ClassModel;
      final nextProp = linkedNodeClass.properties.firstWhereOrNull(
        (p) => p.name == 'next',
      );
      expect(nextProp, isNotNull);
      expect(nextProp!.description, 'Reference to next node');
      expect(nextProp.isDeprecated, isTrue);
      expect(nextProp.model, same(linkedNodeClass));
    });

    test('mutually recursive schemas with annotation siblings '
        'do not cause infinite loop', () {
      const fileContent = {
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Person': {
              'type': 'object',
              'properties': {
                'name': {'type': 'string'},
                'company': {
                  r'$ref': '#/components/schemas/Company',
                  'description': 'The company this person works for',
                },
              },
            },
            'Company': {
              'type': 'object',
              'properties': {
                'name': {'type': 'string'},
                'employees': {
                  'type': 'array',
                  'items': {
                    r'$ref': '#/components/schemas/Person',
                    'description': 'An employee of this company',
                  },
                },
              },
            },
          },
        },
      };

      final api = Importer().import(fileContent);

      final person = api.models.firstWhereOrNull(
        (m) => m is NamedModel && m.name == 'Person',
      );
      final company = api.models.firstWhereOrNull(
        (m) => m is NamedModel && m.name == 'Company',
      );
      expect(person, isNotNull);
      expect(company, isNotNull);
      expect(person, isA<ClassModel>());
      expect(company, isA<ClassModel>());

      final personClass = person! as ClassModel;
      final companyClass = company! as ClassModel;

      final companyProp = personClass.properties.firstWhereOrNull(
        (p) => p.name == 'company',
      );
      expect(companyProp, isNotNull);
      expect(companyProp!.description, 'The company this person works for');
      expect(companyProp.model, same(companyClass));

      final employeesProp = companyClass.properties.firstWhereOrNull(
        (p) => p.name == 'employees',
      );
      expect(employeesProp, isNotNull);
      expect(employeesProp!.model, isA<ListModel>());
    });

    test('nullable self-reference with type array '
        'does not cause infinite loop', () {
      const fileContent = {
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Node': {
              'type': 'object',
              'properties': {
                'value': {'type': 'integer'},
                'parent': {
                  r'$ref': '#/components/schemas/Node',
                  'type': ['object', 'null'],
                  'description': 'Optional parent node',
                },
              },
            },
          },
        },
      };

      final api = Importer().import(fileContent);

      final node = api.models.firstWhereOrNull(
        (m) => m is NamedModel && m.name == 'Node',
      );
      expect(node, isNotNull);
      expect(node, isA<ClassModel>());

      final nodeClass = node! as ClassModel;
      final parentProp = nodeClass.properties.firstWhereOrNull(
        (p) => p.name == 'parent',
      );
      expect(parentProp, isNotNull);
      expect(parentProp!.isNullable, isTrue);
      expect(parentProp.description, 'Optional parent node');
      expect(parentProp.model, same(nodeClass));
    });

    test(r'top-level schema with direct self-reference via $ref '
        'throws ArgumentError', () {
      const fileContent = {
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'RecursiveAlias': {
              r'$ref': '#/components/schemas/RecursiveAlias',
              'description': 'Self-referencing alias',
            },
          },
        },
      };

      // Direct self-reference is not valid and should throw
      expect(
        () => Importer().import(fileContent),
        throwsArgumentError,
      );
    });
  });
}
