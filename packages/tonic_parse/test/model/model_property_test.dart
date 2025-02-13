import 'package:test/test.dart';
import 'package:tonic_core/tonic_core.dart';
import 'package:tonic_parse/tonic_parse.dart';

void main() {
  const fileContent = {
    'openapi': '3.0.0',
    'info': {
      'title': 'Test API',
      'version': '1.0.0',
    },
    'paths': <String, dynamic>{},
    'components': {
      'schemas': {
        'SimpleModel': {
          'type': 'object',
          'properties': {
            'string': {
              'type': 'string',
              'nullable': true,
            },
            'integer': {
              'type': 'integer',
              'deprecated': true,
            },
            'int32': {
              'type': 'integer',
              'format': 'int32',
            },
            'int64': {
              'type': 'integer',
              'format': 'int64',
            },
            'number': {
              'type': 'number',
            },
            'float': {
              'type': 'number',
              'format': 'float',
            },
            'double': {
              'type': 'number',
              'format': 'double',
            },
            'decimal': {
              'type': 'string',
              'format': 'decimal',
            },
            'decimal-alt': {
              'type': 'string',
              'format': 'currency',
            },
            'boolean': {
              'type': 'boolean',
            },
            'date': {
              'type': 'string',
              'format': 'date',
            },
            'dateTime': {
              'type': 'string',
              'format': 'date-time',
            },
          },
        },
      },
    },
  };

  test('imports string', () {
    final api = Importer().import(fileContent);

    final model = api.models.first as ClassModel;
    final string = model.properties.firstWhere((p) => p.name == 'string');
    expect(string.model, isA<StringModel>());
    expect(string.isNullable, isTrue);
  });

  test('imports integer', () {
    final api = Importer().import(fileContent);

    final model = api.models.first as ClassModel;
    final integer = model.properties.firstWhere((p) => p.name == 'integer');
    expect(integer.model, isA<IntegerModel>());
    expect(integer.isDeprecated, isTrue);
  });

  test('imports int32', () {
    final api = Importer().import(fileContent);

    final model = api.models.first as ClassModel;
    final int32 = model.properties.firstWhere((p) => p.name == 'int32');
    expect(int32.model, isA<IntegerModel>());
  });

  test('imports int64', () {
    final api = Importer().import(fileContent);

    final model = api.models.first as ClassModel;
    final int64 = model.properties.firstWhere((p) => p.name == 'int64');
    expect(int64.model, isA<IntegerModel>());
  });

  test('imports number', () {
    final api = Importer().import(fileContent);

    final model = api.models.first as ClassModel;
    final number = model.properties.firstWhere((p) => p.name == 'number');
    expect(number.model, isA<NumberModel>());
  });

  test('imports float', () {
    final api = Importer().import(fileContent);

    final model = api.models.first as ClassModel;
    final float = model.properties.firstWhere((p) => p.name == 'float');
    expect(float.model, isA<DoubleModel>());
  });

  test('imports double', () {
    final api = Importer().import(fileContent);

    final model = api.models.first as ClassModel;
    final double = model.properties.firstWhere((p) => p.name == 'double');
    expect(double.model, isA<DoubleModel>());
  });

  test('imports decimal', () {
    final api = Importer().import(fileContent);

    final model = api.models.first as ClassModel;
    final decimal = model.properties.firstWhere((p) => p.name == 'decimal');
    expect(decimal.model, isA<DecimalModel>());

    final decimalAlt =
        model.properties.firstWhere((p) => p.name == 'decimal-alt');
    expect(decimalAlt.model, isA<DecimalModel>());
  });

  test('imports boolean', () {
    final api = Importer().import(fileContent);

    final model = api.models.first as ClassModel;
    final boolean = model.properties.firstWhere((p) => p.name == 'boolean');
    expect(boolean.model, isA<BooleanModel>());
  });

  test('imports date', () {
    final api = Importer().import(fileContent);

    final model = api.models.first as ClassModel;
    final date = model.properties.firstWhere((p) => p.name == 'date');
    expect(date.model, isA<DateModel>());
  });

  test('imports dateTime', () {
    final api = Importer().import(fileContent);

    final model = api.models.first as ClassModel;
    final dateTime = model.properties.firstWhere((p) => p.name == 'dateTime');
    expect(dateTime.model, isA<DateTimeModel>());
  });
}
