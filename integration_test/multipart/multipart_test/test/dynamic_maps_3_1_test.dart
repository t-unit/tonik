import 'package:multipart_3_1_api/multipart_3_1_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  late RawRequestServer server;
  late Multipart31Api api;
  setUp(() async {
    server = await RawRequestServer.start();
    api = Multipart31Api(CustomServer(baseUrl: server.baseUrl));
  });

  test(
    'supports nullable named map aliases and referenced nullable values',
    () async {
      // The nullable typedef is the generated public request-body type.
      // ignore: unnecessary_nullable_for_final_variable_declarations
      const DynamicNullableAlias body = {'skip': null, 'value': 'alpha'};
      expect(await api.postDynamicNullableAlias(body: body), isTonikSuccess);
      final wire = MultipartWire(await server.takeRequest());
      expect(wire.parts.map((p) => p.name), ['value']);
      expect(wire.parts.single.bodyText, 'alpha');
      expect(wire.parts.single.contentType, startsWith('text/plain'));
    },
  );

  test('classifies a null alias root as encoding failure', () async {
    final error = requireError(await api.postDynamicNullableAlias(body: null));
    expect(error.type, TonikErrorType.encoding);
    expect(error.error, isA<EncodingException>());
    expect(server.requestCount, 0);
  });

  test(
    'reserves emitted exploded names before omitting a null dynamic value',
    () async {
      final error = requireError(
        await api.postDynamicStyled(
          body: const DynamicStyled(
            details: DynamicStyleDetails(extra: 'named'),
            additionalProperties: {'extra': null},
          ),
        ),
      );
      expect(error.type, TonikErrorType.encoding);
      expect(error.error, isA<EncodingException>());
      expect(server.requestCount, 0);
    },
  );

  test(
    'sends named exploded parts before non-colliding dynamic entries',
    () async {
      expect(
        await api.postDynamicStyled(
          body: const DynamicStyled(
            details: DynamicStyleDetails(extra: 'named'),
            additionalProperties: {'later': 'dynamic'},
          ),
        ),
        isTonikSuccess,
      );
      final wire = MultipartWire(await server.takeRequest());
      expect(wire.parts.map((p) => p.name), ['extra', 'later']);
      expect(wire.parts.map((p) => p.bodyText), ['named', 'dynamic']);
    },
  );

  test(
    'allows an encoding key for a literal declared asterisk property',
    () async {
      expect(
        await api.postDynamicStarProperty(
          body: const DynamicStarProperty(
            asterisk: 7,
            additionalProperties: {'later': 'value'},
          ),
        ),
        isTonikSuccess,
      );
      final wire = MultipartWire(await server.takeRequest());
      expect(wire.parts.map((p) => p.name), ['*', 'later']);
      expect(wire.parts[0].bodyText, '7');
      expect(wire.parts[0].contentType, startsWith('application/json'));
      expect(wire.parts[1].bodyText, 'value');
    },
  );
  test(
    'reads additional properties through a nullable class receiver',
    () async {
      expect(
        await api.postDynamicNullableMixed(
          body: const DynamicNullableMixed(
            additionalProperties: {'skip': null, 'present': 'alpha'},
          ),
        ),
        isTonikSuccess,
      );
      final wire = MultipartWire(await server.takeRequest());
      expect(wire.parts.map((p) => p.name), ['present']);
      expect(wire.parts.single.bodyText, 'alpha');
    },
  );

  test('rejects a null mixed class receiver as an encoding error', () async {
    final error = requireError(await api.postDynamicNullableMixed(body: null));
    expect(error.type, TonikErrorType.encoding);
    expect(error.error, isA<EncodingException>());
    expect(server.requestCount, 0);
  });
}
