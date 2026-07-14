import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/response_property_normalizer.dart';

void main() {
  late Context context;

  setUp(() {
    context = Context.initial();
  });

  for (final rawName in ['body', 'Body']) {
    test('keeps body reserved for literal header $rawName', () {
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

  for (final rawName in ['body_', '__body__']) {
    test('disambiguates content body after header $rawName', () {
      final header = _header(rawName, context);
      final response = _response(
        context: context,
        headers: {rawName: header},
        bodies: {_body('application/json', context)},
      );

      final properties = normalizeResponseProperties(response);

      expect(
        properties.map((property) => property.normalizedName),
        ['body', 'body2'],
      );
      expect(properties.first.header, same(header));
      expect(properties.first.property.name, rawName);
      expect(properties.last.header, isNull);
    });
  }

  test('keeps body_ distinct from a literal bodyHeader header', () {
    final normalizedBody = _header('body_', context);
    final literalBodyHeader = _header('bodyHeader', context);
    final response = _response(
      context: context,
      headers: {
        'body_': normalizedBody,
        'bodyHeader': literalBodyHeader,
      },
      bodies: {_body('application/json', context)},
    );

    final properties = normalizeResponseProperties(response);

    expect(
      properties.map((property) => property.normalizedName),
      ['body', 'bodyHeader', 'body2'],
    );
    expect(properties[0].header, same(normalizedBody));
    expect(properties[1].header, same(literalBodyHeader));
    expect(properties[2].header, isNull);
  });

  test('resolves body separately for content-specific response subclasses', () {
    final header = _header('body_', context);
    final response = _response(
      context: context,
      headers: {'body_': header},
      bodies: {
        _body('application/json', context),
        _body('text/plain', context),
      },
    );

    final baseProperties = normalizeResponseProperties(response);
    final implementationProperties = normalizeResponseProperties(
      response,
      body: response.bodies.first,
    );

    expect(
      baseProperties.map((property) => property.normalizedName),
      ['body'],
    );
    expect(baseProperties.single.header, same(header));
    expect(
      implementationProperties.map((property) => property.normalizedName),
      ['body', 'body2'],
    );
    expect(implementationProperties.first.header, same(header));
    expect(implementationProperties.last.header, isNull);
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
