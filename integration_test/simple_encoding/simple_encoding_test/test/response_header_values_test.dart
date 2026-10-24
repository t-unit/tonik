import 'package:simple_encoding_api/simple_encoding_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  test('keeps scalar equals signs in discriminated header fallback', () async {
    final endpoint = await RawRequestServer.start(
      responseHeaders: {'x-person-or-string': 'a=b=c'},
    );
    final server = CustomServer(baseUrl: endpoint.baseUrl);
    addTearDown(server.close);

    final result = await SimpleEncodingApi(server).testLiteralResponseHeaders();

    expect(requireSuccess(result).value.xPersonOrString?.toJson(), 'a=b=c');
  });

  test('keeps scalar quotes in discriminated header fallback', () async {
    final endpoint = await RawRequestServer.start(
      responseHeaders: {'x-person-or-string': 'hello, "world'},
    );
    final server = CustomServer(baseUrl: endpoint.baseUrl);
    addTearDown(server.close);

    final result = await SimpleEncodingApi(server).testLiteralResponseHeaders();

    expect(
      requireSuccess(result).value.xPersonOrString?.toJson(),
      'hello, "world',
    );
  });

  test('validates the selected header object after a recognized tag', () async {
    final endpoint = await RawRequestServer.start(
      responseHeaders: {'x-person-or-string': 'kind=person, name="Alice'},
    );
    final server = CustomServer(baseUrl: endpoint.baseUrl);
    addTearDown(server.close);

    final result = await SimpleEncodingApi(server).testLiteralResponseHeaders();

    final error = requireError(result);
    expect(error.type, TonikErrorType.decoding);
    expect(error.error, isA<SimpleDecodingException>());
  });

  test('decodes whitespace and quoted delimiters in header objects', () async {
    final endpoint = await RawRequestServer.start(
      responseHeaders: {
        'x-flags': 'enabled=true, archived=false',
        'x-person': 'name,Alice, age,30, tags,red, "blue,green"',
        'x-exploded-person':
            'name="Alice=Bob, Jr.", age=30, tags=red, "blue=green,yellow"',
        'x-extended-person': 'note,"a=b,c", name,Alice, age,30, tags,red, blue',
        'x-person-composition':
            'kind=person, name="Alice=Bob, Jr.", age=30, '
            'tags=red, "blue,green"',
      },
    );
    final server = CustomServer(baseUrl: endpoint.baseUrl);
    addTearDown(server.close);

    final result = await SimpleEncodingApi(server).testLiteralResponseHeaders();

    final headers = requireSuccess(result).value;
    expect(headers.xFlags, {'enabled': true, 'archived': false});
    expect(headers.xPerson?.name, 'Alice');
    expect(headers.xPerson?.age, 30);
    expect(headers.xPerson?.tags, ['red', '"blue,green"']);
    expect(headers.xExplodedPerson?.name, '"Alice=Bob, Jr."');
    expect(headers.xExplodedPerson?.age, 30);
    expect(headers.xExplodedPerson?.tags, ['red', '"blue=green,yellow"']);
    expect(headers.xExtendedPerson?.headerPerson.name, 'Alice');
    expect(headers.xExtendedPerson?.headerPerson.age, 30);
    expect(headers.xExtendedPerson?.headerPerson.tags, ['red', 'blue']);
    expect(headers.xExtendedPerson?.additionalProperties, {'note': '"a=b,c"'});
    expect(headers.xPersonComposition?.toJson(), {
      'kind': 'person',
      'name': '"Alice=Bob, Jr."',
      'age': 30,
      'tags': ['red', '"blue,green"'],
    });
  });

  test('preserves scalar commas and decodes quoted header lists', () async {
    final endpoint = await RawRequestServer.start(
      responseHeaders: {
        'x-msg': 'hello, world',
        'last-modified': 'Wed, 21 Oct 2015 07:28:00 GMT',
        'x-list': 'a,\t" b,c ", d',
        'x-list-alias': 'one, two',
        'x-list-composition': 'a, "b,c"',
        'x-scalar-choice': 'hello, world',
        'x-nullable-list': 'a, , ""',
      },
    );
    final server = CustomServer(baseUrl: endpoint.baseUrl);
    addTearDown(server.close);

    final result = await SimpleEncodingApi(server).testLiteralResponseHeaders();

    final headers = requireSuccess(result).value;
    expect(headers.xMsg, 'hello, world');
    expect(headers.lastModified, 'Wed, 21 Oct 2015 07:28:00 GMT');
    expect(headers.xList, ['a', '" b,c "', 'd']);
    expect(headers.xListAlias, ['one', 'two']);
    expect(headers.xListComposition?.toJson(), ['a', '"b,c"']);
    expect(headers.xScalarChoice?.toJson(), 'hello, world');
    expect(headers.xNullableList, ['a', null, '""']);
  });

  test('keeps absent optional response header lists null', () async {
    final endpoint = await RawRequestServer.start();
    final server = CustomServer(baseUrl: endpoint.baseUrl);
    addTearDown(server.close);

    final result = await SimpleEncodingApi(server).testLiteralResponseHeaders();

    final headers = requireSuccess(result).value;
    expect(headers.xMsg, isNull);
    expect(headers.xList, isNull);
    expect(headers.xListAlias, isNull);
    expect(headers.xListComposition, isNull);
    expect(headers.xNullableList, isNull);
  });

  test('reports malformed quoted header lists as decoding errors', () async {
    final endpoint = await RawRequestServer.start(
      responseHeaders: {'x-list': 'a, "b,c'},
    );
    final server = CustomServer(baseUrl: endpoint.baseUrl);
    addTearDown(server.close);

    final result = await SimpleEncodingApi(server).testLiteralResponseHeaders();

    final error = requireError(result);
    expect(error.type, TonikErrorType.decoding);
    expect(error.error, isA<SimpleDecodingException>());
  });
}
