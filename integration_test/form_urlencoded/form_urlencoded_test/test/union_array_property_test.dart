import 'package:form_urlencoded_api/form_urlencoded_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  test(
    'explodes a flat array selected by an unconstrained union member',
    () async {
      final server = await RawRequestServer.start();
      final api = FormApi(CustomServer(baseUrl: server.baseUrl));
      final body = UnknownUnionArrayForm.fromJson(const {
        'tags': ['blue', 'black'],
      });

      final response = await api.postUnknownUnionArrayForm(body: body);

      expect(response, isTonikSuccess);
      final request = await server.takeRequest();
      expect(request.bodyText, 'tags=blue&tags=black');
    },
  );

  test(
    'explodes a union array whose selected item variants are scalars',
    () async {
      final server = await RawRequestServer.start();
      final api = FormApi(CustomServer(baseUrl: server.baseUrl));
      final body = MixedItemUnionArrayForm.fromJson(const {
        'tags': ['blue', 'black'],
      });

      final response = await api.postMixedItemUnionArrayForm(body: body);

      expect(response, isTonikSuccess);
      final request = await server.takeRequest();
      expect(request.bodyText, 'tags=blue&tags=black');
      expect(server.requestCount, 1);
    },
  );

  test('rejects an object item selected within a union array', () async {
    final server = await RawRequestServer.start();
    final api = FormApi(CustomServer(baseUrl: server.baseUrl));
    final body = MixedItemUnionArrayForm.fromJson(const {
      'tags': [
        {'name': 'Ada'},
      ],
    });

    final response = await api.postMixedItemUnionArrayForm(body: body);

    final error = requireError(response);
    expect(error.type, TonikErrorType.encoding);
    expect(error.error, isA<EncodingException>());
    expect(server.requestCount, 0);
  });

  test('sends an exploded union array as repeated form fields', () async {
    final server = await RawRequestServer.start();
    final api = FormApi(CustomServer(baseUrl: server.baseUrl));
    final body = UnionArrayForm.fromJson(const {
      'tags': ['blue', 'black'],
    });

    final response = await api.postUnionArrayForm(body: body);

    expect(response, isTonikSuccess);
    final request = await server.takeRequest();
    expect(request.bodyText, 'tags=blue&tags=black');
    expect(request.header('content-type'), 'application/x-www-form-urlencoded');
    expect(server.requestCount, 1);
  });

  test('sends a union scalar as one form field', () async {
    final server = await RawRequestServer.start();
    final api = FormApi(CustomServer(baseUrl: server.baseUrl));
    final body = UnionArrayForm.fromJson(const {'tags': 'blue,black'});

    final response = await api.postUnionArrayForm(body: body);

    expect(response, isTonikSuccess);
    final request = await server.takeRequest();
    expect(request.bodyText, 'tags=blue%2Cblack');
  });

  test('preserves an empty string selected by an exploded union', () async {
    final server = await RawRequestServer.start();
    final api = FormApi(CustomServer(baseUrl: server.baseUrl));
    final body = UnionArrayForm.fromJson(const {'tags': ''});

    final response = await api.postUnionArrayForm(body: body);

    expect(response, isTonikSuccess);
    final request = await server.takeRequest();
    expect(request.bodyText, 'tags=');
  });

  test(
    'uses the default explode setting and retains an unknown sibling',
    () async {
      final server = await RawRequestServer.start();
      final api = FormApi(CustomServer(baseUrl: server.baseUrl));
      final body = ComplexUnionArrayForm.fromJson(const {
        'label': 'keep',
        'tags': ['blue', 'black'],
      });

      final response = await api.postComplexUnionArrayForm(body: body);

      expect(response, isTonikSuccess);
      final request = await server.takeRequest();
      expect(request.bodyText, 'label=keep&tags=blue&tags=black');
    },
  );

  test('honors explicit non-exploded union arrays', () async {
    final server = await RawRequestServer.start();
    final api = FormApi(CustomServer(baseUrl: server.baseUrl));
    final body = UnionArrayForm.fromJson(const {
      'tags': ['a,b', 'c'],
    });

    final response = await api.postJoinedUnionArrayForm(body: body);

    expect(response, isTonikSuccess);
    final request = await server.takeRequest();
    expect(request.bodyText, 'tags=a%2Cb,c');
  });

  test('keeps a union array beside a direct array property', () {
    final body = UnionArrayAndListForm.fromJson(const {
      'tags': ['blue', 'black'],
      'names': ['Ada'],
    });

    final properties = body.parameterProperties();

    expect((properties['tags']! as ArrayPropertyValue).values, [
      'blue',
      'black',
    ]);
    expect((properties['names']! as ArrayPropertyValue).values, ['Ada']);
  });

  test('encodes an array branch when every union branch is complex', () {
    final body = ComplexUnionArrayForm.fromJson(const {
      'label': 'keep',
      'tags': ['blue', 'black'],
    });

    final properties = body.parameterProperties();

    expect((properties['tags']! as ArrayPropertyValue).values, [
      'blue',
      'black',
    ]);
  });

  test('rejects an object selected by a union property', () {
    final body = ComplexUnionArrayForm.fromJson(const {
      'label': 'keep',
      'tags': {'name': 'Ada'},
    });

    expect(body.parameterProperties, throwsA(isA<EncodingException>()));
  });

  test('omits an absent optional union and preserves a present array', () {
    final absent = OptionalUnionArrayForm.fromJson(const <String, Object?>{});
    final present = OptionalUnionArrayForm.fromJson(const {
      'tags': ['a,b', 'c'],
    });

    expect(absent.parameterProperties(), isEmpty);
    final properties = present.parameterProperties();
    expect((properties['tags']! as ArrayPropertyValue).values, ['a,b', 'c']);
  });
}
