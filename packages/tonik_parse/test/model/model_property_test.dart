import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  const fileContent = {
    'openapi': '3.0.0',
    'info': {'title': 'Test API', 'version': '1.0.0'},
    'paths': <String, dynamic>{},
    'components': {
      'schemas': {
        'SimpleModel': {
          'type': 'object',
          'properties': {
            'string': {'type': 'string', 'nullable': true},
            'integer': {'type': 'integer', 'deprecated': true},
            'int32': {'type': 'integer', 'format': 'int32'},
            'int64': {'type': 'integer', 'format': 'int64'},
            'number': {'type': 'number'},
            'float': {'type': 'number', 'format': 'float'},
            'double': {'type': 'number', 'format': 'double'},
            'decimal': {'type': 'string', 'format': 'decimal'},
            'currency': {'type': 'string', 'format': 'currency'},
            'money': {'type': 'string', 'format': 'money'},
            'numberString': {'type': 'string', 'format': 'number'},
            'boolean': {'type': 'boolean'},
            'date': {'type': 'string', 'format': 'date'},
            'dateTime': {'type': 'string', 'format': 'date-time'},
            'uri': {'type': 'string', 'format': 'uri'},
            'url': {'type': 'string', 'format': 'url'},
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

  test('imports decimal format', () {
    final api = Importer().import(fileContent);

    final model = api.models.first as ClassModel;
    final decimal = model.properties.firstWhere((p) => p.name == 'decimal');
    expect(decimal.model, isA<DecimalModel>());
  });

  test('imports currency format', () {
    final api = Importer().import(fileContent);

    final model = api.models.first as ClassModel;
    final currency = model.properties.firstWhere((p) => p.name == 'currency');
    expect(currency.model, isA<DecimalModel>());
  });

  test('imports money format', () {
    final api = Importer().import(fileContent);

    final model = api.models.first as ClassModel;
    final money = model.properties.firstWhere((p) => p.name == 'money');
    expect(money.model, isA<DecimalModel>());
  });

  test('imports number string format', () {
    final api = Importer().import(fileContent);

    final model = api.models.first as ClassModel;
    final numberString = model.properties.firstWhere(
      (p) => p.name == 'numberString',
    );
    expect(numberString.model, isA<DecimalModel>());
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

  test('imports uri format', () {
    final api = Importer().import(fileContent);

    final model = api.models.first as ClassModel;
    final uri = model.properties.firstWhere((p) => p.name == 'uri');
    expect(uri.model, isA<UriModel>());
  });

  test('imports url format', () {
    final api = Importer().import(fileContent);

    final model = api.models.first as ClassModel;
    final url = model.properties.firstWhere((p) => p.name == 'url');
    expect(url.model, isA<UriModel>());
  });
}
