import 'package:collection/collection.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  const fileContent = {
    'openapi': '3.0.4',
    'info': {'title': 'Header Encoding API', 'version': '1.0.0'},
    'paths': <String, dynamic>{},
    'components': {
      'parameters': {
        'colorMatrix': {
          'name': 'X-Color-Matrix',
          'in': 'header',
          'style': 'simple',
          'explode': false,
          'schema': {'type': 'number'},
          'description': 'Matrix style header',
          'required': true,
          'deprecated': false,
          'allowEmptyValue': false,
        },
        'colorLabel': {
          'name': 'X-Color-Label',
          'in': 'header',
          'style': 'simple',
          'explode': false,
          'schema': {'type': 'string'},
          'description': 'Label style header',
        },
        'colorSimple': {
          'name': 'X-Color-Simple',
          'in': 'header',
          'style': 'simple',
          'explode': false,
          'schema': {'type': 'string'},
        },
        'colorForm': {
          'name': 'X-Color-Form',
          'in': 'header',
          'style': 'simple',
          'explode': false,
          'schema': {'type': 'string'},
        },
        'colorSpaceDelimited': {
          'name': 'X-Color-Space',
          'in': 'header',
          'style': 'simple',
          'explode': false,
          'schema': {
            'type': 'array',
            'items': {'type': 'string'},
          },
        },
        'colorPipeDelimited': {
          'name': 'X-Color-Pipe',
          'in': 'header',
          'style': 'simple',
          'explode': false,
          'schema': {
            'type': 'array',
            'items': {'type': 'string'},
          },
        },
        'colorDeepObject': {
          'name': 'X-Color-Deep',
          'in': 'header',
          'style': 'simple',
          'explode': true,
          'schema': {
            'type': 'object',
            'properties': {
              'r': {'type': 'string'},
              'g': {'type': 'string'},
              'b': {'type': 'string'},
            },
          },
        },
        'colorSchema': {
          'name': 'X-Color-Schema',
          'in': 'header',
          'schema': {r'$ref': '#/components/schemas/Color'},
        },
        'colorReference': {r'$ref': '#/components/parameters/colorMatrix'},
        'header': {
          'name': 'X-Header',
          'in': 'header',
          'schema': {'type': 'string'},
        },
        'headerReference': {r'$ref': '#/components/parameters/header'},
        'queryParameter': {
          'name': 'query',
          'in': 'query',
          'schema': {'type': 'string'},
        },
        'queryReference': {r'$ref': '#/components/parameters/queryParameter'},
      },
      'schemas': {
        'Color': {
          'type': 'object',
          'properties': {
            'r': {'type': 'string'},
            'g': {'type': 'string'},
            'b': {'type': 'string'},
          },
        },
      },
    },
  };

  final api = Importer().import(fileContent);
  final headers = api.requestHeaders;

  test('imports label style header', () {
    final header = headers.whereType<RequestHeaderObject>().firstWhere(
      (h) => h.name == 'colorLabel',
    );

    expect(header.rawName, 'X-Color-Label');
    expect(header.encoding, HeaderParameterEncoding.simple);
    expect(header.model, isA<StringModel>());
    expect(header.description, 'Label style header');
    expect(header.isRequired, isFalse); // default value
    expect(header.isDeprecated, isFalse); // default value
    expect(header.allowEmptyValue, isFalse); // default value
    expect(header.explode, isFalse);
  });

  test('imports simple style header', () {
    final header = headers.whereType<RequestHeaderObject>().firstWhere(
      (h) => h.name == 'colorSimple',
    );

    expect(header.rawName, 'X-Color-Simple');
    expect(header.encoding, HeaderParameterEncoding.simple);
    expect(header.model, isA<StringModel>());
    expect(header.explode, isFalse);
  });

  test('imports form style header', () {
    final header = headers.whereType<RequestHeaderObject>().firstWhere(
      (h) => h.name == 'colorForm',
    );

    expect(header.rawName, 'X-Color-Form');
    expect(header.encoding, HeaderParameterEncoding.simple);
    expect(header.model, isA<StringModel>());
    expect(header.explode, isFalse);
  });

  test('imports spaceDelimited style header', () {
    final header = headers.whereType<RequestHeaderObject>().firstWhere(
      (h) => h.name == 'colorSpaceDelimited',
    );

    expect(header.rawName, 'X-Color-Space');
    expect(header.encoding, HeaderParameterEncoding.simple);
    expect(header.model, isA<ListModel>());
    expect((header.model as ListModel).content, isA<StringModel>());
    expect(header.explode, isFalse);
  });

  test('imports pipeDelimited style header', () {
    final header = headers.whereType<RequestHeaderObject>().firstWhere(
      (h) => h.name == 'colorPipeDelimited',
    );

    expect(header.rawName, 'X-Color-Pipe');
    expect(header.encoding, HeaderParameterEncoding.simple);
    expect(header.model, isA<ListModel>());
    expect((header.model as ListModel).content, isA<StringModel>());
    expect(header.explode, isFalse);
  });

  test('imports deepObject style header', () {
    final header = headers.whereType<RequestHeaderObject>().firstWhere(
      (h) => h.name == 'colorDeepObject',
    );

    expect(header.rawName, 'X-Color-Deep');
    expect(header.encoding, HeaderParameterEncoding.simple);
    expect(header.model, isA<ClassModel>());
    expect(header.explode, isTrue);

    final model = header.model as ClassModel;
    expect(model.properties, hasLength(3));
    expect(model.properties.every((p) => p.model is StringModel), isTrue);
  });

  test('imports header with schema reference', () {
    final header = headers.whereType<RequestHeaderObject>().firstWhere(
      (h) => h.name == 'colorSchema',
    );

    expect(header.rawName, 'X-Color-Schema');
    expect(header.encoding, HeaderParameterEncoding.simple);
    expect(header.model, isA<ClassModel>());

    final model = header.model as ClassModel;
    expect(model.properties, hasLength(3));
    expect(model.properties.every((p) => p.model is StringModel), isTrue);
  });

  test('imports header reference', () {
    final header = headers.whereType<RequestHeaderAlias>().firstWhere(
      (h) => h.name == 'colorReference',
    );

    final target = header.header as RequestHeaderObject;
    expect(target.name, 'colorMatrix');
    expect(target.encoding, HeaderParameterEncoding.simple);
    expect(target.model, isA<NumberModel>());
  });

  test('does not duplicate headers when importing references', () {
    final matrix = headers.whereType<RequestHeaderObject>().where(
      (h) => h.name == 'colorMatrix',
    );
    final reference = headers.whereType<RequestHeaderAlias>().where(
      (h) => h.name == 'colorReference',
    );

    expect(matrix, hasLength(1));
    expect(reference, hasLength(1));
  });

  test('does not import query references as headers', () {
    final reference = headers.whereType<RequestHeaderAlias>().firstWhereOrNull(
      (h) => h.name == 'queryReference',
    );

    expect(reference, isNull);
  });
}
