import 'package:tonik_core/src/model/model.dart';
import 'package:tonik_core/src/model/request_body.dart';

List<({Model source, Model projection})> multipartRequestProjectionPairs(
  Iterable<RequestBody> requestBodies,
) {
  final pairs = <({Model source, Model projection})>[];
  final visited = <Model>{};
  for (final body in requestBodies) {
    for (final content in body.resolvedContent) {
      if (content case final MultipartRequestContent multipart) {
        _collectPairs(multipart.model, multipart.requestModel, pairs, visited);
      }
    }
  }
  return pairs;
}

void _collectPairs(
  Model source,
  Model projection,
  List<({Model source, Model projection})> pairs,
  Set<Model> visited,
) {
  if (identical(source, projection) || !visited.add(projection)) return;

  if (source is AliasModel && projection is AliasModel) {
    _collectPairs(source.model, projection.model, pairs, visited);
  } else if (source is AllOfModel && projection is AllOfModel) {
    for (var index = 0; index < source.models.length; index++) {
      _collectPairs(
        source.models[index],
        projection.models[index],
        pairs,
        visited,
      );
    }
  }
  pairs.add((source: source, projection: projection));
}
