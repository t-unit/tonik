import 'package:multipart_3_1_api/multipart_3_1_api.dart' as v31;
import 'package:multipart_3_2_api/multipart_3_2_api.dart' as v32;
import 'package:multipart_api/multipart_api.dart' as v30;
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';

void main() {
  test('OAS 3.0 multipart encoding has the expected wire values', () async {
    final server = await RawRequestServer.start();
    final api = v30.VersionedApi(
      v30.CustomServer(
        baseUrl: server.baseUrl,
        serverConfig: testServerConfig(),
      ),
    );
    final response = await api.postVersionedMultipart(
      body: const v30.VersionedForm(
        tags: ['a/b', '100%20', 'Grüße'],
        spaces: ['a&b', 'c+d'],
        numbers: [1, 2],
        texts: ['a b', 'c/d'],
        profile: v30.VersionedProfile(note: 'Grüße /?&%20 +'),
      ),
    );
    expect(response, isTonikSuccess);
    final wire = MultipartWire(await server.takeRequest());
    expect(wire.named('tags').map((part) => part.bodyText), [
      'a/b',
      '100%20',
      'Grüße',
    ]);
    expect(wire.named('spaces').map((part) => part.bodyText), ['a&b', 'c+d']);
    expect(wire.single('profile').bodyText, '{"note":"Grüße /?&%20 +"}');
    expect(wire.single('profile').contentType, startsWith('application/json'));
    expect(wire.named('numbers').map((part) => part.bodyText), ['1', '2']);
    expect(
      wire.named('numbers').map((part) => part.contentType),
      everyElement(startsWith('application/json')),
    );
    expect(wire.named('texts').map((part) => part.bodyText), [
      '"a b"',
      '"c/d"',
    ]);
    expect(
      wire.named('texts').map((part) => part.contentType),
      everyElement(startsWith('application/json')),
    );
  });

  test('OAS 3.1 multipart encoding has the expected wire values', () async {
    final server = await RawRequestServer.start();
    final api = v31.VersionedApi(
      v31.CustomServer(
        baseUrl: server.baseUrl,
        serverConfig: testServerConfig(),
      ),
    );
    final response = await api.postVersionedMultipart(
      body: const v31.VersionedForm(
        tags: ['a/b', '100%20', 'Grüße'],
        spaces: ['a&b', 'c+d'],
        numbers: [1, 2],
        texts: ['a b', 'c/d'],
        profile: v31.VersionedProfile(note: 'Grüße /?&%20 +'),
      ),
    );
    expect(response, isTonikSuccess);
    final wire = MultipartWire(await server.takeRequest());
    expect(wire.single('tags').bodyText, 'a/b|100%20|Grüße');
    expect(wire.single('spaces').bodyText, 'a&b c+d');
    expect(wire.single('profile[note]').bodyText, 'Grüße /?&%20 +');
    expect(wire.named('numbers').map((part) => part.bodyText), ['1', '2']);
    expect(
      wire.named('numbers').map((part) => part.contentType),
      everyElement(startsWith('application/json')),
    );
    expect(wire.named('texts').map((part) => part.bodyText), [
      '"a b"',
      '"c/d"',
    ]);
    expect(
      wire.named('texts').map((part) => part.contentType),
      everyElement(startsWith('application/json')),
    );
  });

  test('OAS 3.2 multipart encoding has the expected wire values', () async {
    final server = await RawRequestServer.start();
    final api = v32.VersionedApi(
      v32.CustomServer(
        baseUrl: server.baseUrl,
        serverConfig: testServerConfig(),
      ),
    );
    final response = await api.postVersionedMultipart(
      body: const v32.VersionedForm(
        tags: ['a/b', '100%20', 'Grüße'],
        spaces: ['a&b', 'c+d'],
        numbers: [1, 2],
        texts: ['a b', 'c/d'],
        profile: v32.VersionedProfile(note: 'Grüße /?&%20 +'),
      ),
    );
    expect(response, isTonikSuccess);
    final wire = MultipartWire(await server.takeRequest());
    expect(wire.single('tags').bodyText, 'a/b|100%20|Grüße');
    expect(wire.single('spaces').bodyText, 'a&b c+d');
    expect(wire.single('profile[note]').bodyText, 'Grüße /?&%20 +');
    expect(wire.named('numbers').map((part) => part.bodyText), ['1', '2']);
    expect(
      wire.named('numbers').map((part) => part.contentType),
      everyElement(startsWith('application/json')),
    );
    expect(wire.named('texts').map((part) => part.bodyText), [
      '"a b"',
      '"c/d"',
    ]);
    expect(
      wire.named('texts').map((part) => part.contentType),
      everyElement(startsWith('application/json')),
    );
  });
}
