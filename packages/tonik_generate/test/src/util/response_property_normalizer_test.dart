import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/response_property_normalizer.dart';

void main() {
  late Context context;

  setUp(() {
    context = Context.initial();
  });

  for (final rawName in ['body', 'Body', 'body_', '__body__']) {
    test('reserves body when header $rawName normalizes to body', () {
      final header = _header(rawName, context);
      final response = _response(
        context: context,
        headers: {rawName: header},
        bodies: {_body('application/json', context)},
      );

      final properties = normalizeResponseProperties(response);

      expect(
        properties.map((property) => property.normalizedName),
        ['bodyHeader', 'body'],
      );
      expect(properties.first.header, same(header));
      expect(properties.last.header, isNull);
    });
  }

  test('disambiguates body_ from a literal bodyHeader header', () {
    final normalizedBodyHeader = _header('body_', context);
    final literalBodyHeader = _header('bodyHeader', context);
    final response = _response(
      context: context,
      headers: {
        'body_': normalizedBodyHeader,
        'bodyHeader': literalBodyHeader,
      },
      bodies: {_body('application/json', context)},
    );

    final properties = normalizeResponseProperties(response);

    expect(
      properties.map((property) => property.normalizedName),
      ['bodyHeader', 'bodyHeader2', 'body'],
    );
    expect(properties[0].header, same(normalizedBodyHeader));
    expect(properties[1].header, same(literalBodyHeader));
    expect(properties[2].header, isNull);
  });

  test('reserves body for content-specific response subclasses', () {
    final header = _header('body_', context);
    final response = _response(
      context: context,
      headers: {'body_': header},
      bodies: {
        _body('application/json', context),
        _body('text/plain', context),
      },
    );

    final properties = normalizeResponseProperties(response);

    expect(
      properties.map((property) => property.normalizedName),
      ['bodyHeader'],
    );
    expect(properties.single.header, same(header));
  });
}

ResponseHeaderObject _header(String name, Context context) {
  return ResponseHeaderObject(
    name: name,
    context: context,
    description: 'Header $name',
    model: StringModel(context: context),
    isRequired: true,
    isDeprecated: false,
    explode: false,
    encoding: ResponseHeaderEncoding.simple,
    examples: const [],
  );
}

ResponseBody _body(String contentType, Context context) {
  return ResponseBody(
    model: StringModel(context: context),
    rawContentType: contentType,
    contentType: contentType == 'text/plain'
        ? ContentType.text
        : ContentType.json,
    examples: const [],
  );
}

ResponseObject _response({
  required Context context,
  required Map<String, ResponseHeader> headers,
  required Set<ResponseBody> bodies,
}) {
  return ResponseObject(
    name: 'TestResponse',
    context: context,
    headers: headers,
    description: 'Test response',
    bodies: bodies,
  );
}
