import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  test('OAS 3.0 multipart encodings remain content based', () {
    final encoding = _importEncoding(
      version: '3.0.3',
      encoding: {
        'contentType': 'text/plain; charset=latin1',
        'style': 'deepObject',
        'explode': true,
        'allowReserved': true,
      },
    );

    expect(encoding.contentType, ContentType.text);
    expect(encoding.rawContentType, 'text/plain; charset=latin1');
    expect(encoding.wireContentType, 'text/plain; charset=latin1');
    expect(encoding.textEncoding, TextEncoding.latin1);
    expect(encoding.style, isNull);
    expect(encoding.explode, isNull);
    expect(encoding.allowReserved, isNull);
  });

  test('OAS 3.1 explicit style fields select style-based encoding', () {
    final encoding = _importEncoding(
      encoding: {
        'contentType': 'application/json',
        'style': 'deepObject',
        'explode': false,
        'allowReserved': true,
        'headers': {
          'X-Trace': {
            'required': true,
            'schema': {'type': 'string'},
          },
        },
      },
    );

    expect(encoding.contentType, isNull);
    expect(encoding.rawContentType, isNull);
    expect(encoding.style, EncodingStyle.deepObject);
    expect(encoding.explode, isFalse);
    expect(encoding.allowReserved, isTrue);
    expect(encoding.headers, contains('X-Trace'));
    final header = encoding.headers!['X-Trace']!;
    expect(header, isA<ResponseHeaderObject>());
    expect((header as ResponseHeaderObject).model, isA<StringModel>());
    expect(header.isRequired, isTrue);
  });

  test('OAS 3.1 defaults style mode from explode or allowReserved', () {
    final explodeOnly = _importEncoding(encoding: {'explode': false});
    expect(explodeOnly.style, EncodingStyle.form);
    expect(explodeOnly.explode, isFalse);
    expect(explodeOnly.allowReserved, isFalse);

    final reservedOnly = _importEncoding(encoding: {'allowReserved': true});
    expect(reservedOnly.style, EncodingStyle.form);
    expect(reservedOnly.explode, isTrue);
    expect(reservedOnly.allowReserved, isTrue);
  });

  test('OAS 3.1 content-only encoding preserves text charset handling', () {
    final encoding = _importEncoding(
      encoding: {'contentType': 'text/plain; charset=us-ascii'},
    );

    expect(encoding.contentType, ContentType.text);
    expect(encoding.style, isNull);
    expect(encoding.explode, isNull);
    expect(encoding.allowReserved, isNull);
    expect(encoding.textEncoding, TextEncoding.ascii);
    expect(encoding.wireContentType, 'text/plain; charset=us-ascii');
  });
}

PartEncoding _importEncoding({
  required Map<String, dynamic> encoding,
  String version = '3.1.0',
}) {
  final api = Importer().import({
    'openapi': version,
    'info': {'title': 'Multipart encoding', 'version': '1.0.0'},
    'paths': {
      '/upload': {
        'post': {
          'operationId': 'upload',
          'requestBody': {
            'content': {
              'multipart/form-data': {
                'schema': {
                  'type': 'object',
                  'properties': {
                    'value': {'type': 'string'},
                  },
                },
                'encoding': {'value': encoding},
              },
            },
          },
          'responses': {
            '204': {'description': 'ok'},
          },
        },
      },
    },
  });
  final content =
      api.operations.single.requestBody!.resolvedContent.single
          as MultipartRequestContent;
  return content.encoding['value']!;
}
