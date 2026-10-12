import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:immutable_collections_api/immutable_collections_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  test('stream items preserve immutable nested collections', () async {
    final imposterServer = await setupImposterServer();
    final server = CustomServer(
      baseUrl: 'http://localhost:${imposterServer.port}',
    );
    addTearDown(server.close);

    final result = await ItemsApi(server).getStreamedTagGroups();
    // The explicit type checks the generated immutable item type.
    final Stream<TonikResult<IList<TagGroups>, Object>> items = requireSuccess(
      result,
    ).value;
    final values = await items
        .map((item) => requireSuccess(item).value)
        .toList();

    expect(values, [
      IList<IMap<String, IList<String>>>([
        IMap({
          'primary': IList(const ['alpha', 'beta']),
        }),
      ]),
      const IListConst<IMap<String, IList<String>>>([]),
    ]);
    expect(values.first, isA<IList<IMap<String, IList<String>>>>());
    expect(values.first.single, isA<IMap<String, IList<String>>>());
    expect(values.first.single['primary'], isA<IList<String>>());
  });
}
