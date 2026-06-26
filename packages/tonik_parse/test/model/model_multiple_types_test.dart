import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  const fileContent = {
    'openapi': '3.1.0',
    'info': {'title': 'Test API', 'version': '1.0.0'},
    'paths': <String, dynamic>{},
    'components': {
      'schemas': {
        'MultiTypeModel': {
          'type': 'object',
          'properties': {
            'stringOrNumber': {
              'type': ['string', 'number'],
            },
            'nullableString': {'type': 'string', 'nullable': true},
            'nullableStringViaType': {
              'type': ['string', 'null'],
            },
            'nullableMultiType': {
              'type': ['string', 'number'],
              'nullable': true,
            },
            'nullableMultiTypeViaType': {
              'type': ['string', 'number', 'null'],
            },
            'multiTypeArray': {
              'type': 'array',
              'items': {
                'type': ['string', 'number'],
              },
            },
            'nullableArray': {
              'type': 'array',
              'items': {'type': 'string'},
              'nullable': true,
            },
            'nullableArrayViaType': {
              'type': ['array', 'null'],
              'items': {'type': 'string'},
            },
            'arrayWithNullableItems': {
              'type': 'array',
              'items': {
                'type': ['string', 'null'],
              },
            },
            'arrayWithNullableItemsViaFlag': {
              'type': 'array',
              'items': {'type': 'string', 'nullable': true},
            },
          },
          'required': ['stringOrNumber', 'multiTypeEnum'],
        },
      },
    },
  };

  test('imports property with multiple types', () {
    final api = Importer().import(fileContent);

    final model = api.models.first as ClassModel;
    final stringOrNumber = model.properties.firstWhere(
      (p) => p.name == 'stringOrNumber',
    );
    expect(stringOrNumber.model, isA<OneOfModel>());
    expect(stringOrNumber.isRequired, isTrue);
    expect(stringOrNumber.isNullable, isFalse);

    final oneOf = stringOrNumber.model as OneOfModel;
    expect(oneOf.models.length, 2);
    expect(
      oneOf.models.map((m) => m.model).toList(),
      containsAll([isA<StringModel>(), isA<NumberModel>()]),
    );
  });

  test('imports nullable string property', () {
    final api = Importer().import(fileContent);

    final model = api.models.first as ClassModel;
    final nullableString = model.properties.firstWhere(
      (p) => p.name == 'nullableString',
    );
    expect(nullableString.model, isA<StringModel>());
    expect(nullableString.isRequired, isFalse);
    expect(nullableString.isNullable, isTrue);
  });

  test('imports nullable string property via type array', () {
    final api = Importer().import(fileContent);

    final model = api.models.first as ClassModel;
    final nullableString = model.properties.firstWhere(
      (p) => p.name == 'nullableStringViaType',
    );
    expect(nullableString.model, isA<StringModel>());
    expect(nullableString.isRequired, isFalse);
    expect(nullableString.isNullable, isTrue);
  });

  test('imports property with multiple types and nullable', () {
    final api = Importer().import(fileContent);

    final model = api.models.first as ClassModel;
    final nullableMultiType = model.properties.firstWhere(
      (p) => p.name == 'nullableMultiType',
    );
    expect(nullableMultiType.model, isA<OneOfModel>());
    expect(nullableMultiType.isRequired, isFalse);
    expect(nullableMultiType.isNullable, isTrue);

    final oneOf = nullableMultiType.model as OneOfModel;
    expect(oneOf.models.length, 2);
    expect(
      oneOf.models.map((m) => m.model).toList(),
      containsAll([isA<StringModel>(), isA<NumberModel>()]),
    );
  });

  test('imports property with multiple types and nullable via type array', () {
    final api = Importer().import(fileContent);

    final model = api.models.first as ClassModel;
    final nullableMultiType = model.properties.firstWhere(
      (p) => p.name == 'nullableMultiTypeViaType',
    );
    expect(nullableMultiType.model, isA<OneOfModel>());
    expect(nullableMultiType.isRequired, isFalse);
    expect(nullableMultiType.isNullable, isTrue);

    final oneOf = nullableMultiType.model as OneOfModel;
    expect(oneOf.models.length, 2);
    expect(
      oneOf.models.map((m) => m.model).toList(),
      containsAll([isA<StringModel>(), isA<NumberModel>()]),
    );
  });

  test('imports array with multiple types', () {
    final api = Importer().import(fileContent);

    final model = api.models.first as ClassModel;
    final multiTypeArray = model.properties.firstWhere(
      (p) => p.name == 'multiTypeArray',
    );
    expect(multiTypeArray.model, isA<ListModel>());
    expect(multiTypeArray.isRequired, isFalse);
    expect(multiTypeArray.isNullable, isFalse);

    final listModel = multiTypeArray.model as ListModel;
    expect(listModel.content, isA<OneOfModel>());

    final content = listModel.content as OneOfModel;
    expect(content.models.length, 2);
    expect(
      content.models.map((m) => m.model).toList(),
      containsAll([isA<StringModel>(), isA<NumberModel>()]),
    );
  });

  test('imports nullable array', () {
    final api = Importer().import(fileContent);

    final model = api.models.first as ClassModel;
    final nullableArray = model.properties.firstWhere(
      (p) => p.name == 'nullableArray',
    );
    expect(nullableArray.model, isA<ListModel>());
    expect(nullableArray.isRequired, isFalse);
    expect(nullableArray.isNullable, isTrue);

    final listModel = nullableArray.model as ListModel;
    expect(listModel.content, isA<StringModel>());
  });

  test('imports nullable array via type array', () {
    final api = Importer().import(fileContent);

    final model = api.models.first as ClassModel;
    final nullableArray = model.properties.firstWhere(
      (p) => p.name == 'nullableArrayViaType',
    );
    expect(nullableArray.model, isA<ListModel>());
    expect(nullableArray.isRequired, isFalse);
    expect(nullableArray.isNullable, isTrue);

    final listModel = nullableArray.model as ListModel;
    expect(listModel.content, isA<StringModel>());
  });

  test('imports array with nullable items via type array', () {
    final api = Importer().import(fileContent);

    final model = api.models.first as ClassModel;
    final arrayWithNullableItems = model.properties.firstWhere(
      (p) => p.name == 'arrayWithNullableItems',
    );
    expect(arrayWithNullableItems.model, isA<ListModel>());
    expect(arrayWithNullableItems.isRequired, isFalse);
    expect(arrayWithNullableItems.isNullable, isFalse);

    final listModel = arrayWithNullableItems.model as ListModel;
    expect(listModel.content, isA<AliasModel>());
    expect(listModel.content.isEffectivelyNullable, isTrue);

    final content = listModel.content as AliasModel;
    expect(content.isNullable, isTrue);
    expect(content.model, isA<StringModel>());
    expect((content.model as StringModel).context.path, contains('array'));
  });

  test('imports array with nullable items via nullable flag', () {
    final api = Importer().import(fileContent);

    final model = api.models.first as ClassModel;
    final arrayWithNullableItems = model.properties.firstWhere(
      (p) => p.name == 'arrayWithNullableItemsViaFlag',
    );
    expect(arrayWithNullableItems.model, isA<ListModel>());

    final listModel = arrayWithNullableItems.model as ListModel;
    expect(listModel.content, isA<AliasModel>());
    expect(listModel.content.isEffectivelyNullable, isTrue);

    final content = listModel.content as AliasModel;
    expect(content.isNullable, isTrue);
    expect(content.model, isA<StringModel>());
  });

  test('adds inline type array OneOfModel to models set', () {
    final api = Importer().import(fileContent);

    final classModel =
        api.models.firstWhere(
              (m) => m is ClassModel && m.name == 'MultiTypeModel',
            )
            as ClassModel;

    final stringOrNumber = classModel.properties.firstWhere(
      (p) => p.name == 'stringOrNumber',
    );

    expect(stringOrNumber.model, isA<OneOfModel>());
    final oneOfModel = stringOrNumber.model as OneOfModel;

    expect(api.models.contains(oneOfModel), isTrue);
  });

  test('adds nested inline type array OneOfModel to models set', () {
    final api = Importer().import(fileContent);

    final classModel =
        api.models.firstWhere(
              (m) => m is ClassModel && m.name == 'MultiTypeModel',
            )
            as ClassModel;

    final multiTypeArray = classModel.properties.firstWhere(
      (p) => p.name == 'multiTypeArray',
    );

    expect(multiTypeArray.model, isA<ListModel>());
    final listModel = multiTypeArray.model as ListModel;

    expect(listModel.content, isA<OneOfModel>());
    final oneOfModel = listModel.content as OneOfModel;

    expect(api.models.contains(oneOfModel), isTrue);
  });
}
